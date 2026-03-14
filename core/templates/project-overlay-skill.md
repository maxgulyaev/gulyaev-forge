# Project Overlay Skill: [Stage]

> Location: `project/.forge/skills/[stage].md`
> Purpose: thin product-specific overlay that augments the forge base skill for one stage.

## Use With

- Base skill: `~/Documents/Dev/gulyaev-forge/core/skills/[stage]/SKILL.md`
- Project config: `project/.forge/config.yaml`
- Current issue / approved artifact for this task

## Product-Specific Priorities

- What matters most for this product at this stage?
- What should the agent optimize for?

## Important Context

- Docs or artifacts that matter especially for this project
- Domain facts that the base skill would not know

## Hard Constraints

- Invariants that must not be broken
- Security / deploy / legal / business rules that override generic defaults

## Avoid / Do Not Touch

- Files, subsystems, or behaviors that are out of scope
- Areas requiring explicit human approval before changes

## Stage-Specific Guidance

- What "good" looks like for this stage in this product
- What mistakes are common in this product

## Tools & MCP

- Which tools are useful here
- Which tools are unnecessary or risky

## Escalation Notes

- When the agent must stop and ask for approval
- Which decisions must go through a gate even if the base skill allows auto-proceed
