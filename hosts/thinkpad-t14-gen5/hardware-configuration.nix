# Hardware facts generated on the ThinkPad T14 Gen 5 from the Arch source
# system and reduced to persistent host-specific settings. Codex/Guix bind
# mounts and transient autofs entries were intentionally omitted.
{ lib, ... }:

{
  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "thunderbolt"
    "usbhid"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/c1e9791a-ef8d-4a06-8342-795046372c11";
    fsType = "ext4";
  };

  fileSystems."/efi" = {
    device = "/dev/disk/by-uuid/D94E-D64E";
    fsType = "vfat";
    options = [
      "fmask=0177"
      "dmask=0077"
    ];
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
