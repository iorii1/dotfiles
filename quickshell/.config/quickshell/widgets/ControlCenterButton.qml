import QtQuick
import "../services"

Item {
    id: root
    property var barWindow

    implicitWidth: icon.implicitWidth + 12
    implicitHeight: icon.implicitHeight + 6

    Rectangle {
        anchors.fill: parent
        radius: 6
        color: (hover.hovered || panel.open) ? "#26fab387" : "transparent"

        Behavior on color {
            ColorAnimation { duration: 220 }
        }
    }

    Text {
        id: icon
        anchors.centerIn: parent
        text: "󰒓"
        color: hover.hovered || panel.open ? "#fab387" : "#ffffff"
        font.pixelSize: 14
        font.family: "JetBrainsMono Nerd Font"

        Behavior on color {
            ColorAnimation { duration: 220 }
        }
    }

    HoverHandler {
        id: hover
    }

    ControlCenterPanel {
        id: panel
        parentWindow: barWindow
        open: hover.hovered || panel.hovered

        relativeX: barWindow.width - panel.implicitWidth - 14
        relativeY: barWindow.height + 8
    }
}
