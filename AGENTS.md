# AGENTS.md

This file provides guidance for AI agents working on this repository.

## Project Overview

This repository automates deployment of NixOS to Oracle Cloud Free Tier (ARM A1.Flex instance) using GitHub Actions and Terraform.

## Design Philosophy

**Goal: One-click button deployment to free tier**

The repository is designed to minimize user friction. Users should be able to:
1. Fork the repo
2. Add 2 required variables (TENANCY_OCID, SSH_PUBLIC_KEY)
3. Click deploy
4. Apply their own NixOS flake after deployment

### Why Pre-built Images?

GitHub's free ARM runners don't support building custom NixOS ARM images (no KVM). Using pre-built images from nix-community solves this. Users apply their own config post-deploy via `nixos-rebuild switch`.

### Variable Philosophy

- **Required variables**: Only what cannot be auto-detected or has no sensible default
  - `TENANCY_OCID` - Required to authenticate with OCI
  - `SSH_PUBLIC_KEY` - User needs to provide their key for access

- **Auto-detected variables**: Fetched from OCI API when not provided
  - `REGION` - Auto-detected from tenancy's home region
  - `SUBNET_ID` - Auto-detected (first public subnet found)
  - `COMPARTMENT_OCID` - Defaults to tenancy_ocid
  - `NAMESPACE` - Auto-detected from Object Storage API

- **Optional variables with defaults**: Can be customized but work out of the box
  - `ocpus` - Defaults to 4 (max free tier)
  - `memory_in_gbs` - Defaults to 24 (max free tier)
  - `bucket_name` - Defaults to "nixos-images"

When adding new features or variables, prioritize this philosophy:
- If something can be auto-detected, auto-detect it
- If something has a sensible default, provide one
- Only require what is truly necessary

## Key Files

- `.github/workflows/deploy.yml` - GitHub Actions workflow (downloads pre-built image + deploy)
- `terraform/` - Terraform configuration for OCI

## How It Works

1. Downloads pre-built NixOS ARM image from nix-community releases
2. Terraform uploads and imports the image to OCI
3. Deploys an ARM VM using the imported image
4. User SSHes in and applies their own flake via `nixos-rebuild switch`

## Testing Changes

1. Run the GitHub Actions workflow
2. Verify Terraform syntax: `cd terraform && terraform validate`
3. Test deployment to a test compartment first

## Keeping Docs in Sync

When making changes to variables or workflow, always update:
- `README.md` - User-facing instructions
- `terraform/terraform.tfvars.example` - Local development reference
- Other workflow files if applicable

Check for hardcoded values that should be synced:
- Default region values
- Variable names
- Required vs optional variables

## Terraform State Management

**Always use the OCI native backend** for Terraform state (Terraform >= 1.12.0):
```hcl
terraform {
  backend "oci" {
    bucket = "terraform-state"
    key    = "nixos-deploy/terraform.tfstate"
  }
}
```

Do NOT use the deprecated S3-compatible backend. See Oracle docs: https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/terraform.htm#Using_Object_Storage_for_State_Files

## OCI Provider Usage

When working with OCI Terraform resources:
- Always check the official provider docs at https://registry.terraform.io/providers/oracle/oci/latest/docs
- Many data sources (like oci_core_vcn, oci_core_subnet) don't require compartment_id - it comes from the provider config
- Use import blocks carefully with count - they don't work together
- Test with `terraform validate` before committing

## Managing Existing OCI Resources

### Prerequisites

1. Install OCI CLI:
   ```bash
   bash -c "$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)" -- --accept-all-defaults --install-dir ~/.local/oci-cli
   ```

2. Configure OCI credentials (create `~/.oci/config`):
   ```
   [DEFAULT]
   user=ocid1.user.oc1..aaaaaaa...
   fingerprint=...
   tenancy=ocid1.tenancy.oc1..aaaaaaa...
   region=eu-zurich-1
   key_file=/path/to/private-key.pem
   ```

### Finding Existing Resource IDs

List all resources in the tenancy:
```bash
# Compute instances
oci compute instance list --compartment-id <tenancy_ocid>

# VCNs
oci network vcn list --compartment-id <tenancy_ocid>

# Images
oci compute image list --compartment-id <tenancy_ocid>

# Buckets
oci os bucket list --compartment-id <tenancy_ocid>
```

### Importing Existing Resources into Terraform

1. Find the resource OCIDs from OCI console or CLI
2. Add/update the OCID as a default in `variables.tf`
3. Add import blocks in `main.tf`:
   ```hcl
   import {
     to = oci_core_vcn.nixos
     id = var.vcn_id
   }
   ```
4. Run: `tofu init` then `tofu plan`

### Deleting Resources

#### Via Console (Recommended for VCNs with dependencies)
1. Go to Networking → Virtual Cloud Networks
2. Select the VCN and click Delete (this removes subnet, IG, route table, security list)

#### Via CLI
```bash
# Delete compute instances
oci compute instance terminate --instance-id <instance_ocid> --preserve-boot-volume false --force

# Delete custom images
oci compute image delete --image-id <image_ocid> --force

# Delete buckets (must delete objects first)
oci os object delete --bucket-name <bucket> --object-name <object> --force
oci os bucket delete --name <bucket> --force

# Delete VCNs and components
oci network subnet delete --subnet-id <subnet_ocid> --force
oci network internet-gateway delete --ig-id <ig_ocid> --force
oci network vcn delete --vcn-id <vcn_ocid> --force
```

Note: Deleting VCNs requires first deleting subnets, internet gateways, and route tables that reference them.

### Troubleshooting "Out of Host Capacity"

If ARM instance creation fails with capacity errors:
1. Upgrade to Pay As You Go for priority capacity access
2. Set up $0 budget alert in Billing → Budgets to avoid charges
3. The free tier allows 4 OCPUs / 24GB RAM (3000 OCPU hours/month) - running continuously stays under limit
