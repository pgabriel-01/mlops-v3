<#
.SYNOPSIS
  Estimates the fixed monthly infrastructure cost of each AML scenario from Azure Retail Prices (public API, no login).
.DESCRIPTION
  Fixed costs only: private endpoints, private DNS zones, ACR, the managed-network firewall (scenario 3), and optionally
  one online-endpoint instance per environment. Consumption costs (training compute, log ingestion, storage, model
  tokens) are NOT included. Every environment gets its own copy of the infrastructure, except the shared registry.
.EXAMPLE
  ./scripts/Get-ScenarioCostEstimates.ps1 -Region westus -Environments 3 -AsMarkdown
#>
[CmdletBinding()]
param(
    [string] $Region = 'westus',
    [string] $Currency = 'USD',
    [ValidateRange(1, 10)][int] $Environments = 3,
    [switch] $AsMarkdown
)
$ErrorActionPreference = 'Stop'
$hours = 730; $days = $hours / 24

function Get-RetailPrice([string] $Filter, [string] $FallbackFilter) {
    $uri = 'https://prices.azure.com/api/retail/prices?currencyCode=' + $Currency + '&$filter=' + [uri]::EscapeDataString($Filter)
    for ($try = 1; $try -le 8; $try++) {
        try {
            $items = (Invoke-RestMethod -Uri $uri -TimeoutSec 30).Items | Where-Object { $_.type -eq 'Consumption' }
            $hit = $items | Sort-Object retailPrice -Descending | Select-Object -First 1
            if (-not $hit -and $FallbackFilter) { return Get-RetailPrice $FallbackFilter }
            if (-not $hit) { throw "No price found for: $Filter" }
            return [double] $hit.retailPrice
        }
        catch {
            if ($try -eq 8 -or $_.Exception.Message -like 'No price*') { throw }
            Start-Sleep -Seconds (5 * $try)
        }
    }
}

$r = "armRegionName eq '$Region'"
$unit = [ordered]@{
    private_endpoint = (Get-RetailPrice "$r and productName eq 'Virtual Network Private Link' and meterName eq 'Standard Private Endpoint'" "productName eq 'Virtual Network Private Link' and meterName eq 'Standard Private Endpoint' and priceType eq 'Consumption' and armRegionName ne 'US Gov'") * $hours
    dns_zone         = (Get-RetailPrice "serviceName eq 'Azure DNS' and meterName eq 'Private Zone'")
    acr_standard     = (Get-RetailPrice "$r and serviceName eq 'Container Registry' and skuName eq 'Standard' and meterName eq 'Standard Registry Unit'") * $days
    acr_premium      = (Get-RetailPrice "$r and serviceName eq 'Container Registry' and skuName eq 'Premium' and meterName eq 'Premium Registry Unit'") * $days
    firewall         = (Get-RetailPrice "$r and serviceName eq 'Azure Firewall' and skuName eq 'Standard' and meterName eq 'Standard Deployment'") * $hours
    online_instance  = (Get-RetailPrice "$r and serviceName eq 'Virtual Machines' and armSkuName eq 'Standard_DS3_v2' and productName eq 'Virtual Machines DSv2 Series'") * $hours
}

$modulePath = Join-Path $PSScriptRoot '../src/MLOpsAccelerator/MLOpsAccelerator.psd1'
Import-Module $modulePath -Force
$rows = foreach ($sc in Get-MLOpsScenario) {
    $private = $sc.network_mode -ne 'public'
    $acr = if ($private) { $unit.acr_premium } else { $unit.acr_standard }
    $perEnv = $acr
    if ($sc.network_mode -eq 'byo_vnet') {
        $perEnv += 5 * $unit.private_endpoint
        if (-not $sc.existing_platform) { $perEnv += 6 * $unit.dns_zone }
    }
    if ($sc.network_mode -eq 'managed_approved') { $perEnv += $unit.firewall }
    $shared = if ($sc.registry) { $unit.acr_premium } else { 0 }
    $fixed = $perEnv * $Environments + $shared
    $online = if ($sc.endpoint_type -eq 'online') { $unit.online_instance * $Environments } else { 0 }
    [pscustomobject]@{ Number = $sc.number; Scenario = $sc.id; Fixed = [math]::Round($fixed, 2); WithOneEndpointPerEnv = [math]::Round($fixed + $online, 2) }
}

if ($AsMarkdown) {
    "| # | Scenario | Fixed infrastructure / month | With one online instance per environment |"
    "|---|---|---:|---:|"
    foreach ($x in $rows) { '| {0} | `{1}` | {2:N2} | {3:N2} |' -f $x.Number, $x.Scenario, $x.Fixed, $x.WithOneEndpointPerEnv }
    ''
    "Region **$Region**, **$Currency**, **$Environments** environments, retrieved $(Get-Date -Format 'yyyy-MM-dd')."
}
else { $rows | Format-Table -AutoSize; $unit | Format-Table -AutoSize }
