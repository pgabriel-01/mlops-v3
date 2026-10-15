<#
.SYNOPSIS
  Installs MLOpsAccelerator from this checkout into your user module path (no PowerShell Gallery needed).
.DESCRIPTION
  Copies the module, templates, schema and version lock file into your user module folder and imports the module.
.PARAMETER Uninstall
  Remove the installed module instead of installing it.
.EXAMPLE
  ./install-local.ps1

  Installs or updates the module.
.EXAMPLE
  ./install-local.ps1 -Uninstall

  Removes the installed module.
#>
[CmdletBinding()]
param([switch] $Uninstall)
$ErrorActionPreference = 'Stop'
$sep = [IO.Path]::PathSeparator
$userRoot = ($env:PSModulePath -split $sep | Where-Object { $_ -like (Join-Path $HOME '*') } | Select-Object -First 1)
if (-not $userRoot) { $userRoot = Join-Path $HOME 'Documents/PowerShell/Modules' }
$target = Join-Path $userRoot 'MLOpsAccelerator'
if (Test-Path $target) { Remove-Item -Recurse -Force $target }
if ($Uninstall) { Write-Host "Removed $target"; return }

if (-not (Get-Module -ListAvailable powershell-yaml)) {
    Install-PSResource -Name powershell-yaml -TrustRepository -ErrorAction Stop
}
New-Item -ItemType Directory -Force $target | Out-Null
Copy-Item (Join-Path $PSScriptRoot 'src/MLOpsAccelerator/*') $target -Recurse
Copy-Item (Join-Path $PSScriptRoot 'templates') $target -Recurse
Copy-Item (Join-Path $PSScriptRoot 'schema') $target -Recurse
Copy-Item (Join-Path $PSScriptRoot 'versions.lock.json') $target
Import-Module $target -Force
Write-Host "Installed $((Get-Module MLOpsAccelerator).Version) to $target"
Write-Host 'Next: New-MLOpsInputFile -Scenario <id> -Path inputs.yaml; Deploy-MLOpsAccelerator -InputFile inputs.yaml'
