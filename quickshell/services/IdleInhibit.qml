pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // true = idle timeouts (lock/dpms/suspend) are suspended because
    // hypridle isn't running; toggled manually from Quick Settings
    property bool keepAwake: false

    function refresh() {
        if (!checkProc.running) checkProc.running = true
    }

    function toggle() {
        if (root.keepAwake) {
            resumeProc.running = true
            root.keepAwake = false
        } else {
            pauseProc.running = true
            root.keepAwake = true
        }
    }

    Process {
        id: checkProc
        command: ["pgrep", "-x", "hypridle"]
        stdout: StdioCollector {
            onStreamFinished: root.keepAwake = (text.trim() === "")
        }
    }

    Process { id: pauseProc; command: ["pkill", "-x", "hypridle"] }
    Process { id: resumeProc; command: ["bash", "-c", "pidof hypridle >/dev/null || (hypridle >/dev/null 2>&1 & disown)"] }

    Timer {
        interval: 20000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
