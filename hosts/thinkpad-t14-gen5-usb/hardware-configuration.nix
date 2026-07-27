# USB storage hardware configuration for the ThinkPad T14 Gen 5 test install.
# The root and ESP are addressed by labels created by scripts/prepare-nixos-usb.sh.
{ lib, ... }:

{
  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "thunderbolt"
    "usb_storage"
    "uas"
    "sd_mod"
    "usbhid"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos-usb";
    fsType = "ext4";
    options = [ "noatime" ];
  };

  fileSystems."/efi" = {
    device = "/dev/disk/by-label/NIXOS-ESP";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
