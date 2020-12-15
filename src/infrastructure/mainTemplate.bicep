param tenant string = ''
param service_principal string = ''
param environment string = 'dev'
param location string = 'westeurope'
param blob_sku string = 'Standard_LRS'
param asp_sku string = 'B1'
param retention_days int = 30

var runtime_stack = 'DOTNETCORE|3.0'

// keyvault
resource akv 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: 'clock-dev-akv'
  location: location
  properties: {
    tenantId: tenant
    sku: {
      name: 'standard'
      family: 'A'
    }
    accessPolicies: [
      {
        tenantId: tenant
        objectId: service_principal
        permissions: {
          secrets: [
            'get'
            'list'
            'set'
          ]
        }
      }
    ]
  }
  tags: {
    environment: environment
  }
}

// storage account
resource blob_stac 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: 'clock0dev0stac'
  location: location
  kind: 'BlobStorage'
  sku: {
    name: blob_sku
  }
  properties: {
    accessTier: 'Cool'
  }
  tags: {
    environment: environment 
  }
}

// App service plan
resource app_service_plan 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: 'clock-dev-asp'
  location: location
  kind: 'linux'
  sku: {
    name: asp_sku
  }
  properties: {
    reserved: true
  }
  tags: {
    environment: environment
  }
}

// function app
resource function_app 'Microsoft.Web/sites@2020-06-01' = {
  name: 'clock-dev-funcapp'
  location: location
  tags: {
    environment: environment
  }
  kind: 'functionapp'
  dependsOn: [
    app_service_plan
    blob_stac
  ]
  properties: {
    serverFarmId: app_service_plan.id
    siteConfig: {
      linuxFxVersion: runtime_stack
    }
  }
}

// application insights
resource app_insights 'microsoft.insights/components@2020-02-02-preview' = {
  name: 'clock-dev-appinsights'
  location: location
  kind: 'web'
  tags: {
    environment: environment
  }
  properties: {
    Flow_Type: 'Bluefield'
    Application_Type: 'web'
    WorkspaceResourceId: log_analytics.id
  }
}

//log analytics workspace 
resource log_analytics 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  name: 'clock-dev-analytics'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: retention_days
  }
  tags: {
    environment: environment
  }
}