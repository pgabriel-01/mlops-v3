BeforeAll {
    $script:Root = Split-Path -Parent $PSScriptRoot
    Import-Module (Join-Path $Root 'src/MLOpsAccelerator/MLOpsAccelerator.psd1') -Force
    function New-Case([string] $Scenario, [string] $Extra = '', [string] $Cicd = 'github') {
        $f = Join-Path $TestDrive ([guid]::NewGuid().ToString('N') + '.yaml')
        New-MLOpsInputFile -Scenario $Scenario -Path $f -Cicd $Cicd | Out-Null
        if ($Extra) {
            $y = Get-Content -Raw $f
            foreach ($k in [regex]::Matches($Extra, '(?m)^([a-z_]+):').Groups | Where-Object { $_.Name -eq '1' } | ForEach-Object Value) { $y = $y -replace "(?m)^${k}:.*\r?\n", '' }
            Set-Content $f ($y + "`n$Extra`n")
        }
        $f
    }
}

Describe 'Input validation' {
    Context 'Scenario-specific properties' {
        It 'rejects the rag block on another scenario' {
            { Test-MLOpsAcceleratorInput -InputFile (New-Case 'basic-public' "rag:`n  chat_capacity: 5") } | Should -Throw
        }
        It 'rejects existing_platform on another scenario' {
            { Test-MLOpsAcceleratorInput -InputFile (New-Case 'basic-public' "existing_platform:`n  resource_group: rg") } | Should -Throw
        }
        It 'rejects the adls block unless data_source is adls' {
            { Test-MLOpsAcceleratorInput -InputFile (New-Case 'basic-public' "adls:`n  account: a") } | Should -Throw
        }
        It 'accepts the rag block on rag-llmops' {
            Test-MLOpsAcceleratorInput -InputFile (New-Case 'rag-llmops' "rag:`n  chat_capacity: 5") | Should -BeTrue
        }
    }

    Context 'Private networking and runners' {
        It 'rejects private networking with Azure DevOps' {
            { Test-MLOpsAcceleratorInput -InputFile (New-Case 'basic-public' 'use_private_networking: true' 'azdo') } | Should -Throw
        }
        It 'rejects a hosted runner label with private networking' -ForEach 'ubuntu-latest', 'ubuntu-24.04', 'windows-latest', 'macos-14', 'x-latest' {
            { Test-MLOpsAcceleratorInput -InputFile (New-Case 'basic-public' "use_private_networking: true`nrunner_label: $_") } | Should -Throw
        }
        It 'accepts a self-hosted label and the default with private networking' {
            Test-MLOpsAcceleratorInput -InputFile (New-Case 'basic-public' "use_private_networking: true`nrunner_label: my-aci-runners") | Should -BeTrue
            Test-MLOpsAcceleratorInput -InputFile (New-Case 'basic-public' 'use_private_networking: true') | Should -BeTrue
        }
        It 'still allows a hosted label without private networking' {
            Test-MLOpsAcceleratorInput -InputFile (New-Case 'basic-public' 'runner_label: ubuntu-latest') | Should -BeTrue
        }
    }

    Context 'Environments' {
        It 'sorts environments into dev, test, prod order' {
            $f = New-Case 'basic-public' 'environments: [prod, dev, test]'
            $d = InModuleScope MLOpsAccelerator -Parameters @{ f = $f } { Read-MLOpsInput -Path $f }
            ($d['environments'] -join ',') | Should -Be 'dev,test,prod'
        }
        It 'does not require dev' {
            Test-MLOpsAcceleratorInput -InputFile (New-Case 'basic-public' 'environments: [test, prod]') -WarningAction SilentlyContinue | Should -BeTrue
        }
        It 'requires two environments for registry promotion' {
            { Test-MLOpsAcceleratorInput -InputFile (New-Case 'registry-promotion' 'environments: [dev]') } | Should -Throw '*at least two environments*'
            Test-MLOpsAcceleratorInput -InputFile (New-Case 'registry-promotion' 'environments: [dev, prod]') -WarningAction SilentlyContinue | Should -BeTrue
        }
        It 'warns when prod comes first and when approvers are missing' {
            $w = $null
            Test-MLOpsAcceleratorInput -InputFile (New-Case 'basic-public' 'environments: [prod]') -WarningVariable w -WarningAction SilentlyContinue | Out-Null
            ($w -join ' ') | Should -Match 'first environment|Only the prod'
            ($w -join ' ') | Should -Match 'No approvers'
        }
    }

    Context 'Name suffix' {
        It 'rejects a suffix that is not 5 characters: <_>' -ForEach 'ab12', 'ab1234', 'AB123' {
            { Test-MLOpsAcceleratorInput -InputFile (New-Case 'basic-public' "name_suffix: $_") } | Should -Throw
        }
        It 'accepts 5 characters' {
            Test-MLOpsAcceleratorInput -InputFile (New-Case 'basic-public' 'name_suffix: ab123') | Should -BeTrue
        }
    }

    Context 'Address spaces' {
        It 'rejects <_>' -ForEach '10.20.0.5/16', '999.1.0.0/16', '8.8.0.0/16', '10.20.0.0/24', '10.20.0.0/8' {
            { Test-MLOpsAcceleratorInput -InputFile (New-Case 'byo-vnet' "vnet_address_space: $_") } | Should -Throw
        }
        It 'accepts a private /16 to /18 workload range' {
            Test-MLOpsAcceleratorInput -InputFile (New-Case 'byo-vnet' 'vnet_address_space: 172.16.0.0/18') | Should -BeTrue
        }
        It 'rejects overlapping workload and runner networks' {
            { Test-MLOpsAcceleratorInput -InputFile (New-Case 'byo-vnet' "vnet_address_space: 10.250.0.0/16`nuse_private_networking: true") } | Should -Throw '*overlaps*'
        }
        It 'rejects a bad runner range' {
            { Test-MLOpsAcceleratorInput -InputFile (New-Case 'basic-public' "use_private_networking: true`nrunners_vnet_address_space: 10.250.0.0/30") } | Should -Throw '*prefix between*'
        }
    }
}

Describe 'workload_type' {
    It 'rejects a reserved workload name' {
        { Test-MLOpsAcceleratorInput -InputFile (New-Case 'basic-public' "workloads: [src, fraud]") } | Should -Throw
    }
    It 'accepts the deprecated workload alias with a warning' {
        $f = New-Case 'basic-public' 'workload_type: tabular'
        (Get-Content -Raw $f) -replace 'workload_type:', 'workload:' | Set-Content $f
        $w = Test-MLOpsAcceleratorInput -InputFile $f -WarningVariable wv 3>$null
        $w | Should -BeTrue
        ($wv -join ' ') | Should -Match 'deprecated'
    }
}
