# Host facts from inventories/trt-ryzen7-archlinux.md, checked 2026-07-23.
# Current source system: Arch Linux.
# Planned NixOS hostname: thinkpad-t14.
# Model: Lenovo ThinkPad T14 Gen 5
# CPU: AMD Ryzen 7 PRO 8840U
# GPU: AMD Radeon 780M-class iGPU, amdgpu
# RAM: 30 GiB
# Wi-Fi: Qualcomm QCNFA765, ath11k_pci
# Storage: Micron 3500 NVMe SSD
# Disk swap: none observed on the source Arch system.

{ ... }:

{
  networking.hostName = "trt-ryzen7";

  system.stateVersion = "26.05";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  hardware.cpu.amd.updateMicrocode = true;
}
