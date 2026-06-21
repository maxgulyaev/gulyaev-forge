#!/usr/bin/env python3
"""Offline unit tests for the pure helpers of forge_drift_sentinel.

The network-dependent main() is exercised server-side; here we lock down the
parsing/classification logic that decides what counts as drift, since that is
where a subtle regex/set bug would silently mislabel issues.
"""
import importlib.util
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location("fds", os.path.join(HERE, "forge_drift_sentinel.py"))
fds = importlib.util.module_from_spec(spec)
spec.loader.exec_module(fds)

failures = 0


def check(name, cond):
    global failures
    if cond:
        print(f"PASS {name}")
    else:
        print(f"FAIL {name}")
        failures += 1


# stage_labels strips the prefix and ignores non-stage labels.
labels = [{"name": "stage/review"}, {"name": "P1"}, {"name": "stage/qa"}]
check("stage_labels strips prefix", set(fds.stage_labels(labels, "stage/")) == {"review", "qa"})
check("stage_labels ignores non-stage", "P1" not in fds.stage_labels(labels, "stage/"))

# issue_refs_in_pr: #NNN in title, NNN- segment in branch.
pr1 = {"head": {"ref": "fix/312-grace-recovery-wip"}, "title": "P0 grace", "body": ""}
check("ref from branch segment", fds.issue_refs_in_pr(pr1) == {312})

pr2 = {"head": {"ref": "feature/activity-header"}, "title": "iOS header #366 + #402", "body": "closes #369"}
check("refs from title/body #N", fds.issue_refs_in_pr(pr2) == {366, 402, 369})

pr3 = {"head": {"ref": "feature/no-numbers"}, "title": "fix 100% of the bugs", "body": "speed up by 1000x"}
check("bare numbers in free text ignored", fds.issue_refs_in_pr(pr3) == set())

pr4 = {"head": {"ref": "fix/web-401-csrf"}, "title": "csrf", "body": ""}
check("middle branch segment matches", fds.issue_refs_in_pr(pr4) == {401})

# Stage sets are disjoint and cover the alias forms used by Spodi.
check("pre/post merge stages disjoint",
      not (fds.PRE_MERGE_STAGES & fds.POST_MERGE_STAGES))
check("review alias present", "review" in fds.PRE_MERGE_STAGES and "code_review" in fds.PRE_MERGE_STAGES)
check("shipped is post-merge", "shipped" in fds.POST_MERGE_STAGES)

# urllib_quote escapes the slash in forge/drift.
check("label quote escapes slash", fds.urllib_quote("forge/drift") == "forge%2Fdrift")

print(f"\n{'ALL PASS' if failures == 0 else str(failures) + ' FAILED'}")
sys.exit(1 if failures else 0)
