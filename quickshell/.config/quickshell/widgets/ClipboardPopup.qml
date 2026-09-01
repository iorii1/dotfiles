import QtQuick
import QtQuick.Layouts
import Quickshell
import "../services"

PopupWindow {
    id: root

    property bool open: false

    implicitWidth: 340
    implicitHeight: 440
    color: "transparent"
    visible: open || closeHold.running

    Timer {
        id: closeHold
        interval: 180
    }
    onOpenChanged: {
        if (open) Clipboard.refresh()
        else closeHold.start()
    }

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

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            RowLayout {
                Layout.fillWidth: true

                Text {
                    Layout.fillWidth: true
                    text: "Clipboard History"
                    color: "#cdd6f4"
                    font.bold: true
                    font.pixelSize: 14
                    font.family: "JetBrainsMono Nerd Font"
                }

                Text {
                    text: "󰃢 Clear"
                    color: clearHover.hovered ? "#f38ba8" : "#7f849c"
                    font.pixelSize: 11
                    font.family: "JetBrainsMono Nerd Font"

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }

                    HoverHandler { id: clearHover }
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Clipboard.clearAll()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#26cdd6f4"
            }

            Text {
                Layout.fillWidth: true
                Layout.topMargin: 30
                visible: Clipboard.entries.length === 0
                horizontalAlignment: Text.AlignHCenter
                text: "Nothing copied yet"
                color: "#7f849c"
                font.pixelSize: 12
                font.family: "JetBrainsMono Nerd Font"
            }

            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 6
                model: Clipboard.entries
                visible: Clipboard.entries.length > 0
                boundsBehavior: Flickable.StopAtBounds

                delegate: Rectangle {
                    required property var modelData
                    width: ListView.view.width
                    height: 40
                    radius: 8
                    color: entryHover.hovered ? "#26fab387" : "#141e1e2e"

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }

                    HoverHandler { id: entryHover }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Clipboard.copyEntry(modelData.id)
                            root.open = false
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 8
                        spacing: 8

                        Text {
                            text: modelData.isImage ? "󰋫" : "󰅍"
                            color: "#fab387"
                            font.pixelSize: 13
                            font.family: "JetBrainsMono Nerd Font"
                        }

                        Text {
                            Layout.fillWidth: true
                            text: modelData.isImage ? "Image" : modelData.preview
                            color: "#cdd6f4"
                            font.pixelSize: 12
                            font.family: "JetBrainsMono Nerd Font"
                            elide: Text.ElideRight
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
                                onClicked: Clipboard.deleteEntry(modelData.id)
                            }
                        }
                    }
                }
            }
        }
    }
}
