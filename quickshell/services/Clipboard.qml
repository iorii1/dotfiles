pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var entries: []

    function refresh() {
        if (!listProc.running) listProc.running = true
    }

    function select(id) {
        selectProc.command = ["bash", "-c", "cliphist decode " + id + " | wl-copy"]
        selectProc.running = true
    }

    function clearAll() {
        clearProc.command = ["bash", "-c", "cliphist wipe"]
        clearProc.running = true
    }

    Process {
        id: listProc
        command: ["bash", "-c", "cliphist list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n").filter(l => l.length > 0)
                const list = []
                for (const line of lines) {
                    const idx = line.indexOf("\t")
                    if (idx === -1) continue
                    const id = line.substring(0, idx)
                    const preview = line.substring(idx + 1)
                    list.push({ id: id, preview: preview, isImage: preview.indexOf("binary data") !== -1 })
                }
                root.entries = list
            }
        }
    }

    Process { id: selectProc }
    Process { id: clearProc; onExited: root.refresh() }
}
