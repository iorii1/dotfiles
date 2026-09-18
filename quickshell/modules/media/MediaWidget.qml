import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Services.Mpris
import "../../config"
import "../../services"
import "../common"

Item {
    id: root

    readonly property var player: {
        const list = Mpris.players.values
        for (let i = 0; i < list.length; i++) {
            if (list[i].playbackState === MprisPlaybackState.Playing) return list[i]
        }
        return list.length > 0 ? list[0] : null
    }
    readonly property bool playing: root.player && root.player.playbackState === MprisPlaybackState.Playing
    readonly property bool active: root.player !== null && root.player.trackTitle !== ""

    implicitWidth: root.active ? rowLayout.implicitWidth + Appearance.spacingNormal * 2 : 0
    implicitHeight: 24
    clip: true

    Behavior on implicitWidth { Anim {} }

    Rectangle {
        anchors.fill: parent
        radius: Appearance.radiusNormal
        color: fx.containsMouse ? Colors.surfaceContainerHigh : Colors.surfaceContainer
        Behavior on color { ColorAnimation { duration: Appearance.animFast } }
        clip: true

        Rectangle {
            anchors.fill: parent
            color: "#ffffff"
            opacity: fx.flashOpacity
        }

        RowLayout {
            id: rowLayout
            anchors.centerIn: parent
            spacing: Appearance.spacingSmall

            Item {
                id: discThumb
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16
                Layout.alignment: Qt.AlignVCenter

                Item {
                    id: discSpin
                    anchors.fill: parent

                    NumberAnimation on rotation {
                        from: 0
                        to: 360
                        duration: 20000
                        loops: Animation.Infinite
                        running: true
                        paused: !root.playing
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: Colors.alpha(Colors.surfaceContainerHigh, Appearance.layerOpacity)
                        border.width: 1
                        border.color: root.playing ? Colors.primary : Colors.outline
                        Behavior on border.color { ColorAnimation { duration: Appearance.animSlow } }

                        Image {
                            id: thumbArt
                            anchors.fill: parent
                            anchors.margins: 1
                            visible: false
                            asynchronous: true
                            fillMode: Image.PreserveAspectCrop
                            source: {
                                if (!root.active) return ""
                                const u = root.player.trackArtUrl || ""
                                if (!u) return ""
                                return (u.startsWith("file://") || u.startsWith("http")) ? u : "file://" + u
                            }
                        }

                        Rectangle {
                            id: thumbMask
                            anchors.fill: parent
                            anchors.margins: 1
                            radius: width / 2
                            visible: false
                            layer.enabled: true
                        }

                        MultiEffect {
                            anchors.fill: parent
                            anchors.margins: 1
                            source: thumbArt
                            maskEnabled: true
                            maskSource: thumbMask
                            opacity: (root.active && thumbArt.status === Image.Ready && thumbArt.source !== "") ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: Appearance.animNormal } }
                        }

                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width * 0.28
                            height: width
                            radius: width / 2
                            color: Colors.background
                        }
                    }
                }
            }

            Item {
                id: titleClip
                Layout.preferredWidth: Math.min(150, titleText.implicitWidth)
                Layout.preferredHeight: titleText.implicitHeight
                clip: true

                property real scrollProgress: 0.0
                readonly property bool overflow: titleText.implicitWidth > titleClip.width

                Row {
                    x: titleClip.overflow ? -titleClip.scrollProgress * (titleText.implicitWidth + 24) : 0
                    spacing: 24

                    Text {
                        id: titleText
                        text: root.active
                            ? (root.player.trackTitle || "Unknown") + (root.player.trackArtist ? " — " + root.player.trackArtist : "")
                            : ""
                        color: Colors.textPrimary
                        font.family: Appearance.fontFamily
                        font.pixelSize: Appearance.fontSizeSmall
                        onTextChanged: titleClip.scrollProgress = 0.0
                    }

                    Text {
                        text: titleText.text
                        visible: titleClip.overflow
                        color: Colors.textPrimary
                        font.family: Appearance.fontFamily
                        font.pixelSize: Appearance.fontSizeSmall
                    }
                }

                SequentialAnimation {
                    loops: Animation.Infinite
                    running: titleClip.overflow

                    PauseAnimation { duration: 2200 }
                    NumberAnimation {
                        target: titleClip
                        property: "scrollProgress"
                        from: 0.0
                        to: 1.0
                        duration: (titleText.implicitWidth + 24) * 20
                    }
                    PropertyAction { target: titleClip; property: "scrollProgress"; value: 0.0 }
                }
            }
        }

        PressFx {
            id: fx
            anchors.fill: parent
            onActivated: UiState.mediaPopupOpen = !UiState.mediaPopupOpen
        }
    }
}
