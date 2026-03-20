terraform {
  required_version = ">= 1.12.0"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 7.0.0"
    }
  }
}

provider "oci" {
  region           = var.region
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
}

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

data "oci_core_images" "ubuntu" {
  compartment_id           = var.tenancy_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "24.04"
  shape                    = "VM.Standard.A1.Flex"

  sort_by    = "TIMECREATED"
  sort_order = "DESC"

  filter {
    name   = "limit"
    values = ["1"]
  }
}

resource "oci_core_vcn" "nixos" {
  compartment_id = var.tenancy_ocid
  display_name   = "nixos-vcn"
  cidr_blocks    = ["10.0.0.0/16"]
}

resource "oci_core_internet_gateway" "nixos" {
  compartment_id = var.tenancy_ocid
  vcn_id         = oci_core_vcn.nixos.id
  display_name   = "nixos-ig"
}

resource "oci_core_route_table" "nixos" {
  compartment_id = var.tenancy_ocid
  vcn_id         = oci_core_vcn.nixos.id
  display_name   = "nixos-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.nixos.id
  }
}

resource "oci_core_security_list" "nixos" {
  compartment_id = var.tenancy_ocid
  vcn_id         = oci_core_vcn.nixos.id
  display_name   = "nixos-sg"

  egress_security_rules {
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
  }

  ingress_security_rules {
    protocol = "all"
    source   = "0.0.0.0/0"
  }
}

resource "oci_core_subnet" "nixos" {
  compartment_id             = var.tenancy_ocid
  vcn_id                     = oci_core_vcn.nixos.id
  display_name               = "nixos-subnet"
  cidr_block                 = "10.0.0.0/24"
  route_table_id             = oci_core_route_table.nixos.id
  security_list_ids          = [oci_core_security_list.nixos.id]
  prohibit_public_ip_on_vnic = false
}

resource "oci_core_instance" "nixos" {
  compartment_id      = var.tenancy_ocid
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  shape               = "VM.Standard.A1.Flex"

  shape_config {
    memory_in_gbs = var.memory_in_gbs
    ocpus         = var.ocpus
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.ubuntu.images[0].id
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.nixos.id
    assign_public_ip = true
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
  }
}

module "deploy" {
  source = "github.com/nix-community/nixos-anywhere//terraform/all-in-one"

  target_host = oci_core_instance.nixos.public_ip
  instance_id = oci_core_instance.nixos.id

  install_ssh_key = var.ssh_public_key

  nixos_system_attr      = ".#nixosConfigurations.nixos.config.system.build.toplevel"
  nixos_partitioner_attr = ".#nixosConfigurations.nixos.config.system.build.diskoNoDeps"

  special_args = {
    target_ip = oci_core_instance.nixos.public_ip
  }
}

output "instance_ip" {
  value = oci_core_instance.nixos.public_ip
}
