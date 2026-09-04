#  Iori's Dotfiles

> Personal Wayland desktop configurations on Arch Linux running **Hyprland**, **Quickshell**, **Rofi**, and **kitty**. Managed cleanly with GNU `stow`.
  WORK IN PROGRESS!!
---

##  Screenshots



---

##  Components

| Component | Tool |
| :--- | :--- |
| **Window Manager** | [Hyprland](https://hyprland.org) |
| **Status Bar** | [Quickshell](https://git.outfoxxed.me/quickshell/quickshell) |
| **Notifications** | [mako](https://mako-project.org) |
| **Application Launcher** | [Rofi](https://davatorium.github.io/rofi) |
| **Terminal** | [kitty](https://github.com/kovidgoyal/kitty) |
| **System Info** | [Fastfetch](https://github.com/fastfetch-cli/fastfetch) |
| **Shell** | [Fish](https://fishshell.com/) |

---

##  Core Keybindings

| Keybinding | Action |
| :--- | :--- |
| `ALT` + `SPACE` | Launch Rofi (`drun`) |
| `ALT` + `RETURN` | Open kitty Terminal |
| `ALT` + `Q` | Close Active Window |
| `SUPER` + `R` | Reload Hyprland Config |
| `SUPER` + `SHIFT` + `E` | Quit Hyprland |
| `SUPER` + `1-9` | Switch Workspaces |
| `SUPER` + `SHIFT` + `1-9` | Move Window to Workspace |
| `Print` | Screenshot: full screen (saved + copied) |
| `SHIFT` + `Print` | Screenshot: region (copied only) |
| `SUPER` + `SHIFT` + `S` | Screenshot: region (saved only) |

---

##  Installation & Deployment

To replicate this setup on a fresh installation:

```bash
# 1. Clone the repository
git clone [https://github.com/jorind12313/dotfiles.git](https://github.com/jorind12313/dotfiles.git) ~/.dotfiles
cd ~/.dotfiles

# 2. Install GNU Stow
sudo pacman -S stow

# 3. Stow desired configurations
stow hypr
stow quickshell
stow mako
stow rofi
stow kitty
stow fastfetch
stow fish
stow scripts
```
