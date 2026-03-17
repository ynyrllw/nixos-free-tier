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
