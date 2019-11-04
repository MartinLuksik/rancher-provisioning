variable "prefix" {
    default = "nbapcgo"
}

variable "vmsize" {
    default = "Standard_B2s"
}

variable "ubuntuuser" {
    default = "rancher"
}

variable "vmadminuser" {
    default = "admin"
}

variable "vmpassword" {
    default = "Password1234!"
}

resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}"
  location = "westeurope"
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = "${azurerm_resource_group.main.name}"
  virtual_network_name = "${azurerm_virtual_network.main.name}"
  address_prefix       = "10.0.2.0/24"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "main" {
    name                = "${var.prefix}-nsg"
    location            = "westeurope"
    resource_group_name = "${azurerm_resource_group.main.name}"
    
    security_rule {
        name                       = "SSH"
        priority                   = 300
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "HTTP"
        priority                   = 340
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "HTTPS"
        priority                   = 320
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
}

# Create public IPs
resource "azurerm_public_ip" "main" {
    name                         = "${var.prefix}ip"
    location                     = "westeurope"
    resource_group_name          = "${azurerm_resource_group.main.name}"
    allocation_method            = "Dynamic"
}

resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}-nic"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  network_security_group_id = azurerm_network_security_group.main.id

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = "${azurerm_subnet.internal.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${azurerm_public_ip.main.id}"

  }
}

resource "azurerm_virtual_machine" "main" {
  name                  = "${var.prefix}vm"
  location              = "${azurerm_resource_group.main.location}"
  resource_group_name   = "${azurerm_resource_group.main.name}"
  network_interface_ids = ["${azurerm_network_interface.main.id}"]
  vm_size               = "${var.vmsize}"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true


  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

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
    computer_name  = "${var.ubuntuuser}"
    admin_username = "${var.vmadminuser}"
    admin_password = "${var.vmpassword}"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
  }
}

#resource "azurerm_dns_a_record" "main" {
#  name                = "rancher"
#  zone_name           = "mldedicated.net"
#  resource_group_name = "mlstable"
#  ttl                 = 1
#  records             = ["${azurerm_public_ip.main.ip_address}"]
#}

data "azurerm_public_ip" "main" {
  name                = "${azurerm_public_ip.main.name"}
  resource_group_name = "${azurerm_resource_group.main.name}"
}

output "ipadressasoutput" {
  value = "${data.azurerm_public_ip.main.ip_address}"
}