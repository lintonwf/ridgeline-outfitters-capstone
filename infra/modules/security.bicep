@description('Azure region')
param location string

@description('Resource naming suffix')
param suffix string

@description('Globally unique Key Vault name')
param keyVaultName string

@description('Resource tags')
param tags object

@description('Apply CanNotDelete lock on Key Vault (SEC-7)')
param enableLocks bool = true

// User-Assigned Managed Identity for App Service & Container Apps (SEC-3)
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-${suffix}'
  location: location
  tags: tags
}

// Azure Key Vault with RBAC authorization & purge protection (SEC-2, SEC-3)
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    enablePurgeProtection: true
    publicNetworkAccess: 'Enabled'
  }
}

// Built-in Key Vault Secrets User role (4633458b-17de-408a-b874-0445c86b69e6)
var kvSecretsUserRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')

resource kvSecretsUserAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, managedIdentity.id, kvSecretsUserRoleId)
  scope: keyVault
  properties: {
    roleDefinitionId: kvSecretsUserRoleId
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// SEC-7: Resource lock on Key Vault
resource keyVaultLock 'Microsoft.Authorization/locks@2020-05-01' = if (enableLocks) {
  name: 'lock-kv-cannotdelete'
  scope: keyVault
  properties: {
    level: 'CanNotDelete'
    notes: 'SEC-7: Prevent accidental deletion of production Key Vault'
  }
}

output managedIdentityId string = managedIdentity.id
output managedIdentityClientId string = managedIdentity.properties.clientId
output keyVaultName string = keyVault.name
output keyVaultUri string = keyVault.properties.vaultUri
