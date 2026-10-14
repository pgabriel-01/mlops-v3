BeforeDiscovery {
    $script:Cases = foreach ($sc in (Get-Content -Raw (Join-Path (Split-Path -Parent $PSScriptRoot) 'templates/scenarios.json') | ConvertFrom-Json)) {
        foreach ($iac in 'terraform', 'bicep') { @{ id = $sc.id; iac = $iac; endpoint = $sc.endpoint_type; registry = [bool]$sc.registry } }
    }
}
BeforeAll {
    $script:Root = Split-Path -Parent $PSScriptRoot
    Import-Module (Join-Path $Root 'src/MLOpsAccelerator/MLOpsAccelerator.psd1') -Force
    function New-Inputs($iac, $cicd) {
        $y = (Get-Content -Raw (Join-Path $Root 'inputs.example.yaml')) -replace '(?m)^iac:.*', "iac: $iac" -replace '(?m)^cicd:.*', "cicd: $cicd"
        if ($cicd -eq 'azdo') {
            $y = ($y -replace '(?m)^github_org.*\n', '' -replace '(?m)^github_repo.*\n', '') + "`nazdo_org_url: https://dev.azure.com/o`nazdo_project: p`n"
        }
        $f = Join-Path $TestDrive "in-$iac-$cicd.yaml"; Set-Content $f $y; $f
    }
}

Describe 'Generator' {
    It 'renders <iac>/<cicd> with no unresolved tokens' -ForEach @(
        @{ iac = 'terraform'; cicd = 'github' }, @{ iac = 'terraform'; cicd = 'azdo' }
        @{ iac = 'bicep'; cicd = 'github' }, @{ iac = 'bicep'; cicd = 'azdo' }) {
        $out = Join-Path $TestDrive "o-$iac-$cicd"
        Deploy-MLOpsAccelerator -InputFile (New-Inputs $iac $cicd) -OutputPath $out -SkipVersionCheck
        Test-Path (Join-Path $out 'bootstrap/main.tf') | Should -BeTrue
        Test-Path (Join-Path $out 'src/train.py') | Should -BeTrue
        $hits = Get-ChildItem -Recurse -File $out | Where-Object { $_.Name -notlike 'taxi-request.json' -and $_.Extension -in '.yml', '.tf', '.bicep', '.md' } | Select-String -Pattern '\[\[' -SimpleMatch
        $hits | Should -BeNullOrEmpty
    }
    It 'rejects invalid input' {
        $f = Join-Path $TestDrive 'bad.yaml'; Set-Content $f "project_name: X`n"
        { Test-MLOpsAcceleratorInput -InputFile $f } | Should -Throw
    }
    It 'refuses a non-empty output folder' {
        $out = Join-Path $TestDrive 'busy'; New-Item -ItemType Directory $out | Out-Null; Set-Content (Join-Path $out 'x') 'x'
        { Deploy-MLOpsAccelerator -InputFile (New-Inputs terraform github) -OutputPath $out -SkipVersionCheck } | Should -Throw '*not empty*'
    }
    It 'uses only AVM/utility module sources in Terraform infra' {
        $out = Join-Path $TestDrive 'avm-tf'
        Deploy-MLOpsAccelerator -InputFile (New-Inputs terraform github) -OutputPath $out -SkipVersionCheck
        $src = Select-String -Path (Join-Path $out 'infra/main.tf') -Pattern '^\s*source\s*=\s*"([^"]+)"' | ForEach-Object { $_.Matches[0].Groups[1].Value }
        $src | Should -Not -BeNullOrEmpty
        $src | Where-Object { $_ -notmatch '^Azure/(avm-|naming)' } | Should -BeNullOrEmpty
    }
    It 'uses AVM registry modules in Bicep infra' {
        $out = Join-Path $TestDrive 'avm-bicep'
        Deploy-MLOpsAccelerator -InputFile (New-Inputs bicep github) -OutputPath $out -SkipVersionCheck
        $txt = Get-Content -Raw (Join-Path $out 'infra/main.bicep'), (Join-Path $out 'infra/workload.bicep')
        $txt | Should -Match "br/public:avm/res/"
    }
    Context 'Scenarios' {
        It 'has 11 scenarios with unique ids' {
            $all = Get-MLOpsScenario
            $all.Count | Should -Be 11
            ($all.id | Select-Object -Unique).Count | Should -Be 11
        }
        It 'renders scenario <id> for <iac> with the expected files' -ForEach $Cases {
            $f = Join-Path $TestDrive "$id-$iac.yaml"
            $out = Join-Path $TestDrive "o-$id-$iac"
            New-MLOpsInputFile -Scenario $id -Path $f -Iac $iac | Out-Null
            Test-MLOpsAcceleratorInput -InputFile $f | Should -BeTrue
            Deploy-MLOpsAccelerator -InputFile $f -OutputPath $out -SkipVersionCheck
            (Get-ChildItem -Recurse -File $out | Where-Object { $_.Extension -in '.yml', '.tf', '.bicep', '.bicepparam', '.tfvars', '.md' } | Select-String '[[' -SimpleMatch) | Should -BeNullOrEmpty
            Test-Path (Join-Path $out 'mlops/azureml/online-endpoint.yml') | Should -Be ($endpoint -eq 'online')
            Test-Path (Join-Path $out 'mlops/azureml/batch-endpoint.yml') | Should -Be ($endpoint -eq 'batch')
            Test-Path (Join-Path $out '.github/workflows/ml-deploy.yml') | Should -Be ($endpoint -ne 'none')
            Test-Path (Join-Path $out '.github/workflows/ml-promote.yml') | Should -Be $registry
        }
        It 'renders an identity-based ADLS datastore when data_source is adls' {
            $f = Join-Path $TestDrive 'adls.yaml'
            New-MLOpsInputFile -Scenario basic-public -Path $f | Out-Null
            Set-Content $f ((Get-Content -Raw $f) -replace 'data_source: taxi-csv', "data_source: adls`nadls:`n  account_name: stdatalake01`n  container: raw`n  path: taxi/taxi-data.csv")
            $o = Join-Path $TestDrive 'adls-out'
            Deploy-MLOpsAccelerator -InputFile $f -OutputPath $o -SkipVersionCheck *>$null
            Get-Content -Raw (Join-Path $o 'mlops/azureml/datastore.yml') | Should -Match 'account_name: stdatalake01'
            Get-Content -Raw (Join-Path $o 'mlops/azureml/data.yml') | Should -Match 'azureml://datastores/adls_raw/paths/taxi/taxi-data.csv'
        }
        It 'registers the bundled sample as an MLTable data asset' -ForEach @('taxi-csv', 'taxi-parquet') {
            $f = Join-Path $TestDrive "$_.yaml"
            New-MLOpsInputFile -Scenario basic-public -Path $f | Out-Null
            Set-Content $f ((Get-Content -Raw $f) -replace 'data_source: taxi-csv', "data_source: $_")
            $o = Join-Path $TestDrive "$_-out"
            Deploy-MLOpsAccelerator -InputFile $f -OutputPath $o -SkipVersionCheck *>$null
            $d = Get-Content -Raw (Join-Path $o 'mlops/azureml/data.yml')
            $d | Should -Match 'type: mltable'
            $d | Should -Match "path: \.\./\.\./data/$_"
            Test-Path (Join-Path $o "data/$_/MLTable") | Should -BeTrue
            Get-Content -Raw (Join-Path $o 'mlops/azureml/pipeline.yml') | Should -Match 'type: mltable'
        }
        It 'requires the adls object when data_source is adls' {
            $f = Join-Path $TestDrive 'adls-bad.yaml'
            New-MLOpsInputFile -Scenario basic-public -Path $f | Out-Null
            Set-Content $f ((Get-Content -Raw $f) -replace 'data_source: taxi-csv', 'data_source: adls')
            { Test-MLOpsAcceleratorInput -InputFile $f } | Should -Throw
        }
        It 'defaults policy_mode to audit, none for existing-platform, and honours deny' {
            $f = Join-Path $TestDrive 'pol.yaml'
            New-MLOpsInputFile -Scenario byo-vnet -Path $f | Out-Null
            $o = Join-Path $TestDrive 'pol-out'
            Deploy-MLOpsAccelerator -InputFile $f -OutputPath $o -SkipVersionCheck *>$null
            Get-Content -Raw (Join-Path $o 'infra/envs/dev.tfvars') | Should -Match 'policy_mode\s+= "audit"'
            Set-Content $f ((Get-Content -Raw $f) + "policy_mode: deny`n")
            $o2 = Join-Path $TestDrive 'pol-out2'
            Deploy-MLOpsAccelerator -InputFile $f -OutputPath $o2 -SkipVersionCheck *>$null
            Get-Content -Raw (Join-Path $o2 'infra/envs/dev.tfvars') | Should -Match 'policy_mode\s+= "deny"'
            Test-Path (Join-Path $o2 'infra/policy.tf') | Should -BeTrue
            $e = Join-Path $TestDrive 'pol-ep.yaml'
            New-MLOpsInputFile -Scenario existing-platform -Path $e | Out-Null
            $o3 = Join-Path $TestDrive 'pol-out3'
            Deploy-MLOpsAccelerator -InputFile $e -OutputPath $o3 -SkipVersionCheck *>$null
            Get-Content -Raw (Join-Path $o3 'infra/envs/dev.tfvars') | Should -Match 'policy_mode\s+= "none"'
        }
        It 'rejects an invalid policy_mode' {
            $f = Join-Path $TestDrive 'pol-bad.yaml'
            New-MLOpsInputFile -Scenario basic-public -Path $f | Out-Null
            Set-Content $f ((Get-Content -Raw $f) + "policy_mode: block`n")
            { Test-MLOpsAcceleratorInput -InputFile $f } | Should -Throw
        }
        It 'requires existing_platform for the existing-platform scenario' {
            $f = Join-Path $TestDrive 'ep.yaml'
            New-MLOpsInputFile -Scenario existing-platform -Path $f | Out-Null
            $y = (Get-Content -Raw $f) -replace '(?s)existing_platform:.*$', ''
            Set-Content $f $y
            { Test-MLOpsAcceleratorInput -InputFile $f } | Should -Throw
        }
    }
}
