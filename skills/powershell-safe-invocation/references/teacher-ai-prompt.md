# 给 AI 助手的 Windows 中文编码守则

请在这个 Windows 项目中遵守以下规则，避免中文内容在 PowerShell 或终端中变成乱码：

执行本守则所述的编码诊断脚本与中文/CJK 文件工作流时，请使用 PowerShell 7.6.1 以上版本的 `pwsh`。其他 PowerShell 7 调用场景可依项目支持的版本执行。如果安装 7.6，优先选用 MSI 版；Windows 上可使用：

```powershell
winget install --id Microsoft.PowerShell --source winget --installer-type wix
```

上面的安装指令适用于仍提供 MSI 的 PowerShell 7.6。升级到更新版本前，请 AI 先查官方安装方式；微软表示 7.7 起不提供 MSI。7.6 若省略 `--installer-type wix`，winget 会默认安装 MSIX。MSIX / Store 版可作为一般交互或政策限制下的备选；使用自动化时，要先确认安装路径与功能限制。也不要把 Windows 内置的 Windows PowerShell 5.1 `powershell.exe` 当成中文 AI 工作流的主要运行环境。

1. 先确认目前使用的是 MSI 版 `pwsh` 7.x、MSIX / Store 版 `pwsh`、Windows PowerShell 5.1、Git Bash 还是 WSL。
2. 不要把 PowerShell 或终端显示出来的中文当成最终正确内容。
3. 如果你看到乱码、`???`、`�`，不要把这些文字复制回文件、提示词、浏览器或任何要保存的地方。
4. 中文内容请以 VS Code 编辑器中的 UTF-8 文件、浏览器画面、可靠的 diff，或能检查实际 Unicode 内容的工具为准。
5. 不要用 PowerShell 内联命令、heredoc、`>`、`>>`、`Out-File` 直接生成或保存中文正式内容，除非你已确认 PowerShell 版本、指定编码，并完成验证。
6. 如果需要读写中文文本文件，请明确使用 UTF-8，例如 `Get-Content -Encoding utf8`、`Set-Content -Encoding utf8`，或使用能明确指定 UTF-8 no BOM 的工具。
7. 若要建立或修改含中文的文件，优先直接编辑 UTF-8 文件，不要从终端输出复制中文再粘贴回文件。
8. 这套技能的代码仓库对 `.ps1`、`.psm1`、`.psd1` 采用 ASCII-only 项目规范；其他项目请先看自己的规范。PowerShell 7 可执行含中文的 UTF-8 脚本，不能只因文件含中文就判定它已损坏。
9. 在保存、提交、上传或发布前，如果曾经出现乱码，请先停止并重新确认文件内容没有被污染。

简短版：

> 编码诊断与中文/CJK 工作流建议使用 PowerShell 7.6.1+；一般 PowerShell 7 场景依项目支持版本执行。终端出现乱码时，先检查文件内容。未确认前不要复制乱码或发布受影响的文字。
