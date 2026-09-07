import QtQuick
import "../../config"

Item {
    id: root
    implicitWidth: 44
    implicitHeight: 24

    property bool checked: false
    signal toggled(bool checked)

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? Colors.primary : Colors.surfaceContainerHigh
        Behavior on color { ColorAnimation { duration: Appearance.animFast } }

        scale: fx.popScale * (fx.pressed ? 0.94 : (fx.containsMouse ? 1.05 : 1.0))
        Behavior on scale { NumberAnimation { duration: Appearance.animFast; easing.type: Easing.OutQuint } }

        Rectangle {
            id: handle
            width: parent.height - 6
            height: parent.height - 6
            radius: height / 2
            anchors.verticalCenter: parent.verticalCenter
            x: root.checked ? parent.width - width - 3 : 3
            color: Colors.background

            Behavior on x { NumberAnimation { duration: Appearance.animNormal; easing.type: Easing.OutBack; easing.overshoot: 1.3 } }
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "#ffffff"
            opacity: fx.flashOpacity
        }

        PressFx {
            id: fx
            anchors.fill: parent
            onActivated: {
                root.checked = !root.checked
                root.toggled(root.checked)
            }
        }
    }
}
