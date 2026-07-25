# thinkpad-l480 Waybar

収集日: 2026-07-25
収集元ホスト: thinkpad-l480
収集者: tarutyyyne

## 収集元

- `~/.config/waybar/config.jsonc`
- `~/.config/waybar/style.css`
- `~/.config/waybar/scripts/ime.sh`

注記: `files/.config/waybar/config.jsonc` は commit 前検証のため、空白のみ正規化した。

## 収集しないもの

- `~/.config/waybar/config.jsonc~`: backup file
- `~/.config/waybar/style.css~`: backup file
- `~/.config/waybar/scripts/ime.sh~`: backup file

## 秘密情報レビュー

- token/password/API key: 見つからない
- host 固有情報: `tooltip-format-wifi` が SSID を表示し得るが、実際の SSID 値は含まない
- commit しないもの: backup file、cache/state、位置情報を含む可能性がある状態ファイルは未収集

## 現在の特徴

- bar は top layer / top position / height 30
- module は center に clock、right に IME、memory、battery、network、pulseaudio
- IME 表示は `fcitx5-remote -n` を使う `scripts/ime.sh` で JSON を返す
- 色は black + orange。direct IME は赤、warning/critical/muted は別色で表示
- network tooltip は SSID と signal strength を表示
- volume click は `pactl set-sink-mute @DEFAULT_SINK@ toggle`

## 統合判断

- 方針: 修正して共通 Home Manager 設定へ採用候補
- 共通候補: top bar、clock、memory、battery、network、volume、IME indicator、black + orange theme
- 修正候補: volume click は PipeWire/WirePlumber 方針に合わせて `wpctl` へ寄せる
- 修正候補: `scripts/ime.sh` は Home Manager では inline script または managed script として再現する
- 未確認: niri 上での表示、IME class 名と CSS の対応、SSID tooltip を共通設定で維持するか
