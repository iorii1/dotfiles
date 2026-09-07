import QtQuick
import "../../config"
import "../../services"

Item {
    id: root
    visible: Battery.present
    implicitWidth: visible ? rowLayout.implicitWidth : 0
    implicitHeight: 20

    readonly property color fillColor: (Battery.percent <= 15 && !Battery.charging)
        ? Colors.error
        : (Battery.charging ? Colors.primary : Colors.textPrimary)

    Row {
        id: rowLayout
        anchors.centerIn: parent
        spacing: 5

        Item {
            id: shape
            width: 22
            height: 11
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                id: outline
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width - 3
                radius: 2.5
                color: "transparent"
                border.width: 1.5
                border.color: Colors.textSecondary

                Rectangle {
                    id: fillBar
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.margins: 2
                    radius: 1
                    width: Math.max(0, (parent.width - 4) * (Battery.percent / 100))
                    color: root.fillColor
                    opacity: 1.0

                    Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 400 } }

                    SequentialAnimation on opacity {
                        running: Battery.charging
                        loops: Animation.Infinite
                        onRunningChanged: if (!running) fillBar.opacity = 1.0
                        NumberAnimation { to: 0.35; duration: 700; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1.0; duration: 700; easing.type: Easing.InOutSine }
                    }
                }
            }

            Rectangle {
                anchors.left: outline.right
                anchors.verticalCenter: parent.verticalCenter
                width: 2
                height: 5
                radius: 1
                color: Colors.textSecondary
            }
        }

        Text {
            text: Battery.percent + "%"
            color: Colors.textSecondary
            font.family: Appearance.fontFamily
            font.pixelSize: Appearance.fontSizeSmall
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
