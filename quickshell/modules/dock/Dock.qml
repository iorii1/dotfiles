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

        Scope {
            id: perScreen
            required property var modelData

            readonly property int dockHeight: 60
            readonly property int bottomMargin: Appearance.spacingSmall
            readonly property int zoneWidth: 400
            readonly property bool hasWindows: Hyprland.toplevels.values.length > 0

            property bool revealed: false

            function show() {
                if (!hasWindows) return
                hideTimer.stop()
                revealed = true
            }

            // A grace period, so clipping a corner on the way to an icon does
            // not dismiss the dock.
            Timer {
                id: hideTimer
                interval: 350
                onTriggered: perScreen.revealed = false
            }

            onHasWindowsChanged: if (!hasWindows) revealed = false

            // Two windows rather than one whose mask changes. Swapping a
            // surface's input region while the pointer is inside it makes the
            // compositor re-deliver enter/leave, which flipped `revealed` back
            // and forth and left the dock oscillating. Each window here keeps
            // one fixed input region for its whole life.

            // Always mapped: a thin strip at the bottom centre, the only thing
            // listening while the dock is hidden.
            PanelWindow {
                screen: perScreen.modelData
                visible: BarConfig.showTaskbar
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "quickshell-dock"
                exclusionMode: ExclusionMode.Ignore
                focusable: false
                color: "transparent"

                anchors { bottom: true }
                implicitWidth: perScreen.zoneWidth
                implicitHeight: 4

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: perScreen.show()
                }
            }

            // The dock proper. It reaches down to the screen edge and is at
            // least as wide as the trigger strip, so the pointer arriving from
            // the strip lands inside it rather than in a gap -- and leaving it
            // sideways also leaves the strip, instead of dropping straight back
            // onto the trigger.
            PanelWindow {
                screen: perScreen.modelData
                visible: BarConfig.showTaskbar && perScreen.revealed
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "quickshell-dock"
                exclusionMode: ExclusionMode.Ignore
                focusable: false
                color: "transparent"

                anchors { bottom: true }
                implicitWidth: Math.max(card.width, perScreen.zoneWidth)
                implicitHeight: perScreen.dockHeight + perScreen.bottomMargin

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: perScreen.show()
                    onExited: hideTimer.restart()
                }

                PopupCard {
                    id: card
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    width: items.implicitWidth + Appearance.spacingNormal * 2
                    height: perScreen.dockHeight

                    Behavior on width { Anim {} }

                    DockItems {
                        id: items
                        anchors.centerIn: parent
                        shown: perScreen.revealed
                    }
                }
            }
        }
    }
}
