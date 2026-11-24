@description('Azure region')
param location string

@description('Resource naming suffix')
param suffix string

@description('Delegated subnet ID for App Service VNet integration')
param webSubnetId string

@description('Delegated subnet ID for Container Apps Environment')
param appSubnetId string

@description('User-Assigned Managed Identity resource ID')
param managedIdentityId string

@description('User-Assigned Managed Identity client ID')
param managedIdentityClientId string

@description('Key Vault URI')
param keyVaultUri string

@description('Key Vault Secret URI for SQL connection string')
param sqlConnectionSecretUri string

@description('Storage Account name')
param storageAccountName string

@description('Caddy proxy container image')
param proxyImage string

@description('API container image')
param apiImage string

@description('Deployed application version tag (AUT-7)')
param appVersion string

@description('Resource tags')
param tags object

// ARC-2: App Service Plan Basic B1 (Linux)
resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: 'asp-${suffix}'
  location: location
  tags: tags
  sku: {
    name: 'B1'
    tier: 'Basic'
    capacity: 2
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

// ARC-2 & NET-6: Web Tier App Service (HTTPS-only, TLS 1.2, Managed Identity + Key Vault reference)
resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: 'app-${suffix}'
  location: location
  tags: tags
  kind: 'app,linux'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    virtualNetworkSubnetId: webSubnetId
    keyVaultReferenceIdentity: managedIdentityId
    siteConfig: {
      linuxFxVersion: 'NODE|20-lts'
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      vnetRouteAllEnabled: true
      appSettings: [
        {
          name: 'APP_VERSION'
          value: appVersion
        }
        {
          name: 'KEY_VAULT_URI'
          value: keyVaultUri
        }
        {
          name: 'AZURE_CLIENT_ID'
          value: managedIdentityClientId
        }
        {
          name: 'STORAGE_ACCOUNT_NAME'
          value: storageAccountName
        }
      ]
    }
  }
}

// ARC-5: Azure Container Apps Environment integrated with snet-app
resource containerAppsEnv 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: 'cae-${suffix}'
  location: location
  tags: tags
  properties: {
    vnetConfiguration: {
      infrastructureSubnetId: appSubnetId
      internal: false
    }
    workloadProfiles: [
      {
        name: 'Consumption'
        workloadProfileType: 'Consumption'
      }
    ]
  }
}

// ARC-5: Backend Serverless API Container App (internal ingress only, reads SQL secret via Key Vault)
resource apiContainerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: 'ca-api-${suffix}'
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    managedEnvironmentId: containerAppsEnv.id
    workloadProfileName: 'Consumption'
    configuration: {
      ingress: {
        external: false
        targetPort: 80
        transport: 'auto'
      }
      secrets: [
        {
          name: 'sql-connection-string'
          keyVaultUrl: sqlConnectionSecretUri
          identity: managedIdentityId
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'ridgeline-api'
          image: apiImage
          resources: {
            cpu: json('0.5')
            memory: '1.0Gi'
          }
          env: [
            {
              name: 'APP_VERSION'
              value: appVersion
            }
            {
              name: 'SQL_CONNECTION_STRING'
              secretRef: 'sql-connection-string'
            }
          ]
        }
      ]
      scale: {
        minReplicas: 0
        maxReplicas: 3
      }
    }
  }
}

// NET-7 & NET-6: Caddy Reverse Proxy / Filtering Layer Container App (external HTTPS ingress)
resource proxyContainerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: 'ca-proxy-${suffix}'
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    managedEnvironmentId: containerAppsEnv.id
    workloadProfileName: 'Consumption'
    configuration: {
      ingress: {
        external: true
        targetPort: 80
        allowInsecure: false
        transport: 'auto'
      }
    }
    template: {
      containers: [
        {
          name: 'caddy-proxy'
          image: proxyImage
          resources: {
            cpu: json('0.5')
            memory: '1.0Gi'
          }
          env: [
            {
              name: 'UPSTREAM_WEB_HOST'
              value: webApp.properties.defaultHostName
            }
            {
              name: 'UPSTREAM_API_HOST'
              value: apiContainerApp.properties.configuration.ingress.fqdn
            }
            {
              name: 'APP_VERSION'
              value: appVersion
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 3
      }
    }
  }
}

output webAppDefaultHostName string = webApp.properties.defaultHostName
output proxyFqdn string = proxyContainerApp.properties.configuration.ingress.fqdn
output apiInternalFqdn string = apiContainerApp.properties.configuration.ingress.fqdn
