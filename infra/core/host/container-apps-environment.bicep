param name string
param location string = resourceGroup().location
param tags object = {}
param logAnalyticsWorkspaceId string
param logAnalyticsWorkspaceKey string

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: reference(logAnalyticsWorkspaceId, '2022-10-01').customerId
        sharedKey: logAnalyticsWorkspaceKey
      }
    }
  }
}

output id string = containerAppsEnvironment.id
output name string = containerAppsEnvironment.name
