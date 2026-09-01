pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // [{ id: "331", preview: "...", isImage: bool }]
    property var entries: []

    function refresh() {
        listProc.running = true
    }

    function copyEntry(id) {
        copyProc.command = ["bash", "-c", "cliphist decode <<< " + id + " | wl-copy"]
        copyProc.running = true
    }

    function deleteEntry(id) {
        deleteProc.command = ["bash", "-c", "cliphist delete <<< " + id]
        deleteProc.running = true
    }

    function clearAll() {
        wipeProc.running = true
    }

    Process {
        id: listProc
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.split("\n").filter(l => l.length > 0)
                root.entries = lines.map(line => {
                    const tab = line.indexOf("\t")
                    const id = tab >= 0 ? line.slice(0, tab) : line
                    const preview = tab >= 0 ? line.slice(tab + 1) : ""
                    return {
                        id: id,
                        preview: preview,
                        isImage: preview.indexOf("binary data") >= 0
                    }
                })
            }
        }
    }

    Process { id: copyProc; onExited: root.refresh() }
    Process { id: deleteProc; onExited: root.refresh() }
    Process { id: wipeProc; command: ["cliphist", "wipe"]; onExited: root.refresh() }

    Component.onCompleted: refresh()
}
