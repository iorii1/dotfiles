import QtQuick
import "../../config"
import "../../services"
import "../common"

// Opens the quick settings panel, and shows a dot when something inside it is
// left on -- keep-awake, night light and do-not-disturb are all states you can
// forget about.
Item {
    id: root
    implicitWidth: 22
    implicitHeight: 20

    readonly property bool anyActive: IdleInhibit.keepAwake || NightLight.enabled || Notifications.dnd

    scale: fx.gestureScale
    Behavior on scale { Anim { duration: Appearance.animFast } }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -6
        radius: 8
        color: "#ffffff"
        opacity: fx.flashOpacity
    }

    Text {
        anchors.centerIn: parent
        text: ""
        color: root.anyActive ? Colors.primary : Colors.textPrimary
        font.family: Appearance.fontFamilyIcons
        font.pixelSize: Appearance.fontSizeLarge
        Behavior on color { ColorAnimation { duration: Appearance.animFast } }
    }

    Rectangle {
        width: 6
        height: 6
        radius: 3
        color: Colors.primary
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: -1
        anchors.rightMargin: -1

        scale: root.anyActive ? 1.0 : 0.0
        Behavior on scale { PopAnim { easing.overshoot: Appearance.overshootPop } }
    }

    PressFx {
        id: fx
        anchors.fill: parent
        anchors.margins: -4
        onActivated: UiState.toggle("quickSettings")
    }
}
