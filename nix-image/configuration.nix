{ config, pkgs, lib, ... }: {
  imports = [ ./disko-config.nix ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;

  # Use predictable interface names for Oracle Cloud
  boot.kernelParams = [ 
    "net.ifnames=0" 
    "console=ttyAMA0,115200" 
    "console=ttyS0,115200"
    # Add these for Oracle Cloud
    "ip=dhcp"
    "net.ifnames=0"
  ];

  # Fix conflict between disko and OCI image module - use mkForce to override disko
  fileSystems."/".device = lib.mkForce "/dev/disk/by-label/nixos";
  fileSystems."/boot".device = lib.mkForce "/dev/disk/by-label/ESP";

  system.stateVersion = "25.05";

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # Enable cloud-init with OCI datasource
  services.cloud-init = {
    enable = true;
    network = {
      enable = true;
    };
  };

  # Network configuration for Oracle Cloud
  networking.hostName = "nixos-oci";
  networking.useDHCP = true;
  networking.useNetworkd = true;

  # Explicit network configuration for Oracle Cloud - all interfaces use DHCP
  networking.interfaces = lib.mkForce {
    "eth0" = {
      useDHCP = true;
    };
  };

  # Enable DHCP for all
  networking.dhcpcd.enable = true;

  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIArazRnnZJHwMct5sN+CvWllir1iHkyHGlh4ERPW1xIy ynyrllw@lenny"
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    curl
    git
    htop
  ];
}