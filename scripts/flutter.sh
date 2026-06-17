#!/bin/sh
# Wrapper so plain `./scripts/flutter.sh run` picks up config/app_env.json.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec flutter --dart-define-from-file="$ROOT/config/app_env.json" "$@"
