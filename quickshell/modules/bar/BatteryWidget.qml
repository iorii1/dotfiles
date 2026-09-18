import QtQuick
import "../../config"
import "../../services"
import "../common"

Item {
    id: root
    visible: Battery.present
    implicitWidth: visible ? rowLayout.implicitWidth : 0
    implicitHeight: 20

    readonly property color fillColor: (Battery.percent <= 15 && !Battery.charging)
        ? Colors.error
        : (Battery.charging ? Colors.primary : Colors.textPrimary)

    scale: fx.gestureScale
    Behavior on scale { Anim { duration: Appearance.animFast } }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -6
        radius: 8
        color: "#ffffff"
        opacity: fx.flashOpacity
    }

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

                    Behavior on width { Anim { duration: Appearance.animSlow } }
                    Behavior on color { ColorAnimation { duration: Appearance.animSlow } }

                    SequentialAnimation on opacity {
                        running: Battery.charging
                        loops: Animation.Infinite
                        onRunningChanged: if (!running) fillBar.opacity = 1.0
                        NumberAnimation { to: 0.35; duration: Appearance.animAmbient; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1.0; duration: Appearance.animAmbient; easing.type: Easing.InOutSine }
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

    PressFx {
        id: fx
        anchors.fill: parent
        anchors.margins: -4
        onActivated: UiState.batteryOpen = !UiState.batteryOpen
    }
}
