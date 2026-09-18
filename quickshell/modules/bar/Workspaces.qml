import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "../../config"
import "../../services"
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

            Behavior on implicitWidth { PopAnim { easing.overshoot: Appearance.overshootPop } }
            Behavior on color { ColorAnimation { duration: Appearance.animFast } }

            scale: fx.gestureScale
            Behavior on scale { Anim { duration: Appearance.animFast } }

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
                    NumberAnimation { target: glow; property: "opacity"; to: 0.55; duration: Appearance.animPulse; easing.type: Easing.InOutSine }
                    NumberAnimation { target: glow; property: "opacity"; to: 0.0; duration: Appearance.animPulse; easing.type: Easing.InOutSine }
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
                hoverScale: 1.0
                anchors.fill: parent
                anchors.margins: -4
                popOvershoot: 2.2
                onActivated: Compositor.focusWorkspace(pill.modelData.id)
            }
        }
    }
}
