# AGENTS.md

This file provides guidance for AI agents working on this repository.

## Project Overview

**Note for agents**: When working on any NixOS‑related task, always consult the official NixOS documentation (e.g. `nixos.org/manual` or the NixOS Wiki) for the most up‑to‑date package options and configuration options. This includes checking the package name, module options, and service definitions before adding or modifying Nix expressions.

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
  - `ocpus` - Defaults to 2 (max free tier)
  - `memory_in_gbs` - Defaults to 12 (max free tier)
  - `bucket_name` - Defaults to "nixos-images"

When adding new features or variables, prioritize this philosophy:
- If something can be auto-detected, auto-detect it
- If something has a sensible default, provide one
- Only require what is truly necessary

## Key Files

- `terraform/main.tf` - Terraform configuration (deploys Oracle Linux 8 ARM + VCN)
- `terraform/variables.tf` - Terraform variables

## How It Works

1. Terraform deploys Oracle Linux 8 ARM instance
2. Cloud-init (in `main.tf`) resizes the ESP to 1.1G and runs nixos-infect
3. User applies their own flake via `nixos-rebuild switch`

### Known pitfalls

**Stale sda2 partition**: The cloud-init deletes sda2 and resizes sda1, but sda2
is still mounted at `/boot` from the Oracle Linux boot. Without an explicit
`umount /boot` before the `sgdisk` commands, the kernel retains a stale
`/dev/sda2` that breaks `bootctl` and `grub-install` (both try to probe it and
fail to find a GRUB drive mapping).  The fix (applied) is to unmount first,
then `partx -d` the stale device, then re-read the partition table.

**Empty LOCALE_ARCHIVE env**: `nixos-rebuild` passes `LOCALE_ARCHIVE` to
`systemd-run -E`.  If the variable is empty (as it is during the first switch
after nixos-infect), systemd rejects it: "Invalid environment block".  Work
around: `LOCALE_ARCHIVE=/dummy nixos-rebuild switch`.

This is simpler than the old approach (custom image upload) and more reliable.

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

Use a **local backend** by default:
```hcl
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
```

For team deployments, consider using the OCI native backend (available in Terraform >= 1.12 or with the OCI provider plugin).

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
3. The free tier allows 2 OCPUs / 12GB RAM (1500 OCPU hours/month) - running continuously stays under limit

## Deployment Approaches Tested

### Approach 1: nixos-infect (Recommended)

The simplest approach - use [nixos-infect](https://github.com/elitak/nixos-infect) to convert an existing Oracle Linux VM to NixOS:

```bash
# On Oracle Linux instance
curl https://raw.githubusercontent.com/elitak/nixos-infect/master/nixos-infect | NIX_CHANNEL=nixos-25.11 bash -x
```

**Tested and working on:**
- Oracle Linux 8.10 (aarch64) ✅
- Ubuntu 22.04 (aarch64) ✅
- Oracle Linux 9.1 (aarch64) ✅

**Advantages:**
- No custom image building required
- Works on any Oracle-supported Linux distro
- Single command installation

**Disadvantages:**
- Requires console access to handle reboot (MaxStartups SSH issue)

### Approach 2: Custom Image with Terraform

Build a NixOS image locally (requires ARM hardware or binfmt emulation), then upload via Terraform.

**Requirements:**
- ARM hardware (Mac M1+, Raspberry Pi, etc.) OR
- binfmt emulation on x86_64 (very slow - hours to days)

**Steps:**
1. Build image with `nix build .#packages.aarch64-linux.default`
2. Upload to OCI Object Storage via Terraform
3. Import as custom image
4. Register shape compatibility
5. Deploy instance

### Approach 3: nixos-anywhere / kexec (Does NOT work)

**kexec fails on Oracle Cloud ARM** - After kexec-based installation, the machine reboots but becomes unreachable. This is a known limitation:
- The Oracle Cloud ARM instances don't properly reinitialize networking after kexec
- OCI shows instance as RUNNING but network is unreachable

### Approach 4: netboot.xyz (Not tested)

Michael Lynch's method uses netboot.xyz EFI boot to run the NixOS installer:
1. Download netboot.xyz-arm64.efi to /boot/efi/
2. Boot into EFI shell via Oracle Console
3. Load netboot.xyz and select NixOS installer
4. Run disko + nixos-install

This should work but requires manual console interaction.

## OCI A1 Boot Chain (CRITICAL for flake authors)

Understanding how OCI A1 boots is essential for writing a flake that survives reboot.

### Boot order

```
BootCurrent: 0002
Boot0002* UEFI ORACLE BlockVolume  PciRoot(0x0)/Pci(0x5,0x7)/Pci(0x0,0x0)/SCSI(0,1)
```

1. **Boot0002** loads a GRUB image from a **platform LUN** (not the ESP partition).
2. This platform GRUB reads `grub.cfg` from `(hd0,gpt2)` (sda2 — the boot partition).
3. The grub.cfg searches for sda2 by UUID (`search --fs-uuid`) and loads the NixOS kernel + initrd.
4. The NixOS kernel mounts rootfs and runs systemd.

The **ESP** (`Boot0005`, `/dev/sda1`) is only used if Boot0002 fails — it is a **fallback path** only.

### What this means for flakes

After `nixos-rebuild switch`, `install-grub.pl` writes a new `grub.cfg` to `/boot/`.
If `fileSystems."/boot" = /dev/sda2`, this goes directly to sda2 where the
platform LUN's GRUB can read it.  On a subsequent reboot:

```
Boot0002 → platform LUN GRUB → grub.cfg on sda2 → NixOS kernel + initrd → systemd
```

### Mandatory flake requirements for OCI A1

Every flake that will run on OCI A1 **must** include these:

```nix
{ modulesPath, ... }: {
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot.initrd.availableKernelModules = [ "virtio_blk" "virtio_pci" "virtio_net" ];
  # NOT kernelModules — availableKernelModules probes hardware rather than
  # force-loading.  Using kernelModules causes boot failures on OCI A1.

  boot.kernelParams = [ "console=ttyAMA0,115200" "console=ttyS0,115200" ];
}
```

Without `qemu-guest.nix` and `availableKernelModules`, the NixOS initrd may not
discover the rootfs (`/dev/mapper/ocivolume-root`) and the system will hang
after reboot.

### Filesystem layout (post-nixos-infect)

| Partition | Device | FSType | Mount |
|---|---|---|---|
| ESP | `/dev/sda1` | vfat | `/boot/efi` |
| Boot | `/dev/sda2` | xfs | `/boot` |
| Root (LVM LV) | `/dev/mapper/ocivolume-root` | xfs | `/` |

Mount **all three** in your flake:

```nix
fileSystems."/" = {
  device = "/dev/mapper/ocivolume-root";
  fsType = "xfs";
};
fileSystems."/boot" = {
  device = "/dev/sda2";
  fsType = "xfs";
};
fileSystems."/boot/efi" = {
  device = "/dev/sda1";
  fsType = "vfat";
};
```

Do **not** use `/dev/disk/by-label/` — those labels do not exist on OCI.

### GRUB config on sda2 lifecycle

`install-grub.pl` writes kernels + grub.cfg to sda2.  The platform LUN's GRUB
reads this grub.cfg on every boot.  Additional `extraInstallCommands` are
needed because:

1. `install-grub.pl` runs via `systemd-run` in a separate mount namespace and
   may write to rootfs `/boot/` (a directory) rather than sda2.
2. The grub.cfg it creates references the rootfs UUID and `/boot/kernels/`
   paths, but the boot partition has a different UUID and uses `/kernels/`.
3. The ESP `BOOTAA64.EFI` (fallback boot) must be regenerated because
   `grub-install` produces core images that hang on OCI A1 ARM64 firmware.

See the `extraInstallCommands` in `nixos-flake/modules/default.nix` for a
complete implementation.

### Example flake

The `server/` directory contains a minimal working flake template for OCI A1.
Copy it to start your own NixOS configuration.

## Current Deployment Method

The recommended approach for automation:

1. **Create Oracle Linux 8 ARM instance** via OCI Console or Terraform
2. **Use nixos-infect** to convert to NixOS (run via cloud-init or SSH)
3. **Apply custom flake** via nixos-rebuild

This approach:
- Doesn't require building custom images
- Works with Oracle's provided base images
- Can be automated via cloud-init user data
