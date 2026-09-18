import QtQuick
import "../../config"
import "../../services"
import "../common"

// Only present while recording. A screen recorder with no visible state is how
// you end up with a three-hour file.
Item {
    id: root

    visible: Capture.recording
    implicitWidth: visible ? row.implicitWidth + Appearance.spacingSmall * 2 : 0
    implicitHeight: 24

    Behavior on implicitWidth { Anim {} }

    Rectangle {
        anchors.fill: parent
        radius: Appearance.radiusNormal
        color: fx.containsMouse ? Colors.alpha(Colors.error, 0.28) : Colors.alpha(Colors.error, 0.16)
        Behavior on color { ColorAnimation { duration: Appearance.animFast } }

        scale: fx.gestureScale
        Behavior on scale { Anim { duration: Appearance.animFast } }

        Row {
            id: row
            anchors.centerIn: parent
            spacing: Appearance.spacingSmall

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 8
                height: 8
                radius: 4
                color: Colors.error

                // Breathes on the shared pulse token, like every other ambient
                // loop in the shell.
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
    }

    PressFx {
        id: fx
        anchors.fill: parent
        focusRadius: Appearance.radiusNormal
        onActivated: Capture.stopRecording()
    }
}
