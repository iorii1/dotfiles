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

work_png="$(mktemp -t dotfiless-matugen-XXXXXX.png)"
trap 'rm -f "$work_png"' EXIT

{
    echo "===== $(date) ====="

    # matugen's image decoder panics outright on formats it does not know --
    # AVIF in particular, which turns up here wearing a .jpg extension and
    # leaves the theme silently unchanged. Normalising to one PNG first
    # sidesteps that, and means the monochrome measurement below and matugen
    # itself read exactly the same pixels.
    #
    # ImageMagick only decodes AVIF/HEIC when the libheif delegate is present,
    # which it often is not, so fall back to ffmpeg (already required here for
    # video wallpapers) rather than depending on how IM happens to be built.
    if ! magick "$wallpaper" -resize '600x600>' "$work_png" 2>/dev/null \
        && ! ffmpeg -hide_banner -loglevel error -y -i "$wallpaper" \
            -frames:v 1 -vf "scale='min(600,iw)':-1" "$work_png"; then
        echo "could not decode $wallpaper -- leaving theme unchanged"
        exit 0
    fi

    # Material You scores candidate colours against a chroma floor and discards
    # everything below it. A greyscale wallpaper leaves nothing behind, so
    # matugen quietly falls back to its built-in blue seed and the whole desktop
    # comes out blue. Ask for a greyscale scheme in that case instead.
    #
    # Measured over a real wallpaper library: genuinely monochrome images sit at
    # ~0.01% colourful pixels, a B&W photo with one small coloured object at
    # ~2.7% (matugen extracts that object's colour correctly, so it must stay on
    # the normal path), and ordinary wallpapers at 99-100%. The cutoff has ~270x
    # of headroom either side; anything in 0.1-2 behaves identically.
    MONO_SAT_LEVEL=25   # saturation (%) at which a pixel counts as "colourful"
    MONO_MAX_PCT=1      # below this % of colourful pixels, treat as monochrome

    colour_pct="$(magick "$work_png" -colorspace HSB -channel G -separate +channel \
        -threshold "${MONO_SAT_LEVEL}%" -format "%[fx:mean*100]" info:)"

    scheme_args=()
    if awk -v v="$colour_pct" -v t="$MONO_MAX_PCT" 'BEGIN { exit !(v < t) }'; then
        echo "monochrome wallpaper (${colour_pct}% colourful) -- using scheme-monochrome"
        scheme_args=(-t scheme-monochrome)
    fi

    matugen image "$work_png" -c "$HOME/dotfiless/matugen/config.toml" -m dark \
        --prefer saturation "${scheme_args[@]}"
    qs ipc call theme reloadColors
    hyprctl reload
    # SIGUSR1 makes kitty re-read kitty.conf (and its `include colors.conf`)
    # in every running window, so open terminals -- and anything reading
    # their ANSI palette, e.g. fastfetch -- pick up the new theme live.
    killall -SIGUSR1 kitty 2>/dev/null || true
} >>"$LOG" 2>&1
