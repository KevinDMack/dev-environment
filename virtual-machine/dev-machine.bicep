param satellite_name string = ''
param location string = ''

//Virtual Machine Parametets
param vm_size string = ''
param admin_user string = 'azureuser'
param os_image_id string = ''
param os_disk_size int = 80

//registry parameters
param registry_id string = ''

//storage paramters
param storage_account_id string = ''

//key vault parameters
param key_vault_id string = ''

//Linux Key Parameters
param ssh_public_key string =  ''

//Network Control Paramters
param enable_public_ip bool = false

//Existing network subnet parameters:
param existing_subnet_id string = ''
param ssh_subnet_id string = '' 

// Static IP parameters
param primary_static_private_ip string = ''
param ssh_static_private_ip string = ''

param default_tag_name string = 'Component'
param default_tag_value string = 'Space SDK'

// Monitoring parameters
param work_space_name string = ''
param work_space_resource_group_name string = ''
param performance_metrics_rule_id string = ''
param sdk_log_rule_id string = ''

// Auto Shutdown:
param shutdown_time string = '' // Format: HH:mm
param time_zone string = 'US Eastern Standard Time' // Default: UTC

// Role Defintions:
param acr_push_role_id string = '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/8311e382-0749-4cb8-b61a-304f252e45ec'
param acr_pull_role_id string = '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/7f951dda-4ed3-4680-a7ca-43fe172d538d'
param acr_delete_role_id string = '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/c2f4ef07-c644-48eb-af81-4b1b4947fb11'
param stg_blob_data_contributor string = '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/ba92f5b4-2d11-453d-a403-e96b0029c9fe'
param kv_user string = '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/4633458b-17de-408a-b874-0445c86b69e6'

// NSG Rules
param satellite_cidr_block string = '10.0.0.0/16'
param ground_station_cidr_block string = '10.0.0.0/16'
param ssh_cidr_block string = '10.0.0.0/16'
param disable_network_communication bool = false 
param base_security_rules array = [
  {
    name: 'AllowSSH_10_0_0_0'
    priority: 1001
    protocol: 'Tcp'
    access: 'Allow'
    direction: 'Inbound'
    sourcePortRange: '*'
    sourceAddressPrefix: ssh_cidr_block
    destinationPortRange: '22'
    destinationAddressPrefix: '*'
  },{
    name: 'AllowSSH_10_1_0_0'
    priority: 1002
    protocol: 'Tcp'
    access: 'Allow'
    direction: 'Inbound'
    sourcePortRange: '*'
    sourceAddressPrefix: '10.1.0.0/16'
    destinationPortRange: '22'
    destinationAddressPrefix: '*'
  },{
    name: 'AllowSSH_10_2_0_0'
    priority: 1003
    protocol: 'Tcp'
    access: 'Allow'
    direction: 'Inbound'
    sourcePortRange: '*'
    sourceAddressPrefix: '10.2.0.0/24'
    destinationPortRange: '22'
    destinationAddressPrefix: '*'
  },{
    name: 'DenyFromInternetIcmp'
    priority: 2023
    protocol: 'Icmp'
    access: 'Deny'
    direction: 'Inbound'
    sourcePortRange: '*'
    sourceAddressPrefix: satellite_cidr_block
    destinationPortRange: '*'
    destinationAddressPrefix: 'Internet'
  },{
    name: 'DenyFromInternetTcp'
    priority: 2024
    protocol: 'Tcp'
    access: 'Deny'
    direction: 'Inbound'
    sourcePortRange: '*'
    sourceAddressPrefix: satellite_cidr_block
    destinationPortRange: '*'
    destinationAddressPrefix: 'Internet'
  },{
    name: 'DenyToInternetIcmp'
    priority: 2021
    protocol: 'Icmp'
    access: 'Deny'
    direction: 'Outbound'
    sourcePortRange: '*'
    sourceAddressPrefix: satellite_cidr_block
    destinationPortRange: '*'
    destinationAddressPrefix: 'Internet'
  },{
    name: 'DenyToInternetTcp'
    priority: 2022
    protocol: 'Tcp'
    access: 'Deny'
    direction: 'Outbound'
    sourcePortRange: '*'
    sourceAddressPrefix: satellite_cidr_block
    destinationPortRange: '*'
    destinationAddressPrefix: 'Internet'
  }
]
param satellite_to_ground_rules array = [
  {
    name: 'DenyFromVnetUdp'
    priority: 2001
    protocol: 'Udp'
    access: 'Deny'
    direction: 'Inbound'
    sourcePortRange: '*'
    sourceAddressPrefix: satellite_cidr_block
    destinationPortRange: '*'
    destinationAddressPrefix: ground_station_cidr_block
  },{
    name: 'DenyFromVnetIcmp'
    priority: 2002
    protocol: 'Icmp'
    access: 'Deny'
    direction: 'Inbound'
    sourcePortRange: '*'
    sourceAddressPrefix: satellite_cidr_block
    destinationPortRange: '*'
    destinationAddressPrefix: ground_station_cidr_block
  },{
    name: 'DenyFromVnetTcp'
    priority: 2003
    protocol: 'Tcp'
    access: 'Deny'
    direction: 'Inbound'
    sourcePortRange: '*'
    sourceAddressPrefix: satellite_cidr_block
    destinationPortRange: '*'
    destinationAddressPrefix: ground_station_cidr_block
  }
]
param ground_to_satellite_rules array = [
  {
    name: 'DenyToVnetUdp'
    priority: 2001
    protocol: 'Udp'
    access: 'Deny'
    direction: 'Outbound'
    sourcePortRange: '*'
    sourceAddressPrefix: ground_station_cidr_block
    destinationPortRange: '*'
    destinationAddressPrefix: satellite_cidr_block
  },{
    name: 'DenyToVnetIcmp'
    priority: 2002
    protocol: 'Icmp'
    access: 'Deny'
    direction: 'Outbound'
    sourcePortRange: '*'
    sourceAddressPrefix: ground_station_cidr_block
    destinationPortRange: '*'
    destinationAddressPrefix: satellite_cidr_block
  },{
    name: 'DenyToVnetTcp'
    priority: 2003
    protocol: 'Tcp'
    access: 'Deny'
    direction: 'Outbound'
    sourcePortRange: '*'
    sourceAddressPrefix: ground_station_cidr_block
    destinationPortRange: '*'
    destinationAddressPrefix: satellite_cidr_block
  } 
]

module nics './nic.bicep' = {
  name: '${satellite_name}-nics'
  params: {
    satellite_name: satellite_name
    location: location
    subnet_id: existing_subnet_id
    primary_static_private_ip: primary_static_private_ip
    ssh_subnet_id: ssh_subnet_id
    ssh_static_private_ip: ssh_static_private_ip
    nsg_id: nsg.outputs.nsg_id
    enable_public_ip: enable_public_ip
    default_tag_name: default_tag_name
    default_tag_value: default_tag_value
  }
}

module nsg './nsg.bicep' = {
  name: '${satellite_name}-nsg'
  params: {
    satellite_name: satellite_name
    location: location
    base_security_rules: (disable_network_communication ?  base_security_rules : [])
    satellite_to_ground_rules: (disable_network_communication ? satellite_to_ground_rules : [])
    ground_to_satellite_rules: (disable_network_communication ? ground_to_satellite_rules : [])
    default_tag_name: default_tag_name
    default_tag_value: default_tag_value
  }
}

module virtual_machine './virtual-machine.bicep' = {
  name: '${satellite_name}-vm'
  params: {
    satellite_name: satellite_name
    location: location 
    vm_size: vm_size
    os_disk_size: os_disk_size
    admin_user: admin_user
    ssh_public_key: ssh_public_key
    os_image_id: os_image_id
    ssh_nic_id: nics.outputs.ssh_network_id
    primary_nic_id: nics.outputs.primary_network_id
    work_space_name: work_space_name
    work_space_resource_group_name: work_space_resource_group_name
    performance_metrics_rule_id: performance_metrics_rule_id
    sdk_log_rule_id: sdk_log_rule_id
    shutdown_time : shutdown_time
    time_zone : time_zone
    default_tag_name: default_tag_name
    default_tag_value: default_tag_value
  }
}

resource acrPush 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(registry_id)) {
  name: guid('${virtual_machine.name}', 'acrpush')
  properties: {
    roleDefinitionId: acr_push_role_id
    principalId: virtual_machine.outputs.managed_identity_principal_id
  }
  dependsOn: [
    virtual_machine
  ]
}

resource acrPull 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(registry_id)) {
  name: guid('${virtual_machine.name}', 'acrpull')
  properties: {
    roleDefinitionId: acr_pull_role_id
    principalId: virtual_machine.outputs.managed_identity_principal_id
  }
  dependsOn: [
    virtual_machine
  ]
}

resource acrDelete 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(registry_id)) {
  name: guid('${virtual_machine.name}', 'acrdelete')
  properties: {
    roleDefinitionId: acr_delete_role_id
    principalId: virtual_machine.outputs.managed_identity_principal_id
  }
  dependsOn: [
    virtual_machine
  ]
}

resource stgBloDataContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(storage_account_id)) {
  name: guid('${virtual_machine.name}', 'stg')
  properties: {
    roleDefinitionId: stg_blob_data_contributor
    principalId: virtual_machine.outputs.managed_identity_principal_id
  }
  dependsOn: [
    virtual_machine
  ]
}

resource kv 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(key_vault_id)) {
  name: guid('${virtual_machine.name}', 'stg')
  properties: {
    roleDefinitionId: kv_user
    principalId: virtual_machine.outputs.managed_identity_principal_id
  }
  dependsOn: [
    virtual_machine
  ]
}

output virtual_machine_name string = virtual_machine.name
output private_ip_address array = nics.outputs.private_ips
output public_ip_address array = nics.outputs.public_ips
output private_ip_primary string = nics.outputs.private_ip_primary
output ssh_ip_address string = nics.outputs.private_ip_ssh
output virtual_machine_id string = virtual_machine.outputs.vm_name
output virtual_machine_admin_name string = virtual_machine.outputs.admin_user_name
output virtual_machine_managed_identity_id string = virtual_machine.outputs.managed_identity_principal_id
output identity object = virtual_machine.outputs.identity
