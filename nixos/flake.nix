{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, disko }: {
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
                  boot = {
                    size = "1M";
                    type = "EF00";
                    content = {
                      type = "filesystem";
                      format = "vfat";
                      mountpoint = "/boot/efi";
                    };
                  };
                  root = {
                    size = "100%";
                    content = {
                      type = "lvms";
                      logicalVolumes = {
                        swap = {
                          size = "8G";
                          type = "swap";
                          swap.swapChance = 1;
                          swap.swapPriority = 1;
                        };
                        root = {
                          size = "100%";
                          type = "linux";
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
              };
            };
          };
        }
        ./configuration.nix
      ];
    };
  };
}
