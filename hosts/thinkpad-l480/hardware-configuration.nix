# Hardware facts generated on the ThinkPad L480 and reduced to persistent
# host-specific settings. Codex bind mounts from the generated output were
# intentionally omitted.
{ lib, ... }:

{
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "nvme"
    "sdhci_pci"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/0b8be67c-b220-4081-83c0-3f5ecff20027";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/F170-527F";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
