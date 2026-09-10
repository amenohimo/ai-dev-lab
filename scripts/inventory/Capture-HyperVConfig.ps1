param(
    [string]$VMName = 'AI-Dev-Lab',
    [string]$OutputDirectory = '.\.local\inventory'
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Command Get-VM -ErrorAction SilentlyContinue)) {
    throw 'Hyper-V PowerShell module is not available. Run this on the Hyper-V host.'
}

$vm = Get-VM -Name $VMName
$memory = Get-VMMemory -VMName $VMName
$processor = Get-VMProcessor -VMName $VMName
$firmware = $null
$security = $null
$network = @()
$drives = @()
$integration = @()

try { $firmware = Get-VMFirmware -VMName $VMName } catch {}
try { $security = Get-VMSecurity -VMName $VMName } catch {}
try { $network = @(Get-VMNetworkAdapter -VMName $VMName) } catch {}
try { $drives = @(Get-VMHardDiskDrive -VMName $VMName) } catch {}
try { $integration = @(Get-VMIntegrationService -VMName $VMName) } catch {}

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$out = Join-Path $OutputDirectory "HyperV-$($VMName)-$stamp.txt"

$lines = [System.Collections.Generic.List[string]]::new()

$lines.Add("CapturedAt                  : $(Get-Date -Format o)")
$lines.Add("VMName                      : $($vm.Name)")
$lines.Add("Generation                  : $($vm.Generation)")
$lines.Add("Version                     : $($vm.Version)")
$lines.Add("State                       : $($vm.State)")
$lines.Add("ProcessorCount              : $($processor.Count)")
$lines.Add("DynamicMemoryEnabled        : $($memory.DynamicMemoryEnabled)")
$lines.Add("StartupMemory               : $($memory.Startup)")
$lines.Add("MinimumMemory               : $($memory.Minimum)")
$lines.Add("MaximumMemory               : $($memory.Maximum)")
$lines.Add("CheckpointType              : $($vm.CheckpointType)")
$lines.Add("AutomaticStartAction        : $($vm.AutomaticStartAction)")
$lines.Add("AutomaticStartDelay         : $($vm.AutomaticStartDelay)")
$lines.Add("AutomaticStopAction         : $($vm.AutomaticStopAction)")

if ($firmware) {
    $lines.Add("SecureBoot                  : $($firmware.SecureBoot)")
    $lines.Add("SecureBootTemplate          : $($firmware.SecureBootTemplate)")
}

if ($security) {
    $lines.Add("TPMEnabled                   : $($security.TpmEnabled)")
    $lines.Add("Shielded                     : $($security.Shielded)")
}

$lines.Add('')
$lines.Add('=== Network Adapters ===')
foreach ($nic in $network) {
    $lines.Add("Name                        : $($nic.Name)")
    $lines.Add("SwitchName                  : $($nic.SwitchName)")
    $lines.Add("MacAddress                  : $($nic.MacAddress)")
    $lines.Add("DynamicMacAddressEnabled    : $($nic.DynamicMacAddressEnabled)")
    $lines.Add("MacAddressSpoofing          : $($nic.MacAddressSpoofing)")
    $lines.Add('---')
}

$lines.Add('')
$lines.Add('=== Virtual Disks ===')
foreach ($drive in $drives) {
    $vhd = $null
    try { $vhd = Get-VHD -Path $drive.Path } catch {}

    $lines.Add("ControllerType              : $($drive.ControllerType)")
    $lines.Add("ControllerNumber            : $($drive.ControllerNumber)")
    $lines.Add("ControllerLocation          : $($drive.ControllerLocation)")
    $lines.Add("VHDFileName                 : $(Split-Path $drive.Path -Leaf)")
    if ($vhd) {
        $lines.Add("VHDType                     : $($vhd.VhdType)")
        $lines.Add("VHDFormat                   : $($vhd.VhdFormat)")
        $lines.Add("VHDSize                     : $($vhd.Size)")
        $lines.Add("VHDFileSize                 : $($vhd.FileSize)")
    }
    $lines.Add('---')
}

$lines.Add('')
$lines.Add('=== Integration Services ===')
foreach ($svc in $integration) {
    $lines.Add("$($svc.Name) | Enabled=$($svc.Enabled) | PrimaryStatus=$($svc.PrimaryStatusDescription)")
}

$lines.Add('')
$lines.Add('NOTE: This file is intended for local inventory first. Review before publishing.')

$lines | Set-Content -Path $out -Encoding UTF8

Write-Host "Captured Hyper-V configuration:" -ForegroundColor Green
Write-Host $out
