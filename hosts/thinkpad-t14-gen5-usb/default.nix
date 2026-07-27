# USB boot test host for the ThinkPad T14 Gen 5.
# This keeps the internal Arch Linux disk untouched while validating NixOS.
{ lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "thinkpad-t14-gen5-usb";

  system.stateVersion = "26.05";

  boot.loader.systemd-boot.enable = lib.mkDefault true;
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault false;
  boot.loader.efi.efiSysMountPoint = "/efi";

  hardware.cpu.amd.updateMicrocode = true;

  zramSwap.enable = true;
  systemd.oomd.enable = true;
}
