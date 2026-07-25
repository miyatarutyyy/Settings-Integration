# niri 比較

比較日: 2026-07-25

## 比較元

- `inventories/config-sources/thinkpad-l480/niri/files/.config/niri/config.kdl`
- `inventories/config-sources/thinkpad-t14-gen5/niri/files/.config/niri/config.kdl`

## 2台で同じ設定

- `numlock` を起動時に有効化する。
- touchpad は `tap` と `natural-scroll` を有効化する。
- `layout.gaps` は `16`。
- `default-column-width` は `proportion 0.5`。
- `spawn-at-startup "waybar"` で Waybar を起動する。
- screenshot 保存先は `~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png`。
- `Mod+T` は `alacritty` を起動する。
- 音量操作は `wpctl`、メディア操作は `playerctl`、輝度操作は `brightnessctl` を使う。
- workspace、column、window 移動の基本 bind は niri default 風の `Mod+H/J/K/L`、矢印、`Mod+1..9` を中心にしている。
- 明示的な有効 output 設定はなく、`eDP-1` の monitor 設定例はコメントアウト状態。

## thinkpad-l480 だけにある設定

- `layout.background-color "#000000"`。
- `focus-ring.width 3`、active `#F66E25`、inactive `#000000`。
- `overview.backdrop-color "#000000"`。
- `spawn-at-startup "fcitx5" "-d"`。
- `prefer-no-csd` を有効化。
- `Mod+D` は `rofi -show drun`。
- `Super+Alt+L` は `hyprlock`。
- `Mod+Shift+R` は `switch-preset-column-width-back`、`Mod+Ctrl+Shift+R` は `switch-preset-window-height`。
- `Mod+M` は `maximize-window-to-edges`。

## thinkpad-t14-gen5 だけにある設定

- `focus-ring.width 4`、active `#7fc8ff`、inactive `#505050`。
- `border.width 4`。ただし `border` は `off`。
- `Mod+D` は `fuzzel`。
- `Super+Alt+L` は `swaylock`。
- `Mod+Shift+R` は `switch-preset-window-height`。

## 採用する設定

- 共通 Home Manager: input の `numlock`、touchpad の `tap` と `natural-scroll`。
- 共通 Home Manager: `layout.gaps 16`、`default-column-width { proportion 0.5; }`。
- 共通 Home Manager: `spawn-at-startup "waybar"`。
- 共通 Home Manager: `Mod+T` の `alacritty`、基本 window/workspace navigation、screenshot bind。
- 共通 Home Manager: `wpctl`、`playerctl`、`brightnessctl` による hardware/media key 操作。

## 修正して採用する設定

- IME 起動は L480 側の `spawn-at-startup "fcitx5" "-d"` を候補にする。ただし、Home Manager/systemd user service で管理する案と比較してから決める。
- launcher は L480 側の `rofi -show drun` と T14 側の `fuzzel` が分岐している。既存判断で rofi を採用するなら `Mod+D` は rofi に統一する。
- lock は L480 側が `hyprlock`、T14 側が `swaylock`。NixOS 側の PAM、fingerprint、lock screen 方針に合わせ、主環境では hyprlock 候補として扱う。
- focus ring と background は L480 側の black + orange 方針を候補にする。ただし Waybar、hyprlock、terminal theme と合わせて確認する。
- `prefer-no-csd` は L480 側を候補にする。GTK/Qt アプリの見た目と focus ring 表示を実機で確認してから共通化する。

## 採用しない設定

- コメントアウトされた `eDP-1` output 設定例は、そのまま共通設定には入れない。
- niri テンプレート由来の説明コメントは、最終的な Home Manager 設定では必要最小限に整理する。
- T14 側の `swaylock` bind は、Sway 参照設定としては残せるが、niri 主環境の共通設定としては未採用候補。

## 統合先

- Home Manager: niri user config、keybind、startup command、theme 相当。
- NixOS module: `programs.niri.enable`、portal、PipeWire、lock 認証に関わる PAM、必要 package の有効化。
- host 別設定: monitor/output 名、mode、scale、position。
- 手動または別管理: screenshot 画像、session state、cache。

## secrets と host 固有情報

- 収集済み `config.kdl` には token/password/API key などの秘密値は見つからない。
- monitor/output 設定はホスト固有として扱い、実機の `niri msg outputs` 結果で確認してから host module 側へ分ける。
- screenshot 保存先は秘密値ではないが、生成画像そのものは commit 対象外。

## 未確認

- 両ホストでの `niri msg validate` 結果。
- `fcitx5 -d` を niri startup に置くか、systemd user/Home Manager 管理にするか。
- rofi と fuzzel のどちらを標準 launcher にするか。
- hyprlock と swaylock のどちらを標準 lock command にするか。
- `prefer-no-csd` のアプリ別影響。
- 外部 monitor 接続時の output 名、mode、scale、position。
