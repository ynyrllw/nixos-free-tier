{ config, pkgs, lib, ... }:

let
  target-ip = if (builtins.hasAttr "target_ip" specialArgs) then specialArgs.target_ip else "10.0.0.2";
  ssh-user = if (builtins.hasAttr "ssh_user" specialArgs) then specialArgs.ssh_user else "root";
in
{
  imports = [
    ./hardware-config.nix
  ];

  system.stateVersion = "25.05";

  networking.hostName = "nixos";

  networking.interfaces.ens3.ipv4.addresses = [{
    address = target-ip;
    prefixLength = 24;
  }];

  networking.defaultGateway = {
    address = "10.0.0.1";
    interface = "ens3";
  };

  networking.nameservers = [ "10.0.0.1" ];

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  users.users.root = {
    openssh.authorizedKeys.keys = [
      # Add your SSH keys here
    ];
  };

  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    openssh.authorizedKeys.keys = [
      # Add your SSH keys here
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    vim
    curl
    git
    htop
  ];

  # Enable Docker for container workloads
  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
      flags = [ "--all" ];
    };
  };

  # Enable automatic updates
  system.autoUpgrade.enable = true;
  system.autoUpgrade.allowReboot = true;

  # Boot configuration
  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "btrfs";
  };

  swapDevices = [
    { device = "/dev/disk/by-label/swap"; }
  ];
}
