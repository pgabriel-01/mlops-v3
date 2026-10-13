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
param privateNetworking bool = false
param featureStore bool = false
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
    privateNetworking: privateNetworking
    featureStore: featureStore
    tags: allTags
    enableTelemetry: enableTelemetry
  }
}

output resourceGroupName string = rg.outputs.name
output workspaceName string = workload.outputs.workspaceName
