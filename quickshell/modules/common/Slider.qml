import QtQuick
import "../../config"

Item {
    id: root
    implicitHeight: 24

    property real value: 0.5
    property color accentColor: Colors.primary
    signal moved(real value)

    readonly property bool dragging: ma.pressed

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 10
        radius: 5
        color: Colors.alpha(Colors.surfaceContainerHigh, Appearance.layerOpacity)
        clip: true

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width * Math.max(0, Math.min(1, root.value))
            radius: parent.radius
            color: root.accentColor
            Behavior on width { enabled: !root.dragging; Anim { duration: Appearance.animFast } }
        }
    }

    Rectangle {
        id: handle
        width: 18
        height: 18
        radius: 9
        color: Colors.textPrimary
        border.color: root.accentColor
        border.width: 2
        anchors.verticalCenter: track.verticalCenter
        x: Math.max(0, Math.min(root.width - width, root.value * root.width - width / 2))

        scale: ma.pressed ? 1.25 : (ma.containsMouse ? 1.1 : 1.0)
        Behavior on scale { PopAnim { duration: Appearance.animFast; easing.overshoot: Appearance.overshootPop } }
        Behavior on x { enabled: !root.dragging; Anim { duration: Appearance.animFast } }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPositionChanged: if (pressed) root._setFromX(mouseX)
        onPressed: (mouse) => root._setFromX(mouse.x)
    }

    function _setFromX(x) {
        const v = Math.max(0, Math.min(1, x / root.width))
        root.value = v
        root.moved(v)
    }
}
