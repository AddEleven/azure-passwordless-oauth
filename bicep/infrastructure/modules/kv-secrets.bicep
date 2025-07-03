@description('Name of the existing APIM instance')
param apimServiceName string

@description('Name of the Key Vault')
param keyVaultName string




// Reference existing APIM instance
resource apimService 'Microsoft.ApiManagement/service@2024-06-01-preview' existing = {
  name: apimServiceName
}

// Reference existing Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource apiManagementSubscription 'Microsoft.ApiManagement/service/subscriptions@2021-08-01' existing = {
  name: 'master'
  parent: apimService
}

// Add APIM subscription key to Key Vault
resource apimSubKeySecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'apim-sub-key'
  properties: {
    value: apiManagementSubscription.listSecrets(apiManagementSubscription.apiVersion).primaryKey
  }
}
