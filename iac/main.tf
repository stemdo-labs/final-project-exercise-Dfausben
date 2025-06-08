terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

# First VNet with two subnets
resource "azurerm_virtual_network" "vnet1" {
  name                = "${var.prefix}-vnet1"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name
  tags                = var.default_tags
}

resource "azurerm_subnet" "subnet1" {
  name                 = "${var.prefix}-subnet1"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "subnet2" {
  name                 = "${var.prefix}-subnet2"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.0.2.0/24"]
}

# VMs in each subnet
resource "azurerm_network_interface" "nic1" {
  name                = "${var.prefix}-nic1"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm1_public_ip.id
  }
}

resource "azurerm_network_interface" "nic2" {
  name                = "${var.prefix}-nic2"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet2.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "vm1" {
  name                = "${var.prefix}-vm1"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.location
  size                = "Standard_B1ms"
  admin_username      = var.admin_username
  network_interface_ids = [
    azurerm_network_interface.nic1.id,
  ]
  admin_ssh_key {
    username   = var.admin_username
    public_key = tls_private_key.vms_key.public_key_openssh
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  tags = var.default_tags
}

resource "azurerm_linux_virtual_machine" "vm2" {
  name                = "${var.prefix}-vm2"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.location
  size                = "Standard_B1ms"
  admin_username      = var.admin_username
  network_interface_ids = [
    azurerm_network_interface.nic2.id,
  ]
  admin_ssh_key {
    username   = var.admin_username
    public_key = tls_private_key.vms_key.public_key_openssh
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  tags = var.default_tags
}

# Second VNet for AKS
resource "azurerm_virtual_network" "vnet2" {
  name                = "${var.prefix}-vnet2"
  address_space       = ["10.1.0.0/16"]
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name
  tags                = var.default_tags
}

resource "azurerm_subnet" "aks_subnet" {
  name                 = "${var.prefix}-aks-subnet"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet2.name
  address_prefixes     = ["10.1.1.0/24"]
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${var.prefix}-aks"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name
  dns_prefix          = "${var.prefix}-aks"

  default_node_pool {
    name            = "default"
    node_count      = 2
    vm_size         = "Standard_B2s"
    vnet_subnet_id  = azurerm_subnet.aks_subnet.id
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "azure"
    load_balancer_sku  = "standard"
    outbound_type      = "loadBalancer"
  }

  tags = var.default_tags
}

resource "azurerm_container_registry" "acr" {
  name                = "${var.prefix}acr"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.location
  sku                 = "Basic"
  admin_enabled       = true
  tags                = var.default_tags
}

# VNet Peering between vnet1 and vnet2
resource "azurerm_virtual_network_peering" "vnet1_to_vnet2" {
  name                      = "vnet1-to-vnet2"
  resource_group_name       = data.azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.vnet1.name
  remote_virtual_network_id = azurerm_virtual_network.vnet2.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "vnet2_to_vnet1" {
  name                      = "vnet2-to-vnet1"
  resource_group_name       = data.azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.vnet2.name
  remote_virtual_network_id = azurerm_virtual_network.vnet1.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

resource "tls_private_key" "vms_key" {
    algorithm = "RSA"
    rsa_bits  = 4096
}

resource "local_file" "vms_private_key" {
    content         = tls_private_key.vms_key.private_key_pem
    filename        = "${path.module}/vms_key.pem"
    file_permission = "0600"
} 

resource "azurerm_virtual_machine_extension" "copy_private_key_to_vm1" {
  name                 = "copyPrivateKey"
  virtual_machine_id   = azurerm_linux_virtual_machine.vm1.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"

  settings = jsonencode({
    commandToExecute = "mkdir -p /home/${var.admin_username}/.ssh && echo '${base64encode(tls_private_key.vms_key.private_key_pem)}' | base64 -d > /home/${var.admin_username}/.ssh/id_rsa && chmod 600 /home/${var.admin_username}/.ssh/id_rsa && chown ${var.admin_username}:${var.admin_username} /home/${var.admin_username}/.ssh/id_rsa"
  })

  depends_on = [azurerm_linux_virtual_machine.vm1]
}

resource "azurerm_network_security_group" "nsg_vm2" {
  name                = "${var.prefix}-nsg-vm2"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowSSHFromVM1"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = azurerm_network_interface.nic1.private_ip_address
    source_port_range          = "*"
    destination_port_range     = "22"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowFromAKS"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_address_prefix      = azurerm_subnet.aks_subnet.address_prefixes[0]
    source_port_range          = "*"
    destination_port_range     = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    destination_address_prefix = "*"
  }

  tags = var.default_tags
}

resource "azurerm_network_interface_security_group_association" "nic2_nsg" {
  network_interface_id      = azurerm_network_interface.nic2.id
  network_security_group_id = azurerm_network_security_group.nsg_vm2.id
}

resource "azurerm_public_ip" "vm1_public_ip" {
  name                = "${var.prefix}-vm1-pip"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
  sku                 = "Basic"
  tags                = var.default_tags
}
