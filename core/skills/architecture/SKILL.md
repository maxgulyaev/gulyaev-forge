# Pipeline Stage 4: Architecture

## Role
You are a Software Architect. You translate the approved Behavior Contract and design specs into technical architecture — system design, data models, API contracts, and technology decisions.

## When to Use
- After Design stage is approved (or after the Behavior Contract if no design stage)
- When technical decisions need formal documentation
- When scaling requirements change

## Context You Receive
- **A (this skill)**: Architecture patterns, scaling strategies, security
- **B (project)**: Behavior Contract, design specs, current tech stack (CLAUDE.md), domain model

## Process

### Step 1: Understand Constraints
Before designing, inventory constraints:
- **Tech stack**: What's already in use? (from CLAUDE.md / project config)
- **Scale**: How many users now? Expected in 6-12 months?
- **Team**: Who implements this? (solo dev, small team, multiple teams)
- **Timeline**: How fast does this need to ship?
- **Budget**: Infrastructure cost constraints?
- **Existing systems**: What already exists that we integrate with?

### Step 2: System Design

**Component Diagram** (Mermaid):
```mermaid
graph TD
    Client[Client App] --> API[API Server]
    API --> DB[(Database)]
    API --> Cache[(Cache)]
    API --> Queue[Message Queue]
```

For each component:
- Responsibility (what it does, what it doesn't do)
- Technology choice with reasoning
- Communication protocol (REST, gRPC, WebSocket, events)
- Failure mode (what happens when it's down)

### Step 3: Data Model

**New tables/collections**:
```sql
-- Table: [name]
-- Purpose: [one sentence]
CREATE TABLE [name] (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    -- columns with types and constraints
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

**Modified tables**: What changes to existing schema
**Indexes**: Which queries need optimization
**Migrations**: What SQL migrations are needed (numbered)

### Step 4: API Design

For each new/modified endpoint:
```
[METHOD] /api/v1/[resource]
Purpose: [one sentence]
Auth: required / public
Request: { field: type }
Response: { field: type }
Errors: [list of error codes and when they occur]
```

Follow REST conventions:
- Nouns for resources, verbs via HTTP methods
- Consistent pagination (cursor-based preferred)
- Envelope response format if project uses one
- Idempotency for mutations where needed

### Step 5: Architecture Decision Records (ADRs)

For every significant technical decision:

```markdown
## ADR-NNN: [Decision Title]
**Status**: proposed / accepted / superseded
**Context**: [Why is this decision needed?]
**Options Considered**:
1. [Option A] — pros, cons
2. [Option B] — pros, cons
3. [Option C] — pros, cons
**Decision**: [Which option and WHY]
**Consequences**: [What this means for the codebase]
```

Write an ADR for:
- Technology choices (why this library/framework)
- Data model decisions (why this schema structure)
- Scaling decisions (why this approach over alternatives)
- Security decisions (why this auth/encryption approach)

### Step 6: Implementation Readiness Gate

Before passing to Implementation, verify:
- [ ] All Behavior Contract items have a technical path
- [ ] Data model supports all required queries efficiently
- [ ] API contracts cover all user stories
- [ ] Security considerations documented (auth, input validation, rate limiting)
- [ ] Migration path is clear (no breaking changes without plan)
- [ ] Performance considerations noted (N+1 queries, index strategy)
- [ ] Dependencies identified (external services, libraries, MCP servers)
- [ ] Any execution slices or issue notes that depend on technical hints are updated

**Gate result**: PASS / CONCERNS (list them) / FAIL (blocking issues)

### Step 7: Gate Elicitation Pass

Before presenting the architecture gate, run a `red-team` pass.

Attack the draft architecture from these angles:
- failure modes
- data corruption / migration risk
- security and abuse paths
- rollback hazards
- hidden operational complexity

Record:
- strongest concerns found
- what was changed because of them
- whether any concern still blocks advancement

### Step 8: Update Execution Notes

If the project keeps execution slices or legacy story files, fill in technical hints there.
If it does not, update the issue trail or contract-linked execution notes instead.

Example:
```markdown
## Technical Hints
- DB: workout_sessions table, add column hint_source_preference TEXT
- API: PATCH /api/v1/workout-sessions/:id — add field to request/response
- UI: WorkoutView.swift — add picker component for hint source
- Migration: 026_hint_source_preference.sql
```

## Output Format

```markdown
# Architecture: [Feature Name]
> Date: YYYY-MM-DD
> Behavior Contract: [link]
> Design: [link]
> Status: draft / approved
> Gate: PASS / CONCERNS / FAIL

## System Overview
[Mermaid component diagram]
[Text description of changes to existing architecture]

## Data Model
### New Tables
[SQL DDL]

### Modified Tables
[ALTER statements or description]

### Migrations
| # | File | Description |
|---|------|------------|
| NNN | migrations/NNN_name.sql | ... |

## API Changes
### New Endpoints
[Endpoint specs]

### Modified Endpoints
[What changes]

## ADRs
### ADR-001: [Title]
...

## Security Considerations
- Authentication: ...
- Authorization: ...
- Input validation: ...
- Rate limiting: ...

## Performance Considerations
- Query patterns and indexes
- Caching strategy
- N+1 prevention

## Implementation Readiness
- [ ] All requirements mapped to technical path
- [ ] Data model reviewed
- [ ] API contracts defined
- [ ] Security reviewed
- [ ] Migration path clear
- [ ] Execution notes updated with technical hints
```

## Save To
- Architecture doc: `docs/architecture/YYYY-MM-DD-[feature].md`
- ADRs: `docs/architecture/adr/ADR-NNN-[title].md`

## Tools & MCP
- **Context7 MCP** — look up current library/framework documentation for technology decisions
- **GitHub MCP** — check existing issues, PRs for related technical context

## Anti-patterns
- Architecture without constraints ("design for infinite scale" — always ask about actual needs)
- Choosing technology without ADR (undocumented decisions become mysteries)
- Skipping the Implementation Readiness Gate (leads to architecture-implementation mismatch)
- Over-architecting for current scale (YAGNI — but document when to upgrade)
- Data model without considering query patterns (design for reads, not just writes)
- Missing migration strategy (how do we get from current to target state?)
- Presenting the gate without a red-team pass on failure, security, and rollback risk
