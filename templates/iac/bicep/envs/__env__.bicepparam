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
param genai = [[genai]]
param existingPlatform = [[existing_platform]]
param vnetAddressSpace = '[[vnet_address_space]]'
param allowedFqdns = [[allowed_fqdns_bicep]]
param budgetAmount = [[budget_amount]]
param alertEmails = [[alert_emails_bicep]]
param existingSubnetId = '[[existing_subnet_id]]'
param existingLawId = '[[existing_law_id]]'
param existingDnsZones = [[existing_dns_bicep]]
param tags = {
[[tags_bicep]]
}
