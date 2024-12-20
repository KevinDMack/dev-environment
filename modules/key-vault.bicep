param location string
param key_vault_name string
param private_dns_zone_name string = 'privatelink.vaultcore.azure.net'
param key_vault_sku string = 'standard'
param key_vault_sku_family string = 'A'
param subnet_id string
param vnet_id string 

param default_tag_name string
param default_tag_value string

var randomSuffix = uniqueString(resourceGroup().id, key_vault_name)
var maxLength = 24
var truncatedKeyVaultName = substring('${key_vault_name}-${randomSuffix}', 0, maxLength)
//var randomSuffix = uniqueString(subscription().subscriptionId, location)

resource key_vault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: truncatedKeyVaultName
  location: location
  tags: {
    '${default_tag_name}': default_tag_value
  }
  properties: {
    sku: {
      name: key_vault_sku
      family: key_vault_sku_family
    }
    tenantId: subscription().tenantId
    accessPolicies: []
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'None'
      ipRules: []
      virtualNetworkRules: []
    }
  }
}

resource private_dns_zone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: private_dns_zone_name
  location: 'global'
  tags: {
    '${default_tag_name}': default_tag_value
  }
}

resource private_endpoint 'Microsoft.Network/privateEndpoints@2022-05-01' = {
  name: '${key_vault.name}-pe'
  location: location
  tags: {
    '${default_tag_name}': default_tag_value
  }
  properties: {
    privateLinkServiceConnections: [
      {
        name: '${key_vault.name}-plsc'
        properties: {
          privateLinkServiceId: key_vault.id
          groupIds: [
            'vault'
          ]
        }
      }
    ]
    subnet: {
      id: subnet_id
    }
  }
}

resource privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  name: '${private_dns_zone.name}-link'
  tags: {
    '${default_tag_name}': default_tag_value
  }
  parent: private_dns_zone
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet_id
    }
  }
}

resource private_dns_zone_group 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-09-01' = {
  name: 'default'
  parent: private_endpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'keyVaultConfig1'
        properties: {
          privateDnsZoneId: private_dns_zone.id
        }
      }
    ]
  }
}

output id string = key_vault.id
output private_endpoint_id string = private_endpoint.id
output private_dns_zone_id string = private_dns_zone.id
output name string = key_vault.name 
