
@description('Environment Prefix')
param envPrefix string = 'dev'

@description('VM Reference Number')
param vmReferenceNumber int = 1

@description('Location for all resources') 
param dev1Loc string = 'eastus'

@description('Subnet ID')
param dev1SubnetId string

@description('The admin username')
param admin_user_name string

@description('The admin password')
@secure()
param admin_user_password string


module data_science_vms './modules/virtual-machine.bicep' = {
  name: 'dsvm-${vmReferenceNumber}'
  params: {
    vm_name: '${envPrefix}-dsvm-${vmReferenceNumber}'
    location: dev1Loc
    subnet_id: dev1SubnetId
    vm_image_publisher: 'microsoft-dsvm'
    vm_image_offer: 'ubuntu-2204'
    vm_image_sku: '2204-gen2'
    vm_compute_size: 'Standard_DS3_v2'
    vm_image_version: 'latest'
    admin_user_name: admin_user_name
    admin_user_password: admin_user_password
    default_tag_name: 'environment'
    default_tag_value: envPrefix
  }
}
