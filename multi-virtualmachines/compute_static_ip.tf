provider "vsphere" {
  user           = var.vsphere_user
  password       = var.vsphere_password
  vsphere_server = var.vsphere_server
  allow_unverified_ssl = true
}

#===============================================================================
# vSphere Data
#===============================================================================

data "vsphere_datacenter" "dc" {
  count = length(var.vm)
  name = var.vm[count.index].vsphere_datacenter
}

data "vsphere_datacenter" "pudc" {
  name = "PUDC (PROD)"
}

data "vsphere_virtual_machine" "template" {
  count = length(var.vm)
  name          = var.vm[count.index].vm_template
  datacenter_id = data.vsphere_datacenter.pudc.id
}

data "vsphere_compute_cluster" "cluster" {
  count = length(var.vm)
  name          = var.vm[count.index].vsphere_cluster
  datacenter_id = data.vsphere_datacenter.dc[count.index].id
}

data "vsphere_datastore_cluster" "datastore_cluster" {
  count = length(var.vm)
  name          = var.vm[count.index].vm_datastore_cluster
  datacenter_id = data.vsphere_datacenter.dc[count.index].id
}

data "vsphere_network" "network" {
  count = length(var.vm)
  name = var.vm[count.index].epg
  datacenter_id = data.vsphere_datacenter.dc[count.index].id
}

locals {
  vm_folder_list = distinct(var.vm.*.vm_folder)
}

locals {
  vm_datacenter_list = distinct(var.vm.*.vsphere_datacenter)
}

resource "vsphere_folder" "folder" {
  count = length(local.vm_datacenter_list)
  path          = local.vm_folder_list[count.index]
  type          = "vm"
  datacenter_id = data.vsphere_datacenter.dc[count.index].id
}

resource "vsphere_virtual_machine" "VMs" {
  count = length(var.vm)
  name             = var.vm[count.index].vm_name
  resource_pool_id = data.vsphere_compute_cluster.cluster[count.index].resource_pool_id
  datastore_cluster_id      = data.vsphere_datastore_cluster.datastore_cluster[count.index].id
  folder = var.vm[count.index].vm_folder
  num_cpus = var.vm[count.index].vm_cpu
  cpu_hot_add_enabled = true
  memory   = var.vm[count.index].vm_ram
  memory_hot_add_enabled = true
  guest_id = data.vsphere_virtual_machine.template[count.index].guest_id
  scsi_type = data.vsphere_virtual_machine.template[count.index].scsi_type

  network_interface {
    network_id   = data.vsphere_network.network[count.index].id
    adapter_type = data.vsphere_virtual_machine.template[count.index].network_interface_types[0]
  }

  disk {
    label            = "${var.vm[count.index].vm_name}.vmdk"
    size             = data.vsphere_virtual_machine.template[count.index].disks.0.size
    eagerly_scrub    = data.vsphere_virtual_machine.template[count.index].disks.0.eagerly_scrub
    thin_provisioned = data.vsphere_virtual_machine.template[count.index].disks.0.thin_provisioned
  }

  disk {
    label            = "${var.vm[count.index].vm_name}_2.vmdk"
    size             = var.vm[count.index].vm_data_disk
    eagerly_scrub    = data.vsphere_virtual_machine.template[count.index].disks.0.eagerly_scrub
    thin_provisioned = data.vsphere_virtual_machine.template[count.index].disks.0.thin_provisioned
    unit_number = 1
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template[count.index].id
    customize {
      timeout = "20"
      dynamic "linux_options" {
        for_each = range(var.vm[count.index].vm_template == "_CENTOS7" ? 1 : 0)
        content {
          host_name = var.vm[count.index].vm_name
          domain    = var.vm[count.index].vm_domain
        }
      }
      dynamic "windows_options" {
        for_each = range(var.vm[count.index].vm_template == "_CENTOS7" ? 0 : 1)
        content {
          computer_name  = var.vm[count.index].vm_name
          admin_password = "terraform"
        }
      }
      network_interface {
        ipv4_address = var.vm[count.index].vm_ip
        ipv4_netmask = var.vm[count.index].vm_netmask
      }
      ipv4_gateway = var.vm[count.index].vm_gateway
    }
  }
  depends_on = [
    vsphere_folder.folder
  ]
}
