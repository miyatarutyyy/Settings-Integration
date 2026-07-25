#!/usr/bin/env bash
set -eu
FCITX5_REMOTE="/usr/bin/fcitx5-remote"

mark="FCITX5"
tooltip="keyboard"

if [[ -x "$FCITX5_REMOTE" ]]; then
  im="$($FCITX5_REMOTE -n 2>/dev/null || true)"
  if [[ -n "${im:-}" && "$im" != keyboard-* ]]; then
    mark="SKK"
  fi
  tooltip="${im:-unknown}"
fi

# class 付与（CSSで状態別に色を変えるため）
case "$mark" in
  FCITX5) cls="ime-fcitx5" ;;
  SKK)    cls="ime-skk" ;;
  *)      cls="ime-unknown" ;;
esac

# 他モジュールと同じ見栄え：[ IME : FCITX5 ] / [ IME : SKK ]
printf '{"text":"[ IME : %s ]","tooltip":"%s","class":"%s"}\n' "$mark" "$tooltip" "$cls"
