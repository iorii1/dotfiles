import QtQuick
import "../../config"
import "../../services"
import "../common"

// Opens the quick settings panel, and shows when something in it is on.
Item {
    id: root

    implicitWidth: 24
    implicitHeight: 24

    // Worth surfacing in the bar: these are states you can forget you left on.
    readonly property bool anyActive: IdleInhibit.keepAwake || NightLight.enabled || Notifications.dnd

    Rectangle {
        anchors.fill: parent
        radius: Appearance.radiusNormal
        color: fx.containsMouse ? Colors.surfaceContainerHigh : "transparent"
        Behavior on color { ColorAnimation { duration: Appearance.animFast } }

        scale: fx.gestureScale
        Behavior on scale { Anim { duration: Appearance.animFast } }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "#ffffff"
            opacity: fx.flashOpacity
        }

        Text {
            anchors.centerIn: parent
            text: ""
            color: root.anyActive ? Colors.primary : Colors.textPrimary
            font.family: Appearance.fontFamilyIcons
            font.pixelSize: Appearance.fontSizeNormal
            Behavior on color { ColorAnimation { duration: Appearance.animFast } }
        }

        Rectangle {
            visible: root.anyActive
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 2
            width: 5
            height: 5
            radius: 2.5
            color: Colors.primary
        }
    }

    PressFx {
        id: fx
        anchors.fill: parent
        anchors.margins: -2
        focusRadius: Appearance.radiusNormal
        onActivated: UiState.toggle("quickSettings")
    }
}
