import QtQuick
import "../../config"
import "../../services"
import "../common"

// Only present while recording. A screen recorder with no visible state is how
// you end up with a three-hour file.
Item {
    id: root

    visible: Capture.recording
    implicitWidth: visible ? rowLayout.implicitWidth : 0
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

    Row {
        id: rowLayout
        anchors.centerIn: parent
        spacing: 5

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 8
            height: 8
            radius: 4
            color: Colors.error

            // Breathes on the shared pulse token, like every other ambient loop
            // in the shell.
            SequentialAnimation on opacity {
                running: root.visible
                loops: Animation.Infinite
                NumberAnimation { to: 0.35; duration: Appearance.animPulse; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0; duration: Appearance.animPulse; easing.type: Easing.InOutSine }
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "REC"
            color: Colors.error
            font.family: Appearance.fontFamily
            font.pixelSize: Appearance.fontSizeSmall
            font.bold: true
        }
    }

    PressFx {
        id: fx
        anchors.fill: parent
        anchors.margins: -4
        onActivated: Capture.stopRecording()
    }
}
