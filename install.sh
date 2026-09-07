#!/usr/bin/env bash
# Bootstraps this Hyprland/Quickshell desktop setup on a fresh Arch Linux
# machine: installs packages, enables services, symlinks every config into
# place, and sets up the qs-wallpaper-picker integration.
#
# Safe to re-run: package installs are --needed, symlinks are relinked in
# place, and any real (non-symlink) file/dir already sitting where a
# symlink needs to go gets backed up to <name>.bak instead of clobbered.
set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

info() { printf '\033[1;34m==>\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$1"; }

if ! command -v pacman >/dev/null 2>&1; then
    echo "This installer is Arch Linux only (needs pacman)." >&2
    exit 1
fi

# --- 1. packages ------------------------------------------------------

OFFICIAL_PKGS=(
    hyprland quickshell matugen hyprlock hypridle
    kitty mako rofi fish fastfetch
    cava playerctl imagemagick ffmpeg qt6-multimedia qt6-multimedia-ffmpeg awww
    wl-clipboard cliphist brightnessctl grim slurp libnotify
    networkmanager bluez bluez-utils upower power-profiles-daemon
    xdg-desktop-portal-hyprland ttf-jetbrains-mono-nerd git
)
AUR_PKGS=(mpvpaper xfce-polkit)

info "Installing official packages (pacman)..."
sudo pacman -S --needed --noconfirm "${OFFICIAL_PKGS[@]}"

AUR_HELPER=""
if command -v yay >/dev/null 2>&1; then
    AUR_HELPER=yay
elif command -v paru >/dev/null 2>&1; then
    AUR_HELPER=paru
fi

if [ -n "$AUR_HELPER" ]; then
    info "Installing AUR packages ($AUR_HELPER): ${AUR_PKGS[*]}"
    "$AUR_HELPER" -S --needed --noconfirm "${AUR_PKGS[@]}"
else
    warn "No AUR helper (yay/paru) found -- skipping: ${AUR_PKGS[*]}"
    warn "mpvpaper = video wallpaper support, xfce-polkit = the polkit auth agent."
    warn "Install an AUR helper and re-run, or install these manually."
fi

# --- 2. services --------------------------------------------------------

info "Enabling system services..."
sudo systemctl enable --now NetworkManager bluetooth power-profiles-daemon

# --- 3. symlinks ---------------------------------------------------------

link_path() {
    local target="$1" source="$2"
    mkdir -p "$(dirname -- "$target")"
    if [ -L "$target" ]; then
        : # already a symlink (possibly stale/broken) -- ln -sfn replaces it
    elif [ -e "$target" ]; then
        warn "Backing up existing $target -> $target.bak"
        mv -- "$target" "$target.bak"
    fi
    ln -sfn -- "$source" "$target"
    echo "  $target -> $source"
}

info "Symlinking configs..."
for app in fastfetch fish mako rofi; do
    link_path "$HOME/.config/$app" "$REPO_DIR/$app/.config/$app"
done
# quickshell is not GNU-stow-shaped like the others -- its repo dir *is*
# the config dir directly (no nested .config/quickshell/ inside it).
link_path "$HOME/.config/quickshell" "$REPO_DIR/quickshell"

link_path "$HOME/.config/kitty/kitty.conf" "$REPO_DIR/kitty/.config/kitty/kitty.conf"

for f in monitors.conf hyprland.lua monitors.lua keybinds.conf autostart.conf keybinds.lua hyprland.conf autostart.lua hyprlock.conf hypridle.conf; do
    link_path "$HOME/.config/hypr/$f" "$REPO_DIR/hypr/.config/hypr/$f"
done

link_path "$HOME/.local/bin/take-screenshot" "$REPO_DIR/scripts/.local/bin/take-screenshot"

# --- 4. directories used at runtime --------------------------------------

mkdir -p "$HOME/Pictures/Wallpapers" "$HOME/.cache/quickshell"

# --- 5. qs-wallpaper-picker ------------------------------------------------

PICKER_DIR="$HOME/.local/share/qs-wallpaper-picker"
if [ ! -d "$PICKER_DIR" ]; then
    info "Cloning qs-wallpaper-picker..."
    git clone https://github.com/magetsu002/qs-wallpaper-picker.git "$PICKER_DIR"
else
    info "qs-wallpaper-picker already present at $PICKER_DIR, updating overlay files only."
fi
mkdir -p "$PICKER_DIR/config" "$PICKER_DIR/scripts"
cp "$REPO_DIR/wallpaper-picker/Settings.qml" "$PICKER_DIR/config/Settings.qml"
cp "$REPO_DIR/wallpaper-picker/dotfiless_matugen.sh" "$PICKER_DIR/scripts/dotfiless_matugen.sh"
chmod +x "$PICKER_DIR/scripts/dotfiless_matugen.sh"

echo
info "Done."
echo "  Log out and back into Hyprland (or reboot) to pick up autostart changes."
echo "  Colors default to a fixed palette until you pick a wallpaper: drop images"
echo "  into ~/Pictures/Wallpapers, then press SUPER+W."
