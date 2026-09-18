import QtQuick
import Quickshell
import Quickshell.Io

// A JSON blob on disk under ~/.local/state/quickshell.
//
// This is BarConfig's storage pattern with the bar-specific schema lifted out:
// the same debounced write so a burst of changes is one save, the same guard
// against the load -> apply -> save loop writing the file straight back over
// itself on startup, and the same "no file yet" path that starts from defaults
// and writes one on the first change.
//
// Unlike BarConfig this does not know the schema -- it moves an object to and
// from disk and leaves interpretation to whoever owns it:
//
//     Persist {
//         id: store
//         fileName: "notifications.json"
//         defaults: ({ dnd: false, mutedApps: [] })
//         onLoaded: root.dnd = store.value("dnd")
//     }
//
// Read through value() rather than off `values` directly, so a key the file
// predates still falls back to its default instead of coming back undefined.
Scope {
    id: root

    required property string fileName
    property var defaults: ({})

    readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/quickshell"
    readonly property string filePath: root.stateDir + "/" + root.fileName

    // Whatever was last loaded or written. Assigning to this directly won't
    // schedule a save; go through set() or patch(). Not named `data` -- that is
    // the default property every QObject keeps its children in.
    property var values: ({})

    readonly property bool ready: root._loaded
    property bool _loaded: false

    signal loaded()

    function value(key) {
        if (root.values && key in root.values) return root.values[key]
        return root.defaults[key]
    }

    function set(key, v) {
        const next = Object.assign({}, root.values)
        next[key] = v
        root.values = next
        root.save()
    }

    function patch(obj) {
        root.values = Object.assign({}, root.values, obj)
        root.save()
    }

    function reset() {
        root.values = Object.assign({}, root.defaults)
        root.save()
    }

    function save() {
        if (!root._loaded) return
        saveTimer.restart()
    }

    // Write immediately instead of on the debounce. For the cases where
    // something outside the shell reads the file right after we change it --
    // the matugen hook reading the light/dark preference, for instance -- and
    // would otherwise race the 300 ms timer.
    function flush() {
        if (!root._loaded) return
        saveTimer.stop()
        storeFile.setText(JSON.stringify(root.values, null, 2) + "\n")
    }

    // Settles exactly once. FileView can load more than once at startup --
    // the mkdir below reloads it -- and after the first settle the in-memory
    // copy is authoritative, so a later read must not clobber a change that has
    // not been flushed yet, nor re-run a consumer's onLoaded.
    function _adopt(parsed) {
        if (root._loaded) return
        root.values = Object.assign({}, root.defaults, parsed)
        root._loaded = true
        root.loaded()
    }

    Timer {
        id: saveTimer
        interval: 300
        onTriggered: storeFile.setText(JSON.stringify(root.values, null, 2) + "\n")
    }

    Process {
        id: mkdir
        command: ["mkdir", "-p", root.stateDir]
        running: true
        onExited: storeFile.reload()
    }

    FileView {
        id: storeFile
        path: root.filePath
        printErrors: false

        onLoaded: {
            try {
                root._adopt(JSON.parse(text()))
            } catch (e) {
                console.warn("Persist: failed to parse", root.fileName + ":", e)
                root._adopt({})
            }
        }

        // No file yet -- start from defaults and write one on the first change.
        onLoadFailed: root._adopt({})
    }
}
