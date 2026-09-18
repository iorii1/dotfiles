pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// "Keep awake".
//
// This used to work by `pkill -x hypridle`, respawning it on the way back, and
// polling `pgrep` every 20 seconds to find out which state it was really in.
// That killed the user's idle daemon outright and raced anything else that
// started or stopped it -- and the poll meant the toggle could sit wrong for
// up to twenty seconds.
//
// The helper takes the inhibit hypridle already advertises
// (org.freedesktop.ScreenSaver, reference counted, the same one video players
// use) plus a logind inhibit for suspend, and holds both for as long as it
// runs. Nothing is killed, and other inhibitors are left alone.
Singleton {
    id: root

    readonly property string helper: Quickshell.env("HOME") + "/.local/bin/qs-keep-awake"

    // True while our helper is running. Owned by this service rather than
    // inferred from the world, so it cannot drift.
    readonly property bool keepAwake: helperProc.running

    property string lastError: ""

    function toggle() {
        if (root.keepAwake) root.release()
        else root.inhibit()
    }

    function inhibit() {
        if (helperProc.running) return
        root.lastError = ""
        helperProc.running = true
    }

    function release() {
        // Process.running = false sends SIGTERM, which the helper handles by
        // dropping both inhibits before it exits.
        helperProc.running = false
    }

    Process {
        id: helperProc
        command: [root.helper]

        stderr: StdioCollector {
            onStreamFinished: if (text.trim() !== "") root.lastError = text.trim()
        }

        onExited: (code) => {
            // 0 is the clean release path; anything else means the helper could
            // not start (not installed, or python-dbus missing).
            if (code !== 0 && root.lastError === "") {
                root.lastError = "keep-awake helper exited with " + code
            }
        }
    }
}
