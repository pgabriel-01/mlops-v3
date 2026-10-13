# Local scenario matrix. Renders every scenario (fast) and runs the slow validators
# (terraform init/validate, az bicep build) once per distinct template, not per scenario.
# No model training happens here. Run from the repo root.  Use -Full to validate every scenario.
param([switch]$Full)
Import-Module ./src/MLOpsAccelerator/MLOpsAccelerator.psd1 -Force
$env:TF_PLUGIN_CACHE_DIR = "$env:TMPDIR/tfcache"; New-Item -ItemType Directory -Force $env:TF_PLUGIN_CACHE_DIR | Out-Null
$scen = @(
 @{n='tf-gh-dev';       iac='terraform';cicd='github';envs='[dev]';fs='false';pn='false'},
 @{n='tf-gh-3env-fs';   iac='terraform';cicd='github';envs='[dev, test, prod]';fs='true';pn='false'},
 @{n='tf-azdo-3env-pn'; iac='terraform';cicd='azdo';envs='[dev, test, prod]';fs='false';pn='true'},
 @{n='bi-gh-3env-fs';   iac='bicep';cicd='github';envs='[dev, test, prod]';fs='true';pn='true'},
 @{n='bi-azdo-dev';     iac='bicep';cicd='azdo';envs='[dev]';fs='false';pn='false'},
 @{n='bi-azdo-2env';    iac='bicep';cicd='azdo';envs='[dev, prod]';fs='true';pn='false'})
$validated = @{}; $fail = 0
foreach ($s in $scen) {
 $d = Join-Path $env:TMPDIR "m-$($s.n)"; Remove-Item -Recurse -Force $d -EA SilentlyContinue
 $y = "project_name: demo`nlocation: westeurope`nsubscription_id: 11111111-1111-1111-1111-111111111111`ntenant_id: 22222222-2222-2222-2222-222222222222`niac: $($s.iac)`ncicd: $($s.cicd)`nscenario: tabular`nenvironments: $($s.envs)`nprivate_networking: $($s.pn)`nfeature_store: $($s.fs)`ntags:`n  owner: team-a`n  cost-center: `"1234`"`n"
 $y += if ($s.cicd -eq 'github') { "github_org: o`ngithub_repo: r`n" } else { "azdo_org_url: https://dev.azure.com/o`nazdo_project: p`n" }
 $in = "$env:TMPDIR/$($s.n).yaml"; Set-Content $in $y
 try { Deploy-MLOpsAccelerator -InputFile $in -OutputPath $d -SkipVersionCheck *>$null } catch { "$($s.n): GENFAIL $_"; $fail++; continue }
 $left = @(Get-ChildItem -Recurse -File $d | ? { $_.Name -ne 'taxi-request.json' -and $_.Extension -in '.yml','.tf','.bicep','.bicepparam','.tfvars','.md' } | Select-String '[[' -SimpleMatch).Count
 $r = @("tokens=$left"); if ($left) { $fail++ }
 $targets = @(); if ($s.iac -eq 'terraform') { $targets += 'infra' }; $targets += 'bootstrap'
 foreach ($x in $targets) {
   $key = "tf-$x-$($s.cicd)"; if (-not $Full -and $validated[$key]) { continue }; $validated[$key] = $true
   terraform -chdir="$d/$x" init -backend=false -input=false *>$null
   terraform -chdir="$d/$x" validate -no-color *>$null; $v = $LASTEXITCODE
   terraform -chdir="$d/$x" fmt -check -recursive *>$null; $f = $LASTEXITCODE
   $r += "tf-$x validate=$(if($v){'FAIL'}else{'ok'}) fmt=$(if($f){'FAIL'}else{'ok'})"; if ($v -or $f) { $fail++ }
 }
 if ($s.iac -eq 'bicep' -and ($Full -or -not $validated['bicep'])) {
   $validated['bicep'] = $true; az bicep build --file "$d/infra/main.bicep" --stdout *>$null
   $r += "bicep=$(if($LASTEXITCODE){'FAIL'}else{'ok'})"; if ($LASTEXITCODE) { $fail++ }
 }
 "$($s.n): $($r -join ' | ')"
}
if ($fail) { "FAILED: $fail check(s)"; exit 1 } else { 'ALL OK' }
