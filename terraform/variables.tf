variable "tenancy_ocid" {
  description = "Oracle Cloud Tenancy OCID"
  type        = string
  sensitive   = true
}

variable "compartment_ocid" {
  description = "Compartment OCID (defaults to tenancy_ocid if empty)"
  type        = string
  default     = ""
}

variable "region" {
  description = "Oracle Cloud Region (e.g., eu-zurich-1)"
  type        = string
  default     = "eu-zurich-1"
}

variable "bucket_name" {
  description = "Object Storage Bucket Name for NixOS image"
  type        = string
  default     = "nixos-images"
}

variable "subnet_id" {
  description = "OCID of existing subnet to deploy to (optional, creates new VCN/subnet if empty)"
  type        = string
  default     = "ocid1.subnet.oc1.eu-zurich-1.aaaaaaaahizsa2itiriwt2if65b22i2bls2ukbpxdd6ir7hyjtll5hynn6aa"
}

variable "image_source" {
  description = "Path to the NixOS qcow2 image"
  type        = string
  default     = "./nixos-aarch64.qcow2"
}

variable "ocpus" {
  description = "Number of OCPUs (1-4 for free tier)"
  type        = number
  default     = 4
}

variable "memory_in_gbs" {
  description = "Memory in GB (6-24 for free tier A1.Flex)"
  type        = number
  default     = 24
}

variable "ssh_public_key" {
  description = "SSH public key for instance access"
  type        = string
}

variable "cloud_init_user_data" {
  description = "Cloud-init user data (optional)"
  type        = string
  default     = ""
}

variable "vcn_id" {
  description = "VCN OCID (for importing existing resources)"
  type        = string
  default     = "ocid1.vcn.oc1.eu-zurich-1.amaaaaaalg3cyzqaecpmbsxeadjkr2vtqasa46fyzfezexkeltuaiq7wnoba"
}

variable "ig_id" {
  description = "Internet Gateway OCID (for importing existing resources)"
  type        = string
  default     = "ocid1.internetgateway.oc1.eu-zurich-1.aaaaaaaagieirwccytkpwsynqfrdb5kg3wxdo4hle5uacbebjs7u2hoyjsja"
}

variable "rt_id" {
  description = "Route Table OCID (for importing existing resources)"
  type        = string
  default     = "ocid1.routetable.oc1.eu-zurich-1.aaaaaaaaq3yfcyyaqwl4dg5yhezzawoovhqbxyzykwrxtjojfcrrplnw4uaa"
}

variable "sl_id" {
  description = "Security List OCID (for importing existing resources)"
  type        = string
  default     = "ocid1.securitylist.oc1.eu-zurich-1.aaaaaaaagcin5m6qm5kohapsn574c4r7f2utzadvrtabqrb3ujngaringkwq"
}

variable "image_id" {
  description = "Image OCID (for importing existing resources)"
  type        = string
  default     = ""
}

variable "instance_id" {
  description = "Instance OCID (for importing existing resources)"
  type        = string
  default     = ""
}
