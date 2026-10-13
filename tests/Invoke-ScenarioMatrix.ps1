# Local scenario matrix: renders 6 scenarios and runs terraform validate/fmt and az bicep build. Run from repo root.
Import-Module ./src/MLOpsAccelerator/MLOpsAccelerator.psd1 -Force
$env:TF_PLUGIN_CACHE_DIR="/tmp/tfcache"; New-Item -ItemType Directory -Force /tmp/tfcache | Out-Null
$scen = @(
 @{n='tf-gh-dev';      iac='terraform';cicd='github';envs='[dev]';fs='false';pn='false'},
 @{n='tf-gh-3env-fs';  iac='terraform';cicd='github';envs='[dev, test, prod]';fs='true';pn='false'},
 @{n='tf-azdo-3env-pn';iac='terraform';cicd='azdo';envs='[dev, test, prod]';fs='false';pn='true'},
 @{n='bi-gh-3env-fs';  iac='bicep';cicd='github';envs='[dev, test, prod]';fs='true';pn='true'},
 @{n='bi-azdo-dev';    iac='bicep';cicd='azdo';envs='[dev]';fs='false';pn='false'},
 @{n='bi-azdo-2env';   iac='bicep';cicd='azdo';envs='[dev, prod]';fs='true';pn='false'})
foreach($s in $scen){
 $d="/tmp/m-$($s.n)"; Remove-Item -Recurse -Force $d -EA SilentlyContinue
 $y=@"
project_name: demo
location: westeurope
subscription_id: 11111111-1111-1111-1111-111111111111
tenant_id: 22222222-2222-2222-2222-222222222222
iac: $($s.iac)
cicd: $($s.cicd)
scenario: tabular
environments: $($s.envs)
private_networking: $($s.pn)
feature_store: $($s.fs)
tags:
  owner: team-a
  cost-center: "1234"
"@
 if($s.cicd -eq 'github'){$y+="`ngithub_org: o`ngithub_repo: r`n"}else{$y+="`nazdo_org_url: https://dev.azure.com/o`nazdo_project: p`n"}
 Set-Content "/tmp/$($s.n).yaml" $y
 try{ Deploy-MLOpsAccelerator -InputFile "/tmp/$($s.n).yaml" -OutputPath $d -SkipVersionCheck 6>$null }catch{ "GENFAIL $($s.n): $_"; continue }
 $left = Get-ChildItem -Recurse -File $d | ? {$_.Name -ne 'taxi-request.json' -and $_.Extension -in '.yml','.tf','.bicep','.bicepparam','.tfvars','.md'} | Select-String '[[' -SimpleMatch
 "$($s.n): leftover tokens=$(@($left).Count) files=$((Get-ChildItem -Recurse -File $d).Count)"
 $dirs = if($s.iac -eq 'terraform'){'infra','bootstrap'}else{'bootstrap'}
 foreach($x in $dirs){ terraform -chdir="$d/$x" init -backend=false -input=false *>$null; $o=terraform -chdir="$d/$x" validate 2>&1; "  tf $x : $(($o|Select -First 1))"; terraform -chdir="$d/$x" fmt -check -recursive *>$null; if($LASTEXITCODE){"  fmt FAIL $x"} }
 if($s.iac -eq 'bicep'){ $o=az bicep build --file "$d/infra/main.bicep" --stdout 2>&1 | ? {$_ -match 'Error'}; "  bicep errors: $(@($o).Count) $($o|select -first 3)"
   Get-ChildItem "$d/infra/envs" | % { "  param: $($_.Name)" } }
}
