targetScope = 'subscription'

@minLength(3)
@maxLength(10)
param projectName string
param environment string
param location string
param locationShort string
@description('Deterministic 4 character suffix for globally unique names.')
@minLength(4)
@maxLength(4)
param suffix string
@allowed(['public', 'managed_internet', 'managed_approved', 'byo_vnet'])
param networkMode string = 'public'
param featureStore bool = false
@description('Create the shared AML registry in this environment.')
param registry bool = false
param governance bool = false
@allowed(['audit', 'deny', 'none'])
param policyMode string = 'audit'
param genai bool = false
@description('Reuse an existing platform landing zone (subnet, private DNS zones, Log Analytics) instead of creating them.')
param existingPlatform bool = false
param vnetAddressSpace string = '10.20.0.0/16'
param allowedFqdns array = []
param computeVmSize string = 'Standard_DS3_v2'
param computeMaxNodes int = 4
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
    registry: registry
    governance: governance
    policyMode: policyMode
    genai: genai
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
