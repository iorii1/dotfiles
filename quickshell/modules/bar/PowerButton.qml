import QtQuick
import "../../config"
import "../../services"
import "../common"

Item {
    id: root
    implicitWidth: 22
    implicitHeight: 20

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
        text: "\uf011"
        color: fx.containsMouse ? Colors.error : Colors.textPrimary
        font.family: Appearance.fontFamilyIcons
        font.pixelSize: Appearance.fontSizeLarge
        Behavior on color { ColorAnimation { duration: Appearance.animFast } }
    }

    PressFx {
        id: fx
        anchors.fill: parent
        anchors.margins: -4
        onActivated: UiState.powerMenuOpen = !UiState.powerMenuOpen
    }
}
