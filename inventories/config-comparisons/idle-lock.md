# Idle / Lock 比較

比較日: 2026-07-25

## 比較元

- `inventories/config-sources/thinkpad-l480/hyprlock/files/.config/hypr/hyprlock.conf`
- `inventories/config-sources/thinkpad-l480/niri/files/.config/niri/config.kdl`
- `inventories/thinkpad-l480-nixos.md`
- `inventories/trt-ryzen7-archlinux.md`
- `inventories/dotfiles-decisions.md`

## thinkpad-l480

- lock は `hyprlock` を使う。
- `~/.config/hypr/hyprlock.conf` が存在する。
- niri の手動 lock bind は `Super+Alt+L` で `hyprlock` を起動する。
- `swayidle` package は確認済みだが、ユーザー設定や systemd user unit は見つからない。
- 実行中プロセスにも `swayidle` は見つからない。

## trt-ryzen7 / Arch Linux

- lock は `swaylock` / `gtklock` の痕跡がある。
- `~/.local/bin/lock.sh` と `~/.config/swaylock/config` がある。
- 最終構成では NixOS + niri + hyprlock 方針へ寄せるため、そのまま採用しない。

## 採用する設定

- 共通 Home Manager: `programs.hyprlock`。
- 共通 Home Manager: `swayidle` を user systemd service として起動する。
- 共通 Home Manager: 手動 lock は niri の `Super+Alt+L` で `hyprlock`。
- NixOS module: `security.pam.services.hyprlock = {};`。

## 修正して採用する設定

- thinkpad-l480 の `hyprlock.conf` は Home Manager の `programs.hyprlock.settings` に変換する。
- idle 管理は実機に設定がないため、方針メモに従って新規に `swayidle` service を作る。
- 自動 lock は 10分、自動 monitor off は 15分とする。
- monitor off/on は niri の `power-off-monitors` / `power-on-monitors` action を使う。
- suspend 前は `before-sleep` で `hyprlock` を起動する。

## 採用しない設定

- Arch 側の `swaylock` / `gtklock` 痕跡は共通設定には入れない。
- PAM 設定やログイン状態、認証 cache は Git 管理しない。

## 未確認

- `swayidle` の idle inhibit が niri session 上で期待通り効くか。
- `before-sleep` で `hyprlock` が画面表示完了してから suspend に入るか。
- laptop lid close 時の lock-before-suspend を logind/systemd sleep hook で補強する必要があるか。
