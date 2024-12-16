param satellite_name string = ''
param location string = ''

// Security Rules
param base_security_rules array = []
param satellite_to_ground_rules array = []
param ground_to_satellite_rules array = []

param default_tag_name string
param default_tag_value string

resource machine_nsg 'Microsoft.Network/networkSecurityGroups@2023-06-01' = {
  name: '${satellite_name}-nsg'
  location: location
  tags: {
    '${default_tag_name}': default_tag_value
  }
}

resource base_rule 'Microsoft.Network/networkSecurityGroups/securityRules@2023-06-01' = [for (rule, index) in base_security_rules: {
  parent: machine_nsg
  name: rule.name
  properties: {
    protocol: rule.protocol
    sourcePortRange: rule.sourcePortRange
    sourceAddressPrefix: rule.sourceAddressPrefix
    destinationPortRange: rule.destinationPortRange
    destinationAddressPrefix: rule.destinationAddressPrefix
    access: rule.access
    priority: rule.priority
    direction: rule.direction 
  }
}]

resource satellite_to_ground_rule 'Microsoft.Network/networkSecurityGroups/securityRules@2023-06-01' = [for (rule, index) in satellite_to_ground_rules: {
  parent: machine_nsg
  name: rule.name
  properties: {
    protocol: rule.protocol
    sourcePortRange: rule.sourcePortRange
    sourceAddressPrefix: rule.sourceAddressPrefix
    destinationPortRange: rule.destinationPortRange
    destinationAddressPrefix: rule.destinationAddressPrefix
    access: rule.access
    priority: rule.priority
    direction: rule.direction 
  }
}]

resource ground_to_satellite_rule 'Microsoft.Network/networkSecurityGroups/securityRules@2023-06-01' = [for (rule, index) in ground_to_satellite_rules: {
  parent: machine_nsg
  name: rule.name
  properties: {
    protocol: rule.protocol
    sourcePortRange: rule.sourcePortRange
    sourceAddressPrefix: rule.sourceAddressPrefix
    destinationPortRange: rule.destinationPortRange
    destinationAddressPrefix: rule.destinationAddressPrefix
    access: rule.access
    priority: rule.priority
    direction: rule.direction 
  }
}]

output nsg_id string = machine_nsg.id 
