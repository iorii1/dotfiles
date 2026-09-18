import QtQuick
import "../../config"
import "../../services"
import "../common"

// One selectable output or input device.
Item {
    id: root

    property var node: null
    property bool current: false
    property string icon: ""

    signal picked()

    implicitHeight: 28

    Rectangle {
        anchors.fill: parent
        radius: Appearance.radiusSmall
        color: root.current
            ? Colors.alpha(Colors.primary, 0.18)
            : (fx.containsMouse ? Colors.alpha(Colors.surfaceContainerHigh, Appearance.layerOpacity) : "transparent")
        Behavior on color { ColorAnimation { duration: Appearance.animFast } }

        Row {
            anchors.left: parent.left
            anchors.leftMargin: Appearance.spacingSmall
            anchors.right: parent.right
            anchors.rightMargin: Appearance.spacingSmall
            anchors.verticalCenter: parent.verticalCenter
            spacing: Appearance.spacingSmall

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.icon
                color: root.current ? Colors.primary : Colors.textSecondary
                font.family: Appearance.fontFamilyIcons
                font.pixelSize: Appearance.fontSizeSmall
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 40
                text: Audio.deviceName(root.node)
                color: root.current ? Colors.textPrimary : Colors.textSecondary
                font.family: Appearance.fontFamily
                font.pixelSize: Appearance.fontSizeSmall
                elide: Text.ElideRight
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "#ffffff"
            opacity: fx.flashOpacity
        }
    }

    PressFx {
        id: fx
        anchors.fill: parent
        hoverScale: 1.0
        pressScale: Appearance.pressScaleSubtle
        focusRadius: Appearance.radiusSmall
        onActivated: root.picked()
    }
}
