#!/usr/bin/env sh
# Run the test suite with coverage. Locally it also builds and opens an HTML
# report; in CI it stops at coverage/lcov.info, which the Codecov step uploads.
set -eu

usage() {
  cat <<'EOF'
Usage: scripts/dev/coverage.sh [options] [-- <flutter test args>]

Runs the test suite with coverage and writes coverage/lcov.info.
Locally it then builds an HTML report and opens it; in CI (CI=true) it
stops at lcov.info so the Codecov upload step can take over.

Goldens are excluded (--exclude-tags golden): they assert pixels, not
lines, so they add little real coverage.

Options:
  --html       Build and open the HTML report (the default locally).
  --no-html    Skip the report; only write coverage/lcov.info.
  -h, --help   Show this help.

Launcher:
  Local runs use 'fvm flutter' (the SDK pinned in .fvmrc). CI (CI=true)
  or a machine without fvm uses plain 'flutter'. The SDK version is the
  same either way; only the command prefix differs, which is why this
  script exists rather than a hardcoded command.

Examples:
  scripts/dev/coverage.sh                 # full suite, then open the report
  scripts/dev/coverage.sh --no-html       # lcov only
  scripts/dev/coverage.sh -- test/theme   # coverage for one path
EOF
}

# HTML report on locally, off in CI.
if [ "${CI:-}" = "true" ]; then HTML=0; else HTML=1; fi

while [ $# -gt 0 ]; do
  case "$1" in
    --html) HTML=1; shift ;;
    --no-html) HTML=0; shift ;;
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
$FLUTTER test --coverage --exclude-tags golden "$@"

[ "$HTML" -eq 1 ] || exit 0

if ! command -v genhtml >/dev/null 2>&1; then
  echo "coverage/lcov.info written. Install lcov (brew install lcov) for the HTML report." >&2
  exit 0
fi

genhtml coverage/lcov.info -o coverage/html --quiet
echo "HTML report: coverage/html/index.html"
if command -v open >/dev/null 2>&1; then
  open coverage/html/index.html
elif command -v xdg-open >/dev/null 2>&1; then
  xdg-open coverage/html/index.html
fi
