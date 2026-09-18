import QtQuick
import "../../config"
import "../common"

// A plain push button. FillButton is hold-to-activate, which is right for the
// power menu and wrong for a dialog you want to answer quickly.
Item {
    id: root

    property string label: ""
    property bool accent: false
    // `enabled` is Item's own -- setting it false also disables the PressFx
    // child, so there is nothing to forward.

    signal activated()

    implicitWidth: text.implicitWidth + Appearance.spacingLarge * 2
    implicitHeight: 32

    Rectangle {
        anchors.fill: parent
        radius: Appearance.radiusNormal
        opacity: root.enabled ? 1 : 0.4
        color: root.accent
            ? Colors.primary
            : (fx.containsMouse ? Colors.surfaceContainerHigh
                                : Colors.alpha(Colors.surfaceContainerHigh, Appearance.layerOpacity))
        Behavior on color { ColorAnimation { duration: Appearance.animFast } }
        Behavior on opacity { Anim { duration: Appearance.animFast } }

        scale: fx.gestureScale
        Behavior on scale { Anim { duration: Appearance.animFast } }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "#ffffff"
            opacity: fx.flashOpacity
        }

        Text {
            id: text
            anchors.centerIn: parent
            text: root.label
            color: root.accent ? Colors.primaryText : Colors.textPrimary
            font.family: Appearance.fontFamily
            font.pixelSize: Appearance.fontSizeSmall
            font.bold: root.accent
        }
    }

    PressFx {
        id: fx
        anchors.fill: parent
        hoverScale: Appearance.hoverScaleSubtle
        pressScale: Appearance.pressScaleSubtle
        focusRadius: Appearance.radiusNormal
        onActivated: root.activated()
    }
}
