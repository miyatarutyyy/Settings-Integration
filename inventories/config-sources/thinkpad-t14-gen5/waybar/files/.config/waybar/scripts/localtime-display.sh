#!/bin/sh
set -eu

STATE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/waybar-localtime"
STATE_FILE="$STATE_DIR/state.json"
CACHE_MAX_AGE_SECONDS="${WAYBAR_LOCALTIME_CACHE_MAX_AGE_SECONDS:-21600}"

os_timezone() {
  localtime="$(readlink /etc/localtime 2>/dev/null || true)"
  case "$localtime" in
    /usr/share/zoneinfo/*) printf '%s\n' "${localtime#/usr/share/zoneinfo/}" ;;
    *) printf 'localtime\n' ;;
  esac
}

cached_timezone() {
  [ -r "$STATE_FILE" ] || return 1
  jq -er '.timezone // empty' "$STATE_FILE" 2>/dev/null
}

cached_updated_at() {
  [ -r "$STATE_FILE" ] || return 1
  jq -er '.updated_at // empty' "$STATE_FILE" 2>/dev/null
}

cached_source() {
  [ -r "$STATE_FILE" ] || return 1
  jq -er '.source // empty' "$STATE_FILE" 2>/dev/null
}

cached_is_fresh() {
  case "$CACHE_MAX_AGE_SECONDS" in
    ''|*[!0-9]*) return 1 ;;
  esac

  updated="$(cached_updated_at)" || return 1
  updated_epoch="$(date -d "$updated" '+%s' 2>/dev/null)" || return 1
  now_epoch="$(date '+%s')"
  age_seconds=$((now_epoch - updated_epoch))

  [ "$age_seconds" -lt 0 ] || [ "$age_seconds" -le "$CACHE_MAX_AGE_SECONDS" ]
}

if cached_is_fresh; then
  tz="$(cached_timezone || os_timezone)"
  updated_at="$(cached_updated_at || printf 'not updated\n')"
  source="$(cached_source || printf 'fallback\n')"
else
  tz="$(os_timezone)"
  updated_at="$(cached_updated_at || printf 'not updated\n')"
  if [ -r "$STATE_FILE" ]; then
    source="fallback-stale-cache"
  else
    source="fallback"
  fi
fi

format_timezone_for_display() {
  printf '%s' "$1" | sed 's#/# / #g'
}

display_tz="$(format_timezone_for_display "$tz")"

if [ "$tz" = "localtime" ]; then
  time_text="$(date '+%H:%M')"
else
  time_text="$(TZ="$tz" date '+%H:%M' 2>/dev/null)" || {
    fallback_tz="$(os_timezone)"
    display_tz="$(format_timezone_for_display "$fallback_tz")"
    time_text="$(date '+%H:%M')"
  }
fi

text="[ $display_tz | $time_text ]"
tooltip="$(printf '%s\nupdated: %s\nsource: %s' "$tz" "$updated_at" "$source")"

jq -cn \
  --arg text "$text" \
  --arg tooltip "$tooltip" \
  '{"text":$text,"tooltip":$tooltip,"class":"localtime"}'
