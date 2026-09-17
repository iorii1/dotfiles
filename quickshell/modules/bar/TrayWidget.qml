import QtQuick
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "../../config"
import "../common"

Item {
    id: root

    implicitWidth: SystemTray.items.values.length > 0 ? row.implicitWidth : 0
    implicitHeight: 20
    clip: true

    Behavior on implicitWidth { NumberAnimation { duration: Appearance.animNormal; easing.type: Easing.OutCubic } }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: Appearance.spacingSmall

        Repeater {
            model: SystemTray.items

            Item {
                id: trayItem
                required property var modelData

                width: 18
                height: 18

                opacity: 0
                NumberAnimation on opacity { to: 1.0; duration: 260; easing.type: Easing.OutQuad }

                scale: fx.popScale * (fx.pressed ? 0.85 : (fx.containsMouse ? 1.1 : 1.0))
                Behavior on scale { NumberAnimation { duration: Appearance.animFast; easing.type: Easing.OutQuint } }

                IconImage {
                    anchors.fill: parent
                    source: trayItem.modelData.icon
                    asynchronous: true
                }

                PressFx {
                    id: fx
                    anchors.fill: parent
                    anchors.margins: -4
                    onActivated: trayItem.modelData.activate()
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton
                    onClicked: trayItem.modelData.secondaryActivate()
                }
            }
        }
    }
}
