import QtQuick
import "../services"

Item {
    id: root
    property var barWindow

    implicitWidth: label.implicitWidth + 12
    implicitHeight: label.implicitHeight + 6

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
        text: Time.time
        color: hover.hovered ? "#fab387" : "#ffffff"
        font.pixelSize: 14
        font.family: "JetBrainsMono Nerd Font"
        renderType: Text.NativeRendering

        Behavior on color {
            ColorAnimation { duration: 220 }
        }
    }

    HoverHandler {
        id: hover
    }

    CalendarWidget {
        id: calendar
        parentWindow: barWindow
        open: hover.hovered || calendar.hovered

        relativeX: root.x + (root.width - calendar.implicitWidth) / 2
        relativeY: root.y + root.height + 8
    }
}
