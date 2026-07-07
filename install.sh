#!/usr/bin/env bash
# dev-rigor-stack installer (macOS / Linux / Git Bash).
# Copies the vendored skills into your agent's skills directory.
#
# Usage:
#   ./install.sh                                  # -> $CLAUDE_CONFIG_DIR/skills or ~/.claude/skills
#   ./install.sh --target ~/.codex/skills         # install somewhere else (e.g. Codex)
#   ./install.sh --with-ponytail                  # also fetch the optional ponytail lane from its repo
#   CLAUDE_CONFIG_DIR=/custom ./install.sh
#
# Re-running updates in place (each skill is replaced). No path assumptions.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="$REPO_DIR/skills"
WITH_PONYTAIL=0
TARGET=""

while [ $# -gt 0 ]; do
  case "$1" in
    --with-ponytail) WITH_PONYTAIL=1; shift ;;
    --target) TARGET="${2:-}"; shift 2 ;;
    --target=*) TARGET="${1#*=}"; shift ;;
    -h|--help)
      echo "usage: ./install.sh [--target <skills-dir>] [--with-ponytail]"
      echo "  --target <dir>    install skills into <dir> (default: \$CLAUDE_CONFIG_DIR/skills or ~/.claude/skills)"
      echo "  --with-ponytail   also fetch the optional ponytail (code-minimalism) lane from"
      echo "                    github.com/DietrichGebert/ponytail — third-party, skills only, no hooks"
      exit 0 ;;
    *) echo "unknown option: $1 (try --help)" >&2; exit 2 ;;
  esac
done

if [ ! -d "$SKILLS_SRC" ]; then
  echo "ERROR: no skills/ directory found next to this script ($SKILLS_SRC)" >&2
  exit 1
fi

if [ -n "$TARGET" ]; then
  DEST="$TARGET"
else
  DEST_ROOT="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
  DEST="$DEST_ROOT/skills"
fi

mkdir -p "$DEST"
echo "Installing dev-rigor-stack skills -> $DEST"
echo

installed=0
for src in "$SKILLS_SRC"/*/; do
  name="$(basename "$src")"
  target="$DEST/$name"
  rm -rf "$target"
  cp -r "$src" "$target"
  if [ -f "$target/SKILL.md" ]; then
    printf "  ok    %s\n" "$name"
    installed=$((installed + 1))
  else
    printf "  FAIL  %s (no SKILL.md landed)\n" "$name" >&2
    exit 1
  fi
done

echo
echo "Installed $installed stack skill(s) to $DEST"

if [ "$WITH_PONYTAIL" -eq 1 ]; then
  echo
  echo "Fetching ponytail (third-party — DietrichGebert, MIT) from github.com/DietrichGebert/ponytail ..."
  if ! command -v git >/dev/null 2>&1; then
    echo "  WARN  git not found — skipped ponytail. Your $installed stack skill(s) installed fine."
    echo "        Add it later from https://github.com/DietrichGebert/ponytail"
  else
    tmp="$(mktemp -d)"
    if git clone --depth 1 --quiet "https://github.com/DietrichGebert/ponytail" "$tmp/ponytail" 2>/dev/null \
       && [ -d "$tmp/ponytail/skills" ]; then
      pcount=0
      for ps in "$tmp/ponytail/skills"/*/; do
        pn="$(basename "$ps")"
        pt="$DEST/$pn"
        rm -rf "$pt"; cp -r "$ps" "$pt"
        if [ -f "$pt/SKILL.md" ]; then printf "  ok    %s\n" "$pn"; pcount=$((pcount + 1)); fi
      done
      rm -rf "$tmp"
      echo "  added $pcount ponytail skill(s) — skills only; always-on hooks NOT wired (see its repo for those)."
    else
      rm -rf "$tmp" 2>/dev/null || true
      echo "  WARN  couldn't fetch ponytail (network or repo issue) — skipped."
      echo "        Your $installed stack skill(s) installed fine. Add it later from"
      echo "        https://github.com/DietrichGebert/ponytail"
    fi
  fi
fi

echo
echo "Next steps:"
if [ "$WITH_PONYTAIL" -ne 1 ]; then
  echo "  * ponytail (the code-minimalism / anti-bloat lane) is a separate third-party plugin"
  echo "    by DietrichGebert — not bundled. Re-run with  --with-ponytail  to fetch it, or install"
  echo "    it yourself. The stack works without it; you lose only the 'what can I delete' discipline."
fi
echo "  * Optional: fold config/CLAUDE.md into your own ~/.claude/CLAUDE.md so the stack applies"
echo "    automatically. Review it first -- do not blindly overwrite your existing CLAUDE.md."
echo "  * Restart your agent (or reload skills) so it picks up the new skills."
