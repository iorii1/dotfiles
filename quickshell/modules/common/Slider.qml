import QtQuick
import "../../config"

Item {
    id: root
    implicitHeight: 24

    property real value: 0.5
    property color accentColor: Colors.primary
    signal moved(real value)

    // Arrow-key step. Home/End jump to the ends, PageUp/PageDown take a
    // coarser bite -- the same vocabulary a scrollbar uses.
    property real stepSize: 0.05
    property real pageSize: 0.2

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

        // Rings the handle rather than the whole track, so a focused slider
        // reads as "this thumb will move" instead of "this row is selected".
        Rectangle {
            anchors.centerIn: parent
            width: parent.width + 8
            height: parent.height + 8
            radius: width / 2
            color: "transparent"
            border.width: 2
            border.color: Colors.primary
            opacity: ma.activeFocus ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { Anim { duration: Appearance.animFast } }
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        activeFocusOnTab: true
        onPositionChanged: if (pressed) root._setFromX(mouseX)
        onPressed: (mouse) => root._setFromX(mouse.x)

        Keys.onPressed: (event) => {
            switch (event.key) {
            case Qt.Key_Left:
            case Qt.Key_Down:
                root._nudge(-root.stepSize); break
            case Qt.Key_Right:
            case Qt.Key_Up:
                root._nudge(root.stepSize); break
            case Qt.Key_PageDown:
                root._nudge(-root.pageSize); break
            case Qt.Key_PageUp:
                root._nudge(root.pageSize); break
            case Qt.Key_Home:
                root._commit(0); break
            case Qt.Key_End:
                root._commit(1); break
            default:
                return
            }
            event.accepted = true
        }
    }

    function _commit(v) {
        const c = Math.max(0, Math.min(1, v))
        root.value = c
        root.moved(c)
    }

    function _nudge(delta) {
        root._commit(root.value + delta)
    }

    function _setFromX(x) {
        root._commit(x / root.width)
    }
}
