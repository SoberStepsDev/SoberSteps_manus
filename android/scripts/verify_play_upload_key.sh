#!/usr/bin/env bash
# Verifies android/key.properties points to the Play-registered upload certificate.
# Expected SHA-1 must match Play Console (App integrity) / upload error message.
set -euo pipefail

EXPECTED_SHA1='5C:58:19:49:85:21:D2:34:E6:40:C5:7F:F0:FA:D4:FC:FC:0F:C5:E5'
ANDROID_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROP_FILE="$ANDROID_ROOT/key.properties"

KEYTOOL="${KEYTOOL:-/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool}"
if [[ ! -x "$KEYTOOL" ]]; then
  echo "Set KEYTOOL to keytool binary (e.g. Android Studio JBR)." >&2
  exit 2
fi

if [[ ! -f "$PROP_FILE" ]]; then
  echo "Missing $PROP_FILE — copy android/key.properties.example and fill secrets." >&2
  exit 1
fi

storePassword= keyPassword= keyAlias= storeFile=
while IFS= read -r line || [[ -n "$line" ]]; do
  [[ "$line" =~ ^[[:space:]]*# ]] && continue
  [[ -z "${line// }" ]] && continue
  line="${line%$'\r'}"
  key="${line%%=*}"
  val="${line#*=}"
  case "$key" in
    storePassword) storePassword="$val" ;;
    keyPassword) keyPassword="$val" ;;
    keyAlias) keyAlias="$val" ;;
    storeFile) storeFile="$val" ;;
  esac
done <"$PROP_FILE"

if [[ -z "$storeFile" || -z "$keyAlias" || -z "$storePassword" ]]; then
  echo "key.properties must define storeFile, keyAlias, storePassword." >&2
  exit 1
fi

# Gradle resolves storeFile relative to android/app/
KEYSTORE_ABS="$(cd "$ANDROID_ROOT/app" && cd "$(dirname "$storeFile")" && echo "$PWD/$(basename "$storeFile")")"
if [[ ! -f "$KEYSTORE_ABS" ]]; then
  echo "Keystore not found: $KEYSTORE_ABS (storeFile=$storeFile)" >&2
  exit 1
fi

KP=()
[[ -n "${keyPassword:-}" ]] && KP=(-keypass "$keyPassword")

# shellcheck disable=SC2068
OUT="$("$KEYTOOL" -list -v -keystore "$KEYSTORE_ABS" -alias "$keyAlias" -storepass "$storePassword" ${KP[@]+"${KP[@]}"} 2>&1)" || {
  echo "keytool failed (wrong password, alias, or keystore?)." >&2
  exit 1
}

ACTUAL="$(echo "$OUT" | grep -m1 'SHA1:' | sed 's/^[[:space:]]*SHA1:[[:space:]]*//' | tr 'a-f' 'A-F' | tr -d '\r')"
EXPECT="$(echo "$EXPECTED_SHA1" | tr 'a-f' 'A-F')"

if [[ "$ACTUAL" != "$EXPECT" ]]; then
  echo "SHA1 mismatch." >&2
  echo "  Expected (Play): $EXPECT" >&2
  echo "  Actual (file):   $ACTUAL" >&2
  exit 1
fi

echo "OK — keystore SHA1 matches Play upload key."
