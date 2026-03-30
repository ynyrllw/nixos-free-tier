{
  description = "NixOS configuration for Oracle Cloud";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, disko }: {
    nixosConfigurations = {
      oci = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          "${nixpkgs}/nixos/modules/virtualisation/oci-image.nix"
          disko.nixosModules.disko
          ./configuration.nix
        ];
      };
    };

    packages.aarch64-linux.default =
      self.nixosConfigurations.oci.config.system.build.OCIImage;
  };
}