import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "../../config"
import "../../services"
import "../common"

// The dock's contents: pinned apps first, then anything else that is running.
//
// It used to list open windows and nothing else, so it could switch between
// things but never start one. A pinned app with no window is a launcher; a
// pinned app with windows is a switcher for them; anything running that is not
// pinned still appears, as before.
RowLayout {
    id: root
    spacing: Appearance.spacingSmall

    // Driven by the dock's reveal state so items can fade in staggered.
    property bool shown: true

    // The output this dock belongs to. The list used to be every toplevel on
    // the machine, so on a dual-head setup the dock on one monitor listed -- and
    // revealed itself for -- windows living on the other.
    property string screenName: ""

    readonly property var windows: {
        const all = Hyprland.toplevels.values
        if (!root.screenName) return all
        const out = []
        for (let i = 0; i < all.length; i++) {
            const mon = all[i].monitor
            // A toplevel Hyprland has not placed yet reports no monitor; show
            // it rather than dropping it off every dock.
            if (!mon || mon.name === root.screenName) out.push(all[i])
        }
        return out
    }

    // One entry per pill: a pinned app (with however many windows it has), or
    // a running window whose app is not pinned.
    readonly property var items: {
        const out = []
        const claimed = {}

        const pins = DockPins.entries
        for (let i = 0; i < pins.length; i++) {
            const entry = pins[i]
            const mine = []
            for (let w = 0; w < root.windows.length; w++) {
                const win = root.windows[w]
                const appId = win.wayland ? win.wayland.appId : ""
                const match = Apps.entryForAppId(appId)
                if (match && match.id === entry.id) {
                    mine.push(win)
                    claimed[win.address] = true
                }
            }
            out.push({ pinned: true, entry: entry, entryId: entry.id, windows: mine })
        }

        for (let w = 0; w < root.windows.length; w++) {
            const win = root.windows[w]
            if (claimed[win.address]) continue
            const appId = win.wayland ? win.wayland.appId : ""
            const match = Apps.entryForAppId(appId)
            out.push({
                pinned: false, entry: match,
                entryId: match ? match.id : "",
                windows: [win]
            })
        }
        return out
    }

    Repeater {
        model: root.items

        Rectangle {
            id: pill
            required property var modelData
            required property int index

            readonly property var windows: pill.modelData.windows
            readonly property bool running: pill.windows.length > 0
            readonly property bool active: {
                for (let i = 0; i < pill.windows.length; i++) {
                    if (pill.windows[i].activated) return true
                }
                return false
            }
            readonly property bool hovered: fx.containsMouse

            readonly property string appId: pill.running && pill.windows[0].wayland
                ? pill.windows[0].wayland.appId : ""
            readonly property string iconSource: pill.modelData.entry
                ? pill.modelData.entry.icon
                : pill.appId
            readonly property string label: pill.modelData.entry
                ? pill.modelData.entry.name
                : (pill.running ? (pill.windows[0].title || "") : "")

            implicitWidth: 44
            implicitHeight: 44
            radius: Appearance.radiusNormal
            color: active ? Colors.surfaceContainerHigh : (hovered ? Colors.surfaceContainer : "transparent")
            Behavior on color { ColorAnimation { duration: Appearance.animFast } }

            // A pinned app with nothing open is a launcher, and reads as
            // available rather than active.
            opacity: root.shown ? (pill.running ? 1 : 0.55) : 0
            Behavior on opacity { Anim {} }

            scale: fx.gestureScale
            Behavior on scale { Anim { duration: Appearance.animFast } }

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: "#ffffff"
                opacity: fx.flashOpacity
            }

            Text {
                anchors.centerIn: parent
                visible: icon.status !== Image.Ready
                text: pill.label ? pill.label.charAt(0).toUpperCase() : "?"
                color: Colors.textSecondary
                font.family: Appearance.fontFamily
                font.pixelSize: Appearance.fontSizeLarge
            }

            Image {
                id: icon
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -2
                width: 28
                height: 28
                source: pill.iconSource ? "image://icon/" + pill.iconSource : ""
                fillMode: Image.PreserveAspectFit
                asynchronous: true
            }

            // One dot for running, filled for focused. Several windows get
            // several dots, up to three, which is the point at which counting
            // them stops being useful.
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 4
                spacing: 2

                Repeater {
                    model: Math.min(pill.windows.length, 3)

                    Rectangle {
                        width: 4
                        height: 4
                        radius: 2
                        color: pill.active ? Colors.primary : Colors.textSecondary
                        Behavior on color { ColorAnimation { duration: Appearance.animFast } }
                    }
                }
            }

            // Middle closes, right pins. Both sit below the PressFx, which
            // takes only the left button, and a MouseArea passes through what
            // it does not accept.
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.MiddleButton | Qt.RightButton
                onClicked: (mouse) => {
                    if (mouse.button === Qt.MiddleButton) {
                        if (pill.running) Compositor.closeWindow(pill.windows[0].address)
                        return
                    }
                    if (pill.modelData.entryId !== "") DockPins.toggle(pill.modelData.entryId)
                }
            }

            PressFx {
                id: fx
                anchors.fill: parent

                // Running: focus it, and cycle if there are several. Not
                // running: it is a pinned launcher, so start it.
                onActivated: {
                    if (!pill.running) {
                        Apps.launchEntry(pill.modelData.entry)
                        return
                    }
                    let next = 0
                    for (let i = 0; i < pill.windows.length; i++) {
                        if (pill.windows[i].activated) { next = (i + 1) % pill.windows.length; break }
                    }
                    Compositor.focusWindow(pill.windows[next].address)
                }
            }
        }
    }
}
