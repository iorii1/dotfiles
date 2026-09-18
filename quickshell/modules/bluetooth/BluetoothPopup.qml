import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../config"
import "../../services"
import "../common"

ShellPanel {
    id: btWindow

    name: "bluetooth"

    // Discovery is bracketed by the popup being open, like the wifi scan: BlueZ
    // only populates unpaired devices while it is running, and leaving the radio
    // scanning in the background costs power for nothing.
    onOpenChanged: open ? Bluetooth.startScan() : Bluetooth.stopScan()

    IpcHandler {
        target: "bluetooth"
        function toggle(): void { UiState.toggle("bluetooth") }
        function open(): void { UiState.show("bluetooth") }
        function close(): void { UiState.hide("bluetooth") }
    }

    PopupCard {
        id: card
        anchors.right: parent.right
        anchors.rightMargin: Appearance.spacingLarge
        readonly property int restY: BarConfig.barHeight + BarConfig.barMargin + Appearance.spacingSmall
        width: 300
        height: content.implicitHeight + Appearance.spacingNormal * 2

        opacity: UiState.bluetoothOpen ? 1 : 0
        y: UiState.bluetoothOpen ? restY : restY - 12
        scale: UiState.bluetoothOpen ? 1 : Appearance.popupFromScale
        transformOrigin: Item.TopRight
        Behavior on opacity { Anim {} }
        Behavior on y { Anim {} }
        Behavior on scale { PopAnim {} }
        Behavior on height { Anim {} }

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

                    BtDeviceRow {
                        id: pairedRow
                        required property var modelData
                        required property int index
                        width: parent ? parent.width : 0
                        device: modelData

                        scale: Appearance.popFromScale
                        opacity: 0.0
                        transformOrigin: Item.Left
                        Component.onCompleted: pairedEntrance.start()
                        PopIn { id: pairedEntrance; target: pairedRow; delay: Appearance.staggerDelay(pairedRow.index) }
                    }
                }

                Item { width: 1; height: Appearance.spacingSmall; visible: Bluetooth.discovered.length > 0 }

                RowLayout {
                    width: parent.width
                    visible: Bluetooth.powered

                    Text {
                        Layout.fillWidth: true
                        text: Bluetooth.discovering ? "Scanning…" : "Nearby"
                        color: Colors.textSecondary
                        font.family: Appearance.fontFamily
                        font.pixelSize: Appearance.fontSizeSmall
                    }
                }

                Repeater {
                    model: Bluetooth.discovered

                    BtDeviceRow {
                        required property var modelData
                        required property int index
                        width: parent ? parent.width : 0
                        device: modelData
                        discovered: true
                    }
                }

                Text {
                    width: parent.width
                    visible: Bluetooth.discovering && Bluetooth.discovered.length === 0
                    text: "No new devices yet — put the device in pairing mode."
                    color: Colors.textSecondary
                    opacity: 0.7
                    font.family: Appearance.fontFamily
                    font.pixelSize: Appearance.fontSizeSmall
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
}
