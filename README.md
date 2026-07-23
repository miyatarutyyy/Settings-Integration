# Settings Integration

This repository keeps migration and environment context for multiple machines.

## Inventories

- `inventories/thinkpad-l480-nixos.md`: current NixOS context for `thinkpad-l480` / user `tarutyyyne`.
- `inventories/trt-ryzen7-archlinux.md`: Arch Linux to NixOS migration context for the other PC. This file is imported from the GitHub-side history.

## Workflow

Use normal pull/merge before pushing from either PC:

```bash
git pull --rebase=false origin master
git push
```

If SSH fails because of the systemd SSH proxy config permission issue, use this repository-local setting:

```bash
git config core.sshCommand "ssh -F /dev/null"
```
