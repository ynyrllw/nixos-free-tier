variable "tenancy_ocid" {
  description = "Oracle Cloud Tenancy OCID"
  type        = string
  sensitive   = true
}

variable "user_ocid" {
  description = "OCI User OCID"
  type        = string
  sensitive   = true
}

variable "fingerprint" {
  description = "API Key Fingerprint"
  type        = string
  sensitive   = true
}

variable "private_key_path" {
  description = "Path to private key"
  type        = string
  default     = "~/.oci/oci_api_key.pem"
}

variable "region" {
  description = "Oracle Cloud Region (e.g., eu-zurich-1)"
  type        = string
  default     = "eu-zurich-1"
}

variable "subnet_id" {
  description = "OCID of existing subnet to deploy to (optional, creates new VCN/subnet if empty)"
  type        = string
  default     = ""
}

variable "vcn_id" {
  description = "VCN OCID (optional, creates new VCN if empty)"
  type        = string
  default     = ""
}

variable "ocpus" {
  description = "Number of OCPUs (1-2 for free tier)"
  type        = number
  default     = 2
}

variable "memory_in_gbs" {
  description = "Memory in GB (6-12 for free tier A1.Flex)"
  type        = number
  default     = 12
}

variable "ssh_public_key" {
  description = "SSH public key for instance access"
  type        = string
}

variable "nix_channel" {
  description = "NixOS channel to use (e.g., nixos-25.11, nixos-unstable)"
  type        = string
  default     = "nixos-25.11"
}

variable "ssh_private_key" {
  description = "SSH private key content for nixos-infect to add to authorized_keys"
  type        = string
  default     = ""
}
