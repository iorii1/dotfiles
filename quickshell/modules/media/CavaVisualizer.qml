import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../services"
import "../common"

Item {
    id: root

    implicitWidth: Cava.active ? barsRow.implicitWidth : 0
    implicitHeight: 24
    opacity: Cava.active ? 1 : 0
    visible: opacity > 0
    clip: true

    Behavior on implicitWidth { Anim {} }
    Behavior on opacity { NumberAnimation { duration: Appearance.animNormal } }

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
                    color: Colors.primary
                    opacity: 0.55 + parent.level * 0.45

                    Behavior on height { Anim { duration: Appearance.animFast } }
                    Behavior on opacity { NumberAnimation { duration: Appearance.animFast } }
                }
            }
        }
    }
}
