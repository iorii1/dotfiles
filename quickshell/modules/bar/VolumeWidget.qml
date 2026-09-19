import QtQuick
import "../../config"
import "../../services"
import "../common"

// Volume: the speaker glyph plus the level. Scroll to adjust, click for the
// mixer, middle-click to mute.
Item {
    id: root
    implicitWidth: rowLayout.implicitWidth
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

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Audio.iconFor(Audio.volume, Audio.muted)
            color: Audio.muted ? Colors.textSecondary : Colors.textPrimary
            font.family: Appearance.fontFamilyIcons
            font.pixelSize: Appearance.fontSizeLarge
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

        // Inside the Row, so it contributes to implicitWidth. Anchored outside
        // the item it would overlap whatever sits next in the bar and reserve
        // no space for itself.
        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: Audio.micMuted
            text: Audio.micIconFor(true)
            color: Colors.error
            font.family: Appearance.fontFamilyIcons
            font.pixelSize: Appearance.fontSizeSmall
        }
    }

    // Below the PressFx and accepting only the middle button: a MouseArea
    // passes through buttons it does not accept, so left clicks and the wheel
    // still reach the PressFx stacked above this.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton
        onClicked: Audio.toggleMute()
    }

    PressFx {
        id: fx
        anchors.fill: parent
        anchors.margins: -4
        onActivated: UiState.toggle("audio")

        // Matches the 5% the XF86Audio keys use, so scrolling and the keys land
        // on the same values rather than drifting apart.
        onWheel: (wheel) => {
            Audio.stepVolume(wheel.angleDelta.y > 0 ? 0.05 : -0.05)
            wheel.accepted = true
        }
    }
}
