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
            readonly property int stripHeight: 4
            // Per-screen, so an empty monitor's dock stays down while another
            // monitor has windows.
            readonly property bool hasWindows: {
                const all = Hyprland.toplevels.values
                const name = perScreen.modelData ? perScreen.modelData.name : ""
                for (let i = 0; i < all.length; i++) {
                    const mon = all[i].monitor
                    if (!mon || !name || mon.name === name) return true
                }
                return false
            }
            readonly property bool enabled: BarConfig.showTaskbar

            // Hover is one input, the IPC pin is the other; nothing shows with
            // no windows to show, however it was asked for.
            property bool hovered: false
            // Pins make the dock worth showing even with nothing running --
            // it is a launcher then, not just a switcher.
            readonly property bool hasContent: perScreen.hasWindows || DockPins.pinned.length > 0
            readonly property bool revealed: hasContent && (hovered || UiState.dockOpen)

            function reveal() {
                hovered = true
                hideTimer.stop()
                // A safety net rather than the main path: the dock's own
                // MouseArea stops this the moment the pointer lands on it. If
                // that never happens -- the pointer clips the edge of the strip
                // and is gone by the time the dock maps -- there is no leave
                // event either, and without this the dock would stay up for
                // good.
            }

            // A grace period, so clipping a corner on the way to an icon does
            // not dismiss the dock.
            Timer {
                id: hideTimer
                // Long enough to cover the handoff from the strip to the
                // dock, short enough not to leave the dock hanging around.
                interval: 400
                onTriggered: cursorCheck.running = true
            }

            // Before hiding, ask the compositor where the pointer actually is.
            //
            // Enter and leave cannot be trusted here. Hyprland re-evaluates
            // pointer focus whenever surfaces map, unmap or commit, and this
            // dock is two layer surfaces doing all three as it appears -- so
            // both of them emit leaves while the pointer stands perfectly
            // still, and with no motion to prompt it the compositor never
            // sends the matching enter. Measured: one move to the bottom edge
            // followed by four seconds of stillness produced a strip enter, a
            // strip leave and a hide, with the pointer never having left.
            //
            // The pointer's position is the ground truth. A leave only starts
            // the countdown; this has the final say. One process per
            // dismissal, not per frame.
            Process {
                id: cursorCheck
                command: ["hyprctl", "cursorpos"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        const mon = perScreen.modelData
                        const parts = text.trim().split(",")
                        const cx = parseInt(parts[0])
                        const cy = parseInt(parts[1])

                        if (!mon || parts.length < 2 || isNaN(cx) || isNaN(cy)) {
                            perScreen.hovered = false
                            return
                        }

                        // The band both surfaces occupy, in layout coordinates.
                        const bandTop = mon.y + mon.height
                            - perScreen.dockHeight - perScreen.bottomMargin
                        const centre = mon.x + mon.width / 2
                        const half = Math.max(dockWindow.width, perScreen.zoneWidth) / 2

                        const inside = cy >= bandTop
                            && cx >= centre - half && cx <= centre + half

                        if (inside) hideTimer.restart()
                        else perScreen.hovered = false
                    }
                }
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
                implicitHeight: perScreen.stripHeight

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: perScreen.reveal()
                    onExited: hideTimer.restart()
                }
            }

            // The dock proper. It sits directly on top of the trigger strip
            // rather than over it.
            //
            // These two used to overlap: the dock reached all the way to the
            // screen edge, so the bottom four pixels belonged to both surfaces
            // at once. With the pointer in that shared band the compositor
            // handed it back and forth between them as the dock committed its
            // entrance animation, and every leave restarted the hide timer.
            // Adjacent instead: the strip owns the bottom four pixels, the dock
            // owns everything above, and moving up crosses one boundary once.
            PanelWindow {
                id: dockWindow
                screen: perScreen.modelData
                visible: perScreen.enabled && perScreen.revealed
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "quickshell-dock"
                exclusionMode: ExclusionMode.Ignore
                focusable: false
                color: "transparent"

                anchors { bottom: true }
                margins.bottom: perScreen.stripHeight
                implicitWidth: Math.max(items.implicitWidth + Appearance.spacingNormal * 2,
                                        perScreen.zoneWidth)
                implicitHeight: perScreen.dockHeight + perScreen.bottomMargin
                    - perScreen.stripHeight

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
                        screenName: perScreen.modelData ? perScreen.modelData.name : ""
                    }
                }
            }
        }
    }
}
