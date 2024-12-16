param public_ip_name string 
param location string 

param default_tag_name string
param default_tag_value string

resource vm_public_ip 'Microsoft.Network/publicIPAddresses@2020-11-01' = {
  name: public_ip_name
  location: location
  tags: {
    '${default_tag_name}': default_tag_value
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

output public_ip_id string = vm_public_ip.id 
