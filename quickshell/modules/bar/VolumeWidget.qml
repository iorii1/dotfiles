import QtQuick
import "../../config"
import "../../services"
import "../common"

// Volume in the bar: the speaker glyph plus the level, scroll to adjust,
// click for the mixer, middle-click to mute.
Item {
    id: root

    implicitWidth: row.implicitWidth + Appearance.spacingSmall * 2
    implicitHeight: 24

    Rectangle {
        anchors.fill: parent
        radius: Appearance.radiusNormal
        color: fx.containsMouse ? Colors.surfaceContainerHigh : "transparent"
        Behavior on color { ColorAnimation { duration: Appearance.animFast } }

        scale: fx.gestureScale
        Behavior on scale { Anim { duration: Appearance.animFast } }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "#ffffff"
            opacity: fx.flashOpacity
        }

        Row {
            id: row
            anchors.centerIn: parent
            spacing: Appearance.spacingSmall

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Audio.iconFor(Audio.volume, Audio.muted)
                color: Audio.muted ? Colors.textSecondary : Colors.textPrimary
                font.family: Appearance.fontFamilyIcons
                font.pixelSize: Appearance.fontSizeNormal
                Behavior on color { ColorAnimation { duration: Appearance.animFast } }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Audio.muted ? "--" : Math.round(Audio.volume * 100) + "%"
                color: Audio.muted ? Colors.textSecondary : Colors.textPrimary
                font.family: Appearance.fontFamily
                font.pixelSize: Appearance.fontSizeSmall
                Behavior on color { ColorAnimation { duration: Appearance.animFast } }
            }
        }
    }

    // Muted mic is worth showing even when nothing else about audio is: it is
    // the state people forget they are in.
    Text {
        anchors.left: parent.right
        anchors.leftMargin: 2
        anchors.verticalCenter: parent.verticalCenter
        visible: Audio.micMuted
        text: Audio.micIconFor(true)
        color: Colors.error
        font.family: Appearance.fontFamilyIcons
        font.pixelSize: Appearance.fontSizeSmall
    }

    // Below the PressFx and deliberately accepting only the middle button: a
    // MouseArea passes through buttons it does not accept, so left clicks and
    // the wheel still reach the PressFx stacked above this.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton
        onClicked: Audio.toggleMute()
    }

    PressFx {
        id: fx
        anchors.fill: parent
        anchors.margins: -2
        focusRadius: Appearance.radiusNormal

        onActivated: UiState.toggle("audio")

        // Matches the 5% the XF86Audio keys use, so scrolling and the keys
        // land on the same values rather than drifting apart.
        onWheel: (wheel) => {
            Audio.stepVolume(wheel.angleDelta.y > 0 ? 0.05 : -0.05)
            wheel.accepted = true
        }
    }
}
