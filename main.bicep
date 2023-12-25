param cosmosDBAccountName string = 'toyrnd-${uniqueString(resourceGroup().id)}'
param location string = resourceGroup().location
param cosmosDBDababaseThroughput int = 400
var coamsoDBDatabaseName  = 'FlightTests'
var cosmosDBContainerName = 'FlightTests'
var cosmosDBPartitionKey = '/droneId'
var logAnalyticsWorkspaceName = 'ToyLogs'
var cosmosDBAccountDiagnosticSettingsName = 'route-logs-to-log-analytics'
param storageAccountName string
var storageAccountBlobDiagnosticSettingsName = 'route-logs-to-log-analytics'

resource cosmosDBAccount 'Microsoft.DocumentDB/databaseAccounts@2020-04-01' = {
  name: cosmosDBAccountName
  location: location
  properties: {
    databaseAccountOfferType: 'Standard'
    locations: [
      {
        locationName:location
      }
    ]
  }
}

resource cosmosDBDatabase 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2020-04-01' = {
  parent: cosmosDBAccount
  name: coamsoDBDatabaseName
  properties: {
    resource: {
      id: coamsoDBDatabaseName
    }
    options: {
      throughput: cosmosDBDababaseThroughput
    }
  }

  resource container 'containers' = {
    name: cosmosDBContainerName
    properties: {
      resource: {
        id: cosmosDBContainerName
        partitionKey: {
          paths: [
            cosmosDBPartitionKey
          ]
          kind: 'Hash'
        }
      }
      options: {}
    }

  }
}

resource lockResource 'Microsoft.Authorization/locks@2016-09-01' = {
  scope: cosmosDBAccount
  name: 'DontDelete'
  properties: {
    level: 'CanNotDelete'
    notes: 'This lock is to prevent accidental deletion of the CosmosDB account'
  }
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-03-01-preview' existing = {
  name: logAnalyticsWorkspaceName
}

resource cosmosDBAccountDiagnostic 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  name: cosmosDBAccountDiagnosticSettingsName
  scope: cosmosDBAccount
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'DataPlaneRequests'
        enabled: true
      }
    ]
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2019-06-01' existing = {
  name: storageAccountName
  resource blobService 'blobServices' existing = {
    name: 'default'
  }
}

resource storageAcountBlobDiagnostic 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  name: storageAccountBlobDiagnosticSettingsName
  scope: storageAccount::blobService
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'StorageRead'
        enabled: true
      }
      {
        category: 'StorageWrite'
        enabled: true
      }
      {
        category: 'StorageDelete'
        enabled: true
      }
    ]
  }
}

