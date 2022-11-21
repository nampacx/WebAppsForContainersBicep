@description('Location of the Services, e.g. westeurope')
param location string = resourceGroup().location

@description('stage e.g. dev')
param stage string

@description('Location of the Services, e.g. westeurope')
param applicationName string

@description('image')
param image string

@description('The name for the Mongo DB database')
param databaseName string = 'testdb'

@description('The name for the Mongo DB collection')
param collectionName string = 'cosmosDB'

var servicePrefix = '${applicationName}-${stage}'

var appconfigDataReader = '516239f1-63e1-4d78-a4de-a74fb236a071'

var keyVaultSecretUser = '4633458b-17de-408a-b874-0445c86b69e6'

resource appServicePlan 'Microsoft.Web/serverfarms@2020-12-01' = {
  name: '${servicePrefix}-asp'
  location: location
  kind: 'linux'
  properties: {
    reserved: true
  }
  sku: {
    name: 'B1'
    tier: 'Basic'
  }
}

resource configStore 'Microsoft.AppConfiguration/configurationStores@2021-10-01-preview' = {
  name: '${servicePrefix}-config'
  location: location
  sku: {
    name: 'standard'
  }
}

resource webApp 'Microsoft.Web/sites@2021-01-01' = {
  name: '${servicePrefix}-app'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  tags: {}
  properties: {
    siteConfig: {
      appSettings: []
      linuxFxVersion: 'DOCKER|${image}'
    }
    serverFarmId: appServicePlan.id
  }
}

resource vault 'Microsoft.KeyVault/vaults@2021-11-01-preview' = {
  name: '${replace(servicePrefix, '-', '')}kv'
  location: location
  properties: {
    accessPolicies: [ {
        objectId: webApp.identity.principalId
        tenantId: tenant().tenantId
        permissions: {
          secrets: [ 'get' ]
        }
      }
    ]
    enableRbacAuthorization: false
    enableSoftDelete: false
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
    tenantId: subscription().tenantId
    sku: {
      name: 'standard'
      family: 'A'
    }
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2022-05-15' = {
  name: toLower(replace(servicePrefix, '-', ''))
  location: location
  kind: 'MongoDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    locations: [
      {
        locationName: location
      }
    ]
  }
}

resource cosmosDbConnectionStringAppConfig 'Microsoft.AppConfiguration/configurationStores/keyValues@2021-10-01-preview' = {
  parent: configStore
  name: '${toUpper(cosmosDbAccount.name)}_CONNECTION_STRING'
  properties: {
    value: listConnectionStrings(resourceId('Microsoft.DocumentDB/databaseAccounts', cosmosDbAccount.name), '2020-04-01').connectionStrings[0].connectionString
  }
}

resource database 'Microsoft.DocumentDB/databaseAccounts/mongodbDatabases@2022-05-15' = {
  parent: cosmosDbAccount
  name: databaseName
  properties: {
    resource: {
      id: databaseName
    }
    options: {
      throughput: 1000
    }
  }
}

resource collection 'Microsoft.DocumentDb/databaseAccounts/mongodbDatabases/collections@2022-05-15' = {
  parent: database
  name: collectionName
  properties: {
    resource: {
      id: collectionName
      shardKey: {
        user_id: 'Hash'
      }
      indexes: [
        {
          key: {
            keys: [
              '_id'
            ]
          }
        }
      ]
    }
  }
}

resource cosmosDbConnectionStringAppConfigSecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: '${toUpper(cosmosDbAccount.name)}-CONNECTION-STRING'
  parent: vault
  properties: {
    value: listConnectionStrings(resourceId('Microsoft.DocumentDB/databaseAccounts', cosmosDbAccount.name), '2020-04-01').connectionStrings[0].connectionString
  }
}

resource symbolicname 'Microsoft.Web/sites/config@2022-03-01' = {
  name: 'connectionstrings'
  kind: 'string'
  parent: webApp
  properties: {
    CosmosDBConnectionString: {
      value: '@Microsoft.KeyVault(SecretUri=${cosmosDbConnectionStringAppConfigSecret.properties.secretUri})'
      type: 'DocDb'
    }
  }
}
