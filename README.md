# Passwordless Service Authentication with Azure Functions and APIM


## Overview
This solution demonstrates a secure, passwordless authentication flow between Azure Functions using Managed Identities, with API Management (APIM) handling token validation and access control.

## Architecture
- Frontend Function App (Python)
- Azure API Management
- Backend Function App (Python)
- Azure Key Vault
- Microsoft Entra ID (Azure AD)

## Prerequisites
- Azure subscription with Owner rights
- Create a resource group and set as ENV variable in yaml file.
- Service Principal with:
  - `Application.ReadWrite.All`
  - `Directory.Read.All`
  - `Key Vault Secrets Officer`
  - `Contributor` on resource group

## Getting Started
1. Clone the repository
   ```bash
   git clone https://github.com/yourusername/apim-oauth.git
   cd apim-oauth
   ```

2. Configure GitHub Secrets:
   ```yaml
   AZURE_CLIENT_ID: "<service-principal-client-id>"
   AZURE_TENANT_ID: "<your-tenant-id>"
   AZURE_SUBSCRIPTION_ID: "<your-subscription-id>"
   ```

3. Run the GitHub workflow
   - Navigate to Actions tab
   - Select "Deploy Python project to Azure Function App"
   - Click "Run workflow"

## Deployment Flow
1. Creates/updates backend app registration
2. Deploys infrastructure:
   - Function Apps
   - API Management
   - Key Vault
3. Deploys frontend and backend Function Apps
4. Configures authentication and APIM policies

## Required Permissions

### Frontend Function App
- [x] Managed Identity enabled
- [x] GET access to Key Vault secrets
- [x] Assigned app role from backend API

### Backend Function App
- [x] Entra ID authentication enabled
- [x] App registration with exposed API
- [x] Function app code stored in Key Vault

### APIM
- [x] Managed Identity enabled
- [x] GET access to Key Vault secrets
- [x] API policy configured for token validation

## File Structure
```
├── .github/workflows/
│   └── azure-functions-app-python.yml
├── bicep/
│   ├── infrastructure/
│   │   └── main.bicep
│   └── services/
│       ├── main.bicep
│       └── modules/
│           ├── apim-apis.bicep
│           └── policies/
│               └── apim-backend-policy.xml
└── src/
    └── function-apps/
        ├── frontend/
        └── backend/
```

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License
[MIT](https://choosealicense.com/licenses/mit/)