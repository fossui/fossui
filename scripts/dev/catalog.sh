#!/usr/bin/env sh
# Run the component catalog (the example app). By default it syncs deps,
# regenerates the use-case tree, then launches the app. With --build it stops
# after codegen, the step to run in CI before a web build.
set -eu

usage() {
  cat <<'EOF'
Usage: scripts/dev/catalog.sh [options] [-- <flutter run args>]

Runs the component catalog under example/.

By default it runs 'pub get', regenerates the use-case tree with build_runner,
then launches the app. Pass flutter run args after -- to pick a device, e.g.
-- -d chrome (needs the web platform configured first).

Options:
  --build      Sync deps and regenerate the use-case tree, then stop. No run.
  -h, --help   Show this help.

Launcher:
  Local runs use 'fvm flutter' / 'fvm dart' (the SDK pinned in .fvmrc). CI
  (CI=true) or a machine without fvm uses plain 'flutter' / 'dart'. The SDK
  version is the same either way; only the command prefix differs, which is
  why this script exists rather than a hardcoded command.

Examples:
  scripts/dev/catalog.sh                  # codegen, then launch
  scripts/dev/catalog.sh --build          # codegen only (CI, pre-web-build)
  scripts/dev/catalog.sh -- -d chrome     # launch on a chosen device
EOF
}

BUILD_ONLY=""

while [ $# -gt 0 ]; do
  case "$1" in
    --build) BUILD_ONLY=1; shift ;;
    -h|--help) usage; exit 0 ;;
    --) shift; break ;;
    -*) echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
    *) break ;;
  esac
done

# Local uses fvm; CI installs the SDK directly. Pick the launcher.
if [ "${CI:-}" = "true" ] || ! command -v fvm >/dev/null 2>&1; then
  FLUTTER="flutter"
  DART="dart"
else
  FLUTTER="fvm flutter"
  DART="fvm dart"
fi

# The catalog is a separate package under example/; run everything from there.
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$SCRIPT_DIR/../../example"

# $FLUTTER and $DART are two words ('fvm flutter') and must split.
# shellcheck disable=SC2086
$FLUTTER pub get
# shellcheck disable=SC2086
$DART run build_runner build

[ -n "$BUILD_ONLY" ] && exit 0

# shellcheck disable=SC2086
$FLUTTER run "$@"
