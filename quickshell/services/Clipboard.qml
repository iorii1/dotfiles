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

    // Case-insensitive substring over the preview text. Image rows have no
    // useful preview -- cliphist reports them as "binary data ..." -- so they
    // match on the word "image" instead, which is what they are labelled.
    function filtered(query) {
        const q = (query || "").trim().toLowerCase()
        if (!q) return root.entries
        return root.entries.filter(e => e.isImage
            ? ("image".indexOf(q) === 0 || "binary".indexOf(q) === 0)
            : e.preview.toLowerCase().indexOf(q) !== -1)
    }

    function select(id) {
        selectProc.command = ["bash", "-c", "cliphist decode " + id + " | wl-copy"]
        selectProc.running = true
    }

    function clearAll() {
        clearProc.command = ["bash", "-c", "cliphist wipe"]
        clearProc.running = true
    }

    // cliphist deletes by being fed the item's own list line on stdin, so the
    // line is looked up by id rather than reconstructed -- a preview containing
    // a tab would not survive being rebuilt.
    function remove(id) {
        removeProc.command = ["bash", "-c",
            "cliphist list | awk -F'\t' -v id=" + JSON.stringify(String(id))
            + " '$1==id' | cliphist delete"]
        removeProc.running = true
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

                root.pendingList = list

                const decode = imageIds.map(id =>
                    "[ -f " + JSON.stringify(root.thumbDir + "/" + id) + " ] || cliphist decode " + id +
                    " > " + JSON.stringify(root.thumbDir + "/" + id) + " 2>/dev/null"
                ).join("; ")

                // Sweep thumbnails whose entry has since left the history.
                // Without this the cache grew by one file for every image ever
                // copied and nothing ever removed them.
                const keep = imageIds.join(" ")
                const prune =
                    "cd " + JSON.stringify(root.thumbDir) + " 2>/dev/null && " +
                    "for f in *; do [ -e \"$f\" ] || continue; " +
                    "case \" " + keep + " \" in *\" $f \"*) ;; *) rm -f -- \"$f\";; esac; done"

                thumbProc.command = ["bash", "-c",
                    "mkdir -p " + JSON.stringify(root.thumbDir) + "; "
                    + (decode ? decode + "; " : "") + prune + "; true"]
                thumbProc.running = true
            }
        }
    }

    // Decodes any not-yet-cached image entries to thumbDir BEFORE entries
    // is published, so the ListView never binds an Image to a file that
    // doesn't exist yet.
    Process { id: thumbProc; onExited: root.entries = root.pendingList }

    Process { id: selectProc }
    Process { id: removeProc; onExited: root.refresh() }
    Process { id: clearProc; onExited: root.refresh() }
}
