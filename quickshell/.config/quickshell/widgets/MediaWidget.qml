import QtQuick
import "../services"

Item {
    id: root
    property var barWindow

    implicitWidth: row.implicitWidth + 12
    implicitHeight: 26
    visible: Mpris.hasPlayer

    readonly property bool highlighted: hover.hovered || popup.open

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
        spacing: 6

        Text {
            text: Mpris.isPlaying ? "󰝚" : "󰏤"
            color: root.highlighted ? "#fab387" : "#cba6f7"
            font.pixelSize: 13
            font.family: "JetBrainsMono Nerd Font"

            Behavior on color {
                ColorAnimation { duration: 220 }
            }
        }

        Text {
            text: Mpris.title || ""
            color: root.highlighted ? "#fab387" : "#cdd6f4"
            font.pixelSize: 13
            font.family: "JetBrainsMono Nerd Font"
            elide: Text.ElideRight
            width: Math.min(implicitWidth, 130)

            Behavior on color {
                ColorAnimation { duration: 220 }
            }
        }
    }

    HoverHandler {
        id: hover
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton) Mpris.playPause()
        }
    }

    MediaPopup {
        id: popup
        parentWindow: barWindow
        open: hover.hovered || popup.hovered

        // root sits inside a RowLayout, so root.x is relative to that row, not
        // the bar itself - map into the bar window's own coordinate system.
        // mapToItem() is a plain invokable, not a bindable property, so it
        // doesn't reliably retrigger this binding on its own - reading
        // root.x/y/width/height explicitly forces a real dependency.
        readonly property real barRelativeX: {
            void root.x; void root.y; void root.width; void root.height
            return root.mapToItem(null, 0, 0).x
        }

        relativeX: popup.barRelativeX + (root.width - popup.implicitWidth) / 2
        relativeY: (barWindow ? barWindow.height : 34) + 8
    }
}
