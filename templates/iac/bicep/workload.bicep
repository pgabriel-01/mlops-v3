@minLength(3)
@maxLength(10)
param projectName string
param environment string
param location string
param locationShort string
param baseName string
@minLength(5)
@maxLength(5)
param suffix string
param networkMode string
param featureStore bool
param computeVmSize string
param computeMaxNodes int
param keyVaultRetentionDays int
param registry bool
param governance bool
@allowed(['audit', 'deny', 'none'])
param policyMode string = 'audit'
param genai bool
param rag bool = false
param chatModel string = 'gpt-5.4-mini'
param chatModelVersion string = '2026-03-17'
param chatCapacity int = 10
param embeddingModel string = 'text-embedding-3-small'
param embeddingModelVersion string = '1'
param embeddingCapacity int = 10
param searchSku string = 'basic'
@description('Azure region for Azure AI Search. Empty uses the main location.')
param searchLocation string = ''
@description('Object id of the identity that runs the pipelines. Granted data-plane roles on Search and the models when rag is true.')
param deployerPrincipalId string = ''
param existingPlatform bool
param vnetAddressSpace string
param allowedFqdns array
param existingSubnetId string
param existingLawId string
param existingDnsZones object
param tags object
param enableTelemetry bool

var isPublic = networkMode == 'public'
var isManaged = networkMode == 'managed_internet' || networkMode == 'managed_approved'
var isByo = networkMode == 'byo_vnet'
var access = isPublic ? 'Enabled' : 'Disabled'
var createNet = isByo && !existingPlatform
var createLaw = !(existingPlatform && !empty(existingLawId))
var usePe = isByo

var zoneNames = {
  blob: 'privatelink.blob.${az.environment().suffixes.storage}'
  file: 'privatelink.file.${az.environment().suffixes.storage}'
  vault: 'privatelink.vaultcore.azure.net'
  acr: 'privatelink.azurecr.io'
  aml_api: 'privatelink.api.azureml.ms'
  aml_notebooks: 'privatelink.notebooks.azure.net'
  cognitiveservices: 'privatelink.cognitiveservices.azure.com'
  openai: 'privatelink.openai.azure.com'
  aiservices: 'privatelink.services.ai.azure.com'
  search: 'privatelink.search.windows.net'
}
var zoneKeys = filter(objectKeys(zoneNames), k => (genai || !contains(['cognitiveservices', 'openai', 'aiservices'], k)) && (rag || k != 'search'))
var zoneIds = toObject(objectKeys(zoneNames), k => k, k => createNet
  ? resourceId('Microsoft.Network/privateDnsZones', zoneNames[k])
  : (existingDnsZones[?k] ?? ''))
var peSubnetId = createNet ? vnet!.outputs.subnetResourceIds[0] : existingSubnetId
var computeSubnetId = createNet ? vnet!.outputs.subnetResourceIds[1] : existingSubnetId

// Private endpoint definition for one sub-resource, linked to zero or more private DNS zones.
func peFor(subnetId string, service string, zoneIds array) object => {
  subnetResourceId: subnetId
  service: service
  privateDnsZoneGroup: empty(zoneIds) ? null : {
    privateDnsZoneGroupConfigs: map(zoneIds, z => { privateDnsZoneResourceId: z })
  }
}

func nonEmpty(values array) array => filter(values, v => !empty(v))

var diagSettings = governance ? [
  {
    name: 'to-law'
    workspaceResourceId: lawId
    logCategoriesAndGroups: [{ categoryGroup: 'allLogs' }]
    metricCategories: [{ category: 'AllMetrics' }]
  }
] : []
var storageDiag = governance ? [
  {
    name: 'to-law'
    workspaceResourceId: lawId
    metricCategories: [{ category: 'Transaction' }]
  }
] : []
var blobDiag = governance ? [
  {
    name: 'to-law'
    workspaceResourceId: lawId
    logCategoriesAndGroups: [{ categoryGroup: 'allLogs' }]
  }
] : []
var allow = {
  defaultAction: 'Allow'
  bypass: 'AzureServices'
}

var deny = {
  defaultAction: 'Deny'
  bypass: 'AzureServices'
}

module vnet 'br/public:avm/res/network/virtual-network:[[versions.avm_bicep.res/network/virtual-network]]' = if (createNet) {
  name: 'vnet-${baseName}'
  params: {
    name: 'vnet-${baseName}'
    location: location
    addressPrefixes: [vnetAddressSpace]
    subnets: [
      {
        name: 'snet-pe'
        addressPrefix: cidrSubnet(vnetAddressSpace, 24, 0)
        privateEndpointNetworkPolicies: 'Disabled'
      }
      {
        name: 'snet-training'
        addressPrefix: cidrSubnet(vnetAddressSpace, 24, 1)
      }
    ]
    tags: tags
    enableTelemetry: enableTelemetry
  }
}

module dnsZones 'br/public:avm/res/network/private-dns-zone:[[versions.avm_bicep.res/network/private-dns-zone]]' = [for k in zoneKeys: if (createNet) {
  name: 'pdns-${k}-${baseName}'
  params: {
    name: zoneNames[k]
    virtualNetworkLinks: [{ virtualNetworkResourceId: vnet!.outputs.resourceId }]
    tags: tags
    enableTelemetry: enableTelemetry
  }
}]

module logs 'br/public:avm/res/operational-insights/workspace:[[versions.avm_bicep.res/operational-insights/workspace]]' = if (createLaw) {
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

var lawId = createLaw ? logs!.outputs.resourceId : existingLawId

module appi 'br/public:avm/res/insights/component:[[versions.avm_bicep.res/insights/component]]' = {
  name: 'appi-${baseName}'
  params: {
    name: 'appi-${baseName}'
    location: location
    applicationType: 'web'
    workspaceResourceId: lawId
    tags: tags
    enableTelemetry: enableTelemetry
  }
}

module storage 'br/public:avm/res/storage/storage-account:[[versions.avm_bicep.res/storage/storage-account]]' = {
  name: 'st-${baseName}'
  dependsOn: [dnsZones]
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
    networkAcls: isPublic ? allow : deny
    privateEndpoints: usePe ? [
      peFor(peSubnetId, 'blob', nonEmpty([zoneIds.blob]))
      peFor(peSubnetId, 'file', nonEmpty([zoneIds.file]))
    ] : []
    diagnosticSettings: storageDiag
    blobServices: { diagnosticSettings: blobDiag }
    tags: tags
    enableTelemetry: enableTelemetry
  }
}

module vault 'br/public:avm/res/key-vault/vault:[[versions.avm_bicep.res/key-vault/vault]]' = {
  name: 'kv-${baseName}'
  dependsOn: [dnsZones]
  params: {
    name: 'kv-${projectName}-${environment}-${suffix}'
    location: location
    sku: 'standard'
    enableRbacAuthorization: true
    enablePurgeProtection: true
    softDeleteRetentionInDays: keyVaultRetentionDays
    publicNetworkAccess: access
    networkAcls: isPublic ? allow : deny
    privateEndpoints: usePe ? [peFor(peSubnetId, 'vault', nonEmpty([zoneIds.vault]))] : []
    diagnosticSettings: diagSettings
    tags: tags
    enableTelemetry: enableTelemetry
  }
}

module acr 'br/public:avm/res/container-registry/registry:[[versions.avm_bicep.res/container-registry/registry]]' = {
  name: 'cr-${baseName}'
  dependsOn: [dnsZones]
  params: {
    name: 'cr${projectName}${environment}${suffix}'
    location: location
    acrSku: isPublic ? 'Standard' : 'Premium'
    acrAdminUserEnabled: false
    zoneRedundancy: isPublic ? 'Disabled' : 'Enabled'
    publicNetworkAccess: access
    networkRuleBypassOptions: 'AzureServices'
    networkRuleSetDefaultAction: isPublic ? 'Allow' : 'Deny'
    privateEndpoints: usePe ? [peFor(peSubnetId, 'registry', nonEmpty([zoneIds.acr]))] : []
    diagnosticSettings: diagSettings
    tags: tags
    enableTelemetry: enableTelemetry
  }
}

var fqdnRules = networkMode == 'managed_approved' ? toObject(range(0, length(allowedFqdns)), i => 'fqdn-${i}', i => {
  type: 'FQDN'
  destination: allowedFqdns[i]
  category: 'UserDefined'
}) : {}
var managedNetwork = isManaged ? {
  isolationMode: networkMode == 'managed_approved' ? 'AllowOnlyApprovedOutbound' : 'AllowInternetOutbound'
  firewallSku: length(fqdnRules) > 0 ? 'Standard' : null
  outboundRules: fqdnRules
} : null

// Inbound private endpoint to the workspace or hub when a subnet and Azure ML DNS zones are available.
var amlZones = nonEmpty([zoneIds.aml_api, zoneIds.aml_notebooks])
var workspacePe = (isByo || (isManaged && !empty(existingSubnetId))) ? [
  peFor(peSubnetId, 'amlworkspace', amlZones)
] : []

module workspace 'br/public:avm/res/machine-learning-services/workspace:[[versions.avm_bicep.res/machine-learning-services/workspace]]' = {
  name: 'mlw-${baseName}'
  dependsOn: [dnsZones]
  params: {
    name: 'mlw-${baseName}'
    location: location
    sku: 'Basic'
    managedIdentities: { systemAssigned: true }
    associatedApplicationInsightsResourceId: appi.outputs.resourceId
    associatedKeyVaultResourceId: vault.outputs.resourceId
    associatedStorageAccountResourceId: storage.outputs.resourceId
    associatedContainerRegistryResourceId: acr.outputs.resourceId
    publicNetworkAccess: access
    managedNetworkSettings: managedNetwork
    provisionNetworkNow: isManaged
    privateEndpoints: workspacePe
    diagnosticSettings: diagSettings
    lock: governance ? { kind: 'CanNotDelete', name: 'lock-mlw-${baseName}' } : null
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
    disableLocalAuth: true
    properties: {
      vmSize: computeVmSize
      vmPriority: 'Dedicated'
      enableNodePublicIp: isPublic
      subnet: isByo ? { id: computeSubnetId } : null
      scaleSettings: {
        minNodeCount: 0
        maxNodeCount: computeMaxNodes
        nodeIdleTimeBeforeScaleDown: 'PT15M'
      }
    }
  }
}

module featureStoreWorkspace 'br/public:avm/res/machine-learning-services/workspace:[[versions.avm_bicep.res/machine-learning-services/workspace]]' = if (featureStore) {
  name: 'fs-${baseName}'
  params: {
    name: 'fs-${baseName}'
    location: location
    sku: 'Basic'
    kind: 'FeatureStore'
    featureStoreSettings: { computeRuntime: { sparkRuntimeVersion: '3.4.0' } }
    description: 'Managed feature store for ${projectName} (${environment})'
    managedIdentities: { systemAssigned: true }
    associatedApplicationInsightsResourceId: appi.outputs.resourceId
    associatedKeyVaultResourceId: vault.outputs.resourceId
    associatedStorageAccountResourceId: storage.outputs.resourceId
    publicNetworkAccess: access
    // Serverless Spark needs a managed network, and AllowInternetOutbound is the only mode feature stores support.
    managedNetworkSettings: { isolationMode: 'AllowInternetOutbound' }
    provisionNetworkNow: true
    tags: tags
    enableTelemetry: enableTelemetry
  }
}

module amlRegistry 'br/public:avm/res/machine-learning-services/registry:[[versions.avm_bicep.res/machine-learning-services/registry]]' = if (registry) {
  name: 'reg-${projectName}-${locationShort}'
  params: {
    name: 'reg-${projectName}-${locationShort}'
    location: location
    locations: [location]
    publicNetworkAccess: access
    tags: tags
    enableTelemetry: enableTelemetry
  }
}

var aiServicesPes = (isByo && genai) ? [
  peFor(peSubnetId, 'account', nonEmpty([zoneIds.cognitiveservices, zoneIds.openai, zoneIds.aiservices]))
] : []

module aiServices 'br/public:avm/res/cognitive-services/account:[[versions.avm_bicep.res/cognitive-services/account]]' = if (genai) {
  name: 'ais-${baseName}'
  dependsOn: [dnsZones]
  params: {
    name: 'ais-${projectName}-${environment}-${suffix}'
    location: location
    kind: 'AIServices'
    sku: 'S0'
    customSubDomainName: 'ais-${projectName}-${environment}-${suffix}'
    disableLocalAuth: true
    allowProjectManagement: false
    managedIdentities: { systemAssigned: true }
    publicNetworkAccess: access
    networkAcls: isPublic ? allow : deny
    privateEndpoints: aiServicesPes
    deployments: rag ? [
      {
        name: 'chat'
        model: { format: 'OpenAI', name: chatModel, version: chatModelVersion }
        sku: { name: 'GlobalStandard', capacity: chatCapacity }
      }
      {
        name: 'embedding'
        model: { format: 'OpenAI', name: embeddingModel, version: embeddingModelVersion }
        sku: { name: 'GlobalStandard', capacity: embeddingCapacity }
      }
    ] : []
    roleAssignments: (rag && !empty(deployerPrincipalId)) ? [
      {
        principalId: deployerPrincipalId
        roleDefinitionIdOrName: 'Cognitive Services OpenAI User'
      }
    ] : []
    diagnosticSettings: diagSettings
    tags: tags
    enableTelemetry: enableTelemetry
  }
}

module hub 'br/public:avm/res/machine-learning-services/workspace:[[versions.avm_bicep.res/machine-learning-services/workspace]]' = if (genai) {
  name: 'hub-${baseName}'
  dependsOn: [dnsZones]
  params: {
    name: 'hub-${baseName}'
    location: location
    sku: 'Basic'
    kind: 'Hub'
    description: 'AI Foundry hub for ${projectName} (${environment})'
    managedIdentities: { systemAssigned: true }
    associatedApplicationInsightsResourceId: appi.outputs.resourceId
    associatedKeyVaultResourceId: vault.outputs.resourceId
    associatedStorageAccountResourceId: storage.outputs.resourceId
    associatedContainerRegistryResourceId: acr.outputs.resourceId
    publicNetworkAccess: access
    managedNetworkSettings: managedNetwork
    privateEndpoints: workspacePe
    diagnosticSettings: diagSettings
    connections: [
      {
        name: 'aiservices'
        category: 'AIServices'
        target: aiServices!.outputs.endpoint
        isSharedToAll: true
        metadata: {
          ApiType: 'Azure'
          ResourceId: aiServices!.outputs.resourceId
        }
        connectionProperties: { authType: 'AAD' }
      }
    ]
    tags: tags
    enableTelemetry: enableTelemetry
  }
}

module project 'br/public:avm/res/machine-learning-services/workspace:[[versions.avm_bicep.res/machine-learning-services/workspace]]' = if (genai) {
  name: 'proj-${baseName}'
  params: {
    name: 'proj-${baseName}'
    location: location
    sku: 'Basic'
    kind: 'Project'
    description: 'AI Foundry project for ${projectName} (${environment})'
    hubResourceId: hub!.outputs.resourceId
    managedIdentities: { systemAssigned: true }
    publicNetworkAccess: access
    tags: tags
    enableTelemetry: enableTelemetry
  }
}

var searchPes = (isByo && rag) ? [
  peFor(peSubnetId, 'searchService', nonEmpty([zoneIds.search]))
] : []

module search 'br/public:avm/res/search/search-service:[[versions.avm_bicep.res/search/search-service]]' = if (rag) {
  name: 'srch-${baseName}'
  dependsOn: [dnsZones]
  params: {
    name: 'srch-${projectName}-${environment}-${suffix}'
    location: empty(searchLocation) ? location : searchLocation
    sku: searchSku
    replicaCount: 1
    partitionCount: 1
    disableLocalAuth: true
    authOptions: null
    managedIdentities: { systemAssigned: true }
    publicNetworkAccess: access
    privateEndpoints: searchPes
    roleAssignments: concat([
      {
        principalId: project!.outputs.systemAssignedMIPrincipalId
        roleDefinitionIdOrName: 'Search Index Data Reader'
        principalType: 'ServicePrincipal'
      }
      {
        principalId: project!.outputs.systemAssignedMIPrincipalId
        roleDefinitionIdOrName: 'Search Service Contributor'
        principalType: 'ServicePrincipal'
      }
    ], empty(deployerPrincipalId) ? [] : [
      {
        principalId: deployerPrincipalId
        roleDefinitionIdOrName: 'Search Index Data Contributor'
      }
      {
        principalId: deployerPrincipalId
        roleDefinitionIdOrName: 'Search Service Contributor'
      }
    ])
    diagnosticSettings: diagSettings
    tags: tags
    enableTelemetry: enableTelemetry
  }
}

resource projectRes 'Microsoft.MachineLearningServices/workspaces@2025-06-01' existing = if (rag) {
  name: 'proj-${baseName}'
  dependsOn: [project]
}

resource aiServicesRes 'Microsoft.CognitiveServices/accounts@2025-06-01' existing = if (rag) {
  name: 'ais-${projectName}-${environment}-${suffix}'
  dependsOn: [aiServices]
}

// Outside the AI Services module to avoid a dependency cycle (Search depends on the project, which depends on the account).
resource searchOpenAiUser 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (rag) {
  scope: aiServicesRes
  name: guid(aiServicesRes.id, 'search-openai-user')
  properties: {
    principalId: search!.outputs.systemAssignedMIPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd')
  }
}

resource searchConnection 'Microsoft.MachineLearningServices/workspaces/connections@2025-06-01' = if (rag) {
  parent: projectRes
  name: 'aisearch'
  properties: {
    category: 'CognitiveSearch'
    target: 'https://${search!.outputs.name}.search.windows.net'
    authType: 'AAD'
    metadata: {
      ApiType: 'Azure'
      ResourceId: search!.outputs.resourceId
    }
  }
}

// Built-in policy guardrails on the resource group (policyMode: audit, deny or none).
// The AVM policy-assignment pattern deploys at management-group scope, so a resource-group assignment is raw.
var policyEffect = policyMode == 'deny' ? 'Deny' : 'Audit'
var policies = concat([
  {
    key: 'compute-local-auth'
    name: 'Compute should have local authentication disabled'
    id: 'e96a9a5f-07ca-471b-9bc5-6a0f33cbd68f'
    parameters: { effect: { value: policyEffect } }
    enforce: true
  }
  {
    key: 'require-project-tag'
    name: 'Require the project tag'
    id: '871b6d14-10aa-478d-b590-94f262ecfa99'
    parameters: { tagName: { value: 'project' } }
    enforce: policyMode == 'deny'
  }
], isPublic ? [] : [
  {
    key: 'workspace-no-public-access'
    name: 'ML workspaces should disable public network access'
    id: '438c38d2-3772-465a-a9cc-7a6666a275ce'
    parameters: { effect: { value: policyEffect } }
    enforce: true
  }
])

resource guardrails 'Microsoft.Authorization/policyAssignments@2025-03-01' = [for p in policies: if (policyMode != 'none') {
  name: take('mlops-${environment}-${p.key}', 64)
  properties: {
    displayName: '${p.name} (${baseName})'
    policyDefinitionId: tenantResourceId('Microsoft.Authorization/policyDefinitions', p.id)
    parameters: p.parameters
    enforcementMode: p.enforce ? 'Default' : 'DoNotEnforce'
  }
}]

output workspaceName string = workspace.outputs.name
output registryName string = registry ? amlRegistry!.outputs.name : ''
output searchName string = rag ? search!.outputs.name : ''
output aiServicesEndpoint string = genai ? aiServices!.outputs.endpoint : ''
