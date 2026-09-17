import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../../config"
import "../../services"
import "../common"

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: dockWindow
            required property var modelData
            screen: modelData

            // Deliberately always visible. A layer-shell surface with
            // visible: false is destroyed, and a destroyed surface cannot
            // receive the hover that is supposed to bring the dock back. The
            // window therefore stays mapped and the *mask* is what changes:
            // just the trigger strip while hidden, the whole dock once shown.
            visible: BarConfig.showTaskbar
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell-dock"
            exclusionMode: ExclusionMode.Ignore
            focusable: false
            color: "transparent"

            anchors { bottom: true; left: true; right: true }
            implicitHeight: dockHeight + bottomMargin + revealTravel

            readonly property int dockHeight: 60
            readonly property int bottomMargin: Appearance.spacingSmall
            readonly property int revealTravel: 16
            readonly property int triggerWidth: 400
            readonly property bool hasWindows: Hyprland.toplevels.values.length > 0

            property bool revealed: false

            mask: Region { item: dockWindow.revealed ? hoverArea : trigger }

            function show() {
                if (!hasWindows) return
                hideTimer.stop()
                revealed = true
            }

            // Hiding waits out a short grace period so crossing a gap or
            // clipping a corner on the way to an icon does not dismiss it.
            Timer {
                id: hideTimer
                interval: 350
                onTriggered: dockWindow.revealed = false
            }

            onHasWindowsChanged: if (!hasWindows) revealed = false

            // The hidden-state hit target: a thin strip at the bottom centre.
            Item {
                id: trigger
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                width: dockWindow.triggerWidth
                height: 4

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: dockWindow.show()
                }
            }

            // The revealed-state hit target. It deliberately extends past the
            // card down to the screen edge and out to the trigger's width, so
            // the pointer never falls into a gap between the two regions --
            // which would hide and immediately re-show the dock in a loop.
            Item {
                id: hoverArea
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.max(card.width, dockWindow.triggerWidth)
                height: dockWindow.dockHeight + dockWindow.bottomMargin

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: dockWindow.show()
                    onExited: hideTimer.restart()
                }
            }

            PopupCard {
                id: card
                anchors.horizontalCenter: parent.horizontalCenter
                width: items.implicitWidth + Appearance.spacingNormal * 2
                height: dockWindow.dockHeight

                y: dockWindow.revealed
                   ? parent.height - dockWindow.dockHeight - dockWindow.bottomMargin
                   : parent.height
                opacity: dockWindow.revealed ? 1 : 0

                Behavior on y {
                    NumberAnimation {
                        duration: Appearance.animNormal
                        easing.type: Easing.OutBack
                        easing.overshoot: Appearance.overshootCard
                    }
                }
                Behavior on opacity { NumberAnimation { duration: Appearance.animFast; easing.type: Easing.OutCubic } }
                Behavior on width { NumberAnimation { duration: Appearance.animNormal; easing.type: Easing.OutCubic } }

                DockItems {
                    id: items
                    anchors.centerIn: parent
                    shown: dockWindow.revealed
                }
            }
        }
    }
}
