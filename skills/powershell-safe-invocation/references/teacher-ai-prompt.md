# 給 AI 助手的 Windows 中文編碼守則

請在這個 Windows 專案中遵守以下規則，避免中文內容在 PowerShell 或終端機中變成亂碼：

執行 PowerShell 腳本時，請使用 PowerShell 7.6.1 以上版本的 `pwsh`。如果安裝 7.6，優先選用 MSI 版；Windows 上可使用：

```powershell
winget install --id Microsoft.PowerShell --source winget --installer-type wix
```

上面的安裝指令適用於仍提供 MSI 的 PowerShell 7.6。升級到更新版本前，請 AI 先查官方安裝方式；微軟表示 7.7 起不提供 MSI。7.6 若省略 `--installer-type wix`，winget 會預設安裝 MSIX。MSIX / Store 版可作為一般互動或政策限制下的備選；使用自動化時要先確認安裝路徑與功能限制。也不要把 Windows 內建的 Windows PowerShell 5.1 `powershell.exe` 當成中文 AI 工作流的主要執行環境。

1. 先確認目前使用的是 MSI 版 `pwsh` 7.x、MSIX / Store 版 `pwsh`、Windows PowerShell 5.1、Git Bash 還是 WSL。
2. 不要把 PowerShell 或終端機顯示出來的中文當成最終正確內容。
3. 如果你看到亂碼、`???`、`�`，不要把那些文字複製回文件、提示語、瀏覽器或任何要保存的地方。
4. 中文內容請以 VS Code 編輯器中的 UTF-8 文件、瀏覽器畫面、可靠的 diff，或能檢查實際 Unicode 內容的工具為準。
5. 不要用 PowerShell inline command、heredoc、`>`、`>>`、`Out-File` 直接產生或保存中文正式內容，除非你已確認 PowerShell 版本、指定編碼，並完成驗證。
6. 如果需要讀寫中文文字檔，請明確使用 UTF-8，例如 `Get-Content -Encoding utf8`、`Set-Content -Encoding utf8`，或使用能明確指定 UTF-8 no BOM 的工具。
7. 若要建立或修改含中文的文件，優先直接編輯 UTF-8 文件，不要從終端機輸出複製中文再貼回檔案。
8. 這套技能的 repo 對 `.ps1`、`.psm1`、`.psd1` 採用 ASCII-only 專案規範；其他專案請先看自己的規範。PowerShell 7 可執行含中文的 UTF-8 腳本，不能只因檔案含中文就判定它已損壞。
9. 在儲存、提交、上傳或發布前，如果曾經出現亂碼，請先停止並重新確認文件內容沒有被污染。

簡短版：

> 使用符合目前版本的 PowerShell 安裝方式；終端機出現亂碼時，先檢查檔案內容。未確認前不要複製亂碼或發布受影響的文字。
