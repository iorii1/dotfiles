import QtQuick
import "../services"

Item {
    id: root
    implicitWidth: label.implicitWidth + 12
    implicitHeight: label.implicitHeight + 6

    readonly property string icon: {
        if (Audio.isMuted) return "󰝟"
        if (Audio.volume >= 66) return "󰕾"
        if (Audio.volume >= 33) return "󰖀"
        if (Audio.volume > 0) return "󰕿"
        return "󰸈"
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
        color: Audio.isMuted ? "#f38ba8" : (hover.hovered ? "#fab387" : "#a6e3a1")
        font.pixelSize: 14
        font.family: "JetBrainsMono Nerd Font"

        Behavior on color {
            ColorAnimation { duration: 220 }
        }
    }

    HoverHandler { id: hover }
}
