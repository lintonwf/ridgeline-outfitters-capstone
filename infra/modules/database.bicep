@description('Azure region')
param location string

@description('Resource naming suffix')
param suffix string

@description('VNet ID for Private DNS linking')
param vnetId string

@description('Data subnet ID for SQL Private Endpoint')
param dataSubnetId string

@description('SQL Admin username')
param sqlAdminLogin string

@secure()
@description('SQL Admin password')
param sqlAdminPassword string

@description('Key Vault name for storing SQL connection string (SEC-3)')
param keyVaultName string

@description('Resource tags')
param tags object

@description('Apply CanNotDelete lock on production SQL Database (SEC-7)')
param enableLocks bool = true

// ARC-3: Azure SQL Server with public network access disabled
resource sqlServer 'Microsoft.Sql/servers@2023-08-01-preview' = {
  name: 'sql-${suffix}'
  location: location
  tags: tags
  properties: {
    administratorLogin: sqlAdminLogin
    administratorLoginPassword: sqlAdminPassword
    version: '12.0'
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Disabled'
  }
}

// ARC-3 & ARC-8: Basic Tier (5 DTUs, 2 GB max size) with TDE enabled by default (SEC-2)
resource sqlDatabase 'Microsoft.Sql/servers/databases@2023-08-01-preview' = {
  parent: sqlServer
  name: 'sqldb-${suffix}'
  location: location
  tags: tags
  sku: {
    name: 'Basic'
    tier: 'Basic'
    capacity: 5
  }
  properties: {
    maxSizeBytes: 2147483648
    requestedBackupStorageRedundancy: 'Geo'
  }
}

// SEC-7: Resource lock on production database
resource sqlDbLock 'Microsoft.Authorization/locks@2020-05-01' = if (enableLocks) {
  name: 'lock-sqldb-cannotdelete'
  scope: sqlDatabase
  properties: {
    level: 'CanNotDelete'
    notes: 'SEC-7: Prevent accidental deletion of production Azure SQL Database'
  }
}

// NET-5: Private DNS Zone for Azure SQL Private Link
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink${environment().suffixes.sqlServerHostname}'
  location: 'global'
  tags: tags
}

resource privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: privateDnsZone
  name: 'link-vnet-${suffix}'
  location: 'global'
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

// ARC-3: Private Endpoint in snet-data
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2024-01-01' = {
  name: 'pe-sql-${suffix}'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: dataSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'plsc-sql-${suffix}'
        properties: {
          privateLinkServiceId: sqlServer.id
          groupIds: [
            'sqlServer'
          ]
        }
      }
    ]
  }
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-01-01' = {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'sql-privatelink-config'
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
}

// SEC-3: Store SQL connection string directly in Key Vault (never in code or plaintext settings)
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource sqlConnSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'SqlConnectionString'
  properties: {
    value: 'Server=tcp:${sqlServer.properties.fullyQualifiedDomainName},1433;Initial Catalog=${sqlDatabase.name};Persist Security Info=False;User ID=${sqlAdminLogin};Password=${sqlAdminPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
  }
}

output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName
output sqlConnectionSecretUri string = sqlConnSecret.properties.secretUri
