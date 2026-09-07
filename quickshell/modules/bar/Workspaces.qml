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
            clip: true

            Behavior on implicitWidth { NumberAnimation { duration: Appearance.animNormal; easing.type: Easing.OutBack; easing.overshoot: 1.4 } }
            Behavior on color { ColorAnimation { duration: Appearance.animFast } }

            scale: fx.popScale * (fx.pressed ? 0.85 : 1.0)
            Behavior on scale { NumberAnimation { duration: Appearance.animFast; easing.type: Easing.OutQuint } }

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
