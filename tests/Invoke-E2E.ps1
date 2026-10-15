<#
.SYNOPSIS
Manual end-to-end check against a real subscription: generate, bootstrap (plan and apply), then destroy.
.DESCRIPTION
Not run by CI. Creates real Azure, GitHub or Azure DevOps resources and may incur cost. Requires az login and a token.
.PARAMETER InputFile
The inputs file to generate from.
.PARAMETER WorkPath
The folder that receives the generated project.
.PARAMETER KeepResources
Skip the destroy step and keep the bootstrap resources.
.EXAMPLE
./tests/Invoke-E2E.ps1 -InputFile ./inputs.yaml -WorkPath ./e2e-output
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
