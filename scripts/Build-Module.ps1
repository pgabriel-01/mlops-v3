<#
.SYNOPSIS
Stages a self-contained MLOpsAccelerator module for the PowerShell Gallery.
.DESCRIPTION
Copies the module, templates, schema, version lock file, example inputs and license into a staging folder.
.PARAMETER Version
The module version, for example 1.2.3 or 1.2.3-preview1.
.PARAMETER OutputPath
The folder that receives the staged module. Defaults to build in the repository root.
.EXAMPLE
./scripts/Build-Module.ps1 -Version 0.2.0

Stages version 0.2.0.
.EXAMPLE
./scripts/Build-Module.ps1 -Version 0.2.0-preview1

Stages a prerelease version.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string] $Version,
    [string] $OutputPath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'build')
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$Version = $Version.TrimStart('v')
if ($Version -notmatch '^(?<core>\d+\.\d+\.\d+)(-(?<pre>[0-9A-Za-z]+))?$') { throw "Version '$Version' must look like 1.2.3 or 1.2.3-preview1." }
$stage = Join-Path $OutputPath 'MLOpsAccelerator'
if (Test-Path $stage) { Remove-Item -Recurse -Force $stage }
New-Item -ItemType Directory -Force $stage | Out-Null

Copy-Item (Join-Path $root 'src/MLOpsAccelerator/*') $stage -Recurse
foreach ($item in 'templates', 'schema') { Copy-Item (Join-Path $root $item) $stage -Recurse }
foreach ($file in 'versions.lock.json', 'inputs.example.yaml', 'LICENSE') { Copy-Item (Join-Path $root $file) $stage }
Get-ChildItem $stage -Recurse -Force -Include '__pycache__', '*.pyc' | Remove-Item -Recurse -Force

$core = $Matches['core']; $pre = $Matches['pre']
$psd1 = Join-Path $stage 'MLOpsAccelerator.psd1'
$text = (Get-Content -Raw $psd1) -replace "(?m)^\s+ModuleVersion\s+=\s+'\d[^']*'\s*$", "    ModuleVersion        = '$core'"
if ($pre) { $text = $text -replace 'PSData = @\{', "PSData = @{ Prerelease = '$pre';" }
Set-Content -Path $psd1 -Value $text -NoNewline -Encoding utf8NoBOM

Test-ModuleManifest $psd1 | Out-Null
Import-Module $psd1 -Force
if (@(Get-MLOpsScenario).Count -ne 11) { throw 'Staged module did not find the 11 scenarios.' }
Remove-Module MLOpsAccelerator
Write-Host "Staged $Version at $stage"
$stage
