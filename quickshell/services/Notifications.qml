pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// The shell is the notification daemon; there is no mako.
//
// History and do-not-disturb used to live only in memory, so a shell reload
// threw away everything you had not read and silently un-muted you. Both are
// now written to ~/.local/state/quickshell/notifications.json, along with the
// per-app mute list, which did not exist at all -- DND was one global switch.
Singleton {
    id: root

    property bool dnd: false

    // App names the user has silenced individually. Kept as a plain array so it
    // round-trips through JSON unchanged.
    property var mutedApps: []

    property int _counter: 0
    property var _live: ({})

    readonly property int maxHistory: 100

    // Only this many rows are written to disk. The in-memory cap is larger
    // because scrolling back is cheap; the file is re-read at every start and
    // should stay small.
    readonly property int maxPersisted: 50

    ListModel { id: activeModel }
    property alias active: activeModel

    ListModel { id: historyModel }
    property alias history: historyModel

    property bool _loaded: false

    Persist {
        id: store
        fileName: "notifications.json"
        defaults: ({ dnd: false, mutedApps: [], history: [] })

        onLoaded: {
            root.dnd = store.value("dnd") === true
            root.mutedApps = store.value("mutedApps") || []

            const saved = store.value("history") || []
            for (let i = 0; i < saved.length; i++) {
                const row = saved[i]
                // uid 0 marks a row restored from disk: the Notification object
                // behind it is long gone, so it can be read and cleared but its
                // actions can no longer be invoked.
                historyModel.append({
                    uid: 0,
                    appName: row.appName || "System",
                    summary: row.summary || "",
                    body: row.body || "",
                    icon: row.icon || "",
                    image: row.image || "",
                    urgency: row.urgency || 0,
                    time: row.time || "",
                    actionsJson: "[]",
                    hasReply: false
                })
            }
            root._loaded = true
        }
    }

    function _persist() {
        if (!root._loaded) return
        const rows = []
        const n = Math.min(historyModel.count, root.maxPersisted)
        for (let i = 0; i < n; i++) {
            const r = historyModel.get(i)
            rows.push({
                appName: r.appName, summary: r.summary, body: r.body,
                icon: r.icon, image: r.image, urgency: r.urgency, time: r.time
            })
        }
        store.patch({ dnd: root.dnd, mutedApps: root.mutedApps, history: rows })
    }

    onDndChanged: root._persist()

    // ---- Muting -----------------------------------------------------------

    function isMuted(appName) {
        return root.mutedApps.indexOf(appName) !== -1
    }

    function toggleAppMute(appName) {
        if (!appName) return
        const next = root.mutedApps.slice()
        const i = next.indexOf(appName)
        if (i === -1) next.push(appName)
        else next.splice(i, 1)
        root.mutedApps = next
        root._persist()
    }

    // Every distinct app in the history, for a mute list that only offers apps
    // that have actually sent something.
    function knownApps() {
        const seen = []
        for (let i = 0; i < historyModel.count; i++) {
            const a = historyModel.get(i).appName
            if (a && seen.indexOf(a) === -1) seen.push(a)
        }
        seen.sort()
        return seen
    }

    // ---- History ----------------------------------------------------------

    function clearHistory() {
        // Close anything still live behind these rows rather than just dropping
        // the rows and leaking the notifications.
        for (let i = 0; i < historyModel.count; i++) {
            root._release(historyModel.get(i).uid)
        }
        historyModel.clear()
        root._persist()
    }

    function dismissHistory(uid) {
        for (let i = 0; i < historyModel.count; i++) {
            if (historyModel.get(i).uid === uid) {
                historyModel.remove(i, 1)
                break
            }
        }
        // This used to drop the row and leave the Notification in _live, so the
        // map grew by one entry for every notification dismissed from history.
        root._release(uid)
        root._persist()
    }

    // Closes the underlying notification and forgets it. Safe for uid 0 (a row
    // restored from disk) and for uids already gone.
    function _release(uid) {
        if (!uid || !(uid in root._live)) return
        const n = root._live[uid]
        delete root._live[uid]
        if (n && typeof n.dismiss === "function") n.dismiss()
    }

    function _extractActions(n) {
        const out = []
        if (n.actions) {
            for (let i = 0; i < n.actions.length; i++) {
                const a = n.actions[i]
                out.push({ id: a.identifier || "", text: a.text || a.name || "Action" })
            }
        }
        return out
    }

    // ---- Live notifications ------------------------------------------------

    function _removeActive(uid) {
        for (let i = 0; i < activeModel.count; i++) {
            if (activeModel.get(i).uid === uid) {
                activeModel.remove(i, 1)
                break
            }
        }
    }

    // The toast timed out on its own. The notification is kept alive so its
    // actions still work from the notification centre -- that is the whole
    // reason history rows can offer them -- and it is released when its history
    // row goes.
    function expire(uid) {
        root._removeActive(uid)
    }

    // The user closed the toast, which means they are done with it: tell the
    // app so, and let the notification go. The history row survives as a record
    // but its actions go with it.
    function dismiss(uid) {
        root._removeActive(uid)
        root._release(uid)
        root._stripActions(uid)
    }

    function _stripActions(uid) {
        for (let i = 0; i < historyModel.count; i++) {
            if (historyModel.get(i).uid === uid) {
                historyModel.setProperty(i, "actionsJson", "[]")
                historyModel.setProperty(i, "hasReply", false)
                break
            }
        }
    }

    function _inHistory(uid) {
        for (let i = 0; i < historyModel.count; i++) {
            if (historyModel.get(i).uid === uid) return true
        }
        return false
    }

    function invokeAction(uid, actionId) {
        const n = root._live[uid]
        if (n && typeof n.invokeAction === "function") n.invokeAction(actionId)
        root.dismiss(uid)
    }

    function canReply(uid) {
        const n = root._live[uid]
        return !!n && n.hasInlineReply === true
    }

    function replyPlaceholder(uid) {
        const n = root._live[uid]
        return (n && n.inlineReplyPlaceholder) ? n.inlineReplyPlaceholder : "Reply…"
    }

    function sendReply(uid, text) {
        const n = root._live[uid]
        if (n && typeof n.sendInlineReply === "function") n.sendInlineReply(text)
        root.dismiss(uid)
    }

    NotificationServer {
        id: server
        bodySupported: true
        actionsSupported: true
        imageSupported: true
        inlineReplySupported: true

        onNotification: (n) => {
            n.tracked = true
            root._counter++
            const uid = root._counter
            root._live[uid] = n

            if (n.closed) {
                n.closed.connect(() => root.dismiss(uid))
            }

            const appName = n.appName || "System"
            const row = {
                uid: uid,
                appName: appName,
                summary: n.summary || "",
                body: n.body || "",
                icon: n.appIcon || "",
                image: n.image || "",
                urgency: n.urgency,
                time: new Date().toLocaleTimeString(Qt.locale(), "hh:mm"),
                actionsJson: JSON.stringify(root._extractActions(n)),
                hasReply: n.hasInlineReply === true
            }

            historyModel.insert(0, row)
            if (historyModel.count > root.maxHistory) {
                for (let i = root.maxHistory; i < historyModel.count; i++) {
                    root._release(historyModel.get(i).uid)
                }
                historyModel.remove(root.maxHistory, historyModel.count - root.maxHistory)
            }
            root._persist()

            // Critical notifications ignore DND, as before, but a per-app mute
            // is an explicit choice about that app and holds regardless.
            if (root.isMuted(appName)) return
            if (root.dnd && n.urgency !== 2) return

            activeModel.insert(0, row)
        }
    }
}
