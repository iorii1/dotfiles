pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property int barCount: 20
    property var barLevels: {
        let arr = []
        for (let i = 0; i < barCount; i++) arr.push(0.0)
        return arr
    }
    property int activeConsumers: 0
    readonly property bool processEnabled: activeConsumers > 0

    function registerConsumer() {
        activeConsumers++
    }
    function unregisterConsumer() {
        activeConsumers = Math.max(0, activeConsumers - 1)
    }
    function resetBars() {
        let empty = []
        for (let i = 0; i < root.barCount; i++) empty.push(0.0)
        root.barLevels = empty
    }

    onProcessEnabledChanged: if (!processEnabled) resetBars()

    Process {
        id: cavaProcess
        running: root.processEnabled
        onExited: if (root.processEnabled) restartTimer.start()
        command: [
            "bash", "-c",
            "cava -p <(printf '[general]\\nbars = %d\\nframerate = 60\\nsensitivity = 150\\n[output]\\nmethod = raw\\nraw_target = /dev/stdout\\ndata_format = ascii\\nascii_max_range = 1000\\nbar_delimiter = 59\\n' " + root.barCount + ")"
        ]
        stdout: SplitParser {
            onRead: data => {
                let str = data.trim()
                if (str.length === 0) return
                let parts = str.split(";")
                let count = Math.min(parts.length, root.barCount)
                let newLevels = []
                for (let i = 0; i < root.barCount; i++) {
                    let val = i < count ? (parseInt(parts[i]) || 0) : 0
                    newLevels.push(Math.max(0.0, Math.min(1.0, val / 1000.0)))
                }
                root.barLevels = newLevels
            }
        }
    }

    Timer {
        id: restartTimer
        interval: 500
        running: false
        repeat: false
        onTriggered: if (root.processEnabled) cavaProcess.running = true
    }
}
