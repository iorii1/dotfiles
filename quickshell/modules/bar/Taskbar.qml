import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "../../config"
import "../common"

RowLayout {
    id: root
    spacing: Appearance.spacingSmall

    Repeater {
        model: Hyprland.toplevels

        Rectangle {
            id: pill
            required property var modelData

            readonly property bool active: modelData.activated
            readonly property bool hovered: fx.containsMouse
            readonly property string appId: modelData.wayland ? modelData.wayland.appId : ""

            implicitWidth: 26
            implicitHeight: 20
            radius: Appearance.radiusSmall
            color: active ? Colors.surfaceContainerHigh : (hovered ? Colors.surfaceContainer : "transparent")
            Behavior on color { ColorAnimation { duration: Appearance.animFast } }

            scale: fx.popScale * (fx.pressed ? 0.88 : 1.0)
            Behavior on scale { NumberAnimation { duration: Appearance.animFast; easing.type: Easing.OutQuint } }

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: "#ffffff"
                opacity: fx.flashOpacity
            }

            Text {
                anchors.centerIn: parent
                visible: icon.status !== Image.Ready
                text: pill.modelData.title ? pill.modelData.title.charAt(0).toUpperCase() : "?"
                color: Colors.textSecondary
                font.family: Appearance.fontFamily
                font.pixelSize: Appearance.fontSizeSmall
            }

            Image {
                id: icon
                anchors.centerIn: parent
                width: 16
                height: 16
                source: pill.appId ? "image://icon/" + pill.appId : ""
                fillMode: Image.PreserveAspectFit
                asynchronous: true
            }

            Rectangle {
                visible: pill.active
                width: 4
                height: 4
                radius: 2
                color: Colors.primary
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 1
            }

            PressFx {
                id: fx
                anchors.fill: parent
                anchors.margins: -2
                onActivated: Hyprland.dispatch("focuswindow address:" + pill.modelData.address)
            }
        }
    }
}
