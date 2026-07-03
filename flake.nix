{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };

  outputs = { self, nixpkgs }: {
    packages.aarch64-linux.default = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        "${nixpkgs}/nixos/modules/virtualisation/oci-image.nix"
        ./nix-image/configuration.nix
      ];
    }.config.system.build.OCIImage;
  };
}
