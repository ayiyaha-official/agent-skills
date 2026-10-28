param(
    [string]$OutputPath = ""
)

#requires -Version 7.6

$ErrorActionPreference = "Stop"

$minimumPwshVersion = [version]"7.6.1"
if ($PSVersionTable.PSEdition -ne "Core" -or $PSVersionTable.PSVersion -lt $minimumPwshVersion) {
    throw "PowerShell $minimumPwshVersion or newer is required. Run this script with pwsh."
}

function Get-HexPrefix {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [int]$Count = 32
    )

    $bytes = [System.IO.File]::ReadAllBytes($Path)
    $limit = [Math]::Min($Count, $bytes.Length)
    $parts = New-Object System.Collections.Generic.List[string]

    for ($i = 0; $i -lt $limit; $i++) {
        $parts.Add($bytes[$i].ToString("X2"))
    }

    return ($parts -join " ")
}

function Test-FileWriteEncoding {
    $tempName = "codex-pwsh-encoding-diagnostic-" + [Guid]::NewGuid().ToString("N")
    $tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) $tempName
    New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null

    $text = -join ([char]0x4E2D, [char]0x6587, [char]0x6E2C, [char]0x8A66)

    $defaultPath = Join-Path $tempRoot "set-content-default.txt"
    $utf8Path = Join-Path $tempRoot "set-content-utf8.txt"
    $redirectPath = Join-Path $tempRoot "redirect.txt"
    $dotnetPath = Join-Path $tempRoot "dotnet-utf8-nobom.txt"

    Set-Content -LiteralPath $defaultPath -Value $text
    Set-Content -LiteralPath $utf8Path -Value $text -Encoding utf8
    $text > $redirectPath
    [System.IO.File]::WriteAllText($dotnetPath, $text, [System.Text.UTF8Encoding]::new($false))

    return [ordered]@{
        tempRoot = $tempRoot
        setContentDefaultHex = Get-HexPrefix -Path $defaultPath
        setContentUtf8Hex = Get-HexPrefix -Path $utf8Path
        redirectHex = Get-HexPrefix -Path $redirectPath
        dotnetUtf8NoBomHex = Get-HexPrefix -Path $dotnetPath
    }
}

function Get-PowerShellInstallKind {
    $commandPath = ""
    try {
        $commandPath = (Get-Command pwsh -ErrorAction Stop).Source
    } catch {
        $commandPath = ""
    }

    if ($PSHOME -like "*\WindowsApps\*" -or $commandPath -like "*\WindowsApps\*") {
        return "msix-or-store"
    }

    $msiHit = Get-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue |
        Where-Object {
            ($_.DisplayName -like "PowerShell 7*" -or $_.DisplayName -like "Microsoft PowerShell*") -and
            $_.UninstallString -like "*MsiExec*"
        } |
        Select-Object -First 1

    if ($msiHit) {
        return "msi"
    }

    if ($PSHOME -like "$env:ProgramFiles\PowerShell\7*" -or $commandPath -like "$env:ProgramFiles\PowerShell\7*") {
        return "program-files-unknown-installer"
    }

    return "unknown"
}

$pwshCommandPath = ""
try {
    $pwshCommandPath = (Get-Command pwsh -ErrorAction Stop).Source
} catch {
    $pwshCommandPath = ""
}

$diagnostic = [ordered]@{
    timestampUtc = [DateTime]::UtcNow.ToString("o")
    psEdition = $PSVersionTable.PSEdition
    psVersion = $PSVersionTable.PSVersion.ToString()
    psHome = $PSHOME
    pwshCommandPath = $pwshCommandPath
    installKind = Get-PowerShellInstallKind
    os = $PSVersionTable.OS
    culture = (Get-Culture).Name
    uiCulture = (Get-UICulture).Name
    consoleInputEncoding = [ordered]@{
        webName = [Console]::InputEncoding.WebName
        codePage = [Console]::InputEncoding.CodePage
    }
    consoleOutputEncoding = [ordered]@{
        webName = [Console]::OutputEncoding.WebName
        codePage = [Console]::OutputEncoding.CodePage
    }
    outputEncoding = [ordered]@{
        webName = $OutputEncoding.WebName
        codePage = $OutputEncoding.CodePage
    }
    fileWriteTest = Test-FileWriteEncoding
    guidance = [ordered]@{
        recommendedShell = "PowerShell 7.6.1+; prefer MSI for 7.6 and check official packaging for later releases"
        msixPowerShell = "check path, profile, and remoting limitations before automation"
        windowsPowerShell51 = "legacy compatibility only"
        verifyNonAscii = "Use UTF-8 files, byte checks, structured parsers, browser rendering, or a known-good diff."
    }
}

$json = $diagnostic | ConvertTo-Json -Depth 8

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $json
} else {
    [System.IO.File]::WriteAllText($OutputPath, $json, [System.Text.UTF8Encoding]::new($false))
    Write-Host "Wrote diagnostic JSON to $OutputPath"
}
