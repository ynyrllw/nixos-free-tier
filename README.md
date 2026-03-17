# NixOS on Oracle Cloud Free Tier

Automated deployment of NixOS on Oracle Cloud Infrastructure (OCI) ARM free tier using Terraform and GitHub Actions.

## Overview

This repo deploys NixOS to Oracle Cloud's free tier ARM VM (4 OCPUs, 24GB RAM). It uses a pre-built NixOS ARM image to get you started quickly.

## Features

- **Free**: Runs on Oracle Cloud Always Free tier
- **Automated**: Deploy from GitHub Actions with one click
- **ARM64**: Oracle's free A1.Flex ARM instance (4 OCPUs, 24GB RAM)
- **Customizable**: Apply your own NixOS flake after deployment

## Quick Start

### Step 1: Sign up for Oracle Cloud

Create a free account at [Oracle Cloud Free Tier](https://signup.cloud.oracle.com/?sourceType=_ref_coc-asset-opcSignIn&language=en_US).

### Step 2: Fork this repository

Click "Use this template" above to create your own copy.

### Step 3: Get your values

- **TENANCY_OCID**: Oracle Cloud Console → Profile (top right) → Tenancy → Copy OCID
- **REGION**: Your home region (e.g., `eu-zurich-1`)
- **SSH_PUBLIC_KEY**: Contents of `~/.ssh/id_ed25519.pub`

### Step 4: Configure variables

In your forked repo, go to **Settings → Variables → Actions** and add:

| Variable | Value |
|----------|-------|
| `TENANCY_OCID` | Your tenancy OCID |
| `REGION` | Your home region (e.g., eu-zurich-1) |
| `SSH_PUBLIC_KEY` | Your SSH public key |

Subnet is auto-detected!

### Step 5: Deploy!

Go to **Actions → Build and Deploy NixOS to Oracle Cloud → Run workflow**

The build takes ~20-30 minutes, then Terraform deploys your VM.

### Step 6: Connect

After deployment, the workflow log shows your instance IP:
```
Instance IP: 123.45.67.89
```

Connect with:
```bash
ssh nixos@<IP>
```

## Adding Your Own NixOS Config

Once NixOS is running, you can apply your own flake/config:

```bash
# SSH into your VM
ssh nixos@<IP>

# Clone your flake
git clone https://github.com/yourusername/your-nixos-config
cd your-nixos-config

# Apply your config
sudo nixos-rebuild switch --flake .#your-hostname
```

Your NixOS configuration is now applied!

## How It Works

1. Downloads a pre-built NixOS ARM image (from nix-community)
2. Terraform uploads and imports the image to OCI
3. Deploys an ARM VM using the imported image
4. You apply your own flake/config post-deploy

This approach works on GitHub's free ARM runners (which don't support building custom images).

## Requirements

- Oracle Cloud free tier account
- GitHub account (for Actions)
- SSH key pair

## Troubleshooting

**Instance won't deploy:**
- Check that your tenancy has free ARM capacity in your home region

**Can't connect after deploy:**
- Wait a minute for the instance to fully boot
- Check the OCI console for instance status
