# Federated Credentials Setup for GitHub Actions

## Request for Tenant Owner

Please run the following command to add federated credentials to the existing service principal:

```bash
az ad app federated-credential create --id YOUR_SERVICE_PRINCIPAL_CLIENT_ID --parameters '{
  "name": "github-actions-eshop-dev",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:CleveritDemo/AzureSREAgent:environment:dev",
  "audiences": ["api://AzureADTokenExchange"]
}'
```

## What this does:
- Allows the service principal to authenticate via OIDC
- No client secret needed in GitHub secrets
- More secure authentication method
- Links the service principal to your specific GitHub repository and environment

## Verification:
After running this command, you should see output similar to:
```json
{
  "audiences": ["api://AzureADTokenExchange"],
  "description": null,
  "id": "...",
  "issuer": "https://token.actions.githubusercontent.com",
  "name": "github-actions-eshop-dev",
  "subject": "repo:CleveritDemo/AzureSREAgent:environment:dev"
}
```
