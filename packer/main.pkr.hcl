packer {
  required_plugins {
    azure = {
      source  = "github.com/hashicorp/azure"
      version = ">= 2.0.0"
    }
  }
}

source "azure-arm" "ubuntu" {

  use_azure_cli_auth = true

  subscription_id = "e397652c-2118-4f8c-918d-90f1bdb9bc73"

  location = var.location
  vm_size  = var.vm_size

  os_type         = "Linux"
  image_publisher = "Canonical"
  image_offer     = "0001-com-ubuntu-server-jammy"
  image_sku       = "22_04-lts-gen2"

  ssh_username = "azureuser"

  managed_image_resource_group_name = var.resource_group_name
  managed_image_name                = var.image_name

  shared_image_gallery_destination {
    resource_group      = var.resource_group_name
    gallery_name        = var.gallery_name
    image_name          = var.image_name
    image_version       = var.image_version
    replication_regions = [var.location]
  }

  async_resourcegroup_delete = false
}

build {

  name = "ubuntu-image-build"

  sources = [
    "source.azure-arm.ubuntu"
  ]

  provisioner "shell" {
  inline = [
    "sudo rm -rf /var/lib/apt/lists/*",
    "sudo apt-get clean",
    "sudo apt-get update || true",
    "sudo apt-get install -y nginx",
    "sudo systemctl enable nginx",
    "sudo systemctl start nginx",
  ]
}
}
