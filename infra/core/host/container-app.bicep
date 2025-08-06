param name string
param location string = resourceGroup().location
param tags object = {}
param containerAppsEnvironmentId string
param containerImage string
param containerPort int = 80
param cpu string = '0.5'
param memory string = '1Gi'
param managedIdentityId string
param environmentVariables array = []
param secrets array = []

resource containerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: name
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    managedEnvironmentId: containerAppsEnvironmentId
    configuration: {
      ingress: {
        external: true
        targetPort: containerPort
        corsPolicy: {
          allowedOrigins: ['*']
          allowedMethods: ['*']
          allowedHeaders: ['*']
        }
      }
      secrets: [for secret in secrets: {
        name: secret.name
        keyVaultUrl: secret.keyVaultUrl
        identity: secret.identity
      }]
    }
    template: {
      containers: [
        {
          name: name
          image: containerImage
          resources: {
            cpu: json(cpu)
            memory: memory
          }
          env: environmentVariables
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 3
      }
    }
  }
}

output id string = containerApp.id
output name string = containerApp.name
output uri string = 'https://${containerApp.properties.configuration.ingress.fqdn}'
output fqdn string = containerApp.properties.configuration.ingress.fqdn
