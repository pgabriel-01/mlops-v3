<#
.SYNOPSIS
Manual end-to-end check against a real subscription: generate, bootstrap (plan + apply), then destroy.
.DESCRIPTION
Not run by CI. Creates real Azure and GitHub/Azure DevOps resources and may incur cost. Requires az login and a token.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string] $InputFile,
    [Parameter(Mandatory)][string] $WorkPath,
    [switch] $KeepResources
)
Import-Module (Join-Path (Split-Path -Parent $PSScriptRoot) 'src/MLOpsAccelerator/MLOpsAccelerator.psd1') -Force
$req = Test-MLOpsAcceleratorRequirement
$req | Format-Table
if ($req | Where-Object { $_.Required -and -not $_.Passed }) { throw 'Requirements not met.' }
Deploy-MLOpsAccelerator -InputFile $InputFile -OutputPath $WorkPath -Deploy -AutoApprove -Force
if (-not $KeepResources) { Remove-MLOpsAccelerator -InputFile $InputFile -ProjectPath $WorkPath -AutoApprove -Confirm:$false }
