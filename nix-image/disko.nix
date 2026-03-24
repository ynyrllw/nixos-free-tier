{ lib, ... }:
{
  disko devices = {
    disk = {
      main = {
        device = "/dev/sda";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              label = "boot";
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            root = {
              label = "root";
              size = "100%";
              type = "8304";
              content = {
                type = "btrfs";
                subvolumes = {
                  "/": {
                    mountpoint = "/";
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