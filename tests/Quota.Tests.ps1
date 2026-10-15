BeforeAll {
    $script:Root = Split-Path -Parent $PSScriptRoot
    Import-Module (Join-Path $Root 'src/MLOpsAccelerator/MLOpsAccelerator.psd1') -Force
}

Describe 'Test-MLOpsModelQuota' {
    BeforeAll {
        function New-Usage($name, $current, $limit) { @{ name = @{ value = $name }; currentValue = $current; limit = $limit } }
        $script:ai = @(
            (New-Usage 'OpenAI.GlobalStandard.gpt-5.4-mini' 10 1000),
            (New-Usage 'OpenAI.GlobalStandard.text-embedding-3-small' 995 1000)
        ) | ConvertTo-Json -Depth 4 -AsArray
        $script:search = @{ value = @((New-Usage 'basic' 0 12), (New-Usage 'free' 1 1)) } | ConvertTo-Json -Depth 4
    }
    BeforeEach {
        InModuleScope MLOpsAccelerator -Parameters @{ ai = $script:ai; search = $script:search } {
            param($ai, $search)
            $script:aiJson = $ai; $script:searchJson = $search
            Mock az {
                $global:LASTEXITCODE = 0
                if ($args -contains 'cognitiveservices') { $script:aiJson } else { $script:searchJson }
            }
        }
    }
    It 'passes when every model and the search tier have capacity' {
        $r = @(Test-MLOpsModelQuota -Location eastus2 -SubscriptionId 00000000-0000-0000-0000-000000000000 -EmbeddingCapacity 5)
        $r.Count | Should -Be 3
        ($r | Where-Object { -not $_.Passed }) | Should -BeNullOrEmpty
    }
    It 'fails and names the model when quota is short' {
        $r = @(Test-MLOpsModelQuota -Location eastus2 -SubscriptionId 00000000-0000-0000-0000-000000000000)
        $bad = @($r | Where-Object { -not $_.Passed })
        $bad.Count | Should -Be 1
        $bad[0].Name | Should -Match 'text-embedding-3-small'
        $bad[0].Detail | Should -Match 'eastus2'
    }
    It 'multiplies the need by the number of environments' {
        $r = @(Test-MLOpsModelQuota -Location eastus2 -SubscriptionId 00000000-0000-0000-0000-000000000000 -ChatCapacity 400 -Environments 3)
        ($r | Where-Object Name -Match 'gpt-5.4-mini').Passed | Should -BeFalse
    }
    It 'fails when a model or search tier is not offered in the region' {
        $r = @(Test-MLOpsModelQuota -Location eastus2 -SubscriptionId 00000000-0000-0000-0000-000000000000 -ChatModel gpt-nope -SearchSku standard3)
        ($r | Where-Object Name -Match 'gpt-nope').Passed | Should -BeFalse
        ($r | Where-Object Name -Match 'search standard3').Passed | Should -BeFalse
    }
}
