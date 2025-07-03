param functionAppName string
param location string
param appServicePlanId string
@secure()
param appInsightsKey string
@secure()
param appInsightsConnString string

param keyVaultName string

param apimServiceName string

param backendClientId string

param tenantId string

param backendFunctionAppName string


// Create storage account for the function app
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: 'stg${take(replace(toLower('${functionAppName}${uniqueString(resourceGroup().id)}'), '-', ''), 21)}'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    defaultToOAuthAuthentication: true
  }
}

resource functionApp 'Microsoft.Web/sites@2024-04-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlanId
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'Python|3.11'
      alwaysOn: false
      functionAppScaleLimit: 200
      cors: {
        allowedOrigins: [
          'https://portal.azure.com'
          'https://ms.portal.azure.com'
        ]
        supportCredentials: true
      }
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value}'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsightsKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnString
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'python'
        }
        {
          name: 'APIM_SUBSCRIPTION_KEY'
          value: '@Microsoft.KeyVault(SecretUri=https://${keyVaultName}.vault.azure.net/secrets/apim-sub-key)'
        }
        {
          name: 'APIM_NAME'
          value: apimServiceName
        }
        {
          name: 'BACKEND_CLIENT_ID'
          value: backendClientId
        }
        {
          name: 'TENANT_ID'
          value: tenantId
        }
        {
          name: 'BACKEND_NAME'
          value: backendFunctionAppName
        }
      ]
    }
  }
}

output functionAppName string = functionApp.name
output functionAppIdentityPrincipalId string = functionApp.identity.principalId
