import QtQuick
import "../services"

Item {
    id: root
    property var barWindow

    implicitWidth: row.implicitWidth + 12
    implicitHeight: 20

    readonly property bool highlighted: hover.hovered || popup.open
    readonly property int count: Notifications.history.length

    Rectangle {
        anchors.fill: parent
        radius: 6
        color: root.highlighted ? "#26fab387" : "transparent"

        Behavior on color {
            ColorAnimation { duration: 220 }
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 4

        Text {
            text: root.count > 0 ? "󰂚" : "󰂜"
            color: root.highlighted ? "#fab387" : "#cdd6f4"
            font.pixelSize: 14
            font.family: "JetBrainsMono Nerd Font"

            Behavior on color {
                ColorAnimation { duration: 220 }
            }
        }

        Text {
            visible: root.count > 0
            text: root.count > 9 ? "9+" : root.count
            color: root.highlighted ? "#fab387" : "#a6adc8"
            font.pixelSize: 11
            font.family: "JetBrainsMono Nerd Font"
        }
    }

    HoverHandler { id: hover }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
    }

    NotificationPopup {
        id: popup
        parentWindow: barWindow
        open: hover.hovered || popup.hovered

        readonly property real barRelativeX: {
            void root.x; void root.y; void root.width; void root.height
            return root.mapToItem(null, 0, 0).x
        }

        relativeX: popup.barRelativeX + (root.width - popup.implicitWidth) / 2
        relativeY: (barWindow ? barWindow.height : 34) + 8
    }
}
