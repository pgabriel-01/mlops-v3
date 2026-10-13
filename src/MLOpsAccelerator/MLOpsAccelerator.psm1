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
    if (-not $data.ContainsKey('environments')) { $data['environments'] = @('dev', 'prod') }
    if (-not $data.ContainsKey('private_networking')) { $data['private_networking'] = $false }
    if (-not $data.ContainsKey('feature_store')) { $data['feature_store'] = $false }
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
        data_source            = $Inputs['data_source']
        private_networking     = ([bool]$Inputs['private_networking']).ToString().ToLower()
        feature_store          = ([bool]$Inputs['feature_store']).ToString().ToLower()
        endpoint_public_access = $(if ($Inputs['private_networking']) { 'disabled' } else { 'enabled' })
        environments_csv       = ($envs -join ', ')
        environments_yaml_list = '[' + (($envs | ForEach-Object { '"' + $_ + '"' }) -join ', ') + ']'
        environments_hcl_list  = '[' + (($envs | ForEach-Object { '"' + $_ + '"' }) -join ', ') + ']'
        tags_hcl               = (($tagKeys | ForEach-Object { '  {0} = "{1}"' -f ('"' + $_ + '"').PadRight($tagWidth), $tags[$_] }) -join "`n")
        tags_bicep             = (($tagKeys | ForEach-Object { "  '{0}': '{1}'" -f $_, $tags[$_] }) -join "`n")
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
    param($When, $Inputs)
    if ($null -eq $When) { return $true }
    foreach ($p in $When.PSObject.Properties) {
        if ([string]$Inputs[$p.Name] -ne [string]$p.Value) { return $false }
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
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string] $InputFile,
        [Parameter(Mandatory)][string] $OutputPath,
        [switch] $Deploy,
        [switch] $Destroy,
        [switch] $Force,
        [switch] $SkipVersionCheck
    )

    $inputs = Read-MLOpsInput -Path $InputFile
    $lock = Get-MLOpsLock

    if ($Destroy) {
        Invoke-MLOpsBootstrap -ProjectPath $OutputPath -Inputs $inputs -Destroy
        return
    }

    if (-not $SkipVersionCheck) {
        $stale = @(Test-MLOpsAcceleratorVersion | Where-Object Status -EQ 'Outdated')
        if ($stale.Count -gt 0) {
            Write-Warning ("{0} pinned component(s) are outdated; run Update-MLOpsAcceleratorVersion. Continuing with the tested pins." -f $stale.Count)
        }
    }

    if ((Test-Path $OutputPath) -and (Get-ChildItem -Force -Path $OutputPath | Select-Object -First 1) -and -not $Force) {
        throw "Output path '$OutputPath' is not empty. Use -Force to overwrite."
    }

    $map = New-MLOpsTokenMap -Inputs $inputs -Lock $lock
    $envs = @($inputs['environments'])
    $manifest = Get-Content -Raw -Path (Join-Path $script:TemplateRoot 'manifest.json') | ConvertFrom-Json

    if (-not $PSCmdlet.ShouldProcess($OutputPath, 'Generate MLOps repository')) { return }
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    $OutputPath = (Resolve-Path $OutputPath).Path

    foreach ($entry in $manifest) {
        if (-not (Test-ManifestCondition -When $(if ($entry.PSObject.Properties.Name -contains 'when') { $entry.when }) -Inputs $inputs)) { continue }
        $render = -not ($entry.PSObject.Properties.Name -contains 'render' -and $entry.render -eq $false)
        $srcRoot = Join-Path $script:TemplateRoot $entry.src
        foreach ($file in Get-ChildItem -Recurse -File -Path $srcRoot) {
            $relative = [IO.Path]::GetRelativePath($srcRoot, $file.FullName)
            if ($relative -like '*__env__*') {
                foreach ($e in $envs) {
                    $local = $map.Clone(); $local['env'] = $e
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

    if ($Deploy) { Invoke-MLOpsBootstrap -ProjectPath $OutputPath -Inputs $inputs }
    else { Write-Host "Next: cd '$OutputPath/bootstrap'; terraform init; terraform apply -var-file=bootstrap.tfvars" }
}

function Invoke-MLOpsBootstrap {
    param([Parameter(Mandatory)][string] $ProjectPath, [Parameter(Mandatory)] $Inputs, [switch] $Destroy)

    foreach ($tool in 'terraform', 'az') {
        if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) { throw "'$tool' is required on PATH." }
    }
    az account show --only-show-errors *> $null
    if ($LASTEXITCODE -ne 0) { throw "Run 'az login' first." }

    if ($Inputs['cicd'] -eq 'github' -and -not $env:GITHUB_TOKEN) {
        if (Get-Command gh -ErrorAction SilentlyContinue) { $env:GITHUB_TOKEN = (gh auth token) }
        if (-not $env:GITHUB_TOKEN) { throw 'Set GITHUB_TOKEN (or run gh auth login) so the bootstrap can configure the repository.' }
    }
    if ($Inputs['cicd'] -eq 'azdo' -and -not $env:AZDO_PERSONAL_ACCESS_TOKEN) {
        throw 'Set AZDO_PERSONAL_ACCESS_TOKEN so the bootstrap can configure Azure DevOps.'
    }

    $dir = Join-Path $ProjectPath 'bootstrap'
    $env:ARM_SUBSCRIPTION_ID = $Inputs['subscription_id']
    terraform "-chdir=$dir" init -input=false
    if ($LASTEXITCODE -ne 0) { throw 'terraform init failed' }
    $verb = if ($Destroy) { 'destroy' } else { 'apply' }
    terraform "-chdir=$dir" $verb -var-file=bootstrap.tfvars
    if ($LASTEXITCODE -ne 0) { throw "terraform $verb failed" }
}

function Get-LatestVersion {
    param([string] $Kind, [string] $Name, [string] $Major)
    try {
        if ($Major -and $Kind -eq 'provider') {
            $all = (Invoke-RestMethod -Uri "https://registry.terraform.io/v1/providers/$Name/versions" -TimeoutSec 20).versions.version
            return ($all | Where-Object { $_ -match "^$Major\.\d+\.\d+$" } | Sort-Object { [version]$_ } | Select-Object -Last 1)
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
        $latest = if ($held) { Get-LatestVersion -Kind $c.Kind -Name $c.Name -Major ($c.Pinned.Split('.')[0]) } else { Get-LatestVersion -Kind $c.Kind -Name $c.Name }
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

Export-ModuleMember -Function Deploy-MLOpsAccelerator, Test-MLOpsAcceleratorInput, Test-MLOpsAcceleratorVersion, Update-MLOpsAcceleratorVersion
