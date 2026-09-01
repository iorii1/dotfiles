import QtQuick
import QtQuick.Layouts
import "../services"

Item {
    id: root

    implicitWidth: barsRow.implicitWidth
    implicitHeight: 18

    Component.onCompleted: Cava.registerConsumer()
    Component.onDestruction: Cava.unregisterConsumer()

    Row {
        id: barsRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Repeater {
            model: Cava.barCount

            Item {
                required property int index
                readonly property real level: Cava.barLevels[index] || 0

                width: 3
                height: 18

                Rectangle {
                    width: parent.width
                    radius: 1.5
                    anchors.bottom: parent.bottom
                    height: Math.max(2, parent.level * 18)
                    color: Qt.tint("#fab387", Qt.rgba(1, 1, 1, parent.level * 0.5))
                    opacity: 0.55 + parent.level * 0.45

                    Behavior on height {
                        NumberAnimation { duration: 130; easing.type: Easing.OutCubic }
                    }
                    Behavior on opacity {
                        NumberAnimation { duration: 130 }
                    }
                }
            }
        }
    }
}
