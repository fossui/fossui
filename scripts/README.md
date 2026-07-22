# scripts

Project automation scripts, grouped by purpose in subdirectories.

| Dir | Purpose |
|-----|---------|
| `git-hooks/` | Scripts run by Lefthook Git hooks. See [doc/tools/lefthook.md](../doc/tools/lefthook.md). |
| `dev/` | Local developer helpers. `coverage.sh` runs the suite with coverage (same script CI uses); `goldens.sh` verifies or regenerates the golden references; `measure-size.sh` reports the worst-case package size (Dart AOT plus font) behind [doc/package-size.md](../doc/package-size.md). See [doc/tools/coverage.md](../doc/tools/coverage.md) and [doc/tools/goldens.md](../doc/tools/goldens.md). |

Add a new subdirectory per purpose (e.g. `ci/`, `release/`) rather than dropping loose scripts at the root. Keep scripts POSIX `sh` where possible so they run without extra tooling.
