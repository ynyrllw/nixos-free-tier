{ config, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  boot.initrd.availableKernelModules = [ "ahci" "xhci_pci" "virtio_pci" "sr_mod" "virtio_blk" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";

  # Oracle Cloud specific
  hardware.enableRedistributableFirmware = lib.mkDefault true;

  # Oracle Cloud uses VirtIO for networking
  networking.usePredictableInterfaceNames = lib.mkDefault false;
  networking.interfaces.ens3.useDHCP = false;
}
