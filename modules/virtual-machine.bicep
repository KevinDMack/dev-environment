param vm_name string 
param location string = resourceGroup().location
param subnet_id string

// Data Science VM Configuration:
param data_science_vm_type string = 'Linux'

// Disk Image Configuration:
param vm_image_publisher string = 'microsoft-dsvm'
param vm_image_offer string = 'ubuntu-2204'
param vm_image_sku string = '2204-gen2'
param vm_image_version string = 'latest'

param vm_compute_size string = 'Standard_DS3_v2'

// Data Disk Configuration:
param vm_data_disk_size int = 1024

// User Configuration:
param admin_user_name string
@secure()
param admin_user_password string

param default_tag_name string
param default_tag_value string

resource dsVm 'Microsoft.Compute/virtualMachines@2021-07-01' = {
  name: vm_name
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  tags: {
    '${default_tag_name}': default_tag_value
  }
  properties: {
    hardwareProfile: {
      vmSize: vm_compute_size
    }
    storageProfile: {
      imageReference: {
        publisher: vm_image_publisher
        offer: vm_image_offer
        sku: vm_image_sku
        version: vm_image_version
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
      dataDisks: [
        {
          lun: 0
          createOption: 'Empty'
          diskSizeGB: vm_data_disk_size
          managedDisk: {
            storageAccountType: 'Standard_LRS'
          }
        }
      ]
    }
    osProfile: {
      computerName: vm_name
      adminUsername: admin_user_name
      adminPassword: admin_user_password
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: '${vm_name}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnet_id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

resource vmExtension 'Microsoft.Compute/virtualMachines/extensions@2024-07-01' = {
  name: data_science_vm_type == 'Linux' ? 'AADLoginForLinux' : 'AADLoginForWindows'
  parent: dsVm
  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: data_science_vm_type == 'Linux' ? 'AADLoginForLinux' : 'AADLoginForWindows'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {}
  }
}
