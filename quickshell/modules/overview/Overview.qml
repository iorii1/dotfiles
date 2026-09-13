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
        Hyprland.dispatch("workspace " + workspaceId)
    }

    function focusWindow(address) {
        UiState.overviewOpen = false
        Hyprland.dispatch("focuswindow address:" + address)
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
                    width: 260
                    height: 170

                    scale: 0.9
                    opacity: 0
                    Component.onCompleted: entranceAnim.start()
                    PopIn { id: entranceAnim; target: tile; delay: Math.min(index * 40, 200) }

                    Rectangle {
                        anchors.fill: parent
                        radius: Appearance.radiusLarge
                        color: "transparent"
                        border.width: tile.modelData.focused ? 2 : 0
                        border.color: Colors.primary
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Appearance.spacingNormal
                        spacing: Appearance.spacingSmall

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                Layout.fillWidth: true
                                text: tile.modelData.name || ("Workspace " + tile.modelData.id)
                                color: tile.modelData.focused ? Colors.primary : Colors.textPrimary
                                font.family: Appearance.fontFamily
                                font.bold: true
                                font.pixelSize: Appearance.fontSizeNormal
                                elide: Text.ElideRight
                            }
                        }

                        Text {
                            visible: tile.modelData.toplevels.values.length === 0
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                            text: "Empty"
                            color: Colors.textSecondary
                            font.family: Appearance.fontFamily
                            font.pixelSize: Appearance.fontSizeSmall
                        }

                        Flow {
                            visible: tile.modelData.toplevels.values.length > 0
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: Appearance.spacingSmall

                            Repeater {
                                model: tile.modelData.toplevels

                                Rectangle {
                                    id: chip
                                    required property var modelData
                                    width: Math.min(220, chipLabel.implicitWidth + 36)
                                    height: 26
                                    radius: Appearance.radiusSmall
                                    color: chipFx.containsMouse ? Colors.surfaceContainerHigh : Colors.surfaceContainer
                                    Behavior on color { ColorAnimation { duration: Appearance.animFast } }

                                    scale: chipFx.popScale * (chipFx.pressed ? 0.92 : 1.0)
                                    Behavior on scale { NumberAnimation { duration: Appearance.animFast; easing.type: Easing.OutQuint } }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: Appearance.spacingSmall
                                        anchors.rightMargin: Appearance.spacingSmall
                                        spacing: 4

                                        Image {
                                            Layout.preferredWidth: 14
                                            Layout.preferredHeight: 14
                                            source: chip.modelData.wayland && chip.modelData.wayland.appId
                                                ? "image://icon/" + chip.modelData.wayland.appId : ""
                                            fillMode: Image.PreserveAspectFit
                                            asynchronous: true
                                        }

                                        Text {
                                            id: chipLabel
                                            Layout.fillWidth: true
                                            text: chip.modelData.title || "Window"
                                            color: Colors.textPrimary
                                            font.family: Appearance.fontFamily
                                            font.pixelSize: Appearance.fontSizeSmall
                                            elide: Text.ElideRight
                                        }
                                    }

                                    PressFx {
                                        id: chipFx
                                        anchors.fill: parent
                                        onActivated: overviewWindow.focusWindow(chip.modelData.address)
                                    }
                                }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        z: -1
                        onClicked: overviewWindow.goTo(tile.modelData.id)
                    }
                }
            }
        }
    }
}
