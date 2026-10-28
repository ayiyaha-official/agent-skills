# Maintaining PowerShell Safe Invocation

This reference is for maintainers. Normal skill use does not require reading it.

## Invariants

- Preserve the safe invocation rules in `SKILL.md` and `references/safe-invocation.md`. Encoding changes must not weaken native argument boundaries, path validation, or process-startup guidance.
- Keep PowerShell 7.6.1+ scoped to encoding diagnostics and CJK workflows; do not turn it into a minimum version for every PowerShell 7 task.
- Keep PowerShell source files ASCII-only as this repository's portability policy, not as a PowerShell 7 runtime requirement.
- Treat terminal-rendered non-ASCII text as untrusted and verify important content through bytes, structured parsing, rendering, or a reliable diff.
- Keep one `SKILL.md` entrypoint with detailed guidance routed through focused references and scripts.
- Keep maintainer-only rules here rather than recreating a nested `AGENTS.md`.

## Validation Checklist

Run these checks from the skill directory with PowerShell 7.6.1 or newer:

```powershell
python <path-to-skill-creator>\scripts\quick_validate.py .
pwsh -NoProfile -File .\scripts\assert-no-nonascii-ps1.ps1
pwsh -NoProfile -File .\scripts\diagnose-powershell-encoding.ps1 -OutputPath "$env:TEMP\powershell-encoding-diagnostic.json"
```

After the diagnostic run:

- Parse the JSON output and confirm the PowerShell version, install kind, and encoding fields.
- Confirm the diagnostic did not leave a `codex-pwsh-encoding-diagnostic-*` directory behind.
- Run `git diff --check` and review the complete diff.
- Confirm all paths referenced by `SKILL.md` exist and no second skill entrypoint was introduced.
