import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "../../config"
import "../../services"
import "../common"

RowLayout {
    id: root
    spacing: Appearance.spacingSmall

    // Driven by the dock's reveal state so items can fade in staggered.
    property bool shown: true

    Repeater {
        model: Hyprland.toplevels

        Rectangle {
            id: pill
            required property var modelData
            required property int index

            readonly property bool active: modelData.activated
            readonly property bool hovered: fx.containsMouse
            readonly property string appId: modelData.wayland ? modelData.wayland.appId : ""

            implicitWidth: 44
            implicitHeight: 44
            radius: Appearance.radiusNormal
            color: active ? Colors.surfaceContainerHigh : (hovered ? Colors.surfaceContainer : "transparent")
            Behavior on color { ColorAnimation { duration: Appearance.animFast } }

            // Only opacity is animated for the entrance: `scale` carries a
            // binding to fx.popScale, and a property animation on it would tear
            // that binding down permanently the first time it ran.
            opacity: root.shown ? 1 : 0
            Behavior on opacity { Anim {} }

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
                visible: icon.status !== Image.Ready
                text: pill.modelData.title ? pill.modelData.title.charAt(0).toUpperCase() : "?"
                color: Colors.textSecondary
                font.family: Appearance.fontFamily
                font.pixelSize: Appearance.fontSizeLarge
            }

            Image {
                id: icon
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -2
                width: 28
                height: 28
                source: pill.appId ? "image://icon/" + pill.appId : ""
                fillMode: Image.PreserveAspectFit
                asynchronous: true
            }

            // Focused-window dot, macOS-style beneath the icon. The card floats
            // clear of the screen edge, so this does not sit flush against it.
            Rectangle {
                visible: pill.active
                width: 4
                height: 4
                radius: 2
                color: Colors.primary
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 4
            }

            PressFx {
                id: fx
                anchors.fill: parent
                onActivated: Compositor.focusWindow(pill.modelData.address)
            }
        }
    }
}
