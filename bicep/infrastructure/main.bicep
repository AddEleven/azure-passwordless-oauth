@description('Location for all resources')
param location string = 'Australia East'

@description('Environment name used for resource naming')
param environmentName string = 'apim-auth'

@description('Application Insights name')
param appInsightsName string = 'appi-${environmentName}-001'

param backendClientId string

param publisherEmail string

param publisherName string

// Deploy Application Insights
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    RetentionInDays: 90
  }
}

// Deploy Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: 'kv-${environmentName}-001'
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
  }
}

// Deploy Consumption App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: 'asp-${environmentName}-001'
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  kind: 'functionapp'
  properties: {
    reserved: true
  }
}

// Deploy Frontend Function App
module frontendFunction 'modules/functionApp-frontend.bicep' = {
  name: 'frontendFunctionDeployment'
  params: {
    functionAppName: 'fa-${environmentName}-frontend-001'
    location: location
    appServicePlanId: appServicePlan.id
    appInsightsKey: appInsights.properties.InstrumentationKey
    appInsightsConnString: appInsights.properties.ConnectionString
    keyVaultName: keyVault.name
    apimServiceName: 'apim-${environmentName}-001'
    backendClientId: backendClientId
    tenantId: subscription().tenantId
    backendFunctionName: 'fa-${environmentName}-backend-001'
  }
}

// Deploy Backend Function App
module backendFunction 'modules/functionApp-backend.bicep' = {
  name: 'backendFunctionDeployment'
  params: {
    functionAppName: 'fa-${environmentName}-backend-001'
    location: location
    appServicePlanId: appServicePlan.id
    appInsightsKey: appInsights.properties.InstrumentationKey
    appInsightsConnString: appInsights.properties.ConnectionString
    keyVaultName: keyVault.name
  }
}

// Assign Key Vault Secrets User role to Function Apps
resource frontendFunctionKeyVaultRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('${keyVault.name}-frontend-kv-role')
  scope: keyVault
  properties: {
    principalId: frontendFunction.outputs.functionAppIdentityPrincipalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6') // Key Vault Secrets User
    principalType: 'ServicePrincipal'
  }
}

resource backendFunctionKeyVaultRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('${keyVault.name}-backend-kv-role')
  scope: keyVault
  properties: {
    principalId: backendFunction.outputs.functionAppIdentityPrincipalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6') // Key Vault Secrets User
    principalType: 'ServicePrincipal'
  }
}

module apimModule 'modules/apim.bicep' = {
  name: 'apimDeploy'
  params: {
    apimServiceName: 'apim-${environmentName}-001'
    location: location
    publisherEmail: publisherEmail
    publisherName: publisherName
  }
}

// Add APIM subscription key to Key Vault
module kvSecrets 'modules/kv-secrets.bicep' = {
  name: 'kvSecretsDeploy'
  params: {
    apimServiceName: apimModule.outputs.name
    keyVaultName: keyVault.name
  }
  dependsOn: [
    apimModule
    keyVault
  ]
}
