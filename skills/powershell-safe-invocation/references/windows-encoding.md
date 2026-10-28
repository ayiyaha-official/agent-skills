# Windows PowerShell Encoding Guardrails

This reference preserves the Windows encoding source's operating guidance. Its PowerShell 7.6.1+ recommendation applies to the encoding diagnostics and CJK workflows described here; it does not set a minimum version for unrelated safe-invocation tasks.

## Problem

On Windows, Codex may invoke PowerShell in a non-interactive process that does not share the encoding assumptions of the user's terminal, editor, or profile. Even when files and editors are configured for UTF-8, shell output can still be decoded through a legacy code page. This can make Chinese/CJK text appear as mojibake, question marks, or replacement characters.

The dangerous case is not merely ugly output. The dangerous case is using that mangled output as input for a later write, commit, prompt, browser automation step, or publish action.

## Runtime Dependency

Use PowerShell 7.6.1 or newer for these encoding validation scripts and examples. For PowerShell 7.6, prefer the MSI installation when available. Invoke it as `pwsh`, preferably from `C:\Program Files\PowerShell\7\pwsh.exe`, not Windows PowerShell 5.1 (`powershell.exe`). Check packaging and path assumptions for later releases.

PowerShell 7.6.1 reduces many default encoding pitfalls by using UTF-8-oriented defaults, but it does not make terminal rendering, external tools, legacy Big5 files, or copy/paste workflows automatically safe. Keep the guardrails below even when using `pwsh`.

Recommend PowerShell 7.6 MSI to users who will process Chinese/CJK files or run AI-generated PowerShell on Windows with 7.6. Windows PowerShell 5.1 should be treated as a legacy compatibility target. For later releases, check the officially available package and test MSIX path, profile, and remoting limitations before automation.

Preferred MSI install command:

```powershell
winget install --id Microsoft.PowerShell --source winget --installer-type wix
```

Plain `winget install --id Microsoft.PowerShell --source winget` can install MSIX on current Windows releases. Specify `--installer-type wix` when the goal is the MSI route.

Microsoft states that PowerShell 7.7 will not have an MSI package. Check the official installation documentation for the target version before giving upgrade instructions; do not assume the 7.6 MSI command will continue to work.

## Environment Split

Do not diagnose Windows encoding problems as one generic "PowerShell" problem. First identify the runtime.

Run:

```powershell
$PSVersionTable.PSVersion
$PSHOME
(Get-Command pwsh).Source
[Console]::InputEncoding
[Console]::OutputEncoding
$OutputEncoding
```

Use the result this way:

- PowerShell 7.6 MSI: recommended on 7.6. It normally lives under `C:\Program Files\PowerShell\7`. Default file writes and PowerShell redirection are generally UTF-8-oriented, but native-command boundaries, terminal rendering, old Big5 data, and copy/paste are still risk areas.
- PowerShell 7.6 MSIX / Store: UTF-8 behavior is still PowerShell 7, but the packaged-app environment can affect paths, profiles, all-users settings, remoting, and automation assumptions. Treat `$PSHOME` or command paths under `WindowsApps` as an MSIX signal; check official packaging for later releases.
- Windows PowerShell 5.1: high risk. Default `Set-Content` can use the system ANSI code page, `Out-File` and redirection can write UTF-16LE, and `$OutputEncoding` may affect native-command communication differently from file cmdlets.
- Git Bash: often UTF-8-friendly, but calling Windows-native tools can cross back into Windows code page behavior.
- WSL: usually the cleanest UTF-8 environment, but invoking Windows executables or moving text across the WSL/Windows boundary reintroduces Windows encoding risk.

If the user is not sure which shell they are using, ask them to run the diagnostic script:

```powershell
pwsh -NoProfile -File .\scripts\diagnose-powershell-encoding.ps1
```

## Rules

- Treat PowerShell terminal rendering as a lossy display surface for non-ASCII text.
- Do not copy terminal-rendered Chinese/CJK text back into files, prompts, or browser forms.
- Do not use `Get-Content` output displayed in the terminal as proof that a UTF-8 file is correct.
- If `???`, `�`, or mojibake appears, inspect the underlying bytes or Unicode text before saving or publishing the affected content. Console display alone does not establish file corruption.
- This repository avoids raw Chinese/CJK text in PowerShell inline commands, heredocs, and `.ps1` source. Other projects can permit UTF-8 literals when their encoding boundary is verified.
- Do not use `>`, `>>`, `Out-File`, `Set-Content`, or `Add-Content` to write localized text unless the encoding is explicit and the result is verified outside terminal rendering.
- Prefer UTF-8 files as the boundary for localized content.
- This repository prefers ASCII-only `.ps1` source for portability. That is a project policy, not a PowerShell 7 requirement; UTF-8 scripts may contain localized text when the target project permits it.

## Trustworthy Sources

Use these as source of truth for non-ASCII text:

- a UTF-8 file read by a tool that preserves bytes correctly
- a browser-rendered page or screenshot
- a parser or test that checks exact file bytes or exact Unicode code points
- `git diff` viewed in an environment known to render UTF-8 correctly
- application output written to a UTF-8 artifact file, not only the terminal

## Safer PowerShell Patterns

Read UTF-8 text explicitly:

```powershell
$text = Get-Content -LiteralPath $path -Raw -Encoding utf8
```

Write UTF-8 text explicitly:

```powershell
Set-Content -LiteralPath $path -Value $text -Encoding utf8
```

For cross-version BOM-less UTF-8 writes, use a .NET API that states the encoding directly:

```powershell
[System.IO.File]::WriteAllText($path, $text, [System.Text.UTF8Encoding]::new($false))
```

Append UTF-8 text explicitly:

```powershell
Add-Content -LiteralPath $path -Value $text -Encoding utf8
```

Avoid ambiguous redirection for localized text:

```powershell
# Avoid for CJK/localized text:
# "..." > file.txt
# "..." >> file.txt
```

For `pwsh` 7.6.1+, redirection is much safer than it was in Windows PowerShell 5.1. Still avoid using redirection as the first choice for localized source content because an AI assistant may later repeat the pattern in a legacy shell or a no-profile wrapper.

For legacy Windows PowerShell 5.1 compatibility checks, be aware that `-Encoding utf8` writes UTF-8 with BOM. Normal project work should use `pwsh` 7.6.1 or newer. If exact BOM-less UTF-8 is required, use a runtime or API that can specify BOM-less UTF-8 explicitly.

When piping localized text through external programs, align the console encodings before the boundary:

```powershell
[Console]::InputEncoding = [System.Text.UTF8Encoding]::new()
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
$OutputEncoding = [Console]::OutputEncoding
```

Do not rely on profile initialization for non-interactive AI CLI execution. If an agent calls PowerShell through a wrapper, put the encoding initialization inside the wrapper command or script itself.

Decode small embedded strings from Base64:

```powershell
$bytes = [Convert]::FromBase64String($base64)
$text = [System.Text.Encoding]::UTF8.GetString($bytes)
```

## Safer Agent Behavior

When acting as Codex:

1. Search and inspect files with tools that preserve enough context, but do not trust terminal-rendered CJK as final verification.
2. Use patches for source edits.
3. Follow the target project's PowerShell source policy. Keep source ASCII-only in this repository.
4. Store non-ASCII payloads in separate UTF-8 files when the task needs localized text.
5. Validate with exact checks, browser rendering, screenshots, or diffs.
6. Prefer PowerShell 7.6 MSI for 7.6 validation and examples; check official packaging for later releases.
7. If the active `pwsh` is MSIX / Store, mention the packaging risk and avoid assuming all-users settings, remoting, or stable automation paths.
8. Avoid Windows PowerShell 5.1 unless the user explicitly needs legacy compatibility.
9. Mention any residual risk if the only available check was terminal output.

## Red Flags

Stop and re-check before writing or committing when any of these appear:

- `???` replacing localized text
- replacement characters such as `�`
- mojibake patterns after reading a known UTF-8 file
- non-ASCII text copied through a PowerShell inline command
- a `.ps1` file that contains direct localized strings
- localized text written with `>`, `>>`, `Out-File`, `Set-Content`, or `Add-Content` without an explicit encoding and verification step
- browser automation that pastes text captured from terminal output

## Portable Check

This skill includes `scripts/diagnose-powershell-encoding.ps1`. Run it to inspect the active PowerShell version and console encodings:

```powershell
pwsh -NoProfile -File .\scripts\diagnose-powershell-encoding.ps1
```

This skill also includes `scripts/assert-no-nonascii-ps1.ps1`. Run it from this repo root to enforce this repo's ASCII-only PowerShell source policy; use it in another repo only if that repo adopts the policy:

```powershell
pwsh -NoProfile -File .\scripts\assert-no-nonascii-ps1.ps1
```

Run it with explicit roots or extensions from an active PowerShell session:

```powershell
& .\scripts\assert-no-nonascii-ps1.ps1 -Path .\tools, .\scripts
& .\scripts\assert-no-nonascii-ps1.ps1 -Extension .ps1, .psm1, .psd1
```

When launching with `pwsh -File`, pass one comma-free value for each array parameter and invoke the script again for additional values. Comma-separated values are not parsed as PowerShell parameter arrays across the executable boundary.
