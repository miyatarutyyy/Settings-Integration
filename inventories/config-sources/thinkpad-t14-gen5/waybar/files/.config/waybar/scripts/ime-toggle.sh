#!/usr/bin/env bash
set -eu
FCITX5_REMOTE="/usr/bin/fcitx5-remote"

im="$($FCITX5_REMOTE -n 2>/dev/null || true)"
if [[ -z "${im:-}" || "$im" == keyboard-* ]]; then
  $FCITX5_REMOTE -s skk           
else
  $FCITX5_REMOTE -s keyboard-us   
fi
