# How this desktop fits together

A map of the whole system: which processes exist, who talks to whom, where
every file lives, and what happens when you press a key. Written to be read
front to back once, then dipped into.

Companion document: [`shell-rebuild.md`](shell-rebuild.md) covers *why* parts
of the shell look the way they do, and the traps found building them.

---

## 1. The shape of it

There is no desktop environment here. There is a compositor, a shell, and a
handful of small daemons, and they agree on things through Wayland protocols
and D-Bus rather than through a framework.

```
                    ┌─────────────────────────────────────┐
                    │            Hyprland                 │
                    │  compositor · window manager        │
                    │  reads hypr/*.lua                   │
                    └──────────────┬──────────────────────┘
                                   │ wayland (wlr-layer-shell)
                                   │ + its own IPC socket
                    ┌──────────────▼──────────────────────┐
                    │           quickshell                │
                    │  ONE process. Every panel, the bar, │
                    │  the notification daemon, the       │
                    │  polkit agent, the OSD.             │
                    └──┬────────┬────────┬────────┬───────┘
                       │        │        │        │
              D-Bus ───┘        │        │        └─── spawns processes
         NetworkManager         │        │             (grim, cliphist,
         BlueZ · UPower         │        │              wlsunset, cava,
         PipeWire · polkit      │        │              wf-recorder…)
         o.f.Notifications      │        │
                                │        └─── reads/writes
                    Hyprland IPC│             ~/.local/state/quickshell/*.json
                    (workspaces,│
                     toplevels) │
                                │
   ┌────────────────────────────┴───────────────────────────────┐
   │ other processes Hyprland starts: awww-daemon (wallpaper),  │
   │ hypridle (idle), wl-paste ×2 (clipboard capture)           │
   └────────────────────────────────────────────────────────────┘
```

The single most important fact: **quickshell is one process.** The bar, the
launcher, every popup, the notification daemon and the polkit agent all live
inside it and share memory. That is why a service singleton can be read
directly by any panel, and why a crash takes the whole shell with it.

---

## 2. Where the files live

The repo is not GNU stow, but it is stow-*shaped*: `<app>/.config/<app>/`
mirrors where the files end up. `install.sh` walks that with a hand-rolled
`link_path()` which backs up anything real it finds as `<name>.bak`, then
symlinks.

| In the repo | Symlinked to | Notes |
| :--- | :--- | :--- |
| `fastfetch/.config/fastfetch` | `~/.config/fastfetch` | whole directory |
| `fish/.config/fish` | `~/.config/fish` | whole directory |
| `cava/.config/cava` | `~/.config/cava` | whole directory |
| `gtk-3.0/`, `gtk-4.0/` | `~/.config/gtk-{3,4}.0` | whole directory |
| `quickshell/` | `~/.config/quickshell` | **the repo dir *is* the config dir** |
| `kitty/.config/kitty/kitty.conf` | `~/.config/kitty/kitty.conf` | per-file |
| `kitty/.config/kitty/colors.conf` | `~/.config/kitty/colors.conf` | per-file, generated |
| `hypr/.config/hypr/*.lua`, `*.conf` | `~/.config/hypr/…` | eight files, individually |
| `scripts/.local/bin/*` | `~/.local/bin/…` | three scripts |

Two of these are worth understanding rather than memorising:

**kitty needs both files symlinked separately.** `kitty.conf` says
`include colors.conf`, and kitty resolves that relative to `kitty.conf`'s own
path — not the real directory the symlink points into. So linking only
`kitty.conf` would make the include miss.

**Quickshell's link is the odd one out.** `~/.config/quickshell` points at the
repo's `quickshell/` directory itself, with no nested `.config/quickshell/`
inside it. That is why `qs` finds `shell.qml` and why editing the repo edits
the live shell.

### What is generated, not written

Eight files are matugen output, all gitignored, all living inside the repo
where the symlinks already point:

```
quickshell/generated/colors.json      hypr/.config/hypr/colors.lua
kitty/.config/kitty/colors.conf       hypr/.config/hypr/hyprlock-colors.conf
cava/.config/cava/config              fastfetch/.config/fastfetch/config.jsonc
gtk-3.0/.config/gtk-3.0/gtk.css       gtk-4.0/.config/gtk-4.0/gtk.css
```

A fresh clone has none of them. Symlinks to them dangle harmlessly until you
pick a wallpaper for the first time — every consumer treats a missing colour
file as "use the built-in fallback".

### What is state, not config

`~/.local/state/quickshell/` — deliberately *outside* the repo, because
`~/.config/quickshell` is a symlink into your checkout and writing there would
litter the working tree.

```
bar.json            bar geometry + which widgets are shown
launcher.json       app usage counts, for ranking
notifications.json  history, do-not-disturb, muted apps
theme.json          light or dark   (the matugen hook reads this one too)
nightlight.json     on/off and colour temperatures
```

Each is created the first time something needs to write it, so a fresh install
has none of them and the directory may hold only a subset at any time.

---

## 3. What starts what

`hypr/.config/hypr/autostart.lua` runs on `hyprland.start`:

```
quickshell                                 the shell
awww-daemon                                wallpaper backend
hypridle                                   idle → lock → dpms → suspend
wl-paste --type text  --watch cliphist store
wl-paste --type image --watch cliphist store
```

That is the whole session. Note what is *absent*: no notification daemon (the
shell is one), no polkit agent (likewise), no bar, no launcher, no idle
inhibitor.

`hyprland.lua` is the entry point and `require`s `monitors`, `autostart` and
`keybinds`, then loads matugen's `colors.lua` through a `pcall` with a
hardcoded fallback — so a fresh clone boots before any colours exist.

> Hyprland here is configured in **Lua**, not `.conf`. This matters more than
> it sounds: `hyprctl dispatch` evaluates its argument as Lua, so the classic
> `hyprctl dispatch workspace 3` is a *syntax error* that silently does
> nothing. It has to be `hyprctl dispatch 'hl.dsp.focus({ workspace = 3 })'`.
> `services/Compositor.qml` exists to keep that awkwardness in one place.

---

## 4. Quickshell's model

### The entry point

`quickshell/shell.qml` is a flat `Scope` that instantiates each root component
exactly once:

```qml
Scope {
    Bar {}
    Launcher {}
    NotificationPopups {}
    ...
}
```

Adding a panel means adding a line here and an import above it. Forget it and
the file exists but nothing ever creates it.

### Directory imports and singletons

```qml
import "../../config"     // Appearance, Colors
import "../../services"   // every service singleton
import "../common"        // the shared primitives
```

Quickshell scans those directories and registers anything with
`pragma Singleton` as a singleton, and anything without as a component type.
There is **no `qmldir`**, deliberately — see `shell-rebuild.md` §4 for why
adding one is a trap.

Two consequences worth internalising:

1. **A new file in `services/` is usable immediately**, with no registration
   step. Drop it in, import the directory, use it by filename.
2. **Singletons are created lazily**, on first access. A service's
   `Component.onCompleted` does not run at shell startup — it runs the first
   time something reads it. This is invisible in production (something always
   reads them) but bites constantly when writing test harnesses.

### The three layers

```
config/     Appearance, Colors            design tokens. No behaviour.
services/   19 singletons + Persist       state and the outside world.
modules/    19 directories                windows and widgets. UI only.
```

The dependency direction is strictly downward: modules read services read
config. A service never imports a module.

---

## 5. How a panel becomes pixels

Every window in the shell is a **wlr-layer-shell surface** — not a normal
window. Layer surfaces are anchored to screen edges, can reserve space, and sit
in a fixed stacking layer above or below normal windows.

The three properties that matter:

```qml
WlrLayershell.layer: WlrLayer.Overlay   // above fullscreen windows
WlrLayershell.namespace: "quickshell-popup"
exclusionMode: ExclusionMode.Ignore     // reserve no space
```

**`namespace` is how Hyprland identifies the surface.** It is the hook for
every layer rule in `hyprland.lua`:

| Namespace | Used by | Rules |
| :--- | :--- | :--- |
| `quickshell` | the bar, and toasts | slide animation, blur |
| `quickshell-popup` | every popup, the OSD | fade animation, blur |
| `quickshell-dock` | the dock + its trigger strip | no animation, blur |

The bar sets no namespace at all and gets Quickshell's default, which is
`quickshell` — that is why the `^quickshell$` rule catches it.

Each blur rule carries `ignore_alpha = 0.1`. That is not optional: every popup
is a *screen-sized transparent surface* with a small card drawn somewhere
inside it, so without a threshold the compositor would blur the entire desktop
the moment anything opened.

**Only the bar reserves space.** `exclusiveZone: BarConfig.barHeight` is what
pushes your windows down by 33px. Everything else sets
`ExclusionMode.Ignore` and floats over the desktop.

### The ShellPanel contract

Most popups are a `ShellPanel` rather than a raw `PanelWindow`. It supplies the
layer setup, a backdrop dismiss area, Escape, focus handling, a focus grab, and
follow-the-focused-monitor placement.

```qml
ShellPanel {
    name: "network"        // the UiState key; drives `open`, and close()
    takesFocus: true       // takes the keyboard while up (default)
    followFocus: true      // opens on the focused monitor (default)

    // signals: dismissed(), escapePressed()
    // slot:    close()

    PopupCard { ... }      // content goes here; it is the default property
}
```

Leave `name` empty and drive `open` yourself — that is what the polkit dialog
and the capture preview do, since neither is a panel the user toggles.

**Not everything is migrated yet.** These are still raw `PanelWindow`:
`battery`, `calendar`, `media` (all `focusable: false`, so pointer-only by
design), `settings` (has its own Escape), plus `osd` and `notifications`, which
are deliberately standalone because they are not panels at all.

---

## 6. The service layer

Where each service's truth actually comes from:

| Service | Backend | What it gives you |
| :--- | :--- | :--- |
| `Audio` | PipeWire | sinks, sources, streams, volume, mute |
| `Network` | NetworkManager (D-Bus) | wifi list, connect, PSK, ethernet |
| `Bluetooth` | BlueZ (D-Bus) | adapter, devices, pair, discovery |
| `Battery`, `PowerProfile` | UPower (D-Bus) | charge, state, power profile |
| `Notifications` | `o.f.Notifications` | the shell **is** the daemon |
| `Apps` | `DesktopEntries` | the app index + scoring |
| `Compositor`, `FocusedScreen` | Hyprland IPC | dispatch, focused monitor |
| `Cava`, `Clipboard`, `Capture`, `NightLight`, `IdleInhibit`, `Theme`, `Weather` | spawned processes | cava, cliphist, grim, wlsunset, the keep-awake helper, matugen, curl |
| `BarConfig`, `Persist` | `FileView` on disk | settings and state |
| `UiState` | nothing | pure in-memory state bus |

The split is the point: **anything with a D-Bus interface is read as
properties that announce themselves**, so nothing polls. Only the things with
no such interface get a `Process`.

### Persist

The generic store. Give it a filename and defaults; read through `value()` so
a key the file predates falls back rather than coming back undefined.

```qml
Persist {
    id: store
    fileName: "nightlight.json"
    defaults: ({ enabled: false, nightTemp: 4000 })
    onLoaded: root.enabled = store.value("enabled")
}
// store.set(k, v) · store.patch({…}) · store.flush() · store.reset()
```

Writes are debounced 300 ms. `flush()` bypasses that, for when something
*outside* the shell is about to read the file — which is exactly the case for
`theme.json` and the matugen hook.

---

## 7. The theming pipeline

One wallpaper change re-colours the entire desktop. The chain:

```
 pick a wallpaper (SUPER+W)
        │
        ▼
 ~/.local/share/qs-wallpaper-picker/scripts/dotfiless_matugen.sh
        │
        ├─ normalise to PNG            (magick, ffmpeg fallback — matugen's
        │                               decoder panics on AVIF)
        ├─ measure colourfulness       (<1% ⇒ scheme-monochrome, or Material
        │                               You falls back to a stock blue)
        ├─ read theme.json             (light or dark)
        │
        ▼
    matugen -m <mode>  ──▶  8 templates  ──▶  8 generated files
        │
        ├─ qs ipc call theme reloadColors   shell re-reads colors.json
        ├─ hyprctl reload                   border colours
        └─ killall -SIGUSR1 kitty           open terminals re-read their palette
```

`config/Colors.qml` holds a `FileView` on `generated/colors.json` with
`watchChanges: true`, so the shell picks up a new palette without the IPC call
too — the IPC just makes it immediate.

Ten colour roles come out of it: `background`, `surfaceContainer`,
`surfaceContainerHigh`, `textPrimary`, `textSecondary`, `outline`, `primary`,
`primaryText`, `error`, `errorText`. Every one has a hardcoded fallback so the
shell renders before matugen has ever run.

> **The copy trap.** That hook script is *copied* into the picker's clone at
> install time, not symlinked. It therefore drifts. If theming misbehaves,
> compare it against `wallpaper-picker/dotfiless_matugen.sh` before anything
> else, and check `/tmp/dotfiless-matugen.log`.

---

## 8. What happens when you press a key

Take `SUPER+V`:

```
 SUPER+V
   └─ Hyprland matches a bind in keybinds.lua
        └─ hl.dsp.exec_cmd("qs ipc call clipboard toggle")
             └─ `qs` connects to the running instance's socket
                  └─ IpcHandler { target: "clipboard" } → UiState.toggle("clipboard")
                       └─ UiState closes every other exclusive panel,
                          sets clipboardOpen = true
                            └─ ShellPanel's `open` flips
                                 ├─ latches the focused screen
                                 ├─ maps the layer surface
                                 └─ takes keyboard focus
                                      └─ Clipboard.refresh() spawns `cliphist list`
```

Every panel declares its own `IpcHandler` beside the window it controls; there
is no central registry. `qs ipc show` lists all 17 targets live.

Most take `toggle`/`open`/`close`. Two do not:

```bash
qs ipc call osd volume|brightness|mic
qs ipc call capture region|window|output|screen|copy|save|annotate|close|record
qs ipc call theme reloadColors
```

The practical value: **every panel is reachable even if you hide its bar
widget**, and anything here can be scripted.

---

## 9. Focus, and why it is fiddly

Three separate mechanisms, often confused:

1. **`WlrLayershell.keyboardFocus`** — whether the surface receives key events
   at all. `Exclusive` while open, `None` otherwise. Panels that should not
   steal typing (the OSD, toasts) set `focusable: false` and never take it.
2. **Qt's focus chain** — *within* the surface. `ShellPanel` wraps content in a
   `FocusScope`, so Tab walks the controls of the open panel and stops there.
   `PressFx` sets `activeFocusOnTab`, which is why every control built on it
   became tabbable at once.
3. **`HyprlandFocusGrab`** — dismissal. It grabs pointer *and* keyboard and
   emits `cleared` when the user clicks elsewhere, which is how a popup closes
   when you click another application.

And the exclusivity model on top: `UiState.show(name)` closes every other
exclusive panel first. The dock is excluded from that list on purpose — it is
pinned, not opened.

---

## 10. Multi-monitor

Two different strategies, for two different needs:

**Per-screen instances** — the bar and the dock wrap themselves in
`Variants { model: Quickshell.screens }`, producing one window per monitor.
Each dock filters its contents by `HyprlandToplevel.monitor`, so it lists only
its own screen's windows.

**Follow-the-focus** — every popup, toast and the OSD are single windows whose
`screen` is set from `FocusedScreen`. Panels latch it once when they open;
toasts and the OSD bind it live, because they never take focus and so cannot
disturb what "focused" means.

`FocusedScreen` maps Hyprland's `HyprlandMonitor` onto the `ShellScreen` a
`PanelWindow` wants, by name. It returns null for about a second after startup,
which is safe: null means "let the compositor place it", which is what every
window did before this existed.

---

## 11. Recipes

### Add a bar widget

1. `modules/bar/MyWidget.qml` — an `Item` with `implicitWidth`/`implicitHeight`
   and a `PressFx` for interaction.
2. Add it to the right `RowLayout` in `Bar.qml` (left / centre / right).
3. Give it a visibility flag: a `showMyWidget` property in `BarConfig` plus its
   four mentions (declaration, `defaults`, `applyObject`, `serialize`), and one
   entry in `SettingsWindow`'s `widgets` array.

### Add a panel

1. `modules/mypanel/MyPanel.qml` with `ShellPanel { name: "myPanel" … }`.
2. Add `myPanelOpen` to `UiState` and `"myPanel"` to its `exclusive` array.
3. Declare an `IpcHandler` inside the panel routing to
   `UiState.toggle/show/hide`.
4. Add the import and the instance to `shell.qml`.
5. Optionally a keybind in `keybinds.lua`.

A new *namespace* also needs blur and animation rules in `hyprland.lua` — but
`ShellPanel` already uses `quickshell-popup`, which has them.

### Add a service

Drop the file in `services/` with `pragma Singleton`. Nothing else. Use D-Bus
if the thing has an interface; a `Process` only if it does not. If it needs to
remember something, embed a `Persist`.

### Add a persisted setting

Either add it to `BarConfig` (four places, as above) or give your service its
own `Persist` with its own file. Prefer the latter unless it genuinely belongs
to the bar.

---

## 12. When something breaks

```bash
qs-log                  # tail the running shell's log — start here, always
qs-lint                 # qmllint over quickshell/, noise filtered
qs ipc show             # every target the running shell exposes
hyprctl layers          # which surfaces exist, and on which monitor
hyprctl clients         # windows, and which monitor each is on
hyprctl binds           # confirm a keybind actually registered
tail /tmp/dotfiless-matugen.log      # theming
```

Reload the shell with `pkill -x quickshell` then `setsid -f quickshell`.
Reload Hyprland's config with `hyprctl reload` (binds and rules; it does not
restart the shell).

**Testing a change without disturbing your session:** put a scratch `.qml` in
`quickshell/` and run `qs -p ./scratch.qml`. It gets the real services and real
singletons; if it instantiates nothing visual, nothing appears on screen. Two
traps — singletons are lazy, so warm them in `Component.onCompleted` and read
them on a timer; and relative imports only resolve from inside the config
directory, so the file has to live in `quickshell/`.

**Testing multi-monitor without a second monitor:**

```bash
hyprctl output create headless      # a virtual display appears
hyprctl output remove HEADLESS-1    # and is gone
```
