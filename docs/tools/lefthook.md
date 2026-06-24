# Lefthook

[Lefthook](https://lefthook.dev/) is the Git hooks manager we use in `foss_ui`. It runs checks automatically when you commit and push, so broken formatting, lint errors, or failing tests get caught on your machine instead of in CI or review.

## Why we use it

- **Consistency.** Everyone runs the same checks. No "works on my machine" formatting drift.
- **Fast feedback.** You find out about a lint error in seconds at commit time, not minutes later in CI.
- **Zero per-dev config.** The hook definitions live in `lefthook.yml` in the repo. One `lefthook install` wires them into your local `.git/hooks/`.
- **Conventional commits, automatically.** A `prepare-commit-msg` hook prepends a type emoji to your commit message, so history stays readable without anyone memorizing the emoji table.

## Setup

This is a one-time step after cloning.

1. Install the Lefthook binary.

   ```sh
   # macOS
   brew install lefthook

   # or via npm, if you prefer
   npm install -g lefthook
   ```

   Other install methods are listed in the [Lefthook docs](https://lefthook.dev/installation/).

2. Install the Git hooks from inside the repo.

   ```sh
   lefthook install
   ```

   You should see:

   ```
   sync hooks: ✔️ (pre-push, prepare-commit-msg, pre-commit)
   ```

That's it. The hooks now fire on every commit and push.

> **Note:** This project pins Flutter with [FVM](https://fvm.app/) (`.fvmrc` is `3.41.9`), so the hooks call `fvm flutter` / `fvm dart`. Make sure FVM is installed and the SDK is set up (`fvm install`) or the hooks will fail.

## How we use it

All config lives in [`lefthook.yml`](../../lefthook.yml).

### `pre-commit`

Runs on staged `.dart` files, in parallel:

| Command | What it does |
|---------|--------------|
| `fvm dart format` | Formats staged files and re-stages the result (`stage_fixed: true`). |
| `fvm flutter analyze` | Runs the analyzer; blocks the commit on any error. |

Keeping this stage fast matters, since it runs on every commit. Formatting and analysis are quick; the slower test suite is deferred to push.

### `pre-push`

| Command | What it does |
|---------|--------------|
| `fvm flutter test` | Runs the full suite, including golden tests. |

Golden tests are slow, so they run once before a push rather than on every commit.

### `prepare-commit-msg`

Prepends an emoji based on the [Conventional Commits](https://www.conventionalcommits.org/) type prefix. The logic lives in [`scripts/git-hooks/commit-msg-emoji.sh`](../../scripts/git-hooks/commit-msg-emoji.sh), wired into the hook as a `command` so all project scripts can live under `scripts/` instead of Lefthook's own directory.

```
feat: add button widget   ->   ✨ feat: add button widget
fix: handle null theme    ->   🐛 fix: handle null theme
```

Type-to-emoji map:

| Type | Emoji | Type | Emoji |
|------|-------|------|-------|
| `feat` | ✨ | `perf` | ⚡ |
| `fix` | 🐛 | `test` | 🧪 |
| `build` | 📦 | `revert` | ⏪ |
| `chore` | 🔧 | `release` | 🚀 |
| `ci` | 👷 | `security` | 🔒 |
| `docs` | 📝 | `update` | ⬆️ |
| `style` | 💄 | `refactor` | ♻️ |

The script is a no-op when:

- the message already starts with an emoji (so amends and re-edits stay clean), or
- the commit comes from a merge or squash, or
- the prefix doesn't match any known type.

This hook only decorates; it never blocks a commit. Enforcement is the `commit-msg` hook below.

### `commit-msg`

Rejects any commit whose subject is not a [Conventional Commit](https://www.conventionalcommits.org/). The check lives in [`scripts/git-hooks/commit-msg-lint.sh`](../../scripts/git-hooks/commit-msg-lint.sh).

A subject must match `<type>(<optional scope>): <subject>`, using one of the allowed types (same list as the emoji map). An optional leading emoji is allowed, since `prepare-commit-msg` runs first and may have added one.

```
feat: add button widget        accepted
fix(theme): handle null scheme accepted
✨ feat: add button widget      accepted
added: something               rejected (unknown type)
Fix: capitalized type          rejected (types are lowercase)
```

Merge, revert, and `fixup!` / `squash!` autosquash subjects are allowed through untouched. A rejected commit prints the rule and an example, and the commit is aborted so you can rewrite the message.

## Day-to-day

```sh
# Run a hook manually, without committing
lefthook run pre-commit
lefthook run pre-push

# Skip hooks for a single commit (use sparingly)
git commit --no-verify

# Re-sync after changing lefthook.yml
lefthook install
```

When you edit `lefthook.yml` or add a script, run `lefthook install` again so the local hooks pick up the change.

## Troubleshooting

- **Hook does nothing on commit.** Run `lefthook install`; the Git hook file may be missing or stale.
- **`fvm: command not found`.** Install FVM and run `fvm install` so the pinned SDK exists.
- **Skipped commands say "no matching staged files".** Expected when no `.dart` files are staged; the `pre-commit` checks are scoped to Dart files.
- **Need to bypass once.** `git commit --no-verify` / `git push --no-verify`. Don't make it a habit, since CI runs the same checks.

## Committing the config

`lefthook.yml` and the `scripts/` directory are tracked in Git. After cloning, every dev only needs `lefthook install` to get the same hooks.
