# NixOS on Oracle Cloud Free Tier

Automated deployment of NixOS on Oracle Cloud Infrastructure (OCI) ARM free tier using Terraform and GitHub Actions.

[![Build and Deploy](https://github.com/yourusername/nixos-oracle-free-tier/actions/workflows/deploy.yml/badge.svg)](https://github.com/yourusername/nixos-oracle-free-tier/actions/workflows/deploy.yml)

## Overview

This repo provides a fully automated way to deploy NixOS on Oracle Cloud's free tier ARM VM (4 OCPUs, 24GB RAM).

Based on [Erik Parawell's guide](https://erikparawell.com/oracle-cloud-nixos.html) - the automated Terraform approach.

## Features

- **Free**: Runs on Oracle Cloud Always Free tier
- **Automated**: Build and deploy from GitHub Actions
- **ARM64**: Uses Oracle's free A1.Flex ARM instance (4 OCPUs, 24GB RAM)
- **NixOS**: Modern declarative Linux distribution

## Quick Start (1-Click Deploy)

### Step 1: Sign up for Oracle Cloud

Create a free account at [Oracle Cloud Free Tier](https://signup.cloud.oracle.com/?sourceType=_ref_coc-asset-opcSignIn&language=en_US).

### Step 2: Fork this repository

Click "Use this template" above to create your own copy.

### Step 3: Get your OCI values

- **TENANCY_OCID**: Oracle Cloud Console → Profile (top right) → Tenancy: `<your-tenancy>`
- **COMPARTMENT_OCID**: Usually the same as tenancy or create a new compartment
- **REGION**: Your home region (e.g., `eu-zurich-1`)
- **SUBNET_ID**: Networking → Virtual Cloud Networks → Your VCN → Subnets → Copy a public subnet OCID
- **SSH_PUBLIC_KEY**: Contents of `~/.ssh/id_ed25519.pub` (or create one with `ssh-keygen`)

### Step 4: Configure Oracle Cloud variables

In your forked repo, go to **Settings → Variables → Actions** and add:

| Variable | Description | Example |
|--------|-------------|---------|
| `TENANCY_OCID` | Oracle Cloud Tenancy OCID | `ocid1.tenancy.oc1..aaa...` |
| `COMPARTMENT_OCID` | Compartment OCID | `ocid1.compartment.oc1..aaa...` |
| `REGION` | OCI Region | `eu-zurich-1` |
| `SUBNET_ID` | Public Subnet OCID | `ocid1.subnet.oc1..aaa...` |
| `SSH_PUBLIC_KEY` | Your SSH public key | `ssh-ed25519 AAAA...` |

### Step 5: Deploy!

Go to **Actions → Build and Deploy NixOS to Oracle Cloud → Run workflow**

Click "Run workflow" - the build will take ~15-20 minutes, then Terraform will deploy your VM.

### Step 6: Connect

After deployment completes, the workflow log will show your instance IP:
```
Instance IP: 123.45.67.89
```

Connect with:
```bash
ssh nixos@<IP>
```

## Manual Setup (Local Build)

If you prefer to build locally:

### Requirements

- [Nix](https://nixos.org/download.html) with flakes enabled
- [Terraform](https://www.terraform.io/downloads) >= 1.0
- Oracle Cloud account with free tier
- SSH key pair

### Build and Deploy

```bash
# Clone
git clone https://github.com/yourusername/nixos-oracle-free-tier.git
cd nixos-oracle-free-tier

# Add your SSH key to nix-image/configuration.nix

# Build (requires ARM - use GitHub Actions or ARM machine)
nix build .#

# Configure Terraform
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Edit terraform.tfvars with your OCI credentials

# Deploy
cd terraform && terraform init && terraform apply
```

## Configuration Options

You can customize the deployment via workflow inputs:

| Input | Default | Description |
|-------|---------|-------------|
| ocpus | 4 | Number of OCPUs (1-4 for free tier) |
| memory_gb | 24 | Memory in GB (6-24 for free tier) |

## Architecture

```
.
├── flake.nix                    # NixOS image build definition
├── nix-image/
│   └── configuration.nix        # NixOS system configuration
├── terraform/
│   ├── main.tf                  # Image upload, shape compat, instance
│   ├── variables.tf             # Variable definitions
│   └── outputs.tf               # Output definitions
├── .github/workflows/
│   └── deploy.yml               # Build + Deploy workflow
└── Makefile                     # Local development targets
```

## Troubleshooting

### Shape not compatible error

The workflow includes shape compatibility registration. If you see this error, check the Terraform apply succeeded.

### Instance boots but is unreachable

The workflow configures image capabilities automatically. If issues persist, check the OCI Console for the custom image settings.

### Build fails on x86_64

The build runs on GitHub's ARM64 runners. Local x86_64 builds require QEMU emulation and are very slow.

## Credits

- [Michael Lynch](https://mtlynch.io/nixos-oracle-cloud/) - Original manual guide
- [Erik Parawell](https://erikparawell.com/oracle-cloud-nixos.html) - Automated Terraform approach
- [NixOS](https://nixos.org/) - The OS
- [Oracle Cloud](https://cloud.oracle.com/) - Free tier hosting
