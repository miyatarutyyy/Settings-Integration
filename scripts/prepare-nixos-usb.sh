#!/usr/bin/env bash
set -euo pipefail

disk="${1:-/dev/sda}"

if [[ "$disk" != /dev/sda ]]; then
  echo "Refusing to run: this migration script is pinned to /dev/sda." >&2
  exit 1
fi

if [[ ! -b "$disk" ]]; then
  echo "Block device not found: $disk" >&2
  exit 1
fi

tran="$(lsblk -dn -o TRAN "$disk" | tr -d '[:space:]')"
model="$(lsblk -dn -o MODEL "$disk" | sed 's/[[:space:]]\+/ /g; s/^ //; s/ $//')"
size="$(lsblk -dn -o SIZE "$disk" | tr -d '[:space:]')"

if [[ "$tran" != "usb" ]]; then
  echo "Refusing to run: $disk transport is '$tran', not usb." >&2
  exit 1
fi

echo "About to erase and repartition:"
echo "  disk:  $disk"
echo "  model: $model"
echo "  size:  $size"
echo
echo "This will destroy all data on $disk."
read -r -p "Type ERASE-USB to continue: " answer

if [[ "$answer" != "ERASE-USB" ]]; then
  echo "Aborted."
  exit 1
fi

sudo umount "${disk}"?* 2>/dev/null || true
sudo wipefs --all --force "$disk"
sudo parted --script "$disk" mklabel gpt
sudo parted --script "$disk" mkpart ESP fat32 1MiB 1025MiB
sudo parted --script "$disk" set 1 esp on
sudo parted --script "$disk" mkpart nixos-root ext4 1025MiB 100%
sudo partprobe "$disk"
sleep 2

sudo nix --extra-experimental-features 'nix-command flakes' shell nixpkgs#dosfstools -c mkfs.vfat -F 32 -n NIXOS-ESP "${disk}1"
sudo mkfs.ext4 -F -L nixos-usb "${disk}2"

sudo mkdir -p /mnt
sudo mount "${disk}2" /mnt
sudo mkdir -p /mnt/efi
sudo mount "${disk}1" /mnt/efi

lsblk -f "$disk"
findmnt --real /mnt /mnt/efi
