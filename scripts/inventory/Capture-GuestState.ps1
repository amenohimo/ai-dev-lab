param(
    [string]$OutputDirectory = '.\.local\inventory'
)

$ErrorActionPreference = 'Stop'

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$out = Join-Path $OutputDirectory "GuestState-$env:COMPUTERNAME-$stamp.txt"

$os = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
$uac = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -ErrorAction SilentlyContinue

$smartApp = $null
try {
    $smartApp = Get-MpComputerStatus | Select-Object SmartAppControlState
} catch {}

$commands = @(
    'git.exe','gh.exe','code.cmd','wt.exe','herdr.exe','codex.exe','grok.exe'
)

$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add("CapturedAt          : $(Get-Date -Format o)")
$lines.Add("ComputerName        : $env:COMPUTERNAME")
$lines.Add("UserName            : $env:USERNAME")
$lines.Add("ProductName         : $($os.ProductName)")
$lines.Add("DisplayVersion      : $($os.DisplayVersion)")
$lines.Add("CurrentBuild        : $($os.CurrentBuild)")
$lines.Add("UBR                 : $($os.UBR)")
$lines.Add("EditionID           : $($os.EditionID)")
$lines.Add("SystemLocale        : $((Get-WinSystemLocale).Name)")
$lines.Add("UICulture           : $((Get-UICulture).Name)")
$lines.Add("Culture             : $((Get-Culture).Name)")
$lines.Add("TimeZone            : $((Get-TimeZone).Id)")
$lines.Add("PowerShellVersion   : $($PSVersionTable.PSVersion)")
$lines.Add("UAC EnableLUA       : $($uac.EnableLUA)")
if ($smartApp) {
    $lines.Add("SmartAppControl     : $($smartApp.SmartAppControlState)")
}

$lines.Add('')
$lines.Add('=== Known Folders ===')
$lines.Add("Desktop             : $([Environment]::GetFolderPath('Desktop'))")
$lines.Add("Documents           : $([Environment]::GetFolderPath('MyDocuments'))")
$lines.Add("Pictures            : $([Environment]::GetFolderPath('MyPictures'))")

$lines.Add('')
$lines.Add('=== Important Commands ===')
foreach ($name in $commands) {
    $cmd = Get-Command $name -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($cmd) {
        $lines.Add("$($cmd.Name) | $($cmd.Source)")
    } else {
        $lines.Add("$name | NOT FOUND")
    }
}

$lines.Add('')
$lines.Add('=== winget list ===')
if (Get-Command winget.exe -ErrorAction SilentlyContinue) {
    try {
        $winget = winget list --accept-source-agreements 2>&1
        foreach ($line in $winget) { $lines.Add([string]$line) }
    } catch {
        $lines.Add("winget list failed: $($_.Exception.Message)")
    }
} else {
    $lines.Add('winget.exe not found')
}

$lines.Add('')
$lines.Add('NOTE: Review this local inventory before publishing. Do not publish credentials or private paths unintentionally.')

$lines | Set-Content -Path $out -Encoding UTF8

Write-Host "Captured guest state:" -ForegroundColor Green
Write-Host $out
