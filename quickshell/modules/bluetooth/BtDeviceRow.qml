import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../services"
import "../common"

// One Bluetooth device, paired or not. The pairing case is the reason this
// exists: the popup previously listed only paired devices and had no way to
// bond a new one.
Rectangle {
    id: root

    property var device: null
    property bool discovered: false

    readonly property bool connected: !!root.device && root.device.connected
    readonly property bool pairing: !!root.device && root.device.pairing
    readonly property bool hasBattery: !!root.device && root.device.batteryAvailable

    height: 34
    radius: Appearance.radiusSmall
    color: fx.containsMouse ? Colors.surfaceContainerHigh : "transparent"
    Behavior on color { ColorAnimation { duration: Appearance.animFast } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Appearance.spacingSmall
        anchors.rightMargin: Appearance.spacingSmall
        spacing: Appearance.spacingSmall

        Text {
            Layout.preferredWidth: 14
            text: Bluetooth.iconFor(root.device)
            color: root.connected ? Colors.primary : Colors.textSecondary
            font.family: Appearance.fontFamilyIcons
            font.pixelSize: Appearance.fontSizeSmall
            Behavior on color { ColorAnimation { duration: Appearance.animFast } }
        }

        Text {
            Layout.fillWidth: true
            text: Bluetooth.displayName(root.device)
            color: root.connected ? Colors.primary : Colors.textPrimary
            font.family: Appearance.fontFamily
            font.pixelSize: Appearance.fontSizeSmall
            font.bold: root.connected
            elide: Text.ElideRight
        }

        // Headsets report their charge over BlueZ; it was never shown.
        Text {
            visible: root.hasBattery && root.connected
            text: Math.round((root.device ? root.device.battery : 0) * 100) + "%"
            color: Colors.textSecondary
            font.family: Appearance.fontFamily
            font.pixelSize: Appearance.fontSizeSmall
        }

        Text {
            visible: root.pairing
            text: "pairing…"
            color: Colors.textSecondary
            font.family: Appearance.fontFamily
            font.pixelSize: Appearance.fontSizeSmall
        }

        Text {
            visible: fx.containsMouse && !root.discovered && !root.pairing
            text: "forget"
            color: Colors.error
            font.family: Appearance.fontFamily
            font.pixelSize: Appearance.fontSizeSmall

            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                cursorShape: Qt.PointingHandCursor
                onClicked: Bluetooth.forget(root.device)
            }
        }
    }

    MouseArea {
        id: fx
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        z: -1
        onClicked: {
            if (root.pairing) {
                Bluetooth.cancelPair(root.device)
            } else if (root.discovered) {
                Bluetooth.pair(root.device)
            } else if (root.connected) {
                Bluetooth.disconnectDevice(root.device)
            } else {
                Bluetooth.connectDevice(root.device)
            }
        }
    }
}
