provider "azurerm" {
  features {}

  skip_provider_registration = true
}
resource "azurerm_resource_group" "myRG" {
  name     = "myRG"
  location = "West Europe"
}


#Create Virtual Network
resource "azurerm_virtual_network" "myVnet" {
  name                = "myVnet"
  location            = azurerm_resource_group.myRG.location
  resource_group_name = azurerm_resource_group.myRG.name
  address_space       = ["192.168.0.0/16"]

  tags = {
    environment = "myVNET"
  }
}

# Create Public subnet
resource "azurerm_subnet" "myPublicSubnet" {
  name                 = "myPublicSubnet"
  resource_group_name  = azurerm_resource_group.myRG.name
  virtual_network_name = azurerm_virtual_network.myVnet.name
  address_prefixes     = ["192.168.10.0/24"]
}

# Create Private subnet
resource "azurerm_subnet" "myPrivateSubnet" {
  name                 = "myPrivateSubnet"
  resource_group_name  = azurerm_resource_group.myRG.name
  virtual_network_name = azurerm_virtual_network.myVnet.name
  address_prefixes     = ["192.168.20.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "myPiP" {
  name                = "myPublicIP"
  location            = azurerm_resource_group.myRG.location
  resource_group_name = azurerm_resource_group.myRG.name
  allocation_method   = "Dynamic"
}

# Create network interface
resource "azurerm_network_interface" "myNIC" {
  name                = "myNIC"
  location            = azurerm_resource_group.myRG.location
  resource_group_name = azurerm_resource_group.myRG.name

  ip_configuration {
    name                          = "myNicConfiguration"
    subnet_id                     = azurerm_subnet.myPrivateSubnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.myPiP.id
  }
}

resource "azurerm_network_security_group" "my-all-port-allow" {
  name                = "my-all-port-allow"
  location            = azurerm_resource_group.myRG.location
  resource_group_name = azurerm_resource_group.myRG.name

  security_rule {
    name                       = "my-all-port-allow"
    priority                   = 103
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "my-all-port-allow"
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "nsgandinterface" {
  network_interface_id      = azurerm_network_interface.myNIC.id
  network_security_group_id = azurerm_network_security_group.my-all-port-allow.id
}

resource "azurerm_virtual_machine" "myvm" {
   name                  = "myvm"
   location              = azurerm_resource_group.myRG.location
   resource_group_name   = azurerm_resource_group.myRG.name
   network_interface_ids = [azurerm_network_interface.myNIC.id]
   vm_size               = "Standard_DS1_v2"

   storage_image_reference {
     publisher = "Canonical"
     offer     = "UbuntuServer"
     sku       = "16.04-LTS"
     version   = "latest"
   }

  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

   os_profile {
     computer_name  = "myvm.local"
     admin_username = var.myusername
     admin_password = var.mypassword
   }

   os_profile_linux_config {
     disable_password_authentication = false
   }

   tags = {
     Name = "my-vm"
   }
 }