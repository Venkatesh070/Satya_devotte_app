#!/bin/sh
set -e

DEFAULT_APP_ENV=test
CONFIG_FILE="${SRCROOT}/../config/app_env.default"
if [ -f "$CONFIG_FILE" ]; then
  DEFAULT_APP_ENV=$(tr -d ' \r\n' < "$CONFIG_FILE")
fi

APP_ENV=$DEFAULT_APP_ENV
GENERATED_XCCONFIG="${SRCROOT}/Flutter/Generated.xcconfig"
if [ -f "$GENERATED_XCCONFIG" ]; then
  # xcconfig is not shell syntax — extract DART_DEFINES without sourcing.
  DART_DEFINES=$(grep '^DART_DEFINES=' "$GENERATED_XCCONFIG" | cut -d= -f2- | tr -d '\r')
fi

if [ -n "${DART_DEFINES}" ]; then
  OLD_IFS=$IFS
  IFS=','
  # shellcheck disable=SC2086
  set -- $DART_DEFINES
  IFS=$OLD_IFS
  for define in "$@"; do
    decoded=$(printf '%s' "$define" | base64 --decode 2>/dev/null || printf '%s' "$define" | base64 -D 2>/dev/null || true)
    case "$decoded" in
      APP_ENV=*)
        APP_ENV="${decoded#APP_ENV=}"
        ;;
    esac
  done
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
