# Issue Tracking Integration

## Purpose
Connect pipeline stages to issue tracking — features become epics, stories become issues, tasks break down by discipline, PRs link to issues, deploys close them.

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

---

## Issue Hierarchy (3 levels)

```
Epic (Feature)                               level/epic
  │
  ├── User Story                             level/story
  │     ├── Design Task                      level/task + discipline/design
  │     ├── Backend Task                     level/task + discipline/backend
  │     ├── Frontend Task                    level/task + discipline/frontend
  │     ├── Mobile Task                      level/task + discipline/mobile
  │     └── Test Task                        level/task + discipline/test
  │
  ├── User Story
  │     ├── Backend Task
  │     └── ...
  │
  └── Bug (from QA or post-deploy)           level/task + type/bug
```

### Level 1: Epic (Feature)
- **What**: Large feature or initiative from Strategy/PRD
- **Created at**: Stage 2 (PRD) — one Epic per PRD
- **Contains**: Checklist of all User Stories (sub-issues)
- **Closed when**: All child stories are closed + shipped to production
- **Labels**: `level/epic`, `priority/*`

**GitHub implementation**: Issue with sub-issues (task list tracking)

```markdown
# Epic: Supersets in Workouts

> PRD: docs/prd/2026-03-10-supersets.md
> Strategy pillar: Core Workout Experience

## Stories
- [ ] #101 As a user, I want to group exercises into supersets
- [ ] #102 As a user, I want to see superset rest timers
- [ ] #103 As a user, I want to reorder exercises within a superset
- [ ] #104 As a user, I want templates to support supersets

## Success Metrics
| Metric | Baseline | Target |
|--------|----------|--------|
| Workout completion rate | 72% | 78% |
| Avg exercises per workout | 5.2 | 6.5 |
```

### Level 2: User Story
- **What**: One user-facing behavior from PRD story sharding
- **Created at**: Stage 2 (PRD) — spec-to-issue bridge
- **Contains**: Checklist of Tasks (sub-issues)
- **Parent**: Epic (linked via sub-issue)
- **Closed when**: All child tasks done + QA passed
- **Labels**: `level/story`, `priority/*`, `stage/*`

**GitHub implementation**: Sub-issue of Epic, with its own sub-issues (tasks)

```markdown
# Story: Group exercises into supersets

> Epic: #100 Supersets in Workouts
> Story file: docs/prd/stories/superset-grouping.md

## Context
Users want to perform exercises back-to-back without rest (supersets).
Currently exercises are independent — no grouping concept exists.

## Acceptance Criteria
- [ ] User can select 2+ exercises and group them as a superset
- [ ] Superset is visually distinct in the workout view
- [ ] Exercises within superset share a single rest timer
- [ ] Superset order can be changed during workout

## Tasks
- [ ] #110 Design: superset UI/UX spec
- [ ] #111 Backend: superset data model + API
- [ ] #112 Frontend: superset components (web)
- [ ] #113 Mobile: superset views (iOS)
- [ ] #114 Test: superset E2E journeys

## Technical Hints
[Filled by Architecture stage]
- DB: add superset_group_id to workout_exercises
- API: PATCH /workout-exercises/group, DELETE /workout-exercises/ungroup
- UI: drag-to-group gesture (iOS), multi-select + "Group" button (web)
```

### Level 3: Task
- **What**: One concrete piece of work in one discipline
- **Created at**: Stage 4 (Architecture) or Stage 6 (Implementation)
- **Parent**: User Story (linked via sub-issue)
- **Assigned to**: Specific agent or developer
- **Closed when**: PR merged + review passed
- **Labels**: `level/task`, `discipline/*`, `stage/*`

**GitHub implementation**: Sub-issue of Story

```markdown
# Task: Backend — superset data model + API

> Story: #101 Group exercises into supersets
> Discipline: backend

## Scope
- Add superset_group_id (UUID, nullable) to workout_exercises table
- Migration: 027_superset_groups.sql
- API: PATCH /api/v1/workout-exercises/group
  - Request: { exercise_ids: UUID[], session_id: UUID }
  - Response: { superset_group_id: UUID }
- API: DELETE /api/v1/workout-exercises/ungroup
  - Request: { superset_group_id: UUID }

## Acceptance Criteria
- [ ] Migration runs without locking workout_exercises table
- [ ] Grouping 2+ exercises returns shared superset_group_id
- [ ] Ungrouping sets superset_group_id to NULL
- [ ] Existing workouts unaffected (nullable column)

## Branch
feat/111-superset-backend
```

---

## Disciplines

Tasks are tagged by discipline to enable parallel work:

| Label | Who | Pipeline Stage |
|-------|-----|---------------|
| `discipline/design` | Design agent/person | Stage 3 |
| `discipline/backend` | Backend agent/person | Stage 6 |
| `discipline/frontend` | Frontend agent/person | Stage 6 |
| `discipline/mobile` | Mobile agent/person | Stage 6 |
| `discipline/test` | QA agent/person | Stage 5, 7, 8 |
| `discipline/devops` | DevOps agent/person | Stage 9, 10 |
| `discipline/analytics` | Analytics agent/person | Stage 11, 12 |

**Parallel execution rule**: Backend tasks first (API must exist), then frontend + mobile in parallel. Design tasks can run ahead of or parallel to architecture.

---

## Pipeline Flow (with hierarchy)

```
Stage 0 (Strategy)
  │ Feature identified in roadmap
  │
Stage 2 (PRD)
  │ PRD approved at gate
  │
  ▼ SPEC-TO-ISSUE BRIDGE
  │
  │ 1. Create Epic issue (level/epic)
  │    - Title: feature name
  │    - Body: PRD summary + success metrics
  │    - Labels: level/epic, priority/[p0|p1|p2]
  │
  │ 2. For each story file → create Story issue (level/story)
  │    - Title: story title
  │    - Body: context + acceptance criteria (checkboxes)
  │    - Parent: Epic (sub-issue)
  │    - Labels: level/story, priority/*, stage/prd, source/prd
  │    - Write issue URL back to story file
  │
Stage 3 (Design)
  │ Design approved
  │
  ▼ CREATE DESIGN TASKS
  │   → For each story with UI → create Task (level/task, discipline/design)
  │   → Parent: Story
  │   → Update story label: stage/design
  │
Stage 4 (Architecture)
  │ Architecture approved
  │
  ▼ CREATE IMPLEMENTATION TASKS + UPDATE STORIES
  │   → Add Technical Hints to each Story issue body
  │   → For each story → create Tasks by discipline:
  │     - discipline/backend (if API/DB changes)
  │     - discipline/frontend (if web UI changes)
  │     - discipline/mobile (if mobile UI changes)
  │     - discipline/test (E2E journeys)
  │   → Each task is sub-issue of its Story
  │   → Update story label: stage/architecture
  │
Stage 6 (Implementation)
  │ Developer picks up Task
  │
  ▼ BRANCH + PR
  │   → Branch: feat/[task-number]-[slug]
  │   → PR references task: "Closes #NNN"
  │   → Update task label: stage/implementation
  │   → When all tasks in Story done → Story auto-closes
  │   → When all stories in Epic done → Epic auto-closes
  │
Stage 6.5 (Code Review)
  │ /code-review runs on PR
  │
  ▼ FINDINGS
  │   → Critical findings → comment on Task issue
  │   → Update label: stage/review
  │
Stage 8 (QA)
  │ QA report produced
  │
  ▼ BUGS
  │   → Bugs found → create Bug issues (level/task, type/bug)
  │   → Parent: relevant Story
  │   → Labels: level/task, type/bug, priority/*, discipline/*
  │   → Update story label: stage/qa
  │
Stage 10 (Canary Deploy)
  │ Feature reaches 100%
  │
  ▼ CLOSE CHAIN
  │   → PR merge closes Task issues
  │   → All Tasks closed → Story auto-closes
  │   → All Stories closed → Epic auto-closes
  │   → Epic gets label: stage/shipped
  │
Stage 11-12 (Analytics + Monitoring)
  │ Issues found post-deploy
  │
  ▼ FEEDBACK
      → New issues: source/analytics or source/monitoring
      → Can be standalone or linked to existing Epic
      → Feed back into Stage 0 for next cycle
```

---

## Label System (complete)

### Level labels (hierarchy)
| Label | Color | Meaning |
|-------|-------|---------|
| `level/epic` | purple | Feature/initiative — contains stories |
| `level/story` | blue | User-facing behavior — contains tasks |
| `level/task` | green | Concrete work item — one PR |

### Stage labels (auto-applied by pipeline)
| Label | When Applied |
|-------|-------------|
| `stage/strategy` | Стратегическая оценка начата (Stage 0) |
| `stage/discovery` | Исследование начато (Stage 1) |
| `stage/prd` | PRD написан / issue создан из story (Stage 2) |
| `stage/design` | Дизайн-задача создана (Stage 3) |
| `stage/architecture` | Техническая архитектура готова (Stage 4) |
| `stage/implementation` | Разработка начата (Stage 6) |
| `stage/review` | PR на code review (Stage 6.5) |
| `stage/qa` | QA в процессе (Stage 8) |
| `stage/shipped` | Задеплоено в прод (Stage 10) |

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
| `source/bug` | Bug report (QA or user) |
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

### Discipline labels (for tasks)
| Label | Meaning |
|-------|---------|
| `discipline/design` | UI/UX work |
| `discipline/backend` | API/DB/service work |
| `discipline/frontend` | Web UI work |
| `discipline/mobile` | iOS/Android work |
| `discipline/test` | Test writing/QA work |
| `discipline/devops` | Deploy/infra work |
| `discipline/analytics` | Metrics/monitoring work |

---

## GitHub Implementation Details

### Sub-issues
GitHub supports sub-issues natively. Create via:
```bash
# Create Epic
gh issue create --title "Epic: Supersets" --label "level/epic,priority/p1" --body "..."

# Create Story as sub-issue of Epic
gh issue create --title "Story: Group exercises" --label "level/story" --body "..."
# Then link via GitHub UI or API: parent #100

# Create Task as sub-issue of Story
gh issue create --title "Backend: superset data model" --label "level/task,discipline/backend" --body "..."
# Then link via GitHub UI or API: parent #101
```

### Auto-close chain
- Task closed by PR merge (`Closes #NNN`)
- Story auto-closes when all sub-issues (tasks) are closed
- Epic auto-closes when all sub-issues (stories) are closed
- GitHub handles this natively with sub-issue tracking

### Project Board Views
Recommended views on GitHub Projects:

**Board view** (kanban):
- Columns: Backlog → In Progress → Review → QA → Done
- Filter by: `level/story` (stories are the unit of progress)

**Table view** (status):
- Group by: Epic
- Columns: Title, Priority, Stage, Discipline, Assignee

**Roadmap view** (timeline):
- Group by: Epic
- Show: start date → target date

---

## Issue Templates (GitHub)

### Epic template
```yaml
# .github/ISSUE_TEMPLATE/epic.yml
name: Epic
description: Large feature or initiative
labels: ["level/epic"]
body:
  - type: input
    id: prd
    attributes:
      label: PRD Link
      placeholder: docs/prd/YYYY-MM-DD-feature.md
  - type: input
    id: strategy_pillar
    attributes:
      label: Strategy Pillar
      placeholder: Which strategic pillar does this serve?
  - type: textarea
    id: stories
    attributes:
      label: Stories
      description: Checklist of user stories (will become sub-issues)
  - type: textarea
    id: metrics
    attributes:
      label: Success Metrics
      description: How do we measure success?
```

### Story template
```yaml
# .github/ISSUE_TEMPLATE/story.yml
name: User Story
description: User-facing behavior
labels: ["level/story", "source/prd"]
body:
  - type: input
    id: epic
    attributes:
      label: Parent Epic
      placeholder: "#NNN"
  - type: input
    id: story_file
    attributes:
      label: Story File
      placeholder: docs/prd/stories/slug.md
  - type: textarea
    id: context
    attributes:
      label: Context
  - type: textarea
    id: acceptance_criteria
    attributes:
      label: Acceptance Criteria
      description: Each criterion as a checkbox
  - type: textarea
    id: tech_hints
    attributes:
      label: Technical Hints
      description: Filled by Architecture stage
```

### Task template
```yaml
# .github/ISSUE_TEMPLATE/task.yml
name: Task
description: Concrete work item in one discipline
labels: ["level/task"]
body:
  - type: input
    id: story
    attributes:
      label: Parent Story
      placeholder: "#NNN"
  - type: dropdown
    id: discipline
    attributes:
      label: Discipline
      options:
        - design
        - backend
        - frontend
        - mobile
        - test
        - devops
        - analytics
  - type: textarea
    id: scope
    attributes:
      label: Scope
      description: What exactly needs to be done
  - type: textarea
    id: acceptance_criteria
    attributes:
      label: Acceptance Criteria
```

---

## Provider Adapters

### GitHub Issues (default)
- **Create**: `gh issue create --title "..." --body "..." --label "..."`
- **Sub-issues**: GitHub native sub-issue support
- **Update**: `gh issue edit NNN --add-label "..."`
- **Close**: Auto via PR merge ("Closes #NNN") + sub-issue cascade
- **Board**: GitHub Projects V2 API
- **Templates**: `.github/ISSUE_TEMPLATE/*.yml`
- **MCP**: `@modelcontextprotocol/server-github`

### Linear (future)
- **Epic**: Linear Project
- **Story**: Linear Issue
- **Task**: Linear Sub-issue
- **Labels**: Map to Linear labels/states
- **Board**: Linear built-in views
- **MCP**: `linear-mcp-server`

### Jira (future)
- **Epic**: Jira Epic
- **Story**: Jira Story
- **Task**: Jira Task/Sub-task
- **Labels**: Map to Jira issue types + labels
- **Board**: Jira Scrum/Kanban board
- **MCP**: TBD

### None
- Stories tracked only in `docs/prd/stories/` files
- No external issue tracker
- Pipeline state tracked in `pipeline-state.yaml` only

---

## Forge /init Behavior

When initializing a project:
```
forge init --project ./spodi

Issue tracking:
  Detected: GitHub repo (github.com/maxgulyaev/spodi)
  Detected: GitHub Projects board exists
  Detected: Existing issue templates in .github/ISSUE_TEMPLATE/

  Provider: github (recommended)

  Create standard labels? [Y/N]
    → Creates: level/*, stage/*, priority/*, source/*, type/*, discipline/*

  Add issue templates? [Y/N]
    → Creates: .github/ISSUE_TEMPLATE/epic.yml, story.yml, task.yml

  Link to project board? [Y/N]
    → Auto-add new issues to board

  Configure board views? [Y/N]
    → Creates: Board (kanban), Table (by epic), Roadmap views
```
