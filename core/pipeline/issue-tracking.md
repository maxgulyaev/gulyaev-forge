# Issue Tracking Integration

## Purpose
Connect pipeline stages to issue tracking — stories become tickets, tickets flow through stages, PRs link to tickets, deploys close tickets.

## Principle: Agnostic with Default

Forge supports multiple trackers via adapters. Project chooses its tracker in `.forge/config.yaml`:

```yaml
tracking:
  provider: github       # github | linear | jira | none
  project_board: true    # auto-add issues to project board
  labels:
    stage_prefix: "stage/"       # stage/prd, stage/implementation, etc.
    priority_prefix: "priority/" # priority/p0, priority/p1, priority/p2
```

Default: **GitHub Issues** (most common, free, integrated with PRs).

## Pipeline Flow

```
Stage 2 (PRD)
  │ Stories written in docs/prd/stories/[slug].md
  │
  ▼ SPEC-TO-ISSUE BRIDGE (automatic after PRD gate approved)
  │
  │ For each story file:
  │   → Create issue with title, acceptance criteria, priority label
  │   → Add label: stage/prd
  │   → Add to project board (if configured)
  │   → Link back: add issue URL to story file
  │
Stage 4 (Architecture)
  │ Architecture approved
  │
  ▼ UPDATE ISSUES
  │   → Add Technical Hints from architecture to each issue body
  │   → Update label: stage/architecture
  │
Stage 6 (Implementation)
  │ Developer picks up issue
  │
  ▼ BRANCH + PR
  │   → Branch name: feat/[issue-number]-[slug]
  │   → PR description references issue: "Closes #NNN"
  │   → Update label: stage/implementation
  │
Stage 6.5 (Code Review)
  │ /code-review runs on PR
  │
  ▼ FINDINGS
  │   → Critical findings → comment on issue
  │   → Update label: stage/review
  │
Stage 8 (QA)
  │ QA report produced
  │
  ▼ QA RESULT
  │   → Bugs found → create new issues linked to parent
  │   → Update label: stage/qa
  │
Stage 10 (Canary Deploy)
  │ Feature reaches 100%
  │
  ▼ AUTO-CLOSE
  │   → PR merge closes issue (via "Closes #NNN")
  │   → Or manual close after canary reaches 100%
  │   → Update label: stage/shipped
  │
Stage 11-12 (Analytics + Monitoring)
  │ Issues found post-deploy
  │
  ▼ FEEDBACK ISSUES
      → Create new issues with label: source/analytics or source/monitoring
      → These feed back into Stage 0 (Strategy) for next cycle
```

## Label System

### Stage labels (auto-applied by pipeline)
| Label | When Applied |
|-------|-------------|
| `stage/prd` | Issue created from story |
| `stage/architecture` | Tech hints added |
| `stage/implementation` | Developer starts work |
| `stage/review` | PR in code review |
| `stage/qa` | QA in progress |
| `stage/shipped` | Deployed to production |

### Priority labels (from PRD)
| Label | Meaning |
|-------|---------|
| `priority/p0` | Do now — blocks current cycle |
| `priority/p1` | This cycle — should ship |
| `priority/p2` | Backlog — next cycle or later |

### Source labels (where the issue came from)
| Label | Meaning |
|-------|---------|
| `source/prd` | From PRD story sharding |
| `source/bug` | Bug report |
| `source/analytics` | From product analytics (Stage 11) |
| `source/monitoring` | From tech monitoring (Stage 12) |
| `source/scout` | From technology evaluation |

### Type labels
| Label | Meaning |
|-------|---------|
| `type/feature` | New functionality |
| `type/bug` | Defect |
| `type/improvement` | Enhancement to existing |
| `type/tech-debt` | Internal quality |
| `type/research` | Discovery task |

## Issue Template (auto-generated from story)

```markdown
## Context
[From story file: context section]

## Requirements
[From story file: requirements with REQ-NNN references]

## Acceptance Criteria
- [ ] [From story file: each criterion becomes a checkbox]

## Technical Hints
[Filled by Architecture stage — DB, API, UI changes]

---
> Auto-generated from PRD story: `docs/prd/stories/[slug].md`
> Pipeline: [project] / [feature] / Stage [N]
```

## Provider Adapters

### GitHub Issues (default)
- **Create**: `gh issue create --title "..." --body "..." --label "..."`
- **Update**: `gh issue edit NNN --add-label "..."`
- **Close**: Auto via PR merge ("Closes #NNN") or `gh issue close NNN`
- **Board**: GitHub Projects API
- **MCP**: `@modelcontextprotocol/server-github`

### Linear (future)
- **Create**: Linear MCP or API
- **Labels**: Map to Linear labels/states
- **Board**: Linear built-in board
- **MCP**: `linear-mcp-server`

### Jira (future)
- **Create**: Jira API
- **Labels**: Map to Jira statuses/labels
- **Board**: Jira built-in board
- **MCP**: TBD

### None
- Stories tracked only in `docs/prd/stories/` files
- No external issue tracker
- Pipeline state tracked in `pipeline-state.yaml` only

## Forge /init Behavior

When initializing a project:
```
forge init --project ./spodi

Issue tracking:
  Detected: GitHub repo (github.com/maxgulyaev/spodi)
  Detected: GitHub Projects board exists

  Provider: github (recommended)
  Create standard labels? [Y/N]
    → Creates: stage/*, priority/*, source/*, type/* labels
  Link to project board? [Y/N]
    → Auto-add new issues to board
```
