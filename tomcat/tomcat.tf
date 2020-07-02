#Terraform template to provision a simple tomcat server

provider "vsphere" {
  allow_unverified_ssl = "true"
  version = "~>1.3"
}

data "vsphere_datacenter" "dc" {
  name = var.vsphere_datacenter
}

data "vsphere_resource_pool" "pool" {
  name          = var.vsphere_resource_pool
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_datastore" "datastore" {
  name          = var.vsphere_datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}


data "vsphere_network" "network" {
  name          = var.vsphere_network
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_virtual_machine" "vm" {
  name             = "terraform-test"
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id     = data.vsphere_datastore.datastore.id

  num_cpus = 2
  memory   = 1024
  guest_id = "centos8_64Guest"

  network_interface {
    network_id = data.vsphere_network.network.id
//    ipv4_address       = "10.195.35.208"
//    ipv4_netmask = "27"
  }

//  ipv4_gateway       = "10.195.35.193"

  disk {
    label = "disk0"
    size  = 20
  }
}

variable "vsphere_datacenter" {
  description = "vCenter name"
}

variable "vsphere_resource_pool" {
  description = "vCenter resource pool"
}

variable "vsphere_datastore" {
  description = "vCenter datastore"
}

variable "vsphere_network" {
  description = "vCenter network interface"
}
