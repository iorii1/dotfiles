import QtQuick
import QtQuick.Layouts
import "../../config"
import "../common"

Item {
    id: root

    property string label: ""
    property string icon: ""
    property bool accent: false
    property bool danger: false

    signal activated()

    implicitWidth: inner.implicitWidth + Appearance.spacingNormal * 2
    implicitHeight: 30

    readonly property color tint: root.danger ? Colors.error : Colors.primary

    Rectangle {
        anchors.fill: parent
        radius: Appearance.radiusNormal
        color: root.accent
            ? root.tint
            : (fx.containsMouse ? Colors.alpha(root.tint, 0.22)
                                : Colors.alpha(Colors.surfaceContainerHigh, Appearance.layerOpacity))
        Behavior on color { ColorAnimation { duration: Appearance.animFast } }

        scale: fx.gestureScale
        Behavior on scale { Anim { duration: Appearance.animFast } }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "#ffffff"
            opacity: fx.flashOpacity
        }

        RowLayout {
            id: inner
            anchors.centerIn: parent
            spacing: Appearance.spacingSmall

            Text {
                text: root.icon
                color: root.accent ? Colors.primaryText : Colors.textPrimary
                font.family: Appearance.fontFamilyIcons
                font.pixelSize: Appearance.fontSizeSmall
            }

            Text {
                text: root.label
                color: root.accent ? Colors.primaryText : Colors.textPrimary
                font.family: Appearance.fontFamily
                font.pixelSize: Appearance.fontSizeSmall
                font.bold: root.accent
            }
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
