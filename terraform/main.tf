terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 6.0"
    }
  }
}

provider "oci" {
  region = var.region != "" ? var.region : data.oci_identity_regions.home_region.regions[0].name
}

data "oci_identity_tenancy" "this" {
  tenancy_id = var.tenancy_ocid
}

data "oci_identity_regions" "home_region" {
  filter {
    name   = "key"
    values = [data.oci_identity_tenancy.this.home_region_key]
  }
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

data "oci_core_subnets" "all" {
  compartment_id = var.compartment_ocid != "" ? var.compartment_ocid : var.tenancy_ocid
}

locals {
  subnet_id = var.subnet_id != "" ? var.subnet_id : (
    length([for s in data.oci_core_subnets.all.subnets : s.id if s.prohibit_public_ip_on_vnic == false]) > 0 
    ? [for s in data.oci_core_subnets.all.subnets : s.id if s.prohibit_public_ip_on_vnic == false][0] 
    : null
  )
}

data "oci_core_subnet" "public" {
  subnet_id = var.subnet_id != "" ? var.subnet_id : local.subnet_id
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
  compartment_id                      = var.compartment_ocid
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

output "instance_ip" {
  value = oci_core_instance.nixos.public_ip
}

output "instance_id" {
  value = oci_core_instance.nixos.id
}

output "image_id" {
  value = oci_core_image.nixos.id
}
