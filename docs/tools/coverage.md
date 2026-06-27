# Coverage

`foss_ui` measures test coverage with Flutter's built-in `--coverage` and reports it to [Codecov](https://about.codecov.io/). Coverage tells you which lines the tests actually exercised, so gaps show up before review instead of after.

Treat the number as a signal, not a target. A covered line ran under test; it does not prove the assertion around it was meaningful. Coverage rides alongside the tests that catch real regressions (token bake values, goldens, accessibility), it does not replace them.

## Running it locally

From the repo root:

```sh
sh scripts/dev/coverage.sh
```

This runs the suite with coverage, writes `coverage/lcov.info`, then builds an HTML report and opens it. Goldens are excluded because they assert pixels, not lines, and add little real coverage; the regular suite is what drives the number.

```sh
sh scripts/dev/coverage.sh --help        # all options
sh scripts/dev/coverage.sh --no-html      # lcov only, skip the report
sh scripts/dev/coverage.sh -- test/theme  # coverage for one path
```

The script picks the launcher for you: `fvm flutter` locally, plain `flutter` in CI (or where `fvm` is absent). The pinned SDK is the same either way, only the prefix differs, so the same script runs in both places. The HTML report needs the lcov tools (`brew install lcov`); without them the script still writes `coverage/lcov.info` and tells you.

The raw commands, if you would rather not use the script:

```sh
fvm flutter test --coverage --exclude-tags golden
genhtml coverage/lcov.info -o coverage/html && open coverage/html/index.html
```

`coverage/` is gitignored, so nothing here is committed.

## The const-constructor caveat

This is the one surprise worth knowing. Dart coverage does not record a `const` constructor call as a hit, so a widget built with `const` in a test shows up as uncovered even though the test drove it. `foss_ui` is const-heavy, so left alone this under-reports component coverage badly.

The fix lives in [`test/analysis_options.yaml`](../../test/analysis_options.yaml): it turns `prefer_const_constructors` and `prefer_const_literals_to_create_immutables` off for tests only. The analyzer applies the nearest options file, so `lib/` stays const-correct; only test files opt out, so their widget instantiations are non-const and register coverage. When you write a widget test, build the widget without `const` and let coverage count it.

## Every file in the report

`flutter test --coverage` only instruments libraries a test imports. A `lib/` file that no test touches is not reported at 0%, it is absent, which silently inflates the percentage. [`test/coverage_all_test.dart`](../../test/coverage_all_test.dart) imports the public barrel so the whole exported graph stays in the report regardless of what the real tests cover. If you add an internal library the barrel does not export and nothing exported imports, give it its own test or add an import to that file, or it will be invisible.

## How it is wired

All config lives in [`codecov.yml`](../../codecov.yml) and the CI workflow ([`.github/workflows/ci.yaml`](../../.github/workflows/ci.yaml)).

CI runs the same `flutter test --coverage` and uploads the result:

```yaml
- name: Upload coverage to Codecov
  uses: codecov/codecov-action@v5
  with:
    use_oidc: true
    files: coverage/lcov.info
    fail_ci_if_error: false
```

- **Tokenless.** This is a public repo, so the upload authenticates with GitHub OIDC (`use_oidc: true` plus `id-token: write` on the job). There is no `CODECOV_TOKEN` secret to manage.
- **Never breaks the build.** `fail_ci_if_error: false` means a flaky or skipped upload (for example a fork PR where the OIDC token is restricted) does not fail CI.

`codecov.yml` controls the report:

| Setting | Value | Why |
|---------|-------|-----|
| `project` | `auto`, informational | Guards the whole package against backsliding without blocking. |
| `patch` | `90%`, informational | New code should ship with tests. The lever that matters. |
| `ignore` | barrel, `*.tailor.dart`, `*.g.dart`, `example/` | Measure authored logic, not generated or re-export files. |

Both checks are informational while the component set is still landing, so a gap annotates a pull request without blocking it. The `patch` check flips to blocking before 1.0.

## One-time Codecov setup

The CI step uploads on every run, but reports only appear once the repository is connected on Codecov's side. This is a manual step, done once by a maintainer:

1. Sign in at [codecov.io](https://about.codecov.io/) with GitHub and grant access to the repository's owner.
2. Add (activate) this repository in the Codecov dashboard.
3. Confirm tokenless OIDC is accepted for the org. The workflow already sends an OIDC token (`use_oidc: true`); no `CODECOV_TOKEN` is needed for a public repo. If a fallback is ever required, add `CODECOV_TOKEN` as a repository secret.

Until step 2 is done, the upload runs but no report is produced, and CI stays green because `fail_ci_if_error: false`.

## Badge

Once coverage is meaningful, add the badge to the README (replace `OWNER`):

```md
[![codecov](https://codecov.io/gh/OWNER/foss_ui/branch/main/graph/badge.svg)](https://codecov.io/gh/OWNER/foss_ui)
```

It is left out until then so it does not show an empty or misleading number before the repository is connected.

## Day-to-day

```sh
# full run with coverage, then open the report
sh scripts/dev/coverage.sh

# a single file, still with coverage
sh scripts/dev/coverage.sh -- test/theme/foss_colors_test.dart

# lcov only, no report
sh scripts/dev/coverage.sh --no-html
```

## Troubleshooting

- **A widget test passes but its widget reads as uncovered.** It was built `const`. Drop the `const`; see the caveat above.
- **`genhtml: command not found`.** Install the lcov tools (`brew install lcov`).
- **`coverage/lcov.info` is missing.** Run the test command with `--coverage`; a plain `fvm flutter test` does not emit it.
- **Codecov upload skipped on a fork PR.** Expected. OIDC tokens are restricted on forks, and the upload is set not to fail CI.
