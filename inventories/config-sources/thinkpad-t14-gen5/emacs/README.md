# thinkpad-t14-gen5 Emacs

収集日: 2026-07-26
収集元ホスト: thinkpad-t14-gen5
収集元OS: Arch Linux

## 収集元

- `~/.emacs.d/init.el`
- `~/.emacs.d/early-init.el`
- `~/.emacs.d/theme/my-theme-theme.el`
- `~/.config/systemd/user/emacs.service`
- `~/nil/emacs/custom.el`

## 収集ファイル

- `files/.emacs.d/init.el`
- `files/.emacs.d/early-init.el`
- `files/.emacs.d/theme/my-theme-theme.el`
- `files/.config/systemd/user/emacs.service`
- `files/nil/emacs/custom.el`

## 秘密情報レビュー

- token/password/API key: 値は収集していない。
- `init.el` は `auth-source` から `INIAD_OPENAI_API_KEY` を読むが、秘密値は `~/.authinfo.gpg` 側にあり、この収集には含めない。
- `~/.authinfo.gpg` は存在するが、暗号化 credential として扱い、内容は Git 管理しない。
- cookie/session: `~/.emacs.d/request/curl-cookie-jar` は収集しない。

## commit しないもの

- `~/.authinfo.gpg`
- `~/.emacs.d/elpa/`
- `~/.emacs.d/straight/`
- `~/.emacs.d/eln-cache/`
- `~/.emacs.d/auto-save-list/`
- `~/.emacs.d/transient/`
- `~/.emacs.d/tree-sitter/*.so`
- `~/.emacs.d/.emacs.desktop`
- `~/.emacs.d/.emacs.desktop.lock`
- `~/.emacs.d/recentf`
- `~/.emacs.d/places`
- `~/.emacs.d/tramp`
- `~/.emacs.d/request/curl-cookie-jar`
- `~/.emacs.d/nskk/dict-cache.eld`

## 現在の特徴

- `straight.el` と `use-package` で Emacs package を管理している。
- 独自 theme は `~/.emacs.d/theme/` から `my-theme` として読み込む。
- 日本語入力は Emacs 内で `nskk` を使う。
- Emacs daemon は user systemd service で起動し、IME 関連環境変数を無効化している。
- AI 関連設定は `auth-source` 経由で API key を参照する。

## 統合判断

- 方針: まず参照用設定として収集し、Home Manager 統合時に package 宣言、daemon unit、secret 参照を分離する。
- 未確認: `~/nil/emacs/custom.el` は現在の `init.el` の `custom-file` からは直接参照されていないため、採用要否を後で確認する。
