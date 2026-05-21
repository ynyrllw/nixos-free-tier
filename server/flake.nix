{
  description = "NixOS server configuration with stalwart and neovim";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs = { self, nixpkgs }: {
    nixosConfigurations.default = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [ ./configuration.nix ];
    };
  };
}
