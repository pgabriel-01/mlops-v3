# Local scenario matrix: renders all 11 AML scenarios for Terraform and Bicep (CI/CD alternates
# between GitHub and Azure DevOps), then validates the IaC. No Azure calls, no model training.
#   -Quick         validate only one Terraform and one Bicep scenario (render everything)
#   -Scenario id   limit to a scenario id or number
#   -Iac terraform|bicep   limit to one IaC flavour
param([switch]$Quick, [string] $Scenario, [ValidateSet('terraform', 'bicep')][string] $Iac)
Import-Module ./src/MLOpsAccelerator/MLOpsAccelerator.psd1 -Force
$tmp = [IO.Path]::GetTempPath()
$env:TF_PLUGIN_CACHE_DIR = Join-Path $tmp "tfcache"; New-Item -ItemType Directory -Force $env:TF_PLUGIN_CACHE_DIR | Out-Null
$scenarios = Get-MLOpsScenario
if ($Scenario) { $scenarios = @(Get-MLOpsScenario -Scenario $Scenario) }
$iacs = if ($Iac) { @($Iac) } else { @('terraform', 'bicep') }
$validatedBootstrap = @{}; $quickDone = @{}; $fail = 0; $i = 0
foreach ($sc in $scenarios) {
    foreach ($flavour in $iacs) {
        $cicd = if (($i++ % 2) -eq 0) { 'github' } else { 'azdo' }
        $name = "$($sc.number)-$($sc.id)-$flavour-$cicd"
        $d = Join-Path $tmp "m-$name"; Remove-Item -Recurse -Force $d -EA SilentlyContinue
        $in = Join-Path $tmp "$name.yaml"
        $null = New-MLOpsInputFile -Scenario $sc.id -Path $in -Iac $flavour -Cicd $cicd -Force
        $r = @()
        try { Deploy-MLOpsAccelerator -InputFile $in -OutputPath $d -SkipVersionCheck *>$null } catch { "${name}: GENFAIL $_"; $fail++; continue }
        $left = @(Get-ChildItem -Recurse -File $d | Where-Object { $_.Extension -in '.yml', '.tf', '.bicep', '.bicepparam', '.tfvars', '.md' } | Select-String '[[' -SimpleMatch).Count
        $r += "tokens=$left"; if ($left) { $fail++ }
        $doValidate = -not $Quick -or -not $quickDone[$flavour]
        if ($doValidate) {
            $quickDone[$flavour] = $true
            if ($flavour -eq 'terraform') {
                terraform -chdir="$d/infra" init -backend=false -input=false *>$null
                terraform -chdir="$d/infra" validate -no-color *>$null; $v = $LASTEXITCODE
                terraform -chdir="$d/infra" fmt -check -recursive *>$null; $f = $LASTEXITCODE
                $r += "tf validate=$(if($v){'FAIL'}else{'ok'}) fmt=$(if($f){'FAIL'}else{'ok'})"; if ($v -or $f) { $fail++ }
            }
            else {
                az bicep build --file "$d/infra/main.bicep" --stdout *>$null; $b = $LASTEXITCODE
                az bicep build-params --file "$d/infra/envs/dev.bicepparam" --stdout *>$null; $p = $LASTEXITCODE
                $r += "bicep=$(if($b){'FAIL'}else{'ok'}) params=$(if($p){'FAIL'}else{'ok'})"; if ($b -or $p) { $fail++ }
            }
        }
        if (-not $validatedBootstrap[$cicd]) {
            $validatedBootstrap[$cicd] = $true
            terraform -chdir="$d/bootstrap" init -backend=false -input=false *>$null
            terraform -chdir="$d/bootstrap" validate -no-color *>$null; $v = $LASTEXITCODE
            terraform -chdir="$d/bootstrap" fmt -check -recursive *>$null; $f = $LASTEXITCODE
            $r += "bootstrap-$cicd validate=$(if($v){'FAIL'}else{'ok'}) fmt=$(if($f){'FAIL'}else{'ok'})"; if ($v -or $f) { $fail++ }
        }
        "${name}: $($r -join ' | ')"
    }
}
if ($fail) { "FAILED: $fail check(s)"; exit 1 } else { 'ALL OK' }
