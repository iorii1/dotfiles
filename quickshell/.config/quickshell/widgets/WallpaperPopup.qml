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
        if (open) Wallpaper.scan()
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

            Text {
                Layout.fillWidth: true
                text: "Wallpaper"
                color: "#cdd6f4"
                font.bold: true
                font.pixelSize: 14
                font.family: "JetBrainsMono Nerd Font"
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#26cdd6f4"
            }

            Text {
                Layout.fillWidth: true
                Layout.topMargin: 30
                visible: Wallpaper.items.length === 0
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: "Drop images or videos into\n~/Pictures/Wallpapers"
                color: "#7f849c"
                font.pixelSize: 12
                font.family: "JetBrainsMono Nerd Font"
            }

            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 6
                model: Wallpaper.items
                visible: Wallpaper.items.length > 0
                boundsBehavior: Flickable.StopAtBounds

                delegate: Rectangle {
                    required property var modelData
                    readonly property bool isCurrent: modelData.path === Wallpaper.currentPath

                    width: ListView.view.width
                    height: 44
                    radius: 8
                    color: isCurrent ? "#26fab387" : (entryHover.hovered ? "#141e1e2e" : "transparent")
                    border.width: isCurrent ? 1 : 0
                    border.color: "#fab387"

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }

                    HoverHandler { id: entryHover }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Wallpaper.apply(modelData.path)
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 10

                        Rectangle {
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            radius: 6
                            color: "#141e1e2e"
                            clip: true

                            Image {
                                anchors.fill: parent
                                source: modelData.isVideo ? "" : "file://" + modelData.path
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                visible: status === Image.Ready
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: modelData.isVideo
                                text: "󰕧"
                                color: "#fab387"
                                font.pixelSize: 14
                                font.family: "JetBrainsMono Nerd Font"
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: modelData.name
                            color: "#cdd6f4"
                            font.pixelSize: 12
                            font.family: "JetBrainsMono Nerd Font"
                            elide: Text.ElideRight
                        }

                        Text {
                            visible: isCurrent
                            text: "󰄬"
                            color: "#fab387"
                            font.pixelSize: 13
                            font.family: "JetBrainsMono Nerd Font"
                        }
                    }
                }
            }
        }
    }
}
