# Builds Open Source LAMP stack on OCI Classic IaaS.
# Includes 3 network zones: Management (Public), Application (Public), & Database (Private) - Role-specific instances are distributed across the zones.
#
# Note: Initial version created by: cameron.senese@oracle.com

### Environment ###
  provider "opc" {
    user                = "${var.ociUser}"
    password            = "${var.ociPass}"
    identity_domain     = "${var.idDomain}"
    endpoint            = "${var.apiEndpoint}"
  }
  resource "opc_compute_ssh_key" "ocsk-public-key1" {
    name                = "ocsk-public-key1"
    key                 = "${file(var.sshPublicKey)}"
    enabled             = true
  }

### Network ###
  ### Network :: IP Network ###
    ### Network :: IP Network :: Network Exchange ###
    resource "opc_compute_ip_network_exchange" "default" {
      name                = "net-xch1"
    }
    ### Network :: IP Network :: IP Networks ###
    resource "opc_compute_ip_network" "mgt" {
      name                = "mgt-internal-network"
      description         = "mgt-internal-network"
      ip_address_prefix   = "10.1.0.0/24"
      ip_network_exchange = "net-xch1"
      public_napt_enabled = false
    }
    resource "opc_compute_ip_network" "app" {
      name                = "app-internal-network"
      description         = "app-internal-network"
      ip_address_prefix   = "10.2.0.0/24"
      ip_network_exchange = "net-xch1"
      public_napt_enabled = false
    }
    resource "opc_compute_ip_network" "dbs" {
      name                = "dbs-internal-network"
      description         = "dbs-internal-network"
      ip_address_prefix   = "10.3.0.0/24"
      ip_network_exchange = "net-xch1"
      public_napt_enabled = false
    }
    ### Network :: IP Network :: vNIC Sets ###
    resource "opc_compute_vnic_set" "vns-mgt-public" {
      name         = "vns-mgt-public"
      description  = "vns-mgt-public"
      virtual_nics = ["mgt-internal"]
    }
    ### Network :: IP Network :: Routes ###
    resource "opc_compute_route" "rou-mgt-public" {
      name         = "rou-mgt-public"
      description  = "rou-mgt-public"
      admin_distance = 1
      ip_address_prefix = "0.0.0.0/0"
      next_hop_vnic_set = "vns-mgt-public"
    }
  ### Network :: Shared Network ###
    ### Network :: Shared Network :: IP Reservation ###
    resource "opc_compute_ip_reservation" "reservation-mgt1" {
      parent_pool         = "/oracle/public/ippool"
      name                = "mgt1-external"
      permanent           = true
    }
    resource "opc_compute_ip_reservation" "reservation-app1" {
      parent_pool         = "/oracle/public/ippool"
      name                = "app1-external"
      permanent           = true
    }
    ### Network :: Shared Network :: Security Lists ###
    # A security list is a group of Oracle Compute Cloud Service instances that you can specify as the source or destination in one or more security rules. The instances in a
    # security list can communicate fully, on all ports, with other instances in the same security list using their private IP addresses.
    ###
    resource "opc_compute_security_list" "mgt-sec-list1" {
      name                 = "mgt-sec-list1"
      policy               = "deny"
      outbound_cidr_policy = "permit"
    }
    resource "opc_compute_security_list" "app-sec-list1" {
      name                 = "app-sec-list1"
      policy               = "deny"
      outbound_cidr_policy = "permit"
    }
    ### Network :: Shared Network :: Security Rules ###
    # Security rules are essentially firewall rules, which you can use to permit traffic
    # between Oracle Compute Cloud Service instances in different security lists, as well as between instances and external hosts.
    ###
    resource "opc_compute_sec_rule" "mgt-sec-rule1" {
      name             = "mgt-sec-rule1"
      source_list      = "seciplist:${opc_compute_security_ip_list.sec-ip-list1.name}"
      destination_list = "seclist:${opc_compute_security_list.mgt-sec-list1.name}"
      action           = "permit"
      application      = "/oracle/public/ssh"
    }
    resource "opc_compute_sec_rule" "app-sec-rule1" {
      name             = "app-sec-rule1"
	    source_list      = "seciplist:${opc_compute_security_ip_list.sec-ip-list1.name}"
      destination_list = "seclist:${opc_compute_security_list.app-sec-list1.name}"
      action           = "permit"
      application      = "/oracle/public/http"
    }

    ### Network :: Shared Network :: Security IP Lists ###
    # A security IP list is a list of IP subnets (in the CIDR format) or IP addresses that are external to instances in Compute Classic.
    # You can use a security IP list as the source or the destination in security rules to control network access to or from Compute Classic instances.
    ###	
      resource "opc_compute_security_ip_list" "sec-ip-list1" {
      name        = "sec-ip-list1-inet"
      ip_entries = [ "0.0.0.0/0" ]
    }

### Storage ###
  ### Storage :: Management ###
  resource "opc_compute_storage_volume" "mgt-volume1" {
    size                = "12"
    description         = "mgt-volume1: bootable storage volume"
    name                = "mgt-volume1-boot"
    storage_type        = "/oracle/public/storage/latency"
    bootable            = true
    image_list          = "/oracle/public/OL_6.8_UEKR4_x86_64"
    image_list_entry    = 1
  }
  ### Storage :: Application ###
  resource "opc_compute_storage_volume" "app-volume1" {
    size                = "12"
    description         = "app-volume1: bootable storage volume"
    name                = "app-volume1-boot"
    storage_type        = "/oracle/public/storage/latency"
    bootable            = true
    image_list          = "/oracle/public/OL_6.8_UEKR4_x86_64"
    image_list_entry    = 1
  }
  ### Storage :: Database ###
  resource "opc_compute_storage_volume" "dbs-volume1" {
    size                = "12"
    description         = "dbs-volume1: bootable storage volume"
    name                = "dbs-volume1-boot"
    storage_type        = "/oracle/public/storage/latency"
    bootable            = true
    image_list          = "/oracle/public/OL_6.8_UEKR4_x86_64"
    image_list_entry    = 1
  }

### Compute ###
  ### Compute :: Management ###
  resource "opc_compute_instance" "mgt-instance1" {
    name                = "mgt-instance1"
    label               = "mgt-instance1"
    shape               = "oc3"
    hostname            = "mgt-bastion1"
    reverse_dns       = true
    storage {
      index             = 1
      volume            = "${opc_compute_storage_volume.mgt-volume1.name}"
    }
    networking_info {
      index             = 1
      shared_network    = true
      sec_lists         = ["${opc_compute_security_list.mgt-sec-list1.name}"]
      nat               = ["${opc_compute_ip_reservation.reservation-mgt1.name}"]
      dns               = ["mgt-bastion1"]
      name_servers      = ["8.8.8.8", "10.1.0.1"]
    }
    networking_info {
      index             = 0
  	  vnic              = "mgt-internal"
  	  ip_network        = "mgt-internal-network"
  	  ip_address        = "10.1.0.10"
      shared_network    = false
      dns               = ["mgt-bastion1"]
      name_servers      = ["8.8.8.8", "10.1.0.1"]
    }
    ssh_keys            = ["${opc_compute_ssh_key.ocsk-public-key1.name}"]
    boot_order          = [ 1 ]
  }
  ### Compute :: App ###
  resource "opc_compute_instance" "app-instance1" {
    name                = "app-instance1"
    label               = "app-instance1"
    shape               = "oc3"
    storage {
      index = 1
      volume            = "${opc_compute_storage_volume.app-volume1.name}"
    }
    networking_info {
      index             = 1
      shared_network    = true
      sec_lists         = ["${opc_compute_security_list.app-sec-list1.name}"]
      nat               = ["${opc_compute_ip_reservation.reservation-app1.name}"]
      dns               = ["app-instance1"]
      name_servers      = ["8.8.8.8", "10.2.0.1"]
    }
    networking_info {
      index             = 0
  	  vnic              = "app-internal"
  	  ip_network        = "app-internal-network"
  	  ip_address        = "10.2.0.10"
      shared_network    = false
      dns               = ["app-instance1"]
      name_servers      = ["8.8.8.8", "10.2.0.1"]
    }
    ssh_keys            = ["${opc_compute_ssh_key.ocsk-public-key1.name}"]
    boot_order          = [ 1 ]
  }
  ### Compute :: Dbs ###
  resource "opc_compute_instance" "dbs-instance1" {
    name                = "dbs-instance1"
    label               = "dbs-instance1"
    shape               = "oc3"
    storage {
      index = 1
      volume            = "${opc_compute_storage_volume.dbs-volume1.name}"
    }
    networking_info {
      index             = 0
  	  vnic              = "dbs-internal"
  	  ip_network        = "dbs-internal-network"
  	  ip_address        = "10.3.0.10"
      shared_network    = false
      dns               = ["dbs-instance1"]
      name_servers      = ["8.8.8.8", "10.3.0.1"]
    }
    ssh_keys            = ["${opc_compute_ssh_key.ocsk-public-key1.name}"]
    boot_order          = [ 1 ]
  }

### Null-Resources ###
  ### Null-Resources :: Management ###
  resource "null_resource" "mgt-instance1" {
      depends_on = ["opc_compute_instance.mgt-instance1"]
      provisioner "file" {
        connection {
          timeout = "30m"
          type = "ssh"
          host = "${opc_compute_ip_reservation.reservation-mgt1.ip}"
          user = "opc"
          private_key = "${file(var.sshPrivateKey)}"
        }
      source = "script/"
      destination = "/tmp/"
      }
      provisioner "remote-exec" {
        connection {
          timeout = "30m"
          type = "ssh"
          host = "${opc_compute_ip_reservation.reservation-mgt1.ip}"
          user = "opc"
          private_key = "${file(var.sshPrivateKey)}"
        }
        inline = [
          "chmod +x /tmp/mgt-script.sh",
          "sudo /tmp/mgt-script.sh args",
        ]
      }
  }
  ### Null-Resources :: Application ###
  resource "null_resource" "app-instance1" {
      depends_on = ["null_resource.mgt-instance1"]
      provisioner "file" {
        connection {
          timeout = "30m"
          type = "ssh"
          host = "${data.opc_compute_network_interface.app1.ip_address}"
          bastion_host = "${opc_compute_ip_reservation.reservation-mgt1.ip}"
          user = "opc"
          private_key = "${file(var.sshPrivateKey)}"
        }
      source = "script/"
      destination = "/tmp/"
      }
      provisioner "remote-exec" {
        connection {
          timeout = "30m"
          type = "ssh"
          host = "${data.opc_compute_network_interface.app1.ip_address}"
          bastion_host = "${opc_compute_ip_reservation.reservation-mgt1.ip}"
          user = "opc"
          private_key = "${file(var.sshPrivateKey)}"
        }
        inline = [
          "chmod +x /tmp/app-script.sh",
          "sudo /tmp/app-script.sh args",
        ]
      }
  }
  ### Null-Resources :: Database ###
  resource "null_resource" "dbs-instance1" {
      depends_on = ["null_resource.mgt-instance1"]
      provisioner "file" {
        connection {
          timeout = "30m"
          type = "ssh"
          host = "${data.opc_compute_network_interface.dbs1.ip_address}"
          bastion_host = "${opc_compute_ip_reservation.reservation-mgt1.ip}"
          user = "opc"
          private_key = "${file(var.sshPrivateKey)}"
        }
      source = "script/"
      destination = "/tmp/"
      }
      provisioner "remote-exec" {
        connection {
          timeout = "30m"
          type = "ssh"
          host = "${data.opc_compute_network_interface.dbs1.ip_address}"
          bastion_host = "${opc_compute_ip_reservation.reservation-mgt1.ip}"
          user = "opc"
          private_key = "${file(var.sshPrivateKey)}"
        }
        inline = [
          "chmod +x /tmp/dbs-script.sh",
          "sudo /tmp/dbs-script.sh args",
        ]
      }
  }

### Output ###
  output "Management_Instance_Public_IPs" {
    value = ["${opc_compute_ip_reservation.reservation-mgt1.ip}"]
  }
  
  output "Application_Instance_Public_IPs" {
    value = ["${opc_compute_ip_reservation.reservation-app1.ip}"]
  }
  
  data "opc_compute_network_interface" "app1" {
    instance_id   = "${opc_compute_instance.app-instance1.id}"
    instance_name = "${opc_compute_instance.app-instance1.name}"
    interface     = "eth0"
  }
    output "Application_Instance_Private_IPs" {
      value = ["${data.opc_compute_network_interface.app1.ip_address}"]
    }

  data "opc_compute_network_interface" "dbs1" {
    instance_id   = "${opc_compute_instance.dbs-instance1.id}"
    instance_name = "${opc_compute_instance.dbs-instance1.name}"
    interface     = "eth0"
  }
    output "Database_Instance_Private_IPs" {
      value = ["${data.opc_compute_network_interface.dbs1.ip_address}"]
    }
