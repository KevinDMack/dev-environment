# DevEnvironment
A infrastructure-as-code template for deploying a development environment in azure.  

### Prerequisites

- AZ CLI (logged in)

### Installing

Creating the environment 
1. Log in w/ AZ CLI 
```
 az login --use-device-code
```
2. Verify that you are in the desired subscription 
```
az account show
```
3. Create the target Resource Group
```
az group create --resource-group myRG --location westus2
```
4. Deploy the main.bicep
```
az deployment group create --resource-group sdkinf2 --template-file ./main.bicep
```


## How to Use A Created Infra Environment
1. Retrieve the azurevpnconfig.xml VPN configuration file, in one of 2 ways:

    a. Be provided it by a team member
    b. Via the Azure Portal 
        - Navigate to the Virtual Network Gateway resource
        - Switch to the "Point-to-site configuration" blade
        - Select "Download VPN client"
        ![Download VPN Client](img/downloadVPNClient.png)
        - Unzip the downloaded VPN package from your Downloads folder. The azurevpnconfig.xml file will be under the "AzureVPN" folder
1. Install the Azure VPN client for your OS if you haven't already

    - https://learn.microsoft.com/en-us/azure/vpn-gateway/openvpn-azure-ad-client#download
1. Open the Azure VPN Client and import the azurevpnconfig.xml from above. Then Connect this VPN (note - you must disconnect other VPNs)
    - https://learn.microsoft.com/en-us/azure/vpn-gateway/openvpn-azure-ad-client#import

1. You may now access resources in the development VNets using their private IPs. Ex: in VS.Code's configure Hosts.
    - You can obtain the private IP for your VM from the Azure Portal. For default implementations, it should be in the 10.*.*.* address space (10.0.0.0/16), likely 10.2.0.# or 10.3.0.#. 
    Note - fix your username and identity file
 ![VS.Code Configure SSH Host](img/vscodessh.png)