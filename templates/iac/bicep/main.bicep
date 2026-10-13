targetScope = 'subscription'

param projectName string
param environment string
param location string
param locationShort string
@description('Deterministic 4 character suffix for globally unique names.')
param suffix string
param privateNetworking bool = false
param featureStore bool = false
param tags object = {}

var baseName = '${projectName}-${environment}-${locationShort}'
var allTags = union(tags, {
  project: projectName
  environment: environment
  'managed-by': 'mlops-v3'
})

resource rg 'Microsoft.Resources/resourceGroups@2024-11-01' = {
  name: 'rg-${baseName}'
  location: location
  tags: allTags
}

module workload 'workload.bicep' = {
  scope: rg
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
  }
}

output resourceGroupName string = rg.name
output workspaceName string = workload.outputs.workspaceName
