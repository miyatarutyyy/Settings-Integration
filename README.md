# Settings Integration

This repository keeps the future source-of-truth NixOS and Home Manager
configuration for two Linux laptops.

The current target is a single shared Git repository with common modules, host
specific NixOS configuration, and documented migration decisions. Existing Arch
Linux and NixOS settings are treated as source material, not as files to copy
blindly.

## Current Shape

- `flake.nix`: entrypoint for build-ready NixOS configurations.
- `flake.lock`: pinned input revisions for reproducible evaluation.
- `modules/nixos/`: shared NixOS modules.
- `hosts/<hostname>/`: host-specific NixOS configuration.
- `home/common.nix`: shared Home Manager entrypoint.
- `home/tarutyyyne/`: user-level Home Manager entrypoint.
- `home/modules/`: shared Home Manager modules for desktop, shell, Git,
  development tools, and idle/lock behavior.
- `inventories/`: source inventories, comparison notes, migration decisions,
  and readiness plans.

## Implemented Configuration

- Build-ready hosts: `thinkpad-l480` and `thinkpad-t14-gen5`.
- Common NixOS: flakes, unfree packages, redistributable firmware, locale,
  user creation, iwd, OpenSSH, desktop runtime.
- Desktop runtime: niri, greetd/tuigreet, fcitx5-skk, fonts, PipeWire,
  xdg-desktop-portal, GNOME keyring, keyd.
- Home Manager: Bash, Git, GitHub CLI, SSH host aliases, development CLI tools,
  Alacritty, Rofi, niri config, Waybar, Hyprlock, and swayidle.
- Collected source settings: niri, Waybar, and Hyprlock source material from
  the existing machines.

## Not Yet Verified

This repository can be evaluated with Nix from the Arch-side working
environment. On 2026-07-26, the `thinkpad-l480` NixOS toplevel build succeeded
with Nix 2.35.1; `thinkpad-t14-gen5` has host hardware declared from the Arch
source system and should be verified before switching the installed OS.

The first build target should be `thinkpad-l480`:

```bash
nix flake check
nix build .#nixosConfigurations.thinkpad-l480.config.system.build.toplevel
```

`thinkpad-t14-gen5` can be evaluated as a flake build target, but the actual
NixOS install should still re-check the ESP and root filesystem before
switching.

## Next References

- `inventories/build-readiness.md`: build status, missing host data, and
  verification order.
- `inventories/host-configuration-plan.md`: where hardware configuration,
  filesystems, boot, and swap should live.
- `inventories/dotfiles-decisions.md`: user decisions and migration policy.
- `inventories/config-comparisons/`: per-application comparison notes.

## Inventories

- `inventories/thinkpad-l480-nixos.md`: current NixOS context for `thinkpad-l480` / user `tarutyyyne`.
- `inventories/trt-ryzen7-archlinux.md`: Arch Linux to NixOS migration context for the other PC. This file is imported from the GitHub-side history.
- `inventories/config-collection-instructions.md`: workflow for collecting existing per-application configuration files from each PC without committing secrets.

## Workflow

Before starting work on either PC, pull the current shared state:

```bash
git pull --rebase=false origin master
```

When working from two PCs at the same time, keep each reviewable task scoped to
different files or sections when possible. Before editing, state which task and
files are being handled on that PC so the other PC can avoid the same scope.

After finishing and verifying one reviewable task, push it before starting the
next independent task:

```bash
git push
```

On the other PC, run `git pull --rebase=false origin master` again before
continuing work.

If SSH fails because of the systemd SSH proxy config permission issue, use this repository-local setting:

```bash
git config core.sshCommand "ssh -F /dev/null"
```
