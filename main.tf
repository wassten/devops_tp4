terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "765266c6-9a23-4638-af32-dd1e32613047"
}

data "azurerm_resource_group" "example" {
  name = "devops-TP2"
}

data "azurerm_virtual_network" "main" {
  resource_group_name = data.azurerm_resource_group.example.name

  name = "example-network"
}

data "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = data.azurerm_resource_group.example.name
  virtual_network_name = data.azurerm_virtual_network.main.name
}

resource "azurerm_public_ip" "example" {
  name                = "devops-public-IP-20201184"
  resource_group_name = data.azurerm_resource_group.example.name
  location            = "francecentral"
  allocation_method   = "Static"

  tags = {
    environment = "Production"
  }
}

resource "azurerm_network_interface" "example" {
  name                = "devops-20201184"
  location            = "francecentral"
  resource_group_name = data.azurerm_resource_group.example.name

  ip_configuration {
    public_ip_address_id          = azurerm_public_ip.example.id  
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "tls_private_key" "ssh" {
  algorithm   = "RSA"
  rsa_bits = "4096"
}

resource "azurerm_linux_virtual_machine" "example" {
  name                = "devops-20201184"
  resource_group_name = data.azurerm_resource_group.example.name
  location            = "francecentral"
  size                = "Standard_D2s_v3"
  admin_username      = "devops"
  network_interface_ids = [
    azurerm_network_interface.example.id,
  ]

  admin_ssh_key {
    username   = "devops"
    public_key = tls_private_key.ssh.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
}

output "private_key" {
  value     = tls_private_key.ssh.private_key_pem
  sensitive = true
}
