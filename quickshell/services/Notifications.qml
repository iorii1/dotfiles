pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    property bool dnd: false
    property int _counter: 0
    property var _live: ({})
    readonly property int maxHistory: 100

    ListModel { id: activeModel }
    property alias active: activeModel

    ListModel { id: historyModel }
    property alias history: historyModel

    function clearHistory() { historyModel.clear() }

    function dismissHistory(uid) {
        for (let i = 0; i < historyModel.count; i++) {
            if (historyModel.get(i).uid === uid) {
                historyModel.remove(i, 1)
                break
            }
        }
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

    function dismiss(uid) {
        if (!(uid in root._live)) return
        const n = root._live[uid]
        delete root._live[uid]
        for (let i = 0; i < activeModel.count; i++) {
            if (activeModel.get(i).uid === uid) {
                activeModel.remove(i, 1)
                break
            }
        }
        if (n && typeof n.dismiss === "function") n.dismiss()
    }

    function invokeAction(uid, actionId) {
        const n = root._live[uid]
        if (n && typeof n.invokeAction === "function") n.invokeAction(actionId)
        root.dismiss(uid)
    }

    NotificationServer {
        id: server
        bodySupported: true
        actionsSupported: true
        imageSupported: true

        onNotification: (n) => {
            n.tracked = true
            root._counter++
            const uid = root._counter
            root._live[uid] = n

            if (n.closed) {
                n.closed.connect(() => root.dismiss(uid))
            }

            historyModel.insert(0, {
                uid: uid,
                appName: n.appName || "System",
                summary: n.summary || "",
                body: n.body || "",
                icon: n.appIcon || "",
                urgency: n.urgency,
                time: new Date().toLocaleTimeString(Qt.locale(), "hh:mm")
            })
            if (historyModel.count > root.maxHistory) {
                historyModel.remove(root.maxHistory, historyModel.count - root.maxHistory)
            }

            if (root.dnd && n.urgency !== 2) return

            activeModel.insert(0, {
                uid: uid,
                appName: n.appName || "System",
                summary: n.summary || "",
                body: n.body || "",
                icon: n.appIcon || "",
                urgency: n.urgency,
                actionsJson: JSON.stringify(root._extractActions(n))
            })
        }
    }
}
