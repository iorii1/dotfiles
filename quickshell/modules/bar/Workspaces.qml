import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "../../config"
import "../common"

RowLayout {
    id: root
    spacing: Appearance.spacingSmall

    Repeater {
        model: Hyprland.workspaces

        Rectangle {
            id: pill
            required property var modelData

            readonly property bool active: modelData.focused
            readonly property bool hovered: fx.containsMouse

            implicitWidth: active ? 22 : 10
            implicitHeight: 10
            radius: 5
            color: active ? Colors.primary : (hovered ? Colors.textSecondary : Colors.outline)

            Behavior on implicitWidth { NumberAnimation { duration: Appearance.animNormal; easing.type: Easing.OutBack; easing.overshoot: 1.4 } }
            Behavior on color { ColorAnimation { duration: Appearance.animFast } }

            scale: fx.popScale * (fx.pressed ? 0.85 : 1.0)
            Behavior on scale { NumberAnimation { duration: Appearance.animFast; easing.type: Easing.OutQuint } }

            Rectangle {
                id: glow
                anchors.centerIn: parent
                width: parent.width + 6
                height: parent.height + 6
                radius: height / 2
                color: "transparent"
                border.width: 1.5
                border.color: Colors.primary
                visible: pill.active
                opacity: 0

                SequentialAnimation {
                    running: pill.active
                    loops: Animation.Infinite
                    NumberAnimation { target: glow; property: "opacity"; to: 0.55; duration: 1000; easing.type: Easing.InOutSine }
                    NumberAnimation { target: glow; property: "opacity"; to: 0.0; duration: 1000; easing.type: Easing.InOutSine }
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: "#ffffff"
                opacity: fx.flashOpacity
            }

            PressFx {
                id: fx
                anchors.fill: parent
                anchors.margins: -4
                popOvershoot: 2.2
                onActivated: Hyprland.dispatch("workspace " + pill.modelData.id)
            }
        }
    }
}
