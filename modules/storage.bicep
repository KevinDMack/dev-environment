param location string = resourceGroup().location
param storage_account_name string
param privateDnsZoneName string = 'privatelink.${environment().suffixes.storage}'
param subnet_id string
param vnet_id string 
param default_tag_name string
param default_tag_value string

resource storage_account 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: storage_account_name
  location: location
  tags: {
    '${default_tag_name}': default_tag_value
  }
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    publicNetworkAccess: 'Disabled'
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'None'
      ipRules: []
      virtualNetworkRules: []
      resourceAccessRules: []
    }
  }
}

resource private_dns_zone 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privateDnsZoneName
  location: 'global'
  tags: {
    '${default_tag_name}': default_tag_value
  }
}

resource private_endpoint 'Microsoft.Network/privateEndpoints@2020-07-01' = {
  name: '${storage_account_name}-pe'
  location: location
  tags: {
    '${default_tag_name}': default_tag_value
  }
  properties: {
    privateLinkServiceConnections: [
      {
        name: '${storage_account_name}-plsc'
        properties: {
          privateLinkServiceId: storage_account.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
    manualPrivateLinkServiceConnections: []
    subnet: {
      id: subnet_id
    }
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

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-07-01' = {
  name: 'default'
  parent: private_endpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'storageConfig1'
        properties: {
          privateDnsZoneId: private_dns_zone.id
        }
      }
    ]
  }
}

output id string = storage_account.id
output private_endpoint_id string = private_endpoint.id
output private_dns_zone_id string = private_dns_zone.id
output name string = storage_account.name 
