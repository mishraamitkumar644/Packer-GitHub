provider "azurerm" {
  features {}
}

# Reference your Packer image
data "azurerm_image" "custom" {
  name                = "ubuntu-docker-nginx"
  resource_group_name = "rg-canada-prod"
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-vm-prod"
  location = "canadacentral"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vm-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "vm-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "pip" {
  name                = "vm-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "nic" {
  name                = "vm-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}
variable "ssh_public_key" {}
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "custom-vm"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = "Standard_B2s"

  admin_username = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  source_image_id = data.azurerm_image.custom.id

  admin_ssh_key {
    username   = "azureuser"
    public_key = var.ssh_public_key
  }

  disable_password_authentication = true

  # The os_disk MUST stay inside the resource block
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}
