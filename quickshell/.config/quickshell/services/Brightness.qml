pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property int level: 100

    function setLevel(pct) {
        pct = Math.max(0, Math.min(100, pct))
        setProc.command = ["brightnessctl", "set", pct + "%"]
        setProc.running = true
    }

    Process {
        id: setProc
        running: false
    }

    Timer {
        interval: 400
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: pollProc.running = true
    }

    Process {
        id: pollProc
        running: false
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = this.text.trim().split(",")
                if (parts.length >= 4) {
                    const pct = parseInt(parts[3].replace("%", ""))
                    if (!isNaN(pct)) root.level = pct
                }
            }
        }
    }
}
