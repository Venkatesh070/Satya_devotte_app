#!/bin/sh
set -e

# Resolve APP_ENV from (highest priority first):
# 1. DART_DEFINES (--dart-define / --dart-define-from-file at flutter run)
# 2. config/app_env.json (single switch when running plain `flutter run`)
# 3. config/app_env.default (CI / fallback)

parse_app_env_from_dart_defines() {
  defines=$1
  [ -n "$defines" ] || return 1

  OLD_IFS=$IFS
  IFS=','
  # shellcheck disable=SC2086
  set -- $defines
  IFS=$OLD_IFS

  for define in "$@"; do
    [ -n "$define" ] || continue
    decoded=$(printf '%s' "$define" | base64 --decode 2>/dev/null || printf '%s' "$define" | base64 -D 2>/dev/null || true)
    case "$decoded" in
      APP_ENV=*)
        printf '%s' "${decoded#APP_ENV=}"
        return 0
        ;;
    esac
  done
  return 1
}

read_app_env_from_json() {
  json_file=$1
  [ -f "$json_file" ] || return 1
  grep -E '"APP_ENV"[[:space:]]*:' "$json_file" 2>/dev/null \
    | sed -E 's/.*"APP_ENV"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/' \
    | tr -d ' \r\n'
}

DEFAULT_APP_ENV=test
CONFIG_FILE="${SRCROOT}/../config/app_env.default"
if [ -f "$CONFIG_FILE" ]; then
  DEFAULT_APP_ENV=$(tr -d ' \r\n' < "$CONFIG_FILE")
fi

APP_ENV=$DEFAULT_APP_ENV

JSON_FILE="${SRCROOT}/../config/app_env.json"
json_env=$(read_app_env_from_json "$JSON_FILE" || true)
if [ -n "$json_env" ]; then
  APP_ENV=$json_env
fi

if resolved=$(parse_app_env_from_dart_defines "${DART_DEFINES:-}"); then
  APP_ENV=$resolved
else
  GENERATED_XCCONFIG="${SRCROOT}/Flutter/Generated.xcconfig"
  if [ -f "$GENERATED_XCCONFIG" ]; then
    FILE_DEFINES=$(grep '^DART_DEFINES=' "$GENERATED_XCCONFIG" | cut -d= -f2- | tr -d '\r')
    if resolved=$(parse_app_env_from_dart_defines "$FILE_DEFINES"); then
      APP_ENV=$resolved
    fi
  fi
fi

RUNNER_DIR="${SRCROOT}/Runner"
ACTIVE_PLIST="${RUNNER_DIR}/GoogleService-Info.plist"

if [ "$APP_ENV" = "prod" ]; then
  SOURCE_PLIST="${RUNNER_DIR}/GoogleService-Info.prod.plist"
else
  SOURCE_PLIST="${RUNNER_DIR}/GoogleService-Info(test).plist"
fi

if [ ! -f "$SOURCE_PLIST" ]; then
  echo "error: Missing Firebase plist for APP_ENV=${APP_ENV}: ${SOURCE_PLIST}" >&2
  exit 1
fi

cp "${SOURCE_PLIST}" "${ACTIVE_PLIST}"
echo "Selected ${SOURCE_PLIST} for APP_ENV=${APP_ENV}"
