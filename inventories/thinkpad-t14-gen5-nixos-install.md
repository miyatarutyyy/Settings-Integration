# ThinkPad T14 Gen 5 NixOS install plan

作成日: 2026-07-28

目的: ThinkPad T14 Gen 5 の既存 Arch Linux を消去し、内蔵 SSD を再フォーマットして、この repository の `thinkpad-t14-gen5` NixOS 構成を本番適用するための手順を記録する。

この文書は破壊的操作を含む。実行前に対象ディスク、バックアップ、secrets の扱いを確認する。

## 前提

- この repository を NixOS / Home Manager の正本とする。
- NixOS host 名は `thinkpad-t14-gen5` とする。
- ユーザー名は `tarutyyyne` に統一する。
- 既存 Arch Linux の hostname や user 名は移行元情報として扱い、最終 NixOS 構成名には使わない。
- 秘密鍵、token、password、login state は平文で Git 管理しない。
- SSD を format すると filesystem UUID は変わるため、install 直前に `hosts/thinkpad-t14-gen5/hardware-configuration.nix` を更新する。

## 重要な注意点

現在の `hosts/thinkpad-t14-gen5/hardware-configuration.nix` は、Arch Linux 時点で観測した filesystem UUID を参照している。

```nix
fileSystems."/" = {
  device = "/dev/disk/by-uuid/c1e9791a-ef8d-4a06-8342-795046372c11";
  fsType = "ext4";
};

fileSystems."/efi" = {
  device = "/dev/disk/by-uuid/D94E-D64E";
  fsType = "vfat";
};
```

内蔵 SSD を再フォーマットした場合、これらの UUID は変わる。したがって、format 後に `nixos-generate-config --root /mnt` の結果と照合し、repo 側の `hosts/thinkpad-t14-gen5/hardware-configuration.nix` を必ず更新する。

更新せずに install すると、boot 後に root filesystem や ESP を見つけられない可能性がある。

## 0. L480 側で repository を確認して push する

現在の正本 repository で、少なくとも評価が通ることを確認する。

```bash
cd /home/tarutyyyne/Git/MIGRATE
git status
nix flake check
git push
```

## 1. Arch Linux 側で必要データをバックアップする

SSD を消去する前に、必要な状態データを外部ディスクまたは暗号化バックアップへ退避する。

必須候補:

- `~/.ssh`
- `~/.gnupg`
- `~/.authinfo.gpg`
- `~/.authinfo`
- `~/.config/gh`
- `~/.config/.wrangler`
- `~/.claude`
- `~/.claude.json`
- `~/.codex`
- `~/.local/share/fcitx5/skk/user.dict`
- 未 push の `~/Git/*`
- 必要な `~/Documents`、`~/Downloads`、その他個人データ

secrets 方針:

- 秘密値はこの repository に commit しない。
- OAuth token 類は原則として NixOS 移行後に再ログインする。
- 既存環境で平文保存されていた API key や password は、可能なら rotate する。
- SSH / GPG private key は、必要な場合だけ暗号化バックアップで移行する。

## 2. NixOS installer USB で T14 を起動する

NixOS installer を起動し、network を接続する。

Wi-Fi の例:

```bash
iwctl
station wlan0 scan
station wlan0 get-networks
station wlan0 connect <SSID>
exit
```

接続確認:

```bash
ping -c 3 github.com
```

## 3. 対象 SSD を確認する

次のコマンドで disk model、size、transport、既存 filesystem を確認する。

```bash
lsblk -o NAME,SIZE,MODEL,TRAN,FSTYPE,LABEL,UUID,MOUNTPOINTS
```

inventory 上の T14 内蔵 SSD は Micron 3500 NVMe SSD である。通常は `/dev/nvme0n1` の可能性が高いが、device 名だけで判断しない。必ず `MODEL` と `SIZE` を見て対象を確認する。

以降の例では、対象 disk を `/dev/nvme0n1` として書く。

## 4. 内蔵 SSD を消去して partition / format する

この操作は `/dev/nvme0n1` の全データを消去する。

```bash
sudo wipefs --all --force /dev/nvme0n1

sudo parted --script /dev/nvme0n1 mklabel gpt
sudo parted --script /dev/nvme0n1 mkpart ESP fat32 1MiB 1025MiB
sudo parted --script /dev/nvme0n1 set 1 esp on
sudo parted --script /dev/nvme0n1 mkpart nixos-root ext4 1025MiB 100%

sudo partprobe /dev/nvme0n1

sudo mkfs.vfat -F 32 -n NIXOS-ESP /dev/nvme0n1p1
sudo mkfs.ext4 -F -L nixos-root /dev/nvme0n1p2
```

mount:

```bash
sudo mount /dev/disk/by-label/nixos-root /mnt
sudo mkdir -p /mnt/efi
sudo mount /dev/disk/by-label/NIXOS-ESP /mnt/efi
```

確認:

```bash
lsblk -f
findmnt --real /mnt /mnt/efi
```

## 5. repository を install target へ clone する

```bash
sudo mkdir -p /mnt/home/tarutyyyne/Git
sudo git clone https://github.com/miyatarutyyy/Settings-Integration.git /mnt/home/tarutyyyne/Git/MIGRATE
```

## 6. hardware configuration を生成して repo 側へ反映する

installer 上で生成する。

```bash
sudo nixos-generate-config --root /mnt
```

生成結果を確認する。

```bash
sudo less /mnt/etc/nixos/hardware-configuration.nix
```

repo 側の T14 hardware configuration を更新する。

```bash
sudoedit /mnt/home/tarutyyyne/Git/MIGRATE/hosts/thinkpad-t14-gen5/hardware-configuration.nix
```

最低限確認・更新する項目:

- `boot.initrd.availableKernelModules`
- `boot.initrd.kernelModules`
- `boot.kernelModules`
- `boot.extraModulePackages`
- `fileSystems."/".device`
- `fileSystems."/efi".device`
- `swapDevices`
- `nixpkgs.hostPlatform`

`/efi` mountpoint は、`hosts/thinkpad-t14-gen5/default.nix` の次の設定と一致させる。

```nix
boot.loader.efi.efiSysMountPoint = "/efi";
```

## 7. NixOS を install する

```bash
sudo nixos-install \
  --flake /mnt/home/tarutyyyne/Git/MIGRATE#thinkpad-t14-gen5 \
  --root /mnt
```

install 後、`tarutyyyne` の password を設定する。

```bash
sudo nixos-enter --root /mnt -c 'passwd tarutyyyne'
```

repository の owner を通常ユーザーへ戻す。

```bash
sudo nixos-enter --root /mnt -c 'chown -R tarutyyyne:users /home/tarutyyyne/Git'
```

## 8. reboot 後に確認する

```bash
sudo reboot
```

boot 後に確認する。

```bash
hostname
nixos-version
whoami
cd /home/tarutyyyne/Git/MIGRATE
nix flake check
sudo nixos-rebuild switch --flake .#thinkpad-t14-gen5
```

desktop 実動作の確認項目:

- niri session が起動する
- Waybar が表示される
- fcitx5-skk で日本語入力できる
- hyprlock で lock できる
- swayidle が idle lock / monitor off を行う
- PipeWire audio が動く
- portal 経由の screen sharing / screenshot が動く
- Wi-Fi / Bluetooth が動く
- suspend / resume が動く
- lid close 時の挙動が許容できる
- Ollama を使う場合、`services.ollama.enable = true;` の実動作を確認する

## USB 検証との違い

この repository には `thinkpad-t14-gen5-usb` と USB 用 scripts がある。

- `hosts/thinkpad-t14-gen5-usb/`
- `scripts/prepare-nixos-usb.sh`
- `scripts/mount-prepared-nixos-usb.sh`
- `scripts/install-nixos-usb.sh`

これは内蔵 Arch Linux を消さずに USB boot で NixOS を検証するための構成である。

内蔵 SSD に本番 install する場合は、`thinkpad-t14-gen5-usb` ではなく `thinkpad-t14-gen5` を使う。

安全性を優先する場合は、先に USB 検証で T14 の display、Wi-Fi、Bluetooth、input、suspend、desktop session を確認してから、内蔵 SSD を消去する。

## 完了条件

- T14 が `thinkpad-t14-gen5` として NixOS で boot する。
- `/run/current-system` がこの repository の `.#thinkpad-t14-gen5` 由来である。
- `nix flake check` が通る。
- `sudo nixos-rebuild switch --flake .#thinkpad-t14-gen5` が通る。
- desktop session と基本 device が実機で確認済みである。
- secrets は平文で Git / Nix store に入っていない。
