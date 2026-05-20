terraform {

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.13.0"
    }
  }
}

# -----------------------------
# PROVIDER
# -----------------------------

provider "azurerm" {
  features {}
  subscription_id = "e397672c-2118-4f8c-918d-90f1bdb9bc73"
}

# -----------------------------
# VARIABLE
# -----------------------------

variable "ssh_public_key" {
  type = string
}

# -----------------------------
# Resource Group
# -----------------------------

resource "azurerm_resource_group" "rg" {
  name     = "rg-linux-vm"
  location = "Canada Central"
}

# -----------------------------
# Virtual Network
# -----------------------------

resource "azurerm_virtual_network" "vnet" {
  name                = "linux-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# -----------------------------
# Subnet
# -----------------------------

resource "azurerm_subnet" "subnet" {
  name                 = "linux-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# -----------------------------
# Public IP
# -----------------------------

resource "azurerm_public_ip" "pip" {
  name                = "linux-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# -----------------------------
# NSG
# -----------------------------

resource "azurerm_network_security_group" "nsg" {

  name                = "linux-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# -----------------------------
# NIC
# -----------------------------

resource "azurerm_network_interface" "nic" {

  name                = "linux-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

# -----------------------------
# NSG Association
# -----------------------------

resource "azurerm_network_interface_security_group_association" "assoc" {

  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# -----------------------------
# CUSTOM IMAGE
# -----------------------------

data "azurerm_image" "custom" {
  name                = "ubuntu-docker-nginx"
  resource_group_name = "rg-canada-prod"
}

# -----------------------------
# Linux VM
# -----------------------------

resource "azurerm_linux_virtual_machine" "vm" {

  name                = "linux-custom-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_D2s_v5"

  admin_username = "azureuser"

  disable_password_authentication = true

  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = var.ssh_public_key
  }

  source_image_id = data.azurerm_image.custom.id

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}

# -----------------------------
# OUTPUT
# -----------------------------

output "public_ip" {
  value = azurerm_public_ip.pip.ip_address
}
