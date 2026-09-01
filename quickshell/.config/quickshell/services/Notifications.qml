pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string hiddenFile: "/home/yor/.cache/quickshell/notifications_hidden"

    property var rawHistory: []
    property var hiddenIds: []

    // makoctl has no way to delete a single history entry (only list/restore),
    // so "delete" here just hides it client-side, persisted across restarts.
    readonly property var history: rawHistory.filter(n => hiddenIds.indexOf(n.id) === -1)

    function refresh() {
        histProc.running = true
    }

    function hideEntry(id) {
        if (hiddenIds.indexOf(id) !== -1) return
        hiddenIds = hiddenIds.concat([id])
        saveHidden()
    }

    function dismissAllVisible() {
        dismissProc.running = true
    }

    function saveHidden() {
        saveProc.command = ["bash", "-c",
            "mkdir -p ~/.cache/quickshell && printf '%s' '" + hiddenIds.join(",") + "' > " + hiddenFile]
        saveProc.running = true
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Process {
        id: histProc
        command: ["makoctl", "history", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(this.text)
                    root.rawHistory = Array.isArray(parsed) ? parsed : []
                } catch (e) {
                    root.rawHistory = []
                }
            }
        }
    }

    Process {
        id: dismissProc
        command: ["makoctl", "dismiss", "--all"]
    }

    Process { id: saveProc }

    Process {
        id: loadHiddenProc
        command: ["bash", "-c", "cat " + hiddenFile + " 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const text = this.text.trim()
                root.hiddenIds = text.length > 0 ? text.split(",").map(n => parseInt(n)).filter(n => !isNaN(n)) : []
            }
        }
    }

    Component.onCompleted: loadHiddenProc.running = true
}
