using '../main.bicep'

param projectName = '[[project_name]]'
param environment = '[[env]]'
param location = '[[location]]'
param locationShort = '[[location_short]]'
param suffix = '[[suffix]]'
param privateNetworking = [[private_networking]]
param featureStore = [[feature_store]]
param tags = {
[[tags_bicep]]
}
