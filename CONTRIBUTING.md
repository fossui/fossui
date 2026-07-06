# Contributing

fossui is in beta, so APIs and tokens can still change between releases. Bug
reports, fixes, and questions are welcome.

By taking part you agree to the [Code of Conduct](CODE_OF_CONDUCT.md).

## Before you start

- For a bug, open an issue with a minimal repro (Flutter version, platform, and
  the smallest widget tree that shows it).
- For a new component or an API change, open an issue first so we can agree on
  the shape before code is written. It saves everyone a rewrite.
- Small fixes (typos, docs, obvious bugs) can go straight to a pull request.

## Setup

The package pins its Flutter SDK with [fvm](https://fvm.app):

```bash
fvm install          # uses .fvmrc (Flutter 3.41.9)
fvm flutter pub get
```

Run every Dart and Flutter command through `fvm` so you match the pinned SDK.

## Making changes

- Branch off `main`: `git switch -c fix/short-summary`.
- Keep each change focused. One concern per pull request.
- Public members need a doc comment, and the analyzer is strict. Both are checked
  in CI and by the git hooks.

Before pushing, make sure these pass:

```bash
fvm flutter analyze   # must be clean
fvm flutter test      # all tests green
fvm dart format .     # formatted
```

Commits follow [Conventional Commits](https://www.conventionalcommits.org)
(`type(scope): summary`). A git hook lints the message and formats staged files,
so a malformed commit is rejected locally.

## Pull requests

- Describe what changed and why. Link the issue it closes.
- Add or update tests for the behavior you touch.
- If a change affects the rendered output, include before and after screenshots.
- Note any user-facing change in the CHANGELOG.

Reviews happen when time allows. If a pull request goes quiet, a ping is fine.
