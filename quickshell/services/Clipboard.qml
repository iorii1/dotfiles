pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var entries: []
    property var pendingList: []
    readonly property string thumbDir: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/quickshell-clip-thumbs"

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
        command: ["bash", "-c", "mkdir -p " + JSON.stringify(root.thumbDir) + "; cliphist list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n").filter(l => l.length > 0)
                const list = []
                const imageIds = []
                for (const line of lines) {
                    const idx = line.indexOf("\t")
                    if (idx === -1) continue
                    const id = line.substring(0, idx)
                    const preview = line.substring(idx + 1)
                    const isImage = preview.indexOf("binary data") !== -1
                    if (isImage) imageIds.push(id)
                    list.push({ id: id, preview: preview, isImage: isImage })
                }

                if (imageIds.length > 0) {
                    root.pendingList = list
                    const cmds = imageIds.map(id =>
                        "[ -f " + JSON.stringify(root.thumbDir + "/" + id) + " ] || cliphist decode " + id +
                        " > " + JSON.stringify(root.thumbDir + "/" + id) + " 2>/dev/null"
                    ).join("; ")
                    thumbProc.command = ["bash", "-c", cmds]
                    thumbProc.running = true
                } else {
                    root.entries = list
                }
            }
        }
    }

    // Decodes any not-yet-cached image entries to thumbDir BEFORE entries
    // is published, so the ListView never binds an Image to a file that
    // doesn't exist yet.
    Process { id: thumbProc; onExited: root.entries = root.pendingList }

    Process { id: selectProc }
    Process { id: clearProc; onExited: root.refresh() }
}
