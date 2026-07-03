{ config, pkgs, modulesPath, lib, ... }:

# =============================================================================
# Minimal working NixOS configuration for Oracle Cloud A1.Flex (ARM free tier)
#
# This is a template — copy it and customize to your needs.
#
# REQUIRED for all OCI A1 flakes:
#   1. Import qemu-guest.nix  (↓ line 18)
#   2. availableKernelModules (↓ line 52) — NOT kernelModules
#   3. Mount /, /boot, /boot/efi (↓ line 22)
# =============================================================================

{
  imports = [
    # REQUIRED: Provides virtio/scsi kernel modules the initrd needs
    # to discover the root LVM volume.  Without this the system will
    # hang after reboot (Boot0002 loads the kernel but it can't find rootfs).
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  # ── Filesystems (post-nixos-infect layout) ────────────────────────────────
  # Mount /dev/sda2 at /boot so install-grub.pl writes kernels + GRUB config
  # directly to the boot partition where Boot0002's platform GRUB reads them.
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

  # ── Bootloader (GRUB) ────────────────────────────────────────────────────
  # Boot chain: Boot0002 → platform LUN GRUB → grub.cfg on sda2 → NixOS kernel
  #
  # copyKernels = true is REQUIRED: install-grub.pl writes kernel + initrd to
  # /boot/ (sda2) so the platform GRUB can load them.
  boot.loader.grub.enable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.grub.device = "nodev";
  boot.loader.grub.copyKernels = true;
  boot.loader.efi.canTouchEfiVariables = false;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  # ── LVM (REQUIRED — root is on LVM) ──────────────────────────────────────
  boot.initrd.services.lvm.enable = true;

  # ── Initrd kernel modules ─────────────────────────────────────────────────
  # Use availableKernelModules (NOT kernelModules) so modules are probed
  # rather than force-loaded.  Force-loading causes boot failures on OCI A1.
  boot.initrd.availableKernelModules = [
    "virtio_blk"
    "virtio_net"
    "virtio_pci"
  ];

  # ── Kernel command line ───────────────────────────────────────────────────
  # ttyAMA0 is the OCI serial console.  ttyS0 is a common fallback.
  boot.kernelParams = [
    "console=ttyAMA0,115200"
    "console=ttyS0,115200"
  ];

  # ── Networking ────────────────────────────────────────────────────────────
  networking.hostName = "nixos-oci";          # change to your host
  networking.useDHCP = true;
  networking.dhcpcd.extraConfig = ''
    nohook hostname
  '';

  # ── SSH access ────────────────────────────────────────────────────────────
  services.openssh.enable = true;
  services.openssh.settings = {
    PasswordAuthentication = false;
    PermitRootLogin = "prohibit-password";
  };

  # Add your SSH public key(s) here
  users.users.root = {
    openssh.authorizedKeys.keys = [
      # "ssh-ed25519 AAAA... your-key-here"
    ];
  };

  # Non-root user with sudo (no password prompts)
  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      # "ssh-ed25519 AAAA... your-key-here"
    ];
  };
  security.sudo.wheelNeedsPassword = false;

  # ── Packages ──────────────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    curl
    git
    htop
    neovim
  ];

  # ── Firewall ──────────────────────────────────────────────────────────────
  networking.firewall.allowedTCPPorts = [ 22 ];

  # ── State version (keep at initial install version) ───────────────────────
  system.stateVersion = "25.11";
}
