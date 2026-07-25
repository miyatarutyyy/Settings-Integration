# Settings Integration

This repository keeps migration and environment context for multiple machines.

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
