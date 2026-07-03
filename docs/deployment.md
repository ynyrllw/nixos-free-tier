# Deployment Guide

This guide covers how to deploy NixOS to Oracle Cloud Free Tier using GitHub Actions.

## Prerequisites

- Oracle Cloud account with free tier
- GitHub account
- SSH key pair (generate with `ssh-keygen` if you don't have one)

## Step 1: Fork the Repository

Click "Use this template" on the repository page to create your own copy.

## Step 2: Get Oracle Cloud Credentials

### Get Tenancy OCID
1. Log into [Oracle Cloud Console](https://console.oraclecloud.com)
2. Click your profile (top right) → Tenancy: `<your-tenancy>`
3. Copy the OCID

### Get Compartment OCID
Usually the same as your tenancy OCID, or create a new compartment:
- Identity & Security → Compartments → Create Compartment

### Get Region
Your home region (e.g., `us-ashburn-1`, `us-phoenix-1`)

### Get Object Storage Namespace
1. Storage → Buckets
2. Create a bucket named `nixos-images`
3. The namespace is shown at the top of the bucket page

### Get Subnet OCID
1. Networking → Virtual Cloud Networks
2. Select your VCN (or create one)
3. Go to Subnets
4. Copy a public subnet's OCID

### Get SSH Public Key
```bash
cat ~/.ssh/id_ed25519.pub
# or
cat ~/.ssh/id_rsa.pub
```

## Step 3: Add Secrets to GitHub

In your forked repo:

1. Go to **Settings → Secrets and variables → Actions**
2. Click "New repository secret" and add:

| Secret | Value |
|--------|-------|
| `TENANCY_OCID` | Your tenancy OCID |
| `COMPARTMENT_OCID` | Your compartment OCID |
| `REGION` | Your region (e.g., `us-ashburn-1`) |
| `NAMESPACE` | Your object storage namespace |
| `SUBNET_ID` | Your subnet OCID |
| `SSH_PUBLIC_KEY` | Your SSH public key |

## Step 4: Run the Workflow

1. Go to **Actions → Build and Deploy NixOS to Oracle Cloud**
2. Click "Run workflow"
3. Use default values (2 OCPUs, 12GB) or customize
4. Click "Run workflow"

## Step 5: Connect

The workflow takes ~15-20 minutes to build + deploy.

When complete, check the workflow log for the instance IP:
```
Instance IP: 123.45.67.89
```

Connect with:
```bash
ssh nixos@<IP>
```

## Configuration Options

| Input | Default | Description |
|-------|---------|-------------|
| ocpus | 2 | OCPUs (1-2 for free tier) |
| memory_gb | 12 | Memory in GB (6-12 for free tier) |

## Troubleshooting

### Shape not compatible error
This should be handled automatically by the Terraform configuration. If it persists, check the workflow logs.

### Image import takes too long
OCI image imports can take 30-45 minutes. The workflow has a 60-minute timeout.

### Instance unreachable after deploy
Wait 1-2 minutes for the instance to fully boot. Check the OCI Console for instance status.

## Cleanup

To destroy the instance:
1. Go to Actions → Build and Deploy NixOS to Oracle Cloud
2. Click "Run workflow"
3. Add input: wait_for_destroy = true
4. Or manually: go to OCI Console → Compute → Instances → Terminate
