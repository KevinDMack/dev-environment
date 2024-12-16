packer {
  required_plugins {
    azure = {
      source  = "github.com/hashicorp/azure"
      version = "~> 1"
    }
  }
}

variable "vm_location" {
    type = string
}

variable "admin_username" {
    type = string
    default = "azureuser"
}

variable "managed_image_name" {
  type = string 
}

variable "managed_image_resource_group_name" {
  type = string
  default = "vth-constellation-images"
}

variable "subscription_id" {
  type = string 
}
variable "client_id" {
  type = string 
}
variable "client_secret" {
  type = string 
}
variable "tenant_id" {
  type = string 
}

variable "constellation_private_key_name" {
  type = string
  default = "constellation-key-private"
}

variable "constellation_public_key_name" {
  type = string
  default = "constellation-key-public"
}

variable "constellation_key_file_name" {
  type = string
  default = "constellation_key"
}

variable "key_vault_name" {
  type = string
}

variable "spacefx_version" {
  type = string
}

variable "image_size" {
  type = string
  default = "Standard_E8s_v4"
}

source "azure-arm" "ubuntu2204" {
  client_id = var.client_id
  client_secret = var.client_secret
  tenant_id = var.tenant_id
  image_publisher = "Canonical"
  image_offer     = "0001-com-ubuntu-server-jammy"
  image_sku       = "22_04-lts-gen2"
  image_version   = "latest"
  location        = var.vm_location
  os_type  = "Linux"
  vm_size  = var.image_size
  ssh_username = var.admin_username
  managed_image_name                      = var.managed_image_name
  managed_image_resource_group_name       = var.managed_image_resource_group_name
  subscription_id = var.subscription_id
}

build {
  sources = ["source.azure-arm.ubuntu2204"]

  # Create landing directory for bootstrap
  provisioner "shell" {
    inline = [ 
      join("", ["sudo mkdir -p /home/", var.admin_username, "/sdk-bootstrap/env"]),
      join("", ["sudo chown -R $USER:$USER /home/", var.admin_username, "/sdk-bootstrap/"]),
      join("", ["sudo mkdir -p /home/", var.admin_username, "/sdk-bootstrap/machine-config"]),
      join("", ["sudo chown -R $USER:$USER /home/", var.admin_username, "/sdk-bootstrap/machine-config"]),
      join("", ["sudo mkdir -p /home/", var.admin_username, "/inbox/"]),
      join("", ["sudo chown -R $USER:$USER /home/", var.admin_username, "/inbox/"]),
      join("", ["sudo mkdir -p /home/", var.admin_username, "/outbox/"]),
      join("", ["sudo chown -R $USER:$USER /home/", var.admin_username, "/outbox/"])
      ]
  }

  # Copy SDK Bootstrap
  provisioner "file" {
    source = "./sdk-bootstrap/"
    destination = join("", ["/home/", var.admin_username, "/sdk-bootstrap/"])
  }

  # Copy Environment File
  provisioner "file" {
    source = join("", ["./sdk-bootstrap/envs/spacefx.", var.spacefx_version, ".env" ])
    destination = join("", ["/home/", var.admin_username, "/sdk-bootstrap/spacefx.env"])
  }

  # Configure sdk-bootstrap
  provisioner "shell" {
    inline = [       
      join("", ["sudo chown -R $USER:$USER /home/", var.admin_username, "/sdk-bootstrap/"]),
      join("", ["sudo chmod +x -R /home/", var.admin_username, "/sdk-bootstrap/"])
      ]
  }

  # Install pre-reqs
  provisioner "shell" {
    inline = [ 
      join("", ["cd /home/", var.admin_username, "/sdk-bootstrap/"]),
      join("", ["sudo chmod +x /home/", var.admin_username, "/sdk-bootstrap/", "install-space-sdk-prereqs.sh"]),
      join("", ["bash ./install-space-sdk-prereqs.sh --docker"])
      ]
  }

  provisioner "shell" {
    inline = [ 
      "docker version",
      ]
  }

  # Login to Azure CLI
  provisioner "shell" {
    inline = [ 
      join("", ["az login --service-principal --username ", var.client_id, " --password ", var.client_secret, " --tenant ", var.tenant_id]),
      join("", ["sudo az login --service-principal --username ", var.client_id, " --password ", var.client_secret, " --tenant ", var.tenant_id])
      ]
  }

  # Copy constellation key to enable copying between
  provisioner "shell" {
    inline = [ 
      join("", ["sudo az keyvault secret download --name ", var.constellation_private_key_name, " --vault-name ", var.key_vault_name, " -f /home/", var.admin_username, "/.ssh/", var.constellation_key_file_name ]),
      join("", ["sudo az keyvault secret download --name ", var.constellation_public_key_name, " --vault-name ", var.key_vault_name, " -f /home/", var.admin_username, "/.ssh/", var.constellation_key_file_name, ".pub" ]),
      join("", ["sudo chmod 700 ~/.ssh"]),
      join("", ["sudo cat /home/", var.admin_username, "/.ssh/", var.constellation_key_file_name, ".pub >> ~/.ssh/authorized_keys" ]),
      join("", ["sudo chmod 600 ~/.ssh/", var.constellation_key_file_name ]),
      join("", ["sudo chown $USER:$USER ~/.ssh/", var.constellation_key_file_name ])
      ]
  }

  provisioner "shell" {
    inline = [ 
      "echo \"Performing az logout...\"...",
      "az account show &> /dev/null && echo \"Logged in, logging out now...\" && az logout || echo \"Not logged in\"",
      "echo \"Performed az logout\"..."
      ]
  }

  provisioner "shell" {
    inline = [ 
      "sleep 30",
      ]
  }
}