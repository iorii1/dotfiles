# Rebuilding the shell: what changed, and what it taught

This is a record of a single large pass over the Quickshell config in
`quickshell/` — what was wrong, what was built, and the things that were only
learned by running them. It is written to be read by someone who wants to
understand *why* the code looks the way it does, not as a changelog.

The shell went from **5,943 lines of QML across 54 files** to **11,107 across
84**, and from **14 IPC targets to 19**.

---

## 1. The starting point

The config was already good. `config/Appearance.qml` was a real design-token
system — every duration derived from one `animScale`, Material 3 easing curves
as bezier control points, two tiers of hover/press scale. Services were
DBus-backed rather than polling. `modules/common/` held ten well-factored
primitives. There were zero `TODO` or `FIXME` markers anywhere.

So the problem was never polish. It was **capability holes**: places where the
shell either handed you off to a terminal, swallowed your keyboard, or shelled
out to a CLI on every keypress.

The audit found these, in rough order of how much daily friction they caused:

| Gap | Evidence |
| :--- | :--- |
| Four panels grabbed the keyboard and dropped it | `WlrKeyboardFocus.Exclusive` in six panels, `Keys.onEscapePressed` in only two |
| No audio service at all | Nothing imported `Quickshell.Services.Pipewire`; the OSD scraped `wpctl` stdout |
| Wi-Fi could not join a new secured network | `Network.qml` literally said *"connect once with nmcli or nmtui"* |
| Bluetooth could not pair | The device list filtered to `paired` only; `adapter.discovering` was never set |
| Notification history died on reload | A plain in-memory `ListModel` |
| 13 of 15 windows ignored which monitor you were on | No `screen:` set anywhere but the bar and dock |
| Auth prompts were unthemed GTK | `autostart.lua` launched `xfce-polkit` |
| The launcher was a substring filter | `name.includes(q)`, sorted alphabetically, *staying* alphabetical as you typed |

Two smaller ones worth naming because they show the shape of the codebase:
`Clipboard.clearAll()` existed with no call site anywhere, and `ToggleRow` had
a complete expandable-content mechanism that **all three** of its call sites
disabled. Both were built for things that were never finished.

---

## 2. The foundation everything else needed

Before any feature work, four pieces went in. They exist because otherwise
every later change would have re-solved the same problem.

### `modules/common/ShellPanel.qml`

Every popup re-declared the same twelve lines: overlay layer, popup namespace,
ignored exclusion zone, full-screen anchors, a backdrop `MouseArea` to dismiss,
an inner one to swallow clicks. That much was harmless duplication.

What was *not* harmless: six panels also copied
`WlrLayershell.keyboardFocus: Exclusive` while only two ever wrote the
`Keys.onEscapePressed` to go with it. The other four took the keyboard from the
compositor and then dropped every key on the floor.

Folding the window into one component means a panel now gets dismissal, Escape
and focus **by existing**, and can only lose them deliberately.

### `services/Persist.qml`

`BarConfig` already did persistence carefully — a `FileView` under
`~/.local/state/quickshell/`, a 300 ms debounce so a burst of changes is one
write, a `_loaded` guard so the load→apply→save loop does not write the file
straight back over itself on startup, and a graceful "no file yet" path.

That pattern was lifted out with the bar-specific schema removed, so
notifications, the launcher's ranking, the theme mode and night light could all
persist without re-implementing the guard. Four state files now exist where
there was one.

### `modules/common/TextField.qml`

Four later features needed a text input — Wi-Fi passwords, the polkit prompt,
notification replies, clipboard search — and the launcher had hand-rolled a
bare `TextInput`.

### Panel exclusivity in `UiState`

`UiState` was eleven independent booleans, so the network, Bluetooth, battery
and notification popups — which all anchor to the same top-right corner at the
same `restY` — could be open on top of each other. `show()` / `hide()` /
`toggle()` now keep one panel up at a time. The dock is deliberately excluded:
it is *pinned*, not opened, so it should stay put while panels come and go.

---

## 3. What got built

Briefly, since the README covers the user-facing side:

- **Keyboard everywhere.** The four trapped panels moved onto `ShellPanel` and
  each got real navigation. The primitives (`Slider`, `Toggle`,
  `SegmentedControl`, `FillButton`, `ToggleRow`, `PressFx`) gained
  `activeFocusOnTab`, key handlers and a focus ring. `FillButton` needed a
  keyboard equivalent for its hold-to-fill gesture, or the power menu would
  have stayed pointer-only.
- **A real launcher.** Subsequence scoring with word-boundary and contiguity
  bonuses, across name / generic name / keywords / comment / categories, plus
  frecency persisted to `launcher.json` and `.desktop` actions as sub-results.
- **`services/Audio.qml`** on PipeWire: bar widget, device switching, per-app
  mixer, mic indicator, and an OSD that subscribes instead of being poked.
- **Wi-Fi passwords, Bluetooth pairing, notification persistence**, per-app
  mute, inline replies, history actions, clipboard search and delete.
- **Follow-focus placement** for every popup, toast and OSD, and per-screen
  dock contents.
- **An in-shell polkit agent**, replacing `xfce-polkit`.
- **Capture and recording** with a preview offering Copy / Save / Annotate /
  Discard.
- **A quick settings panel**, finally using `ToggleRow`'s expandable mechanism.

Then a second pass, measured against what caelestia ships:

- **System monitoring**, which did not exist in any form: `Resources` reading
  `/proc` and `/sys`, and a dashboard on `SUPER+SHIFT+D`.
- **Launcher modes** — arithmetic, `>` to run a command, and the shell's own
  verbs, so "cpu" reaches the system monitor and "shut" reaches shutdown.
- **A window title** in the bar, which had twelve modules and no way to say
  what had focus.
- **Notification grouping**, collapsing a run from one app into the newest with
  a count.
- **Toasts for state the shell knew and never mentioned** — charger, battery
  thresholds, do-not-disturb, audio device changes, night light, keep-awake.
- **A media player switcher**, replacing the same "first playing player" loop
  duplicated in two files.
- **A lock screen** on ext-session-lock and PAM, deliberately not bound to
  anything yet.
- **The first window rules** in the repo, and XWayland scaling, which was
  leaving XWayland clients soft at scale 1.25.

---

## 4. The things that were only learned by running them

This is the part worth keeping.

### The type information lied about `keywords`

`DesktopEntry.keywords` and `.categories` are advertised as `QString` in
Quickshell's `.qmltypes`. They come back as string **lists**. Calling
`.toLowerCase()` on them threw for every app that had keywords, which would
have silently emptied the launcher.

Nothing static caught this. It appeared the first time the scorer ran against
real `.desktop` files. Hence `Apps._text()`, which handles both.

### Binding `screen` to the focused monitor feeds back on itself

The obvious implementation of "open on the monitor you are looking at" is:

```qml
screen: FocusedScreen.screen
```

It is wrong, and wrong in an interesting way. A panel takes keyboard focus when
it opens. Hyprland answers that by re-deriving the focused monitor from where
the **pointer** is. So the panel opens on the right monitor, grabbing focus
moves "focused" to the monitor under the cursor, and the panel slides over to
join it — within a frame.

The fix is to latch the screen once. But latching in `onOpenChanged` was *also*
not enough, because `visible: open` meant both changed in the same turn and the
new screen arrived after the surface had already mapped — so it only took
effect on the *next* open. `ShellPanel` now maps off an internal `_mapped` flag
written immediately after the latch in the same handler, which guarantees the
order.

### A focus grab with no input behind it gets cleared instantly

`HyprlandFocusGrab` is the right way to dismiss a popup when the user clicks
another window. But a grab requested with no input event behind it — which is
exactly what happens for a panel that appears *on its own*, like a capture
preview or an auth prompt — is declined by the compositor, and `cleared` fires
immediately.

Treating that as "the user clicked away" closed those panels the moment they
opened. `ShellPanel` now ignores a clear that arrives within the entrance
animation.

### Sizing a card from its content's *painted* size is a loop

The capture preview sized its card from `preview.paintedWidth`, while the image
inside was constrained by the card's width. Painted size depends on layout,
layout depends on the card width, and a card whose width never resolves **never
maps** — so the preview sometimes did not appear at all.

Sizing from the image's `implicitWidth` (its natural, source-derived size)
breaks the cycle.

### A derived `onXChanged` does *not* replace the base's

This one was checked rather than assumed, because if it had gone the other way
every panel built on `ShellPanel` would have been broken. Given a base `.qml`
with `onFlagChanged` and a derived instance that also declares
`onFlagChanged` — **both run**. The base handler survives.

Worth knowing, because the opposite is true of ordinary property *bindings*,
which a derived declaration does replace.

### Two ways a Column silently measures zero

Both found building `Select`, the collapsible device picker, and both only
visible by printing the numbers — the UI simply did not grow, with no warning
of any kind.

**Visibility propagates.** `Item.visible` is effective visibility: a child of an
invisible parent reports `visible == false` itself. So a `Column` with
`visible: false` has, as far as it is concerned, no visible children, and
measures 0. That much is reasonable. What is not is that it does not reliably
recompute when shown again — it stayed 0 high with its three rows already
inside it, correctly parented and 28px each.

The fix is to never hide the Column. Keep it visible inside a wrapper with
`clip: true` whose *height* animates to zero instead, which also slides rather
than pops.

**A positioner does not re-measure a child that changes height.** `Column`
counts a child's height when that child is created, and its own
`implicitHeight` then stops tracking it. With the list open the wrapper was
correctly 86 high and the Column still reported 30:

```
SMOKE listOpen = true | wrapper.h = 86 | list.implicitH = 86 | sel.implicitH = 30
```

Deriving the height explicitly is exact, and gives one place to animate:

```qml
implicitHeight: root.headerHeight
    + (root.listOpen ? column.spacing + list.implicitHeight : 0)
```

The general lesson is the debugging shape, not the two quirks: when a layout is
wrong, walk the tree and print `height`, `implicitHeight`, `visible` and
`children.length` at each level. The answer was two levels down both times, and
no amount of re-reading the QML would have produced it.

### A singleton nothing references is never created

`StateToasts` observes half the services and announces what changed. It has no
public API, because nothing needs to ask it anything — and that is exactly why
it did not work as a singleton. QML creates a singleton the first time
something reads a property off it, and nothing ever read one.

The instinct is to force it: `Component.onCompleted: StateToasts.armed` in
`shell.qml`. That took the entire shell down —

```
ERROR: Failed to load configuration
  caused by @shell.qml[27:5]: Non-existent attached object
```

— because Quickshell's `Scope` does not support the `Component` attached
property. The right answer was not a workaround but a correction: something
with no public API that exists only to observe is a **component**, not a
singleton, and `shell.qml` instantiates it like any other object.

The same reasoning applies to `Persist`, for a different reason: each store is
a separate file, so there is nothing singular to be.

### An observer that arms late misses the value it is comparing against

The state toasts must not fire on login — otherwise every one of them
announces, once, that the state has "changed" to what it already was. So they
arm on a delay, and the `Connections` carry `enabled: root.armed`.

That is correct and it introduced a second bug. A disabled `Connections`
receives nothing, so the signal that fires as the services first settle never
arrives, and `_lastSink` stayed empty. The first *real* device change then
looked like the initial one and was swallowed:

```qml
const had = root._lastSink !== ""   // false, because we were asleep for it
root._lastSink = name
if (had) notify(...)                // so the first change says nothing
```

Measured exactly that way: switching output device produced nothing at all,
and exactly one toast once the previous values were seeded at the moment of
arming rather than inferred from a signal that had already passed.

### eval is not a calculator

The launcher needed arithmetic. `eval(query)` is one line and wrong twice over:
it will execute anything typed into a launcher, and it *accepts* input that is
not arithmetic at all — `[]+{}` is `"[object Object]"`, an assignment returns
its value, a property access returns whatever is there — so it answers
confidently instead of declining.

A tokeniser and a recursive-descent parser is perhaps eighty lines and rejects
all of it. Checked against 23 cases including `[]+{}`, `alert(1)` and `1;2`,
all of which correctly produce nothing.

Worth noting where the line is: `evaluate("5")` returns `5`, because 5 *is* an
expression. Whether to offer that as a calculator result is a separate
question, and `looksLikeMath()` answers it — a bare number is not a sum
somebody wants the answer to.

### Hardware can make a feature impossible, not just unconfigured

Hibernate looked like a one-line addition to the power menu. This machine's
only swap is zram: four gigabytes of *compressed RAM*. Hibernation writes RAM
to swap and then cuts power — hibernating into RAM cannot survive that, and
`systemctl hibernate` fails every time.

A button that always fails is worse than no button, so it is shown only when
`swapon` reports backing store that is not zram, and the keyboard focus chain
skips it when hidden.

The general shape: before adding a control for something the system
*advertises* — `/sys/power/state` does list `disk` here — check whether it can
actually work on this machine.

### Two layer surfaces must not share a pixel

The dock is two surfaces on purpose: a four-pixel trigger strip that is always
mapped, and the dock proper that appears when it is touched. The comment in the
file explains why it is not one surface whose input region changes — that had
already been tried, and swapping a region under the pointer makes the
compositor re-deliver enter and leave.

What it did not account for is that the two surfaces **overlapped**. The dock
reached all the way to the screen edge while the strip owned the bottom four
pixels, so that band belonged to both at once. With the pointer resting in it
the compositor handed focus back and forth between them as the dock committed
each frame of its entrance animation, and because every leave restarted the
hide timer, the dock faded out from under the pointer before an icon could be
clicked.

Making them adjacent — the strip owns the bottom four pixels, the dock owns
everything above, the dock shortened by exactly the strip's height so the card
lands in the same place — removes the contention entirely. There is no band
that two surfaces can argue over.

The general rule: two layer surfaces that both want the pointer must not share
any pixel. Overlap is not a small inefficiency, it is an ambiguity the
compositor resolves differently from frame to frame.

### Enter and leave are not enough to know where the pointer is

Even adjacent, the same dock produced leaves with the pointer standing
perfectly still. Hyprland re-evaluates pointer focus when surfaces map, unmap
and commit, and a dock that appears is doing all three — so a leave arrives,
and then no motion follows to prompt the matching enter, because the user has
simply stopped moving.

Anything that hides itself on leave therefore needs a second opinion. A leave
now only starts a countdown; when it expires the compositor is asked where the
pointer actually is, through `hyprctl cursorpos`, and the surface hides only if
it has really gone. That is one process per dismissal, not per frame, which is
cheap enough — and unlike an event stream, a coordinate cannot be stale in a
way that silently loses the pointer.

### A `qmldir` replaces directory scanning entirely

Adding `qmldir` files to `config/` and `services/` made qmllint resolve the
singletons properly and removed a whole category of noise. It worked.

It was still removed, because a `qmldir` *replaces* directory scanning rather
than supplementing it. Deleting one line from it was enough to take the entire
shell down with a cascade of `Type X unavailable` — which means the first
`.qml` file added without a matching entry would do the same. Not worth it for
two warnings.

### hypridle can be asked politely

"Keep awake" worked by `pkill -x hypridle`, respawning it later, and polling
`pgrep` every 20 seconds to find out which state it was really in. That kills
the user's idle daemon outright and races anything else that starts or stops
it.

hypridle owns `org.freedesktop.ScreenSaver` — the same reference-counted
interface video players use. Taking an inhibit there disturbs nothing else, and
dropping it does not wake the machine if something else still holds one.

The catch: the inhibit lives as long as the **D-Bus connection**, so a one-shot
`gdbus call` releases the instant it exits. It has to be a process that stays
running, which is what `scripts/.local/bin/qs-keep-awake` is.

### One source of truth, or two that disagree

`MediaWidget.qml` and `MediaPopup.qml` each contained the same loop — *the
first player in Playing state, else the first player at all* — copied between
them. That is not merely duplication: the two are separate bindings evaluated
independently, so the bar widget and the popup could genuinely disagree about
which player they were showing, and neither offered a way to choose.

Moving the decision into a `Media` singleton fixed the choosing and the
disagreement at once. It also surfaced a subtler hazard while rewiring them:

```qml
readonly property var player: Media.active      // an object, or null
readonly property bool active: Media.hasActive  // derived from the same thing

text: root.active ? root.player.trackTitle : ""  // reads null, sometimes
```

Both derive from `Media.active`, but they are separate bindings and QML may
re-evaluate them in different passes. Checking one while dereferencing the
other therefore reads `null` intermittently — which is exactly what happened,
as two `TypeError: Cannot read property 'trackTitle' of null` in the log.

Guard on the thing you are about to dereference, not on a sibling that happens
to describe it.

### Notification history and notification actions are in tension

Actions on a history entry can only work while the underlying `Notification`
object is alive. The original code released it on every toast dismissal, which
is why history rows had no actions — a UI omission that was really a lifetime
decision.

Resolving it meant splitting one verb into two: a toast that **times out**
keeps its notification alive so its actions still work from the notification
centre, while a toast the user **closes** tells the app they are done and lets
it go. You cannot have both behaviours under one `dismiss()`.

---

## 5. A fix that was committed but never took effect

Not a code change, but the most surprising find.

`wallpaper-picker/dotfiless_matugen.sh` is *copied* into the cloned picker at
install time rather than symlinked, and the installed copy on this machine
dated from 13 September. Commit `775bc13` — "Fix matugen producing a blue theme
from monochrome wallpapers" — landed on 18 September.

So the fix existed in the repository and had simply never run. On a greyscale
wallpaper matugen was still falling back to its built-in blue seed, which is
precisely the bug that commit was written to eliminate. Copying the current
script over produced the correct greyscale palette on the next run, and the log
said so: `monochrome wallpaper (0% colourful) -- using scheme-monochrome`.

The lesson is about the *copy*, not the script: anything installed by copying
instead of symlinking will drift, and will do it silently.

---

## 6. How any of this was verified

Almost every claim above was checked by running something, because the static
tools could not see most of it.

- **`scripts/.local/bin/qs-lint`** runs qmllint with this repo's structural
  noise filtered out — the suppressions are documented in the script, each one
  a case where qmllint is reporting how Quickshell works rather than a defect.
  CI runs the same script. It is clean across all 74 files.
- **Throwaway Quickshell instances.** `qs -p <file>` against a scratch `.qml`
  in the repo runs real singletons against real services without mapping any
  surfaces. This is how the PipeWire graph, the launcher scoring, the persist
  round-trip and the `onXChanged` semantics were all checked.
  Two traps: singletons are created **lazily**, so a probe that reads one at
  t=0 gets nothing — warm it in `Component.onCompleted` and read later; and
  relative imports only resolve from inside the config directory, so the scratch
  file has to live in `quickshell/`.
- **`hyprctl layers`** tells you which monitor a surface actually landed on,
  which is the only way to check follow-focus.
- **A headless output.** `hyprctl output create headless` gives you a second
  monitor without hardware; `hyprctl output remove HEADLESS-1` takes it away.
  Multi-monitor placement was verified 20/20 across four focus switches this
  way.
- **Real side effects.** Bluetooth discovery was confirmed with
  `bluetoothctl show | grep Discovering` flipping to `yes` when the popup
  opened. Per-app notification mute was confirmed by counting toast layers with
  one muted app and one control app. Keep-awake was confirmed with
  `systemd-inhibit --list`.

### Three ways this testing went wrong

Worth recording, because each one produced confident, wrong conclusions.

**Do not debug a visible feature by invoking it in a loop.** Driving the
capture preview a dozen times to chase a race flashes a full-screen preview
over whatever the user is doing. Measure the underlying command standalone
(`grim` took 350 ms, which ruled out timing immediately) before touching the
UI.

**Do not drive the pointer on a machine somebody is using.** The dock bug was
chased with `hl.dsp.cursor.move`, warping the cursor to the bottom edge and
sampling what happened. The results contradicted each other run to run — the
fix appeared to work, then not, then work again. The reason was in the log all
along: a check reported the cursor at `(2806, 661)` immediately after it had
been moved to `(2688, 862)`. The user's hand was on the mouse, and every warp
was racing a real pointer. An automated cursor is not an observer; it is a
second user.

**Assert that a patch applied.** Two rounds of that same investigation tested
code that had never changed, because a `str.replace()` silently does nothing
when its pattern does not match, and the file had been restored from a backup
in between. Every edit in a script deserves `assert old in s` — the failure is
loud and immediate, instead of a measurement of the wrong thing.

---

## 7. What is still open

Stated plainly, because a document like this is worth nothing if it only lists
wins.

- **The lock screen has never been locked.** Its authentication path is
  verified — PAM starts, asks for a password with echo off, and returns
  `Failed` for a wrong one — but the surface itself has not been shown, because
  testing it needs a real password typed at it. It is on no keybind for that
  reason, and hyprlock is still installed and still on `SUPER+Escape`. See
  `architecture.md` §9 for the failure mode before trying it.
- **Screen recording has never been run end to end** — start, stop, and a
  playable file. The region picker needs a human, so it was never driven to
  completion. If a recording will not play, the SIGINT handling in
  `Capture.stopRecording()` is where to look.
- **The polkit dialog has never been submitted with a real password.** It was
  confirmed to appear for a real `pkexec` and to dismiss cleanly when the
  request is withdrawn; the success path is untested.
- **The capture preview failed to map once in five runs** during debugging. Two
  real causes were found and fixed (the binding loop, the focus grab). It has
  been reliable since, but that is not proof the flake is gone — only that two
  mechanisms that could produce it are gone.
- **Hibernate cannot work on this machine** and is hidden accordingly; the
  button has therefore never been exercised anywhere.
- **Enterprise (802.1X) Wi-Fi** still needs `nmtui` once. A PSK field cannot
  serve a network that wants a certificate.
- **`Hyprland.focusedMonitor` takes about a second to populate** after startup,
  and `HyprlandMonitor.focused` never becomes true on any monitor in this
  build. `FocusedScreen` falls back to the focused workspace's monitor, and
  returning null is safe — it means "let the compositor place it", which is
  what every window did before.
- **No GPU metrics.** The dashboard covers CPU, memory, temperature, disk and
  network; caelestia also shows GPU, which needs vendor-specific tooling this
  machine does not have installed.
