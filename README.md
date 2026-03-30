# NixOS on Oracle Cloud Free Tier

Deploy NixOS on Oracle Cloud's free tier ARM VM (4 OCPUs, 24GB RAM) using Terraform + nixos-infect.

## Always Free Resources

| Resource | Limit |
|----------|-------|
| **ARM Compute (A1.Flex)** | 4 OCPUs, 24GB RAM |
| **Boot Volume** | 200 GB |
| **Outbound Data Transfer** | 10 TB/month |

Run a 4-core, 24GB ARM VM on Oracle Cloud **completely free**, forever.

## Prerequisites

- Oracle Cloud free tier account
- API Key (see [Oracle Docs](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm))

## Quick Start

### 1. Configure Terraform

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your OCI credentials:
- `tenancy_ocid` - From Oracle Cloud console
- `user_ocid` - From Profile → User Settings
- `fingerprint` - From API Keys
- `private_key_path` - Path to your API private key
- `ssh_public_key` - Your SSH public key

### 2. Deploy Oracle Linux VM

```bash
terraform init
terraform apply
```

This creates:
- VCN with public subnet
- Oracle Linux 8 ARM instance (4 OCPUs, 24GB RAM, 100GB boot volume)
- Automatically installs NixOS via cloud-init (~15 min)
- Automatically expands disk to use full 100GB

### 3. Install NixOS

SSH into the instance and run nixos-infect:

```bash
ssh opc@<instance-ip>

sudo su
curl https://raw.githubusercontent.com/elitak/nixos-infect/master/nixos-infect | NIX_CHANNEL=nixos-24.05 bash -x
```

The VM will reboot into NixOS.

### 4. Connect to NixOS

```bash
ssh root@<instance-ip>
```

## Adding Your Own NixOS Config

```bash
# Clone your flake
git clone https://github.com/yourusername/your-nixos-config
cd your-nixos-config

# Apply your config
sudo nixos-rebuild switch --flake .#your-hostname
```

## Terraform Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `tenancy_ocid` | Yes | - | Tenancy OCID |
| `user_ocid` | Yes | - | User OCID |
| `fingerprint` | Yes | - | API key fingerprint |
| `private_key_path` | Yes | `~/.oci/oci_api_key.pem` | Path to API private key |
| `ssh_public_key` | Yes | - | SSH public key |
| `region` | No | `eu-zurich-1` | OCI region |
| `ocpus` | No | `4` | Number of OCPUs |
| `memory_in_gbs` | No | `24` | Memory in GB |
| `vcn_id` | No | (new VCN) | Use existing VCN |
| `subnet_id` | No | (new subnet) | Use existing subnet |

## Troubleshooting

**Can't connect after terraform apply:**
- Wait 1-2 minutes for the instance to boot
- Check OCI console for instance status

**SSH permission denied:**
- After nixos-infect, log in as `root` (not `opc`)
- Make sure your SSH key is added to the instance

**ARM capacity unavailable:**
- Try a different region
- Oracle Cloud free tier ARM capacity is limited
