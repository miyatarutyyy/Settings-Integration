#!/bin/sh
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
REFRESH="$SCRIPT_DIR/localtime-refresh.sh"
DISPLAY="$SCRIPT_DIR/localtime-display.sh"
TEST_CACHE="$(mktemp -d "${TMPDIR:-/tmp}/waybar-localtime-test.XXXXXX")"

cleanup() {
  rm -rf "$TEST_CACHE"
}
trap cleanup EXIT HUP INT TERM

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_eq() {
  label="$1"
  expected="$2"
  actual="$3"

  if [ "$actual" != "$expected" ]; then
    fail "$label: expected '$expected', got '$actual'"
  fi
}

run_case() {
  name="$1"
  lat="$2"
  lng="$3"
  expected_timezone="$4"
  expected_display="$5"

  XDG_CACHE_HOME="$TEST_CACHE" \
    WAYBAR_LOCALTIME_TEST_LAT="$lat" \
    WAYBAR_LOCALTIME_TEST_LNG="$lng" \
    "$REFRESH" >/dev/null

  state_file="$TEST_CACHE/waybar-localtime/state.json"
  [ -r "$state_file" ] || fail "$name: state file was not created"

  timezone="$(jq -er '.timezone' "$state_file")"
  source="$(jq -er '.source' "$state_file")"
  latitude="$(jq -er '.latitude' "$state_file")"
  longitude="$(jq -er '.longitude' "$state_file")"

  assert_eq "$name timezone" "$expected_timezone" "$timezone"
  assert_eq "$name source" "mock-coordinates" "$source"
  assert_eq "$name latitude" "$lat" "$latitude"
  assert_eq "$name longitude" "$lng" "$longitude"

  display_json="$(XDG_CACHE_HOME="$TEST_CACHE" "$DISPLAY")"
  display_text="$(printf '%s\n' "$display_json" | jq -er '.text')"
  tooltip="$(printf '%s\n' "$display_json" | jq -er '.tooltip')"

  case "$display_text" in
    *"$expected_display"*) ;;
    *) fail "$name display text did not include '$expected_display': $display_text" ;;
  esac

  case "$tooltip" in
    *"$expected_timezone"*mock-coordinates*) ;;
    *) fail "$name tooltip did not include timezone and mock source: $tooltip" ;;
  esac

  printf 'ok: %s -> %s\n' "$name" "$timezone"
}

run_case "tokyo" "35.6895" "139.6917" "Asia/Tokyo" "Asia / Tokyo"
run_case "bangkok" "13.7563" "100.5018" "Asia/Bangkok" "Asia / Bangkok"

final_timezone="$(jq -er '.timezone' "$TEST_CACHE/waybar-localtime/state.json")"
assert_eq "final cache timezone" "Asia/Bangkok" "$final_timezone"

printf 'ok: localtime cache switches dynamically with mock coordinates\n'

state_file="$TEST_CACHE/waybar-localtime/state.json"
jq -cn \
  --arg timezone "Asia/Bangkok" \
  --arg updated_at "2000-01-01T00:00:00+07:00" \
  '{
    timezone: $timezone,
    latitude: 13.7563,
    longitude: 100.5018,
    accuracy_m: null,
    source: "mock-stale-cache",
    updated_at: $updated_at
  }' > "$state_file"

stale_display_json="$(XDG_CACHE_HOME="$TEST_CACHE" "$DISPLAY")"
stale_display_text="$(printf '%s\n' "$stale_display_json" | jq -er '.text')"
stale_tooltip="$(printf '%s\n' "$stale_display_json" | jq -er '.tooltip')"

case "$stale_display_text" in
  *"Asia / Tokyo"*) ;;
  *) fail "stale cache display did not fall back to Asia / Tokyo: $stale_display_text" ;;
esac

case "$stale_tooltip" in
  *"fallback-stale-cache"*) ;;
  *) fail "stale cache tooltip did not mark fallback-stale-cache: $stale_tooltip" ;;
esac

printf 'ok: stale cache falls back to OS timezone\n'
