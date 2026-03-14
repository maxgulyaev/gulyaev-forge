---
name: scout
description: Evaluate a new tool, framework, MCP server, adapter idea, or workflow candidate for forge. Use during SELF work when the user says "посмотри вот это", "оценим инструмент", or wants to compare whether something should enter today's plan, scout backlog, or the roadmap.
---

# Scout

## Purpose

This skill turns ad-hoc tool discovery into a repeatable forge decision.

Use it to decide whether a new thing should be:
- adopted now
- trialed selectively
- kept in assessment backlog
- put on hold

This is a SELF skill.
It evaluates inputs against forge priorities and invariants instead of treating every interesting tool as something to install.

## When To Use

- The user sends a GitHub repo, tool, framework, MCP, model, adapter, or workflow
- The user asks whether something should be added to forge
- The user wants comparison against current forge capabilities
- The user wants to know whether something belongs in today's plan

## Forge Invariants

Scout decisions must preserve these unless the user explicitly wants to redesign the system:
- `PRODUCT` vs `SELF` split
- three-layer model: forge base skill -> project overlay -> config/adapter
- issue trail and approved artifacts as source of truth
- gate discipline
- role-filtered context
- pragmatic scope control

## Inputs

Read only what is needed:
- the primary source for the candidate tool
- current forge priorities in `docs/design.md`
- current operating model in `docs/operating-playbook.md`
- relevant local skills, templates, scripts, or registry entries already covering similar ground
- `docs/research/scout-queue.md`
- `core/registry/mcp-servers.yaml` when the candidate belongs in the catalog

## Evaluation Process

### 1. Identify the candidate type

Classify the incoming thing as one or more of:
- `mcp`
- `tool`
- `skill-collection`
- `framework`
- `adapter`
- `workflow-pattern`

### 2. Identify its forge contribution type

Mark one or more:
- `role donor` — gives new role intelligence
- `stage donor` — improves a current stage
- `loop donor` — suggests a new loop or post-ship loop
- `tooling donor` — gives new execution capability
- `adapter donor` — improves entry/routing for an agent

### 3. Compare against current forge reality

Ask:
- what exact pain does this solve?
- do we already have this covered locally?
- is it stronger than our current approach or only different?
- is it a donor for selective patterns or a candidate dependency?

### 4. Score against current priorities

A candidate is stronger for *today* if it helps one of:
- MCP setup and operational toolchain
- adapter maturity
- `/init` and scaffolding
- pilot completion on a real feature
- stage rigor for `strategy`, `discovery`, `prd`, `implementation`, `qa`
- documentation/navigation/operator clarity

### 5. Evaluate cost and risk

At minimum consider:
- integration effort
- lock-in to a specific agent or runtime
- overlap with existing forge assets
- maintenance burden
- likelihood of scope drift

### 6. Decide the verdict

Use one:
- `ADOPT` — clear win, aligned with current priorities, should enter the active plan
- `TRIAL` — promising, but should be tried narrowly before becoming core
- `ASSESS` — interesting, but not worth active work today
- `HOLD` — explicitly not now

## Output Format

Use this exact structure in chat:

```text
[Название]
Что это: одно предложение
Тип: mcp / tool / skill-collection / framework / adapter / workflow-pattern
Тип вклада: role donor / stage donor / loop donor / tooling donor / adapter donor
Где полезно в forge: stages / loops / adapters / tooling
С чем сравниваем: текущий forge, похожие инструменты, существующие skills
Плюсы: 2-4 конкретных пункта
Риски / стоимость: 2-4 конкретных пункта
Вердикт: ADOPT / TRIAL / ASSESS / HOLD
План на сегодня: добавить / не добавлять / отложить
Следующее действие: что именно сделать в forge
```

## Recording Rules

After the evaluation:

1. Record the human-readable note in `docs/research/scout-queue.md`
2. If the thing belongs in the technical catalog, add/update `core/registry/mcp-servers.yaml`
3. If the verdict is `ADOPT` or a high-confidence `TRIAL`, link it to the next intended forge change
4. Do not put it into the active roadmap unless it displaces or supports current priorities clearly

## Promotion Rules

### Promote to active roadmap only if:

- it directly advances a current roadmap bottleneck
- or it unlocks a concrete blocked workflow already happening now
- or it materially improves stage quality with low integration cost

### Keep in scout backlog if:

- it is promising but not urgent
- it overlaps existing capabilities
- it implies a broader redesign than today's priorities allow

## Anti-Patterns

- Treating every interesting repo as a must-adopt
- Confusing "many features" with "high leverage for forge"
- Rewriting forge taxonomy to match a donor project wholesale
- Promoting a tool to roadmap before identifying the concrete pain it solves
- Ignoring the difference between donor patterns and core dependencies
