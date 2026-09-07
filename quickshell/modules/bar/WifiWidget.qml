import QtQuick
import "../../config"
import "../../services"
import "../common"

Item {
    id: root
    implicitWidth: 22
    implicitHeight: 20

    readonly property string icon: {
        if (!Network.wifiEnabled || !Network.connected) return "󰤭"
        if (Network.signalStrength >= 67) return "󰤨"
        if (Network.signalStrength >= 34) return "󰤢"
        if (Network.signalStrength > 0) return "󰤟"
        return "󰤯"
    }

    scale: fx.popScale * (fx.pressed ? 0.85 : (fx.containsMouse ? 1.1 : 1.0))
    Behavior on scale { NumberAnimation { duration: Appearance.animFast; easing.type: Easing.OutQuint } }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -6
        radius: 8
        color: "#ffffff"
        opacity: fx.flashOpacity
    }

    Text {
        anchors.centerIn: parent
        text: root.icon
        color: !Network.wifiEnabled ? Colors.outline : (Network.connected ? Colors.primary : Colors.textSecondary)
        font.family: Appearance.fontFamily
        font.pixelSize: Appearance.fontSizeLarge
        Behavior on color { ColorAnimation { duration: Appearance.animFast } }
    }

    PressFx {
        id: fx
        anchors.fill: parent
        anchors.margins: -4
        onActivated: {
            UiState.quickSettingsSection = "wifi"
            UiState.quickSettingsOpen = true
            Network.scan()
        }
    }
}
