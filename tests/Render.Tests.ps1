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
}
