@description('Name of the API Management service')
param apimServiceName string
param location string = resourceGroup().location
param publisherEmail string = 'alexdantico11@hotmail.com'
param publisherName string = 'AlexDantico'

// Create API Management service
resource apimService 'Microsoft.ApiManagement/service@2024-06-01-preview' = {
  name: apimServiceName
  location: location
  sku: {
    name: 'Developer'
    capacity: 1
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
    publicNetworkAccess: 'Enabled'
  }
}

// Outputs
output id string = apimService.id
output name string = apimService.name
output gatewayUrl string = 'https://${apimServiceName}.azure-api.net'
