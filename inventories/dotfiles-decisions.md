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

共通:

* Nix設定リポジトリには秘密値を平文で入れない。
* 宣言的に配布したい秘密情報は`sops-nix`を第一候補にする。
* age鍵はホストまたはユーザーごとに分け、秘密値の復号対象を必要最小限にする。
* SSH秘密鍵、GPG秘密鍵、ブラウザprofile、keyring、Claude/Codexなどのログイン状態は、Nix storeへ置かず暗号化バックアップまたは再ログインで扱う。
* GitHub CLI、Cloudflare Wrangler、Kaggle、Qiita CLIなどのOAuth tokenは、原則として移行後に再ログインする。
* `.env`はプロジェクト単位で扱い、共通dotfilesには含めない。必要なものだけ暗号化バックアップする。
* `pass`は日常的な手入力secretの保存先として必要になった場合に導入する。初期構成では`sops-nix`と再ログイン運用を優先する。

## 2. デスクトップ環境

### 2.1 Wayland compositor

Sway と niri のどちらを標準にするか。両方残す場合、どちらを主環境にするか。

回答: niri を標準にする。両ホストとも主環境は niri に寄せる。Sway は `trt-ryzen7` の既存設定参照用または復旧用として必要になった場合だけ残す。


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

回答: いまのところ fcitx5-skk を使うようにする


## 5. 日本語入力・キーボード

### 5.1 IME

`fcitx5 + SKK` を標準にするか。`mozc` も使うか。

回答: `fcitx5 + SKK`


### 5.2 SKK 辞書

fcitx5 の `user.dict` と Emacs の `nskk-jisyo` をどう同期・バックアップするか。

回答: 同期させたい

補足:

`fcitx5-skk` を標準 IME とするため、通常入力のユーザー辞書は
`~/.local/share/fcitx5/skk/user.dict` を正とする。
この辞書は個人語彙を含む可能性が高いため、平文のまま Git 管理しない。

移行時は次のどちらかにする。

* 暗号化バックアップとして退避し、新環境で同じ path へ復元する。
* 内容を確認して問題ない範囲だけ手動で新環境へ移す。

旧 Emacs 側の `nskk` は主方針から外し、`~/.emacs.d/nskk/dict-cache.eld`
などは再生成可能な cache として扱う。
将来 Emacs 内で `nskk` を再採用する場合だけ、`nskk-jisyo` と
`fcitx5-skk` の同期方法を別作業として設計する。


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

回答: `wpctl`に寄せる。PipeWire/WirePlumberを標準にするため、Waybarのクリック操作や音量表示スクリプトも`wpctl`基準で実装する。`pactl`前提の既存設定は移行時に置き換える。


### 6.3 テーマカラー

黒 + オレンジ系を標準テーマにするか。アプリごとに変えるか。

回答: 標準テーマにしたい


### 6.4 フォント

Noto、JetBrains Mono Nerd、HackGen、PlemolJP など、標準フォントをどうするか。

回答:

共通:

* UI日本語フォントは`Noto Sans CJK JP`を標準にする。
* monospace/terminal/editorは`HackGen Console NF`を第一候補にする。
* Nerd Fontが必要なWaybarやターミナル表示では、アイコン表示用にNerd Font対応フォントを入れる。
* 絵文字用に`Noto Color Emoji`を入れる。
* PlemolJPやJetBrains Mono Nerdは必要なら追加候補にするが、初期標準は増やしすぎない。


## 7. オーディオ・映像

### 7.1 オーディオ基盤

PipeWire + WirePlumber + Pulse compatibility に統一するか。

回答:

PipeWire + WirePlumber + PulseAudio互換に統一する。
ALSA/JACK/PulseAudio互換もNixOS側で有効化し、デスクトップアプリ、OBS、Bluetooth audioが同じ基盤で動くようにする。


### 7.2 音量GUI

`pavucontrol` と `pwvucontrol` のどちらを標準にするか。

回答:

`pwvucontrol`を標準にする。
`pavucontrol`はPulseAudio互換UIが必要な場合の予備として追加してもよいが、初期の標準操作は`wpctl`と`pwvucontrol`へ寄せる。


### 7.3 OBS・画面録画

OBS を使うか、`wf-recorder` など軽量ツール中心にするか。

回答:

OBSを標準の録画・配信ツールとして入れる。
軽量な一時録画用に`wf-recorder`系のCLIを追加するかは実装時に判断する。
画面共有と録画はPipeWire + portal前提で構成する。


### 7.4 Bluetooth audio

Bluetooth を両ホストで有効化するか。audio codec など追加方針があるか。

回答:

両ホストでBluetoothを有効化する。
Bluetooth audioはPipeWire/WirePlumberで扱う。
codecの追加調整は、実機でヘッドセットやイヤホンの接続確認をしてから必要な範囲だけ行う。


## 8. 開発環境

### 8.1 Node.js

Nix devShell / direnv に寄せるか、nvm を継続するか。

回答:

プロジェクトごとの`flake.nix` + `direnv`に寄せる。
グローバルなnvmは原則使わない。
共通で必要なNode.js、pnpm、TypeScript系LSPはHome Managerまたは共通dev toolsとして最小限だけ入れ、バージョン固定が必要なものは各プロジェクトのdevShellで管理する。


### 8.2 Python

`uv` を標準にするか、conda を再構築するか。conda を捨てるか。

回答:

`uv`を標準にする。
壊れているconda環境は丸ごと移行しない。
Python本体やビルド依存は、プロジェクトごとのdevShellまたは`uv`の管理に寄せる。
既存conda環境が必要になった場合だけ、環境定義を確認して再作成する。


### 8.3 Rust

`rustup` を使うか、Nix packages / devShell に寄せるか。

回答:

原則としてNix packages / devShellに寄せる。
プロジェクトごとに必要なRust toolchain、rust-analyzer、clippy、rustfmtをdevShellで入れる。
`rustup`は、Nixで扱いにくいnightlyや特定targetが必要になった場合だけ例外的に使う。


### 8.4 Java / Maven

JDK21 + Maven を共通開発ツールに入れるか。

回答:

JDK21 + Mavenを共通開発ツールに入れる。
授業・既存プロジェクトで別バージョンが必要な場合は、そのプロジェクトのdevShellで上書きする。


### 8.5 direnv / nix-direnv

プロジェクトごとの環境を `.envrc` + `flake.nix` に寄せるか。

回答:

`.envrc` + `flake.nix` + `nix-direnv`に寄せる。
共通設定でdirenv hookを有効化し、プロジェクト側で必要な開発環境を宣言する。
`.envrc`は実行許可が必要なため、信頼したリポジトリだけ`direnv allow`する運用にする。


### 8.6 TeX / Arduino / TypeScript

TeX、Arduino、TypeScript language server などを共通ツールに入れるか。

回答:

TeX、Arduino、TypeScript language serverは共通ツール候補に入れる。
ただしサイズが大きいTeXやArduino関連パッケージは、常時必要な最小セットを共通にし、重いものはプロジェクトdevShellかホスト別設定へ逃がす。
TypeScript LSPやformatterはEmacsで使う前提で導入する。


## 9. Git・SSH・GPG

### 9.1 Git global config

GitHub URL rewrite、INIAD 用 includeIf、`core.sshCommand` などをどう管理するか。

回答:

Home Managerの`programs.git`で管理する。
共通のuser name/email、default branch、pull/rebase方針、diff設定を宣言する。
GitHub personal/private/INIADの切り替えは`includeIf`とSSH host aliasで分ける。
`core.sshCommand`は恒久設定にせず、systemd SSH proxy権限問題の回避が必要な場合だけリポジトリローカルに設定する。


### 9.2 SSH config

GitHub personal、private、INIAD 用 host alias と鍵をどう分けるか。

回答:

Home Managerの`programs.ssh`でhost aliasを管理する。
秘密鍵本体はGit管理しない。
GitHub personal、GitHub private、INIAD用のhost aliasを分け、それぞれ明示的に`IdentityFile`を割り当てる。
秘密鍵は暗号化バックアップから復元するか、必要に応じて再発行する。


### 9.3 GPG

GPG を標準で使うか。`authinfo.gpg` や commit signing を使うか。

回答:

GPGは標準で利用可能にする。
`authinfo.gpg`を使う場合に備えてGPG秘密鍵は暗号化バックアップ対象にする。
commit signingは必須にはしない。必要なリポジトリだけGit設定で有効化する。
`trt-ryzen7`側のGPG keyboxdエラーは、移行前に秘密鍵のexport/backup可否を確認する。


### 9.4 GitHub CLI

`gh` の認証状態を移行するか、移行後に再ログインするか。

回答:

`gh`の認証tokenは移行せず、移行後に`gh auth login`で再ログインする。
`~/.config/gh/config.yml`のような秘密値を含まない設定だけ、必要ならHome Managerまたはバックアップで扱う。
無効なtokenはバックアップ対象ではなくrotate/re-login対象にする。


## 10. ネットワーク・サービス

### 10.1 Wi-Fi 管理

`iwd + dhcpcd` に統一するか、NetworkManager を使うか。

回答:

`iwd + DHCP`に統一する。
既存の`thinkpad-l480`と`trt-ryzen7`の棚卸しに合わせ、NetworkManagerは初期標準にしない。
Wi-Fi profileはSSID/PSKを文書化せず、必要なら暗号化バックアップまたは手動再設定で扱う。


### 10.2 Avahi

Avahi / mDNS を有効化するか。

回答:

Avahi/mDNSは有効化する。
ローカルネットワーク上の名前解決や開発用途で使えるようにする。
不要な公開範囲が出ないよう、firewall設定と合わせて確認する。


### 10.3 Docker / Incus / Ollama

Docker、Incus、Ollama を標準で有効化するか、必要なホストだけにするか。

回答:

必要なホストだけで有効化する。
`trt-ryzen7`ではDocker、Incus、Ollamaをホスト別設定で有効化候補にする。
`thinkpad-l480`では初期標準にせず、必要になったものだけ追加する。
既存コンテナ、volume、model dataを移すかは、フォーマット前の最終確認で判断する。


### 10.4 Guix

Guix を NixOS 上でも併用するか、Nix に寄せるか。

回答:

原則としてNixに寄せる。
Guixは初期構成では有効化しない。
既存のGuix profileや特定用途が必要だと分かった場合だけ、ホスト別の追加項目として検討する。


### 10.5 電源管理

TLP を使うか、power-profiles-daemon を使うか。

回答:

ノートPCの`thinkpad-l480`はTLPを第一候補にする。
デスクトップの`trt-ryzen7`ではTLPを有効化しない。
`power-profiles-daemon`との併用は避け、ホストごとにどちらか一方を選ぶ。


## 11. GUIアプリ・状態データ

### 11.1 ブラウザ

Floorp、Firefox、Chromium など、標準ブラウザをどうするか。profile を移行するか。

回答:

Floorpを標準ブラウザ候補にする。
Firefox/Chromiumは開発・検証用途として必要に応じて入れる。
ブラウザprofileは秘密情報を含むため、Git管理しない。
ログイン状態や拡張機能状態まで必要な場合だけ暗号化バックアップし、基本は再ログインで復旧する。


### 11.2 Discord

ログイン状態を移行するか、cache を捨てて再ログインするか。

回答:

Discordはパッケージだけ管理し、ログイン状態は移行後に再ログインする。
cache、GPUCache、Code Cache、Crashpadなどは捨てる。
Local StorageやCookiesは秘密情報を含む可能性が高いため、通常は移行しない。


### 11.3 Steam / ゲーム

Steam やゲームデータをバックアップ対象にするか。

回答:

Steam本体はNixOS側で再導入する。
ゲームデータは容量が大きいため、丸ごとバックアップするか再ダウンロードするかをタイトル単位で判断する。
セーブデータ、PrismLauncher/Minecraftなど再取得しにくい状態データは優先してバックアップする。


### 11.4 Zed / Obsidian / LibreOffice / GIMP

どの GUI アプリの設定を dotfiles 管理対象にするか。

回答:

Zed、Obsidian、LibreOffice、GIMPはパッケージ導入候補にする。
設定ファイルは、平文で管理できる軽い設定だけHome Managerで扱う。
Obsidian vaultやブラウザ/アプリのログイン状態はdotfilesではなくデータバックアップとして扱う。
`~/obsidian`の実在は移行前に再確認する。


## 12. バックアップ・除外

### 12.1 必ず移すもの

dotfiles、NixOS flake、SSH鍵、SKK辞書、Emacs設定、Git repos、作業データなど、必須バックアップ対象を書く。

回答:

必ず移すもの:

* NixOS flake / Home Manager設定リポジトリ。
* `/etc/nixos`の現行設定。
* `~/.config/niri`、`~/.config/waybar`、`~/.config/alacritty`、`~/.config/hypr/hyprlock.conf`相当の設定。
* Emacs設定、特に`~/.emacs.d/init.org`、`init.el`、themes、必要なsnippetや辞書。
* fcitx5 SKKのユーザー辞書。
* SSH秘密鍵と公開鍵、SSH config、known_hosts。
* GPG秘密鍵、`authinfo.gpg`または`authinfo`。
* GitHub/開発用リポジトリと未push作業。
* 学校・開発・個人作業データ。
* 必要なブラウザprofile、keyring、Claude/Codex状態は暗号化バックアップ対象として別扱い。


### 12.2 再生成するもの

`~/.cache`、`node_modules`、`.venv`、`dist`、`.next`、npm/pnpm/uv cache など、捨てるものを書く。

回答:

再生成するもの:

* `~/.cache/*`
* pacman/yay build cache
* npm/pnpm/uv/pip cache
* `node_modules`
* `.venv`
* Python/Node/Rustなどのビルド成果物
* `dist`
* `.next`
* `.vite`
* `target`
* `tsconfig.tsbuildinfo`
* browser/electron cache
* Discord cache、GPUCache、Code Cache、Crashpad
* Emacs native compilation cache、url cache
* Playwright/Puppeteer cache
* Trash
* 壊れているconda環境


### 12.3 秘密混入リスクがあるもの

ブラウザ profile、Discord、keyrings、clipboard DB、`.env`、Claude/Codex 状態などをどう扱うか。

回答:

秘密混入リスクがあるものは、Git管理せず暗号化バックアップまたは再ログインで扱う。

対象:

* ブラウザprofileとNSS DB。
* DiscordのCookies、Local Storage、Trust Tokens。
* GNOME keyringなどのkeyring。
* clipboard DB。
* `.env`。
* Claude/Codexのcredentialsや状態ファイル。
* GitHub CLI、Wrangler、Kaggle、Qiita CLIなどの認証ファイル。
* SSH秘密鍵、GPG秘密鍵、authinfo。

値を文書へ転記しない。
移行前にrotateできるtoken/passwordはrotateし、移行後は再ログインを優先する。


## 13. 優先順位

最初に実装したい順番を書く。

回答:

1. flake構成の土台を作る: `flake.nix`、nixpkgs、Home Manager、ホスト別module、共通module。
2. bootできる最小NixOSを整える: loader、filesystem、hardware configuration、user、sudo/wheel。
3. networkを復旧する: iwd + DHCP、firewall、必要ならAvahi。
4. niriデスクトップを起動する: greetd/tuigreet、niri-session、portal、PipeWire。
5. 入力と基本UIを復旧する: fcitx5 + SKK、keyd、Alacritty、rofi、Waybar、hyprlock/swayidle。
6. secretsの扱いを固める: sops-nix、暗号化バックアップ、SSH/GPG、再ログイン対象の整理。
7. Emacs環境を復旧する: Emacs daemon、straight.el、既存設定、IME連携。
8. Git/SSH/GitHub CLIを復旧する: host alias、includeIf、gh再ログイン。
9. 開発環境を整える: direnv/nix-direnv、Node、Python/uv、Rust、JDK/Maven、TeX、Arduino、TypeScript。
10. ホスト別サービスを追加する: Docker、Incus、Ollama、TLP、Bluetooth。
11. GUIアプリと状態データを戻す: Floorp、Discord、Zed、Obsidian、LibreOffice、GIMP、Steam/ゲーム。
12. キャッシュ除外とバックアップ手順を最終確認する。


## 14. その他メモ

上記にない希望、迷っていること、あとで相談したいことを書く。

回答:

実装時は、共通moduleを先に作りすぎず、両ホストで実際に共通化できることが確認できたものから切り出す。
最初は`hosts/trt-ryzen7`と`hosts/thinkpad-l480`、`home/tarutyyyne`、`modules/common`程度の小さい構成にする。
秘密情報、ブラウザprofile、ゲームデータ、コンテナvolumeは、Nix設定とは別の移行手順として扱う。
