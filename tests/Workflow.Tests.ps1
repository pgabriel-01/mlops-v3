BeforeAll {
    $script:Root = Split-Path -Parent $PSScriptRoot
    Import-Module (Join-Path $Root 'src/MLOpsAccelerator/MLOpsAccelerator.psd1') -Force
}

Describe 'Requirements check' {
    It 'returns named checks with Passed and Required' {
        $r = @(Test-MLOpsAcceleratorRequirement -Cicd github -Iac bicep)
        $r.Name | Should -Contain 'terraform'
        $r.Name | Should -Contain 'Bicep (az bicep)'
        ($r | Where-Object Name -EQ 'PowerShell 7.4+').Passed | Should -BeTrue
    }
    It 'checks the Azure DevOps token for azdo' {
        $old = $env:AZDO_PERSONAL_ACCESS_TOKEN; $env:AZDO_PERSONAL_ACCESS_TOKEN = $null
        try { (Test-MLOpsAcceleratorRequirement -Cicd azdo | Where-Object Name -EQ 'Azure DevOps token').Passed | Should -BeFalse }
        finally { $env:AZDO_PERSONAL_ACCESS_TOKEN = $old }
    }
}

Describe 'Upgrade and cleanup guards' {
    BeforeAll {
        $script:f = Join-Path $TestDrive 'in.yaml'
        New-MLOpsInputFile -Scenario basic-public -Path $f | Out-Null
        $script:out = Join-Path $TestDrive 'proj'
        Deploy-MLOpsAccelerator -InputFile $f -OutputPath $out -SkipVersionCheck *>$null
    }
    It 'emits LF-only text files (pipelines run on Linux agents)' {
        $crlf = Get-ChildItem -Recurse -File $out -Include *.yml, *.tf, *.bicep, *.py, *.md | Where-Object { (Get-Content -Raw $_.FullName) -match "`r" }
        @($crlf).Count | Should -Be 0
    }
    It 'refuses a non-empty folder without -Force or -Upgrade' {
        { Deploy-MLOpsAccelerator -InputFile $f -OutputPath $out -SkipVersionCheck } | Should -Throw '*not empty*'
    }
    It 'regenerates an existing project with -Upgrade' {
        Remove-Item (Join-Path $out 'src/train.py')
        Deploy-MLOpsAccelerator -InputFile $f -OutputPath $out -SkipVersionCheck -Upgrade *>$null
        Test-Path (Join-Path $out 'src/train.py') | Should -BeTrue
    }
    It 'rejects -Upgrade on a folder that is not a project' {
        $other = Join-Path $TestDrive 'other'; New-Item -ItemType Directory $other | Out-Null; Set-Content (Join-Path $other 'x.txt') 'x'
        { Deploy-MLOpsAccelerator -InputFile $f -OutputPath $other -SkipVersionCheck -Upgrade } | Should -Throw '*not an MLOps v3 project*'
    }
    It 'Remove-MLOpsAccelerator rejects a non-project folder' {
        { Remove-MLOpsAccelerator -InputFile $f -ProjectPath $TestDrive -Confirm:$false } | Should -Throw '*not an MLOps v3 project*'
    }
    It 'Remove-MLOpsAccelerator honours -WhatIf' {
        { Remove-MLOpsAccelerator -InputFile $f -ProjectPath $out -WhatIf } | Should -Not -Throw
        Test-Path $out | Should -BeTrue
    }
}

Describe 'Interactive input' {
    It 'writes an inputs file from prompts' {
        $script:answers = [System.Collections.Queue]::new(@('managed-vnet-approved', 'bicep', 'azdo', 'demo', 'westus3', '11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', 'https://dev.azure.com/acme', 'proj'))
        Mock Read-Host { $script:answers.Dequeue() } -ModuleName MLOpsAccelerator
        Mock Get-MLOpsRegionZoneInfo { @([pscustomobject]@{ name = 'eastus2'; zones = 3 }, [pscustomobject]@{ name = 'westus3'; zones = 3 }, [pscustomobject]@{ name = 'noazregion'; zones = 0 }) } -ModuleName MLOpsAccelerator
        $f = Join-Path $TestDrive 'ix.yaml'
        InModuleScope MLOpsAccelerator -Parameters @{ f = $f } { Read-MLOpsInteractiveInput -Path $f | Out-Null }
        Test-MLOpsAcceleratorInput -InputFile $f | Should -BeTrue
        $y = Get-Content -Raw $f
        $y | Should -Match 'project_name: demo'
        $y | Should -Match 'iac: bicep'
        $y | Should -Match 'scenario: managed-vnet-approved'
        $y | Should -Match 'azdo_project: proj'
    }
}

Describe 'Module packaging' {
    It 'stages a self-contained module that finds its templates' {
        $out = Join-Path $TestDrive 'build'
        $stage = & (Join-Path $PSScriptRoot '../scripts/Build-Module.ps1') -Version 9.8.7-test1 -OutputPath $out | Select-Object -Last 1
        Test-Path (Join-Path $stage 'templates/manifest.json') | Should -BeTrue
        Test-Path (Join-Path $stage 'schema/inputs.schema.json') | Should -BeTrue
        $m = Import-PowerShellDataFile (Join-Path $stage 'MLOpsAccelerator.psd1')
        $m.ModuleVersion | Should -Be '9.8.7'
        $m.PrivateData.PSData.Prerelease | Should -Be 'test1'
        $m.RequiredModules[0].ModuleVersion | Should -Be '0.4.7'
    }
}
