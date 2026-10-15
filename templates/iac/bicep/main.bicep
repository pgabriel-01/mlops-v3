targetScope = 'subscription'

@minLength(3)
@maxLength(10)
param projectName string
param environment string
param location string
param locationShort string
@description('Deterministic 5 character suffix for globally unique names.')
@minLength(5)
@maxLength(5)
param suffix string
@allowed(['public', 'managed_internet', 'managed_approved', 'byo_vnet'])
param networkMode string = 'public'
param featureStore bool = false
@description('Create the shared Azure ML registry in this environment.')
param registry bool = false
param governance bool = false
@allowed(['audit', 'deny', 'none'])
param policyMode string = 'audit'
param genai bool = false
@description('Add Azure AI Search and chat and embedding model deployments (requires genai).')
param rag bool = false
param chatModel string = 'gpt-5.4-mini'
param chatModelVersion string = '2026-03-17'
@description('Chat model capacity in thousands of tokens per minute (GlobalStandard).')
param chatCapacity int = 10
param embeddingModel string = 'text-embedding-3-small'
param embeddingModelVersion string = '1'
@description('Embedding model capacity in thousands of tokens per minute (GlobalStandard).')
param embeddingCapacity int = 10
@description('Azure AI Search tier. free allows one per subscription and has no private endpoints.')
param searchSku string = 'basic'
param searchLocation string = ''
@description('Object id of the pipeline identity, granted data-plane roles when rag is true.')
param deployerPrincipalId string = ''
@description('Reuse an existing platform landing zone (subnet, private DNS zones, Log Analytics) instead of creating them.')
param existingPlatform bool = false
param vnetAddressSpace string = '10.20.0.0/16'
param allowedFqdns array = []
param computeVmSize string = 'Standard_DS3_v2'
param computeMaxNodes int = 4
@minValue(7)
@maxValue(90)
param keyVaultRetentionDays int = 7
param budgetAmount int = 0
param alertEmails array = []
param existingSubnetId string = ''
param existingLawId string = ''
param existingDnsZones object = {}
param tags object = {}
@description('AVM module telemetry (anonymous deployment counters).')
param enableTelemetry bool = true

var baseName = '${projectName}-${environment}-${locationShort}'
var allTags = union(tags, {
  project: projectName
  environment: environment
  'managed-by': 'mlops-v3'
})

module rg 'br/public:avm/res/resources/resource-group:[[versions.avm_bicep.res/resources/resource-group]]' = {
  name: 'rg-${baseName}'
  params: {
    name: 'rg-${baseName}'
    location: location
    tags: allTags
    enableTelemetry: enableTelemetry
  }
}

module budget 'br/public:avm/res/consumption/budget:[[versions.avm_bicep.res/consumption/budget]]' = if (governance && budgetAmount > 0 && !empty(alertEmails)) {
  name: 'budget-${baseName}'
  dependsOn: [rg]
  params: {
    name: 'budget-${baseName}'
    amount: budgetAmount
    category: 'Cost'
    resetPeriod: 'Monthly'
    contactEmails: alertEmails
    resourceGroupFilter: ['rg-${baseName}']
    thresholds: [80, 100]
    enableTelemetry: enableTelemetry
  }
}

module workload 'workload.bicep' = {
  scope: resourceGroup('rg-${baseName}')
  dependsOn: [rg]
  name: 'workload'
  params: {
    projectName: projectName
    environment: environment
    location: location
    baseName: baseName
    suffix: suffix
    locationShort: locationShort
    networkMode: networkMode
    featureStore: featureStore
    computeVmSize: computeVmSize
    computeMaxNodes: computeMaxNodes
    keyVaultRetentionDays: keyVaultRetentionDays
    registry: registry
    governance: governance
    policyMode: policyMode
    genai: genai
    rag: rag
    chatModel: chatModel
    chatModelVersion: chatModelVersion
    chatCapacity: chatCapacity
    embeddingModel: embeddingModel
    embeddingModelVersion: embeddingModelVersion
    embeddingCapacity: embeddingCapacity
    searchSku: searchSku
    searchLocation: searchLocation
    deployerPrincipalId: deployerPrincipalId
    existingPlatform: existingPlatform
    vnetAddressSpace: vnetAddressSpace
    allowedFqdns: allowedFqdns
    existingSubnetId: existingSubnetId
    existingLawId: existingLawId
    existingDnsZones: existingDnsZones
    tags: allTags
    enableTelemetry: enableTelemetry
  }
}

output resourceGroupName string = rg.outputs.name
output workspaceName string = workload.outputs.workspaceName
output registryName string = workload.outputs.registryName
output searchName string = workload.outputs.searchName
output aiServicesEndpoint string = workload.outputs.aiServicesEndpoint
