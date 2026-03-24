terraform {
  required_version = ">= 1.12.0"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 7.0.0"
    }
  }

  backend "oci" {
    bucket    = "terraform-state"
    namespace = "zr4kpvluldho"
    key       = "nixos-deploy/terraform.tfstate"
    region    = "eu-zurich-1"
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

locals {
  use_existing_vcn = var.vcn_id != ""
  ubuntu_image_id  = "ocid1.image.oc1.eu-zurich-1.aaaaaaaagt4fin33bgwrmpianub6pdwog5g27fxyg3vwwwztwidvc2g4knqa"
}

data "oci_core_vcn" "existing" {
  count  = local.use_existing_vcn ? 1 : 0
  vcn_id = var.vcn_id
}

data "oci_core_subnet" "existing" {
  count     = local.use_existing_vcn ? 1 : 0
  subnet_id = var.subnet_id
}

resource "oci_core_vcn" "nixos" {
  count          = local.use_existing_vcn ? 0 : 1
  compartment_id = var.tenancy_ocid
  display_name   = "nixos-vcn"
  cidr_blocks    = ["10.0.0.0/16"]
}

resource "oci_core_internet_gateway" "nixos" {
  count          = local.use_existing_vcn ? 0 : 1
  compartment_id = var.tenancy_ocid
  vcn_id         = oci_core_vcn.nixos[0].id
  display_name   = "nixos-ig"
}

resource "oci_core_route_table" "nixos" {
  count          = local.use_existing_vcn ? 0 : 1
  compartment_id = var.tenancy_ocid
  vcn_id         = oci_core_vcn.nixos[0].id
  display_name   = "nixos-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.nixos[0].id
  }
}

resource "oci_core_security_list" "nixos" {
  count          = local.use_existing_vcn ? 0 : 1
  compartment_id = var.tenancy_ocid
  vcn_id         = oci_core_vcn.nixos[0].id
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
  count                      = local.use_existing_vcn ? 0 : 1
  compartment_id             = var.tenancy_ocid
  vcn_id                     = oci_core_vcn.nixos[0].id
  display_name               = "nixos-subnet"
  cidr_block                 = "10.0.0.0/24"
  route_table_id             = oci_core_route_table.nixos[0].id
  security_list_ids          = [oci_core_security_list.nixos[0].id]
  prohibit_public_ip_on_vnic = false
}

locals {
  vcn_id    = local.use_existing_vcn ? var.vcn_id : oci_core_vcn.nixos[0].id
  subnet_id = local.use_existing_vcn ? var.subnet_id : oci_core_subnet.nixos[0].id
}

resource "oci_core_instance" "nixos" {
  count               = var.instance_id != "" ? 0 : 1
  compartment_id      = var.tenancy_ocid
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  shape               = "VM.Standard.A1.Flex"

  shape_config {
    memory_in_gbs = var.memory_in_gbs
    ocpus         = var.ocpus
  }

  source_details {
    source_type = "image"
    source_id   = var.image_id != "" ? var.image_id : local.ubuntu_image_id
  }

  create_vnic_details {
    subnet_id        = local.subnet_id
    assign_public_ip = true
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
  }
}

output "instance_ip" {
  value = oci_core_instance.nixos[0].public_ip
}