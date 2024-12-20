param azure_ml_workspace_name string 
param location string = resourceGroup().location
param subnet_id string
param vnet_id string 

// Dependent Resources:
param key_vault_id string
param container_registry_id string
param storage_account_id string

param private_dns_zone_name string = 'privatelink.api.ml.azure.us'

param default_tag_name string
param default_tag_value string

resource application_insights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${azure_ml_workspace_name}-ai'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}

resource aml_workspace 'Microsoft.MachineLearningServices/workspaces@2021-04-01' = {
  name: azure_ml_workspace_name
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: azure_ml_workspace_name
    keyVault: key_vault_id
    containerRegistry: container_registry_id
    storageAccount: storage_account_id
    applicationInsights: application_insights.id
    publicNetworkAccess: 'Disabled'
    privateEndpointConnections: [
      {
        privateEndpoint: {
          id: resourceId('Microsoft.Network/privateEndpoints', '${azure_ml_workspace_name}-pe')
        }
        groupIds: [
          'amlworkspace'
        ]
      }
    ]
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  name: '${azure_ml_workspace_name}-pe'
  location: location
  properties: {
    subnet: {
      id: subnet_id
    }
    privateLinkServiceConnections: [
      {
        name: '${azure_ml_workspace_name}-plsc'
        properties: {
          privateLinkServiceId: aml_workspace.id
          groupIds: [
            'amlworkspace'
          ]
        }
      }
    ]
  }
}

resource private_dns_zone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: private_dns_zone_name
  location: 'global'
  tags: {
    '${default_tag_name}': default_tag_value
  }
}

resource privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  name: '${private_dns_zone.name}-link'
  parent: private_dns_zone
  location: 'global'
  tags: {
    '${default_tag_name}': default_tag_value
  }
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet_id
    }
  }
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-11-01' = {
  name: 'default'
  parent: privateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: private_dns_zone.id
        }
      }
    ]
  }
}

output azure_ml_workspace_id string = aml_workspace.id
output private_endpoint_id string = privateEndpoint.id
output private_dns_zone_id string = private_dns_zone.id
