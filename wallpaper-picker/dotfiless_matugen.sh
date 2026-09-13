#!/usr/bin/env bash
# Retheme the dotfiless quickshell bar AND Hyprland's border colors after
# qs-wallpaper-picker applies a wallpaper. Invoked as Settings.qml's
# extraReloadCommand (unconditional, runs regardless of the
# enableDynamicColors/enableMatugen toggles).
set -u

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/wallpaper_picker"
LAST="$CACHE_DIR/last_wallpaper"
LOG="/tmp/dotfiless-matugen.log"

[[ -f "$LAST" ]] || exit 0

stored_path="$(cut -d'|' -f2- "$LAST")"
DEFAULT_SOURCE="${QS_WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}"

if [[ "$stored_path" = /* ]]; then
    wallpaper="$stored_path"
else
    wallpaper="$DEFAULT_SOURCE/$stored_path"
fi

[[ -f "$wallpaper" ]] || exit 0

{
    echo "===== $(date) ====="
    matugen image "$wallpaper" -c "$HOME/dotfiless/matugen/config.toml" -m dark --prefer saturation
    qs ipc call theme reloadColors
    hyprctl reload
    # SIGUSR1 makes kitty re-read kitty.conf (and its `include colors.conf`)
    # in every running window, so open terminals -- and anything reading
    # their ANSI palette, e.g. fastfetch -- pick up the new theme live.
    killall -SIGUSR1 kitty 2>/dev/null || true
} >>"$LOG" 2>&1
