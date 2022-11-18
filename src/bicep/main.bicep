
@description('Location of the Services, e.g. westeurope')
param location string = resourceGroup().location

@description('stage e.g. dev')
param stage string

@description('Location of the Services, e.g. westeurope')
param applicationName string

@description('image')
param image string

var servicePrefix = '${applicationName}-${stage}'

resource appServicePlan 'Microsoft.Web/serverfarms@2020-12-01' = {
  name: '${servicePrefix}-asp'
  location: location
  kind: 'linux'
  properties: {
    reserved: true
  }	
  sku:  {
  	name: 'B1'
    tier: 'Basic'
  }
}

resource webApp 'Microsoft.Web/sites@2021-01-01' = {
  name: '${servicePrefix}-app'
  location: location
  tags: {}
  properties: {
    siteConfig: {
      appSettings: []
      linuxFxVersion: 'DOCKER|${image}'
    }
    serverFarmId: appServicePlan.id
  }
}
