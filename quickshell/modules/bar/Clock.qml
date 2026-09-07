import QtQuick
import "../../config"
import "../../services"
import "../common"

Item {
    id: root
    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight

    property date now: new Date()

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    scale: fx.popScale * (fx.pressed ? 0.95 : (fx.containsMouse ? 1.05 : 1.0))
    Behavior on scale { NumberAnimation { duration: Appearance.animFast; easing.type: Easing.OutQuint } }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -8
        radius: 8
        color: "#ffffff"
        opacity: fx.flashOpacity
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: Qt.formatDateTime(root.now, "ddd d MMM  hh:mm")
        color: Colors.textPrimary
        font.family: Appearance.fontFamily
        font.pixelSize: Appearance.fontSizeNormal
        font.bold: true
    }

    PressFx {
        id: fx
        anchors.fill: parent
        anchors.margins: -6
        onActivated: UiState.calendarOpen = !UiState.calendarOpen
    }
}
