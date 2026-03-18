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
  description = "Object Storage Bucket Name for NixOS image and state"
  type        = string
  default     = "nixos-images"
}

variable "subnet_id" {
  description = "OCID of existing subnet to deploy to (optional, creates new VCN/subnet if empty)"
  type        = string
  default     = ""
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
