import QtQuick
import "../../config"

MouseArea {
    id: root

    hoverEnabled: true
    cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

    // Bind a sibling Rectangle's `scale` to gestureScale and give it a white
    // overlay Rectangle with `opacity: flashOpacity` to get the full effect.
    // Targets bigger than an icon take the subtle tier; ones that should not
    // grow under the cursor at all set hoverScale: 1.0.
    property real hoverScale: Appearance.hoverScale
    property real pressScale: Appearance.pressScale

    // popScale is the click animation -- a dip and a spring back -- and is
    // multiplied with the hovered and held-down sizes, which are steady rather
    // than timed. Animate the target's `scale` with a Behavior, never a
    // PropertyAnimation, which would tear this binding down the first time it ran.
    property real popScale: 1.0
    readonly property real gestureScale: root.popScale
        * (root.pressed ? root.pressScale : (root.containsMouse ? root.hoverScale : 1.0))

    property real flashOpacity: 0.0
    property int flashDuration: Appearance.animSlow
    property real popOvershoot: Appearance.overshootPop

    signal activated()

    // ---- Keyboard ----------------------------------------------------------
    //
    // Space and Return run exactly the same pop + flash + activated() path the
    // pointer does, so every control built on PressFx became Tab-reachable
    // without any of its call sites changing.
    //
    // A MouseArea does not take focus when it is clicked, so activeFocus here
    // only ever means the keyboard put it there -- which is precisely when the
    // ring should show, and why it needs no separate "focused by tab" flag.
    activeFocusOnTab: root.enabled

    // Drawn at the MouseArea's own bounds, so a PressFx with negative anchor
    // margins rings its hit area rather than the artwork inside it. Match it to
    // the target's corner where they differ.
    property real focusRadius: Appearance.radiusNormal
    property color focusColor: Colors.primary

    Rectangle {
        anchors.fill: parent
        radius: root.focusRadius
        color: "transparent"
        border.width: 2
        border.color: root.focusColor
        opacity: root.activeFocus ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { Anim { duration: Appearance.animFast } }
    }

    Keys.onPressed: (event) => {
        if (event.isAutoRepeat) return
        if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root._activate()
            event.accepted = true
        }
    }

    function _activate() {
        popAnim.restart()
        root.flashOpacity = 0.35
        flashAnim.restart()
        root.activated()
    }

    SequentialAnimation {
        id: popAnim
        NumberAnimation {
            target: root
            property: "popScale"
            to: Appearance.pressDip
            duration: Appearance.animInstant
            easing.type: Easing.Bezier
            easing.bezierCurve: Appearance.easeAccelerate
        }
        NumberAnimation {
            target: root
            property: "popScale"
            to: 1.0
            duration: Appearance.animSlow
            easing.type: Easing.OutBack
            easing.overshoot: root.popOvershoot
        }
    }

    PropertyAnimation {
        id: flashAnim
        target: root
        property: "flashOpacity"
        to: 0.0
        duration: root.flashDuration
        easing.type: Easing.Bezier
        easing.bezierCurve: Appearance.easeAccelerate
    }

    onClicked: root._activate()
}
