# Research-Derived Adoption Plan

**Date:** 2026-03-14  
**Status:** active backlog  
**Input:** [bmad-comparison.md](./bmad-comparison.md), scout queue, Ruflo, audit-workflow pattern, TDD/proof-first pattern

## Goal

Adopt the external ideas that make forge more operational without abandoning the current forge contract.

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

## Already Landed

### A. Behavior Contract model

Done:
- Stage 2 public artifact is now a compact `Behavior Contract`
- Stage 5 became `Proof Hardening` of the same file
- implementation/test_coverage/qa now reference one contract instead of PRD + separate test plan by default

Why it landed:
- direct response to the proof-first / less-files / less-drift direction

### B. One stronger PRODUCT entrypoint

Done:
- `/forge:work` for Claude
- soft equivalent for Codex via business prompt routing
- execution lanes for `micro_change`, `small_change`, `full_feature`

Why it landed:
- aligns with Ruflo/BMAD lesson that the user should not manually drive stage mechanics

### C. Gate elicitation patterns

Done:
- gate template now includes an explicit elicitation section
- orchestrator/playbook define default second-pass methods for high-risk gates
- `strategy` uses inversion
- `Behavior Contract` uses pre-mortem
- `architecture` uses red-team
- `canary_deploy` uses pre-mortem

Why it landed:
- reduces false-confidence gates
- imports the useful BMAD-style second-pass rigor without changing forge's source-of-truth model

### D. Compact execution proposal for long runs

Done:
- checkpoints now support a compact `Execution Proposal` block for long implementation, research, and release-prep runs
- the block captures milestone order, proof per milestone, and a stop-and-fix rule
- forge keeps this inside the existing checkpoint / issue trail model instead of adding `plans.md` or `status.md`

Why it landed:
- imports the useful part of `justdoit` and `big-project-orchestrator` execution discipline
- reduces prompt-dump style handoffs in long Codex/Claude runs
- preserves the fewer-files / one-source-of-truth direction

### E. Stage-agent transport boundary

Done:
- forge now explicitly separates:
  - source of truth (`issue trail`, approved artifacts, `.forge/pipeline-state.yaml`)
  - secondary-agent transport/runtime
- `stage_agents` config documents `transport` as an execution concern, not a process concern
- current runtime is explicitly `local_cli`
- `mcp` and `acp_a2a` are positioned as future transport classes, not as replacements for gates/artifacts

Why it landed:
- preserves the forge process contract while leaving room for richer multi-agent orchestration later
- prevents premature “protocol hype” from rewriting the source-of-truth model
- makes ACP/A2A evaluation concrete: transport for stage agents, not a new process core

### P0: Immediate Rigor and UX Wins

#### 0. Claude smoke on the new contract

Before adding more process:
- run the new `Behavior Contract` flow end-to-end in the pilot product
- verify that Claude routes `small_change` into compact contract + implementation without reverting to PRD/test-plan sprawl

Definition of done:
- one adjacent Claude session completes a real feature/change through the new contract model
- friction points are recorded as a retro

#### 1. Fresh context rule

Make stage isolation explicit instead of implicit.

Candidate surface:
- `core/pipeline/orchestrator.md`

Definition of done:
- docs say each stage must rely on approved artifacts rather than chat residue
- early-stage inline injection and later-stage file access are described as an intentional rule, not an implementation detail

#### 2. Harder review protocol

Strengthen review expectations so "no findings" is exceptional rather than the default.

Candidate surfaces:
- `core/skills/implementation/SKILL.md`
- `core/templates/REVIEW.md.template`

Definition of done:
- review severity is explicit
- zero-findings runs require a second pass or a justification
- the protocol works for both primary-agent review and external reviewer adapters

#### 3. Investigation / audit mode

Adopt the structured investigation pattern from the audit workflow donor:
- `sources`
- `facts`
- `analysis`
- `recommendations`

Candidate surfaces:
- `core/skills/investigate/*`
- issue comment/report templates
- `docs/operating-playbook.md`

Definition of done:
- forge has one reusable compact artifact for deep investigation work
- evidence and conclusions are explicitly separated
- the mode works for product incidents, architecture reviews, and research-heavy discovery

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
- the answer is useful in both Claude and Codex sessions

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

## Not Planned For Now

- Ruflo swarm / queen hierarchy
- self-learning / RL routing
- second persistent state-plane beyond issue trail + `.forge/pipeline-state.yaml`
- strict mandatory TDD for every UI-polish change

## Not Recommended As Direct Goals

Do not frame roadmap around:
- "surpass BMAD on every dimension"
- copying BMAD's project-local monolith
- adding persona flavor as a core architectural primitive

Those may be optional stylistic choices, but they are not sound source-of-truth goals for forge.

## Immediate Next Step

When the current dirty worktree settles, the next real order should be:
1. Claude smoke on the new Behavior Contract flow
2. Investigation / audit mode
3. Harder review protocol
4. Fresh context rule
5. Navigator / help layer
