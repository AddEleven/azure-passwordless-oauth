@description('Name of the APIM instance')
param apimServiceName string

@description('Name of the backend function app')
param backendFunctionName string

@description('Resource group name')
param resourceGroupName string

@description('Subscription ID')
param subscriptionId string = subscription().subscriptionId

@secure()
@description('Function app key')
param functionAppKey string

param tenantId string
param entraAuthClientId string

@description('Frontend function app application ID (client ID)')
param frontendFunctionApplicationId string

var backendUrl = 'https://${backendFunctionName}.azurewebsites.net/api'
var backendResourceId = 'https://management.azure.com/subscriptions/${subscriptionId}/resourceGroups/${resourceGroupName}/providers/Microsoft.Web/sites/${backendFunctionName}'

// Reference existing APIM instance
resource apimService 'Microsoft.ApiManagement/service@2024-06-01-preview' existing = {
  name: apimServiceName
}

// Create named value for function key
resource functionKeyNamedValue 'Microsoft.ApiManagement/service/namedValues@2024-06-01-preview' = {
  parent: apimService
  name: '${backendFunctionName}-key'
  properties: {
    displayName: '${backendFunctionName}-key'
    secret: true
    value: functionAppKey
    tags: [
      'key'
      'function'
      'auto'
    ]
  }
}

// Create backend
resource functionBackend 'Microsoft.ApiManagement/service/backends@2024-06-01-preview' = {
  parent: apimService
  name: backendFunctionName
  properties: {
    description: 'Backend Function App'
    url: backendUrl
    protocol: 'http'
    resourceId: backendResourceId
    credentials: {
      header: {
        'x-functions-key': [
          '{{${backendFunctionName}-key}}'
        ]
      }
    }
  }
  dependsOn: [
    functionKeyNamedValue
  ]
}

// Create API
resource backendApi 'Microsoft.ApiManagement/service/apis@2024-06-01-preview' = {
  parent: apimService
  name: backendFunctionName
  properties: {
    displayName: backendFunctionName
    apiRevision: '1'
    path: backendFunctionName
    protocols: [
      'https'
    ]
    subscriptionRequired: true
    authenticationSettings: {
      oAuth2AuthenticationSettings: []
      openidAuthenticationSettings: []
    }
    subscriptionKeyParameterNames: {
      header: 'Ocp-Apim-Subscription-Key'
      query: 'subscription-key'
    }
    isCurrent: true
  }
}



// Create API operation
resource backendApiOperation 'Microsoft.ApiManagement/service/apis/operations@2024-06-01-preview' = {
  parent: backendApi
  name: 'fa-adtest-backend-trigger'
  properties: {
    displayName: 'fa_adtest_backend_trigger'
    method: 'POST'
    urlTemplate: '/fa_adtest_backend_trigger'
    templateParameters: []
    responses: []
  }
}

func replaceMultiple(input string, replacements { *: string }) string => reduce(
  items(replacements), input, (cur, next) => replace(string(cur), next.key, next.value)
  )


// Create API operation policy
var policyContent = loadTextContent('./policies/apim-backend-policy.xml')

var filledPolicy = replaceMultiple(policyContent, {
  '{entraAuthClientId}': entraAuthClientId
  '{backendFunctionName}': backendFunctionName
  '{tenantId}': tenantId
  '{frontendFunctionApplicationId}': frontendFunctionApplicationId
  })

resource backendApiOperationPolicy 'Microsoft.ApiManagement/service/apis/operations/policies@2024-06-01-preview' = {
  parent: backendApiOperation
  name: 'policy'
  properties: {
    format: 'xml'
    value: filledPolicy
  }
  dependsOn: [
    functionBackend
  ]
}

// Outputs
output apiId string = backendApi.id
output apiPath string = backendApi.properties.path
