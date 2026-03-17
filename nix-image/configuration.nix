{ config, pkgs, ... }: {
  system.stateVersion = "25.05";

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  services.cloud-init.enable = true;

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
  };

  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      # TODO: Replace with your SSH public key
    ];
  };

  security.sudo.wheelNeedsPassword = false;
}
