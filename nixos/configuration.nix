{ config, pkgs, lib, target-ip ? "10.0.0.2", ... }:

{
  system.stateVersion = "25.05";

  # Bootloader for Oracle Cloud UEFI
  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  # Oracle Cloud networking - VirtIO
  networking.hostName = "nixos";
  
  networking.interfaces.ens3 = {
    ipv4.addresses = [{
      address = target-ip;
      prefixLength = 24;
    }];
  };

  networking.defaultGateway = {
    address = "10.0.0.1";
    interface = "ens3";
  };

  # Oracle Cloud DNS
  networking.nameservers = [ "10.0.0.1" ];

  # SSH server
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  # Root user with SSH access
  users.users.root = {
    openssh.authorizedKeys.keys = [
      # Add your SSH public keys here
    ];
  };

  # Create nixos user
  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      # Add your SSH public keys here
    ];
  };

  # Sudo without password
  security.sudo.wheelNeedsPassword = false;

  # File systems - btrfs
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "btrfs";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/*";
    fsType = "vfat";
  };

  # Basic packages
  environment.systemPackages = with pkgs; [
    vim
    curl
    git
    htop
    wget
  ];

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Automatic garbage collection
  nix.gc.automatic = true;
  nix.gc.dates = "weekly";

  # Systemd timer for auto-updates (optional)
  systemd.timesyncd.enable = true;
}
