# Azure provider configuration
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

#####
##### Resource Group #####
#####
resource "azurerm_resource_group" "rg" {
  name     = "tf-managed"
  location = "swedencentral"
  tags = {
    terraform-managed = "true"
  }
}

#####
##### Base network infrastructure #####
#####


resource "azurerm_public_ip" "ip1" {
  name                = "tf-managed-ip1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"

  tags = {
    terraform-managed = "true"
  }

}
#####
##### Virtual Machine 1 #####
#####

resource "azurerm_network_interface" "nic1" {
  name                = "tf-managed-nic1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  enable_accelerated_networking = true

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ip1.id
  }

  tags = {
    terraform-managed = "true"
  }

}

resource "azurerm_network_interface_security_group_association" "nic-to-nsg" {
  network_interface_id      = azurerm_network_interface.nic1.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_linux_virtual_machine" "vm1" {
  name                = "tf-managed-vm1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B2pls_v2"
  admin_username      = "cmocan"
  network_interface_ids = [
    azurerm_network_interface.nic1.id,
  ]

  admin_ssh_key {
    username   = "cmocan"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "debian"
    offer     = "debian-12"
    sku       = "12-arm64"
    version   = "latest"
  }

  tags = {
    terraform-managed = "true"
  }
}

#####
##### Storage Account & Blob #####
#####

resource "azurerm_storage_account" "sa1" {
  name                     = "tfmanagedsa1"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  access_tier              = "Cool" 

  tags = {
    terraform-managed = "true"
  }
}

resource "azurerm_storage_container" "sc1" {
  name                  = "synology-backup"
  storage_account_name  = azurerm_storage_account.sa1.name
  container_access_type = "private"
  
}
