pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// What the launcher actually searches.
//
// It used to be apps and nothing else. This composes apps with three other
// kinds of result, each identified by `kind` so the delegate can render them
// differently:
//
//   calc     arithmetic, when the query looks like a sum. Enter copies it.
//   command  anything after ">", run through the shell.
//   action   the shell's own verbs -- lock, reboot, panels, wallpaper.
//   app      desktop entries, ranked by Apps.
//
// qalc is preferred for arithmetic when it is installed, because it does units
// and currency; Calculator is the fallback so this works with no extra package.
Singleton {
    id: root

    readonly property string commandPrefix: ">"

    property bool qalcAvailable: false
    property string qalcResult: ""

    Process {
        id: findQalc
        running: true
        command: ["bash", "-c", "command -v qalc >/dev/null && echo yes || echo no"]
        stdout: StdioCollector { onStreamFinished: root.qalcAvailable = (text.trim() === "yes") }
    }

    // ---- Actions -----------------------------------------------------------

    // `panel` opens one of the shell's own panels; `run` shells out. Keywords
    // widen what matches without cluttering the visible name.
    readonly property var actions: [
        { name: "Lock",            icon: "", keywords: "lock screen session", run: "loginctl lock-session" },
        { name: "Sleep",           icon: "", keywords: "suspend sleep",       run: "systemctl suspend" },
        { name: "Log out",         icon: "", keywords: "logout exit quit",    run: "hyprctl dispatch 'hl.dsp.exit()'" },
        { name: "Restart",         icon: "", keywords: "reboot restart",      run: "systemctl reboot" },
        { name: "Shut down",       icon: "", keywords: "shutdown poweroff halt", run: "systemctl poweroff" },
        { name: "Wallpaper",       icon: "", keywords: "wallpaper background theme", run: "QS_WALLPAPER_DIR=$HOME/Pictures/Wallpapers ~/.local/share/qs-wallpaper-picker/scripts/open_picker.sh" },
        { name: "Bar settings",    icon: "", keywords: "settings preferences bar", panel: "settings" },
        { name: "Quick settings",  icon: "", keywords: "quick settings toggles night light", panel: "quickSettings" },
        { name: "System monitor",  icon: "", keywords: "system monitor resources cpu memory dashboard", panel: "dashboard" },
        { name: "Audio",           icon: "", keywords: "audio volume sound mixer output input", panel: "audio" },
        { name: "Clipboard",       icon: "", keywords: "clipboard history paste", panel: "clipboard" },
        { name: "Notifications",   icon: "", keywords: "notifications history", panel: "notificationCenter" },
        { name: "Screenshot",      icon: "", keywords: "screenshot capture region grab", ipc: "region" },
        { name: "Record screen",   icon: "", keywords: "record recording screencast video", ipc: "record" }
    ]

    // ---- Composing results -------------------------------------------------

    function results(query) {
        const q = (query || "").trim()
        if (q === "") return Apps.filtered("").map(root._asApp)

        // A command is explicit, so it is the only thing offered.
        if (q.startsWith(root.commandPrefix)) {
            const cmd = q.substring(root.commandPrefix.length).trim()
            if (cmd === "") return []
            return [{
                kind: "command", name: cmd, comment: "Run in a shell",
                icon: "", command: cmd
            }]
        }

        const out = []

        if (Calculator.looksLikeMath(q)) {
            const value = root.qalcAvailable && root.qalcResult !== ""
                ? root.qalcResult
                : Calculator.evaluate(q)
            if (value !== "") {
                out.push({
                    kind: "calc", name: value, comment: q + " — press Enter to copy",
                    icon: "", value: value
                })
            }
        }

        const lower = q.toLowerCase()
        for (let i = 0; i < root.actions.length; i++) {
            const a = root.actions[i]
            const hay = (a.name + " " + (a.keywords || "")).toLowerCase()
            if (hay.indexOf(lower) === -1) continue
            out.push({
                kind: "action", name: a.name,
                comment: a.panel ? "Open panel" : "Shell action",
                icon: a.icon, action: a
            })
        }

        return out.concat(Apps.filtered(q).map(root._asApp))
    }

    function _asApp(item) {
        return {
            kind: "app", name: item.name, comment: item.comment,
            icon: item.icon, app: item
        }
    }

    // ---- Activating --------------------------------------------------------

    function activate(result) {
        if (!result) return

        switch (result.kind) {
        case "app":
            Apps.launch(result.app)
            return
        case "calc":
            copyProc.command = ["bash", "-c",
                "printf '%s' " + JSON.stringify(result.value) + " | wl-copy"]
            copyProc.running = true
            return
        case "command":
            root._run(result.command)
            return
        case "action":
            const a = result.action
            if (a.panel) UiState.show(a.panel)
            else if (a.ipc) Capture[a.ipc === "record" ? "toggleRecording" : "region"]()
            else if (a.run) root._run(a.run)
            return
        }
    }

    // setsid so the launched thing outlives the shell rather than dying with
    // it, which is what `exec_cmd` does for keybinds too.
    function _run(cmd) {
        runProc.command = ["bash", "-c", "setsid -f " + cmd + " >/dev/null 2>&1"]
        runProc.running = true
    }

    Process { id: runProc }
    Process { id: copyProc }
}
