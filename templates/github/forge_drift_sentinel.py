#!/usr/bin/env python3
"""forge-drift-sentinel — central, server-side drift detector (Layer L3).

Runs in GitHub Actions (on push + daily schedule). Because it runs centrally it
catches drift introduced on ANY machine — the only layer that works regardless
of which laptop/agent/Codex session created the inconsistency.

Durable invariants checked, per open issue carrying a `stage/<prefix>` label:
  1. ISSUE_CLOSED_PR_OPEN  — an open PR's branch/title references this issue but
                             the issue is CLOSED (stale PR or premature close).
  2. STAGE_VS_PR           — issue labelled a pre-merge stage (review/qa/...) but
                             its PR is already MERGED, or labelled a post-merge
                             stage (shipped/deployed) but the PR is still OPEN.
  3. NO_STAGE_LABEL_PR     — an open PR references an OPEN issue that has NO
                             stage/* label at all (work running outside forge).
  4. BRANCH_BEHIND_DUP     — an open PR's head branch is far behind base and its
                             unique commits are already on base (duplicate /
                             already-merged commits — the classic merge-conflict
                             source described in the #366 incident).

On any violation the issue is labelled `forge/drift` and a sticky comment
(marked with an HTML sentinel) is posted/updated listing the findings. When an
issue's violations clear, the label is removed and the sticky comment is closed
out. The script is intentionally repo-agnostic: everything is parameterized via
environment variables so the same template drops into any forge project.

Environment:
  GITHUB_REPOSITORY   owner/repo (provided by Actions)
  GH_TOKEN            token with issues:write, pull-requests:read, contents:read
  STAGE_PREFIX        label prefix for stages (default: "stage/")
  DRIFT_LABEL         label applied on violation (default: "forge/drift")
  BEHIND_THRESHOLD    commits-behind to trigger BRANCH_BEHIND_DUP (default: 30)
  DRY_RUN             "1" to log only, never mutate (default: "0")

Exit code is always 0 unless the GitHub API is unreachable (so a transient API
blip fails the job loudly rather than silently passing).
"""
from __future__ import annotations

import json
import os
import re
import sys
import urllib.error
import urllib.request

API = "https://api.github.com"

STICKY_SENTINEL = "<!--forge-drift-sentinel-->"

PRE_MERGE_STAGES = {
    "strategy", "discovery", "prd", "behavior_contract", "design",
    "architecture", "test_plan", "implementation", "review", "code_review",
    "test_coverage", "proof_hardening", "qa",
}
POST_MERGE_STAGES = {"canary_deploy", "shipped", "deployed", "staging_deploy"}


def env(name: str, default: str = "") -> str:
    return os.environ.get(name, default)


def gh_request(method: str, path: str, token: str, body=None):
    url = path if path.startswith("http") else f"{API}{path}"
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header("Authorization", f"Bearer {token}")
    req.add_header("Accept", "application/vnd.github+json")
    req.add_header("X-GitHub-Api-Version", "2022-11-28")
    if data is not None:
        req.add_header("Content-Type", "application/json")
    with urllib.request.urlopen(req, timeout=30) as resp:
        raw = resp.read().decode()
        link = resp.headers.get("Link", "")
        return (json.loads(raw) if raw.strip() else None), link


def gh_paginate(path: str, token: str):
    """Yield items across all pages of a list endpoint."""
    sep = "&" if "?" in path else "?"
    next_url = f"{API}{path}{sep}per_page=100"
    while next_url:
        items, link = gh_request("GET", next_url, token)
        if isinstance(items, list):
            yield from items
        next_url = ""
        for part in link.split(","):
            if 'rel="next"' in part:
                m = re.search(r"<([^>]+)>", part)
                if m:
                    next_url = m.group(1)


def stage_labels(labels, prefix):
    return [name[len(prefix):] for lbl in labels
            for name in [lbl["name"] if isinstance(lbl, dict) else lbl]
            if name.startswith(prefix)]


def issue_refs_in_pr(pr):
    """Issue numbers referenced by a PR.

    `#NNN` anywhere in title/body/branch, plus the `<NNN>-` / `-<NNN>` segment
    convention in branch names (e.g. fix/312-grace, feature/foo-401). Bare
    numbers in free-text title/body are deliberately ignored to avoid false
    positives like "fix 100% of bugs".
    """
    ref = pr.get("head", {}).get("ref", "") or ""
    text = f"{ref} {pr.get('title', '')} {pr.get('body', '') or ''}"
    refs = {int(n) for n in re.findall(r"#(\d{2,6})", text)}
    # Branch-name numeric segments delimited by / - _ or string ends.
    for seg in re.split(r"[\/_-]", ref):
        if seg.isdigit() and 2 <= len(seg) <= 6:
            refs.add(int(seg))
    return refs


def main() -> int:
    repo = env("GITHUB_REPOSITORY")
    token = env("GH_TOKEN") or env("GITHUB_TOKEN")
    prefix = env("STAGE_PREFIX", "stage/")
    drift_label = env("DRIFT_LABEL", "forge/drift")
    behind_threshold = int(env("BEHIND_THRESHOLD", "30") or "30")
    dry_run = env("DRY_RUN", "0") == "1"

    if not repo or not token:
        print("forge-drift-sentinel: GITHUB_REPOSITORY and GH_TOKEN are required", file=sys.stderr)
        return 1

    try:
        open_issues = [i for i in gh_paginate(f"/repos/{repo}/issues?state=open", token)
                       if "pull_request" not in i]
        open_prs = list(gh_paginate(f"/repos/{repo}/pulls?state=open", token))
        # Recently closed PRs (to detect already-merged duplicates / stale refs).
        closed_prs = list(gh_paginate(f"/repos/{repo}/pulls?state=closed&sort=updated&direction=desc", token))[:50]
    except urllib.error.URLError as exc:
        print(f"forge-drift-sentinel: GitHub API unreachable: {exc}", file=sys.stderr)
        return 1

    issue_state = {}  # number -> "open"/"closed"
    for i in open_issues:
        issue_state[i["number"]] = "open"

    # Map issue -> findings (list of strings).
    findings: dict[int, list[str]] = {}

    def add(issue_num, msg):
        findings.setdefault(issue_num, []).append(msg)

    # Build a PR view keyed by referenced issue.
    pr_index = []
    for pr in open_prs + closed_prs:
        refs = issue_refs_in_pr(pr)
        pr_index.append((pr, refs))

    # --- Invariant 1 & 3: PR referencing closed / unlabelled issues -----------
    for pr, refs in pr_index:
        if pr.get("state") != "open":
            continue
        for num in refs:
            # Look up issue state lazily (closed issues are not in open_issues).
            st = issue_state.get(num)
            if st is None:
                try:
                    issue, _ = gh_request("GET", f"/repos/{repo}/issues/{num}", token)
                    st = issue.get("state")
                    issue_state[num] = st
                    if st == "open":
                        # cache labels for invariant 3
                        issue["_labels_cache"] = issue.get("labels", [])
                except Exception:
                    continue
            if st == "closed":
                add(num, f"PR #{pr['number']} ({pr['head']['ref']}) is OPEN but references CLOSED issue #{num} "
                         f"(stale PR or premature close).")

    # For invariant 3 we need labels of open issues referenced by open PRs.
    open_issue_by_num = {i["number"]: i for i in open_issues}
    for pr, refs in pr_index:
        if pr.get("state") != "open":
            continue
        for num in refs:
            issue = open_issue_by_num.get(num)
            if issue is None:
                continue
            slabels = stage_labels(issue.get("labels", []), prefix)
            if not slabels:
                add(num, f"open PR #{pr['number']} references OPEN issue #{num} which has NO "
                         f"{prefix}* label (work running outside the forge pipeline).")

    # --- Invariant 2: stage label vs PR merge state ---------------------------
    # Build issue -> open PR(s) and merged PR(s).
    merged_for_issue: dict[int, list] = {}
    open_for_issue: dict[int, list] = {}
    for pr, refs in pr_index:
        for num in refs:
            if pr.get("state") == "open":
                open_for_issue.setdefault(num, []).append(pr)
            elif pr.get("merged_at"):
                merged_for_issue.setdefault(num, []).append(pr)

    for issue in open_issues:
        num = issue["number"]
        slabels = set(stage_labels(issue.get("labels", []), prefix))
        if not slabels:
            continue
        if slabels & PRE_MERGE_STAGES and num in merged_for_issue and num not in open_for_issue:
            pr = merged_for_issue[num][0]
            add(num, f"issue labelled pre-merge stage ({', '.join(sorted(slabels & PRE_MERGE_STAGES))}) "
                     f"but PR #{pr['number']} is already MERGED — advance/close the stage.")
        if slabels & POST_MERGE_STAGES and num in open_for_issue:
            pr = open_for_issue[num][0]
            add(num, f"issue labelled post-merge stage ({', '.join(sorted(slabels & POST_MERGE_STAGES))}) "
                     f"but PR #{pr['number']} is still OPEN — not actually shipped.")

    # --- Invariant 4: branch far behind base, with real duplicate detection ---
    # "Far behind" alone is the merge-conflict risk. We additionally try to PROVE
    # already-merged duplicates by matching the branch's ahead-commit subjects
    # against the base branch's recent commit subjects (cheap, no clone). The
    # message only claims duplicates when actually found; otherwise it is a plain
    # "far behind base" warning.
    base_subjects_cache = {}

    def base_subjects(base_ref):
        if base_ref in base_subjects_cache:
            return base_subjects_cache[base_ref]
        subs = set()
        try:
            for c in list(gh_paginate(f"/repos/{repo}/commits?sha={urllib_quote(base_ref)}", token))[:200]:
                msg0 = (c.get("commit", {}).get("message", "") or "").splitlines()[:1]
                if msg0:
                    subs.add(msg0[0].strip())
        except Exception:
            pass
        base_subjects_cache[base_ref] = subs
        return subs

    for pr in open_prs:
        num_set = issue_refs_in_pr(pr)
        try:
            base = pr["base"]["ref"]
            head = pr["head"]["ref"]
            cmp, _ = gh_request("GET", f"/repos/{repo}/compare/{base}...{head}", token)
            behind = cmp.get("behind_by", 0)
            ahead = cmp.get("ahead_by", 0)
            ahead_commits = cmp.get("commits", []) or []
        except Exception:
            continue
        if behind < behind_threshold:
            continue
        targets = {n for n in num_set if issue_state.get(n) == "open"}
        if not targets:
            continue
        # Count how many of this branch's ahead-commit subjects already exist on base.
        bsubs = base_subjects(base)
        dup = 0
        for c in ahead_commits:
            s0 = (c.get("commit", {}).get("message", "") or "").splitlines()[:1]
            if s0 and s0[0].strip() in bsubs:
                dup += 1
        if dup > 0:
            msg = (f"PR #{pr['number']} branch '{head}' is {behind} commits behind '{base}' "
                   f"(ahead {ahead}); {dup} of its commits have subjects already on '{base}' "
                   f"— duplicate/already-merged commits (merge-conflict source). "
                   f"Merge '{base}' in and drop the superseded commits.")
        else:
            msg = (f"PR #{pr['number']} branch '{head}' is {behind} commits behind '{base}' "
                   f"(ahead {ahead}) — far behind base (merge-conflict risk). "
                   f"Rebase or merge '{base}' in.")
        for num in targets:
            add(num, msg)

    # --- Apply: label + sticky comment per issue ------------------------------
    print(f"forge-drift-sentinel: scanned {len(open_issues)} open issues, "
          f"{len(open_prs)} open PRs; {len(findings)} issue(s) with drift.")

    flagged = set(findings.keys())
    for num in sorted(flagged):
        msgs = findings[num]
        body = (f"{STICKY_SENTINEL}\n"
                f"### ⚠️ forge drift detected\n\n"
                f"The central drift sentinel found durable-state inconsistencies on this issue. "
                f"Source of truth is GitHub (issues/labels/PRs + tags); the local `.forge` cache is derived.\n\n"
                + "\n".join(f"- {m}" for m in msgs)
                + "\n\nResolve, then re-run `bash scripts/forge-reconcile.sh <dir> --apply` locally, "
                  "or `/forge:gate` to record the correct stage. This comment and the "
                  f"`{drift_label}` label clear automatically once the drift is gone.")
        print(f"  #{num}: {len(msgs)} finding(s)")
        for m in msgs:
            print(f"     - {m}")
        if dry_run:
            continue
        try:
            _add_label(repo, token, num, drift_label)
            _upsert_sticky(repo, token, num, body)
        except Exception as exc:  # noqa: BLE001
            print(f"  #{num}: could not apply label/comment: {exc}", file=sys.stderr)

    # Clear drift on issues that previously carried the label but are now clean.
    # Scan state=all: invariant 1 can flag a CLOSED issue (referenced by an open
    # PR), so a closed issue may still carry the label and must be cleanable.
    if not dry_run:
        try:
            labelled = gh_paginate(f"/repos/{repo}/issues?state=all&labels={urllib_quote(drift_label)}", token)
            for issue in labelled:
                if "pull_request" in issue:
                    continue
                num = issue["number"]
                if num not in flagged:
                    print(f"  #{num}: drift cleared — removing {drift_label}")
                    _remove_label(repo, token, num, drift_label)
                    _resolve_sticky(repo, token, num)
        except Exception as exc:  # noqa: BLE001
            print(f"forge-drift-sentinel: clear pass failed: {exc}", file=sys.stderr)

    return 0


def urllib_quote(s: str) -> str:
    import urllib.parse
    return urllib.parse.quote(s, safe="")


def _add_label(repo, token, num, label):
    gh_request("POST", f"/repos/{repo}/issues/{num}/labels", token, {"labels": [label]})


def _remove_label(repo, token, num, label):
    try:
        gh_request("DELETE", f"/repos/{repo}/issues/{num}/labels/{urllib_quote(label)}", token)
    except urllib.error.HTTPError as exc:
        if exc.code != 404:
            raise


def _find_sticky(repo, token, num):
    for c in gh_paginate(f"/repos/{repo}/issues/{num}/comments", token):
        if STICKY_SENTINEL in (c.get("body") or ""):
            return c["id"]
    return None


def _upsert_sticky(repo, token, num, body):
    cid = _find_sticky(repo, token, num)
    if cid:
        gh_request("PATCH", f"/repos/{repo}/issues/comments/{cid}", token, {"body": body})
    else:
        gh_request("POST", f"/repos/{repo}/issues/{num}/comments", token, {"body": body})


def _resolve_sticky(repo, token, num):
    cid = _find_sticky(repo, token, num)
    if cid:
        gh_request("PATCH", f"/repos/{repo}/issues/comments/{cid}", token,
                   {"body": f"{STICKY_SENTINEL}\n_forge drift sentinel: previously-reported drift has cleared._"})


if __name__ == "__main__":
    sys.exit(main())
