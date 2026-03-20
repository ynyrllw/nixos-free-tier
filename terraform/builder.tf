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

variable "tenancy_ocid" {
  description = "OCI Tenancy OCID"
  type        = string
}

variable "user_ocid" {
  description = "OCI User OCID"
  type        = string
}

variable "fingerprint" {
  description = "API Key Fingerprint"
  type        = string
}

variable "private_key_path" {
  description = "Path to private key"
  type        = string
  default     = "/tmp/oci_private_key"
}

variable "compartment_ocid" {
  description = "Compartment OCID"
  type        = string
  default     = ""
}

variable "region" {
  description = "OCI Region"
  type        = string
  default     = "eu-zurich-1"
}

variable "bucket_name" {
  description = "Object Storage Bucket Name"
  type        = string
  default     = "nixos-builder"
}

variable "ocpus" {
  description = "Number of OCPUs"
  type        = number
  default     = 4
}

variable "memory_in_gbs" {
  description = "Memory in GB"
  type        = number
  default     = 24
}

variable "ssh_public_key" {
  description = "SSH public key for access"
  type        = string
}

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

data "oci_objectstorage_namespace" "this" {
  compartment_id = var.tenancy_ocid
}

resource "oci_core_vcn" "builder" {
  compartment_id = var.tenancy_ocid
  display_name   = "nixos-builder-vcn"
  cidr_blocks    = ["10.1.0.0/16"]
}

resource "oci_core_internet_gateway" "builder" {
  compartment_id = var.tenancy_ocid
  vcn_id         = oci_core_vcn.builder.id
  display_name   = "nixos-builder-ig"
}

resource "oci_core_route_table" "builder" {
  compartment_id = var.tenancy_ocid
  vcn_id         = oci_core_vcn.builder.id
  display_name   = "nixos-builder-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.builder.id
  }
}

resource "oci_core_security_list" "builder" {
  compartment_id = var.tenancy_ocid
  vcn_id         = oci_core_vcn.builder.id
  display_name   = "nixos-builder-sg"

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

resource "oci_core_subnet" "builder" {
  compartment_id             = var.tenancy_ocid
  vcn_id                     = oci_core_vcn.builder.id
  display_name               = "nixos-builder-subnet"
  cidr_block                 = "10.1.0.0/24"
  route_table_id             = oci_core_route_table.builder.id
  security_list_ids          = [oci_core_security_list.builder.id]
  prohibit_public_ip_on_vnic = false
}

data "oci_core_images" "centos" {
  compartment_id           = var.tenancy_ocid
  operating_system         = "Oracle Linux"
  operating_system_version = "9"
  shape                    = "VM.Standard.A1.Flex"

  sort_by    = "TIMECREATED"
  sort_order = "DESC"

  filter {
    name   = "limit"
    values = ["1"]
  }
}

resource "oci_core_instance" "builder" {
  compartment_id      = var.tenancy_ocid
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  shape               = "VM.Standard.A1.Flex"

  shape_config {
    memory_in_gbs = var.memory_in_gbs
    ocpus         = var.ocpus
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.centos.images[0].id
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.builder.id
    assign_public_ip = true
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
  }
}

output "builder_instance_ip" {
  value = oci_core_instance.builder.public_ip
}

output "builder_private_ip" {
  value = oci_core_instance.builder.private_ip
}
