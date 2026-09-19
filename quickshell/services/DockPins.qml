pragma Singleton
import QtQuick
import Quickshell

// Apps pinned to the dock.
//
// The dock was a pure window switcher: it listed what was open and nothing
// else, so it could never start anything. Pins give it the other half, and
// they persist.
//
// Stored as desktop entry ids, because that is what survives -- a window
// address does not outlive the window, and an app id is what a pin means.
Singleton {
    id: root

    property var pinned: []

    Persist {
        id: store
        fileName: "dock.json"
        defaults: ({ pinned: [] })
        onLoaded: root.pinned = store.value("pinned") || []
    }

    function isPinned(entryId) {
        return root.pinned.indexOf(String(entryId)) !== -1
    }

    function toggle(entryId) {
        if (!entryId) return
        const id = String(entryId)
        const next = root.pinned.slice()
        const at = next.indexOf(id)
        if (at === -1) next.push(id)
        else next.splice(at, 1)
        root.pinned = next
        store.set("pinned", next)
    }

    function move(entryId, delta) {
        const id = String(entryId)
        const next = root.pinned.slice()
        const at = next.indexOf(id)
        if (at === -1) return
        const to = at + delta
        if (to < 0 || to >= next.length) return
        next.splice(at, 1)
        next.splice(to, 0, id)
        root.pinned = next
        store.set("pinned", next)
    }

    // The DesktopEntry objects, in pin order, skipping ids that no longer
    // resolve -- an app can be uninstalled while its pin remains.
    readonly property var entries: {
        const out = []
        for (let i = 0; i < root.pinned.length; i++) {
            const e = Apps.entryById(root.pinned[i])
            if (e) out.push(e)
        }
        return out
    }
}
