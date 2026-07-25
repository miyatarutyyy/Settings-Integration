# Waybar 比較

比較日: 2026-07-25

## 比較元

- `inventories/config-sources/thinkpad-l480/waybar/files/.config/waybar/config.jsonc`
- `inventories/config-sources/thinkpad-l480/waybar/files/.config/waybar/style.css`
- `inventories/config-sources/thinkpad-l480/waybar/files/.config/waybar/scripts/ime.sh`
- `inventories/config-sources/thinkpad-t14-gen5/waybar/files/.config/waybar/config`
- `inventories/config-sources/thinkpad-t14-gen5/waybar/files/.config/waybar/style.css`
- `inventories/config-sources/thinkpad-t14-gen5/waybar/files/.config/waybar/scripts/ime.sh`
- `inventories/config-sources/thinkpad-t14-gen5/waybar/files/.config/waybar/scripts/ime-toggle.sh`
- `inventories/config-sources/thinkpad-t14-gen5/waybar/files/.config/waybar/scripts/localtime-display.sh`
- `inventories/config-sources/thinkpad-t14-gen5/waybar/files/.config/waybar/scripts/localtime-refresh.sh`
- `inventories/config-sources/thinkpad-t14-gen5/waybar/files/.config/waybar/scripts/test-localtime-switch.sh`

## 2台で同じ設定

- bar は top layer / top position / height 30。
- 色は black + orange `#F66E25` 系を基調にする。
- IME 表示は `fcitx5-remote -n` を使う custom module。
- battery、network、volume を右側に表示する。
- battery には warning / critical 状態を設定する。
- network は接続中と切断状態で表示を分ける。
- volume は PulseAudio 互換 module を使うが、実体は PipeWire / WirePlumber 方針へ寄せる。

## thinkpad-l480 だけにある設定

- 中央は `clock` のみ。
- 右側は `custom/ime`, `memory`, `battery`, `network`, `pulseaudio`。
- IME 表示は `[ IME: SKK ]`, `[ IME: DIRECT ]`, `[ IME: off ]`。
- network tooltip は SSID と signal strength を表示し得る。
- volume click は `pactl set-sink-mute @DEFAULT_SINK@ toggle`。
- style は `@define-color` を使い、比較的短い。

## thinkpad-t14-gen5 だけにある設定

- `style` と custom script に `/home/trt-ryzen7` の絶対パスがある。
- 左側に Sway 用の `sway/workspaces`, `sway/mode`, `sway/scratchpad` がある。
- 中央は `custom/localtime` と `custom/ime`。
- `custom/localtime` は cache が新しければ cache の timezone、古ければ OS timezone を表示する。
- `localtime-refresh.sh` は GeoClue を優先し、失敗時に iwd / BeaconDB fallback を試す。
- `test-localtime-switch.sh` は mock coordinates で timezone 切り替えを検証する。
- IME 表示は click で `skk` と `keyboard-us` を切り替える。
- `power-profiles-daemon` module がある。
- network tooltip は interface、SSID、IPv4、gateway を表示し得る。
- style は workspace、tooltip、power profile、audio input など追加 module 向けの指定が多い。

## 採用する設定

- 共通 Home Manager: top bar / height 30。
- 共通 Home Manager: clock、IME、memory、battery、network、volume の基本表示。
- 共通 Home Manager: black + orange theme。
- 共通 Home Manager: IME 状態は `fcitx5-remote -n` から JSON を返す。
- 共通 Home Manager: volume click は `wpctl` を使う。

## 修正して採用する設定

- IME 表示は両ホストの表記を統一する。候補は `[ IME : SKK ]` と `[ IME : DIRECT ]`。
- IME class 名は CSS と一致するように統一する。候補は `ime-skk`, `ime-direct`, `ime-off`, `ime-other`。
- L480 側の `pactl` は PipeWire / WirePlumber 方針に合わせて `wpctl` へ置き換える。
- T14 側の絶対パスは Home Manager の生成 script path に置き換える。
- network tooltip は秘密値そのものは含まないが、画面共有時に SSID / IP / gateway が出るため、共通設定では控えめにする。
- `power-profiles-daemon` はホスト別の電源管理方針と合わせて、共通化するか host module 側で採用するかを分ける。

## 採用しない設定

- Sway 用の `sway/workspaces`, `sway/mode`, `sway/scratchpad` は niri 主環境の共通 Waybar 設定には入れない。
- T14 側の `/home/trt-ryzen7` 絶対パスはそのまま採用しない。
- commit しない cache、backup file、temporary style file、現在地 state は採用しない。

## 保留する設定

- `custom/localtime` と `localtime-refresh.sh` は便利だが、位置情報取得、cache、GeoClue、iwd / BeaconDB、`tzf` の依存を含むため別作業に分ける。
- IME click toggle は便利だが、誤操作や実機での `fcitx5-remote -s` の挙動確認後に採用する。
- niri workspace 表示は、niri 側で Waybar module をどう扱うか確認してから設計する。
- audio input / mic 表示は、実際に必要な表示と WirePlumber module への移行可否を確認してから扱う。

## 統合先

- Home Manager: `programs.waybar.settings.mainBar`、`programs.waybar.style`、managed custom script。
- Home Manager: `home.packages` に Waybar custom script が呼ぶ CLI を追加する場合がある。
- NixOS module: `power-profiles-daemon` など system service が必要な module は host 方針と合わせて検討する。
- host 別設定: power profile、battery 名、monitor / workspace 表示、公開画面向け tooltip 方針。

## secrets と host 固有情報

- 収集済み Waybar 設定に token/password/API key は見つからない。
- network tooltip は SSID、IP address、gateway を表示し得るが、設定ファイル内に実値はない。
- T14 側の localtime cache は latitude / longitude を含むため未収集であり、Git 管理しない。
- T14 側の `/home/trt-ryzen7` は移行元 Arch 環境のパスであり、最終 Home Manager 設定には残さない。

## 未確認

- niri session 上で現在の共通 Waybar 設定が期待通り表示されるか。
- Waybar で niri workspace を表示する標準的な module / script を採用するか。
- IME class 名と CSS が両ホストで期待通り対応するか。
- `fcitx5-remote -s skk` / `keyboard-us` による click toggle を共通採用してよいか。
- `custom/localtime` の GeoClue、iwd / BeaconDB fallback、`tzf` を NixOS 上でどう再現するか。
- `power-profiles-daemon` を TLP 採用候補の `thinkpad-l480` とどう両立させるか。
