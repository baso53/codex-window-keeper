#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="$HOME/.local/bin"
DEST="$INSTALL_DIR/codex-window-keeper"

STATE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/codex-window-keeper"

MARKER_BEGIN="# BEGIN codex-window-keeper"
MARKER_END="# END codex-window-keeper"

if ! command -v crontab >/dev/null 2>&1; then
    echo "WARNING: crontab is not installed; skipping cron cleanup."
else
    CURRENT_CRONTAB="$(mktemp)"
    NEW_CRONTAB="$(mktemp)"

    cleanup() {
        rm -f "$CURRENT_CRONTAB" "$NEW_CRONTAB"
    }
    trap cleanup EXIT

    crontab -l >"$CURRENT_CRONTAB" 2>/dev/null || true

    # Remove only the block created by install.sh.
    awk \
        -v begin="$MARKER_BEGIN" \
        -v end="$MARKER_END" '
        $0 == begin { skip=1; next }
        $0 == end   { skip=0; next }
        !skip       { print }
    ' "$CURRENT_CRONTAB" >"$NEW_CRONTAB"

    # If there is anything left, install the cleaned crontab.
    # Otherwise remove the now-empty user crontab.
    if grep -q '[^[:space:]]' "$NEW_CRONTAB"; then
        crontab "$NEW_CRONTAB"
    else
        crontab -r 2>/dev/null || true
    fi
fi

# Remove only files/directories belonging to codex-window-keeper.
rm -f "$DEST"
rm -rf "$STATE_DIR"

# Remove ~/.local/bin only if it is completely empty.
rmdir "$INSTALL_DIR" 2>/dev/null || true

echo
echo "Uninstalled successfully."
echo
echo "Removed:"
echo "  $DEST"
echo "  $STATE_DIR"
echo "  codex-window-keeper cron entry"
echo
echo "Your other crontab entries were left untouched."
echo "No root privileges were used."