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
bar.json            bar geometry, widget visibility, animation and corner scale
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
services/   22 singletons + 2 components  state and the outside world.
modules/    21 directories                windows and widgets. UI only.
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

**Every panel is a `ShellPanel`.** The only two windows that are not are
`osd` and `notifications`, and deliberately so — they are indicators rather
than panels: they take no keyboard, cannot be dismissed, and follow the
focused monitor by a live binding instead of latching, because neither can
disturb what "focused" means.

### The shared primitives

`modules/common/` holds everything a panel is assembled from. Reach for these
before writing a new one:

| | |
| :--- | :--- |
| `ShellPanel` | the window itself (above) |
| `PopupCard` | the floating surface: rounded, translucent, shadowed |
| `PressFx` | the whole gesture vocabulary — hover, press, click ripple, keyboard activation, focus ring |
| `Anim`, `PopAnim`, `PopIn` | the motion presets everything animates on |
| `Toggle`, `Slider`, `SegmentedControl`, `TextField` | controls |
| `ToggleRow` | a labelled toggle with optional expandable content |
| `Select` | a collapsible picker for a list that would be clunky inline |
| `TextField` | themed input, with a password mode |
| `FillButton` | hold-to-activate, with optional two-stage confirm |

`PressFx` is the one to understand: binding a sibling `Rectangle`'s `scale` to
`fx.gestureScale` and its overlay's `opacity` to `fx.flashOpacity` gets you the
shell's entire interaction feel, and because it sets `activeFocusOnTab` every
control built on it is keyboard-reachable for free.

> Animate a target's `scale` with a `Behavior`, never a `PropertyAnimation` —
> the latter tears down `gestureScale`'s binding permanently the first time it
> runs. The comment in `PressFx.qml` says so, and three separate places in the
> codebase cite the same class of bug.

---

## 6. The service layer

Where each service's truth actually comes from:

| Service | Backend | What it gives you |
| :--- | :--- | :--- |
| `Audio` | PipeWire | sinks, sources, streams, volume, mute |
| `Network` | NetworkManager (D-Bus) | wifi list, connect, PSK, ethernet |
| `Bluetooth` | BlueZ (D-Bus) | adapter, devices, pair, discovery |
| `Battery`, `PowerProfile` | UPower (D-Bus) | charge, state, power profile |
| `Notifications` | `o.f.Notifications` | the shell **is** the daemon; history, grouping, mute |
| `Media` | MPRIS | which player the bar and popup agree on |
| `Apps`, `Search`, `Calculator` | `DesktopEntries` + JS | the launcher's index, modes and arithmetic |
| `Resources` | `/proc`, `/sys` | CPU, memory, temperature, disk, network |
| `Compositor`, `FocusedScreen` | Hyprland IPC | dispatch, focused monitor |
| `Cava`, `Clipboard`, `Capture`, `NightLight`, `IdleInhibit`, `Theme`, `Weather` | spawned processes | cava, cliphist, grim, wlsunset, the keep-awake helper, matugen, curl |
| `BarConfig`, `Persist` | `FileView` on disk | settings and state |
| `UiState` | nothing | pure in-memory state bus |
| `StateToasts` | observes the above | announces changes nobody was told about |

The split is the point: **anything with a D-Bus interface is read as
properties that announce themselves**, so nothing polls. Only the things with
no such interface get a `Process`.

`Resources` is the third case: `/proc` and `/sys` are neither. It uses
`FileView` and reloads on a timer, because a `FileView` reload is a read rather
than a fork — which is what makes sampling every two seconds cheap enough to
leave on permanently.

Two of the files here are **not** singletons. `Persist` is a component because
each store is a separate file, and `StateToasts` is one because it has no
public API — and a singleton that nothing references is never created, so it
would simply never run. `shell.qml` instantiates it.

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
is no central registry. `qs ipc show` lists all 19 targets live.

Most take `toggle`/`open`/`close`. Four do not:

```bash
qs ipc call osd volume|brightness|mic
qs ipc call capture region|window|output|screen|copy|save|annotate|close|record
qs ipc call lock lock|isLocked          # see §9 before using this
qs ipc call theme reloadColors
```

The practical value: **every panel is reachable even if you hide its bar
widget**, and anything here can be scripted.

---

## 9. The lock screen, and why it is not bound to anything

`modules/lock/Lock.qml` is an **ext-session-lock** client: a Wayland protocol
where the compositor shows *only* the lock client's surfaces and routes all
input to them.

Understand the failure mode before touching it. **If the lock client dies
without unlocking, the session stays locked.** That is the protocol's security
guarantee working as designed — the alternative would be that killing a process
unlocks your machine. The way back in is a TTY (`Ctrl+Alt+F2`), not the
desktop.

Which is why it is deliberately **not on a keybind**. `SUPER+Escape` still runs
`loginctl lock-session`, which hypridle answers with hyprlock; hyprlock is still
installed. Locking with the shell's own screen is an explicit
`qs ipc call lock lock` until it has been proven on your machine.

Authentication is PAM via `Services.Pam`, borrowing `/etc/pam.d/hyprlock`
(which is just `auth include login`), so it needs no new file under `/etc`.
The conversation is PAM's to drive:

```
start()  →  pamMessage "Password: " (responseRequired, echo off)
         →  respond(text)
         →  completed(Success | Failed | Error | MaxTries)
```

One detail that is not obvious: **a failed attempt ends the PAM transaction.**
A second `respond()` into the same context goes nowhere and the screen appears
to hang, so `start()` is called again on failure.

This can be tested without ever locking anything — a standalone `PamContext` in
a scratch file will start a session, relay the password prompt and return
`Failed` for a wrong answer. That verifies everything except the surface
itself.

---

## 10. System monitoring

`services/Resources.qml` samples `/proc/stat`, `/proc/meminfo`,
`/proc/net/dev`, a hwmon temperature and `df`, and `modules/dashboard/`
presents them on `SUPER+SHIFT+D`.

Three decisions worth keeping:

- **`FileView`, not a `Process`.** `/proc` reads are cheap; forking every two
  seconds is not. Only the disk uses a process, once a minute, because `df`
  forks and a root filesystem does not move that fast.
- **`MemTotal - MemAvailable`, never `MemFree`.** Free excludes the cache the
  kernel hands back on demand, and reports a machine with plenty of room as
  nearly full.
- **The temperature sensor is found by name, not by index.** `hwmonN`
  numbering is assigned in probe order and moves between boots, so
  `/sys/class/hwmon/hwmon5` being `coretemp` today means nothing tomorrow. A
  one-shot scan at startup looks for `coretemp`, `k10temp` or `zenpower`.

---

## 11. What the launcher searches

`Search` composes four kinds of result, each tagged with `kind` so the delegate
can render it differently:

| kind | Trigger | Enter does |
| :--- | :--- | :--- |
| `calc` | the query looks like a sum | copies the result |
| `command` | the query starts with `>` | runs it through a shell |
| `action` | matches a name or keyword | opens a panel, or runs a command |
| `app` | anything else | launches it, and records the use |

The calculator is a tokeniser and recursive-descent parser in
`services/Calculator.qml`, **not** `eval`. `eval` would execute anything typed
into the launcher, and it also happily accepts JavaScript that is not
arithmetic — `[]+{}`, assignments, property access — returning nonsense instead
of declining. The parser rejects all of it.

`qalc` is preferred when installed, because it does units and currency;
the built-in parser is the fallback so arithmetic works with no extra package.

---

## 12. Focus, and why it is fiddly

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

## 13. Multi-monitor

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

## 14. Recipes

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

## 15. House style, and why qmlformat is not used

Two conventions run through every QML file here, and both are deliberate:

```qml
Behavior on color { ColorAnimation { duration: Appearance.animFast } }   // one line
root.checked = !root.checked                                            // no semicolons
```

`qmlformat` is installed at `/usr/lib/qt6/bin/qmlformat` and **is not used on
this repository.** It has no option to preserve either convention, and running
it was measured rather than guessed:

| | |
| :--- | :--- |
| Files it would rewrite | **80 of 84** |
| Line growth | **+1,775 lines, 15%** |
| What changes | 182 one-line `Behavior` blocks exploded to five lines each, and a semicolon added to every JS statement |
| What improves | nothing — the output is semantically identical |

A `Behavior on scale { Anim { duration: Appearance.animFast } }` reads as a
single thought: *this scales quickly*. The five-line form says the same thing
while burying it, and doing that 182 times pushes the actual logic further
apart everywhere. It would also rewrite `git blame` for almost the whole shell
in one commit.

So the style is maintained by hand. If you ever do run qmlformat, you will get
an 80-file diff — that is expected, and the answer is `git checkout`, not
review.

(`qmlformat --output-options` lists what it can be told to do. `SemicolonRule:
essential` would fix the semicolons; nothing fixes the one-liners, which is the
larger half.)

`qs-lint` is the tool that *is* used, and it checks correctness rather than
layout.

---

## 16. When something breaks

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
