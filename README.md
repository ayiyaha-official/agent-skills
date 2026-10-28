# agent-skills

A personal collection of reusable AI agent skills and MCP-related utilities.

这个仓库用于收集个人日常使用中沉淀下来的 agent skills，包括网页读取、命令行调用规范、自动化流程、工具集成经验等。内容以可直接复制使用的 `SKILL.md` 为主，后续也可能加入 MCP server 配置和示例。

## 安装

复制需要的 skill 到通用的 `.agents/skills` 技能目录即可，支持该目录的 agent 可以共享同一份安装。

### 通用安装

推荐使用 PowerShell 7+ (`pwsh`)。`powershell-safe-invocation` skill 针对现代 PowerShell 行为编写，尤其关注原生命令参数传递、路径、引号、编码和进程启动。

- 安装指南：[Install PowerShell](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell)
- 发布页面：[PowerShell GitHub Releases](https://github.com/PowerShell/PowerShell/releases)

```powershell
$repo = (Get-Location).Path
$target = "$env:USERPROFILE\.agents\skills"

New-Item -ItemType Directory -Force -Path $target | Out-Null
Copy-Item -LiteralPath "$repo\skills\bilibili-page-reader" -Destination $target -Recurse -Force
Copy-Item -LiteralPath "$repo\skills\powershell-safe-invocation" -Destination $target -Recurse -Force
Copy-Item -LiteralPath "$repo\skills\locus-unity-bridge" -Destination $target -Recurse -Force
```

### 自定义技能目录

如果你的 agent 不支持 `~/.agents/skills`，把 `$target` 改成它使用的技能目录即可。

## powershell-safe-invocation 的运行与编码检查

`powershell-safe-invocation` 负责两类相互关联的 Windows 风险：一是安全地组织 PowerShell 调用、原生命令参数、路径和进程启动；二是避免 UTF-8、中文/CJK 文本和终端渲染造成的乱码或内容污染。

这个 skill 的主体适用于 PowerShell 7。它的编码诊断脚本和中文/CJK 验证建议使用 PowerShell 7.6.1 或更新版本：

- PowerShell 7.6 优先使用 MSI 安装：`winget install --id Microsoft.PowerShell --source winget --installer-type wix`。
- 未指定 `--installer-type wix` 时，winget 可能安装 MSIX/Store 版本；用于自动化前应确认路径、profile 和 remoting 限制。
- `powershell.exe` 是 Windows PowerShell 5.1，只作为兼容性目标；正常的中文/CJK 自动化优先使用 `pwsh`。
- 本仓库对 `.ps1`、`.psm1`、`.psd1` 采用 ASCII-only 的保守可移植性规范。这不是 PowerShell 7 本身的硬性限制；其他项目应按自己的源码规范执行。

从 `skills/powershell-safe-invocation` 目录运行：

```powershell
pwsh -NoProfile -File .\scripts\assert-no-nonascii-ps1.ps1
pwsh -NoProfile -File .\scripts\diagnose-powershell-encoding.ps1 -OutputPath "$env:TEMP\powershell-encoding-diagnostic.json"
```

诊断脚本会输出 PowerShell 版本、安装类型、控制台编码、`$OutputEncoding` 和文件写入测试的十六进制前缀。终端中显示的中文不是最终真值；应以 UTF-8 文件字节、结构化解析、浏览器/截图或可靠 diff 验证内容。

## bilibili-page-reader 的工作环境与依赖

`bilibili-page-reader` 用来读取 Bilibili 视频页内容：优先获取投稿字幕、弹幕摘要和评论；如果没有投稿字幕，再走音频下载和本地 ASR 转写。

运行这个 skill 主要依赖这几类工具：

- [Kimi WebBridge](https://www.kimi.com/zh-cn/features/webbridge)：让 agent 访问真实浏览器页面，用于读取当前 Bilibili 页面状态和登录后可见内容。
- [Bilibili Evolved](https://github.com/the1812/Bilibili-Evolved)：提供投稿字幕、弹幕等页面内数据来源。
- Node.js：用于请求 Bilibili playurl API 和下载音频流。
- `ffmpeg` / `ffprobe`：用于音频格式转换和时长读取。
- Python + [FunASR](https://github.com/modelscope/FunASR)：无投稿字幕时，把下载到的音频转写成 SRT/VTT/JSON。

相关辅助文件：

- `skills/bilibili-page-reader/audio2srt.py`：音频转字幕脚本。
- `skills/bilibili-page-reader/clean_srt.py`：SRT 清理脚本。
- `skills/bilibili-page-reader/agents/openai.yaml`：agent 界面元数据。

更具体的执行步骤、兜底策略和常见问题写在 `skills/bilibili-page-reader/SKILL.md` 中。

## locus-unity-bridge 的工作环境与依赖

`locus-unity-bridge` 用于通过 [Locus](https://github.com/r1n7aro/Locus) 检测并控制真实 Unity Editor，运行环境是 Windows 和 PowerShell 7。实际连接需要目标 Unity 项目已经安装 Locus package，并启用对应项目的 Bridge。

skill 会先通过 `probe` 区分缺少 package、Bridge 未启用和 Unity 不可达等状态；缺少 package 时只提供诊断，不会自动安装或修改项目。

## 可用 Skills

| Skill | 说明 |
| --- | --- |
| [`bilibili-page-reader`](skills/bilibili-page-reader/) | 读取 Bilibili 视频页，包括投稿字幕、弹幕摘要、评论；无字幕时可通过 FunASR 下载音频并转写。 |
| [`locus-unity-bridge`](skills/locus-unity-bridge/) | 通过 Locus 检测并控制真实 Unity Editor，支持项目/package/Bridge 诊断、C# 执行和脚本重新编译。 |
| [`powershell-safe-invocation`](skills/powershell-safe-invocation/) | Windows agent 的安全 PowerShell 调用规范，覆盖原生命令参数、路径、引号、进程启动、UTF-8/CJK 编码防护和乱码诊断。 |

## 仓库结构

```text
skills/   可复用的 agent skills
mcp/      预留给未来的 MCP servers、配置和示例
```

每个 skill 都放在独立目录中，并以 `SKILL.md` 作为入口。有些 skill 还会包含辅助脚本、示例或 agent 专用元数据。

## Sources and attribution

`skills/powershell-safe-invocation` 的整合来源：

- 基础 skill：[Misaka-Mikoto-Tech/agent-skills](https://github.com/Misaka-Mikoto-Tech/agent-skills) 中的 `skills/powershell-safe-invocation`，保留其安全调用规则，并将详细说明整理为 `references/safe-invocation.md`。
- Windows 编码守卫与诊断：[chianwu-hash/windows-powershell-encoding-skill](https://github.com/chianwu-hash/windows-powershell-encoding-skill)，其 guardrails、教师提示词和两个 PowerShell 脚本按本仓库的单一入口结构迁入。

encoding 来源仓库未声明许可证字段；本仓库不把该来源单独标注为 MIT。其内容按用户请求整合，并在此保留来源归属。本仓库自身的 MIT 许可证见 [LICENSE](LICENSE)。

## 许可证

[MIT](LICENSE)
