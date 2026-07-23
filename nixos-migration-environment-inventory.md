# NixOS 移行用 環境棚卸し

調査日: 2026-07-23  
対象ユーザー: `tarutyyyne`  
注意: 秘密値は記録していない。存在したファイルパス、種類、移行方針だけを記録する。

## 1. 重要な結論

- この PC は実測では Arch Linux ではなく `NixOS 26.05 (Yarara)`。ホスト名は `thinkpad-l480`。
- 主用途は Wayland デスクトップ、Emacs/Org、TypeScript/Arduino/TeX、GitHub CLI、Claude/Codex 系 CLI、学校/開発リポジトリ作業。
- デスクトップ環境は `niri`。バーは `waybar`、ターミナルは `alacritty`、ランチャーは `rofi`、ロックは `hyprlock`。
- 入力方式は `fcitx5` + `fcitx5-skk`。キーボードリマップは system service `keyd` で CapsLock を control layer にしている。
- 重要サービスは `iwd`、`dhcpcd`、`keyd`、`PipeWire/WirePlumber`、`Home Manager`、`nix-daemon`、`systemd-boot`。
- NixOS 移行時に特に再現が必要なもの:
  - `/etc/nixos` flake 一式。
  - `~/.config/niri/config.kdl`、`~/.config/waybar`、`~/.config/hypr/hyprlock.conf`、`~/.config/alacritty/alacritty.toml`。
  - `~/.emacs.d/init.org` / `init.el` / `themes/` と Home Manager の Emacs パッケージ宣言。
  - `~/.ssh` の鍵と `config`、`~/.config/gh`、`~/.authinfo`、`~/.claude`、`~/.local/share/keyrings` などの秘密/ログイン状態。
  - `~/.local/share/fcitx5/skk/user.dict`。
- 壊れている、または移行前に確認すべきもの:
  - `gh auth status` で GitHub token が無効。
  - `ssh -G github.com` が Nix store 内 `20-systemd-ssh-proxy.conf` の所有者/権限問題で失敗。
  - `/home/tarutyyyne/Git/AtCoder/.git` が空で、Git リポジトリとして壊れている。
  - `/etc/nixos` は Git repo だが所有者が `nobody:nogroup` のため通常の `git status` は dubious ownership で失敗する。`-c safe.directory=/etc/nixos` では確認可。
  - `Discord --version` 実行は sandbox 制限で fatal 終了した。GUI 実行は未確認。
- 秘密情報の扱い:
  - 値はこの文書に記録しない。
  - 移行は secret manager、手動再ログイン、または暗号化バックアップで扱う。
  - 無効な token は移行ではなく再発行/再ログインを優先する。

## 2. 調査時の制限

- Codex sandbox は `bubblewrap` コンテナ内で動作しており、`systemd-detect-virt` は `container-other`。
- `/`、`/boot`、`/nix/store`、`/run`、`/sys`、`/proc` の多くが read-only または権限制限付き。
- live systemd / D-Bus / netlink への接続は制限された。
- `hostnamectl`、`systemctl list-units`、`loginctl` は system bus に接続できず失敗。
- `systemctl --user list-unit-files` は user bus に接続できず失敗。
- `networkctl list`、`resolvectl status`、`ss -tulpen` は netlink / systemd-resolved 権限で失敗。
- `iwctl station wlan0 show` は応答せず、こちらで終了を試みた。接続 SSID は未確認。
- `wpctl status` は PipeWire / RTKit / bus 接続不可で失敗。
- `nix-store -q --references ...` は nix-daemon socket 接続不可で失敗。
- `gpg`、`pacman`、`yay`、`paru`、`flatpak`、`snap`、`lspci`、`lsusb`、`pactl`、`gsettings` は未導入または PATH 上になかった。
- `/var/lib/iwd` は権限不足で中身を確認していない。Wi-Fi profile 名も秘密情報に近いため本文へ記録しない。

## 3. セキュリティと秘密情報

| パス | 状態 | 種類 | 移行方針 |
|---|---:|---|---|
| `~/.zshenv` | なし | shell env | 移行不要 |
| `~/.zshrc` | 31 B | zsh 設定 | 値なし。必要なら dotfiles 化 |
| `~/.bashrc` | symlink | Home Manager 生成 bash 設定 | Nix/Home Manager で再生成 |
| `~/.bash_profile` | symlink | Home Manager 生成 | Nix/Home Manager で再生成 |
| `~/.profile` | symlink | Home Manager session vars | Nix/Home Manager で再生成 |
| `~/.config/gh/hosts.yml` | `0600`, 90 B | GitHub token | 値は記録しない。token は無効なので再ログイン推奨 |
| `~/.config/gh/config.yml` | `0600`, 1661 B | gh 設定 | token 値なしなら移行可。hosts は別扱い |
| `~/.ssh` | `0700` | SSH 鍵/known_hosts/config | 暗号化バックアップ。秘密鍵は値を記録しない |
| `~/.ssh/id_ed25519_github` | `0600` | GitHub 秘密鍵 | 暗号化バックアップまたは再発行 |
| `~/.ssh/id_ed25519_github_iniad` | `0600` | GitHub/INIAD 用秘密鍵 | 暗号化バックアップまたは再発行 |
| `~/.gnupg` | なし | GPG home | 現状移行不要 |
| `~/.authinfo.gpg` | なし | 暗号化 authinfo | 現状移行不要 |
| `~/.authinfo` | `0600`, 63 B | Emacs auth-source 平文秘密 | 暗号化保管へ移す。値は記録しない |
| `~/.config/msmtp/config` | なし | msmtp | 現状移行不要 |
| `~/.claude/.credentials.json` | `0600`, 466 B | Claude 認証 | 値を記録せず、再ログインまたは暗号化移行 |
| `~/.claude.json` | `0600`, 47 KiB | Claude Code 状態 | secret 混入可能。必要なら暗号化移行 |
| `~/.config/.wrangler` | あり | Wrangler logs/metrics | ログのみ確認。認証状態は未確認 |
| `~/.local/share/keyrings` | `0700` | GNOME keyring | ログイン状態。必要なら暗号化バックアップ |
| `~/.pki/nssdb` | `0600` db | NSS cert/key DB | ブラウザ/アプリ証明書状態。必要なら暗号化移行 |
| `~/.floorp/ffxm5uk3.default/key4.db` | `0600` | ブラウザ秘密鍵 DB | ブラウザ profile と一緒に暗号化バックアップ |
| `~/Git/*/.env` | あり | project secrets | 値を記録しない。必要なら暗号化バックアップ |

追加で見つかった秘密候補:

- `~/Git/26-intern/MicroPost-26/.env`
- `~/Git/make-AI-Avater/.env`
- `~/.config/discord/Cookies`、`~/.config/discord/Local Storage`、`~/.config/discord/Trust Tokens`
- `~/.config/pulse/cookie`
- `~/.local/share/vicinae/clipboard.db` と `clipboard-data/`
- `~/.local/share/uv/credentials/`

## 4. システム概要

| 項目 | 値 |
|---|---|
| OS | NixOS 26.05 (Yarara), build `26.05.20260629.1f01958` |
| kernel | Linux `6.18.37` |
| hostname | `thinkpad-l480` |
| architecture | `x86_64` |
| locale | `LANG=en_US.UTF-8`, `LC_ALL=C.UTF-8` |
| timezone | `Asia/Tokyo` (`/etc/zoneinfo/Asia/Tokyo`) |
| shell | `/run/current-system/sw/bin/bash` |
| user | `tarutyyyne`, uid `1000`, gid `100(users)` |
| groups | 実行環境では `users`, `nogroup`。NixOS 設定上は `wheel`, `dialout` も宣言 |
| swap | なし (`Swap: 0B`) |
| virtualization | `container-other` と検出。Codex sandbox の影響あり |

## 5. ハードウェア

| 項目 | 値 |
|---|---|
| vendor / model | Lenovo `20LTA02NJP` |
| BIOS | Lenovo `R0QET60W (1.37)`, 2019-12-18 |
| CPU | Intel Core i5-8250U, 4 cores / 8 threads |
| RAM | 7.5 GiB |
| GPU | Intel iGPU, PCI ID `8086:5917`, driver `i915` |
| Wi-Fi | `wlan0`, Intel PCI ID `8086:24FD`, driver `iwlwifi`, operstate `up` |
| Ethernet | `enp0s31f6`, Intel PCI ID `8086:15D8`, driver `e1000e`, operstate `down` |
| storage | NVMe `SKHynix_HFS256GD9TNG-L5B0B`, firmware `80750C10` |
| battery | `BAT0`, SMP `01AV465`, 調査時 62%, Discharging |

NixOS で有効化が必要そうなもの:

- `hardware.enableRedistributableFirmware = true` 相当。Intel Wi-Fi `iwlwifi` の firmware が必要。
- Intel microcode: `hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;` が既存設定にある。
- GPU は `i915`。通常追加設定なしでよいが Wayland のため mesa/portal を確認する。
- `keyd` は `/dev/uinput` と input group 依存。

## 6. ディスクと起動

`lsblk -f`:

```text
nvme0n1
├─nvme0n1p1 vfat FAT32 LABEL=boot UUID=8D49-5802 MOUNTPOINT=/boot
└─nvme0n1p2 ext4 1.0 LABEL=nixos UUID=d78c73d9-14f2-4ea8-996d-62ffbd1e3f2b MOUNTPOINT=/
```

`findmnt -R /` の要点:

- `/` は `/dev/nvme0n1p2` ext4。sandbox では `ro,nosuid,nodev,relatime` に見える。
- `/home/tarutyyyne`、`/tmp` は同じ ext4 上の bind mount で `rw`。
- `/boot` は `/dev/nvme0n1p1` vfat。sandbox では `ro`。
- `/nix/store` は同じ ext4 上で `ro`。
- `/run`、`/dev`、`/proc`、`/sys` は sandbox 制限付き mount。

`/etc/fstab`:

```text
/dev/disk/by-uuid/d78c73d9-14f2-4ea8-996d-62ffbd1e3f2b / ext4 x-initrd.mount 0 1
/dev/disk/by-uuid/8D49-5802 /boot vfat fmask=0022,dmask=0022 0 2
```

`/proc/cmdline` の要点:

- systemd-boot 経由の NixOS generation。
- `init=/nix/store/...-nixos-system-thinkpad-l480-26.05.20260629.1f01958/init`
- `root=fstab loglevel=4 lsm=landlock,yama,bpf`

bootloader:

- `/etc/nixos/hosts/thinkpad-l480/default.nix` で `boot.loader.systemd-boot.enable = true`、`efi.canTouchEfiVariables = true`。
- `/boot/EFI/systemd/systemd-bootx64.efi` と `/boot/EFI/BOOT/BOOTX64.EFI` は `systemd-boot 260.2`。
- `/boot/loader/entries` に NixOS generation 1-33。
- default entry は generation 33。built on 2026-07-17。
- `bootctl status` は sandbox/container のため「Not booted with EFI」と表示。

root で最終確認:

```bash
bootctl status
efibootmgr -v
lsblk -f
findmnt -R /
blkid
cat /etc/fstab
cat /proc/cmdline
```

## 7. パッケージ

この PC では `pacman`、`yay`、`paru` が未導入。Arch の公式/AUR パッケージ一覧はこの環境からは存在しない。明示インストール相当は `/etc/nixos` flake の宣言で管理されている。

NixOS system packages:

- terminal: `alacritty`
- Wayland desktop: `niri`, `waybar`, `xwayland-satellite`, `wl-clipboard`
- screenshot/recording: `grim`, `slurp`, `wf-recorder`, `libnotify`
- media/audio: `mpv`, `pwvucontrol`, `alsa-utils`
- lock/idle: `hyprlock`, `swayidle`
- launcher: `rofi`
- browser/chat: `floorp-bin`, `discord`
- IME: `fcitx5-configtool`, `skkDictionaries.l`
- dev: `git`, `gh`, `codex`, `claude-code`, `arduino-cli`, `arduino-language-server`, `clang-tools`, `typescript`, `typescript-language-server`, TeX Live medium + Japanese/Beamer packages, `collect-cli`, `herdr`
- Nix features: `nix-command`, `flakes`, `nix-ld`, `direnv`, `nix-direnv`

Home Manager packages:

- `emacs-pgtk`
- Emacs packages: `nix-ts-mode`, `corfu`, `orderless`, `cape`, `yasnippet`, `vterm`, tree-sitter grammars, custom `ox-hub`
- `collect-cli`

Flatpak / Snap:

- `flatpak` command は未導入。ただし `~/.local/share/flatpak/db` だけ存在し、中身は空に見える。
- `snap` command は未導入。

主要バージョン:

| package | version |
|---|---|
| Nix | 2.34.7 |
| Git | 2.54.0 |
| GitHub CLI | 2.93.0 |
| Emacs | 30.2 |
| Alacritty | 0.17.0 |
| niri | 26.04 |
| Waybar | 0.15.0 |
| fcitx5 | 5.1.19 |
| rofi | 2.0.0 |
| Floorp | 152.0.2 |
| Hyprlock | 0.9.5 |
| wf-recorder | 0.6.0 |
| mpv | 0.41.0 |
| direnv | 2.37.1 |
| codex-cli | 0.133.0 |
| Claude Code | 2.1.187 |
| arduino-cli | 1.4.1 |
| clangd | 21.1.8 |
| TypeScript | 5.9.3 |
| typescript-language-server | 5.3.0 |
| latexmk | 4.87 |

## 8. systemd system units

`systemctl --root=/ list-unit-files --state=enabled` で確認できた重要 enabled unit:

- network: `iwd.service`, `dhcpcd.service`, `resolvconf.service`, `firewall.service`
- input: `keyd.service`
- user/home: `home-manager-tarutyyyne.service`, `linger-users.service`
- core: `dbus-broker.service`, `systemd-logind.service`, `systemd-journald.service`, `systemd-oomd.service`, `nscd.service`
- boot/maintenance: `systemd-boot-random-seed.service`, `fstrim.timer`, `logrotate.timer`, `systemd-tmpfiles-clean.timer`
- nix: `nix-daemon.socket`

Display manager:

- `display-manager.service`、greetd 系は見つからなかった。
- `XDG_CURRENT_DESKTOP=niri`、`XDG_SESSION_TYPE=wayland`。ログイン方法は未確定。

custom / NixOS 由来 unit:

- `home-manager-tarutyyyne.service`
- `keyd.service`
- `iwd.service`
- `dhcpcd.service`

NixOS 候補設定:

- `services.keyd.enable = true`
- `networking.wireless.iwd.enable = true`
- `networking.useDHCP = true`
- `services.pipewire.enable = true`
- `programs.niri.enable = true`
- `home-manager.users.tarutyyyne = import ./home/tarutyyyne`

## 9. systemd user units

- `systemctl --user list-unit-files` は user bus 接続不可で失敗。
- `~/.config/systemd/user/tray.target` のみ確認。
- `tray.target` は Home Manager 生成物への symlink:
  - `/nix/store/...-home-manager-files/.config/systemd/user/tray.target`
- 内容:
  - `Description=Home Manager System Tray`
  - `Requires=graphical-session-pre.target`
- enabled symlink は、この sandbox からは `tray.target` のみ確認。
- timer/service はユーザー設定下では未確認。

## 10. Desktop / Wayland / X11

- 使用中 desktop: `niri`
- `XDG_SESSION_TYPE=wayland`
- `XDG_CURRENT_DESKTOP=niri`
- `WAYLAND_DISPLAY=wayland-1`
- `~/.config/niri/config.kdl` が実設定。
- session desktop file:
  - `/run/current-system/sw/share/wayland-sessions` は存在しない。
  - `/run/current-system/sw/bin/niri-session` は存在。
- autostart:
  - `spawn-at-startup "waybar"`
  - `spawn-at-startup "fcitx5" "-d"`
  - `~/.config/autostart`、`/etc/xdg/autostart` は存在しない。
- portal:
  - `/run/current-system/sw/share/xdg-desktop-portal/niri-portals.conf`
  - preferred default: `gnome;gtk;`
  - secret portal: `gnome-keyring`
- screenshot:
  - niri builtin screenshot bind。
  - 保存先 `~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png`
  - packages: `grim`, `slurp`, `wf-recorder`
- lock:
  - `Super+Alt+L` -> `hyprlock`
- launcher:
  - `Mod+D` -> `rofi -show drun`
- terminal:
  - `Mod+T` -> `alacritty`

## 11. Waybar / status bar / panel

設定ファイル:

- `~/.config/waybar/config.jsonc`
- `~/.config/waybar/style.css`
- `~/.config/waybar/scripts/ime.sh`

表示モジュール:

- center: `clock`
- right: `custom/ime`, `memory`, `battery`, `network`, `pulseaudio`
- left: なし

特徴:

- 高さ 30px、top layer/top position。
- 色は黒背景 + orange `#F66E25`。
- 時計表示は `[ Asia / Tokyo | %H:%M ]`。
- network tooltip は SSID を表示し得るため、スクリーンショット公開時は注意。
- `custom/ime` は `fcitx5-remote -n` の結果を JSON 化し、SKK / DIRECT / off を表示。
- `pulseaudio.on-click` は `pactl set-sink-mute @DEFAULT_SINK@ toggle` だが、`pactl` は現 PATH で未導入。Waybar のクリック mute は壊れている可能性がある。

## 12. IME / Keyboard

IME:

- NixOS: `i18n.inputMethod.enable = true`, `type = "fcitx5"`。
- addons: `fcitx5-skk`, `fcitx5-gtk`, `fcitx5-qt`。
- user profile: `~/.config/fcitx5/profile`
  - group `Default`
  - default layout `us`
  - default input method `keyboard-us`
  - items: `skk`, `keyboard-us`
- hotkeys:
  - trigger: `Shift+space`, `Zenkaku_Hankaku`, `Hangul`
  - alternate trigger: `Shift_L`
  - group forward: `Super+space`
- state:
  - `~/.local/share/fcitx5/skk/user.dict` はユーザー辞書。バックアップ優先。

Keyboard:

- `services.keyd.enable = true`
- `/etc/keyd/default.conf`
- `capslock=layer(control)`
- control layer:
  - `b=left`, `f=right`, `p=up`, `n=down`
  - `a=home`, `e=end`
  - `h=backspace`, `d=delete`

Environment variables:

- `XMODIFIERS=@im=fcitx`
- `GTK_IM_MODULE`、`QT_IM_MODULE` は実行環境では空。

## 13. Shell

- login shell: bash (`/run/current-system/sw/bin/bash`)
- Home Manager で `programs.bash.enable = true`
- `~/.bashrc` / `~/.bash_profile` / `~/.profile` は Home Manager 生成物への symlink。
- `~/.zshrc` は `# Created by newuser for 5.9.1` のみ。`~/.zshenv` はなし。
- alias:
  - `lsa='ls -A1 --color=auto'`
- interactive bash:
  - history append, `globstar`, `checkjobs`
  - bash-completion
  - `EAT_SHELL_INTEGRATION_DIR` がある場合だけ EAT integration を source
- Alacritty 用:
  - `~/.config/bash/alacritty-interactive.bash`
  - Git branch/dirty marker 付き prompt
- PATH:
  - Codex temp path
  - ripgrep/bubblewrap Nix store path
  - `/run/wrappers/bin`
  - `~/.nix-profile/bin`
  - `/nix/profile/bin`
  - `~/.local/state/nix/profile/bin`
  - `/etc/profiles/per-user/tarutyyyne/bin`
  - `/nix/var/nix/profiles/default/bin`
  - `/run/current-system/sw/bin`
- `nvm`、`conda`、`pyenv`、`rustup` の home は確認できなかった。

## 14. Terminal / Launcher / Lock

Terminal:

- `alacritty 0.17.0`
- `~/.config/alacritty/alacritty.toml`
- shell program: `/etc/profiles/per-user/tarutyyyne/bin/bash`
- args: `--rcfile ~/.config/bash/alacritty-interactive.bash`
- Shift+Return sends escape + carriage return。

Launcher:

- `rofi 2.0.0`
- niri bind: `Mod+D` -> `rofi -show drun`

Lock:

- `hyprlock 0.9.5`
- `~/.config/hypr/hyprlock.conf`
- 黒背景、オレンジ文字、時刻表示、入力欄あり。
- PAM: `security.pam.services.hyprlock = {};`

Idle:

- `swayidle` package はあるが、設定ファイルや起動設定は未確認。

## 15. Editor

Emacs:

- `GNU Emacs 30.2`, package `emacs-pgtk`
- Home Manager で本体と一部パッケージを管理。
- 実設定:
  - `~/.emacs.d/init.org`
  - `~/.emacs.d/init.el` は `init.org` から生成
  - `~/.emacs.d/custom.el`
  - `~/.emacs.d/themes/miyatarutyyy-interface-theme.el`
- package manager:
  - Home Manager / Nix 経由: `nix-ts-mode`, `corfu`, `orderless`, `cape`, `yasnippet`, `vterm`, tree-sitter grammars, `ox-hub`
  - `~/.emacs.d/elpa`: `vertico`, `compat`, `marginalia`, `orderless`, `consult`
- 設定内容:
  - Tree-sitter remap for bash/css/json/python/js/typescript/tsx/yaml/nix
  - Eglot for TypeScript/TSX/JS
  - Arduino mode, `arduino-cli`, `arduino-language-server`, `clangd`
  - Org Babel: Emacs Lisp, Python
  - Org Beamer export via LuaLaTeX + latexmk
  - custom dark/orange theme
  - `make-backup-files nil`、`create-lockfiles nil`
- daemon/user service:
  - user service は見つからず。
  - `emacs --batch --eval '(bound-and-true-p server-mode)'` は `nil`。
- GPG/auth-source:
  - init 内に auth-source/GPG 参照は見つからず。
  - `~/.authinfo` は存在するため、今後 auth-source で使う可能性あり。平文のため移行時は暗号化推奨。
- キャッシュ:
  - `eln-cache`、`elpa`、`url/cache` は再生成可能。
  - `auto-save-list` には作業中ファイル断片が含まれる可能性がある。移行前に確認。

Other editors:

- Zed 設定あり: `~/.config/zed/settings.json`
  - agent servers: `claude-acp`, `codex-acp`
  - base keymap: Emacs
  - theme: Ayu Dark
- `nvim`、`vim`、VS Code は PATH 上で未確認。

## 16. Git / SSH / GPG

Git:

- `~/.gitconfig`、`~/.config/git` はなし。
- `git config --global --list --show-origin` は `.gitconfig` 不在で失敗。
- URL rewrite / includeIf は global では未確認。

SSH:

- `~/.ssh/config`:
  - `github.com` -> `IdentityFile ~/.ssh/id_ed25519_github`
  - `github.com-iniad` -> `IdentityFile ~/.ssh/id_ed25519_github_iniad`
- private keys:
  - `~/.ssh/id_ed25519_github`
  - `~/.ssh/id_ed25519_github_iniad`
- public keys:
  - `~/.ssh/id_ed25519_github.pub`
  - `~/.ssh/id_ed25519_github_iniad.pub`
- `known_hosts` と `known_hosts.old` あり。
- `ssh -G github.com` は以下の理由で失敗:
  - `Bad owner or permissions on /nix/store/.../systemd/ssh_config.d/20-systemd-ssh-proxy.conf`
  - 対象ファイルは `-r--r--r-- nobody:nogroup` に見えている。sandbox の所有者マッピング影響の可能性がある。

GPG:

- `~/.gnupg` は存在しない。
- `gpg` command は未導入。
- GPG key listing はできなかった。

NixOS 移行時に壊れそうな OS 固有パス:

- `~/.config/alacritty/alacritty.toml` の shell path `/etc/profiles/per-user/tarutyyyne/bin/bash`
- `~/.profile` の Nix store path
- Emacs init の `~/.arduino15/arduino-cli.yaml`
- SSH の systemd ssh proxy include が sandbox 上で権限エラー

## 17. 開発環境

グローバル PATH 上で確認できたもの:

- Nix / flakes / Home Manager
- `direnv` + `nix-direnv`
- `git`, `gh`
- `codex`, `claude`
- `arduino-cli`, `arduino-language-server`, `clangd`
- `tsc`, `typescript-language-server`
- TeX Live / `latexmk`
- `collect-cli`, `herdr`

未確認または未導入:

- `node`, `npm`, `pnpm`, `yarn` は PATH 上にはない。ただし `~/.npm` と `~/.local/share/pnpm` は存在。
- `python`, `python3`, `pip`, `uv` は PATH 上にはない。ただし `~/.cache/uv`、`~/.local/share/uv` は存在。
- `rustc`, `cargo`, `rustup` は PATH 上にはない。
- `java`, `mvn`, `gradle`, `go`, `ruby`, `sbcl` は PATH 上にはない。

プロジェクト単位の開発環境:

- `.envrc`:
  - `~/Git/Fes-System2026/2026-programing-experience/.envrc`
  - `~/Git/SEBASTIAN/.envrc`
  - `~/Git/Horse-Racing-ML/.envrc`
  - `~/Git/AtCoder/.envrc`
  - `~/INIAD/.envrc`
  - `~/INIAD/cs3/.envrc`
- `flake.nix`:
  - `~/Git/Fes-System2026/2026-programing-experience/flake.nix`
  - `~/Git/SEBASTIAN/flake.nix`
  - `~/Git/Horse-Racing-ML/flake.nix`
  - `~/Git/make-AI-Avater/flake.nix`
  - `~/Git/AtCoder/flake.nix`
  - `~/INIAD/ux-ex/assignment/flake.nix`

生成物/キャッシュ候補:

- `node_modules`: `Fes-System2026`, `SEBASTIAN`, `make-AI-Avater`, `INIAD/ux-ex/assignment`
- `.venv`: `Horse-Racing-ML`, `INIAD/cs3`
- `dist`: `INIAD/ux-ex/assignment`
- `.npm`, `.local/share/pnpm`, `.cache/pnpm`, `.cache/uv`

## 18. Containers / VM / Local LLM

- `docker`, `podman`, `incus`, `lxc`, `ollama` は PATH 上にない。
- `systemctl --root=/ list-unit-files '*docker*' '*podman*' '*incus*' '*lxd*' '*ollama*' '*libvirtd*' '*qemu*'` は 0 件。
- `/var/lib/docker`、`/var/lib/containers`、`/var/lib/incus`、`/var/lib/lxd`、`/var/lib/ollama` は存在しない。
- `~/.local/share/containers`、`~/.ollama` は存在しない。
- `/dev/kvm` は sandbox 内では存在しない。
- `docker-compose.yml`、`compose.yml`、`Dockerfile`、`Containerfile` は `~/Git` maxdepth 3 では未検出。

root/ホスト側で追加確認:

```bash
systemctl list-unit-files 'docker*' 'podman*' 'incus*' 'lxd*' 'ollama*' 'libvirtd*'
docker ps -a
podman ps -a
ls -ld /var/lib/docker /var/lib/containers /var/lib/libvirt /var/lib/ollama
ls -l /dev/kvm
```

## 19. Network

NixOS 設定:

- `networking.networkmanager.enable = false`
- `networking.wireless.iwd.enable = true`
- `networking.wireless.iwd.settings.Settings.AutoConnect = true`
- `networking.useDHCP = true`

実測:

- `iwd.service` enabled
- `dhcpcd.service` enabled
- `wlan0`: driver `iwlwifi`, operstate `up`
- `enp0s31f6`: driver `e1000e`, operstate `down`
- `/etc/iwd/main.conf` あり
- `/var/lib/iwd` は `0700` で権限不足。Wi-Fi profile はここにある可能性が高い。SSID/PSK は本文へ記録しない。
- `/etc/NetworkManager` と `/var/lib/NetworkManager` は残骸あり。NetworkManager は無効。
- `/etc/NetworkManager/system-connections` は permission denied。
- VPN:
  - `/etc/wireguard`、`~/.config/wireguard`、`~/.config/openvpn` はなし。

## 20. Audio / Video / OBS

NixOS 設定:

- `security.rtkit.enable = true`
- `services.pipewire.enable = true`
- `services.pipewire.alsa.enable = true`
- `services.pipewire.alsa.support32Bit = true`
- `services.pipewire.pulse.enable = true`
- `services.pipewire.wireplumber.enable = true`

実測:

- `/run/user/1000/pipewire-0` socket あり。
- `/run/user/1000/pulse/native` socket あり。
- `wpctl status` は bus/RTKit/pipewire 接続不可で失敗。
- `pactl` は未導入。ただし Waybar 設定は `pactl` を呼ぶため、`pulseaudio` package または `wpctl` への置換が必要。
- `~/.config/pulse/cookie` あり。secret 扱い。
- OBS:
  - `obs` / `obs-studio` は PATH 上になし。
  - `~/.config/obs-studio` はなし。
- recordings:
  - `~/Videos/Recordings/submission-micropost.mp4`
  - `~/Videos/Recordings/test.mp4`

Portal / screen capture:

- `niri-portals.conf` あり。default `gnome;gtk;`。
- `xdg-desktop-portal` の live 状態は未確認。

## 21. Browsers / GUI apps

Browsers:

- `floorp-bin` installed。
- profile:
  - `~/.floorp/profiles.ini`
  - default profile `ffxm5uk3.default`
- secret/state:
  - `cookies.sqlite`
  - `key4.db`
  - `cert9.db`
  - `places.sqlite`
- Firefox/Chromium/Chrome は PATH 上に見つからず。

GUI apps:

- `discord` installed。`~/.config/discord` は約 403 MiB。
- `mpv` installed。
- `pwvucontrol` installed。
- `nautilus` state directory あり。ただし command は PATH 上で未確認。
- `zed` 設定/状態あり。ただし `zed` command は PATH 上で未確認。
- Obsidian / LibreOffice / GIMP / Steam は PATH 上に見つからず。

アプリ状態として必要ならバックアップ:

- `~/.floorp`
- `~/.config/discord` のログイン状態。ただし cache は除外可。
- `~/.config/zed`、`~/.local/share/zed`
- `~/.local/share/keyrings`
- `~/.local/share/vicinae` は launcher/clipboard/file index 状態。clipboard は秘密混入注意。

## 22. Fonts / Themes

NixOS 設定:

- `noto-fonts`
- `noto-fonts-cjk-sans`
- `noto-fonts-cjk-serif`
- `noto-fonts-color-emoji`

確認:

- `fc-match 'Noto Sans CJK JP'` -> `NotoSansCJK-VF.otf.ttc`
- `fc-match emoji` -> `NotoColorEmoji.ttf`
- local fonts:
  - `~/.local/share/fonts` なし
  - `~/.fonts` なし
- GTK/Qt theme:
  - `~/.config/gtk-3.0`、`gtk-4.0`、`qt5ct`、`qt6ct`、`Kvantum` はなし。
  - `gsettings` command は未導入。
- icon/theme:
  - `~/.icons`、`~/.themes`、`~/.local/share/icons`、`~/.local/share/themes` はなし。
- アプリ独自 theme:
  - Emacs: `miyatarutyyy-interface`
  - Waybar/Hyprlock/niri: black + orange `#F66E25`
  - Zed: `Ayu Dark`

## 23. Mail / external CLIs

Mail:

- `msmtp` command は未確認。
- `~/.config/msmtp/config` はなし。
- `~/.authinfo` は存在。Emacs/mail/API などに使われる可能性がある。平文なので暗号化移行推奨。

External CLIs:

- `gh` installed。`gh auth status` では GitHub token が無効。
- `wrangler` command は PATH 上になし。ただし `~/.config/.wrangler/logs` と `metrics.json` は存在。
- `kaggle`、`qiita`、`aws`、`gcloud`、`az`、`firebase`、`vercel`、`netlify`、`heroku`、`flyctl`、`tailscale`、`pass` は PATH 上に見つからず。
- `claude` / `codex` は installed。`~/.claude`、`~/.claude.json`、`~/.codex` はログイン/状態/履歴を含む可能性がある。

## 24. データとバックアップ対象

最優先でバックアップ:

| パス | サイズ | 理由 |
|---|---:|---|
| `/etc/nixos` | 小 | NixOS flake 本体 |
| `~/.ssh` | 36 KiB | SSH 鍵 |
| `~/.authinfo` | 4 KiB | 平文秘密 |
| `~/.config/gh` | 12 KiB | GitHub CLI 認証/設定 |
| `~/.claude`, `~/.claude.json` | 11 MiB + 48 KiB | Claude Code 認証/状態 |
| `~/.config/niri` | 88 KiB | desktop 設定 |
| `~/.config/waybar` | 32 KiB | bar 設定/script |
| `~/.config/alacritty` | 12 KiB | terminal 設定 |
| `~/.config/hypr` | 8 KiB | lock 設定 |
| `~/.emacs.d/init.org`, `init.el`, `themes/` | 小 | editor 設定 |
| `~/.local/share/fcitx5/skk/user.dict` | 64 KiB | SKK ユーザー辞書 |
| `~/Git` | 2.6 GiB | 作業リポジトリ |
| `~/INIAD` | 7.9 GiB | 学校/作業データ |

アプリ状態として必要ならバックアップ:

| パス | サイズ | 備考 |
|---|---:|---|
| `~/.floorp` | 452 MiB | ブラウザ profile。秘密 DB あり |
| `~/.config/discord` | 403 MiB | ログイン状態。cache 多め |
| `~/.local/share/keyrings` | 12 KiB | secret store |
| `~/.local/share/zed` | 17 MiB | Zed 状態 |
| `~/.local/share/vicinae` | 122 MiB | clipboard/index DB。秘密混入注意 |
| `~/.arduino15` | 1.1 GiB | Arduino index/cache。設定は小さい |
| `~/.platformio` | 871 MiB | PlatformIO state/cache |
| `~/.texlive2025` | 78 MiB | TeX user state/cache |

再生成可能または捨てる候補:

| パス | サイズ | 理由 |
|---|---:|---|
| `~/.cache` | 1.6 GiB | cache |
| `~/.cache/floorp` | 1.1 GiB | browser cache |
| `~/.cache/uv` | 805 MiB | Python/uv cache |
| `~/.cache/pnpm` | 297 MiB | pnpm cache |
| `~/.npm` | 1.1 GiB | npm cache/npx |
| `~/.local/share/pnpm` | 496 MiB | pnpm store |
| `node_modules` | 複数 | package manager で再生成 |
| `.venv` | 複数 | lock/flake から再生成 |
| `dist`, `.next`, `tsconfig.tsbuildinfo` | 複数 | build artifacts |
| `~/.emacs.d/eln-cache` | 1.2 MiB | native compile cache |
| `~/.emacs.d/url/cache` | 160 KiB | URL cache |
| `~/.local/share/Trash` | 32 MiB | Trash |

大きいディレクトリ:

| パス | サイズ |
|---|---:|
| `~/INIAD` | 7.9 GiB |
| `~/Downloads` | 2.8 GiB |
| `~/Git` | 2.6 GiB |
| `~/.cache` | 1.6 GiB |
| `~/.arduino15` | 1.1 GiB |
| `~/.npm` | 1.1 GiB |
| `~/.platformio` | 871 MiB |
| `~/.floorp` | 452 MiB |
| `~/.config/discord` | 403 MiB |
| `~/.codex` | 392 MiB |

## 25. 主要 Git リポジトリ

| repo | 状態 | 移行前対応 |
|---|---|---|
| `/etc/nixos` | branch `master`, 差分なし, remote なし | 必ずバックアップ。`safe.directory` 問題に注意 |
| `~/Git/26-intern/MicroPost-26` | `main...origin/main [ahead 1]`, `docs/app-startup.md` untracked | push/commit 判断 |
| `~/Git/Fes-System2026/2026-programing-experience` | `main...origin/main`, `.gitignore`/`package.json` modified, `flake.lock` added, 変な untracked 名あり | 差分確認必須 |
| `~/Git/SEBASTIAN` | `docs/project-state-overview...origin/docs/project-state-overview`, clean | 必要なら push 状態確認 |
| `~/Git/Articles` | `master...origin/master`, `org/debugging-dns-issues-on-nixos-with-iwd.org` untracked | commit/不要判断 |
| `~/Git/git-handson-0705` | no commits, `hoge.txt` staged, `result` untracked | 学習 repo なら不要判断 |
| `~/Git/make-AI-Avater` | no commits, 多数 untracked, `.env` あり | secret を除いてバックアップ/初回 commit 判断 |
| `~/Git/AtCoder` | `.git` が空。Git として壊れている | repo 再初期化/再 clone/単純データ扱いを判断 |
| `~/Git/MIGRATION` | no commits, remote `Settings-Integration` | この棚卸し保存先候補なら commit 判断 |

移行前に取るべきコマンド:

```bash
git -c safe.directory=/etc/nixos -C /etc/nixos status --short --branch
for repo in ~/Git/* ~/Git/*/*; do [ -d "$repo/.git" ] && git -C "$repo" status --short --branch; done
```

## 26. NixOS / Home Manager への対応表

| 現在の対象 | NixOS/Home Manager 候補 |
|---|---|
| `/etc/nixos/flake.nix` | flake root として継続 |
| host `thinkpad-l480` | `nixosConfigurations.thinkpad-l480` |
| systemd-boot | `boot.loader.systemd-boot.enable = true` |
| EFI vars | `boot.loader.efi.canTouchEfiVariables = true` |
| ext4 `/`, vfat `/boot` | `fileSystems` と `hardware-configuration.nix` |
| no swap | `swapDevices = [ ];` |
| Intel microcode | `hardware.cpu.intel.updateMicrocode` |
| iwd + DHCP | `networking.wireless.iwd`, `networking.useDHCP` |
| firewall | `networking.firewall` |
| keyd remap | `services.keyd` |
| fcitx5 SKK | `i18n.inputMethod.fcitx5.addons` |
| niri | `programs.niri.enable = true` + user config managed by Home Manager |
| Waybar | `programs.waybar` or `home.file.".config/waybar"` |
| Alacritty | `programs.alacritty` |
| Hyprlock | `programs.hyprlock` or `home.file` |
| rofi | `programs.rofi` |
| Emacs | `programs.emacs` + `home.file.".emacs.d"` |
| Bash | `programs.bash` |
| GitHub CLI | `programs.gh` + secrets outside Nix store |
| SSH config | `programs.ssh` + keys outside Nix store |
| Floorp | `home.packages = [ floorp-bin ]`; profile data as backup |
| Discord | `home.packages = [ discord ]`; cache除外 |
| Zed | package 追加検討 + `home.file` |
| secrets | `sops-nix`, `agenix`, `pass`, or manual encrypted backup |

## 27. 初期 NixOS 設定の優先順位

1. boot: EFI/systemd-boot、fileSystems、kernel modules、microcode。
2. user: `tarutyyyne`、shell、`wheel`、`dialout`。
3. network: iwd + DHCP、Wi-Fi profile の安全な移行。
4. desktop: niri、Waybar、portal、Alacritty、rofi、hyprlock。
5. IME: fcitx5 + SKK、user dictionary、environment variables。
6. secrets: SSH keys、gh auth、authinfo、Claude/Codex、keyrings、browser secrets。
7. editor: Emacs pgtk、init.org、Nix-managed packages、TeX。
8. dev tools: direnv/nix-direnv、TypeScript、Arduino、clangd、project flakes。
9. GUI apps: Floorp、Discord、mpv、pwvucontrol、Zed。

## 28. フォーマット直前の最終確認コマンド

user 権限でよいもの:

```bash
uname -a
cat /etc/os-release
locale
readlink /etc/localtime
id
lsblk -f
findmnt -R /
cat /etc/fstab
cat /proc/cmdline
bootctl status
systemctl --root=/ list-unit-files --state=enabled
systemctl --user list-unit-files
git -c safe.directory=/etc/nixos -C /etc/nixos status --short --branch
for repo in ~/Git/* ~/Git/*/*; do [ -d "$repo/.git" ] && git -C "$repo" status --short --branch; done
gh auth status
ssh -T github.com
```

root 権限が必要または推奨:

```bash
sudo lspci -nnk
sudo lsusb
sudo dmidecode -t system -t bios -t baseboard
sudo efibootmgr -v
sudo blkid
sudo ls -la /var/lib/iwd
sudo find /var/lib/iwd -maxdepth 1 -type f -printf '%M %s %p\n'
sudo ls -la /etc/NetworkManager/system-connections
sudo systemctl status iwd dhcpcd keyd home-manager-tarutyyyne
sudo journalctl -b -u iwd -u dhcpcd -u keyd --no-pager
```

secret rotation / re-login:

```bash
gh auth logout -h github.com
gh auth login -h github.com
ssh-keygen -lf ~/.ssh/id_ed25519_github.pub
ssh-keygen -lf ~/.ssh/id_ed25519_github_iniad.pub
```

秘密値の退避方針:

- `tar --acls --xattrs` などで archive 化し、別途暗号化する。
- `.env`、`.authinfo`、SSH 秘密鍵、browser profile、keyrings は平文転送しない。
- 無効な GitHub token は移行ではなく再ログインする。

## 29. 移行で捨ててよい可能性が高いもの

- `~/.cache/*`
- `~/.npm`
- `~/.local/share/pnpm/store`
- `~/.cache/pnpm`
- `~/.cache/uv`
- `node_modules`
- `.venv`
- `dist`
- `.next`
- `tsconfig.tsbuildinfo`
- `~/.emacs.d/eln-cache`
- `~/.emacs.d/url/cache`
- `~/.config/discord/Cache`
- `~/.config/discord/GPUCache`
- `~/.config/discord/Code Cache`
- `~/.config/discord/Crashpad`
- `~/.cache/floorp`
- `~/.texlive2025` は必要なら再生成可
- `~/.arduino15/package_index.json`、`library_index.json` は再取得可
- `~/.platformio` は project に応じて再生成可

## 30. 未解決・要判断

- 依頼文は「Arch Linux から NixOS」だが、この PC は実測では NixOS。別 PC の Arch 棚卸しと比較する場合、この文書は NixOS 側の基準として扱う。
- `/etc/nixos` の所有者が `nobody:nogroup` に見える。sandbox の UID mapping か実機状態か root で確認。
- `iwd` の Wi-Fi profile は未確認。SSID/PSK を記録しない形で root 確認が必要。
- `pactl` 未導入なのに Waybar の音量クリックが `pactl` を使っている。`wpctl` へ変更するか `pulseaudio` package を入れるか判断。
- `gh` token が無効。移行後に再ログインが必要。
- `ssh -G` の systemd ssh proxy 権限問題が実機でも起きるか確認。
- `~/Git/AtCoder` の壊れた `.git` を捨てるか再初期化するか判断。
- `~/Git/make-AI-Avater` と `git-handson-0705` は no commits。移行するなら commit/remote 設定を決める。
- `~/.authinfo` が平文。`~/.authinfo.gpg` や NixOS secret 管理へ移すか判断。
- `~/.local/share/vicinae/clipboard.db` は秘密混入リスクが高い。移行するか捨てるか判断。
- Floorp/Discord のログイン状態を移行するか、再ログインして cache は捨てるか判断。

## 31. この文書の検証メモ

実行して確認した主なコマンド:

- `cat /etc/os-release`
- `uname -a`
- `hostname`
- `id`
- `locale`
- `readlink /etc/localtime`
- `getent passwd tarutyyyne`
- `swapon --show`
- `free -h`
- `lscpu`
- `lsblk -f`
- `findmnt -R /`
- `cat /etc/fstab`
- `cat /proc/cmdline`
- `systemd-detect-virt`
- `ls -la /etc/nixos`
- `rg --files /etc/nixos`
- `sed -n ... /etc/nixos/*.nix`
- `systemctl --root=/ list-unit-files --state=enabled`
- `find ~/.config/systemd/user`
- `ls -la ~ ~/.config`
- `find ~/.config -maxdepth 2`
- `sed -n ... ~/.config/niri/config.kdl`
- `sed -n ... ~/.config/waybar/config.jsonc`
- `sed -n ... ~/.config/waybar/style.css`
- `sed -n ... ~/.config/alacritty/alacritty.toml`
- `sed -n ... ~/.config/hypr/hyprlock.conf`
- `sed -n ... ~/.config/fcitx5/profile ~/.config/fcitx5/config`
- `find ~/.ssh`
- `gh auth status`
- `gpg --list-secret-keys --keyid-format LONG`
- `sed -n ... ~/.ssh/config`
- `rg --files ~/.emacs.d`
- `sed -n ... ~/.emacs.d/init.el`
- `find ~/.floorp`
- `du -sh ...`
- `git -C ... status --short --branch`

失敗した主なコマンドと理由:

| コマンド | 理由 |
|---|---|
| `hostnamectl` | system bus 接続不可 |
| `systemctl list-units --type=service --state=running` | system bus 接続不可 |
| `loginctl` | system bus 接続不可 |
| `systemctl --user list-unit-files` | user bus 接続不可 |
| `systemctl --root=/ cat keyd.service` | `cat` verb は `--root` と併用不可 |
| `lspci -nnk` | command not found |
| `lsusb` | command not found |
| `networkctl list` | netlink 権限不足 |
| `resolvectl status` | systemd-resolved socket 権限不足 |
| `iwctl station wlan0 show` | 応答せず。live iwd 接続不可の可能性 |
| `ss -tulpen` | netlink 権限不足 |
| `wpctl status` | PipeWire / RTKit / D-Bus 接続不可 |
| `pactl info` | command not found |
| `gpg --list-secret-keys` | `gpg` command not found |
| `pacman -Qqe` | command not found |
| `yay -Qqm` / `paru -Qqm` | command not found |
| `flatpak list` / `snap list` | command not found |
| `nix-store -q --references ...` | nix-daemon socket 権限不足 |
| `ssh -G github.com` | systemd ssh proxy config の owner/permission 問題 |
| `discord --version` | GUI/sandbox 制限で fatal |
