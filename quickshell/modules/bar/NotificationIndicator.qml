import QtQuick
import "../../config"
import "../../services"
import "../common"

Item {
    id: root
    implicitWidth: 26
    implicitHeight: 20

    readonly property int count: Notifications.active.count
    readonly property bool hovered: fx.containsMouse
    readonly property bool badgeVisible: root.count > 0 && !Notifications.dnd

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
        text: Notifications.dnd ? "\uf1f6" : "\uf0f3"
        color: Notifications.dnd ? Colors.textSecondary : (root.count > 0 ? Colors.primary : Colors.textPrimary)
        font.family: Appearance.fontFamilyIcons
        font.pixelSize: Appearance.fontSizeLarge
        Behavior on color { ColorAnimation { duration: Appearance.animFast } }
    }

    Rectangle {
        width: 14
        height: 14
        radius: 7
        color: Colors.error
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: -2
        anchors.rightMargin: -4

        scale: root.badgeVisible ? 1.0 : 0.0
        Behavior on scale { PopAnim { easing.overshoot: Appearance.overshootPop } }

        Text {
            anchors.centerIn: parent
            text: root.count > 9 ? "9+" : root.count
            color: Colors.errorText
            font.pixelSize: 9
            font.bold: true
        }
    }

    PressFx {
        id: fx
        anchors.fill: parent
        anchors.margins: -4
        onActivated: UiState.notificationCenterOpen = !UiState.notificationCenterOpen
    }
}
