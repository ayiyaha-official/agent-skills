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
    $tempBase = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
    $tempRoot = [System.IO.Path]::GetFullPath((Join-Path $tempBase $tempName))
    if (-not $tempRoot.StartsWith($tempBase, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to create diagnostic files outside the temporary directory: $tempRoot"
    }

    New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null

    try {
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
            setContentDefaultHex = Get-HexPrefix -Path $defaultPath
            setContentUtf8Hex = Get-HexPrefix -Path $utf8Path
            redirectHex = Get-HexPrefix -Path $redirectPath
            dotnetUtf8NoBomHex = Get-HexPrefix -Path $dotnetPath
        }
    }
    finally {
        if (Test-Path -LiteralPath $tempRoot) {
            Remove-Item -LiteralPath $tempRoot -Recurse -Force
        }
    }
}

function Get-VersionCore {
    param(
        [AllowNull()]
        [string]$Version
    )

    if ([string]::IsNullOrWhiteSpace($Version)) {
        return ""
    }

    try {
        $parsed = [version]($Version.Trim())
        return "{0}.{1}.{2}" -f $parsed.Major, $parsed.Minor, $parsed.Build
    } catch {
        return ""
    }
}

function Get-PowerShellInstallKind {
    $processPath = [Environment]::ProcessPath
    $runtimePaths = @($PSHOME, $processPath) | Where-Object {
        -not [string]::IsNullOrWhiteSpace($_)
    }

    if ($runtimePaths | Where-Object { $_ -like "*\WindowsApps\*" }) {
        return "msix-or-store"
    }

    $programFilesRoot = [System.IO.Path]::GetFullPath((Join-Path $env:ProgramFiles "PowerShell"))
    $programFilesPrefix = $programFilesRoot.TrimEnd(
        [System.IO.Path]::DirectorySeparatorChar,
        [System.IO.Path]::AltDirectorySeparatorChar
    ) + [System.IO.Path]::DirectorySeparatorChar
    $runsFromProgramFiles = $runtimePaths | Where-Object {
        [System.IO.Path]::GetFullPath($_).StartsWith(
            $programFilesPrefix,
            [System.StringComparison]::OrdinalIgnoreCase
        )
    }

    if (-not $runsFromProgramFiles) {
        return "unknown"
    }

    $currentVersion = Get-VersionCore -Version $PSVersionTable.PSVersion.ToString()
    $msiHit = Get-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue |
        Where-Object {
            ($_.DisplayName -like "PowerShell 7*" -or $_.DisplayName -like "Microsoft PowerShell*") -and
            $_.UninstallString -like "*MsiExec*" -and
            (Get-VersionCore -Version $_.DisplayVersion) -eq $currentVersion
        } |
        Select-Object -First 1

    if ($msiHit) {
        return "msi"
    }

    return "program-files-unknown-installer"
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
    processPath = [Environment]::ProcessPath
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
