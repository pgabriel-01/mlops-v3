Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:ModuleRoot = Split-Path -Parent $PSCommandPath
$script:RepoRoot = Resolve-Path (Join-Path $script:ModuleRoot '../..')
$script:TemplateRoot = Join-Path $script:RepoRoot 'templates'
$script:SchemaPath = Join-Path $script:RepoRoot 'schema/inputs.schema.json'
$script:LockPath = Join-Path $script:RepoRoot 'versions.lock.json'

$script:TextExtensions = '.yml', '.yaml', '.tf', '.tfvars', '.bicep', '.bicepparam', '.json', '.md', '.py', '.txt'
$script:LocationShort = @{
    eastus = 'eus'; eastus2 = 'eus2'; westus = 'wus'; westus2 = 'wus2'; westus3 = 'wus3'; centralus = 'cus'
    northcentralus = 'ncus'; southcentralus = 'scus'; westcentralus = 'wcus'; canadacentral = 'cac'; canadaeast = 'cae'
    northeurope = 'neu'; westeurope = 'weu'; uksouth = 'uks'; ukwest = 'ukw'; francecentral = 'frc'; germanywestcentral = 'gwc'
    swedencentral = 'sec'; switzerlandnorth = 'szn'; norwayeast = 'noe'; australiaeast = 'aue'; southeastasia = 'sea'
    eastasia = 'ea'; japaneast = 'jpe'; koreacentral = 'krc'; centralindia = 'inc'; brazilsouth = 'brs'
    southafricanorth = 'san'; uaenorth = 'uan'
}

function Get-FlatVersion {
    param([Parameter(Mandatory)] $Node, [string] $Prefix = 'versions')
    $flat = @{}
    foreach ($prop in $Node.PSObject.Properties) {
        $key = "$Prefix.$($prop.Name)"
        if ($prop.Value -is [pscustomobject]) {
            foreach ($entry in (Get-FlatVersion -Node $prop.Value -Prefix $key).GetEnumerator()) { $flat[$entry.Key] = $entry.Value }
        }
        elseif ($prop.Name -notin 'notes', 'generatedOn', 'schemaVersion') {
            $flat[$key] = [string]$prop.Value
        }
    }
    $flat
}

function Read-MLOpsInput {
    param([Parameter(Mandatory)][string] $Path)

    if (-not (Test-Path $Path)) { throw "Input file not found: $Path" }
    Import-Module powershell-yaml -ErrorAction Stop
    $raw = Get-Content -Raw -Path $Path
    $data = if ($Path -match '\.json$') { $raw | ConvertFrom-Json -AsHashtable } else { $raw | ConvertFrom-Yaml }

    if (-not $data.ContainsKey('data_source')) { $data['data_source'] = 'taxi-csv' }
    if (-not $data.ContainsKey('environments')) { $data['environments'] = @('dev', 'test', 'prod') }
    if (-not $data.ContainsKey('workload')) { $data['workload'] = 'tabular' }
    if (-not $data.ContainsKey('vnet_address_space')) { $data['vnet_address_space'] = '10.20.0.0/16' }
    if (-not $data.ContainsKey('allowed_outbound_fqdns')) { $data['allowed_outbound_fqdns'] = @('pypi.org', 'files.pythonhosted.org', '*.anaconda.com', 'conda.anaconda.org') }
    if (-not $data.ContainsKey('budget_amount')) { $data['budget_amount'] = 500 }
    if (-not $data.ContainsKey('alert_emails')) { $data['alert_emails'] = @() }
    $data['allowed_outbound_fqdns'] = @($data['allowed_outbound_fqdns'])
    $data['alert_emails'] = @($data['alert_emails'])
    if (-not $data.ContainsKey('tags') -or $null -eq $data['tags']) { $data['tags'] = @{} }
    $data['environments'] = @($data['environments'])

    $json = $data | ConvertTo-Json -Depth 5
    $errors = $null
    if (-not (Test-Json -Json $json -SchemaFile $script:SchemaPath -ErrorVariable errors -ErrorAction SilentlyContinue)) {
        $detail = ($errors | ForEach-Object { $_.ToString() }) -join '; '
        throw "Invalid inputs in '$Path': $detail"
    }
    $data
}

function Get-MLOpsScenario {
    <#
    .SYNOPSIS
    Lists the AML platform scenarios (or returns one by id or number).
    #>
    [CmdletBinding()]
    param([string] $Scenario)
    $all = Get-Content -Raw -Path (Join-Path $script:TemplateRoot 'scenarios.json') | ConvertFrom-Json
    if (-not $Scenario) { return $all }
    $hit = $all | Where-Object { $_.id -eq $Scenario -or [string]$_.number -eq $Scenario }
    if (-not $hit) { throw "Unknown scenario '$Scenario'. Valid: $(($all.id) -join ', ')" }
    $hit
}

function New-MLOpsInputFile {
    <#
    .SYNOPSIS
    Writes a starter inputs file for a scenario, with the parameters that scenario needs.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string] $Scenario,
        [Parameter(Mandatory)][string] $Path,
        [ValidateSet('terraform', 'bicep')][string] $Iac = 'terraform',
        [ValidateSet('github', 'azdo')][string] $Cicd = 'github',
        [switch] $Force
    )
    $sc = Get-MLOpsScenario -Scenario $Scenario
    if ((Test-Path $Path) -and -not $Force) { throw "'$Path' exists. Use -Force to overwrite." }
    $y = @"
# Scenario $($sc.number): $($sc.name)
# $($sc.summary)
project_name: myml
location: eastus2
subscription_id: 00000000-0000-0000-0000-000000000000
tenant_id: 00000000-0000-0000-0000-000000000000
iac: $Iac
cicd: $Cicd
scenario: $($sc.id)
workload: tabular
data_source: taxi-csv
environments: [dev, test, prod]
tags:
  owner: ml-platform

"@
    $y += if ($Cicd -eq 'github') { "github_org: my-org`ngithub_repo: myml-mlops`n" } else { "azdo_org_url: https://dev.azure.com/my-org`nazdo_project: my-project`n" }
    if ($sc.network_mode -eq 'byo_vnet' -and -not $sc.existing_platform) { $y += "vnet_address_space: 10.20.0.0/16`n" }
    if ($sc.network_mode -eq 'managed_approved') { $y += "allowed_outbound_fqdns: [pypi.org, files.pythonhosted.org, '*.anaconda.com', conda.anaconda.org]`n" }
    if ($sc.governance) { $y += "budget_amount: 500`nalert_emails: [mlops@example.com]`n" }
    if ($sc.existing_platform) {
        $y += "existing_platform:`n  subnet_id: /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-platform/providers/Microsoft.Network/virtualNetworks/vnet-platform/subnets/snet-ml`n  log_analytics_workspace_id: /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-platform/providers/Microsoft.OperationalInsights/workspaces/law-platform`n  private_dns_zone_ids:`n    blob: /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-dns/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net`n    file: /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-dns/providers/Microsoft.Network/privateDnsZones/privatelink.file.core.windows.net`n    vault: /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net`n    acr: /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-dns/providers/Microsoft.Network/privateDnsZones/privatelink.azurecr.io`n    aml_api: /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-dns/providers/Microsoft.Network/privateDnsZones/privatelink.api.azureml.ms`n    aml_notebooks: /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-dns/providers/Microsoft.Network/privateDnsZones/privatelink.notebooks.azure.net`n" }
    Set-Content -Path $Path -Value $y -NoNewline
    $Path
}

function Get-MLOpsLock {
    param([string] $Path = $script:LockPath)
    Get-Content -Raw -Path $Path | ConvertFrom-Json
}

function New-MLOpsTokenMap {
    param([Parameter(Mandatory)] $Inputs, [Parameter(Mandatory)] $Lock)

    $loc = $Inputs['location']
    $short = if ($script:LocationShort.ContainsKey($loc)) { $script:LocationShort[$loc] } else { $loc.Substring(0, [Math]::Min(4, $loc.Length)) }
    $hash = [System.Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes("$($Inputs['subscription_id'])/$($Inputs['project_name'])"))
    $suffix = (($hash | Select-Object -First 2 | ForEach-Object { $_.ToString('x2') }) -join '')

    $envs = @($Inputs['environments'])
    $tags = $Inputs['tags']
    $tagKeys = @($tags.Keys | Sort-Object)
    $tagWidth = 2 + ($tagKeys | ForEach-Object { $_.Length } | Measure-Object -Maximum).Maximum

    $sc = Get-MLOpsScenario -Scenario $Inputs['scenario']
    $ep = $Inputs['existing_platform']
    $dnsKeys = 'blob', 'file', 'vault', 'acr', 'aml_api', 'aml_notebooks'
    $dns = @{}; if ($ep -and $ep.ContainsKey('private_dns_zone_ids')) { $dns = $ep['private_dns_zone_ids'] }
    $fqdn = @($Inputs['allowed_outbound_fqdns']); $mails = @($Inputs['alert_emails'])
    $lc = { param($b) ([bool]$b).ToString().ToLower() }
    $map = @{
        project_name           = $Inputs['project_name']
        location               = $loc
        location_short         = $short
        suffix                 = $suffix
        subscription_id        = $Inputs['subscription_id']
        tenant_id              = $Inputs['tenant_id']
        iac                    = $Inputs['iac']
        cicd                   = $Inputs['cicd']
        scenario               = $Inputs['scenario']
        scenario_number        = [string]$sc.number
        scenario_name          = $sc.name
        workload               = $Inputs['workload']
        network_mode           = $sc.network_mode
        endpoint_type          = $sc.endpoint_type
        endpoint_online        = (& $lc ($sc.endpoint_type -eq 'online'))
        endpoint_batch         = (& $lc ($sc.endpoint_type -eq 'batch'))
        registry               = (& $lc $sc.registry)
        model_ref              = $(if ($sc.registry) { "azureml://registries/reg-$($Inputs['project_name'])-$short/models/$($Inputs['project_name'])-model/labels/latest" } else { "azureml:$($Inputs['project_name'])-model@latest" })
        scenario_summary       = $sc.summary
        scenario_docs_md       = (($sc.docs | ForEach-Object { "- <$_>" }) -join "`n")
        first_env              = @($Inputs['environments'])[0]
        registry_name          = "reg-$($Inputs['project_name'])-$short"
        deploy_mode            = $(if ($sc.endpoint_type -eq 'online' -and $sc.id -eq 'online-bluegreen') { 'bluegreen' } else { $sc.endpoint_type })
        governance             = (& $lc $sc.governance)
        genai                  = (& $lc $sc.genai)
        existing_platform      = (& $lc $sc.existing_platform)
        vnet_address_space     = $Inputs['vnet_address_space']
        budget_amount          = [string]$Inputs['budget_amount']
        allowed_fqdns_hcl      = '[' + (($fqdn | ForEach-Object { '"' + $_ + '"' }) -join ', ') + ']'
        allowed_fqdns_bicep    = '[' + (($fqdn | ForEach-Object { "'" + $_ + "'" }) -join ', ') + ']'
        alert_emails_hcl       = '[' + (($mails | ForEach-Object { '"' + $_ + '"' }) -join ', ') + ']'
        alert_emails_bicep     = '[' + (($mails | ForEach-Object { "'" + $_ + "'" }) -join ', ') + ']'
        existing_subnet_id     = $(if ($ep) { [string]$ep['subnet_id'] } else { '' })
        existing_law_id        = $(if ($ep) { [string]$ep['log_analytics_workspace_id'] } else { '' })
        existing_dns_hcl       = $(if ($dns.Count -eq 0) { '{}' } else { '{' + (($dnsKeys | Where-Object { $dns.ContainsKey($_) } | ForEach-Object { ' {0} = "{1}"' -f $_, $dns[$_] }) -join ',') + ' }' })
        existing_dns_bicep     = '{' + (($dnsKeys | Where-Object { $dns.ContainsKey($_) } | ForEach-Object { "`n  {0}: '{1}'" -f $_, $dns[$_] }) -join '') + "`n}"
        data_source            = $Inputs['data_source']
        data_path              = $(if ($Inputs['data_source'] -eq 'adls') { 'azureml://datastores/adls_raw/paths/' + $Inputs['adls']['path'] } else { '../../data/taxi-data.csv' })
        adls_account           = $(if ($Inputs['data_source'] -eq 'adls') { [string]$Inputs['adls']['account_name'] } else { '' })
        adls_container         = $(if ($Inputs['data_source'] -eq 'adls') { [string]$Inputs['adls']['container'] } else { '' })
        private_networking     = (& $lc ($sc.network_mode -ne 'public'))
        feature_store          = (& $lc $sc.feature_store)
        endpoint_public_access = $(if ($sc.network_mode -ne 'public') { 'disabled' } else { 'enabled' })
        environments_csv       = ($envs -join ', ')
        environments_yaml_list = '[' + (($envs | ForEach-Object { '"' + $_ + '"' }) -join ', ') + ']'
        environments_hcl_list  = '[' + (($envs | ForEach-Object { '"' + $_ + '"' }) -join ', ') + ']'
        tags_hcl               = (($tagKeys | ForEach-Object { '  {0} = "{1}"' -f ('"' + $_ + '"').PadRight($tagWidth), $tags[$_] }) -join "`n")
        tags_bicep             = (($tagKeys | ForEach-Object { $k = if ($_ -match '^[A-Za-z_][A-Za-z0-9_]*$') { $_ } else { "'$_'" }; "  {0}: '{1}'" -f $k, $tags[$_] }) -join "`n")
        cicd_label             = $(if ($Inputs['cicd'] -eq 'github') { 'GitHub' } else { 'Azure DevOps' })
        iac_label              = $(if ($Inputs['iac'] -eq 'terraform') { 'Terraform' } else { 'Bicep' })
        pipelines_dir          = $(if ($Inputs['cicd'] -eq 'github') { '.github/workflows' } else { 'pipelines' })
        github_org             = [string]$Inputs['github_org']
        github_repo            = [string]$Inputs['github_repo']
        azdo_org_url           = [string]$Inputs['azdo_org_url']
        azdo_project           = [string]$Inputs['azdo_project']
    }
    foreach ($entry in (Get-FlatVersion -Node $Lock).GetEnumerator()) { $map[$entry.Key] = $entry.Value }
    $map
}

function Expand-MLOpsTemplate {
    param([Parameter(Mandatory)][string] $Text, [Parameter(Mandatory)] $Map, [string[]] $Environments, [string] $Source)

    $blockPattern = '(?s)\[\[#each_env\]\]\r?\n(.*?)\[\[/each_env\]\]\r?\n?'
    $Text = [regex]::Replace($Text, $blockPattern, {
            param($m)
            $body = $m.Groups[1].Value
            $out = for ($i = 0; $i -lt $Environments.Count; $i++) {
                $e = $Environments[$i]
                $prev = if ($i -eq 0) { $null } else { $Environments[$i - 1] }
                $local = @{
                    env        = $e
                    needs      = $(if ($prev) { "deploy-$prev" } else { 'validate' })
                    needs_azdo = $(if ($prev) { "deploy_$prev" } else { 'validate' })
                }
                [regex]::Replace($body, '\[\[\s*([A-Za-z0-9_.\-/]+)\s*\]\]', {
                        param($t)
                        $k = $t.Groups[1].Value
                        if ($local.ContainsKey($k)) { $local[$k] } elseif ($Map.ContainsKey($k)) { $Map[$k] } else { $t.Value }
                    })
            }
            -join $out
        })

    [regex]::Replace($Text, '\[\[\s*([A-Za-z0-9_.\-/]+)\s*\]\]', {
            param($t)
            $k = $t.Groups[1].Value
            if ($Map.ContainsKey($k)) { $Map[$k] } else { throw "Unknown template token '$k' in $Source" }
        })
}

function Test-ManifestCondition {
    param($When, $Map)
    if ($null -eq $When) { return $true }
    foreach ($p in $When.PSObject.Properties) {
        if ([string]$Map[$p.Name] -ne [string]$p.Value) { return $false }
    }
    $true
}

function Write-MLOpsFile {
    param([string] $SourceFile, [string] $Destination, [bool] $Render, $Map, [string[]] $Environments)

    $dir = Split-Path -Parent $Destination
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $isText = $script:TextExtensions -contains [IO.Path]::GetExtension($SourceFile).ToLower()
    if ($Render -and $isText) {
        $text = Get-Content -Raw -Path $SourceFile
        $out = Expand-MLOpsTemplate -Text $text -Map $Map -Environments $Environments -Source $SourceFile
        [IO.File]::WriteAllText($Destination, $out, [Text.UTF8Encoding]::new($false))
    }
    else {
        Copy-Item -Path $SourceFile -Destination $Destination -Force
    }
}

function Test-MLOpsAcceleratorInput {
    <#
    .SYNOPSIS
    Validates an inputs file (YAML or JSON) against the accelerator schema.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string] $InputFile)
    $null = Read-MLOpsInput -Path $InputFile
    $true
}

function Deploy-MLOpsAccelerator {
    <#
    .SYNOPSIS
    Generates an MLOps repository from an inputs file and optionally runs the bootstrap.
    .PARAMETER InputFile
    YAML or JSON inputs (see inputs.example.yaml).
    .PARAMETER OutputPath
    Folder that receives the generated repository. Must be empty unless -Force is used.
    .PARAMETER Deploy
    After generating, run the Terraform bootstrap (state, identity, repository wiring).
    .PARAMETER Destroy
    Destroy the bootstrap resources of a previously generated project in OutputPath.
    .PARAMETER SkipVersionCheck
    Skip the check for outdated pinned versions.
    .PARAMETER AutoApprove
    Apply or destroy the bootstrap without the interactive confirmation after the plan.
    .PARAMETER Upgrade
    Regenerate into a folder created by an earlier run (marked by .mlops-v3). Files are overwritten; commit first so you can review the diff.
    .PARAMETER SkipRequirementsCheck
    Skip the pre-flight requirements check used by -Deploy and -Destroy.
    .PARAMETER Interactive
    Prompt for the key inputs and write the inputs file (InputFile, default ./inputs.yaml) before generating.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string] $InputFile,
        [Parameter(Mandatory)][string] $OutputPath,
        [switch] $Deploy,
        [switch] $Destroy,
        [switch] $Force,
        [switch] $SkipVersionCheck,
        [switch] $AutoApprove,
        [switch] $Upgrade,
        [switch] $SkipRequirementsCheck,
        [switch] $Interactive
    )

    if ($Interactive) {
        if (-not $InputFile) { $InputFile = './inputs.yaml' }
        $null = Read-MLOpsInteractiveInput -Path $InputFile
    }
    if (-not $InputFile) { throw 'Provide -InputFile, or use -Interactive to be prompted.' }
    $inputs = Read-MLOpsInput -Path $InputFile
    $lock = Get-MLOpsLock

    if ($Destroy) {
        Invoke-MLOpsBootstrap -ProjectPath $OutputPath -Inputs $inputs -Destroy -AutoApprove:$AutoApprove -SkipRequirementsCheck:$SkipRequirementsCheck
        return
    }

    if (-not $SkipVersionCheck) {
        $stale = @(Test-MLOpsAcceleratorVersion | Where-Object Status -EQ 'Outdated')
        if ($stale.Count -gt 0) {
            Write-Warning ("{0} pinned component(s) are outdated; run Update-MLOpsAcceleratorVersion. Continuing with the tested pins." -f $stale.Count)
        }
    }

    $nonEmpty = (Test-Path $OutputPath) -and (Get-ChildItem -Force -Path $OutputPath | Select-Object -First 1)
    $isProject = Test-Path (Join-Path $OutputPath '.mlops-v3/generation.json')
    if ($Upgrade -and $nonEmpty -and -not $isProject) { throw "'$OutputPath' is not an MLOps v3 project (no .mlops-v3/generation.json)." }
    if ($nonEmpty -and -not $Force -and -not ($Upgrade -and $isProject)) {
        throw "Output path '$OutputPath' is not empty. Use -Force to overwrite, or -Upgrade for an existing MLOps v3 project."
    }

    $map = New-MLOpsTokenMap -Inputs $inputs -Lock $lock
    $envs = @($inputs['environments'])
    $manifest = Get-Content -Raw -Path (Join-Path $script:TemplateRoot 'manifest.json') | ConvertFrom-Json

    if (-not $PSCmdlet.ShouldProcess($OutputPath, 'Generate MLOps repository')) { return }
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    $OutputPath = (Resolve-Path $OutputPath).Path

    foreach ($entry in $manifest) {
        if (-not (Test-ManifestCondition -When $(if ($entry.PSObject.Properties.Name -contains 'when') { $entry.when }) -Map $map)) { continue }
        $render = -not ($entry.PSObject.Properties.Name -contains 'render' -and $entry.render -eq $false)
        $srcRoot = Join-Path $script:TemplateRoot $entry.src
        foreach ($file in Get-ChildItem -Recurse -File -Path $srcRoot) {
            $relative = [IO.Path]::GetRelativePath($srcRoot, $file.FullName)
            if ($relative -like '*__env__*') {
                foreach ($e in $envs) {
                    $local = $map.Clone(); $local['env'] = $e
                    $local['registry'] = (([bool]($map['registry'] -eq 'true')) -and $e -eq $envs[0]).ToString().ToLower()
                    $dest = Join-Path (Join-Path $OutputPath $entry.dest) ($relative -replace '__env__', $e)
                    Write-MLOpsFile -SourceFile $file.FullName -Destination $dest -Render $render -Map $local -Environments $envs
                }
            }
            else {
                $dest = Join-Path (Join-Path $OutputPath $entry.dest) $relative
                Write-MLOpsFile -SourceFile $file.FullName -Destination $dest -Render $render -Map $map -Environments $envs
            }
        }
    }

    $meta = Join-Path $OutputPath '.mlops-v3'
    New-Item -ItemType Directory -Path $meta -Force | Out-Null
    Copy-Item $script:LockPath (Join-Path $meta 'versions.lock.json') -Force
    $moduleVersion = (Import-PowerShellDataFile (Join-Path $script:ModuleRoot 'MLOpsAccelerator.psd1')).ModuleVersion
    @{ moduleVersion = $moduleVersion; inputs = $inputs } | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $meta 'generation.json')

    Write-Host "Generated MLOps v3 project in $OutputPath"

    if ($Deploy) { Invoke-MLOpsBootstrap -ProjectPath $OutputPath -Inputs $inputs -AutoApprove:$AutoApprove -SkipRequirementsCheck:$SkipRequirementsCheck }
    else { Write-Host "Next: cd '$OutputPath/bootstrap'; terraform init; terraform apply -var-file=bootstrap.tfvars" }
}

function Invoke-MLOpsBootstrap {
    param([Parameter(Mandatory)][string] $ProjectPath, [Parameter(Mandatory)] $Inputs, [switch] $Destroy, [switch] $AutoApprove, [switch] $SkipRequirementsCheck)

    if (-not $SkipRequirementsCheck) {
        $bad = @(Test-MLOpsAcceleratorRequirement -Cicd $Inputs['cicd'] -Iac $Inputs['iac'] | Where-Object { -not $_.Passed -and $_.Required })
        if ($bad.Count -gt 0) {
            $bad | ForEach-Object { Write-Warning ("{0}: {1}" -f $_.Name, $_.Detail) }
            throw 'Requirements check failed. Fix the items above or use -SkipRequirementsCheck.'
        }
    }
    if ($Inputs['cicd'] -eq 'github' -and -not $env:GITHUB_TOKEN -and (Get-Command gh -ErrorAction SilentlyContinue)) { $env:GITHUB_TOKEN = (gh auth token) }

    $dir = Join-Path $ProjectPath 'bootstrap'
    $env:ARM_SUBSCRIPTION_ID = $Inputs['subscription_id']
    terraform "-chdir=$dir" init -input=false
    if ($LASTEXITCODE -ne 0) { throw 'terraform init failed' }

    $verb = if ($Destroy) { 'destroy' } else { 'apply' }
    $planArgs = @('plan', '-input=false', '-var-file=bootstrap.tfvars', '-out=tfplan')
    if ($Destroy) { $planArgs += '-destroy' }
    terraform "-chdir=$dir" @planArgs
    if ($LASTEXITCODE -ne 0) { throw 'terraform plan failed' }
    if (-not $AutoApprove) {
        $answer = Read-Host "Review the plan above. Type 'yes' to $verb"
        if ($answer -ne 'yes') { Write-Host "Cancelled; nothing was changed. The saved plan is $dir/tfplan."; return }
    }
    terraform "-chdir=$dir" apply -input=false tfplan
    if ($LASTEXITCODE -ne 0) { throw "terraform $verb failed" }
    Remove-Item (Join-Path $dir 'tfplan') -Force -ErrorAction SilentlyContinue
}

function Test-MLOpsAcceleratorRequirement {
    <#
    .SYNOPSIS
    Pre-flight check of the tools, sign-ins and tokens that -Deploy / -Destroy need.
    .OUTPUTS
    One object per check: Name, Required, Passed, Detail.
    #>
    [CmdletBinding()]
    param(
        [ValidateSet('github', 'azdo')][string] $Cicd = 'github',
        [ValidateSet('terraform', 'bicep')][string] $Iac = 'terraform'
    )
    $r = [System.Collections.Generic.List[object]]::new()
    $add = { param($n, $req, $ok, $d) $r.Add([pscustomobject]@{ Name = $n; Required = $req; Passed = [bool]$ok; Detail = $d }) }

    & $add 'PowerShell 7.4+' $true ($PSVersionTable.PSVersion -ge [version]'7.4') "found $($PSVersionTable.PSVersion)"
    & $add 'powershell-yaml module' $true ([bool](Get-Module -ListAvailable powershell-yaml)) 'Install-PSResource powershell-yaml'
    & $add 'terraform' $true ([bool](Get-Command terraform -ErrorAction SilentlyContinue)) 'install Terraform and add it to PATH (bootstrap always uses it)'
    & $add 'git' $true ([bool](Get-Command git -ErrorAction SilentlyContinue)) 'install git'
    $az = [bool](Get-Command az -ErrorAction SilentlyContinue)
    & $add 'Azure CLI' $true $az 'install the Azure CLI'
    $signedIn = $false
    if ($az) { az account show --only-show-errors *> $null; $signedIn = ($LASTEXITCODE -eq 0) }
    & $add 'az login' $true $signedIn 'run az login'
    if ($Iac -eq 'bicep') {
        $bicep = $false
        if ($az) { az bicep version --only-show-errors *> $null; $bicep = ($LASTEXITCODE -eq 0) }
        & $add 'Bicep (az bicep)' $true $bicep 'run az bicep install'
    }
    if ($Cicd -eq 'github') {
        $gh = [bool](Get-Command gh -ErrorAction SilentlyContinue)
        $tokenOk = [bool]$env:GITHUB_TOKEN
        if (-not $tokenOk -and $gh) { gh auth status *> $null; $tokenOk = ($LASTEXITCODE -eq 0) }
        & $add 'GitHub token' $true $tokenOk 'set GITHUB_TOKEN or run gh auth login'
        & $add 'GitHub CLI (gh)' $false $gh 'optional; used to read the token'
    }
    else {
        & $add 'Azure DevOps token' $true ([bool]$env:AZDO_PERSONAL_ACCESS_TOKEN) 'set AZDO_PERSONAL_ACCESS_TOKEN'
    }
    $net = $false
    try { $net = (Invoke-WebRequest -Uri 'https://registry.terraform.io' -Method Head -TimeoutSec 10 -SkipHttpErrorCheck).StatusCode -lt 500 } catch { $net = $false }
    & $add 'Network: registry.terraform.io' $false $net 'needed for terraform init unless you use a mirror'
    $r
}

function Remove-MLOpsAccelerator {
    <#
    .SYNOPSIS
    Destroys the bootstrap resources of a generated project and optionally deletes the local folder.
    .DESCRIPTION
    Workload infrastructure (per-environment AML resources) is owned by the generated pipelines; destroy those first
    (run the infra pipeline with the destroy option, or delete the resource groups) before removing the bootstrap.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory)][string] $InputFile,
        [Parameter(Mandatory)][string] $ProjectPath,
        [switch] $AutoApprove,
        [switch] $DeleteLocalFolder,
        [switch] $SkipRequirementsCheck
    )
    $inputs = Read-MLOpsInput -Path $InputFile
    if (-not (Test-Path (Join-Path $ProjectPath '.mlops-v3/generation.json'))) { throw "'$ProjectPath' is not an MLOps v3 project." }
    if (-not $PSCmdlet.ShouldProcess($ProjectPath, 'Destroy bootstrap resources')) { return }
    Invoke-MLOpsBootstrap -ProjectPath $ProjectPath -Inputs $inputs -Destroy -AutoApprove:$AutoApprove -SkipRequirementsCheck:$SkipRequirementsCheck
    if ($DeleteLocalFolder -and (Test-Path (Join-Path (Join-Path $ProjectPath 'bootstrap') 'terraform.tfstate'))) {
        Write-Warning 'Local terraform state still exists; not deleting the folder. Check the destroy result first.'
    }
    elseif ($DeleteLocalFolder) { Remove-Item -Recurse -Force $ProjectPath }
}

function Grant-MLOpsStorageAccess {
    <#
    .SYNOPSIS
    Grants the AML workspace identity Storage Blob Data Reader on the ADLS account used by data_source: adls.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string] $StorageAccountName,
        [Parameter(Mandatory)][string] $StorageResourceGroup,
        [Parameter(Mandatory)][string] $WorkspaceName,
        [Parameter(Mandatory)][string] $WorkspaceResourceGroup
    )
    $principal = az ml workspace show -n $WorkspaceName -g $WorkspaceResourceGroup --query identity.principal_id -o tsv --only-show-errors
    if ($LASTEXITCODE -ne 0 -or -not $principal) { throw 'Could not read the workspace managed identity. Is the workspace deployed and are you logged in?' }
    $scope = az storage account show -n $StorageAccountName -g $StorageResourceGroup --query id -o tsv --only-show-errors
    if ($LASTEXITCODE -ne 0 -or -not $scope) { throw "Storage account '$StorageAccountName' not found." }
    if ($PSCmdlet.ShouldProcess($scope, "Assign Storage Blob Data Reader to $principal")) {
        az role assignment create --assignee-object-id $principal --assignee-principal-type ServicePrincipal --role 'Storage Blob Data Reader' --scope $scope --only-show-errors | Out-Null
        if ($LASTEXITCODE -ne 0) { throw 'Role assignment failed.' }
        Write-Host "Granted Storage Blob Data Reader on $StorageAccountName."
    }
}

function Read-MLOpsInteractiveInput {
    param([Parameter(Mandatory)][string] $Path)

    $ask = {
        param($prompt, $default, $choices)
        while ($true) {
            $hint = if ($choices) { " ($($choices -join '/'))" } else { '' }
            $v = Read-Host "$prompt$hint [$default]"
            if ([string]::IsNullOrWhiteSpace($v)) { $v = $default }
            if (-not $choices -or $choices -contains $v) { return $v }
            Write-Host "Choose one of: $($choices -join ', ')"
        }
    }
    $scenarios = @(Get-MLOpsScenario)
    $scenarios | ForEach-Object { Write-Host ("  {0,2}. {1,-28} {2}" -f $_.number, $_.id, $_.name) }
    $sc = & $ask 'Scenario id' 'basic-public' @($scenarios.id)
    $iac = & $ask 'IaC' 'terraform' @('terraform', 'bicep')
    $cicd = & $ask 'CI/CD' 'github' @('github', 'azdo')
    New-MLOpsInputFile -Scenario $sc -Path $Path -Iac $iac -Cicd $cicd -Force | Out-Null

    $sub = ''; $ten = ''
    if (Get-Command az -ErrorAction SilentlyContinue) {
        $sub = (az account show --query id -o tsv --only-show-errors 2>$null); $ten = (az account show --query tenantId -o tsv --only-show-errors 2>$null)
    }
    $set = @{
        project_name = (& $ask 'Project name' 'myml' $null)
        location = (& $ask 'Azure region' 'eastus2' $null)
        subscription_id = (& $ask 'Subscription id' $(if ($sub) { $sub } else { '00000000-0000-0000-0000-000000000000' }) $null)
        tenant_id = (& $ask 'Tenant id' $(if ($ten) { $ten } else { '00000000-0000-0000-0000-000000000000' }) $null)
    }
    if ($cicd -eq 'github') { $set['github_org'] = (& $ask 'GitHub org' 'my-org' $null); $set['github_repo'] = (& $ask 'GitHub repo' "$($set['project_name'])-mlops" $null) }
    else { $set['azdo_org_url'] = (& $ask 'Azure DevOps org URL' 'https://dev.azure.com/my-org' $null); $set['azdo_project'] = (& $ask 'Azure DevOps project' 'my-project' $null) }
    $text = Get-Content -Raw $Path
    foreach ($k in $set.Keys) { $text = [regex]::Replace($text, "(?m)^${k}:.*`$", { param($m) "${k}: $($set[$k])" }) }
    Set-Content -Path $Path -Value $text -NoNewline
    $Path
}

function Get-LatestVersion {
    param([string] $Kind, [string] $Name, [string] $Major)
    try {
        if ($Major -and $Kind -eq 'provider') {
            $all = (Invoke-RestMethod -Uri "https://registry.terraform.io/v1/providers/$Name/versions" -TimeoutSec 20).versions.version
            return ($all | Where-Object { $_ -match "^$Major\.\d+\.\d+$" } | Sort-Object { [version]$_ } | Select-Object -Last 1)
        }
        if ($Major -and $Kind -eq 'pypi') {
            # A held PyPI package tracks only its pinned major.minor series (patch releases, no post releases).
            $rel = (Invoke-RestMethod -Uri "https://pypi.org/pypi/$Name/json" -TimeoutSec 20).releases.PSObject.Properties
            $rx = '^' + [regex]::Escape($Major) + '(\.\d+)?$'
            $ok = $rel | Where-Object { $_.Name -match $rx -and ($_.Value | Where-Object { -not $_.yanked }) } | ForEach-Object Name
            return ($ok | Sort-Object { [version](($_ -replace '\.post\d+$', '') + $(if (($_ -replace '\.post\d+$','').Split('.').Count -lt 3) { '.0' } else { '' })) }, { $_ } | Select-Object -Last 1)
        }
        switch ($Kind) {
            'tfmodule' { (Invoke-RestMethod -Uri "https://registry.terraform.io/v1/modules/$Name" -TimeoutSec 20).version }
            'bicepmodule' {
                $tags = (Invoke-RestMethod -Uri "https://mcr.microsoft.com/v2/bicep/avm/$Name/tags/list" -TimeoutSec 20).tags
                $tags | Where-Object { $_ -match '^\d+\.\d+\.\d+$' } | Sort-Object { [version]$_ } | Select-Object -Last 1
            }
            'pypi' { (Invoke-RestMethod -Uri "https://pypi.org/pypi/$Name/json" -TimeoutSec 20).info.version }
            'provider' { (Invoke-RestMethod -Uri "https://registry.terraform.io/v1/providers/$Name" -TimeoutSec 20).version }
            'terraform' { (Invoke-RestMethod -Uri 'https://checkpoint-api.hashicorp.com/v1/check/terraform' -TimeoutSec 20).current_version }
            'action' {
                $tag = (Invoke-RestMethod -Uri "https://api.github.com/repos/$Name/releases/latest" -TimeoutSec 20).tag_name
                ($tag -replace '^v', '').Split('.')[0]
            }
        }
    }
    catch { $null }
}

$script:ProviderSource = @{ azurerm = 'hashicorp/azurerm'; azapi = 'Azure/azapi'; github = 'integrations/github'; azuredevops = 'microsoft/azuredevops' }
$script:ActionRepo = @{ checkout = 'actions/checkout'; login = 'Azure/login'; setup_terraform = 'hashicorp/setup-terraform'; checkov = 'bridgecrewio/checkov-action'; upload_artifact = 'actions/upload-artifact' }

function Get-MLOpsComponent {
    param($Lock)
    $items = [System.Collections.Generic.List[object]]::new()
    $items.Add([pscustomobject]@{ Component = 'terraform'; Kind = 'terraform'; Name = 'terraform'; Pinned = $Lock.terraform; Section = 'terraform'; Key = $null })
    foreach ($p in $Lock.providers.PSObject.Properties) {
        $items.Add([pscustomobject]@{ Component = "provider:$($p.Name)"; Kind = 'provider'; Name = $script:ProviderSource[$p.Name]; Pinned = $p.Value; Section = 'providers'; Key = $p.Name })
    }
    foreach ($p in $Lock.pkg.PSObject.Properties) {
        $items.Add([pscustomobject]@{ Component = "pypi:$($p.Name)"; Kind = 'pypi'; Name = $p.Name; Pinned = $p.Value; Section = 'pkg'; Key = $p.Name })
    }
    foreach ($p in $Lock.actions.PSObject.Properties) {
        $items.Add([pscustomobject]@{ Component = "action:$($p.Name)"; Kind = 'action'; Name = $script:ActionRepo[$p.Name]; Pinned = ($p.Value -replace '^v', ''); Section = 'actions'; Key = $p.Name })
    }
    foreach ($section in 'avm_tf', 'tf_modules') {
        if ($Lock.PSObject.Properties.Name -notcontains $section) { continue }
        foreach ($p in $Lock.$section.PSObject.Properties) {
            $path = if ($section -eq 'avm_tf') { "Azure/avm-$($p.Name)/azurerm" } else { "Azure/$($p.Name)/azurerm" }
            $items.Add([pscustomobject]@{ Component = "tfmodule:$($p.Name)"; Kind = 'tfmodule'; Name = $path; Pinned = $p.Value; Section = $section; Key = $p.Name })
        }
    }
    if ($Lock.PSObject.Properties.Name -contains 'avm_bicep') {
        foreach ($p in $Lock.avm_bicep.PSObject.Properties) {
            $items.Add([pscustomobject]@{ Component = "bicepmodule:$($p.Name)"; Kind = 'bicepmodule'; Name = $p.Name; Pinned = $p.Value; Section = 'avm_bicep'; Key = $p.Name })
        }
    }
    $items
}

function Test-MLOpsAcceleratorVersion {
    <#
    .SYNOPSIS
    Compares pinned versions with the latest releases and warns about outdated components.
    .PARAMETER Path
    A generated project (reads .mlops-v3/versions.lock.json) or a lock file. Defaults to the accelerator's own lock.
    #>
    [CmdletBinding()]
    param([string] $Path)

    $lockPath = $script:LockPath
    if ($Path) {
        $candidate = if (Test-Path $Path -PathType Container) { Join-Path $Path '.mlops-v3/versions.lock.json' } else { $Path }
        if (-not (Test-Path $candidate)) { throw "No lock file found at $candidate" }
        $lockPath = $candidate
    }
    $lock = Get-MLOpsLock -Path $lockPath

    $results = foreach ($c in (Get-MLOpsComponent -Lock $lock)) {
        $held = $lock.PSObject.Properties.Name -contains 'holds' -and $lock.holds.PSObject.Properties.Name -contains $c.Component
        $latest = if ($held) { Get-LatestVersion -Kind $c.Kind -Name $c.Name -Major $(if ($c.Kind -eq 'pypi') { ($c.Pinned.Split('.')[0..1] -join '.') } else { $c.Pinned.Split('.')[0] }) } else { Get-LatestVersion -Kind $c.Kind -Name $c.Name }
        $status = if (-not $latest) { 'Unknown' } elseif ($latest -eq $c.Pinned) { 'Current' } else { 'Outdated' }
        [pscustomobject]@{ Component = $c.Component; Pinned = $c.Pinned; Latest = $latest; Status = $status }
    }
    foreach ($r in $results | Where-Object Status -EQ 'Outdated') {
        Write-Warning "$($r.Component) is outdated: pinned $($r.Pinned), latest $($r.Latest)"
    }
    $results
}

function Update-MLOpsAcceleratorVersion {
    <#
    .SYNOPSIS
    Moves the lock file to the latest releases, but only if the Python packages still resolve together.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param([string] $LockFile = $script:LockPath)

    $lock = Get-MLOpsLock -Path $LockFile
    $updates = @(Test-MLOpsAcceleratorVersion -Path $LockFile | Where-Object Status -EQ 'Outdated')
    if ($updates.Count -eq 0) { Write-Host 'Everything is current.'; return }

    $pins = foreach ($u in $updates | Where-Object { $_.Component -like 'pypi:*' }) { "$($u.Component.Substring(5))==$($u.Latest)" }
    $unchanged = foreach ($p in $lock.pkg.PSObject.Properties) { if ($updates.Component -notcontains "pypi:$($p.Name)") { "$($p.Name)==$($p.Value)" } }
    $all = @($pins) + @($unchanged) | Where-Object { $_ }

    if ($pins) {
        $python = Get-Command "python$($lock.python)" -ErrorAction SilentlyContinue
        if (-not $python) { $python = Get-Command python3 -ErrorAction SilentlyContinue }
        if (-not $python) { throw "Python $($lock.python) is required to verify that the updated packages resolve together." }
        $version = & $python.Source -c 'import sys;print(f"{sys.version_info[0]}.{sys.version_info[1]}")'
        if ($version -ne $lock.python) { throw "Found Python $version but the lock targets $($lock.python)." }
        & $python.Source -m pip install --dry-run --ignore-installed --only-binary=:all: --quiet @all
        if ($LASTEXITCODE -ne 0) {
            throw 'The latest Python packages do not resolve together on this Python version. The lock file was not changed.'
        }
    }

    foreach ($u in $updates) {
        $c = Get-MLOpsComponent -Lock $lock | Where-Object Component -EQ $u.Component
        $new = if ($c.Section -eq 'actions') { "v$($u.Latest)" } else { $u.Latest }
        if ($c.Section -eq 'terraform') { $lock.terraform = $new } else { $lock.($c.Section).($c.Key) = $new }
    }
    $lock.generatedOn = (Get-Date -Format 'yyyy-MM-dd')
    if ($PSCmdlet.ShouldProcess($LockFile, 'Write updated versions')) {
        $lock | ConvertTo-Json -Depth 5 | Set-Content -Path $LockFile
        Write-Host "Updated $($updates.Count) component(s). Re-run the generator to apply."
    }
}

Export-ModuleMember -Function Test-MLOpsAcceleratorRequirement, Remove-MLOpsAccelerator, Grant-MLOpsStorageAccess, Get-MLOpsScenario, New-MLOpsInputFile, Deploy-MLOpsAccelerator, Test-MLOpsAcceleratorInput, Test-MLOpsAcceleratorVersion, Update-MLOpsAcceleratorVersion
