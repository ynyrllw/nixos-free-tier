{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs = { self, nixpkgs }: {
    nixosConfigurations.oci-base = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        "${nixpkgs}/nixos/modules/virtualisation/oci-image.nix"
        ./configuration.nix
      ];
    };

    packages.aarch64-linux.default =
      self.nixosConfigurations.oci-base.config.system.build.OCIImage;
  };
}
