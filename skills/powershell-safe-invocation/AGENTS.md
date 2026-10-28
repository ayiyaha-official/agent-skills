# Local Agent Instructions

These constraints apply while working inside `skills/powershell-safe-invocation`.

## PowerShell Runtime

- Use PowerShell 7.6.1 or newer when running this skill's validation scripts and CJK encoding diagnostics. The parent safe-invocation guidance remains applicable to other supported PowerShell versions.
- For PowerShell 7.6, prefer the MSI package and invoke `pwsh`, normally from `C:\Program Files\PowerShell\7\pwsh.exe`. Check the official installer and executable path for later releases.
- Check Microsoft Store / MSIX path, profile, and remoting limitations before using it for automation.
- Treat Windows PowerShell 5.1 (`powershell.exe`) as a legacy compatibility target, not the normal validation runtime.
- Prefer `pwsh -NoProfile -File ...` for non-interactive execution.

## Source And Encoding

- Keep `.ps1`, `.psm1`, and `.psd1` source files ASCII-only as this repository's portability policy. Put localized content in UTF-8 Markdown or data files; PowerShell 7 itself can run UTF-8 scripts containing localized text.
- Treat terminal-rendered CJK text as untrusted. Verify it through file bytes, structured checks, browser rendering, screenshots, or a known-good UTF-8 diff.
- Do not copy `???`, replacement characters, or mojibake from terminal output into source files, prompts, browser forms, commits, or published artifacts.
- Preserve the safe invocation rules in `SKILL.md` and `reference.md`; encoding hardening must not weaken native argument handling, path validation, or process-startup guidance.
