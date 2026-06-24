#!/bin/sh
# Reject commit messages that are not Conventional Commits.
# Runs as a commit-msg hook. $1 = path to the commit message file.
#
# By the time this runs, prepare-commit-msg may have prepended a type emoji,
# so an optional leading emoji is allowed before the type.

COMMIT_MSG_FILE=$1

# First non-comment, non-empty line is the subject.
SUBJECT=$(grep -v '^#' "$COMMIT_MSG_FILE" | sed '/^[[:space:]]*$/d' | head -n 1)

# Let Git's own machinery through: merges, reverts, fixup/squash autosquash.
case "$SUBJECT" in
  "Merge "*|"Revert "*|"fixup! "*|"squash! "*|"amend! "*) exit 0 ;;
esac

TYPES='feat|fix|build|chore|ci|docs|style|refactor|perf|test|revert|release|security|update'

# Optional leading emoji ([^[:alnum:]]*), then type, optional (scope), optional !, then ": ".
if printf '%s' "$SUBJECT" | grep -Eq "^[^[:alnum:]]*($TYPES)(\([[:alnum:] ._/-]+\))?!?: .+"; then
  exit 0
fi

cat >&2 <<EOF
✗ Invalid commit message:

    $SUBJECT

Expected Conventional Commits format:  <type>(<optional scope>): <subject>

Allowed types: feat fix build chore ci docs style refactor perf test revert release security update

Examples:
    feat: add primary button widget
    fix(theme): handle null color scheme
    docs: document lefthook setup
EOF
exit 1
