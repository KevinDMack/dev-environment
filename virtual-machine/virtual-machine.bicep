param satellite_name string = ''
param location string = ''
param vm_size string = ''
param os_disk_size int = 80
param data_disk_size int = 1024
param admin_user string = 'azureuser'
param ssh_public_key string = ''
param os_image_id string = ''
param ssh_nic_id string = ''
param primary_nic_id string = ''
param work_space_name string = ''
param work_space_resource_group_name string = ''
param performance_metrics_rule_id string = ''
param sdk_log_rule_id string = ''
param shutdown_time string = '' // Format: HH:mm
param time_zone string = 'UTC' // Default: UTC

param default_tag_name string
param default_tag_value string

resource virtual_resource 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: satellite_name  
  location: location
  tags: {
    '${default_tag_name}': default_tag_value
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: vm_size
    }
    osProfile: {
      computerName: satellite_name
      adminUsername: admin_user
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              keyData: ssh_public_key
              path: '/home/azureuser/.ssh/authorized_keys'
            }
          ]
        }
      }
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
        diskSizeGB: os_disk_size
      }
      dataDisks: [
        {
          lun: 0
          createOption: 'Empty'
          diskSizeGB: data_disk_size
          managedDisk: {
            storageAccountType: 'Standard_LRS'
          }
        }
      ]
      imageReference: {
        id: os_image_id
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: primary_nic_id
          properties: {
            primary: true
          }
        }
        {
          id: ssh_nic_id
          properties: {
            primary: false
          }
        }
      ]
    }
  }
}

// Log Analytics and Monitoring
resource log_analytics_workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = if (!empty(work_space_name)) {
  name: work_space_name
  scope: resourceGroup(work_space_resource_group_name)
}

// Data Collection Rules
resource metricsCollectionRuleAssociation 'Microsoft.Insights/dataCollectionRuleAssociations@2022-06-01' = if (!empty(performance_metrics_rule_id)) {
  name: '${virtual_resource.name}-metrics-association'
  scope: virtual_resource
  properties: {
    dataCollectionRuleId: performance_metrics_rule_id
  }
}

resource sdkCollectionRuleAssociation 'Microsoft.Insights/dataCollectionRuleAssociations@2022-06-01' = if (!empty(sdk_log_rule_id)) {
  name: '${virtual_resource.name}-sdk-association'
  scope: virtual_resource
  properties: {
    dataCollectionRuleId: sdk_log_rule_id
  }
}

// Enable auto-shutdown
resource autoShutdown 'Microsoft.DevTestLab/schedules@2018-09-15' = if (!empty(shutdown_time)) {
  name: 'shutdown-computevm-${virtual_resource.name}'
  location: location
  tags: {
    '${default_tag_name}': default_tag_value
  }
  properties: {
    status: 'Enabled'
    taskType: 'ComputeVmShutdownTask'
    dailyRecurrence: {
      time: shutdown_time
    }
    timeZoneId: time_zone
    targetResourceId: virtual_resource.id
    notificationSettings: {
      status: 'Disabled'
    }
  }
}

// Monitoring Agent
resource azureMonitorAgent 'Microsoft.Compute/virtualMachines/extensions@2021-04-01' = if (!empty(work_space_name)) {
  name: 'AzureMonitorLinuxAgent'
  parent: virtual_resource
  tags: {
    '${default_tag_name}': default_tag_value
  }
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Monitor'
    type: 'AzureMonitorLinuxAgent'
    typeHandlerVersion: '1.13'
    autoUpgradeMinorVersion: true
    settings: {
      workspaceId: log_analytics_workspace.id
    }
  }
}

// Custom Script Extension to trigger SDK startup
// resource customScript 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = if (ssh_nic_id != primary_nic_id) {
//   name: 'customScript'
//   parent: virtual_resource
//   location: location
//   tags: {
//     '${default_tag_name}': default_tag_value
//   }
//   properties: {
//     publisher: 'Microsoft.Azure.Extensions'
//     type: 'CustomScript'
//     typeHandlerVersion: '2.1'
//     autoUpgradeMinorVersion: true
//     settings: {
//       commandToExecute: 'sudo systemctl enable sshconfig.service ; nohup sudo systemctl start sshconfig.service > /dev/null 2>&1 ; sudo systemctl enable spacesdk.service ; nohup sudo systemctl start spacesdk.service > /dev/null 2>&1 &'
//     }
//   }
// }

output vm_name string = virtual_resource.name
output admin_user_name string = virtual_resource.properties.osProfile.adminUsername
output managed_identity_principal_id string = virtual_resource.identity.principalId
output identity object = virtual_resource.identity
