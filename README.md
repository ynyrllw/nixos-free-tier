# NixOS on Oracle Cloud Free Tier

Automated deployment of NixOS on Oracle Cloud Infrastructure (OCI) ARM free tier using Terraform and GitHub Actions.

## Overview

This repo deploys NixOS to Oracle Cloud's free tier ARM VM (4 OCPUs, 24GB RAM). It uses a pre-built NixOS ARM image to get you started quickly.

## Always Free Resources

Oracle Cloud provides **Always Free** resources that never expire:

| Resource | Limit |
|----------|-------|
| **ARM Compute (A1.Flex)** | 3,000 OCPU hours + 18,000 GB hours/month (~4 OCPUs, 24GB continuously) |
| **VCN** | 2 Virtual Cloud Networks |
| **Outbound Data Transfer** | 10 TB/month |
| **Object Storage** | 10 GB in home region (or 20 GB total with Archive Storage) |
| **Custom Image Storage** | Included in Object Storage limit (NixOS image is ~1GB) |

This means you can run a 4-core, 24GB ARM VM on Oracle Cloud **completely free**, forever.

The deployment uses just one bucket (~1GB for the NixOS image) - well under the free limits.

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

### Step 3: Oracle Cloud Authentication

To authenticate with Oracle Cloud from GitHub Actions, you need an API key.

#### Create API Key

1. Go to **Profile → User Settings → API Keys**
2. Click **Add API Key**
3. Choose **"Generate API Key Pair"**
4. Click **Download Private Key** and save it
5. Click **Add** (fingerprint is shown automatically)

See [Oracle Docs](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm) for full details.

#### Get Values

After creating the API key, you'll see a config like this:

```
[DEFAULT]
user=ocid1.user.oc1..aaaa...
fingerprint=aa:bb:cc:...
tenancy=ocid1.tenancy.oc1..aaaa...
region=eu-zurich-1
key_file=<path>
```

Use these values below. Only the private key is sensitive.

### Step 4: Configure secrets and variables

In your forked repo:

1. Go to **Settings → Secrets → Actions** and add:

| Secret | Value |
|--------|-------|
| `OCI_PRIVATE_KEY` | Paste entire private key (including -----BEGIN...) |

2. Go to **Settings → Variables → Actions** and add:

| Variable | Value |
|----------|-------|
| `OCI_TENANCY_OCID` | From config (tenancy=) |
| `OCI_USER_OCID` | From config (user=) |
| `OCI_FINGERPRINT` | From config (fingerprint=) |
| `OCI_REGION` | From config (region=) |
| `SSH_PUBLIC_KEY` | Your SSH public key |

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
