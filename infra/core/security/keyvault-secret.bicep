param keyVaultName string
param secrets array

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

resource keyVaultSecrets 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = [for secret in secrets: {
  name: secret.name
  parent: keyVault
  properties: {
    value: secret.value
  }
}]
