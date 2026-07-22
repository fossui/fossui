#!/usr/bin/env sh
# Measure what fossui adds to an app: worst-case Dart (AOT) code plus the bundled
# font. Builds an app that exercises every component (the gallery by default),
# reads Flutter's --analyze-size snapshot, and sums the package:fossui symbols.
#
# Usage:
#   scripts/dev/measure-size.sh [app-dir] [target]
#     app-dir  app that imports every component (default: the bundled example/)
#     target   build target: apk | appbundle | ios (default: apk)
#
# Needs the toolchain for the target (Android SDK for apk/appbundle, Xcode for
# ios) and python3. The app dir owns its Flutter version, so the build runs
# through its own fvm.
set -eu

script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd)
pkg_dir=$(CDPATH= cd "$script_dir/../.." && pwd)
font="$pkg_dir/fonts/Geist-Variable.ttf"

app=${1:-"$pkg_dir/example"}
target=${2:-apk}

[ -d "$app" ] || { echo "app dir not found: $app" >&2; exit 1; }
[ -f "$font" ] || { echo "font not found: $font" >&2; exit 1; }
app=$(CDPATH= cd "$app" && pwd)

case "$target" in
  apk|appbundle) arch=arm64-v8a; platform_flag="--target-platform=android-arm64" ;;
  ios) arch=arm64; platform_flag="" ;;
  *) echo "unsupported target: $target (apk|appbundle|ios)" >&2; exit 1 ;;
esac

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# The bundled example is Dart-only (no android/ios project), so build a staged
# copy: scaffold the platform the target needs and repoint the fossui dependency
# at this package by absolute path. The committed example stays untouched.
echo "Staging $app and building $target (release, --analyze-size)..." >&2
cp -R "$app/." "$work/"
rm -rf "$work/.dart_tool" "$work/build" "$work/pubspec.lock" \
       "$work/android" "$work/ios"
(
  cd "$work"
  # Repoint fossui at this package by absolute path before any pub resolution;
  # the override replaces the example's own relative path source, which no
  # longer resolves from the copy.
  printf 'dependency_overrides:\n  fossui:\n    path: %s\n' "$pkg_dir" \
    > pubspec_overrides.yaml
  case "$target" in
    ios) fvm flutter create --platforms=ios . >/dev/null ;;
    *)   fvm flutter create --platforms=android . >/dev/null ;;
  esac
  # shellcheck disable=SC2086
  fvm flutter build "$target" --release $platform_flag --analyze-size >&2
)

# --analyze-size writes a size tree to ~/.flutter-devtools; the freshest file is
# this build's.
snap=$(ls -t "$HOME"/.flutter-devtools/*code-size-analysis*.json 2>/dev/null \
  | head -n1)
[ -n "$snap" ] || { echo "no size analysis json found" >&2; exit 1; }

# The tree is {n: name, value: bytes, children: [...]}. Group nodes carry a zero
# value, so sum the leaf symbols under the package:fossui subtree (never
# package:fossui_example). The font is a leaf under the assets subtree; its value
# is the compressed size the app downloads.
metrics=$(python3 - "$snap" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
dart = font_app = 0

def leafsum(node):
    kids = node.get('children') or []
    return (node.get('value', 0) or 0) if not kids \
        else sum(leafsum(c) for c in kids)

def walk(node, in_assets):
    global dart, font_app
    n = node.get('n', '')
    if n == 'package:fossui':
        dart += leafsum(node); return
    if in_assets and n == 'fossui':
        font_app += leafsum(node); return
    for c in node.get('children') or []:
        walk(c, in_assets or n == 'assets')

walk(d, False)
print(dart, font_app)
PY
)
dart_bytes=${metrics% *}
font_app_bytes=${metrics#* }
font_disk=$(wc -c < "$font" | tr -d ' ')
[ "${font_app_bytes:-0}" -gt 0 ] || font_app_bytes=$(gzip -c "$font" | wc -c | tr -d ' ')

kb() { echo $(( ($1 + 512) / 1024 )); }

echo
echo "| Item | Size | Notes |"
echo "|------|------|-------|"
echo "| Dart code (AOT) | $(kb "$dart_bytes") KB | tree-shaken; worst-case, every component referenced |"
echo "| Geist font (download) | $(kb "$font_app_bytes") KB | compressed in the build |"
echo "| Geist font (on disk) | $(kb "$font_disk") KB | after install; fixed cost |"
echo "| Runtime deps | ~0 | one annotation package, no icon dependency |"
echo "| **Total (on disk)** | **$(kb $(( dart_bytes + font_disk ))) KB** | Dart plus installed font |"
echo
echo "Target: $target ($arch).  App: $app"
