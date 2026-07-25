# Host configuration plan

作成日: 2026-07-25

目的: 実機由来の hardware configuration、filesystem、boot、swap、host 固有設定をどのファイルへ取り込むかを決める。

## 基本方針

- 共通設定は `modules/nixos/` と `home/modules/` に置く。
- hostname、CPU microcode、boot、filesystem、GPU、network device、power management など実機依存の設定は `hosts/<hostname>/` に置く。
- `nixos-generate-config` が生成する内容は無条件に共通化しない。
- UUID、device path、kernel module、filesystem option は host 固有情報として扱う。
- 秘密値、Wi-Fi PSK、login token、private key、keyring は hardware configuration には含めない。

## 推奨ファイル構成

各 host は次の分割にする。

```text
hosts/<hostname>/
  default.nix
  hardware.nix
```

`default.nix`:

- hostname
- `system.stateVersion`
- boot loader 方針
- CPU microcode
- zram / OOM / power management など、判断して採用した host policy
- `./hardware.nix` の import

`hardware.nix`:

- `fileSystems`
- `swapDevices`
- `boot.initrd.availableKernelModules`
- `boot.initrd.kernelModules`
- `boot.kernelModules`
- `boot.extraModulePackages`
- generated hardware configuration 由来の hardware-specific options

将来、host 固有設定が大きくなった場合だけ、次のようにさらに分ける。

```text
hosts/<hostname>/
  default.nix
  hardware.nix
  power.nix
  graphics.nix
```

初期段階では分割しすぎず、`default.nix` と `hardware.nix` に留める。

## hardware.nix の取り込みルール

- 実機で `nixos-generate-config` を実行して生成された `hardware-configuration.nix` を元にする。
- 生成ファイルをそのまま貼る前に、コメント、古い option、不要な mount、生成時だけの一時 mount が混じっていないか確認する。
- `fileSystems` の UUID は、実機の `lsblk -f` と照合してから採用する。
- swap がない場合は `swapDevices = [ ];` と明示するか、zram 方針に合わせて host policy 側へ寄せる。
- root 以外の外付け disk、USB、temporary mount、backup disk は初期 hardware config に入れない。
- secrets や credential values は記録しない。

## thinkpad-l480

現在の状態:

- `hosts/thinkpad-l480/default.nix` は hostname、stateVersion、systemd-boot、Intel microcode、zram、oomd を持つ。
- inventory では root は ext4、`/boot` は vfat。
- inventory では disk swap は観測されていない。

次に行うこと:

- `hosts/thinkpad-l480/default.nix` に `./hardware.nix` import を追加する。
- `hosts/thinkpad-l480/hardware.nix` を新規作成する。
- `hardware.nix` は実機の `/etc/nixos/hardware-configuration.nix` または `nixos-generate-config` 結果から作る。
- root UUID、boot UUID、filesystem option を実機で再確認する。
- `swapDevices = [ ];` を `hardware.nix` に置くか、zram 方針だけで足りるか build 結果で確認する。

未確認のまま推測で入れないもの:

- root filesystem UUID
- boot filesystem UUID
- initrd kernel modules
- external disk mount
- Wi-Fi profile

## thinkpad-t14-gen5

現在の状態:

- `hosts/thinkpad-t14-gen5/default.nix` は hostname、stateVersion、systemd-boot、AMD microcode を持つ。
- 現在の移行元は Arch Linux。
- NixOS install 先の filesystem 構成はまだ未確定。

次に行うこと:

- NixOS install 時に `nixos-generate-config --root /mnt` を実行する。
- 生成された hardware configuration を `hosts/thinkpad-t14-gen5/hardware.nix` として取り込む。
- `hosts/thinkpad-t14-gen5/default.nix` に `./hardware.nix` import を追加する。
- ESP mountpoint が `/boot` か `/efi` かを install 方針として決める。
- swap なし、zram、disk swap のどれにするかを決める。

未確認のまま推測で入れないもの:

- NixOS install 後の root filesystem UUID
- EFI system partition mountpoint
- generated initrd modules
- host 固有 monitor/output 設定
- Wi-Fi profile

## 収集コマンド

`thinkpad-l480` の既存 NixOS 側:

```bash
sudo cp /etc/nixos/hardware-configuration.nix /tmp/thinkpad-l480-hardware-configuration.nix
lsblk -f
findmnt --real
swapon --show
```

`thinkpad-t14-gen5` の NixOS install 時:

```bash
sudo nixos-generate-config --root /mnt
sudo cp /mnt/etc/nixos/hardware-configuration.nix /tmp/thinkpad-t14-gen5-hardware-configuration.nix
lsblk -f
findmnt --real
swapon --show
```

## 取り込み後の検証

1. `nix flake check`
2. `nixos-rebuild build --flake .#thinkpad-l480`
3. `nixos-rebuild build --flake .#thinkpad-t14-gen5`
4. 実機で boot、network、display、input、sound、suspend/resume を確認する。

`thinkpad-t14-gen5` は install 先が未確定の間、build が通らない可能性を許容する。先に `thinkpad-l480` を build 成功の基準 host にする。
