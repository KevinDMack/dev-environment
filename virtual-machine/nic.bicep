param satellite_name string = ''
param location string = ''
param subnet_id string = ''
param ssh_subnet_id string = ''
param nsg_id string = ''
param enable_public_ip bool = false 

param primary_static_private_ip string = ''
param ssh_static_private_ip string = ''

param default_tag_name string
param default_tag_value string

resource network_card 'Microsoft.Network/networkInterfaces@2020-11-01' = {
  name: '${satellite_name}-nic'
  location: location
  tags: {
    '${default_tag_name}': default_tag_value
  }
  properties: {
    ipConfigurations: [
      {
        name: '${satellite_name}-nic'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: primary_static_private_ip
          subnet: {
            id: subnet_id
          }
          publicIPAddress: enable_public_ip ? {
            id: public_ip.id
          } : null
        }
      }
    ]
    networkSecurityGroup: {
      id: nsg_id
    }
  }
}

resource ssh_network_card 'Microsoft.Network/networkInterfaces@2020-11-01' = if (subnet_id != ssh_subnet_id) {
  name: '${satellite_name}-ssh-nic'
  location: location
  tags: {
    '${default_tag_name}': default_tag_value
  }
  properties: {
    ipConfigurations: [
      {
        name: '${satellite_name}-ssh-nic'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: ssh_static_private_ip
          subnet: {
            id: ssh_subnet_id
          }
          publicIPAddress: enable_public_ip ? {
            id: public_ssh_ip.id
          } : null
        }
      }
    ]
    networkSecurityGroup: {
      id: nsg_id
    }
  }
}

resource public_ip 'Microsoft.Network/publicIPAddresses@2020-11-01' = if (enable_public_ip) {
  name: '${satellite_name}-pip'
  location: location
  tags: {
    '${default_tag_name}': default_tag_value
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource public_ssh_ip 'Microsoft.Network/publicIPAddresses@2020-11-01' = if (enable_public_ip) {
  name: '${satellite_name}-ssh-pip'
  tags: {
    '${default_tag_name}': default_tag_value
  }
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

output nic_ids array = [ network_card.id ]

output private_ips array = [ network_card.properties.ipConfigurations[0].properties.privateIPAddress ]

output public_ips array = [ enable_public_ip ? network_card.properties.ipConfigurations[0].properties.publicIPAddress : '' ]

output private_ip_primary string = network_card.properties.ipConfigurations[0].properties.privateIPAddress

output private_ip_ssh string = (subnet_id != ssh_subnet_id) ? ssh_network_card.properties.ipConfigurations[0].properties.privateIPAddress : network_card.properties.ipConfigurations[0].properties.privateIPAddress

output ssh_network_id string = (subnet_id != ssh_subnet_id) ? ssh_network_card.id : network_card.id 

output primary_network_id string = network_card.id 
