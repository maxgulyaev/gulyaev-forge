# Forge Self

Route this request through `gulyaev-forge` SELF mode in the forge repo.

User request:
$ARGUMENTS

Required behavior:
1. Load `core/skills/self-entry/SKILL.md`.
2. Run self preflight:
   - `bash scripts/forge-doctor.sh self .`
   - `bash scripts/forge-status.sh self .`
3. Read `docs/operating-playbook.md`, `docs/design.md`, and the relevant files under `core/`, `docs/`, or `scripts/`.
4. Treat the request as forge/process/tooling work, not as product implementation.
5. Start with a short preload summary:
   - chosen self submode
   - what context is being loaded
   - what files or scripts are likely affected
6. Carry the change through implementation and verification.
