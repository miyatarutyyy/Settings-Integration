# thinkpad-t14-gen5 niri

収集日: 2026-07-25
収集元ホスト: thinkpad-t14-gen5
収集時の実ホスト名: trt-arch
収集者: tarutyyyne

## 収集元

- `~/.config/niri/config.kdl`

## 秘密情報レビュー

- token/password/API key: 見つからない
- host 固有情報: コメントアウトされた `eDP-1` 出力例に解像度、refresh rate、scale、position が含まれる
- commit しないもの: cache、session state、screenshot 画像は未収集

危険語検索では、password manager や secret を説明するコメント例にだけ該当語が出ており、秘密値そのものは見つからない。

## 現在の特徴

- `spawn-at-startup "waybar"` で Waybar を起動する。
- touchpad は tap と natural-scroll を有効にしている。
- terminal は `Mod+T` で `alacritty` を起動する。
- launcher は `Mod+D` で `fuzzel` を起動する。
- lock は `Super+Alt+L` で `swaylock` を起動する。
- audio key は `wpctl`、media key は `playerctl`、brightness key は `brightnessctl` を使う。
- screenshot は niri builtin action を使う。
- focus ring は active `#7fc8ff`、inactive `#505050`。
- border は `off`。

## 統合判断

- 方針: 修正して Home Manager の niri user config へ採用候補。
- 共通候補: 入力設定、Waybar 起動、基本 keybind、`wpctl`/`playerctl`/`brightnessctl` の操作。
- ホスト別候補: 出力設定、scale、monitor position。
- 修正候補: launcher を標準方針の rofi/fuzzel どちらへ寄せるか決める。lock は NixOS 側 PAM と合わせて hyprlock/swaylock の方針を確認する。

## 未確認

- 実際に niri session として常用されているか。
- `niri msg outputs` での現在の monitor 名、mode、scale。
- `fuzzel` を標準採用するか、既存判断どおり rofi に寄せるか。
- lock command と PAM/fingerprint の実動作。
- Waybar、portal、XWayland bridge との実動作。
