# scripts

Project automation scripts, grouped by purpose in subdirectories.

| Dir | Purpose |
|-----|---------|
| `git-hooks/` | Scripts run by Lefthook Git hooks. See [docs/tools/lefthook.md](../docs/tools/lefthook.md). |
| `dev/` | Local developer helpers. `coverage.sh` runs the suite with coverage (same script CI uses); `goldens.sh` verifies or regenerates the golden references; `catalog.sh` runs the component catalog. See [docs/tools/coverage.md](../docs/tools/coverage.md), [docs/tools/goldens.md](../docs/tools/goldens.md), and [docs/tools/catalog.md](../docs/tools/catalog.md). |

Add a new subdirectory per purpose (e.g. `ci/`, `release/`) rather than dropping loose scripts at the root. Keep scripts POSIX `sh` where possible so they run without extra tooling.
