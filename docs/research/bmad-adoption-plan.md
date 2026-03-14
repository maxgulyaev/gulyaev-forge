# BMAD-Derived Adoption Plan

**Date:** 2026-03-14  
**Status:** draft backlog  
**Input:** [bmad-comparison.md](./bmad-comparison.md)

## Goal

Adopt the BMAD ideas that make forge more operational without abandoning the current forge contract.

This is a selective adoption plan, not a rewrite.

## Forge Invariants To Preserve

Any BMAD-inspired change should preserve:
- `PRODUCT` vs `SELF` split
- three-layer model: base skill -> project overlay -> config/adapter
- issue trail as durable source of truth
- explicit gate discipline
- role-filtered context rather than broad project visibility
- low-dependency operation as a default

## Recommended Work Packages

### P0: Immediate Rigor and UX Wins

#### 1. Gate elicitation patterns

Add a lightweight mandatory second-pass thinking step to gated stages.

Candidate surfaces:
- `core/templates/gate-template.md`
- `core/pipeline/orchestrator.md`

Candidate methods:
- pre-mortem
- inversion
- red-team pass
- first-principles pass

Definition of done:
- gate format says when elicitation is expected
- at least `strategy`, `prd`, `architecture`, and `canary_deploy` have a documented default method

#### 2. Fresh context rule

Make stage isolation explicit instead of implicit.

Candidate surface:
- `core/pipeline/orchestrator.md`

Definition of done:
- docs say each stage must rely on approved artifacts rather than chat residue
- early-stage inline injection and later-stage file access are described as an intentional rule, not an implementation detail

#### 3. Harder review protocol

Strengthen review expectations so "no findings" is exceptional rather than the default.

Candidate surfaces:
- `core/skills/implementation/SKILL.md`
- `core/templates/REVIEW.md.template`

Definition of done:
- review severity is explicit
- zero-findings runs require a second pass or a justification
- the protocol works for both primary-agent review and external reviewer adapters

### P1: Operator Experience Improvements

#### 4. Complexity tracks

Expose clearer pipeline modes:
- quick
- standard
- enterprise

Candidate surfaces:
- `core/pipeline/orchestrator.md`
- `docs/operating-playbook.md`
- `QUICKSTART.md`

Definition of done:
- routing rules say when each track applies
- skip rules and extra stages are documented per track

#### 5. Navigator / help layer

Add a skill or documented entry surface that answers:
- where am I
- what is the next valid move
- why am I blocked
- which artifact or gate is missing

Candidate shape:
- `core/skills/navigator/SKILL.md`

Definition of done:
- operator can ask status/help without already knowing forge internals

#### 6. Multi-perspective review

Formalize structured review perspectives for high-risk gates.

Candidate shape:
- dedicated review skill or embedded protocol for `strategy`, `prd`, `architecture`, and deploy gates

Definition of done:
- at least one reusable protocol exists for multi-perspective analysis
- verdict is consolidated rather than left as scattered commentary

### P2: Packaging and Extensibility

#### 7. Skill packs

Allow projects to opt into additional stage bundles or specialized review layers without copying forge core.

Candidate surfaces:
- registry metadata under `core/registry/`
- project config schema in `core/templates/project-context.yaml`

Definition of done:
- a project can declare optional packs in config
- pack behavior is documented without breaking the base contract

#### 8. Forge CLI and `/init`

BMAD's installer experience highlights a current forge weakness.

Candidate surfaces:
- `scripts/`
- future `bin/forge`

Definition of done:
- bootstrap and validation require fewer manual steps
- `/init` or equivalent scaffolding becomes repeatable and documented

#### 9. Documentation IA

Reorganize documentation into clearer user-facing layers:
- tutorial
- how-to
- explanation
- reference

Definition of done:
- a new user can start without reading the whole design doc first

## Not Recommended As Direct Goals

Do not frame roadmap around:
- "surpass BMAD on every dimension"
- copying BMAD's project-local monolith
- adding persona flavor as a core architectural primitive

Those may be optional stylistic choices, but they are not sound source-of-truth goals for forge.

## Immediate Next Step

When the current dirty worktree settles, promote the top P0 items into the main roadmap in `docs/design.md` if they still align with active priorities.
