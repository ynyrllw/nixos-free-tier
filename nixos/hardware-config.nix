{ config, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  # Oracle Cloud ARM64 (Ampere Altra)
  boot.initrd.availableKernelModules = [
    "ahci"
    "xhci_pci"
    "virtio_pci"
    "sr_mod"
    "virtio_blk"
    "virtio_scsi"
  ];

  boot.initrd.kernelModules = [ "virtio" ];
  boot.kernelModules = [ "virtio_pci" "virtio_blk" "virtio_scsi" ];
  boot.extraModulePackages = [ ];

  # Set target platform
  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

  # CPU frequency
  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";

  # Oracle Cloud firmware
  hardware.enableRedistributableFirmware = lib.mkDefault true;

  # VirtIO networking
  networking.usePredictableInterfaceNames = lib.mkDefault false;
  networking.interfaces.ens3.useDHCP = false;
}
