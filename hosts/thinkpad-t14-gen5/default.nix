# Host facts from the Arch source inventory, checked 2026-07-23.
# Current source system: Arch Linux.
# NixOS hostname: thinkpad-t14-gen5.
# Model: Lenovo ThinkPad T14 Gen 5
# CPU: AMD Ryzen 7 PRO 8840U
# GPU: AMD Radeon 780M-class iGPU, amdgpu
# RAM: 30 GiB
# Wi-Fi: Qualcomm QCNFA765, ath11k_pci
# Storage: Micron 3500 NVMe SSD
# Disk swap: none observed on the source Arch system.

{ ... }:

{
  networking.hostName = "thinkpad-t14-gen5";

  system.stateVersion = "26.05";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  hardware.cpu.amd.updateMicrocode = true;

  services.ollama.enable = true;
}
