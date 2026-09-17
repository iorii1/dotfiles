import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../config"
import "../../services"
import "../common"

PanelWindow {
    id: btWindow

    visible: UiState.bluetoothOpen
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-popup"
    exclusionMode: ExclusionMode.Ignore
    focusable: false
    color: "transparent"

    anchors { top: true; bottom: true; left: true; right: true }

    IpcHandler {
        target: "bluetooth"
        function toggle(): void { UiState.bluetoothOpen = !UiState.bluetoothOpen }
        function open(): void { UiState.bluetoothOpen = true }
        function close(): void { UiState.bluetoothOpen = false }
    }

    onVisibleChanged: if (visible) Bluetooth.refresh()

    MouseArea {
        anchors.fill: parent
        onClicked: UiState.bluetoothOpen = false
    }

    PopupCard {
        id: card
        anchors.right: parent.right
        anchors.rightMargin: Appearance.spacingLarge
        readonly property int restY: Appearance.barHeight + Appearance.barMargin + Appearance.spacingSmall
        width: 300
        height: content.implicitHeight + Appearance.spacingNormal * 2

        opacity: UiState.bluetoothOpen ? 1 : 0
        y: UiState.bluetoothOpen ? restY : restY - 12
        scale: UiState.bluetoothOpen ? 1 : 0.96
        transformOrigin: Item.TopRight
        Behavior on opacity { NumberAnimation { duration: Appearance.animNormal; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: Appearance.animNormal; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: Appearance.animNormal; easing.type: Easing.OutBack; easing.overshoot: Appearance.overshootCard } }
        Behavior on height { NumberAnimation { duration: Appearance.animNormal; easing.type: Easing.OutCubic } }

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            id: content
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Appearance.spacingNormal
            spacing: Appearance.spacingNormal

            ToggleRow {
                Layout.fillWidth: true
                icon: ""
                label: "Bluetooth"
                checked: Bluetooth.powered
                active: UiState.bluetoothOpen
                entranceDelay: 0
                expandable: false
                pulsing: Bluetooth.refreshing
                onToggleRequested: Bluetooth.toggle()
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Colors.outline; opacity: 0.4 }

            Column {
                Layout.fillWidth: true
                spacing: 2
                visible: Bluetooth.powered

                Repeater {
                    model: Bluetooth.devices

                    Rectangle {
                        id: btRow
                        required property var modelData
                        required property int index
                        width: parent ? parent.width : 0
                        height: 34
                        radius: Appearance.radiusSmall
                        color: btFx.containsMouse ? Colors.surfaceContainerHigh : "transparent"
                        Behavior on color { ColorAnimation { duration: Appearance.animFast } }

                        scale: 0.85
                        opacity: 0.0
                        transformOrigin: Item.Left

                        Component.onCompleted: btEntranceAnim.start()
                        PopIn { id: btEntranceAnim; target: btRow; delay: Math.min(btRow.index * 25, 200); scaleDuration: 220; opacityDuration: 180 }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Appearance.spacingSmall
                            anchors.rightMargin: Appearance.spacingSmall
                            spacing: Appearance.spacingSmall

                            Text {
                                text: modelData.connected ? "" : ""
                                color: Colors.primary
                                font.family: Appearance.fontFamily
                                font.pixelSize: Appearance.fontSizeSmall
                                Layout.preferredWidth: 14
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.name
                                color: Colors.textPrimary
                                font.family: Appearance.fontFamily
                                font.pixelSize: Appearance.fontSizeSmall
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            id: btFx
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: modelData.connected ? Bluetooth.disconnectDevice(modelData.mac) : Bluetooth.connectDevice(modelData.mac)
                        }
                    }
                }
            }
        }
    }
}
