{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs = { self, nixpkgs }: {
    packages.aarch64-linux.default =
      let
        config = {
          system.stateVersion = "25.05";

          # Enable SSH
          services.openssh = {
            enable = true;
            settings = {
              PasswordAuthentication = false;
              PermitRootLogin = "no";
            };
          };

          # Cloud-init for Oracle Cloud
          services.cloud-init = {
            enable = true;
            network.enable = true;
          };

          # Networking
          networking.firewall = {
            enable = true;
            allowedTCPPorts = [ 22 ];
          };

          # User configuration
          users.users.nixos = {
            isNormalUser = true;
            extraGroups = [ "wheel" ];
            openssh.authorizedKeys.keys = [
              # This will be replaced by cloud-init or instance metadata
            ];
          };

          security.sudo.wheelNeedsPassword = false;

          # Enable QEMU guest agent for Oracle Cloud
          services.qemuGuest.enable = true;
        };
      in
      nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          "${nixpkgs}/nixos/modules/virtualisation/oci-image.nix"
          { _module.args = { }; }
          config
        ];
      };
  };
}
