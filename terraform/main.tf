terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 6.0"
    }
  }
  
  backend "s3" {
    endpoint                    = "https://objectstorage.${var.region}.oraclecloud.com"
    region                      = var.region
    bucket                      = var.bucket_name
    key                         = "terraform/state"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id = true
  }
}

provider "oci" {
  region           = var.region
  tenancy_ocid     = var.tenancy_ocid
  user_ocid       = var.user_ocid
  fingerprint     = var.fingerprint
  private_key_path = var.private_key_path
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

data "oci_identity_tenancy" "this" {
  tenancy_id = var.tenancy_ocid
}

data "oci_objectstorage_namespace" "this" {
  compartment_id = var.tenancy_ocid
}

resource "oci_objectstorage_bucket" "nixos_bucket" {
  compartment_id = var.tenancy_ocid
  namespace      = data.oci_objectstorage_namespace.this.namespace
  name           = var.bucket_name
}

data "oci_objectstorage_bucket" "nixos_bucket" {
  namespace = data.oci_objectstorage_namespace.this.namespace
  name      = oci_objectstorage_bucket.nixos_bucket.name
}

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_ocid != "" ? var.compartment_ocid : var.tenancy_ocid
}

resource "oci_core_vcn" "nixos" {
  compartment_id = var.compartment_ocid != "" ? var.compartment_ocid : var.tenancy_ocid
  display_name   = "nixos-vcn"
  cidr_blocks     = ["10.0.0.0/16"]
}

resource "oci_core_internet_gateway" "nixos" {
  compartment_id = var.compartment_ocid != "" ? var.compartment_ocid : var.tenancy_ocid
  display_name   = "nixos-ig"
  vcn_id         = oci_core_vcn.nixos.id
}

resource "oci_core_route_table" "nixos" {
  compartment_id = var.compartment_ocid != "" ? var.compartment_ocid : var.tenancy_ocid
  display_name   = "nixos-rt"
  vcn_id         = oci_core_vcn.nixos.id

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.nixos.id
  }
}

resource "oci_core_security_list" "nixos" {
  compartment_id = var.compartment_ocid != "" ? var.compartment_ocid : var.tenancy_ocid
  display_name   = "nixos-sg"
  vcn_id         = oci_core_vcn.nixos.id

  egress_security_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    protocol          = "all"
  }

  ingress_security_rules {
    protocol  = "all"
    source    = "0.0.0.0/0"
  }
}

resource "oci_core_subnet" "nixos" {
  compartment_id     = var.compartment_ocid != "" ? var.compartment_ocid : var.tenancy_ocid
  vcn_id              = oci_core_vcn.nixos.id
  display_name        = "nixos-subnet"
  cidr_block          = "10.0.1.0/24"
  route_table_id      = oci_core_route_table.nixos.id
  security_list_ids   = [oci_core_security_list.nixos.id]
  prohibit_public_ip_on_vnic = false
}

data "oci_core_subnet" "public" {
  subnet_id = var.subnet_id != "" ? var.subnet_id : oci_core_subnet.nixos.id
}

resource "oci_objectstorage_object" "nixos_image" {
  bucket    = data.oci_objectstorage_bucket.nixos_bucket.name
  namespace = data.oci_objectstorage_namespace.this.namespace
  object    = "nixos-aarch64.qcow2"
  source    = var.image_source
}

resource "oci_core_image" "nixos" {
  compartment_id = var.compartment_ocid != "" ? var.compartment_ocid : var.tenancy_ocid
  display_name   = "NixOS ARM64"

  image_source_details {
    source_type     = "objectStorageTuple"
    namespace_name  = data.oci_objectstorage_namespace.this.namespace
    bucket_name     = data.oci_objectstorage_bucket.nixos_bucket.name
    object_name     = oci_objectstorage_object.nixos_image.object
  }

  launch_mode = "PARAVIRTUALIZED"

  timeouts {
    create = "60m"
  }
}

resource "oci_core_shape_management" "nixos_a1_compat" {
  compartment_id = var.compartment_ocid != "" ? var.compartment_ocid : var.tenancy_ocid
  image_id       = oci_core_image.nixos.id
  shape_name     = "VM.Standard.A1.Flex"

  depends_on = [oci_core_image.nixos]
}

resource "oci_core_compute_image_capability_schema" "nixos_caps" {
  compartment_id                      = var.compartment_ocid != "" ? var.compartment_ocid : var.tenancy_ocid
  image_id                            = oci_core_image.nixos.id
  compute_global_image_capability_schema_version_name = "2024-03-27"

  schema_data = {
    "Compute.Firmware" = jsonencode({
      descriptorType = "enumstring"
      source         = "IMAGE"
      defaultValue   = "UEFI_64"
      values         = ["UEFI_64"]
    })

    "Compute.LaunchMode" = jsonencode({
      descriptorType = "enumstring"
      source         = "IMAGE"
      defaultValue   = "PARAVIRTUALIZED"
      values         = ["PARAVIRTUALIZED", "EMULATED", "CUSTOM", "NATIVE"]
    })

    "Storage.BootVolumeType" = jsonencode({
      descriptorType = "enumstring"
      source         = "IMAGE"
      defaultValue   = "PARAVIRTUALIZED"
      values         = ["PARAVIRTUALIZED", "ISCSI", "SCSI", "IDE", "NVME"]
    })

    "Network.AttachmentType" = jsonencode({
      descriptorType = "enumstring"
      source         = "IMAGE"
      defaultValue   = "PARAVIRTUALIZED"
      values         = ["PARAVIRTUALIZED", "E1000", "VFIO", "VDPA"]
    })
  }

  depends_on = [oci_core_image.nixos]
}

resource "oci_core_instance" "nixos" {
  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  shape               = "VM.Standard.A1.Flex"

  shape_config {
    memory_in_gbs = var.memory_in_gbs
    ocpus         = var.ocpus
  }

  source_details {
    source_type             = "image"
    source_id               = oci_core_image.nixos.id
    boot_volume_vpus_per_gb = 10
  }

  create_vnic_details {
    subnet_id        = data.oci_core_subnet.public.id
    assign_public_ip = true
  }

  launch_options {
    network_type     = "PARAVIRTUALIZED"
    boot_volume_type  = "PARAVIRTUALIZED"
  }

  depends_on = [
    oci_core_shape_management.nixos_a1_compat,
    oci_core_compute_image_capability_schema.nixos_caps
  ]

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data = base64encode(var.cloud_init_user_data != "" ? var.cloud_init_user_data : <<-EOF
#cloud-config
users:
  - name: nixos
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh-authorized-keys:
      - ${var.ssh_public_key}
EOF
)
  }
}
