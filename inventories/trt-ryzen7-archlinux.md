# Arch Linux to NixOS migration inventory

作成日: 2026-07-23  
対象ホスト: `/home/trt-ryzen7` の現在の Arch Linux 環境  
目的: Arch Linux をフォーマットして NixOS を導入する前に、再現すべき設定、手動バックアップすべき状態データ、破棄してよいキャッシュ、秘密情報のローテーション対象を一覧化する。

## 重要な結論

1. この環境は **Sway + Waybar + fcitx5/SKK + Ly** が中心の Wayland 環境。
2. `~/.local/share/wayland-sessions/sway.desktop` が `/home/trt-ryzen7/.local/bin/sway-fcitx` を起動し、IME 環境変数を入れてから `sway` を起動している。NixOS 移行時にここを再現しないと日本語入力が崩れやすい。
3. systemd system unit は `avahi-daemon`, `bluetooth`, `dhcpcd`, `docker`, `guix-daemon`, `iwd`, `keyd`, `ollama`, `tlp`, `systemd-timesyncd`, `ly` が移行候補。
4. user systemd unit は `emacs.service` と `waybar-localtime-refresh.timer/service` が重要。
5. 平文の秘密情報が複数ある。値はこの文書に載せない。NixOS へ移る前に rotate/re-login する。
6. `miniconda3` は 6.5G 残っているが、`conda` が参照する Python が消えており壊れている。丸ごと移行より再作成が妥当。
7. 容量の大きい状態データは `~/.local/share/Steam` 88G、`~/.cache` 23G、`~/.npm` 13G、`~/Downloads` 6.8G、`~/.local/share/Trash` 5.6G。バックアップ対象と破棄対象を分ける。

## 調査時の制限

Codex 実行環境の制限により、以下は完全確認できなかった。

- systemd system/user bus: `hostnamectl`, `timedatectl`, `systemctl` の live 状態確認は `Operation not permitted`。
- `/efi`: `bootctl status` は `/efi` 読み取り不可で失敗。
- Docker/Incus/Ollama socket: API 接続は権限不足または sandbox の loopback 制限で失敗。
- network/rfkill/USB: `ip link`, `rfkill`, `lsusb`, `vulkaninfo` は一部失敗。
- root 権限が必要な `/var/lib/iwd`, `/var/lib/docker`, `/var/lib/incus`, `/etc/sudoers*` は中身未確認。

そのため、この文書は「読めた設定ファイルとパッケージ/ファイル実体に基づく棚卸し」であり、フォーマット直前に root で最終確認する項目を末尾に残す。

## セキュリティと秘密情報

次のファイルに token/password/credential が存在することを確認した。値は意図的に記録しない。

| パス | 種別 | NixOS 移行方針 |
|---|---|---|
| `~/.zshenv` | `INIAD_OPENAI_API_KEY` の平文 export | 直ちに rotate。NixOS では `sops-nix`, `agenix`, password manager, または shell へ直書きしない方式へ移行 |
| `~/.config/gh/hosts.yml` | GitHub CLI OAuth token | バックアップするより `gh auth login` で再ログイン推奨。既存 token は rotate 推奨 |
| `~/.config/github-copilot/apps.json` | GitHub Copilot OAuth token | 再ログイン推奨。既存 token は rotate 推奨 |
| `~/.config/.wrangler/config/default.toml` | Cloudflare Wrangler OAuth/refresh token | 再ログイン推奨。既存 token は rotate 推奨 |
| `~/.config/msmtp/config` | SMTP password | `passwordeval` や secrets 管理へ移す。既存 password は rotate 推奨 |
| `~/.kaggle/credentials.json` | Kaggle access/refresh token | 再ログインまたは token 再発行推奨 |
| `~/.config/qiita-cli/credentials.json` | Qiita access token | 再ログインまたは token 再発行推奨 |
| `~/.authinfo.gpg` | Emacs/auth-source 用の暗号化 credential | GPG 秘密鍵と一緒に扱う。復号できるか要確認 |
| `~/.ssh/id_ed25519*` | SSH private keys | 必ず暗号化バックアップ。公開鍵だけでは復元不可 |
| `~/.gnupg/private-keys-v1.d` | GPG private keys | 必ず暗号化バックアップ。今回 `gpg --list-keys` は keyboxd 起動失敗で未確認 |

移行前の優先作業:

1. 上記 token/password を rotate する。
2. NixOS 側に秘密値を直書きしない方針を決める。
3. `~/.ssh`, `~/.gnupg`, `~/.authinfo.gpg` は暗号化した外部バックアップへ退避する。

## システム概要

| 項目 | 現在値 |
|---|---|
| OS | Arch Linux rolling |
| Kernel | `7.0.11-arch1-1` |
| Hostname | `trt-arch` |
| Architecture | `x86_64` |
| Locale | `LANG=en_US.UTF-8` |
| Timezone | `/etc/localtime -> /usr/share/zoneinfo/Asia/Tokyo` |
| Shell | `/bin/zsh` |
| User | `trt-ryzen7`, uid/gid `1000` |
| Groups | `trt-ryzen7`, `nobody` |
| Swap | なし |

`/etc/vconsole.conf` は fallback のみで、`KEYMAP` はコメントアウト。

## ハードウェア

| 項目 | 現在値 |
|---|---|
| Vendor | LENOVO |
| Model | ThinkPad T14 Gen 5 |
| Product name | `21MCCTO1WW` |
| BIOS | `R2LET30W (1.11 )`, 2024-11-11 |
| CPU | AMD Ryzen 7 PRO 8840U w/ Radeon 780M Graphics |
| CPU cores/threads | 8 cores / 16 threads |
| RAM | 30GiB |
| GPU | AMD HawkPoint1 / amdgpu |
| Ethernet | Realtek RTL8111/8168/8211/8411, `r8169` |
| Wi-Fi | Qualcomm QCNFA765, `ath11k_pci` |
| Storage | Micron 3500 NVMe SSD |
| Thunderbolt/USB4 | AMD Pink Sardine USB4/Thunderbolt controllers |

NixOS では AMD GPU, Vulkan, PipeWire, Wi-Fi firmware, fingerprint, TLP/power profile 周辺を明示的に有効化する。

## ディスクと起動

`lsblk -f` で確認できた構成:

| Device | FS | UUID | Mount |
|---|---|---|---|
| `nvme0n1p1` | vfat FAT32 | `D94E-D64E` | ESP と推定。ただし `/efi` 権限不足で未確認 |
| `nvme0n1p2` | ext4 | `c1e9791a-ef8d-4a06-8342-795046372c11` | `/`, `/home/trt-ryzen7`, `/gnu/store`, `~/.codex` |

`/etc/fstab` は実質空。`/proc/cmdline` は次の通り。

```text
BOOT_IMAGE=/boot/vmlinuz-linux root=UUID=c1e9791a-ef8d-4a06-8342-795046372c11 rw loglevel=3 noquiet
```

インストール済み boot 関連パッケージ:

- `grub`
- `efibootmgr`
- `btrfs-progs`

ただし実際の bootloader エントリは `/efi` 未確認。NixOS インストール前に root で確認する。

## Pacman 設定

`/etc/pacman.conf`:

- enabled repos: `[core]`, `[extra]`, `[multilib]`
- `ParallelDownloads = 5`
- `CheckSpace`
- `SigLevel = Required DatabaseOptional`
- `LocalFileSigLevel = Optional`

`/etc/pacman.d/hooks` は存在しない。

## 明示インストール済み pacman パッケージ

### 公式リポジトリ

```text
actionlint
base
base-devel
bashtop
bat
bind
bluez
bluez-utils
brightnessctl
btrfs-progs
celluloid
chromium
cmake
code
dhcpcd
discord
docker
docker-compose
efibootmgr
emacs
eza
fastfetch
fcitx5
fcitx5-configtool
fcitx5-gtk
fcitx5-mozc
fcitx5-qt
fcitx5-skk
firefox
firefox-i18n-ja
fprintd
fwupd
gdb
geoclue
gimp
git
github-cli
gitleaks
graphviz
grim
grub
incus
iwd
jdk21-openjdk
jq
keyd
kitty
less
libreoffice-fresh
libvterm
linux
linux-firmware
lsd
lxappearance
ly
man-db
maven
mpv
msmtp
msmtp-mta
net-tools
nethogs
nodejs
noto-fonts
noto-fonts-cjk
noto-fonts-emoji
npm
nvm
nyancat
nyxt
obs-studio
obsidian
ollama-vulkan
openssh
otf-ipafont
papirus-icon-theme
patchelf
pavucontrol
pipewire-pulse
pnpm
polkit-kde-agent
prismlauncher
pyright
ripgrep
rlwrap
rofi
sbcl
skk-jisyo
slurp
speedtest-cli
sqlitebrowser
steam
strace
sudo
sway
swaybg
swaylock
tesseract
tesseract-data-eng
tesseract-data-jpn
tk
tlp
tlp-rdw
tree
ttf-dejavu
ttf-jetbrains-mono-nerd
ttf-liberation
ttf-sourcecodepro-nerd
unzip
uv
vulkan-tools
w3m
waybar
wev
which
wine
winetricks
wl-clipboard
wl-mirror
xdg-desktop-portal-gnome
xdg-desktop-portal-gtk
xdg-desktop-portal-wlr
xorg-xwayland
yaml-language-server
zip
zsh
```

### AUR / foreign

```text
browsh
discord-ptb
floorp-bin
mecab-git
mecab-ipadic
minecraft-launcher
moocs-collect-cli
ocrmypdf
oldschool-pc-fonts
skk-emoji-jisyo-ja
ttf-hackgen
ttf-plemoljp-bin
voicevox-appimage
webkit2gtk
yay
yay-debug
```

Flatpak/Snap はコマンド未導入。

## 主要パッケージバージョン

| Package | Version |
|---|---|
| `linux` | `7.0.11.arch1-1` |
| `linux-firmware` | `20260519-1` |
| `sway` | `1:1.12-1` |
| `waybar` | `0.15.0-2` |
| `fcitx5` | `5.1.19-1` |
| `fcitx5-skk` | `5.1.10-1` |
| `fcitx5-mozc` | `3.33.6133.2-1` |
| `kitty` | `0.47.1-1` |
| `rofi` | `2.0.0-1` |
| `ly` | `1.4.1-1` |
| `keyd` | `2.6.0-5` |
| `tlp` | `1.10.0-1` |
| `docker` | `1:29.5.2-1` |
| `incus` | `7.1.0-2` |
| `ollama-vulkan` | `0.30.4-1` |
| `emacs` | `30.2-3` |
| `zsh` | `5.9.1-1` |
| `nodejs` | `26.2.0-1` |
| `npm` | `11.16.0-1` |
| `pnpm` | `11.3.0-1` |
| `uv` | `0.11.19-1` |
| `jdk21-openjdk` | `21.0.11.u10-1` |
| `maven` | `3.9.16-1` |

注意: 実際の `node` は nvm の `v24.12.0` が使われていた。

## systemd system units

`systemctl --root=/ list-unit-files --type=service --state=enabled` と `/etc/systemd/system` から確認。

enabled service:

```text
avahi-daemon.service
bluetooth.service
dhcpcd.service
docker.service
getty@.service
guix-daemon.service
iwd.service
keyd.service
ollama.service
systemd-timesyncd.service
tlp.service
```

display manager:

- `/etc/systemd/system/display-manager.service -> /usr/lib/systemd/system/ly.service`

custom unit:

- `/etc/systemd/system/guix-daemon.service`
- `/etc/systemd/system/gnu-store.mount`

`guix-daemon.service` は `/var/guix/profiles/per-user/root/current-guix/bin/guix-daemon --build-users-group=guixbuild --discover=no` を起動する。

NixOS 化候補:

- `services.avahi.enable = true`
- `hardware.bluetooth.enable = true`
- `networking.wireless.iwd.enable = true`
- `networking.useDHCP` または interface 別 DHCP
- `virtualisation.docker.enable = true`
- `virtualisation.incus.enable = true` は利用継続するなら
- `services.ollama.enable = true` と Vulkan/ROCm 方針の再検討
- `services.tlp.enable = true`
- `services.timesyncd.enable = true`
- `services.keyd.enable = true`
- `services.displayManager.ly.enable = true` 相当

## systemd user units

重要ファイル:

- `~/.config/systemd/user/emacs.service`
- `~/.config/systemd/user/default.target.wants/emacs.service`
- `~/.config/systemd/user/waybar-localtime-refresh.service`
- `~/.config/systemd/user/waybar-localtime-refresh.timer`
- `~/.config/systemd/user/timers.target.wants/waybar-localtime-refresh.timer`

`emacs.service`:

- `Type=forking`
- `ExecStart=/usr/bin/emacs --daemon`
- `ExecStop=/usr/bin/emacsclient -e "(kill-emacs)"`
- IME を明示的に無効化:
  - `GTK_IM_MODULE=gtk-im-context-simple`
  - `XMODIFIERS=@im=none`
  - `UnsetEnvironment=QT_IM_MODULE INPUT_METHOD SDL_IM_MODULE`

`waybar-localtime-refresh.timer`:

- `OnActiveSec=30s`
- `OnStartupSec=30s`
- `OnBootSec=30s`
- `OnUnitActiveSec=5min`
- `Persistent=true`

## Desktop / Wayland

### Sway

主設定:

- `~/.config/sway/config`
- `~/.local/share/wayland-sessions/sway.desktop`
- `~/.local/bin/sway-fcitx`

Sway の特徴:

- `$mod = Mod4`
- terminal: `kitty`
- launcher: `rofi -show drun`
- workspace は `u i o p [ j k l ; '` に割り当て
- 移動キーは Emacs 風:
  - left `b`
  - down `n`
  - up `p`
  - right `f`
- output:
  - `DP-7` position `0 0`
  - `eDP-1` position `0 1080`
- touchpad:
  - tap
  - natural scroll
  - middle emulation
- keyboard:
  - `xkb_options "caps:ctrl_modifier"`
- autostart:
  - `waybar`
  - `fcitx5 -dr`
- portal 環境:
  - `systemctl --user import-environment`
  - `dbus-update-activation-environment`
  - `xdg-desktop-portal-wlr.service` と `xdg-desktop-portal.service` を restart
- screenshot:
  - `grim`
  - `slurp`
  - `wl-copy`
  - 保存先: `~/Media/screenshots`

`~/.local/share/wayland-sessions/sway.desktop`:

- `Exec=/home/trt-ryzen7/.local/bin/sway-fcitx`

`~/.local/bin/sway-fcitx`:

- fcitx5 関連 env を export
- `dbus-update-activation-environment --systemd ...`
- `fcitx5 -dr` を background 起動
- `exec sway "$@"`

### Niri

設定ファイル:

- `~/.config/niri/config.kdl`

状態:

- niri パッケージは明示インストール一覧には見えない。
- 設定は存在するが、Sway ほど live session としての証拠はない。

設定の特徴:

- touchpad tap/natural-scroll
- layout gaps `16`
- focus ring active color `#7fc8ff`
- `spawn-at-startup "waybar"`
- `screenshot-path "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"`
- keybind は niri default 風に Mod+H/J/K/L, Mod+1..9 など。

NixOS では、まず Sway を優先して移し、niri は必要なら追加する。

### xdg-desktop-portal

設定:

- `~/.config/xdg-desktop-portal/portals.conf`
- `~/.config/xdg-desktop-portal/sway-portals.conf`

内容:

```ini
[preferred]
default=gtk
org.freedesktop.impl.portal.Screenshot=wlr
org.freedesktop.impl.portal.ScreenCast=wlr
org.freedesktop.impl.portal.Inhibit=none
```

OBS screen capture のため `xdg-desktop-portal-wlr` が重要。

## Waybar

主設定:

- `~/.config/waybar/config`
- `~/.config/waybar/style.css`
- `~/.config/waybar/scripts/localtime-display.sh`
- `~/.config/waybar/scripts/localtime-refresh.sh`
- `~/.config/waybar/scripts/ime.sh`
- `~/.config/waybar/scripts/ime-toggle.sh`
- `~/.config/waybar/scripts/test-localtime-switch.sh`

表示構成:

- left:
  - `sway/workspaces`
  - `sway/mode`
  - `sway/scratchpad`
  - `custom/media`
- center:
  - `custom/localtime`
  - `custom/ime`
- right:
  - `battery`
  - `pulseaudio`
  - `network`
  - `power-profiles-daemon`

`custom/localtime`:

- exec: `~/.config/waybar/scripts/localtime-display.sh`
- `return-type = json`
- cache: `~/.cache/waybar-localtime/state.json`
- OS timezone ではなく cache 内 timezone を優先して表示
- cache には緯度経度が含まれるため、値を公開ドキュメントに載せない

`localtime-refresh.sh`:

- GeoClue `where-am-i`
- fallback: iwd + BeaconDB
- timezone 変換: `~/.cargo/bin/tzf`
- test env:
  - `WAYBAR_LOCALTIME_TEST_LAT`
  - `WAYBAR_LOCALTIME_TEST_LNG`

`custom/ime`:

- `ime.sh` が `fcitx5-remote -n` を見て `[ IME : FCITX5 ]` または `[ IME : SKK ]`
- click で `ime-toggle.sh`
- `ime-toggle.sh` は `skk` と `keyboard-us` を切り替える

style:

- 黒背景 + orange/red 系
- `#custom-localtime` と `#custom-ime` を同一 pill style
- `#custom-ime.ime-fcitx5` は赤
- network/audio/battery に状態別色

## IME / Keyboard

### fcitx5

設定:

- `~/.config/fcitx5/profile`
- `~/.config/fcitx5/config`
- `~/.config/environment.d/fcitx5.conf`
- `~/.config/environment.d/ime.conf`
- `~/.config/environment.d/ime-fcitx5.conf`

profile:

- group: `Default`
- default layout: `us`
- default input method: `keyboard-us`
- items:
  - `skk`
  - `keyboard-us`

hotkeys:

- toggle:
  - `Shift+space`
  - `Zenkaku_Hankaku`
  - `Hangul`
- group forward:
  - `Super+space`
- group backward:
  - `Shift+Super+space`
- candidate:
  - previous `Shift+Tab`
  - next `Tab`

environment:

- `GTK_IM_MODULE=fcitx`
- `QT_IM_MODULE=fcitx`
- `XMODIFIERS=@im=fcitx`
- `INPUT_METHOD=fcitx`
- `SDL_IM_MODULE=fcitx`
- `GLFW_IM_MODULE=ibus`

注意: `~/.config/environment.d/ime.conf` の先頭に `(getenv_GTK_IM_MODULE=fcitx` のような壊れた行がある。NixOS 化時に整理する。

### keyd

設定:

- `/etc/keyd/default.conf`

内容:

```ini
[ids]
0001:0001:09b4e68d

[main]
capslock = layer(control)

[control]
a = home
e = end
h = backspace
d = delete
p = up
n = down
b = left
f = right
```

注意: 過去に device ID mismatch が問題になったため、NixOS 移行後は `keyd monitor` / `keyd list-keys` 相当で対象 ID を再確認する。

## Shell

主設定:

- `~/.zshrc`
- `~/.zprofile`
- `~/.zshenv`
- `~/.oh-my-zsh`

`~/.zshrc`:

- Oh My Zsh
- theme: `agnoster-orange-plain`
- plugins:
  - `git`
  - `zsh-autosuggestions`
  - `zsh-syntax-highlighting`
- `NVM_DIR="$HOME/.nvm"`
- interactive shell 起動時に `fcitx5-remote -c`
- `EDITOR=emacs`
- Guix profile を source
- conda init block が残っているが、現状 conda は壊れている

`~/.zprofile`:

- Guix user profile
- `PATH="$HOME/.local/bin:$PATH"`

`~/.zshenv`:

- 平文 API key があるため、このまま NixOS へ移さない

NixOS/Home Manager 方針:

- `programs.zsh.enable = true`
- Oh My Zsh theme/plugin を Home Manager で管理
- `~/.zshenv` の秘密値は削除
- nvm を使い続けるか、Nix devShell/direnv へ寄せるか決める

## Terminal / Launcher / Lock

### kitty

設定:

- `~/.config/kitty/kitty.conf`

重要値:

- foreground `#F66E25`
- red/orange palette override
- `allow_remote_control yes`
- `ctrl+enter` を Enter と同等に送信
- `adjust_line_height 1`

### rofi

設定:

- `~/.config/rofi/config.rasi`
- `~/.config/rofi/mytheme.rasi`

`config.rasi` は大部分が generated/default コメントで、末尾で `@theme "~/.config/rofi/mytheme.rasi"`。

### swaylock

設定:

- `~/.config/swaylock/config`
- `~/.local/bin/lock.sh`

黒背景、indicator 透明/赤系。Sway config では `gtklock -d` と `swaylock` の両方の keybind 痕跡があるが、`gtklock` は pacman 明示一覧にはない。NixOS では `swaylock` に寄せるのが安全。

## Emacs

主設定:

- `~/.emacs.d/init.el`
- `~/.emacs.d/early-init.el`
- `~/.emacs.d/theme/my-theme-theme.el`
- `~/.emacs.d/tree-sitter/*.so`
- `~/.config/systemd/user/emacs.service`

early-init:

- `package-enable-at-startup nil`
- startup screen 無効
- menu/tool/scroll bar 無効

package 管理:

- `straight.el`
- `use-package`
- ELPA に `gptel`, `cond-let`, `transient`

主な straight repos:

- `gptel`
- `gptel-magit`
- `magit`
- `vterm`
- `nskk.el`
- `org`
- `vertico`
- `orderless`
- `marginalia`
- `consult`
- `embark`
- `corfu`
- `cape`
- `treemacs`
- `diff-hl`
- `apheleia`
- `jupyter`
- `ein` 関連
- `yaml-mode`

重要設定:

- `nskk-global-mode 1`
- system dictionary:
  - `/usr/share/skk/SKK-JISYO.L`
  - `/usr/share/skk/SKK-JISYO.jinmei`
  - `/usr/share/skk/SKK-JISYO.geo`
- user dictionary:
  - `~/.emacs.d/nskk-jisyo`
- minibuffer completion:
  - vertico/orderless/marginalia/consult/embark
- in-buffer completion:
  - corfu/cape
- programming:
  - eglot
  - flymake
  - apheleia
  - treesit
  - yaml-mode
- Git:
  - magit
  - diff-hl
- terminal:
  - vterm
  - `vterm-always-compile-module t`
- clipboard:
  - Wayland clipboard integration via `wl-copy`/`wl-paste` 系の独自関数
- LLM:
  - `gptel`
  - INIAD OpenAI-compatible backend
  - INIAD Anthropic-compatible backend
  - key は `auth-source` / env `INIAD_OPENAI_API_KEY` から取得
- Magit AI helper:
  - commit plan / commit message generation helpers
- Org:
  - org-babel languages

NixOS 移行方針:

- 最初は `~/.emacs.d` を丸ごとバックアップして復元
- その後、system packages と Emacs packages を分離
- `libvterm`, tree-sitter grammar, SKK dictionaries を Nix 側に入れる
- `emacs.service` の IME 無効化 env を Home Manager user unit で再現
- `~/.authinfo.gpg` と GPG 復号環境を先に復旧する

## Git / SSH / GPG

### Git

`~/.gitconfig`:

- `pull.rebase = false`
- `http.sslcainfo = /etc/ca-certificates/extracted/tls-ca-bundle.pem`
- GitHub URL rewrite:
  - personal/private 用 host alias
  - INIAD 用 host alias
  - `geeken-iniad` 用 host alias
- `core.sshCommand = ssh -F ~/.ssh/config`
- `includeIf gitdir:/home/trt-ryzen7/Iniad/` で `~/.gitconfig-iniad`

`~/.gitconfig-iniad`:

- `git@github.com:` を `git@github-iniad:` へ rewrite

NixOS 注意:

- `http.sslcainfo` は Arch 固有パス。NixOS では `/etc/ssl/certs/ca-bundle.crt` などに変わるため、そのまま移すと Git HTTPS が壊れる可能性がある。

### SSH

`~/.ssh/config`:

- `github.com` -> `~/.ssh/id_ed25519_personal`
- `github-personal`, `github-private` -> `~/.ssh/id_ed25519_personal`
- `github-iniad` -> `~/.ssh/id_ed25519_iniad`
- `IdentitiesOnly yes`
- `AddKeysToAgent yes`

private keys:

- `~/.ssh/id_ed25519`
- `~/.ssh/id_ed25519_personal`
- `~/.ssh/id_ed25519_iniad`

### GPG

`~/.gnupg` は存在するが、`gpg --list-keys` / `gpg --list-secret-keys` は keyboxd 起動エラーで失敗。

重要:

- `~/.gnupg` は必ず暗号化バックアップ
- NixOS 移行後に `gpg --list-secret-keys` と `.authinfo.gpg` 復号を確認

## 開発環境

### Node.js

pacman:

- `nodejs 26.2.0-1`
- `npm 11.16.0-1`
- `pnpm 11.3.0-1`
- `nvm 0.40.4-1`

実際の shell:

- `node --version`: `v24.12.0`
- `npm --version`: `11.6.2`
- `pnpm --version`: `11.6.0`

nvm installed:

- `v20.19.6`
- `v24.10.0`
- `v24.11.1`
- `v24.12.0` active/default

global npm packages under active nvm:

```text
@astrojs/language-server@2.16.3
@nestjs/cli@11.0.21
@openai/codex@0.142.1
corepack@0.34.5
npm@11.6.2
sass@1.97.3
typescript-language-server@5.3.0
typescript@6.0.3
```

方針:

- NixOS では system Node と nvm Node の二重管理を避ける。
- プロジェクトごとは `direnv` + Nix devShell、または nvm 継続のどちらかに寄せる。

### Python / uv / Conda

- `python --version`: `Python 3.14.5`
- `uv --version`: `0.11.19`
- `~/.cache/uv`: 7.3G
- `~/.cache/pip`: 404M

Conda:

- `~/miniconda3`: 6.5G
- env: `ds2026` が存在
- ただし `~/miniconda3/condabin/conda` は `~/miniconda3/bin/python` 不在で起動不能
- `~/.condarc`:
  - channels: `pkgs/main`, `pkgs/r`
  - `auto_activate_base: false`

方針:

- Conda は再インストール/再作成推奨。
- `ds2026` の package list は現状 conda が動かず取得不可。必要なら移行前に修復して export する。

### Rust

- `rustup`
- default toolchain: `stable-x86_64-unknown-linux-gnu`
- `cargo 1.91.1`
- `rustc 1.91.1`
- installed target: `x86_64-unknown-linux-gnu`
- `~/.cargo/bin/tzf` が Waybar timezone refresh に必須

方針:

- `tzf` は Nix package があれば Nix 管理へ。なければ cargo install 手順を Home Manager activation ではなく手動メモへ。

### Java / Maven

- OpenJDK `21.0.11`
- Maven `3.9.16`

### Go / Ruby / Lisp

- `go version go1.26.4-X:nodwarf5 linux/amd64`
- `ruby 3.4.8`
- `sbcl` installed

### Guix

systemd:

- `guix-daemon.service`
- `gnu-store.mount`

profile:

- shell で `~/.config/guix/current/etc/profile` と `~/.guix-profile/etc/profile` を source

manifest:

```scheme
(specifications->manifest
 '(
   "git"
   "btop"
   ))
```

channels:

- default channels
- nonguix channel

installed:

- `git 2.52.0`
- `btop 1.4.5`

NixOS へ移るなら Guix を残す必要性は再検討。残すなら Guix daemon と `/gnu/store` の扱いを別途設計する。

## Containers / VM / Local LLM

### Docker

- package installed
- `docker.service` enabled
- `/var/lib/docker` は存在するが、権限不足で中身未確認
- `docker ps -a` / `docker images` は socket permission denied

移行前に root で以下を取得:

```sh
sudo docker ps -a
sudo docker images
sudo docker volume ls
sudo docker network ls
```

### Incus

- package installed
- `incus.socket` symlink あり
- `/var/lib/incus` は存在するが、権限不足で中身未確認
- `incus list` は socket permission denied

移行前に root で確認:

```sh
sudo incus list
sudo incus storage list
sudo incus profile list
```

### Ollama

- `ollama-vulkan 0.30.4-1`
- `ollama.service` enabled
- `ollama --version` は client version のみ確認、server へは接続不可
- `~/.ollama` は 8K でモデル実体はほぼ無いように見えるが、socket 制限で `ollama list` は未確認

方針:

- NixOS では `services.ollama.enable = true`
- AMD iGPU/Vulkan/ROCm 方針を再確認
- model は再 pull 前提でもよい

## Network

インストール:

- `iwd`
- `dhcpcd`
- `networkmanager` は依存/通常パッケージとして存在するが、enabled service ではない

enabled:

- `iwd.service`
- `dhcpcd.service`

未確認:

- `/var/lib/iwd` は permission denied。Wi-Fi network profile はここにある可能性が高い。
- `/etc/NetworkManager/system-connections` は permission denied。NetworkManager が有効でないため優先度は低い。

NixOS 方針:

- iwd + dhcpcd を継続するか、NetworkManager へ寄せるか決める。
- 現状踏襲なら iwd を有効化。

## Audio / Video / OBS

packages:

- `pipewire-pulse`
- `pavucontrol`
- `obs-studio`
- `mpv`
- `celluloid`
- `wl-mirror`
- `xdg-desktop-portal-wlr`
- `xdg-desktop-portal-gtk`
- `xdg-desktop-portal-gnome`

状態:

- `~/.config/obs-studio`: 116M
- portal 設定は wlr screen capture を優先

NixOS:

- PipeWire/PulseAudio compatibility
- OBS + portal-wlr
- Wayland screen capture

## Browsers / GUI apps

明示パッケージ:

- Firefox + Japanese language pack
- Chromium
- Floorp AUR
- Nyxt
- Discord / Discord PTB
- Obsidian
- LibreOffice
- GIMP
- VoiceVox AppImage
- Steam
- PrismLauncher
- Minecraft Launcher
- Wine / Winetricks

Firefox:

- `~/.mozilla/firefox/profiles.ini`
- default release: `yb4vcvde.default-release-1760951239020`
- other profiles:
  - `ug4ccrx9.default`
  - `2s29vf7m.default-release`

Obsidian:

- `~/.config/obsidian/obsidian.json` points to vault path `/home/trt-ryzen7/obsidian`
- ただし `/home/trt-ryzen7/obsidian` は今回の `find` では確認できなかった。vault の実在要確認。

VS Code OSS:

- `~/.config/Code - OSS/User/settings.json` は `{}` のみ
- extensions:
  - `llvm-vs-code-extensions.vscode-clangd`
  - `esbenp.prettier-vscode`
  - `lordimmaculate.platformio-ide`
  - `dbaeumer.vscode-eslint`

## Fonts / Themes

pacman fonts:

- `noto-fonts`
- `noto-fonts-cjk`
- `noto-fonts-emoji`
- `otf-ipafont`
- `ttf-dejavu`
- `ttf-hackgen` AUR
- `ttf-jetbrains-mono-nerd`
- `ttf-liberation`
- `ttf-plemoljp-bin` AUR
- `ttf-sourcecodepro-nerd`
- `oldschool-pc-fonts` AUR

local fonts:

- `~/.local/share/fonts/material-design-icons.ttf`
- `~/.local/share/fonts/file-icons.ttf`
- `~/.local/share/fonts/octicons.ttf`
- `~/.local/share/fonts/all-the-icons.ttf`
- `~/.local/share/fonts/fontawesome.ttf`
- `~/.local/share/fonts/weathericons.ttf`

fontconfig:

- `fc-match monospace`: Noto Sans Mono
- `fc-match sans`: Noto Sans

theme/icons:

- `papirus-icon-theme`
- GTK config:
  - `~/.config/gtk-3.0/settings.ini`
  - `~/.config/gtk-4.0/settings.ini`
  - `~/.gtkrc-2.0`

## Mail / external CLIs

`msmtp`:

- `~/.config/msmtp/config`
- account `fes`
- SMTP host and user are configured
- password は平文。値は記録しない

Cloudflare/Wrangler:

- `~/.config/.wrangler`
- OAuth token/refresh token present
- many logs under `~/.config/.wrangler/logs`
- NixOS 移行後は `wrangler login` で再認証推奨

GitHub CLI:

- `~/.config/gh/config.yml`
- `gh` alias: `co: pr checkout`
- auth file has token. 再ログイン推奨

Kaggle:

- `~/.kaggle/credentials.json` exists and contains token

Qiita CLI:

- `~/.config/qiita-cli/credentials.json` exists and contains token

## データとバックアップ対象

### 最優先でバックアップ

```text
~/.ssh
~/.gnupg
~/.authinfo.gpg
~/.gitconfig
~/.gitconfig-iniad
~/.emacs.d
~/.config/sway
~/.config/waybar
~/.config/fcitx5
~/.config/environment.d
~/.config/systemd/user
~/.config/kitty
~/.config/rofi
~/.config/swaylock
~/.local/bin/sway-fcitx
~/.local/bin/lock.sh
~/.local/share/wayland-sessions/sway.desktop
~/.local/share/fonts
~/.mozilla/firefox
~/.floorp
~/Dev
~/Iniad
~/Intern26
~/Articles
~/GeeKEN
~/Media
~/Study
~/learnEnglish
~/memos
```

### アプリ状態として必要ならバックアップ

```text
~/.config/obs-studio
~/.config/obsidian
~/.config/chromium
~/.config/discord
~/.config/discordptb
~/.config/Code - OSS
~/.vscode-oss
~/.local/share/Steam
~/.local/share/PrismLauncher
~/.minecraft
~/.config/WarThunder
~/.local/share/Paradox Interactive
~/.paradoxlauncher
~/.local/share/applications
~/.local/share/pnpm
~/.nvm
~/.rustup
~/.cargo
~/.m2
~/.platformio
~/.clojure
```

### 再生成可能または捨てる候補

```text
~/.cache
~/.npm/_cacache
~/.cache/yay
~/.cache/uv
~/.cache/ms-playwright
~/.cache/pnpm
~/.cache/puppeteer
~/.cache/pip
~/.local/share/Trash
node_modules
dist
target
.venv
```

### 大きいディレクトリ

| Path | Size | 扱い |
|---|---:|---|
| `~/.local/share/Steam` | 88G | ゲームを再ダウンロードしたくないならバックアップ |
| `~/.cache` | 23G | 原則破棄可。ただし一部作業中キャッシュに注意 |
| `~/.npm` | 13G | 原則破棄可 |
| `~/Downloads` | 6.8G | 手で仕分け |
| `~/miniconda3` | 6.5G | 壊れているため再作成推奨 |
| `~/Dev` | 5.7G | バックアップ |
| `~/.config` | 4.9G | 設定はバックアップ。Discord 等の巨大 state は選別 |
| `~/Iniad` | 4.3G | バックアップ |
| `~/Intern26` | 4.3G | バックアップ |
| `~/.local/share/Trash` | 5.6G | 原則削除候補 |
| `~/.nvm` | 2.0G | nvm 継続ならバックアップ、Nix に寄せるなら不要 |
| `~/.minecraft` | 1.2G | ゲーム状態として必要なら |
| `~/.rustup` | 1.3G | 再生成可 |
| `~/.codex` | 1.2G | Codex 履歴/設定が必要ならバックアップ |

## 主要 Git リポジトリ

`.cache/yay` 由来を除いた、目立つ作業リポジトリ:

```text
~/.emacs.d
~/Articles
~/kaggle-project
~/keyd
~/nlp-study
~/Intern26/MicroPost-26
~/Intern26/MicroPost-26/backend
~/Intern26/MicroPost-26/frontend
~/Intern26/practiceNestJS
~/GeeKEN/GeeK-en-English
~/GeeKEN/SelfIntroduction
~/Iniad/ux-ex
~/Iniad/ds_ex
~/Iniad/cs3-ex
~/Iniad/algorithm
~/Iniad/soft_ex/lecture02
~/Iniad/cs3_lecture_again
~/Iniad/cs3_lecture_again/study_for_midterm
~/Dev/BiblioTECK_mock
~/Dev/LExEco
~/Dev/LExEco/lexeco-core
~/Dev/ox-hub
~/Dev/GeekenWebsite/web-site
~/Dev/moocs-mystyle
~/Dev/miyatarutyyy
~/Dev/histolink
~/Dev/I_will_BINGO
~/Dev/GeeKEN-Gate-2.0
~/Dev/MiyatarutyyyBlog
~/Dev/typyyyne
~/Dev/archivyyy
~/Dev/GeeKEN_BiblioTECK
~/Dev/org-converter
~/Dev/GeeKEN-Gate
~/Dev/hackathon/MinKara
~/Dev/hackathon/Are-you-a-robot
~/Dev/my-chatgpt-outfit
```

移行前に各 repo で `git status --short --branch` を取り、未 push / 未 commit を確認する。

## NixOS / Home Manager への対応表

| 現在の対象 | NixOS/Home Manager 候補 |
|---|---|
| `linux`, firmware, AMD GPU | `boot.kernelPackages`, `hardware.graphics`, AMD firmware |
| Sway | `programs.sway.enable`, `services.displayManager`, `xdg.portal` |
| Ly | `services.displayManager.ly.enable` |
| Waybar | Home Manager `programs.waybar` または dotfile 配置 |
| fcitx5/SKK/Mozc | `i18n.inputMethod` / fcitx5 addons |
| keyd | `services.keyd` |
| TLP | `services.tlp` |
| Bluetooth | `hardware.bluetooth` |
| iwd/dhcpcd | `networking.wireless.iwd` + DHCP 方針 |
| Docker | `virtualisation.docker` |
| Incus | `virtualisation.incus` |
| Ollama | `services.ollama` |
| PipeWire | `services.pipewire` |
| fonts | `fonts.packages` |
| zsh/oh-my-zsh | Home Manager `programs.zsh` |
| Emacs daemon | Home Manager `systemd.user.services.emacs` |
| Git | Home Manager `programs.git` |
| SSH config | Home Manager `programs.ssh` |
| secrets | `sops-nix` or `agenix` |
| user packages | Home Manager `home.packages` |

## 初期 NixOS 設定の優先順位

1. Boot できる最小 NixOS。
2. user `trt-ryzen7`、zsh、network、sudo/wheel の復旧。
3. Sway + Ly + xdg-desktop-portal-wlr + PipeWire + fcitx5。
4. `~/.config/sway`, `~/.config/waybar`, `~/.config/fcitx5`, `~/.local/bin/sway-fcitx` を復元。
5. SSH/GPG/auth-source を復元し、GitHub/Cloudflare/Kaggle/Qiita は再ログイン。
6. Emacs daemon と `~/.emacs.d` を復元。
7. Dev tools: Node, pnpm, uv, JDK, Maven, Rust, Go, Docker。
8. GUI apps/games は必要順に復元。

## フォーマット直前の最終確認コマンド

root 権限が必要なもの:

```sh
sudo bootctl status
sudo efibootmgr -v
sudo findmnt -R /
sudo lsblk -f
sudo systemctl list-unit-files --state=enabled
sudo systemctl status ly iwd dhcpcd docker keyd tlp ollama guix-daemon
sudo ls -la /var/lib/iwd
sudo docker ps -a
sudo docker images
sudo docker volume ls
sudo incus list
sudo incus storage list
sudo du -h --max-depth=1 /var/lib/docker /var/lib/incus
```

user 権限でよいもの:

```sh
git -C ~/.emacs.d status --short --branch
git -C ~/Dev/GeeKEN-Gate status --short --branch
git -C ~/Intern26/MicroPost-26 status --short --branch
gpg --list-secret-keys --keyid-format LONG
ssh -T git@github.com
ssh -T git@github-iniad
~/.config/waybar/scripts/test-localtime-switch.sh
```

secret rotation:

```sh
gh auth status
wrangler whoami
```

値を表示するコマンドは shell history やログに残さないよう注意する。

## 移行で捨ててよい可能性が高いもの

- pacman/yay build cache
- browser/electron cache
- npm/pnpm/uv/pip cache
- Playwright/Puppeteer cache
- `node_modules`
- build artifacts: `dist`, `target`, `.next`, `.vite`
- Trash
- 壊れている `~/miniconda3` は、必要な env 定義が取れないなら再構築

## 未解決・要判断

1. NixOS で Sway を主環境にするか、niri へ移行するか。
2. Node.js を nvm 継続にするか、Nix devShell/direnv へ寄せるか。
3. Guix を NixOS 上でも併用するか。
4. Docker/Incus の既存コンテナ・volume を移す必要があるか。
5. Steam/Minecraft/PrismLauncher/WarThunder などゲームデータを丸ごと移すか、再ダウンロードするか。
6. `~/.zshenv`, `msmtp`, `gh`, `wrangler`, `kaggle`, `qiita-cli` の secret をどの secret manager へ寄せるか。
7. `~/obsidian` vault が存在するか。`~/.config/obsidian/obsidian.json` には path が残っているが、今回の探索では実体未確認。
8. GPG keyboxd のエラー原因。NixOS 移行前に GPG 秘密鍵の export/backup ができるか確認する。

## この文書の検証メモ

実行して確認した主なコマンド:

- `cat /etc/os-release`
- `uname -a`
- `lscpu`
- `free -h`
- `id`
- `lsblk -f`
- `findmnt -R /`
- `cat /etc/fstab`
- `cat /proc/cmdline`
- `pacman -Qqen`
- `pacman -Qqem`
- `pacman -Qqe`
- `systemctl --root=/ list-unit-files --type=service --state=enabled`
- `find /etc/systemd/system`
- `find ~/.config/systemd/user`
- `find ~/.config -maxdepth 2 -type f`
- `find ~/.local/bin -maxdepth 2 -type f`
- `find ~/.ssh -maxdepth 2 -type f`
- `find ~/.gnupg -maxdepth 2 -type f`
- `lspci -nnk`
- DMI files under `/sys/class/dmi/id`
- `readlink -f /etc/localtime`
- selected `sed`/`rg` over Sway, Waybar, fcitx5, zsh, Emacs, Git, SSH, Ly, TLP, keyd
- `du -h --max-depth=1` over home and major state directories

失敗した主なコマンド:

- `hostnamectl`: system bus permission denied
- `timedatectl status`: system bus permission denied
- `bootctl status`: `/efi` permission denied
- `systemctl list-unit-files` without `--root`: bus permission denied
- `systemctl --user list-unit-files`: user bus permission denied
- `lsusb`: libusb initialization failed
- `vulkaninfo --summary`: no valid GPU in sandbox
- `ip link`: netlink permission denied
- `rfkill list`: `/dev/rfkill` unavailable
- `docker ps -a`: docker socket permission denied
- `incus list`: incus socket permission denied
- `ollama list`: loopback/socket permission denied
- `gpg --list-keys`: keyboxd failed to start
