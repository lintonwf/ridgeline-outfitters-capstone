targetScope = 'resourceGroup'

@description('Primary Azure region for deployment (ARC-6)')
param location string = resourceGroup().location

@description('Workload identifier used in resource names (ARC-9)')
param appName string = 'ridgeline'

@description('Environment short name (e.g., prod, stage)')
@allowed([
  'prod'
  'stage'
])
param environment string = 'prod'

@description('Region short code used in resource names (ARC-9)')
param regionCode string = 'wus3'

@description('Student name for Owner tag (ARC-9)')
param ownerName string

@description('Cost center code (ARC-9)')
param costCenter string = 'RO-IT-001'

@description('Project identifier tag (ARC-9)')
param projectName string = 'CPTR445-Capstone'

@description('SQL Administrator login username')
param sqlAdminLogin string

@secure()
@description('SQL Administrator password (supplied at deploy time or from Key Vault; never hardcoded)')
param sqlAdminPassword string

@description('Container image for Caddy reverse proxy (NET-7)')
param proxyImage string = 'caddy:2.8-alpine'

@description('Container image for backend API (ARC-5)')
param apiImage string = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'

@description('Deployed application release version tag (AUT-7)')
param appVersion string = 'v0.1.0'

var commonTags = {
  Owner: ownerName
  Environment: environment == 'prod' ? 'Production' : 'Staging'
  CostCenter: costCenter
  Project: projectName
}

var suffix = '${appName}-${environment}-${regionCode}'
// Storage and Key Vault names must be globally unique and alphanumeric (3-24 chars)
var uniqueToken = substring(uniqueString(resourceGroup().id), 0, 6)
var storageAccountName = take('st${appName}${environment}${uniqueToken}', 24)
var keyVaultName = take('kv-${appName}-${environment}-${uniqueToken}', 24)

// 1. Networking & Segmentation (NET-1, NET-2, NET-4)
module network 'modules/network.bicep' = {
  name: 'deploy-network'
  params: {
    location: location
    suffix: suffix
    tags: commonTags
  }
}

// 2. Identity, Key Vault & Resource Lock (SEC-2, SEC-3, SEC-7)
module security 'modules/security.bicep' = {
  name: 'deploy-security'
  params: {
    location: location
    suffix: suffix
    keyVaultName: keyVaultName
    tags: commonTags
    enableLocks: environment == 'prod'
  }
}

// 3. Storage Account - Hot Tier, LRS (ARC-4, SEC-2)
module storage 'modules/storage.bicep' = {
  name: 'deploy-storage'
  params: {
    location: location
    storageAccountName: storageAccountName
    tags: commonTags
  }
}

// 4. Azure SQL Database with Private Endpoint & Private DNS (ARC-3, NET-5, SEC-2, SEC-7)
module database 'modules/database.bicep' = {
  name: 'deploy-database'
  params: {
    location: location
    suffix: suffix
    vnetId: network.outputs.vnetId
    dataSubnetId: network.outputs.dataSubnetId
    sqlAdminLogin: sqlAdminLogin
    sqlAdminPassword: sqlAdminPassword
    keyVaultName: security.outputs.keyVaultName
    tags: commonTags
    enableLocks: environment == 'prod'
  }
}

// 5. Compute: App Service (2x B1) & Container Apps Proxy/API (ARC-2, ARC-5, NET-6, NET-7)
module compute 'modules/compute.bicep' = {
  name: 'deploy-compute'
  params: {
    location: location
    suffix: suffix
    webSubnetId: network.outputs.webSubnetId
    appSubnetId: network.outputs.appSubnetId
    managedIdentityId: security.outputs.managedIdentityId
    managedIdentityClientId: security.outputs.managedIdentityClientId
    keyVaultUri: security.outputs.keyVaultUri
    sqlConnectionSecretUri: database.outputs.sqlConnectionSecretUri
    storageAccountName: storage.outputs.storageAccountName
    proxyImage: proxyImage
    apiImage: apiImage
    appVersion: appVersion
    tags: commonTags
  }
}

output vnetId string = network.outputs.vnetId
output webAppDefaultHostName string = compute.outputs.webAppDefaultHostName
output proxyFqdn string = compute.outputs.proxyFqdn
output apiInternalFqdn string = compute.outputs.apiInternalFqdn
output sqlServerFqdn string = database.outputs.sqlServerFqdn
output keyVaultName string = security.outputs.keyVaultName
output storageAccountName string = storage.outputs.storageAccountName
