#!/bin/sh
set -eu

STATE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/waybar-localtime"
STATE_FILE="$STATE_DIR/state.json"
WHEREAMI="${WAYBAR_LOCALTIME_WHEREAMI:-/usr/lib/geoclue-2.0/demos/where-am-i}"
TZF="${WAYBAR_LOCALTIME_TZF:-/home/trt-ryzen7/.cargo/bin/tzf}"
CURL="${WAYBAR_LOCALTIME_CURL:-curl}"
BUSCTL="${WAYBAR_LOCALTIME_BUSCTL:-busctl}"
BEACONDB_URL="${WAYBAR_LOCALTIME_BEACONDB_URL:-https://api.beacondb.net/v1/geolocate}"
TIMEOUT="${WAYBAR_LOCALTIME_TIMEOUT:-20}"
ACCURACY_LEVEL="${WAYBAR_LOCALTIME_ACCURACY_LEVEL:-4}"

die() {
  printf '%s\n' "$*" >&2
  exit 1
}

keep_cache_or_die() {
  printf '%s\n' "$*" >&2
  if [ -r "$STATE_FILE" ]; then
    printf 'Keeping existing timezone cache: %s\n' "$STATE_FILE" >&2
    exit 0
  fi
  exit 1
}

trim() {
  sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

is_number() {
  awk -v n="$1" 'BEGIN { exit !(n ~ /^-?[0-9]+([.][0-9]+)?([eE][+-]?[0-9]+)?$/) }'
}

iwd_wifi_json() {
  "$BUSCTL" --system tree net.connman.iwd 2>/dev/null |
    sed -n 's#.*[/]\([0-9a-fA-F]\{12\}\)$#\1#p' |
    sort -u |
    jq -R -s -c '
      split("\n")
      | map(select(length == 12) | ascii_downcase | [range(0; 12; 2) as $i | .[$i:$i + 2]] | join(":") | {macAddress: .})
      | {wifiAccessPoints: .}
    '
}

iwd_location_output() {
  command -v "$CURL" >/dev/null 2>&1 || return 1
  command -v "$BUSCTL" >/dev/null 2>&1 || return 1

  wifi_json="$(iwd_wifi_json)" || return 1
  access_point_count="$(printf '%s\n' "$wifi_json" | jq -er '.wifiAccessPoints | length')" || return 1
  [ "$access_point_count" -gt 0 ] || return 1

  printf '%s' "$wifi_json" |
    "$CURL" -fsS --max-time "$TIMEOUT" \
      -X POST \
      -H 'Content-Type: application/json' \
      --data-binary @- \
      "$BEACONDB_URL"
}

[ -x "$TZF" ] || die "tzf is not executable: $TZF"

if [ -n "${WAYBAR_LOCALTIME_TEST_LAT:-}" ] && [ -n "${WAYBAR_LOCALTIME_TEST_LNG:-}" ]; then
  lat="$WAYBAR_LOCALTIME_TEST_LAT"
  lon="$WAYBAR_LOCALTIME_TEST_LNG"
  accuracy="null"
  source="mock-coordinates"
elif [ -n "${WAYBAR_LOCALTIME_TEST_LAT:-}" ] || [ -n "${WAYBAR_LOCALTIME_TEST_LNG:-}" ]; then
  die "WAYBAR_LOCALTIME_TEST_LAT and WAYBAR_LOCALTIME_TEST_LNG must be set together"
else
  [ -x "$WHEREAMI" ] || die "where-am-i is not executable: $WHEREAMI"

  location_output="$("$WHEREAMI" --timeout="$TIMEOUT" --accuracy-level="$ACCURACY_LEVEL" 2>&1)" ||
    location_output=""

  lat="$(printf '%s\n' "$location_output" | awk -F: '/Latitude:/ { print $2; exit }' | trim)"
  lon="$(printf '%s\n' "$location_output" | awk -F: '/Longitude:/ { print $2; exit }' | trim)"
  accuracy="$(printf '%s\n' "$location_output" | awk -F: '/Accuracy:/ { gsub(/meters/, "", $2); print $2; exit }' | trim)"
  source="geoclue"

  if [ -z "$lat" ] || [ -z "$lon" ]; then
    printf 'GeoClue output did not include Latitude/Longitude. Raw output: %s\n' "$location_output" >&2

    iwd_output="$(iwd_location_output 2>&1)" ||
      keep_cache_or_die "Could not get location from GeoClue or iwd/BeaconDB. iwd/BeaconDB output: $iwd_output"

    lat="$(printf '%s\n' "$iwd_output" | jq -er '.location.lat // empty')" ||
      keep_cache_or_die "BeaconDB output did not include location.lat. Raw output: $iwd_output"
    lon="$(printf '%s\n' "$iwd_output" | jq -er '.location.lng // empty')" ||
      keep_cache_or_die "BeaconDB output did not include location.lng. Raw output: $iwd_output"
    accuracy="$(printf '%s\n' "$iwd_output" | jq -er '.accuracy // empty' 2>/dev/null || true)"
    beacondb_fallback="$(printf '%s\n' "$iwd_output" | jq -er '.fallback // empty' 2>/dev/null || true)"
    source="iwd-beacondb"
    if [ -n "$beacondb_fallback" ]; then
      source="iwd-beacondb-$beacondb_fallback"
    fi
  fi
fi

[ -n "$lat" ] || die "Latitude is empty"
[ -n "$lon" ] || die "Longitude is empty"
is_number "$lat" || die "Latitude is not numeric: $lat"
is_number "$lon" || die "Longitude is not numeric: $lon"
if [ -z "$accuracy" ] || ! is_number "$accuracy"; then
  accuracy="null"
fi

timezone="$("$TZF" --lng "$lon" --lat "$lat" | jq -er .)" ||
  die "Could not convert location to timezone"

[ -n "$timezone" ] || die "tzf returned an empty timezone"
[ -e "/usr/share/zoneinfo/$timezone" ] || die "Unknown zoneinfo timezone: $timezone"

mkdir -p "$STATE_DIR"
tmp="$(mktemp "$STATE_DIR/state.json.XXXXXX")"
trap 'rm -f "$tmp"' EXIT HUP INT TERM

updated_at="$(TZ="$timezone" date -Iseconds)"

if [ "$accuracy" = "null" ]; then
  jq -cn \
    --arg timezone "$timezone" \
    --arg latitude "$lat" \
    --arg longitude "$lon" \
    --arg source "$source" \
    --arg updated_at "$updated_at" \
    '{
      timezone: $timezone,
      latitude: ($latitude | tonumber),
      longitude: ($longitude | tonumber),
      accuracy_m: null,
      source: $source,
      updated_at: $updated_at
    }' > "$tmp"
else
  jq -cn \
    --arg timezone "$timezone" \
    --arg latitude "$lat" \
    --arg longitude "$lon" \
    --arg accuracy "$accuracy" \
    --arg source "$source" \
    --arg updated_at "$updated_at" \
    '{
      timezone: $timezone,
      latitude: ($latitude | tonumber),
      longitude: ($longitude | tonumber),
      accuracy_m: ($accuracy | tonumber),
      source: $source,
      updated_at: $updated_at
    }' > "$tmp"
fi

mv "$tmp" "$STATE_FILE"
trap - EXIT HUP INT TERM
printf '%s\n' "$STATE_FILE"
