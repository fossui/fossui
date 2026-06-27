#!/usr/bin/env sh
# Run the golden tests. By default it verifies against the committed references;
# with --update it regenerates them. CI runs this with CI=true so only the
# committed Ahem flavor renders and gates the build.
set -eu

usage() {
  cat <<'EOF'
Usage: scripts/dev/goldens.sh [options] [-- <flutter test args>]

Runs the golden tests (--tags golden).

By default it verifies the rendered output against the committed references.
With --update it regenerates them; review the diff before committing.

The two flavors render on different platforms, so each is exercised only where
its references were generated. In CI (CI=true) the committed Ahem flavor under
test/**/goldens/ci/ renders and gates the build. Locally the gitignored
host-rendered preview renders; regenerate the ci/ flavor with the Update
goldens workflow.

Options:
  --update     Regenerate the references (--update-goldens).
  -h, --help   Show this help.

Launcher:
  Local runs use 'fvm flutter' (the SDK pinned in .fvmrc). CI (CI=true)
  or a machine without fvm uses plain 'flutter'. The SDK version is the
  same either way; only the command prefix differs, which is why this
  script exists rather than a hardcoded command.

Examples:
  scripts/dev/goldens.sh                  # verify against committed refs
  scripts/dev/goldens.sh --update         # regenerate refs
  scripts/dev/goldens.sh -- test/components/spinner   # one path
EOF
}

UPDATE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --update) UPDATE="--update-goldens"; shift ;;
    -h|--help) usage; exit 0 ;;
    --) shift; break ;;
    -*) echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
    *) break ;;
  esac
done

# Local uses fvm; CI installs flutter directly. Pick the launcher.
if [ "${CI:-}" = "true" ] || ! command -v fvm >/dev/null 2>&1; then
  FLUTTER="flutter"
else
  FLUTTER="fvm flutter"
fi

# $FLUTTER is two words ('fvm flutter') and must split; remaining args are forwarded.
# shellcheck disable=SC2086
$FLUTTER test --tags golden $UPDATE "$@"
