# NixOS on Oracle Cloud Free Tier

Deploy NixOS on Oracle Cloud's free tier ARM VM (2 OCPUs, 12GB RAM) using Terraform + nixos-infect.

## Always Free Resources

| Resource | Limit |
|----------|-------|
| **ARM Compute (A1.Flex)** | 2 OCPUs, 12GB RAM |
| **Boot Volume** | 200 GB |
| **Outbound Data Transfer** | 10 TB/month |

Run a 2-core, 12GB ARM VM on Oracle Cloud **completely free**, forever.

### Post-infect filesystem layout

After nixos-infect, the disk layout is (all three must be mounted in your flake):

| Mount | Device | FSType |
|---|---|---|
| `/` | `/dev/mapper/ocivolume-root` | xfs |
| `/boot` | `/dev/sda2` | xfs |
| `/boot/efi` | `/dev/sda1` | vfat |

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
- Oracle Linux 8 ARM instance (2 OCPUs, 12GB RAM, 100GB boot volume)
- Automatically installs NixOS via cloud-init (~15 min)
- Automatically expands disk to use full 100GB

### 3. Install NixOS

SSH into the instance and run nixos-infect:

```bash
ssh opc@<instance-ip>

sudo su
curl https://raw.githubusercontent.com/elitak/nixos-infect/master/nixos-infect | NIX_CHANNEL=nixos-25.11 bash -x
```

The VM will reboot into NixOS.

### 4. Connect to NixOS

```bash
ssh root@<instance-ip>
```

## Adding Your Own NixOS Config

After nixos-infect completes, the instance is ready for your own flake:

```bash
# Copy your flake to the server
rsync -avz -e "ssh" /path/to/your-flake/ root@<instance-ip>:/root/your-flake/

# Apply it
ssh root@<instance-ip>
export LOCALE_ARCHIVE=/dummy
cd /root/your-flake && nixos-rebuild switch --flake .#default
```

### Requirements for your flake on OCI A1

Your flake **must** include these three things to survive a reboot:

1. **Import `qemu-guest.nix`** — provides virtio/scsi kernel modules the initrd needs to discover the rootfs.

2. **Use `availableKernelModules`** (not `kernelModules`) — force-loading modules causes boot failures.

3. **Mount all three filesystems** — `/`, `/boot` (sda2), and `/boot/efi` (sda1). See the filesystem table below.

The `server/` directory in this repo contains a [minimal working example](server/) you can copy.

### Known pitfalls

- First `nixos-rebuild switch` may fail with `LOCALE_ARCHIVE` for `systemd-run -E`. Workaround: `LOCALE_ARCHIVE=/dummy nixos-rebuild switch`.
- The boot partition (`/dev/sda2`) must be mounted at `/boot` in your flake so `install-grub.pl` writes the GRUB config to it. Without this, the system won't boot after reboot.

## Terraform Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `tenancy_ocid` | Yes | - | Tenancy OCID |
| `user_ocid` | Yes | - | User OCID |
| `fingerprint` | Yes | - | API key fingerprint |
| `private_key_path` | Yes | `~/.oci/oci_api_key.pem` | Path to API private key |
| `ssh_public_key` | Yes | - | SSH public key |
| `region` | No | `eu-zurich-1` | OCI region |
| `ocpus` | No | `2` | Number of OCPUs |
| `memory_in_gbs` | No | `12` | Memory in GB |
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
