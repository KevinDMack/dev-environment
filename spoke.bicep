@description('Environment Prefix')
param envPrefix string = 'dev'

@description('Infra VNet Name')
param infraVNetNameParam string = 'vnet-ev-infra'

@description('Dev1 Location')
param dev1Loc string = 'usgovarizona'

@description('Dev1 VNet Name')
param dev1VNetNameParam string = 'vnet-dev1'
var dev1VNetName = '${envPrefix}-${dev1VNetNameParam}'


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

resource VNetPeeringHubToDev1 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-05-01' = {
  parent: infraVNet
  name: '${infraVNetNameParam}-${dev1VNetName}'
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
