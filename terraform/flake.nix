{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, disko }:
    let
      target-ip = if (builtins.hasAttr "target_ip" specialArgs) then specialArgs.target_ip else "10.0.0.2";
    in
    {
      packages.aarch64-linux.nixos-anywhere-installer = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          disko.nixosModules.disko
          {
            disko.devices = {
              disk = {
                device = "/dev/sda";
                type = "disk";
                partitionTableType = "gpt";
                content = {
                  type = "gpt";
                  partitions = {
                    esp = {
                      size = "512M";
                      type = "EF00";
                      content = {
                        type = "filesystem";
                        format = "vfat";
                        mountpoint = "/boot";
                      };
                    };
                    root = {
                      size = "100%";
                      content = {
                        type = "btrfs";
                        extraArgs = [ "-L" "nixos" ];
                        subvolumes = {
                          "/root" = {
                            mountpoint = "/";
                          };
                          "/home" = {
                            mountpoint = "/home";
                          };
                          "/nix" = {
                            mountpoint = "/nix/store";
                            mountOptions = [ "noatime" ];
                          };
                          "/var/log" = {
                            mountpoint = "/var/log";
                          };
                        };
                      };
                    };
                  };
                };
              };
            };
          }
          ./configuration.nix
          { _module.args = { inherit target-ip; }; }
        ];
      };
    };
}
