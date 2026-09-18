pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Light or dark, for the whole desktop.
//
// dotfiless_matugen.sh hardcoded `-m dark`, so the wallpaper drove the hue and
// nothing drove the brightness. The mode now lives in a file the script reads,
// and flipping it re-runs the same pipeline the wallpaper picker uses -- so
// kitty, GTK, hyprlock and the shell all move together rather than the shell
// going light on its own.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")

    property string mode: "dark"
    readonly property bool isDark: root.mode !== "light"

    // Written by install.sh from the wallpaper picker it clones.
    readonly property string hook: root.home + "/.local/share/qs-wallpaper-picker/scripts/dotfiless_matugen.sh"

    property bool applying: false

    Persist {
        id: store
        fileName: "theme.json"
        defaults: ({ mode: "dark" })
        onLoaded: root.mode = (store.value("mode") === "light") ? "light" : "dark"
    }

    // Always re-applies, even when the mode is unchanged: the generated files
    // can be stale from a switch that never finished, and re-running the hook
    // is the cheapest way to make them true again.
    function setMode(m) {
        const next = (m === "light") ? "light" : "dark"
        root.mode = next
        store.set("mode", next)
        // The hook reads this file, so it has to be on disk before it runs.
        store.flush()
        root.apply()
    }

    function toggle() {
        root.setMode(root.isDark ? "light" : "dark")
    }

    // Re-derives every generated palette from the current wallpaper at the
    // current mode. Falls back to just reloading the shell's own colours if
    // the hook is missing, so a half-installed checkout still flips.
    function apply() {
        root.applying = true
        applyProc.command = ["bash", "-c",
            "if [ -x " + JSON.stringify(root.hook) + " ]; then "
            + JSON.stringify(root.hook) + "; else qs ipc call theme reloadColors; fi"]
        applyProc.running = true
    }

    Process {
        id: applyProc
        onExited: root.applying = false
    }
}
