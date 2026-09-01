import QtQuick
import QtQuick.Layouts
import Quickshell
import "../services/"

PopupWindow {
    id: root

    property bool open: false
    property alias hovered: hoverHandler.hovered
    readonly property int today: Time.date.getDate()
    readonly property real cellSize: 32

    implicitWidth: 514
    implicitHeight: 320
    color: "transparent"
    visible: open || closeHold.running

    Timer {
        id: closeHold
        interval: 180
    }
    onOpenChanged: if (!open) closeHold.start()

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

        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 18

            AnalogClock {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 220
                Layout.preferredHeight: 220
            }

            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 2
                Layout.topMargin: 8
                Layout.bottomMargin: 8
                radius: 1
                color: "#40fab387"
            }

            ColumnLayout {
            spacing: 10

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: Qt.formatDateTime(Time.date, "MMMM yyyy")
                color: "#cdd6f4"
                font.bold: true
                font.pixelSize: 15
                font.family: "JetBrainsMono Nerd Font"
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#26cdd6f4"
            }

            Grid {
                Layout.alignment: Qt.AlignHCenter
                columns: 7
                rowSpacing: 6
                columnSpacing: 0

                Repeater {
                    model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
                    Text {
                        width: root.cellSize
                        height: 18
                        text: modelData
                        color: "#7f849c"
                        font.bold: true
                        font.pixelSize: 11
                        font.family: "JetBrainsMono Nerd Font"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Repeater {
                    model: {
                        const d = Time.date;
                        const first = new Date(d.getFullYear(), d.getMonth(), 1);
                        const startOffset = first.getDay();
                        const daysInMonth = new Date(d.getFullYear(), d.getMonth() + 1, 0).getDate();
                        let cells = [];
                        for (let i = 0; i < startOffset; i++) cells.push(null);
                        for (let i = 1; i <= daysInMonth; i++) cells.push(i);
                        return cells;
                    }
                    delegate: Item {
                        width: root.cellSize
                        height: root.cellSize

                        Rectangle {
                            anchors.centerIn: parent
                            width: 22
                            height: 22
                            radius: 11
                            visible: modelData === root.today
                            color: "#f9e2af"
                        }

                        Text {
                            anchors.centerIn: parent
                            text: modelData ? modelData : ""
                            color: modelData === root.today ? "#1e1e2e" : "#cdd6f4"
                            font.bold: modelData === root.today
                            font.pixelSize: 12
                            font.family: "JetBrainsMono Nerd Font"
                        }
                    }
                }
            }
            }
        }
    }
}
