#!/usr/bin/env bash
# GAPIT-AI installer (TRAE / Claude Code)
#
# Usage:
#   ./install.sh          install the TRAE version (default)
#   ./install.sh claude   install the Claude Code version
#
# Override install location with TRAE_SKILLS_DIR / CLAUDE_SKILLS_DIR.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODE="${1:-trae}"

case "$MODE" in
  trae)
    SRC="$REPO/.trae/skills/GAPIT-AI"
    PARENT="${TRAE_SKILLS_DIR:-$HOME/.trae/skills}"
    DST="$PARENT/GAPIT-AI"
    ;;
  claude)
    SRC="$REPO/.claude/skills/gapit-ai"
    PARENT="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
    DST="$PARENT/gapit-ai"
    ;;
  *)
    echo "Usage: $0 [trae|claude]" >&2
    exit 1
    ;;
esac

mkdir -p "$PARENT"
rm -rf "$DST"
cp -R "$SRC" "$DST"

# Copy shared data resources next to the skill parent so
# data/gapit-resources/{gapit_functions.txt, templates, question bank}
# are discoverable by the mode code.
cp -R "$REPO/data" "$PARENT/"

echo "GAPIT-AI ($MODE) installed:"
echo "  skill -> $DST"
echo "  data  -> $PARENT/data"
