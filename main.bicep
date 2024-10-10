

@description('Environment Prefix')
param envPrefix string = 'spacesdk'

@description('Infra Location')
param infraLoc string = 'westus2'

@description('Infra VNet Name')
param infraVNetNameParam string = 'vnet-teaminfra'
var infraVNetName = '${envPrefix}-${infraVNetNameParam}'

@description('Infra VPN Gateway Name')
param vpnNameParam string = 'vpn-teaminfra'
var vpnName = '${envPrefix}-${vpnNameParam}'


@description('The IP address range from which VPN clients will receive an IP address when connected. Range specified must not overlap with on-premise network')
param vpnClientAddressPool string = '10.1.0.0/24'

/* Improvement - move this to an array of test environments  */

@description('Test1 Location')
param test1Loc string = 'westus2'

@description('Test1 VNet Name')
param test1VNetNameParam string = 'vnet-test1'
var test1VNetName = '${envPrefix}-${test1VNetNameParam}'


/* Improvement - move this to an array of dev environments  */
@description('Dev1 Location')
param dev1Loc string = 'westus2'

@description('Dev1 VNet Name')
param dev1VNetNameParam string = 'vnet-dev1'
var dev1VNetName = '${envPrefix}-${dev1VNetNameParam}'

@description('Dev2 Location')
param dev2Loc string = 'eastus'

@description('Dev2 VNet Name')
param dev2VNetNameParam string = 'vnet-dev2'
var dev2VNetName = '${envPrefix}-${dev2VNetNameParam}'



var audienceMap = {
  AzureCloud: '41b23e61-6c1e-4545-b367-cd054e0ed4b4'
  AzureUSGovernment: '51bb15d4-3a4f-4ebf-9dca-40096fe32426'
  AzureGermanCloud: '538ee9e6-310a-468d-afef-ea97365856a9'
  AzureChinaCloud: '49f817b6-84ae-4cc0-928c-73f27289b3aa'
}

var tenantId = subscription().tenantId
var cloud             = environment().name
var audience          = audienceMap[cloud]
var tenant = uri(environment().authentication.loginEndpoint, tenantId)
var issuer = 'https://sts.windows.net/${tenantId}/'

var vpnPubIPName      = '${vpnName}PIP'
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

resource dev1VNet 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: dev1VNetName
  location: dev1Loc
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.2.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'Main'
        properties: {
          addressPrefix: '10.2.0.0/24'
        }
      }
    ]
  }
}


resource dev2VNet 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: dev2VNetName
  location: dev2Loc
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.3.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'Main'
        properties: {
          addressPrefix: '10.3.0.0/24'
        }
      }
    ]
  }
}



resource test1VNet 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: test1VNetName
  location: test1Loc
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.4.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'Main'
        properties: {
          addressPrefix: '10.4.0.0/24'
        }
      }
    ]
  }
}



resource VNetPeeringHubToDev1 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-05-01' = {
  parent: infraVNet
  name: '${infraVNetName}-${dev1VNetName}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: true
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: dev1VNet.id
    }
  }
}

resource VNetPeeringDev1ToHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-05-01' = {
  parent: dev1VNet
  name: '${dev1VNetName}-${infraVNetName}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: true
    remoteVirtualNetwork: {
      id: infraVNet.id
    }
  }
  dependsOn: [
    virtualNetworkGateway
  ]
}


resource VNetPeeringHubToDev2 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-05-01' = {
  parent: infraVNet
  name: '${infraVNetName}-${dev2VNetName}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: true
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: dev2VNet.id
    }
  }
}


resource VNetPeeringDev2ToHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-05-01' = {
  parent: dev2VNet
  name: '${dev2VNetName}-${infraVNetName}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: true
    remoteVirtualNetwork: {
      id: infraVNet.id
    }
  }
  dependsOn: [
    virtualNetworkGateway
  ]
}


resource VNetPeeringHubToTest1 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-05-01' = {
  parent: infraVNet
  name: '${infraVNetName}-${test1VNetName}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: true
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: test1VNet.id
    }
  }
}


resource VNetPeeringTest1ToHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-05-01' = {
  parent: test1VNet
  name: '${test1VNetName}-${infraVNetName}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: true
    remoteVirtualNetwork: {
      id: infraVNet.id
    }
  }
  dependsOn: [
    virtualNetworkGateway
  ]
}
