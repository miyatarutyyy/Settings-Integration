#!/usr/bin/env bash
set -euo pipefail

disk="${1:-/dev/sda}"

if [[ "$disk" != /dev/sda ]]; then
  echo "Refusing to run: this migration script is pinned to /dev/sda." >&2
  exit 1
fi

if [[ ! -b "${disk}1" || ! -b "${disk}2" ]]; then
  echo "Expected ${disk}1 and ${disk}2 to exist." >&2
  exit 1
fi

tran="$(lsblk -dn -o TRAN "$disk" | tr -d '[:space:]')"
esp_label="$(lsblk -dn -o LABEL "${disk}1" | tr -d '[:space:]')"

if [[ "$tran" != "usb" ]]; then
  echo "Refusing to run: $disk transport is '$tran', not usb." >&2
  exit 1
fi

if [[ "$esp_label" != "NIXOS-ESP" ]]; then
  echo "Refusing to run: ${disk}1 label is '$esp_label', not NIXOS-ESP." >&2
  exit 1
fi

echo "About to format ${disk}2 as ext4 label nixos-usb and mount USB install target."
read -r -p "Type FORMAT-ROOT to continue: " answer

if [[ "$answer" != "FORMAT-ROOT" ]]; then
  echo "Aborted."
  exit 1
fi

sudo umount /mnt/efi /mnt "${disk}2" 2>/dev/null || true
sudo mkfs.ext4 -F -L nixos-usb "${disk}2"
sudo mkdir -p /mnt
sudo mount "${disk}2" /mnt
sudo mkdir -p /mnt/efi
sudo mount "${disk}1" /mnt/efi

lsblk -f "$disk"
findmnt --real /mnt /mnt/efi
