#!/usr/bin/env bash
set -euo pipefail

repo="/home/trt-ryzen7/MIGRATE"
host="thinkpad-t14-gen5-usb"

root_source="$(findmnt -n -o SOURCE /mnt || true)"
esp_source="$(findmnt -n -o SOURCE /mnt/efi || true)"
root_label="$(lsblk -no LABEL "$root_source" 2>/dev/null | tr -d '[:space:]' || true)"
esp_label="$(lsblk -no LABEL "$esp_source" 2>/dev/null | tr -d '[:space:]' || true)"

if [[ "$root_source" != "/dev/sda2" || "$esp_source" != "/dev/sda1" ]]; then
  echo "Refusing to install: expected /mnt=/dev/sda2 and /mnt/efi=/dev/sda1." >&2
  echo "  /mnt:     ${root_source:-not mounted}" >&2
  echo "  /mnt/efi: ${esp_source:-not mounted}" >&2
  exit 1
fi

if [[ "$root_label" != "nixos-usb" || "$esp_label" != "NIXOS-ESP" ]]; then
  echo "Refusing to install: unexpected USB labels." >&2
  echo "  /mnt label:     ${root_label:-none}" >&2
  echo "  /mnt/efi label: ${esp_label:-none}" >&2
  exit 1
fi

echo "Installing NixOS host '$host' to USB:"
echo "  root: /dev/sda2 mounted at /mnt"
echo "  ESP:  /dev/sda1 mounted at /mnt/efi"
echo
echo "Internal disk /dev/nvme0n1 is not an install target."
read -r -p "Type INSTALL-USB-NIXOS to continue: " answer

if [[ "$answer" != "INSTALL-USB-NIXOS" ]]; then
  echo "Aborted."
  exit 1
fi

sudo nix --extra-experimental-features 'nix-command flakes' \
  shell github:NixOS/nixpkgs/nixos-26.05#nixos-install-tools \
  -c nixos-install \
  --flake "$repo#$host" \
  --root /mnt \
  --no-root-passwd

cat <<'EOF'

Set the test user's password before booting the USB install:
  sudo nixos-enter --root /mnt -c 'passwd tarutyyyne'

EOF
