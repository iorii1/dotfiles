import QtQuick

MouseArea {
    id: root

    hoverEnabled: true
    cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

    // Bind a sibling Rectangle's `scale` to popScale and give it a white
    // overlay Rectangle with `opacity: flashOpacity` to get the full effect.
    property real popScale: 1.0
    property real flashOpacity: 0.0
    property int flashDuration: 350
    property real popOvershoot: 1.6

    signal activated()

    SequentialAnimation {
        id: popAnim
        NumberAnimation { target: root; property: "popScale"; to: 0.92; duration: 90; easing.type: Easing.OutQuad }
        NumberAnimation { target: root; property: "popScale"; to: 1.0; duration: 320; easing.type: Easing.OutBack; easing.overshoot: root.popOvershoot }
    }

    PropertyAnimation {
        id: flashAnim
        target: root
        property: "flashOpacity"
        to: 0.0
        duration: root.flashDuration
        easing.type: Easing.OutExpo
    }

    onClicked: {
        popAnim.restart()
        root.flashOpacity = 0.35
        flashAnim.restart()
        root.activated()
    }
}
