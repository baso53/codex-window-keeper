#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="$SCRIPT_DIR/codex-window-keeper"

INSTALL_DIR="$HOME/.local/bin"
DEST="$INSTALL_DIR/codex-window-keeper"

MARKER_BEGIN="# BEGIN codex-window-keeper"
MARKER_END="# END codex-window-keeper"

if [[ ! -f "$SOURCE" ]]; then
    echo "ERROR: Cannot find:"
    echo "  $SOURCE"
    exit 1
fi

if ! command -v crontab >/dev/null 2>&1; then
    echo "ERROR: crontab is not installed."
    exit 1
fi

if ! command -v codex >/dev/null 2>&1; then
    echo "ERROR: codex is not available in your current PATH."
    echo "Install/login to Codex CLI first."
    exit 1
fi

CODEX_BIN="$(command -v codex)"

mkdir -p "$INSTALL_DIR"

# Install our script into the current user's ~/.local/bin only.
cp "$SOURCE" "$DEST"
chmod 700 "$DEST"

# Preserve the user's existing crontab.
CURRENT_CRONTAB="$(mktemp)"
NEW_CRONTAB="$(mktemp)"

cleanup() {
    rm -f "$CURRENT_CRONTAB" "$NEW_CRONTAB"
}
trap cleanup EXIT

crontab -l >"$CURRENT_CRONTAB" 2>/dev/null || true

# Remove an older installation of our own marked block, if present.
awk \
    -v begin="$MARKER_BEGIN" \
    -v end="$MARKER_END" '
    $0 == begin { skip=1; next }
    $0 == end   { skip=0; next }
    !skip       { print }
' "$CURRENT_CRONTAB" >"$NEW_CRONTAB"

# Avoid accumulating unnecessary blank lines.
while [[ -s "$NEW_CRONTAB" ]] && [[ "$(tail -c 1 "$NEW_CRONTAB" | wc -l)" -eq 0 ]]; do
    printf '\n' >>"$NEW_CRONTAB"
    break
done

cat >>"$NEW_CRONTAB" <<EOF
$MARKER_BEGIN
CODEX_BIN=$CODEX_BIN
* * * * * $DEST
$MARKER_END
EOF

crontab "$NEW_CRONTAB"

echo
echo "Installed successfully."
echo
echo "Script:"
echo "  $DEST"
echo
echo "Codex:"
echo "  $CODEX_BIN"
echo
echo "Cron:"
echo "  Runs once per minute as user: $USER"
echo
echo "No root privileges were used."