pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    property var entries: []

    function _refresh() {
        const list = []
        const apps = DesktopEntries.applications.values
        for (let i = 0; i < apps.length; i++) {
            const e = apps[i]
            if (e.noDisplay) continue
            list.push({
                id: e.id,
                name: e.name,
                comment: e.comment || "",
                icon: e.icon || "",
                entry: e
            })
        }
        list.sort((a, b) => a.name.localeCompare(b.name))
        root.entries = list
    }

    function filtered(query) {
        if (!query) return root.entries
        const q = query.toLowerCase()
        return root.entries.filter(e =>
            e.name.toLowerCase().includes(q) || e.comment.toLowerCase().includes(q))
    }

    function launch(item) {
        if (item && item.entry && typeof item.entry.execute === "function") {
            item.entry.execute()
        }
    }

    Component.onCompleted: root._refresh()

    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() { root._refresh() }
    }
}
