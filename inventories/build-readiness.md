# NixOS build readiness

作成日: 2026-07-25

目的: 現在の flake を実機で `nix flake check` / `nixos-rebuild build` できる状態へ近づけるため、未実装項目と確認順序を整理する。

## 現在できていること

- `flake.nix` は `thinkpad-l480` と `thinkpad-t14-gen5` の `nixosConfigurations` を定義している。
- `flake.lock` は作成済み。
- 共通 NixOS module は flakes、locale、user、iwd、OpenSSH、desktop runtime を持つ。
- 共通 Home Manager module は shell、Git/SSH、development tools、niri、Waybar、hyprlock、swayidle を持つ。
- `thinkpad-l480` と `thinkpad-t14-gen5` の host module は hostname、stateVersion、boot loader、CPU microcode の最小設定を持つ。

## build 確認結果

- 2026-07-26 に Arch 側作業環境で Nix 2.35.1 を導入し、Nix daemon が active であることを確認した。
- `nix --extra-experimental-features 'nix-command flakes' build .#nixosConfigurations.thinkpad-l480.config.system.build.toplevel` は成功した。
- `nix flake check` は、`thinkpad-t14-gen5` を `nixosConfigurations` に公開したままだと root filesystem 未指定で失敗したため、T14 の hardware configuration を追加した。
- `nixos-rebuild build --flake .#thinkpad-t14-gen5` の結果は未確認。
- Home Manager option 名、package 名、niri / hyprlock / Waybar / swayidle の組み合わせは `thinkpad-l480` の toplevel build では評価・生成まで通った。

## host 共通で必要な未実装項目

- `fileSystems` を host module に入れるか、実機生成の `hardware-configuration.nix` を import するかを決める。
- root filesystem、boot filesystem、swap の宣言を実機確認後に追加する。
- kernel modules、initrd modules、firmware、GPU、touchpad、trackpoint など hardware-specific 設定を実機生成ファイルと照合する。
- secrets 管理方式は現フェーズでは確定しない。まず秘密値を Git / Nix store に入れない境界だけ守る。
- SSH/GPG/GitHub CLI/browser/keyring/Codex/Claude などのログイン状態は、初回 build の必須条件に含めず、移行直前または移行後に再ログイン / 暗号化バックアップ方針を決める。
- 実機 build 後、niri session、Waybar、fcitx5-skk、hyprlock、swayidle、portal、PipeWire を確認する。

## thinkpad-l480

既知:

- root は ext4、`/boot` は vfat。
- inventory では swap device は観測されておらず、host module では `zramSwap.enable = true;` を採用済み。
- systemd-boot と EFI variable 書き込みは既存 NixOS 側の方針に合わせて有効化済み。
- Intel CPU microcode は有効化済み。

未実装 / 要確認:

- 現在の `/etc/nixos/hardware-configuration.nix` 相当を収集または再生成する。
- `fileSystems."/"` と `fileSystems."/boot"` を UUID 付きで宣言するか、収集した hardware configuration から import する。
- `/boot` の UUID、root の UUID、filesystem options を root 権限で再確認する。
- `thinkpad-l480` 実機で `nixos-rebuild build --flake .#thinkpad-l480` を実行する。
- `swayidle` service が user graphical session で起動するか確認する。
- lid close 時の lock-before-suspend が必要か実機で確認する。

## thinkpad-t14-gen5

既知:

- 現在は Arch Linux 移行元。
- NixOS 移行後の hostname は `thinkpad-t14-gen5`。
- AMD CPU microcode は有効化済み。
- boot loader は systemd-boot 候補。

未実装 / 要確認:

- Arch source system 上で `nixos-generate-config --show-hardware-config`、`lsblk -f`、`findmnt --real`、`bootctl status`、`lspci -nnk` を確認し、`hosts/thinkpad-t14-gen5/hardware-configuration.nix` を追加した。
- root filesystem は ext4 `c1e9791a-ef8d-4a06-8342-795046372c11`、ESP は vfat `D94E-D64E` mounted at `/efi` として宣言済み。
- swap device は観測されておらず、`swapDevices = [ ];` として宣言済み。
- NixOS install 時には `/efi` と root filesystem が同じ構成でよいか再確認する。
- Qualcomm Wi-Fi、AMD GPU、firmware、Bluetooth、power management を実機で確認する。
- `nixos-rebuild build --flake .#thinkpad-t14-gen5` は、実機NixOS環境ではまだ未実行。

## 推奨する確認順序

1. `thinkpad-l480` で repository を最新化する。
2. 任意の Nix 環境で `nix flake check` を実行する。
3. 任意の Nix 環境で `nix build .#nixosConfigurations.thinkpad-l480.config.system.build.toplevel` を実行する。
4. `thinkpad-l480` 実機で `nixos-rebuild build --flake .#thinkpad-l480` を実行する。
5. 失敗した場合、package rename、option rename、module import のどれかに分類して最小修正する。
6. build が通ったら、実機 session で niri、Waybar、fcitx5、hyprlock、swayidle を確認する。
7. `thinkpad-t14-gen5` は NixOS install 前に root/ESP UUID と `/efi` mountpoint を再確認する。

## 実行コマンド

`thinkpad-l480`:

```bash
git pull --rebase=false origin master
nix flake check
nix build .#nixosConfigurations.thinkpad-l480.config.system.build.toplevel
nixos-rebuild build --flake .#thinkpad-l480
```

`thinkpad-t14-gen5` の NixOS install 準備時:

```bash
sudo nixos-generate-config --root /mnt
sudo lsblk -f
sudo bootctl status
sudo efibootmgr -v
nixos-rebuild build --flake .#thinkpad-t14-gen5
```

## secrets 方針

- 秘密値そのものはこの repository に平文で入れない。
- SSH private key、GPG private key、browser profile、GNOME keyring、Claude/Codex login state は Nix store に入れない。
- OAuth token は原則として移行後に再ログインする。
- Wi-Fi profile は SSID/PSK を文書化せず、必要なら暗号化バックアップまたは手動再設定にする。
- project `.env` は project 側で扱い、この共通 dotfiles repository には含めない。
- `sops-nix` などの宣言的 secrets 管理は、最初の host build が通った後に必要な secret だけを対象として設計する。

## 完了条件

- `thinkpad-l480` の toplevel build が通る。
- `thinkpad-l480` の desktop session で niri / Waybar / fcitx5 / hyprlock / swayidle が確認済みになる。
- `thinkpad-t14-gen5` の filesystem と hardware configuration が NixOS install 前提で確定する。
- secrets は、値を Git / Nix store に入れない境界を維持し、詳細設計は別作業として保留されている。
