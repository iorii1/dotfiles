import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import "../../config"
import "../../services"
import "../common"

Scope {
    // The same open/close/toggle contract every other panel has, so the dock
    // can also be brought up without the pointer -- from a keybind or a
    // script -- and not only by reaching for the bottom of the screen.
    IpcHandler {
        target: "dock"
        function toggle(): void { UiState.dockOpen = !UiState.dockOpen }
        function open(): void { UiState.dockOpen = true }
        function close(): void { UiState.dockOpen = false }
    }

    Variants {
        model: Quickshell.screens

        Scope {
            id: perScreen
            required property var modelData

            readonly property int dockHeight: 60
            readonly property int bottomMargin: Appearance.spacingSmall
            readonly property int zoneWidth: 400
            readonly property bool hasWindows: Hyprland.toplevels.values.length > 0
            readonly property bool enabled: BarConfig.showTaskbar

            // Hover is one input, the IPC pin is the other; nothing shows with
            // no windows to show, however it was asked for.
            property bool hovered: false
            readonly property bool revealed: hasWindows && (hovered || UiState.dockOpen)

            function reveal() {
                hovered = true
                // A safety net rather than the main path: the dock's own
                // MouseArea stops this the moment the pointer lands on it. If
                // that never happens -- the pointer clips the edge of the strip
                // and is gone by the time the dock maps -- there is no leave
                // event either, and without this the dock would stay up for
                // good.
                hideTimer.restart()
            }

            // A grace period, so clipping a corner on the way to an icon does
            // not dismiss the dock.
            Timer {
                id: hideTimer
                interval: 350
                onTriggered: perScreen.hovered = false
            }

            // Switching the dock off in the settings app, or closing the last
            // window, unmaps the surface the pointer is sitting on -- and an
            // unmapped surface delivers no leave. Drop the hover here, or it
            // survives to re-reveal the dock the moment the dock comes back.
            onEnabledChanged: if (!enabled) perScreen.hovered = false
            onHasWindowsChanged: if (!hasWindows) perScreen.hovered = false

            // Two windows rather than one whose mask changes. Swapping a
            // surface's input region while the pointer is inside it makes the
            // compositor re-deliver enter/leave, which flipped the reveal back
            // and forth and left the dock oscillating. Each window here keeps
            // one fixed input region for its whole life.

            // Always mapped: a thin strip at the bottom centre, the only thing
            // listening while the dock is hidden.
            PanelWindow {
                screen: perScreen.modelData
                visible: perScreen.enabled
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
                    onEntered: perScreen.reveal()
                }
            }

            // The dock proper. It reaches down to the screen edge and is at
            // least as wide as the trigger strip, so the pointer arriving from
            // the strip lands inside it rather than in a gap -- and leaving it
            // sideways also leaves the strip, instead of dropping straight back
            // onto the trigger.
            PanelWindow {
                screen: perScreen.modelData
                visible: perScreen.enabled && perScreen.revealed
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
                    onEntered: hideTimer.stop()
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
