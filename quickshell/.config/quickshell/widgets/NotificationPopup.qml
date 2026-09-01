import QtQuick
import QtQuick.Layouts
import Quickshell
import "../services"

PopupWindow {
    id: root

    property bool open: false
    property alias hovered: hoverHandler.hovered

    implicitWidth: 340
    implicitHeight: 440
    color: "transparent"
    visible: open || closeHold.running

    Timer {
        id: closeHold
        interval: 180
    }
    onOpenChanged: {
        if (open) Notifications.refresh()
        else closeHold.start()
    }

    HoverHandler { id: hoverHandler }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: 14
        color: "#e61e1e2e"
        border.width: 1
        border.color: "#33cdd6f4"
        clip: true

        opacity: root.open ? 1 : 0
        scale: root.open ? 1 : 0.92
        transformOrigin: Item.Top

        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: 260; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
        }

        Text {
            id: headerText
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 14
            text: "Notifications"
            color: "#cdd6f4"
            font.bold: true
            font.pixelSize: 14
            font.family: "JetBrainsMono Nerd Font"
        }

        Rectangle {
            id: divider
            anchors.top: headerText.bottom
            anchors.topMargin: 10
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            height: 1
            color: "#26cdd6f4"
        }

        Text {
            anchors.top: divider.bottom
            anchors.topMargin: 30
            anchors.left: parent.left
            anchors.right: parent.right
            visible: Notifications.history.length === 0
            horizontalAlignment: Text.AlignHCenter
            text: "No notifications yet"
            color: "#7f849c"
            font.pixelSize: 12
            font.family: "JetBrainsMono Nerd Font"
        }

        ListView {
            anchors.top: divider.bottom
            anchors.topMargin: 10
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 14
            clip: true
            spacing: 6
            model: Notifications.history
            visible: Notifications.history.length > 0
            boundsBehavior: Flickable.StopAtBounds

            delegate: Rectangle {
                required property var modelData
                width: ListView.view.width
                height: bodyText.text.length > 0 ? 58 : 40
                radius: 8
                color: "#141e1e2e"
                border.width: modelData.urgency === "critical" ? 1 : 0
                border.color: "#f38ba8"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    anchors.topMargin: 6
                    anchors.bottomMargin: 6
                    spacing: 1

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            text: modelData.urgency === "critical" ? "󰀪" : "󰂚"
                            color: modelData.urgency === "critical" ? "#f38ba8" : "#fab387"
                            font.pixelSize: 12
                            font.family: "JetBrainsMono Nerd Font"
                        }

                        Text {
                            Layout.fillWidth: true
                            text: modelData.summary || modelData.app_name || "Notification"
                            color: "#cdd6f4"
                            font.bold: true
                            font.pixelSize: 12
                            font.family: "JetBrainsMono Nerd Font"
                            elide: Text.ElideRight
                        }

                        Text {
                            text: modelData.app_name || ""
                            color: "#7f849c"
                            font.pixelSize: 10
                            font.family: "JetBrainsMono Nerd Font"
                        }

                        Text {
                            text: "󰆴"
                            color: delHover.hovered ? "#f38ba8" : "#7f849c"
                            font.pixelSize: 13
                            font.family: "JetBrainsMono Nerd Font"

                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }

                            HoverHandler { id: delHover }
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -6
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Notifications.hideEntry(modelData.id)
                            }
                        }
                    }

                    Text {
                        id: bodyText
                        Layout.fillWidth: true
                        Layout.leftMargin: 18
                        text: modelData.body || ""
                        color: "#a6adc8"
                        font.pixelSize: 11
                        font.family: "JetBrainsMono Nerd Font"
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
