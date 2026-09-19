import QtQuick
import "../../config"
import "../../services"
import "../common"

// Opens the system dashboard, and turns red when something is running hot or
// full -- the point of monitoring is noticing without going to look.
Item {
    id: root
    implicitWidth: 22
    implicitHeight: 20

    readonly property bool alarming: Resources.cpuUsage >= 0.9
        || Resources.memoryUsage >= 0.9
        || Resources.diskUsage >= 0.9
        || (Resources.temperature > 0 && Resources.temperature >= 85)

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
        text: ""
        color: root.alarming ? Colors.error : Colors.textPrimary
        font.family: Appearance.fontFamilyIcons
        font.pixelSize: Appearance.fontSizeLarge
        Behavior on color { ColorAnimation { duration: Appearance.animFast } }
    }

    PressFx {
        id: fx
        anchors.fill: parent
        anchors.margins: -4
        onActivated: UiState.toggle("dashboard")
    }
}
