# Host facts from inventories/thinkpad-l480-nixos.md, checked 2026-07-23.
# Model: Lenovo ThinkPad L480
# CPU: Intel Core i5-8250U
# GPU: Intel iGPU, i915
# RAM: 7.5 GiB
# Wi-Fi: Intel iwlwifi
# Storage: NVMe, ext4 root, vfat /boot
# Disk swap: none observed; zram swap is enabled for desktop stability.

{ lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "thinkpad-l480";

  system.stateVersion = "26.05";

  boot.loader.systemd-boot.enable = lib.mkDefault true;
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;

  hardware.cpu.intel.updateMicrocode = true;

  zramSwap.enable = true;
  systemd.oomd.enable = true;
}
