import QtQuick
import Quickshell.Hyprland
import "../../config"
import "../common"

// What you are focused on. The bar had twelve modules and none of them said
// which window had focus.
Item {
    id: root

    readonly property var toplevel: Hyprland.activeToplevel
    readonly property string title: root.toplevel ? (root.toplevel.title || "") : ""
    readonly property string appId: (root.toplevel && root.toplevel.wayland)
        ? (root.toplevel.wayland.appId || "") : ""

    // Collapses to nothing on an empty workspace rather than leaving a gap.
    implicitWidth: root.title !== "" ? Math.min(row.implicitWidth, root.maxWidth) : 0
    implicitHeight: 20

    property int maxWidth: 280

    Behavior on implicitWidth { Anim { duration: Appearance.animFast } }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        spacing: 5

        Image {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.appId !== ""
            width: 14
            height: 14
            source: root.appId !== "" ? "image://icon/" + root.appId : ""
            fillMode: Image.PreserveAspectFit
            asynchronous: true
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, root.maxWidth - 19)
            text: root.title
            color: Colors.textSecondary
            font.family: Appearance.fontFamily
            font.pixelSize: Appearance.fontSizeSmall
            elide: Text.ElideRight
        }
    }
}
