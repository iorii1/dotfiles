pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string current: "balanced"
    readonly property var available: ["power-saver", "balanced", "performance"]

    function refresh() {
        if (!getProc.running) getProc.running = true
    }

    function set(profile) {
        root.current = profile
        setProc.command = ["powerprofilesctl", "set", profile]
        setProc.running = true
    }

    Process {
        id: getProc
        command: ["powerprofilesctl", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim()
                if (p) root.current = p
            }
        }
    }

    Process { id: setProc }

    Timer {
        interval: 15000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
