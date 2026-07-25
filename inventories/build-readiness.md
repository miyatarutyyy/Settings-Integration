# NixOS build readiness

作成日: 2026-07-25

目的: 現在の flake を実機で `nix flake check` / `nixos-rebuild build` できる状態へ近づけるため、未実装項目と確認順序を整理する。

## 現在できていること

- `flake.nix` は `thinkpad-t14-gen5` と `thinkpad-l480` の `nixosConfigurations` を定義している。
- `flake.lock` は作成済み。
- 共通 NixOS module は flakes、locale、user、iwd、OpenSSH、desktop runtime を持つ。
- 共通 Home Manager module は shell、Git/SSH、development tools、niri、Waybar、hyprlock、swayidle を持つ。
- `thinkpad-l480` と `thinkpad-t14-gen5` の host module は hostname、stateVersion、boot loader、CPU microcode の最小設定を持つ。

## まだ build 可否が未確認

- この Arch 側作業環境には `nix` / `nixos-rebuild` がないため、flake 評価は未実施。
- `nix flake check` の結果は未確認。
- `nixos-rebuild build --flake .#thinkpad-l480` の結果は未確認。
- `nixos-rebuild build --flake .#thinkpad-t14-gen5` の結果は未確認。
- Home Manager option 名、package 名、niri / hyprlock / Waybar / swayidle の組み合わせが現在の nixpkgs で通るか未確認。

## host 共通で必要な未実装項目

- `fileSystems` を host module に入れるか、実機生成の `hardware-configuration.nix` を import するかを決める。
- root filesystem、boot filesystem、swap の宣言を実機確認後に追加する。
- kernel modules、initrd modules、firmware、GPU、touchpad、trackpoint など hardware-specific 設定を実機生成ファイルと照合する。
- secrets 管理方式を確定する。初期候補は `sops-nix` だが、鍵と暗号化ファイルはまだ未作成。
- SSH/GPG/GitHub CLI/browser/keyring/Codex/Claude などのログイン状態は Nix store に入れず、再ログインまたは暗号化バックアップ方針に分ける。
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
- `nixos-rebuild build --flake .#thinkpad-l480` を実行する。
- `swayidle` service が user graphical session で起動するか確認する。
- lid close 時の lock-before-suspend が必要か実機で確認する。

## thinkpad-t14-gen5

既知:

- 現在は Arch Linux 移行元。
- NixOS 移行後の hostname は `thinkpad-t14-gen5`。
- AMD CPU microcode は有効化済み。
- boot loader は systemd-boot 候補。

未実装 / 要確認:

- NixOS install 時に `nixos-generate-config` で `hardware-configuration.nix` を生成する。
- EFI system partition、root filesystem、swap の最終構成を決める。
- `/efi` または `/boot` の実際の mountpoint と bootloader entry を root 権限で確認する。
- Qualcomm Wi-Fi、AMD GPU、firmware、Bluetooth、power management を実機で確認する。
- `nixos-rebuild build --flake .#thinkpad-t14-gen5` は、インストール先 filesystem 情報を入れるまで通らない可能性が高い。

## 推奨する確認順序

1. `thinkpad-l480` で repository を最新化する。
2. `thinkpad-l480` で `nix flake check` を実行する。
3. `thinkpad-l480` で `nixos-rebuild build --flake .#thinkpad-l480` を実行する。
4. 失敗した場合、package rename、option rename、module import のどれかに分類して最小修正する。
5. build が通ったら、実機 session で niri、Waybar、fcitx5、hyprlock、swayidle を確認する。
6. `thinkpad-t14-gen5` は NixOS install 方針と filesystem 情報を確定してから build 対象として仕上げる。

## 実行コマンド

`thinkpad-l480`:

```bash
git pull --rebase=false origin master
nix flake check
nixos-rebuild build --flake .#thinkpad-l480
```

`thinkpad-t14-gen5` の NixOS install 準備時:

```bash
sudo nixos-generate-config --root /mnt
sudo lsblk -f
sudo bootctl status
sudo efibootmgr -v
```

## secrets 方針

- 秘密値そのものはこの repository に平文で入れない。
- SSH private key、GPG private key、browser profile、GNOME keyring、Claude/Codex login state は Nix store に入れない。
- OAuth token は原則として移行後に再ログインする。
- Wi-Fi profile は SSID/PSK を文書化せず、必要なら暗号化バックアップまたは手動再設定にする。
- project `.env` は project 側で扱い、この共通 dotfiles repository には含めない。

## 完了条件

- `thinkpad-l480` の build が通る。
- `thinkpad-l480` の desktop session で niri / Waybar / fcitx5 / hyprlock / swayidle が確認済みになる。
- `thinkpad-t14-gen5` の filesystem と hardware configuration が NixOS install 前提で確定する。
- secrets の移行方法が、再ログイン、暗号化バックアップ、sops 管理のどれかに分類済みになる。
