# thinkpad-l480 Hyprlock

収集日: 2026-07-25
収集元ホスト: thinkpad-l480
収集者: tarutyyyne

## 収集元

- `~/.config/hypr/hyprlock.conf`

## 収集しないもの

- なし

## 秘密情報レビュー

- token/password/API key: 見つからない
- host 固有情報: 見つからない
- commit しないもの: ログイン状態、PAM 状態、認証 cache は Git 管理しない

## 現在の特徴

- lock tool は `hyprlock`
- 背景は黒単色
- 時刻を中央上寄りに大きく表示する
- password input は中央配置、black + orange `#f66e25` 系
- `hide_cursor = true`
- `ignore_empty_input = true`
- `fail_timeout = 2000`
- fade animation を有効にしている

## 統合判断

- 方針: 共通 Home Manager の `programs.hyprlock` に修正して採用する
- 共通候補: black + orange theme、時刻 label、中央 input、fail 表示
- 修正候補: font は共通 font 方針に合わせて `Noto Sans CJK JP` を維持する
- NixOS 側: `security.pam.services.hyprlock = {};` は system module で管理する

## idle 設定の確認

- `swayidle` package は方針上採用候補だが、このPCの `~/.config/systemd/user` に起動 unit は見つからない
- 実行中プロセスにも `swayidle` は見つからない
- 方針メモに従い、再現用 Home Manager では user systemd service として `swayidle` を追加する
