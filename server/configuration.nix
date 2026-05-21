{ config, pkgs, lib, ... }:

{
  system.stateVersion = "25.05";

  environment.systemPackages = with pkgs; [
    neovim
    curl
    git
    htop
  ];

  services.stalwart = {
    enable = true;
    openFirewall = true;
    settings = {
      server.hostname = "mail.example.com";
      server.listener = {
        smtp = {
          protocol = "smtp";
          bind = "[::]:25";
        };
        submissions = {
          protocol = "smtp";
          bind = "[::]:587";
          tls.implicit = false;
        };
        imaps = {
          protocol = "imap";
          bind = "[::]:993";
          tls.implicit = true;
        };
        jmap = {
          protocol = "http";
          bind = "[::]:443";
          tls.implicit = true;
        };
      };
    };
  };

  services.tailscale = {
    enable = true;
    openFirewall = true;
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIArazRnnZJHwMct5sN+CvWllir1iHkyHGlh4ERPW1xIy ynyrllw@lenny"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN9tQ4dm3dkw4w+lS6Yxwt1mBOlbRJc0sGmClYcgAUIB ynyr.williams@TC-K90PXJR252"
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  networking.hostName = "nixos-oci";
  networking.useDHCP = true;
  networking.useNetworkd = true;
  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
