import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../config"
import "../../services"
import "../common"

PanelWindow {
    id: overviewWindow

    visible: UiState.overviewOpen
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-popup"
    WlrLayershell.keyboardFocus: UiState.overviewOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    anchors { top: true; bottom: true; left: true; right: true }

    IpcHandler {
        target: "overview"
        function toggle(): void { UiState.overviewOpen = !UiState.overviewOpen }
        function open(): void { UiState.overviewOpen = true }
        function close(): void { UiState.overviewOpen = false }
    }

    function goTo(workspaceId) {
        UiState.overviewOpen = false
        Compositor.focusWorkspace(workspaceId)
    }

    function focusWindow(address) {
        UiState.overviewOpen = false
        Compositor.focusWindow(address)
    }

    MouseArea {
        anchors.fill: parent
        onClicked: UiState.overviewOpen = false
    }

    Item {
        anchors.centerIn: parent
        width: grid.implicitWidth
        height: grid.implicitHeight

        opacity: UiState.overviewOpen ? 1 : 0
        scale: UiState.overviewOpen ? 1 : 0.92
        Behavior on opacity { NumberAnimation { duration: Appearance.animNormal; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: Appearance.animNormal; easing.type: Easing.OutBack; easing.overshoot: Appearance.overshootCard } }

        Grid {
            id: grid
            columns: Math.max(1, Math.min(4, Hyprland.workspaces.values.length))
            spacing: Appearance.spacingNormal

            Repeater {
                model: Hyprland.workspaces

                PopupCard {
                    id: tile
                    required property var modelData
                    required property int index
                    width: 320
                    height: 220

                    readonly property bool hovered: tileHoverFx.containsMouse

                    scale: 0.9
                    opacity: 0
                    Component.onCompleted: entranceAnim.start()
                    PopIn { id: entranceAnim; target: tile; delay: Math.min(index * 40, 200) }

                    MouseArea {
                        id: tileHoverFx
                        anchors.fill: parent
                        hoverEnabled: true
                        z: -1
                        onClicked: overviewWindow.goTo(tile.modelData.id)
                    }

                    // "Screen" inset, like a monitor bezel around the windows.
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 8
                        radius: Appearance.radiusNormal
                        color: Colors.background
                        opacity: tile.hovered ? 1.0 : 0.92
                        Behavior on opacity { NumberAnimation { duration: Appearance.animFast } }
                    }

                    Rectangle {
                        id: focusBorder
                        anchors.fill: parent
                        radius: Appearance.radiusLarge
                        color: "transparent"
                        border.width: tile.modelData.focused ? 2 : (tile.hovered ? 1 : 0)
                        border.color: Colors.primary
                        opacity: tile.modelData.focused ? glowOpacity : 1.0
                        Behavior on border.width { NumberAnimation { duration: Appearance.animFast } }

                        property real glowOpacity: 1.0
                        SequentialAnimation {
                            running: tile.modelData.focused
                            loops: Animation.Infinite
                            NumberAnimation { target: focusBorder; property: "glowOpacity"; to: 0.5; duration: 1100; easing.type: Easing.InOutSine }
                            NumberAnimation { target: focusBorder; property: "glowOpacity"; to: 1.0; duration: 1100; easing.type: Easing.InOutSine }
                        }
                    }

                    Item {
                        visible: tile.modelData.toplevels.values.length === 0
                        anchors.fill: parent
                        anchors.margins: 8

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 2

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: ""
                                color: Colors.textSecondary
                                opacity: 0.35
                                font.family: Appearance.fontFamilyIcons
                                font.pixelSize: 30
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "Empty"
                                color: Colors.textSecondary
                                opacity: 0.6
                                font.family: Appearance.fontFamily
                                font.pixelSize: Appearance.fontSizeSmall
                            }
                        }
                    }

                    Flow {
                        visible: tile.modelData.toplevels.values.length > 0
                        anchors.fill: parent
                        anchors.margins: Appearance.spacingNormal + 8
                        spacing: Appearance.spacingNormal

                        Repeater {
                            model: tile.modelData.toplevels

                            ColumnLayout {
                                id: winTile
                                required property var modelData
                                required property int index
                                width: 60
                                spacing: 4

                                scale: 0.7
                                opacity: 0
                                Component.onCompleted: winEntranceAnim.start()
                                PopIn { id: winEntranceAnim; target: winTile; delay: Math.min(winTile.index * 35, 240); fromScale: 0.7; overshoot: 1.8 }

                                Rectangle {
                                    id: iconBg
                                    Layout.alignment: Qt.AlignHCenter
                                    width: 48
                                    height: 48
                                    radius: Appearance.radiusNormal
                                    color: winFx.containsMouse ? Colors.surfaceContainerHigh : Colors.surfaceContainer
                                    Behavior on color { ColorAnimation { duration: Appearance.animFast } }

                                    scale: winFx.popScale * (winFx.pressed ? 0.9 : 1.0)
                                    Behavior on scale { NumberAnimation { duration: Appearance.animFast; easing.type: Easing.OutQuint } }

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: parent.radius
                                        color: "#ffffff"
                                        opacity: winFx.flashOpacity
                                    }

                                    Image {
                                        anchors.centerIn: parent
                                        width: 26
                                        height: 26
                                        source: winTile.modelData.wayland && winTile.modelData.wayland.appId
                                            ? "image://icon/" + winTile.modelData.wayland.appId : ""
                                        fillMode: Image.PreserveAspectFit
                                        asynchronous: true
                                    }

                                    PressFx {
                                        id: winFx
                                        anchors.fill: parent
                                        onActivated: overviewWindow.focusWindow(winTile.modelData.address)
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignHCenter
                                    horizontalAlignment: Text.AlignHCenter
                                    text: winTile.modelData.title || "Window"
                                    color: Colors.textSecondary
                                    font.family: Appearance.fontFamily
                                    font.pixelSize: 10
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                }
                            }
                        }
                    }

                    // Corner badge with the workspace number/name.
                    Rectangle {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.margins: 10
                        implicitWidth: badgeLabel.implicitWidth + 14
                        implicitHeight: 22
                        radius: implicitHeight / 2
                        color: tile.modelData.focused ? Colors.primary : Colors.surfaceContainerHigh

                        Text {
                            id: badgeLabel
                            anchors.centerIn: parent
                            text: tile.modelData.name || ("" + tile.modelData.id)
                            color: tile.modelData.focused ? Colors.primaryText : Colors.textPrimary
                            font.family: Appearance.fontFamily
                            font.bold: true
                            font.pixelSize: Appearance.fontSizeSmall
                        }
                    }
                }
            }
        }
    }
}
