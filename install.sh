#!/usr/bin/env bash
# Install skills from this repo into a Claude Code skills directory by
# symlinking them. Symlinks mean edits in this repo go live immediately —
# no re-copy needed. Re-run any time; existing entries are replaced.
#
# Usage:
#   ./install.sh                         # user-level: ~/.claude/skills
#   ./install.sh --project               # project-level: ./.claude/skills (cwd)
#   ./install.sh --project /path/to/proj # project-level at a given project dir
#   ./install.sh verify-note             # only the named skill(s)
#   ./install.sh --project foo bar       # combine: mode + skill filter
#
# Destination precedence: CLAUDE_SKILLS_DIR (if set) overrides everything.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="$REPO_DIR/skills"

MODE="user"
PROJECT_DIR="$PWD"
names=()

while [ "$#" -gt 0 ]; do
  case "$1" in
    --user)    MODE="user"; shift ;;
    --project) MODE="project"; shift
               if [ "$#" -gt 0 ] && [ -d "$1" ]; then PROJECT_DIR="$1"; shift; fi ;;
    -h|--help) sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*)        echo "unknown option: $1" >&2; exit 1 ;;
    *)         names+=("$1"); shift ;;
  esac
done

if [ -n "${CLAUDE_SKILLS_DIR:-}" ]; then
  DEST="$CLAUDE_SKILLS_DIR"
elif [ "$MODE" = "project" ]; then
  DEST="$PROJECT_DIR/.claude/skills"
else
  DEST="$HOME/.claude/skills"
fi

mkdir -p "$DEST"

install_one() {
  local src="$1"
  local name target
  name="$(basename "$src")"
  target="$DEST/$name"
  rm -rf "$target"
  ln -s "$src" "$target"
  echo "linked $name -> $target"
}

if [ "${#names[@]}" -gt 0 ]; then
  for name in "${names[@]}"; do
    src="$SKILLS_SRC/$name"
    [ -d "$src" ] || { echo "no such skill: $name" >&2; exit 1; }
    install_one "$src"
  done
else
  for src in "$SKILLS_SRC"/*/; do
    [ -d "$src" ] || continue
    install_one "${src%/}"
  done
fi

echo "Installed into: $DEST"
echo "Done. Restart Claude Code (or run /skills) to pick up changes."
