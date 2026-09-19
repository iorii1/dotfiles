pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var entries: []
    property var pendingList: []

    // Entries kept at the top and never aged out of view. cliphist itself has
    // no concept of pinning, so this is the shell's own list of ids, held
    // alongside the preview text: an id that has since fallen off the end of
    // cliphist's history is dropped rather than shown as a dead row.
    property var pinned: []
    readonly property string thumbDir: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/quickshell-clip-thumbs"

    Persist {
        id: store
        fileName: "clipboard.json"
        defaults: ({ pinned: [] })
        onLoaded: root.pinned = store.value("pinned") || []
    }

    function isPinned(id) {
        const list = root.pinned
        for (let i = 0; i < list.length; i++) {
            if (list[i].id === String(id)) return true
        }
        return false
    }

    function togglePin(entry) {
        if (!entry) return
        const id = String(entry.id)
        const next = []
        let found = false
        for (let i = 0; i < root.pinned.length; i++) {
            if (root.pinned[i].id === id) { found = true; continue }
            next.push(root.pinned[i])
        }
        // Newest pin first, so pinning something puts it where you just looked.
        if (!found) next.unshift({ id: id, preview: entry.preview || "" })
        root.pinned = next
        store.set("pinned", next)
    }

    function refresh() {
        if (!listProc.running) listProc.running = true
    }

    // Case-insensitive substring over the preview text. Image rows have no
    // useful preview -- cliphist reports them as "binary data ..." -- so they
    // match on the word "image" instead, which is what they are labelled.
    // Pinned entries float to the top, in pin order. Everything else keeps
    // cliphist's order, which is most-recent-first.
    function _withPinnedFirst(list) {
        if (root.pinned.length === 0) return list
        const pins = []
        const rest = []
        for (let i = 0; i < list.length; i++) {
            (root.isPinned(list[i].id) ? pins : rest).push(list[i])
        }
        pins.sort((a, b) => {
            const ia = root.pinned.findIndex(p => p.id === String(a.id))
            const ib = root.pinned.findIndex(p => p.id === String(b.id))
            return ia - ib
        })
        return pins.concat(rest)
    }

    function filtered(query) {
        const q = (query || "").trim().toLowerCase()
        if (!q) return root._withPinnedFirst(root.entries)
        return root._withPinnedFirst(root.entries.filter(e => e.isImage
            ? ("image".indexOf(q) === 0 || "binary".indexOf(q) === 0)
            : e.preview.toLowerCase().indexOf(q) !== -1))
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
    Process {
        id: thumbProc
        onExited: {
            root.entries = root.pendingList
            root._prunePins()
        }
    }

    // cliphist ages entries out at its own max-items, so a pin can outlive the
    // thing it points at. Dropped rather than left as a row that copies
    // nothing.
    function _prunePins() {
        if (root.pinned.length === 0) return
        const live = {}
        for (let i = 0; i < root.entries.length; i++) live[String(root.entries[i].id)] = true
        const kept = root.pinned.filter(p => live[p.id])
        if (kept.length === root.pinned.length) return
        root.pinned = kept
        store.set("pinned", kept)
    }

    Process { id: selectProc }
    Process { id: removeProc; onExited: root.refresh() }
    Process { id: clearProc; onExited: root.refresh() }
}
