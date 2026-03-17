# AGENTS.md

This file provides guidance for AI agents working on this repository.

## Project Overview

This repository automates deployment of NixOS to Oracle Cloud Free Tier (ARM A1.Flex instance) using GitHub Actions and Terraform.

## Key Files

- `flake.nix` - NixOS image build definition
- `nix-image/configuration.nix` - NixOS system configuration
- `.github/workflows/deploy.yml` - GitHub Actions workflow (build + deploy)
- `terraform/` - Terraform configuration for OCI

## Building

The NixOS image is built using the `oci-image` module:
```bash
nix build .#
```
Output: `result/nixos.qcow2`

## Testing Changes

1. Test build locally (requires ARM) or on GitHub Actions
2. Verify Terraform syntax: `cd terraform && terraform validate`
3. Test deployment to a test compartment first

## Adding Features

- To add NixOS packages: edit `nix-image/configuration.nix`
- To change instance shape: modify variables in workflow or terraform
- To add OCI resources: edit `terraform/main.tf`

## Known Issues

- Image import to OCI can take 30-45 minutes
- Shape compatibility must be registered for A1.Flex
- Image capabilities metadata required for ARM instances
