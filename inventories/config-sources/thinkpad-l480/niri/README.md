# thinkpad-l480 niri

収集日: 2026-07-25
収集元ホスト: thinkpad-l480
収集者: tarutyyyne

## 収集元

- `~/.config/niri/config.kdl`

## 収集しないもの

- `~/.config/niri/config.kdl~`: backup file
- `~/.config/niri/#config.kdl#`: editor temporary file

## 秘密情報レビュー

- token/password/API key: 見つからない
- host 固有情報: 明示的な有効 output 設定はない。`eDP-1` の設定例はコメントアウト状態
- commit しないもの: backup file と editor temporary file は未収集

## 現在の特徴

- touchpad は tap と natural-scroll を有効化
- keyboard は numlock を起動時に有効化
- layout gap は 16、background は black、focus ring の active color は orange
- 起動時に `waybar` と `fcitx5 -d` を起動
- `prefer-no-csd` を有効化
- screenshot 保存先は `~/Pictures/Screenshots/`
- 主要 bind は `Mod+T` が Alacritty、`Mod+D` が Rofi、`Super+Alt+L` が Hyprlock
- 音量操作は `wpctl`、輝度操作は `brightnessctl`

## 統合判断

- 方針: 修正して共通 Home Manager 設定へ採用候補
- 共通候補: input、layout、focus ring、起動アプリ、基本 keybind
- ホスト別候補: output/monitor layout、screenshot 保存先の運用
- 未確認: 実機での `niri msg validate`、Waybar/fcitx5 起動順、lock hotkey の overlay 表示名、外部モニター接続時の挙動
