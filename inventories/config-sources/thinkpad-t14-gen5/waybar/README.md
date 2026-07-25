# thinkpad-t14-gen5 Waybar

収集日: 2026-07-25
収集元ホスト: thinkpad-t14-gen5
収集時の実ホスト名: trt-arch
収集者: tarutyyyne

## 収集元

- `~/.config/waybar/config`
- `~/.config/waybar/style.css`
- `~/.config/waybar/scripts/ime.sh`
- `~/.config/waybar/scripts/ime-toggle.sh`
- `~/.config/waybar/scripts/localtime-display.sh`
- `~/.config/waybar/scripts/localtime-refresh.sh`
- `~/.config/waybar/scripts/test-localtime-switch.sh`

## 収集しないもの

- `~/.config/waybar/config~`: backup file
- `~/.config/waybar/style.css~`: backup file
- `~/.config/waybar/scripts/ime.sh~`: backup file
- `~/.config/waybar/scripts/ime-toggle.sh~`: backup file
- `~/.config/waybar/tmpstyle.css`: temporary style file
- `~/.cache/waybar-localtime/state.json`: 位置情報由来の latitude/longitude を含む state

## 秘密情報レビュー

- token/password/API key: 見つからない
- host 固有情報: `style` と custom script の path が `/home/trt-ryzen7` を参照する
- 位置情報: `localtime-refresh.sh` は GeoClue または iwd/BeaconDB で latitude/longitude を取得して cache へ書くが、cache 本体は未収集
- network 情報: `network.tooltip-format` は表示時に SSID、IPv4、gateway を出し得るが、設定ファイル内に実値はない
- commit しないもの: backup、temporary file、cache、現在地 state は未収集

危険語検索では、network tooltip の `{essid}`、localtime helper の latitude/longitude/GeoClue/BeaconDB 処理、mock test 座標に該当した。実際の SSID、IP、gateway、現在地 cache、token/password/API key は見つからない。

## 現在の特徴

- Sway 用 module として `sway/workspaces`、`sway/mode`、`sway/scratchpad` を使う。
- 中央に `custom/localtime` と `custom/ime` を表示する。
- `custom/localtime` は cache が新しければ cache の timezone、古ければ OS timezone を使う。
- `localtime-refresh.sh` は GeoClue を優先し、失敗時に iwd/BeaconDB fallback を試す。
- `test-localtime-switch.sh` は mock coordinates で Tokyo/Bangkok の timezone 切り替えをテストする。
- `custom/ime` は `fcitx5-remote -n` を見て `[ IME : FCITX5 ]` または `[ IME : SKK ]` を表示する。
- IME 表示は click で `skk` と `keyboard-us` を切り替える。
- 色は black + orange `#F66E25` を基調にしている。
- network tooltip は SSID、IPv4、gateway を表示し得る。

## 統合判断

- 方針: 修正して Home Manager の Waybar 設定へ採用候補。
- 共通候補: black + orange theme、battery/network/volume 表示、IME 表示、`wpctl` への音量操作。
- niri 向け修正候補: `sway/*` module は niri 用 module または非 compositor 依存 module へ置き換える。
- 修正候補: `/home/trt-ryzen7` の absolute path は Home Manager の生成 script path に置き換える。
- 修正候補: network tooltip に SSID/IP/GW を常時出すか、公開画面で隠すかを運用方針として決める。
- 保留候補: dynamic localtime は便利だが、位置情報取得と cache の扱いを NixOS/secret-safe 方針に合わせて再設計する。

## 未確認

- niri session 上で `sway/*` module がどう表示されるか。
- niri 向けの workspace 表示方式。
- `power-profiles-daemon` を TLP 採用ホストでも表示するか。
- `localtime-refresh.sh` の GeoClue、iwd/BeaconDB fallback、`tzf` path の NixOS 上での再現方法。
- Waybar localtime refresh を systemd user timer で管理するか。
- IME click toggle を共通採用するか。
