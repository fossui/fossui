#!/bin/sh
COMMIT_MSG_FILE=$1
COMMIT_SOURCE=$2

# Only modify manual commits (not merges, squashes, etc.)
[ "$COMMIT_SOURCE" = "merge" ] && exit 0
[ "$COMMIT_SOURCE" = "squash" ] && exit 0

MSG=$(cat "$COMMIT_MSG_FILE")

# Skip if emoji already present
echo "$MSG" | grep -qP '^[\x{1F000}-\x{1FFFF}]' 2>/dev/null || \
echo "$MSG" | grep -q '^[🎉✨🐛🔨📦🔧👷📝💄♻️⚡🧪⏪🚀🔒💥]' && exit 0

case "$MSG" in
  feat*)     EMOJI="✨" ;;
  fix*)      EMOJI="🐛" ;;
  build*)    EMOJI="📦" ;;
  chore*)    EMOJI="🔧" ;;
  ci*)       EMOJI="👷" ;;
  docs*)     EMOJI="📝" ;;
  style*)    EMOJI="💄" ;;
  refactor*) EMOJI="♻️" ;;
  perf*)     EMOJI="⚡" ;;
  test*)     EMOJI="🧪" ;;
  revert*)   EMOJI="⏪" ;;
  release*)  EMOJI="🚀" ;;
  security*) EMOJI="🔒" ;;
  update*)   EMOJI="⬆️" ;;
  *)         exit 0 ;;
esac

echo "$EMOJI $MSG" > "$COMMIT_MSG_FILE"
