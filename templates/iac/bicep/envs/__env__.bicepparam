using '../main.bicep'

param projectName = '[[project_name]]'
param environment = '[[env]]'
param location = '[[location]]'
param locationShort = '[[location_short]]'
param suffix = '[[suffix]]'
param networkMode = '[[network_mode]]'
param featureStore = [[feature_store]]
param registry = [[registry]]
param governance = [[governance]]
param policyMode = '[[policy_mode]]'
param genai = [[genai]]
param rag = [[rag]]
param chatModel = '[[chat_model]]'
param chatModelVersion = '[[chat_model_version]]'
param chatCapacity = [[chat_capacity]]
param embeddingModel = '[[embedding_model]]'
param embeddingModelVersion = '[[embedding_model_version]]'
param embeddingCapacity = [[embedding_capacity]]
param searchSku = '[[search_sku]]'
param deployerPrincipalId = readEnvironmentVariable('DEPLOYER_PRINCIPAL_ID', '')
param existingPlatform = [[existing_platform]]
param vnetAddressSpace = '[[vnet_address_space]]'
param allowedFqdns = [[allowed_fqdns_bicep]]
param computeVmSize = '[[compute_vm_size]]'
param computeMaxNodes = [[compute_max_nodes]]
param keyVaultRetentionDays = [[keyvault_retention_days]]
param budgetAmount = [[budget_amount]]
param alertEmails = [[alert_emails_bicep]]
param existingSubnetId = '[[existing_subnet_id]]'
param existingLawId = '[[existing_law_id]]'
param existingDnsZones = [[existing_dns_bicep]]
param tags = {
[[tags_bicep]]
}
