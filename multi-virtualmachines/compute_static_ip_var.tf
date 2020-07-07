#=============================================
# vCenter connection
#=============================================
variable "vsphere_server"{
  type = string
}
variable "vsphere_user"{
  type = string
}
variable "vsphere_password"{
  type = string
}

#=============================================
# vSphere virtual machine Configuration
#=============================================
variable "vm" {
  type = list(object({
    vsphere_datacenter = string
    vsphere_cluster = string
    vm_folder = string
    vm_name = string
    vm_template = string
    vm_cpu = number
    vm_ram = number
    vm_datastore_cluster = string
    epg = string
    vm_ip = string
    vm_netmask = number
    vm_gateway = string
    vm_dns = string
    vm_domain = string
    vm_linked_clone = bool
    vm_data_disk = number
  }))
}