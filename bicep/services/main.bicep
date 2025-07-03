@description('Location for all resources')
param location string = 'Australia East'

@description('Environment name used for resource naming')
param environmentName string = 'apim-auth'

@description('Backend function app name')
param backendFunctionName string = 'fa-apim-auth-backend-001'

param apimServiceName string

// Add new parameters
param frontendFunctionObjectId string = ''
param frontendFunctionApplicationId string = ''

param entraAuthClientId string

// Reference existing resources
resource backendFunction 'Microsoft.Web/sites@2024-04-01' existing = {
  name: backendFunctionName
}

resource apimService 'Microsoft.ApiManagement/service@2024-06-01-preview' existing = {
  name: apimServiceName
}


// Add backend auth configuration if IDs are provided
module backendAuth 'modules/backend-auth.bicep' = if (frontendFunctionObjectId != '' && frontendFunctionApplicationId != '') {
  name: 'backendAuthDeployment'
  params: {
    backendFunctionName: backendFunctionName
    frontendFunctionObjectId: frontendFunctionObjectId
    frontendFunctionApplicationId: frontendFunctionApplicationId
    allowedTenantId: subscription().tenantId
    entraAuthClientId: entraAuthClientId
  }
  dependsOn: [
    backendFunction
  ]
}

module apimApis 'modules/apim-apis.bicep' = {
  name: 'apimApisDeployment'
  params: {
    apimServiceName: apimService.name
    backendFunctionName: backendFunction.name
    resourceGroupName: resourceGroup().name
    functionAppKey: listKeys('${backendFunction.id}/host/default', '2024-04-01').functionKeys.default
    entraAuthClientId: entraAuthClientId
    tenantId: subscription().tenantId
    frontendFunctionApplicationId: frontendFunctionApplicationId
  }
  dependsOn: [
    apimService
    backendFunction
  ]
}

// Add outputs if needed
output backendFunctionId string = backendFunction.id
output apimServiceId string = apimService.id
