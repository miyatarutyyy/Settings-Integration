# Inventories

作成日: 2026-07-26

目的: 既存 Arch Linux / NixOS 環境の棚卸し、設定収集、比較判断、build 準備状況をこの directory から辿れるようにする。

この directory の文書は、NixOS / Home Manager 正本設定へ取り込む前の判断材料である。既存設定をそのまま正本として扱わず、採用、修正して採用、破棄、未確認のどれかに分類してから `flake.nix`、`modules/`、`hosts/`、`home/` へ反映する。

## 読む順序

1. `dotfiles-decisions.md`
   - 統一環境を NixOS + Home Manager で作る判断、共通/host/user 分離、secrets 方針を確認する。
2. `build-readiness.md`
   - 現在の flake がどこまで実機 build 可能な状態か、未確認項目、検証順序を確認する。
3. `host-configuration-plan.md`
   - filesystem、boot、hardware configuration、swap など host 固有設定の置き場所を確認する。
4. `config-collection-instructions.md`
   - 既存設定を追加で収集するときの保存先、秘密情報レビュー、commit 単位を確認する。
5. `config-comparisons/`
   - niri、Waybar、idle-lock など、収集済み設定の採否判断を確認する。
6. `config-sources/`
   - 各 host から収集した実ファイル由来の参考資料を確認する。

## 主要ファイル

- `thinkpad-l480-nixos.md`
  - 既存 NixOS PC `thinkpad-l480` の棚卸し。
- `trt-ryzen7-archlinux.md`
  - Arch Linux 移行元の棚卸し。NixOS 移行後の host 名は `thinkpad-t14-gen5` として扱う。
- `dotfiles-decisions.md`
  - 統一 dotfiles / NixOS / Home Manager を作る前に決めた方針。
- `build-readiness.md`
  - `nix flake check` と `nixos-rebuild build` に向けた未確認項目と確認順序。
- `host-configuration-plan.md`
  - `hosts/<hostname>/default.nix` と `hosts/<hostname>/hardware.nix` の役割分担。
- `thinkpad-t14-gen5-nixos-install.md`
  - ThinkPad T14 Gen 5 の内蔵 SSD を消去して NixOS を本番 install する手順。
- `config-collection-instructions.md`
  - 既存設定を秘密情報なしで収集するための作業手順。

## Subdirectories

- `config-sources/<hostname>/<application>/`
  - 各 PC から収集した既存設定の source material。
  - `README.md` には収集元、確認日、秘密情報レビュー、採否判断、未確認事項を書く。
  - `files/` には commit してよいと確認した設定ファイルだけを置く。
- `config-comparisons/`
  - 収集済み source material を比較し、共通設定へ採用するかどうかを記録する。

## 秘密情報の扱い

次の値や状態は、この repository に平文で入れない。

- SSH private key、GPG private key、age key
- password、token、API key、OAuth token、cookie、session ID
- browser profile、GNOME keyring、KWallet、login state
- Wi-Fi PSK、SSID を含む接続 profile
- `.env`
- 緯度経度など現在地を含む cache / state

必要な場合も、文書化するのは path、種類、移行方針だけにする。値そのものは記録しない。

## 現在の build 境界

- 最初の実機 build target は `thinkpad-l480`。
- この Arch 側作業環境では `nix` / `nixos-rebuild` がないため、flake 評価は未確認。
- `thinkpad-t14-gen5` は NixOS install 時に filesystem と hardware configuration を確定するまで、完全な build target として扱わない。

実機では次の順に確認する。

```bash
nix flake check
nixos-rebuild build --flake .#thinkpad-l480
```

`thinkpad-t14-gen5` の filesystem、UUID、mountpoint、Wi-Fi profile、secrets は推測で埋めない。
