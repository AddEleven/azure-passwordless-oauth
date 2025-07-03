@description('Name of the backend function app')
param backendFunctionName string

@description('Frontend function app object ID (principal ID)')
param frontendFunctionObjectId string

@description('Frontend function app application ID (client ID)')
param frontendFunctionApplicationId string

@description('Tenant ID for allowed identities')
param allowedTenantId string

@description('Client ID for the backend app registration')
param entraAuthClientId string

// Reference existing backend function app
resource functionApp 'Microsoft.Web/sites@2024-04-01' existing = {
  name: backendFunctionName
}

// Configure auth settings
resource authSettings 'Microsoft.Web/sites/config@2024-04-01' = {
  parent: functionApp
  name: 'authsettingsV2'
  properties: {
    platform: {
      enabled: true
    }
    globalValidation: {
      requireAuthentication: true
      unauthenticatedClientAction: 'Return401'
      redirectToProvider: 'azureactivedirectory'
    }
    identityProviders: {
      azureActiveDirectory: {
        enabled: true
        registration: {
          openIdIssuer: 'https://sts.windows.net/${allowedTenantId}/v2.0'
          clientId: entraAuthClientId
          clientSecretSettingName: 'MICROSOFT_PROVIDER_AUTHENTICATION_SECRET'
        }
        validation: {
          allowedAudiences: [
            'api://${entraAuthClientId}'
          ]
          defaultAuthorizationPolicy: {
            allowedApplications: [
              frontendFunctionApplicationId  // Only allow frontend app
            ]
            allowedPrincipals: {
              identities: [
                frontendFunctionObjectId  // Only allow frontend's managed identity
              ]
            }
          }
        }
      }
    }
    httpSettings: {
      requireHttps: true
    }
  }
}
