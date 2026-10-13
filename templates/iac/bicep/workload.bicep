param projectName string
param environment string
param location string
param baseName string
param suffix string
param privateNetworking bool
param featureStore bool
param tags object

var access = privateNetworking ? 'Disabled' : 'Enabled'

resource logs 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: 'log-${baseName}'
  location: location
  tags: tags
  properties: {
    sku: { name: 'PerGB2018' }
    retentionInDays: 30
  }
}

resource appi 'Microsoft.Insights/components@2020-02-02' = {
  name: 'appi-${baseName}'
  location: location
  kind: 'web'
  tags: tags
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logs.id
  }
}

resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: 'st${projectName}${environment}${suffix}'
  location: location
  kind: 'StorageV2'
  tags: tags
  sku: { name: environment == 'prod' ? 'Standard_ZRS' : 'Standard_LRS' }
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    publicNetworkAccess: access
  }
}

resource vault 'Microsoft.KeyVault/vaults@2024-11-01' = {
  name: 'kv-${projectName}-${environment}-${suffix}'
  location: location
  tags: tags
  properties: {
    tenantId: tenant().tenantId
    sku: { family: 'A', name: 'standard' }
    enableRbacAuthorization: true
    enablePurgeProtection: true
    softDeleteRetentionInDays: 7
    publicNetworkAccess: access
  }
}

resource registry 'Microsoft.ContainerRegistry/registries@2025-04-01' = {
  name: 'cr${projectName}${environment}${suffix}'
  location: location
  tags: tags
  sku: { name: privateNetworking ? 'Premium' : 'Standard' }
  properties: {
    adminUserEnabled: false
    publicNetworkAccess: access
  }
}

resource workspace 'Microsoft.MachineLearningServices/workspaces@2025-06-01' = {
  name: 'mlw-${baseName}'
  location: location
  tags: tags
  kind: 'Default'
  identity: { type: 'SystemAssigned' }
  sku: { name: 'Basic', tier: 'Basic' }
  properties: {
    friendlyName: 'mlw-${baseName}'
    applicationInsights: appi.id
    keyVault: vault.id
    storageAccount: storage.id
    containerRegistry: registry.id
    publicNetworkAccess: access
  }
}

resource cpu 'Microsoft.MachineLearningServices/workspaces/computes@2025-06-01' = {
  parent: workspace
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

output workspaceName string = workspace.name
