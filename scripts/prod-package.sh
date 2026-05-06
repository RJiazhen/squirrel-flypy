#!/usr/bin/env bash
# One-shot production packaging for Squirrel Flypy.
#
# Implements the flow in .cursor/skills/squirrel-package-flow/SKILL.md:
#   - prerequisites (cmake, full Xcode via DEVELOPER_DIR)
#   - bootstrap binary/plum assets via action-install.sh (unless skipped)
#   - make package (Release build + pkg) or make archive (release-style artifact)
#
# For whether a feature belongs in flypy-rime-config vs code vs upstream, see
# .cursor/skills/rime-feature-evaluation-flow/SKILL.md (not run by this script).

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

usage() {
  echo "Usage: $(basename "$0") [--no-install] [--archive]"
  echo ""
  echo "  --no-install, -n   Skip action-install.sh (use when deps are already present)."
  echo "  --archive, -a      Run 'make archive' instead of 'make package' (versioned pkg + archive helpers)."
  echo ""
  echo "Environment:"
  echo "  DEVELOPER_DIR      Xcode path (default: /Applications/Xcode.app/Contents/Developer)"
}

RUN_INSTALL=1
MAKE_TARGET="package"

while [ $# -gt 0 ]; do
  case "$1" in
    --no-install|-n)
      RUN_INSTALL=0
      ;;
    --archive|-a)
      MAKE_TARGET="archive"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "prod-package: unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

if ! command -v cmake >/dev/null 2>&1; then
  echo "prod-package: cmake not found in PATH (see squirrel-package-flow skill)." >&2
  exit 1
fi

if [ ! -d "$DEVELOPER_DIR" ]; then
  echo "prod-package: DEVELOPER_DIR is not a directory: $DEVELOPER_DIR" >&2
  exit 1
fi

if [ "$RUN_INSTALL" -eq 1 ]; then
  bash "$ROOT/action-install.sh"
fi

make "$MAKE_TARGET"

echo ""
echo "prod-package: artifacts under package/:"
find "$ROOT/package" -maxdepth 1 -type f \( -name '*.pkg' -o -name '*.zip' \) -print | sort || true
ls -la "$ROOT/package"/*.pkg 2>/dev/null || true
