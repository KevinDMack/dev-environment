

@description('Environment Prefix')
param envPrefix string = 'dev'

@description('Infra Location')
param infraLoc string = 'usgovarizona'

@description('Infra VNet Name')
param infraVNetNameParam string = 'vnet-ev-infra'
var infraVNetName = '${envPrefix}-${infraVNetNameParam}'

@description('Infra VPN Gateway Name')
param vpnNameParam string = 'vpn-dev-infra'
var vpnName = '${envPrefix}-${vpnNameParam}'


@description('The IP address range from which VPN clients will receive an IP address when connected. Range specified must not overlap with on-premise network')
param vpnClientAddressPool string = '10.1.0.0/24'

var audienceMap = {
  AzureCloud: '41b23e61-6c1e-4545-b367-cd054e0ed4b4'
  AzureUSGovernment: '51bb15d4-3a4f-4ebf-9dca-40096fe32426'
}

var tenantId = subscription().tenantId
var cloud             = environment().name
var audience          = audienceMap[cloud]
var tenant = uri(environment().authentication.loginEndpoint, tenantId)
var issuer = 'https://sts.windows.net/${tenantId}/'

var vpnPubIPName      = '${vpnName}-pip'
var gatewaySubnetRef  = resourceId('Microsoft.Network/virtualNetworks/subnets', infraVNetName, 'GatewaySubnet')


resource infraVNet 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: infraVNetName
  location: infraLoc
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'Subnet-FrontEnd'
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: '10.0.2.0/24'
        }
      }
    ]
  }
}

resource vpnPIP 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: vpnPubIPName
  location: infraLoc
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
}

resource virtualNetworkGateway 'Microsoft.Network/virtualNetworkGateways@2020-11-01' = {
  name: vpnName
  location: infraLoc
  properties: {
    ipConfigurations: [
      {
        name: '${vpnName}-ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: gatewaySubnetRef
          }
          publicIPAddress: {
            id: vpnPIP.id
          }
        }
      }
    ]
    sku: {
      name: 'VpnGw2'
      tier: 'VpnGw2'
    }
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    vpnClientConfiguration: {
      vpnClientAddressPool: {
        addressPrefixes: [
          vpnClientAddressPool
        ]
      }
      vpnClientProtocols: [
        'OpenVPN'
      ]
      vpnAuthenticationTypes: [
        'AAD'
      ]
      aadTenant: tenant
      aadAudience: audience
      aadIssuer: issuer
    }
   
  }
}

