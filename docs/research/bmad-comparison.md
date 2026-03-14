# BMAD Method vs Gulyaev Forge

**Date:** 2026-03-14  
**Status:** research note  
**Source material:** branch `origin/claude/compare-bmad-documentation-P1aIo`, normalized into current forge wording

## Purpose

Compare BMAD Method and Gulyaev Forge to identify:
- where BMAD is currently more operational
- where forge has a structurally different advantage
- which BMAD patterns are worth adopting without breaking forge invariants

This is not a "winner" document. It is a fit-and-gap analysis.

## Short Read

BMAD is ahead on packaging, install flow, user guidance, and operational polish today.

Forge is broader in architecture intent: two operating modes (`PRODUCT` and `SELF`), stricter gate discipline, role-filtered context, explicit issue/state contract, and a full lifecycle target that includes deploy, analytics, and monitoring.

The practical conclusion is not "copy BMAD". It is:
- keep forge's three-layer architecture and issue-driven control surface
- selectively import the BMAD patterns that reduce friction and increase rigor

## Comparison Matrix

| Area | BMAD | Forge now | Practical conclusion |
|---|---|---|---|
| Packaging | Mature installer and CLI-driven setup | Mostly docs + scripts | BMAD is ahead |
| Documentation IA | More complete and easier to navigate | Strong design doc, but still sparse | BMAD is ahead |
| Workflow guidance | Clearer operator experience for first runs | Good concepts, less guided execution | BMAD is ahead |
| Lifecycle scope | Mostly through planning, stories, implementation, review | Strategy through deploy, analytics, monitoring | Forge intent is broader |
| Project footprint | Framework copied into project | Forge core stays centralized, project keeps thin `.forge/` layer | Forge architecture is leaner |
| Context isolation | Less strict | Explicit stage-based injection and inline context for early stages | Forge has a stronger model |
| State contract | Internal workflow conventions | GitHub issue + `.forge/pipeline-state.yaml` + gates | Forge is more explicit |
| Agent posture | More concrete today for supported tools | Wider adapter ambition, but several adapters are still planned | BMAD is ahead operationally |
| Multi-project model | Project-centric | Factory model across multiple products | Forge has a broader operating model |

## Where BMAD Is Stronger Today

### 1. Onboarding and discoverability

BMAD has a clearer "how do I start" story. Forge still depends on reading `README.md`, `QUICKSTART.md`, and stage docs plus remembering the right entry surface.

### 2. Packaging discipline

BMAD feels like a product. Forge still feels like an operating model plus scripts.

### 3. Help and navigation

BMAD exposes a clearer helper layer for users who do not already know the method. Forge still assumes the operator can infer the right stage and command more often than it should.

### 4. Workflow framing

BMAD presents clearer variants for different complexity levels. Forge has `quick path`, but not yet a crisp tiering model that users can see and reason about.

## Where Forge Is Structurally Stronger

### 1. Two operating modes

Forge explicitly separates:
- `PRODUCT` work on a connected product
- `SELF` work on the forge itself

That split is operationally useful and should stay.

### 2. Three-layer architecture

Forge separates:
- forge base skill
- project overlay skill
- project config and adapter shim

That keeps knowledge centralized and avoids copying the whole framework into every product repo.

### 3. Context isolation by role

Forge's current direction is stronger here than BMAD's default pattern:
- stage-specific inject lists
- inline context injection for early stages
- file-tool access deferred until implementation or later

### 4. Explicit gate and issue discipline

Forge has a better defined control plane:
- gated stages require explicit approval
- GitHub issue trail is durable state
- `.forge/pipeline-state.yaml` is local cache, not source of truth

### 5. Full lifecycle target

Forge is not only about getting to merged code. Its design target includes:
- deploy
- canary
- product analytics
- tech monitoring
- feedback back into strategy

That loop should remain a differentiator.

## BMAD Patterns Worth Adopting

### 1. Better elicitation prompts

BMAD's structured second-pass thinking is useful. Forge can adopt this as a gate-quality mechanism:
- pre-mortem
- inversion
- red-team pass
- first-principles pass

### 2. Complexity tracks

Forge should expose clearer paths such as:
- quick
- standard
- enterprise

This would make routing easier to understand and reduce process anxiety for small changes.

### 3. Navigator/help layer

A helper skill that explains "where am I, what is next, why am I blocked" would materially improve first-run usability.

### 4. Better modular packaging

BMAD's modularity suggests a useful forge direction:
- skill packs
- optional stage extensions
- project-declared capabilities

### 5. Stronger documentation information architecture

Forge needs a clearer split between:
- tutorial
- how-to
- explanation
- reference

## Patterns Not Worth Copying Blindly

### 1. Project-local framework monolith

Forge should not give up the centralized-core model just to imitate BMAD packaging.

### 2. Persona-first system design

Named characters can be useful for onboarding tone, but forge's core contract should remain role- and stage-driven rather than personality-driven.

### 3. "Beat BMAD everywhere" framing

That framing is not rigorous enough for source-of-truth docs. The right test is operational usefulness, not rhetorical superiority.

## Recommendation

Use BMAD as a benchmark for operator experience, packaging, and guidance quality.

Do not collapse forge into BMAD's shape. Instead:
- preserve forge's lifecycle breadth and issue discipline
- import selected BMAD patterns where they directly reduce friction or improve rigor
- evaluate each adoption against existing forge invariants before it enters roadmap or templates
