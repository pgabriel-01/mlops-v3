@minLength(3)
@maxLength(10)
param projectName string
param environment string
param location string
param baseName string
@minLength(4)
@maxLength(4)
param suffix string
param privateNetworking bool
param featureStore bool
param tags object
param enableTelemetry bool

var access = privateNetworking ? 'Disabled' : 'Enabled'

module logs 'br/public:avm/res/operational-insights/workspace:[[versions.avm_bicep.res/operational-insights/workspace]]' = {
  name: 'log-${baseName}'
  params: {
    name: 'log-${baseName}'
    location: location
    skuName: 'PerGB2018'
    dataRetention: 30
    tags: tags
    enableTelemetry: enableTelemetry
  }
}

module appi 'br/public:avm/res/insights/component:[[versions.avm_bicep.res/insights/component]]' = {
  name: 'appi-${baseName}'
  params: {
    name: 'appi-${baseName}'
    location: location
    applicationType: 'web'
    workspaceResourceId: logs.outputs.resourceId
    tags: tags
    enableTelemetry: enableTelemetry
  }
}

module storage 'br/public:avm/res/storage/storage-account:[[versions.avm_bicep.res/storage/storage-account]]' = {
  name: 'st-${baseName}'
  params: {
    name: 'st${projectName}${environment}${suffix}'
    location: location
    kind: 'StorageV2'
    skuName: environment == 'prod' ? 'Standard_ZRS' : 'Standard_LRS'
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    // Azure ML's default datastore uses account keys unless identity-based access is configured.
    allowSharedKeyAccess: true
    publicNetworkAccess: access
    tags: tags
    enableTelemetry: enableTelemetry
  }
}

module vault 'br/public:avm/res/key-vault/vault:[[versions.avm_bicep.res/key-vault/vault]]' = {
  name: 'kv-${baseName}'
  params: {
    name: 'kv-${projectName}-${environment}-${suffix}'
    location: location
    sku: 'standard'
    enableRbacAuthorization: true
    enablePurgeProtection: true
    softDeleteRetentionInDays: 7
    publicNetworkAccess: access
    tags: tags
    enableTelemetry: enableTelemetry
  }
}

module registry 'br/public:avm/res/container-registry/registry:[[versions.avm_bicep.res/container-registry/registry]]' = {
  name: 'cr-${baseName}'
  params: {
    name: 'cr${projectName}${environment}${suffix}'
    location: location
    acrSku: privateNetworking ? 'Premium' : 'Standard'
    acrAdminUserEnabled: false
    publicNetworkAccess: access
    tags: tags
    enableTelemetry: enableTelemetry
  }
}

module workspace 'br/public:avm/res/machine-learning-services/workspace:[[versions.avm_bicep.res/machine-learning-services/workspace]]' = {
  name: 'mlw-${baseName}'
  params: {
    name: 'mlw-${baseName}'
    location: location
    sku: 'Basic'
    managedIdentities: { systemAssigned: true }
    associatedApplicationInsightsResourceId: appi.outputs.resourceId
    associatedKeyVaultResourceId: vault.outputs.resourceId
    associatedStorageAccountResourceId: storage.outputs.resourceId
    associatedContainerRegistryResourceId: registry.outputs.resourceId
    publicNetworkAccess: access
    tags: tags
    enableTelemetry: enableTelemetry
  }
}

resource workspaceRef 'Microsoft.MachineLearningServices/workspaces@2025-06-01' existing = {
  name: 'mlw-${baseName}'
  dependsOn: [workspace]
}

resource cpu 'Microsoft.MachineLearningServices/workspaces/computes@2025-06-01' = {
  parent: workspaceRef
  name: 'cpu-cluster'
  location: location
  properties: {
    computeType: 'AmlCompute'
    properties: {
      vmSize: 'Standard_DS3_v2'
      vmPriority: 'Dedicated'
      scaleSettings: {
        minNodeCount: 0
        maxNodeCount: 4
        nodeIdleTimeBeforeScaleDown: 'PT15M'
      }
    }
  }
}

resource featureStoreWorkspace 'Microsoft.MachineLearningServices/workspaces@2025-06-01' = if (featureStore) {
  name: 'fs-${baseName}'
  location: location
  tags: tags
  kind: 'FeatureStore'
  identity: { type: 'SystemAssigned' }
  sku: { name: 'Basic', tier: 'Basic' }
  properties: {
    description: 'Managed feature store for ${projectName} (${environment})'
    publicNetworkAccess: access
  }
}

output workspaceName string = workspace.outputs.name
