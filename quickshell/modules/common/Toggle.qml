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

        scale: fx.gestureScale
        Behavior on scale { Anim { duration: Appearance.animFast } }

        Rectangle {
            id: handle
            width: parent.height - 6
            height: parent.height - 6
            radius: height / 2
            anchors.verticalCenter: parent.verticalCenter
            x: root.checked ? parent.width - width - 3 : 3
            color: Colors.background

            Behavior on x { PopAnim { easing.overshoot: Appearance.overshootPop } }
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "#ffffff"
            opacity: fx.flashOpacity
        }

        PressFx {
            id: fx
            hoverScale: Appearance.hoverScaleSubtle
            pressScale: Appearance.pressScaleSubtle
            anchors.fill: parent
            onActivated: {
                root.checked = !root.checked
                root.toggled(root.checked)
            }
        }
    }
}
