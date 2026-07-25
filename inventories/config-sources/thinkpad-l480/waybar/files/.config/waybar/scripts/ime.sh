#!/usr/bin/env bash

im="$(fcitx5-remote -n 2>/dev/null || true)"

case "$im" in
  *skk*|*SKK*)
    echo '{"text":"[ IME: SKK ]","class":"skk"}'
    ;;
  keyboard-*|*keyboard*|*us*|*jp*)
    echo '{"text":"[ IME: DIRECT ]","class":"direct"}'
    ;;
  "")
    echo '{"text":"[ IME: off ]","class":"off"}'
    ;;
  *)
    echo '{"text":"[ IME: DIRECT ]","class":"direct"}'
    ;;
esac
