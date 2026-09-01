import QtQuick
import "../services"

Item {
    id: root
    implicitWidth: label.implicitWidth + 12
    implicitHeight: label.implicitHeight + 6

    readonly property string icon: {
        if (Battery.isCharging) return "󰂄"
        if (Battery.percentage >= 90) return "󰁹"
        if (Battery.percentage >= 70) return "󰂂"
        if (Battery.percentage >= 50) return "󰁿"
        if (Battery.percentage >= 30) return "󰁽"
        if (Battery.percentage >= 10) return "󰁻"
        return "󰂎"
    }

    Rectangle {
        anchors.fill: parent
        radius: 6
        color: hover.hovered ? "#26fab387" : "transparent"

        Behavior on color {
            ColorAnimation { duration: 220 }
        }
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.icon
        color: Battery.percentage < 20 ? "#f38ba8" : (hover.hovered ? "#fab387" : "#f9e2af")
        font.pixelSize: 14
        font.family: "JetBrainsMono Nerd Font"

        Behavior on color {
            ColorAnimation { duration: 220 }
        }

        SequentialAnimation on opacity {
            running: Battery.percentage < 20 && !Battery.isCharging
            loops: Animation.Infinite
            onRunningChanged: if (!running) label.opacity = 1
            NumberAnimation { to: 0.5; duration: 600; easing.type: Easing.InOutQuad }
            NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InOutQuad }
        }
    }

    HoverHandler { id: hover }
}
