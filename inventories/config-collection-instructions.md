# 既存設定ファイル収集の指示書

作成日: 2026-07-25

目的: 2台の既存 Linux PC に散逸しているアプリケーション、パッケージ、システムの設定ファイルを、秘密情報を混ぜずにこの Git repo へ段階的に収集し、実際の差分を見てから NixOS / Home Manager の正本設定へ統合する。

対象ホスト:

- `thinkpad-t14-gen5`: 現在の Arch Linux 移行元。旧名 `trt-ryzen7` / `trt-arch` を参照情報として扱う。
- `thinkpad-l480`: 既存 NixOS PC。

## 基本方針

- 既存設定は正本ではなく参考資料として収集する。
- 収集はアプリケーションまたは関心事ごとに小さく行う。
- 1つの収集単位を1つの commit にする。
- 各 commit は、片方のPCの1アプリ、または両PCの同じ1アプリの比較に限定する。
- 秘密値、token、password、cookie、private key、ログイン状態、位置情報、ブラウザ profile、keyring は commit しない。
- 収集した設定は、採用、修正して採用、破棄、未確認のどれかに後で分類する。
- 推測で Nix 設定へ変換しない。まず実ファイルを読み、差分と意図を確認する。

## 保存先

既存設定の収集先は次の形式にする。

```text
inventories/config-sources/<hostname>/<application>/
```

例:

```text
inventories/config-sources/thinkpad-l480/emacs/
inventories/config-sources/thinkpad-l480/niri/
inventories/config-sources/thinkpad-l480/waybar/
inventories/config-sources/thinkpad-t14-gen5/sway/
inventories/config-sources/thinkpad-t14-gen5/fcitx5/
```

各 application directory には、可能な限り次を置く。

```text
README.md
files/
```

- `README.md`: 収集元、確認日、秘密情報レビュー、採否判断、未確認事項を書く。
- `files/`: 秘密情報レビュー済みの設定ファイルだけを置く。

元パスは `README.md` に記録する。`files/` 内では、`$HOME` 配下の相対パスを保った名前にする。

例:

```text
~/.config/waybar/config.jsonc
-> inventories/config-sources/thinkpad-l480/waybar/files/.config/waybar/config.jsonc
```

## 収集前チェック

各PCで作業を始める前に、必ず repo を最新化する。

```bash
cd ~/Git/Settings-Integration
git status --short --branch
git pull --rebase=false origin master
git status --short --branch
```

作業ツリーが clean でない場合は、先にその差分の意味を確認する。別PCの未push作業を上書きしない。

## 収集単位

最初は次の単位で収集する。

| 単位 | 主な収集元 | 備考 |
|---|---|---|
| Emacs | `~/.emacs.d/init.org`, `init.el`, `early-init.el`, `themes/` | `eln-cache`, `url/cache`, package cache は除外 |
| niri | `~/.config/niri/config.kdl` | monitor layout はホスト別候補 |
| Sway | `~/.config/sway/`, sway 起動 wrapper | Arch 側の参照用。標準は niri |
| Waybar | `~/.config/waybar/config*`, `style.css`, scripts | 位置情報 cache は除外 |
| Alacritty | `~/.config/alacritty/alacritty.toml` | shell path のホスト依存に注意 |
| Kitty | `~/.config/kitty/` | 標準化しない場合も比較用に残す |
| Rofi | `~/.config/rofi/` | generated default は必要範囲だけ |
| Hyprlock | `~/.config/hypr/hyprlock.conf` | lock 認証の PAM は NixOS 側 |
| fcitx5 | `~/.config/fcitx5/`, `~/.local/share/fcitx5/skk/user.dict` | user dict は個人データ。commit 前に内容確認 |
| Git | `~/.gitconfig`, `~/.config/git/` | user/email/includeIf/url rewrite を確認 |
| SSH | `~/.ssh/config` | private key は絶対に commit しない |
| GPG/auth-source | `~/.gnupg` の存在、`~/.authinfo*` の種類 | 値や key material は commit しない |
| shell | `~/.bashrc`, `~/.bash_profile`, `~/.profile`, `~/.zshenv`, `~/.zshrc` | API key 直書きがないか必ず確認 |
| user systemd | `~/.config/systemd/user/*.service`, `*.timer` | Emacs daemon, Waybar helper など |
| NixOS config | `/etc/nixos` または既存 flake | secrets, host UUID, hardware 差分に注意 |
| Arch system config | `/etc` の採用候補 | root 権限が必要なものは path と確認結果だけでもよい |

## commit してよいもの

次の条件を満たすテキスト設定だけ commit する。

- token、password、secret、private key、cookie、session ID が含まれていない。
- ホスト固有値が含まれる場合、その理由が `README.md` に書かれている。
- 生成 cache ではなく、手で調整した設定または採用判断に必要な設定である。
- ファイルの出所と確認日が `README.md` に書かれている。

## commit しないもの

次は repo に入れない。必要な場合は `README.md` にパス、種類、移行方針だけを書く。

- `~/.ssh/id_*`, private key, private key backup
- `~/.gnupg/private-keys-v1.d/`
- `~/.authinfo`, `~/.authinfo.gpg` の中身
- `~/.config/gh/hosts.yml`
- browser profile, cookie DB, NSS DB, key4.db
- GNOME keyring, KWallet, login state
- Claude, Codex, Copilot, Wrangler, Kaggle, Qiita などの認証ファイル
- `.env`
- Waybar localtime cache など、緯度経度や現在地を含む state
- `node_modules`, `.venv`, cache, build output, native compile cache
- 大きい binary data

## 収集手順

1. 作業対象を1つ決める。

例:

```text
thinkpad-l480 の Emacs 設定を収集する
thinkpad-t14-gen5 の Waybar 設定を収集する
```

2. 保存先を作る。

```bash
host=thinkpad-l480
app=emacs
mkdir -p "inventories/config-sources/$host/$app/files"
```

3. まずファイル一覧だけ確認する。

```bash
rg --files ~/.emacs.d
rg --files ~/.config/waybar
rg --files ~/.config/niri
```

4. 秘密情報が入りそうなファイルを除外してからコピーする。

```bash
install -D -m 0644 ~/.config/waybar/config.jsonc \
  inventories/config-sources/thinkpad-l480/waybar/files/.config/waybar/config.jsonc

install -D -m 0644 ~/.config/waybar/style.css \
  inventories/config-sources/thinkpad-l480/waybar/files/.config/waybar/style.css
```

5. `README.md` を書く。

```markdown
# thinkpad-l480 Waybar

収集日: 2026-07-25
収集元ホスト: thinkpad-l480
収集者: tarutyyyne

## 収集元

- `~/.config/waybar/config.jsonc`
- `~/.config/waybar/style.css`

## 秘密情報レビュー

- token/password/API key: 見つからない
- host 固有情報: network tooltip が SSID を表示し得る
- commit しないもの: cache/state は未収集

## 現在の特徴

- bar は top layer / top position
- 色は black + orange
- volume 操作は `wpctl` へ寄せる必要あり

## 統合判断

- 方針: 修正して共通 Home Manager 設定へ採用
- 未確認: niri での表示、音量 click、IME 表示
```

6. commit 前に secret scan と差分確認をする。

```bash
git diff --check
git diff -- inventories/config-sources/<hostname>/<application>/
gitleaks detect --no-git --source inventories/config-sources/<hostname>/<application>/
```

`gitleaks` が使えないPCでは、最低限 `rg` で危険語を確認する。

```bash
rg -n -i 'token|password|passwd|secret|api[_-]?key|oauth|bearer|cookie|private' \
  inventories/config-sources/<hostname>/<application>/
```

7. commit する。

```bash
git add inventories/config-sources/<hostname>/<application>/
git commit -m "Collect <hostname> <application> configuration"
```

8. push する。

```bash
git pull --rebase=false origin master
git push origin master
```

push 前の `git pull` で衝突した場合は、無理に解決せず、対象ファイルと衝突内容を確認してから続行する。

## 比較手順

両PCの同じアプリが揃ったら比較用メモを追加する。

保存先:

```text
inventories/config-comparisons/<application>.md
```

比較メモには次を書く。

- 2台で同じ設定
- 片方だけにある設定
- 採用する設定
- 修正して採用する設定
- 破棄する設定
- Home Manager で管理するか、NixOS module で管理するか、手動バックアップにするか
- secrets や host 固有情報の扱い

例:

```markdown
# Waybar 比較

比較日: 2026-07-25

## 共通化する

- top bar
- black + orange theme
- clock
- memory
- battery
- network
- volume
- IME indicator

## 修正して採用する

- volume click は `pactl` ではなく `wpctl`
- Sway module は niri 用に置き換える

## 採用しない

- 位置情報 cache の commit
- SSID を公開スクリーンショットに出す運用

## 統合先

- Home Manager: `home/modules/desktop.nix`
- NixOS: PipeWire / portal は `modules/nixos/desktop.nix`
```

## 優先順

最初は、統合済み module との対応が強いものから収集する。

1. `niri`
2. `waybar`
3. `alacritty`
4. `hyprlock`
5. `rofi`
6. `fcitx5`
7. `keyd`
8. `emacs`
9. `git`
10. `ssh`
11. shell
12. user systemd
13. GUI apps

## Codex に依頼するときの型

各PCで Codex に収集を依頼するときは、次のように依頼する。

```text
このPCの <application> 設定を、inventories/config-collection-instructions.md に従って収集してください。
秘密情報は値を記録せず、収集元パスと移行方針だけを書いてください。
実装前に作業項目を提示し、commit 前に対象範囲、検証結果、commit message 案を出してください。
```

複数アプリを一度に依頼しない。1アプリずつ収集、確認、commit、push する。

## 判断保留の扱い

不明な設定や実機でしか判断できない設定は、推測で Nix 設定へ変換しない。`README.md` または比較メモに `未確認` として残す。

例:

- 起動中 service の live 状態
- DBus / portal / PipeWire の実動作
- fingerprint / PAM の動作
- monitor 名、解像度、scale
- battery / suspend policy
- SSH/GPG key の復元可否

## 最終的な統合の流れ

1. 各PCから実設定を収集する。
2. 同じアプリごとに比較メモを書く。
3. 採用、修正採用、破棄、未確認を分類する。
4. 採用するものだけ NixOS / Home Manager module へ写す。
5. 実機で `nixos-rebuild build` または `nixos-rebuild switch` を行う。
6. 動作確認結果を比較メモまたは判断メモに追記する。

この repo に入れるのは、再現すべき設定と判断材料だけである。認証状態、秘密値、cache、巨大な状態データは別の暗号化バックアップまたは再ログインで扱う。
