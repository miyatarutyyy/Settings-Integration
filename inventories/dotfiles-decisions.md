# 統一 dotfiles 作成前の判断メモ

作成日: 2026-07-23

目的: `trt-ryzen7-archlinux.md` と `thinkpad-l480-nixos.md` をもとに、統一的な dotfiles / NixOS / Home Manager 設定を作る前に決めることを記録する。

書き方:

- 各項目の「回答」に方針を書く。
- 未定の場合は「未定」と書く。
- ホスト別に分けたい場合は、`共通`, `trt-ryzen7`, `thinkpad-l480` のように分けて書く。

## 1. 全体方針

### 1.1 dotfiles の対象OS

NixOS + Home Manager を正とするか、Arch Linux でも使える汎用 dotfiles にするか。

回答: NixOS + Home Manager を正としたい


### 1.2 ホスト差分の扱い

2台で完全に統一するか、共通設定とホスト別設定に分けるか。

回答: 共通設定とホスト別設定に分ける


### 1.3 dotfiles 管理方式

Home Manager、GNU Stow、chezmoi、自前 symlink、Nix flake 直管理など、どれを使うか。

回答:
Gitで管理する単一のNix設定リポジトリを作り、
Nix flake + NixOS + Home Managerで直接管理する。

- flake.nix:
  nixpkgs、Home Managerなどの依存関係と、
  各ホストのNixOS構成を定義する。

- NixOS:
  OS、ハードウェア、サービス、システム全体のパッケージを管理する。

- Home Manager:
  ユーザー単位のパッケージ、環境変数、
  Emacs、Git、Alacritty、niri、waybarなどの設定を管理する。
  Home ManagerはNixOSモジュールとして組み込む。

- Git:
  flake.nix、flake.lock、NixOSモジュール、
  Home Managerモジュール、設定ファイルを一括して履歴管理する。

GNU Stow、chezmoi、自前symlinkは原則として併用しない。
Home Managerに専用の設定項目がないアプリについては、
home.fileまたはxdg.configFileを使用して設定ファイルを配置する。

秘密鍵、APIキー、パスワードなどは平文でGit管理しない。

### 1.4 秘密情報の管理方式

`sops-nix`、`agenix`、`pass`、手動暗号化バックアップ、再ログイン運用など、どれを使うか。

回答:


## 2. デスクトップ環境

### 2.1 Wayland compositor

Sway と niri のどちらを標準にするか。両方残す場合、どちらを主環境にするか。

回答: niri を標準に、どちらもそうする


### 2.2 セッション起動方法

`ly`、niri-session、display manager なし、手動起動など、ログイン後の起動方法をどうするか。

回答:

共通:

* Display Managerには`greetd`を使用する。
* greeterにはTUI形式の`tuigreet`を使用する。
* ログイン成功後は`niri-session`を起動する。
* 原則として自動ログインは使用しない。
* `trt-ryzen7`と`thinkpad-l480`で同じ起動方式を使用する。

`ly`は使用しない。
Display ManagerなしでTTYから手動起動する方式も、通常運用には使用しない。
ただし、Display Managerやniriが起動しない場合は、別のTTYへ切り替えて復旧作業を行えるようにする。

### 2.3 xdg-desktop-portal

画面共有、スクリーンショット、OBS のために portal をどう構成するか。

回答:


### 2.4 ロック・idle

`swaylock`、`hyprlock`、`swayidle` などをどう使うか。

回答:### 2.3 xdg-desktop-portal

回答:

共通:

* `xdg-desktop-portal`を有効にする。
* 画面共有とOBS用のバックエンドとして`xdg-desktop-portal-gnome`を使用する。
* 基本機能のフォールバックとして`xdg-desktop-portal-gtk`を併用する。
* ファイル選択はGTK portalを優先し、Nautilusへの依存を避ける。
* Secret portalには`gnome-keyring`を使用する。
* PipeWireを有効にし、niriは`niri-session`経由で起動する。
* `xdg-desktop-portal-wlr`および`xdg-desktop-portal-hyprland`は使用しない。
* `GDK_BACKEND`をシステム全体の環境変数として固定しない。

画面共有:

* OBS、Firefox、Chromium、Electron系アプリの画面共有にはportalとPipeWireを使用する。
* モニター全体と個別ウィンドウの共有に対応させる。

スクリーンショット:

* 通常のスクリーンショットにはniri組み込みのスクリーンショット機能を使用する。
* アプリケーションがScreenshot portalを要求する場合は、portal経由で処理する。

### 2.4 ロック・idle

回答:

共通:

* ロックスクリーンには`hyprlock`を使用する。
* idle管理には`swayidle`を使用する。
* `hypridle`は使用しない。
* 手動ロック用のniriキーバインドを設定する。
* サスペンド前には必ずロックを実行する。
* ロック中またはサスペンド中に画面が一瞬表示されないよう、ロック完了後にサスペンドする構成にする。

共通のidle動作:

* 10分間操作がなければロックする。
* 15分間操作がなければモニターを消灯する。
* 操作再開時にはモニターを点灯する。
* 動画再生、ゲーム、画面共有などがidle inhibitを要求している場合は、自動ロック・消灯を抑制する。
* 手動ロック時にも同じ`hyprlock`を使用する。

trt-ryzen7:

* 自動ロックとモニター消灯を行う。
* 長時間処理やサーバー用途を妨げないよう、自動サスペンドは原則として行わない。

thinkpad-l480:

* 自動ロックとモニター消灯を行う。
* 一定時間操作がない場合は自動サスペンドする。
* 蓋を閉じた場合も、ロックしてからサスペンドする。
* AC接続中とバッテリー駆動中でサスペンド時間を分けるかは、実装時に決定する。



## 3. ターミナル・シェル

### 3.1 ターミナル

`kitty` と `alacritty` のどちらを標準にするか。ホスト別に分けるか。

回答: alacritty にする


### 3.2 シェル

`zsh` と `bash` のどちらを標準にするか。

回答: bash にしよう


### 3.3 プロンプト・テーマ

プロンプト、色、フォント、shell integration をどう統一するか。

回答: いつものオレンジベースのを採用したいがこれはこのあと別個で設定したい


### 3.4 PATH 管理

Nix profile、`~/.local/bin`、Guix、nvm、conda、cargo bin をどう扱うか。

回答:

PATH管理はNix / Home Managerを中心とする。

- システム共通ツールはNixOSのenvironment.systemPackagesで管理する。
- ユーザー単位の常用ツールはHome Managerのhome.packagesで管理する。
- nix profile installは原則使用しない。宣言的設定に残らず、再現性を損なうため。
- ~/.local/binは自作スクリプト専用としてPATHに追加する。
- プロジェクト固有のNode.js、Python、Rust等はflake.nixとdirenvで管理する。
- nvm、conda、Guixは原則使用しない。NixとのPATH競合や環境の二重管理を避けるため。
- cargo installは原則避け、必要なCLIはNixパッケージとして導入する。

## 4. エディタ

### 4.1 メインエディタ

Emacs を標準にするか。Zed、VS Code、Vim、nvim を管理対象に含めるか。

回答: Emacs を標準に


### 4.2 Emacs パッケージ管理

Nix/Home Manager に寄せるか、`straight.el` を継続するか、混在を許すか。

回答: straight.el にする


### 4.3 Emacs daemon

user systemd service で daemon 起動するか、通常起動にするか。

回答: daemon 起動にしたい


### 4.4 Emacs と日本語入力

Emacs 内では `nskk` を使うか、fcitx5-skk に寄せるか。daemon 起動時の IME 環境変数をどうするか。

回答: いまのことろ fcitx5-skk を使うようにする


## 5. 日本語入力・キーボード

### 5.1 IME

`fcitx5 + skk` を標準にするか。`mozc` も使うか。

回答: `fcitx5 + skk` 


### 5.2 SKK 辞書

fcitx5 の `user.dict` と Emacs の `nskk-jisyo` をどう同期・バックアップするか。

回答: 同期させたい


### 5.3 keyd

CapsLock を control layer にする設定を共通化するか。device ID 固定にするか。

回答: 共通化する


### 5.4 キーバインド体系

Compositor やエディタ周辺の移動キーを Emacs 風に寄せるか、Vim 風に寄せるか、アプリごとに分けるか。

回答: アプリごとに分けたい


## 6. Waybar・UI

### 6.1 Waybar

Sway 用と niri 用を分けるか、共通設定にするか。

回答: 共通にしたい


### 6.2 Waybar の音量操作

`pactl` を使うか、`wpctl` に寄せるか。

回答: 


### 6.3 テーマカラー

黒 + オレンジ系を標準テーマにするか。アプリごとに変えるか。

回答: 標準テーマにしたい


### 6.4 フォント

Noto、JetBrains Mono Nerd、HackGen、PlemolJP など、標準フォントをどうするか。

回答:


## 7. オーディオ・映像

### 7.1 オーディオ基盤

PipeWire + WirePlumber + Pulse compatibility に統一するか。

回答:


### 7.2 音量GUI

`pavucontrol` と `pwvucontrol` のどちらを標準にするか。

回答:


### 7.3 OBS・画面録画

OBS を使うか、`wf-recorder` など軽量ツール中心にするか。

回答:


### 7.4 Bluetooth audio

Bluetooth を両ホストで有効化するか。audio codec など追加方針があるか。

回答:


## 8. 開発環境

### 8.1 Node.js

Nix devShell / direnv に寄せるか、nvm を継続するか。

回答:


### 8.2 Python

`uv` を標準にするか、conda を再構築するか。conda を捨てるか。

回答:


### 8.3 Rust

`rustup` を使うか、Nix packages / devShell に寄せるか。

回答:


### 8.4 Java / Maven

JDK21 + Maven を共通開発ツールに入れるか。

回答:


### 8.5 direnv / nix-direnv

プロジェクトごとの環境を `.envrc` + `flake.nix` に寄せるか。

回答:


### 8.6 TeX / Arduino / TypeScript

TeX、Arduino、TypeScript language server などを共通ツールに入れるか。

回答:


## 9. Git・SSH・GPG

### 9.1 Git global config

GitHub URL rewrite、INIAD 用 includeIf、`core.sshCommand` などをどう管理するか。

回答:


### 9.2 SSH config

GitHub personal、private、INIAD 用 host alias と鍵をどう分けるか。

回答:


### 9.3 GPG

GPG を標準で使うか。`authinfo.gpg` や commit signing を使うか。

回答:


### 9.4 GitHub CLI

`gh` の認証状態を移行するか、移行後に再ログインするか。

回答:


## 10. ネットワーク・サービス

### 10.1 Wi-Fi 管理

`iwd + dhcpcd` に統一するか、NetworkManager を使うか。

回答:


### 10.2 Avahi

Avahi / mDNS を有効化するか。

回答:


### 10.3 Docker / Incus / Ollama

Docker、Incus、Ollama を標準で有効化するか、必要なホストだけにするか。

回答:


### 10.4 Guix

Guix を NixOS 上でも併用するか、Nix に寄せるか。

回答:


### 10.5 電源管理

TLP を使うか、power-profiles-daemon を使うか。

回答:


## 11. GUIアプリ・状態データ

### 11.1 ブラウザ

Floorp、Firefox、Chromium など、標準ブラウザをどうするか。profile を移行するか。

回答:


### 11.2 Discord

ログイン状態を移行するか、cache を捨てて再ログインするか。

回答:


### 11.3 Steam / ゲーム

Steam やゲームデータをバックアップ対象にするか。

回答:


### 11.4 Zed / Obsidian / LibreOffice / GIMP

どの GUI アプリの設定を dotfiles 管理対象にするか。

回答:


## 12. バックアップ・除外

### 12.1 必ず移すもの

dotfiles、NixOS flake、SSH鍵、SKK辞書、Emacs設定、Git repos、作業データなど、必須バックアップ対象を書く。

回答:


### 12.2 再生成するもの

`~/.cache`、`node_modules`、`.venv`、`dist`、`.next`、npm/pnpm/uv cache など、捨てるものを書く。

回答:


### 12.3 秘密混入リスクがあるもの

ブラウザ profile、Discord、keyrings、clipboard DB、`.env`、Claude/Codex 状態などをどう扱うか。

回答:


## 13. 優先順位

最初に実装したい順番を書く。

回答:


## 14. その他メモ

上記にない希望、迷っていること、あとで相談したいことを書く。

回答:

