import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris
import "../../config"
import "../../services"
import "../common"

PanelWindow {
    id: popupWindow

    visible: UiState.mediaPopupOpen
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-popup"
    exclusionMode: ExclusionMode.Ignore
    focusable: false
    color: "transparent"

    anchors { top: true; bottom: true; left: true; right: true }

    readonly property var player: {
        const list = Mpris.players.values
        for (let i = 0; i < list.length; i++) {
            if (list[i].playbackState === MprisPlaybackState.Playing) return list[i]
        }
        return list.length > 0 ? list[0] : null
    }
    readonly property bool active: player !== null && player.trackTitle !== ""
    readonly property bool playing: active && player.playbackState === MprisPlaybackState.Playing

    property real displayPosition: 0

    IpcHandler {
        target: "media"
        function toggle(): void { UiState.mediaPopupOpen = !UiState.mediaPopupOpen }
        function open(): void { UiState.mediaPopupOpen = true }
        function close(): void { UiState.mediaPopupOpen = false }
    }

    onVisibleChanged: if (visible && player) displayPosition = player.position

    Connections {
        target: popupWindow.player
        function onPositionChanged() { popupWindow.displayPosition = popupWindow.player.position }
    }

    Timer {
        interval: 500
        running: popupWindow.playing && !seekSlider.dragging
        repeat: true
        onTriggered: popupWindow.displayPosition += 0.5
    }

    function formatTime(sec) {
        sec = Math.max(0, Math.floor(sec || 0))
        const m = Math.floor(sec / 60)
        const s = sec % 60
        return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s
    }

    MouseArea {
        anchors.fill: parent
        onClicked: UiState.mediaPopupOpen = false
    }

    PopupCard {
        id: card
        anchors.left: parent.left
        anchors.leftMargin: Appearance.spacingLarge
        readonly property int restY: BarConfig.barHeight + BarConfig.barMargin + Appearance.spacingSmall
        width: 300
        height: layout.implicitHeight + Appearance.spacingNormal * 2

        opacity: UiState.mediaPopupOpen ? 1 : 0
        y: UiState.mediaPopupOpen ? restY : restY - 12
        scale: UiState.mediaPopupOpen ? 1 : 0.95
        transformOrigin: Item.TopLeft
        Behavior on opacity { NumberAnimation { duration: Appearance.animNormal; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: Appearance.animNormal; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: Appearance.animNormal; easing.type: Easing.OutBack; easing.overshoot: Appearance.overshootCard } }

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            id: layout
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Appearance.spacingNormal
            spacing: Appearance.spacingNormal

            // --- Vinyl disc -------------------------------------------------
            Item {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 168
                Layout.preferredHeight: 168

                Item {
                    id: disc
                    anchors.fill: parent
                    rotation: 0

                    NumberAnimation on rotation {
                        from: 0
                        to: 360
                        duration: 20000
                        loops: Animation.Infinite
                        running: true
                        paused: !popupWindow.playing
                    }

                    Rectangle {
                        id: vinylBase
                        anchors.fill: parent
                        radius: width / 2
                        color: Colors.surfaceContainerHigh
                        border.width: 2
                        border.color: popupWindow.playing ? Colors.primary : Colors.outline
                        Behavior on border.color { ColorAnimation { duration: 400 } }

                        Repeater {
                            model: [0.92, 0.82, 0.72, 0.62, 0.52]
                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width * modelData
                                height: width
                                radius: width / 2
                                color: "transparent"
                                border.width: 1
                                border.color: index % 2 === 0 ? "#ffffff" : "#000000"
                                opacity: 0.05
                                antialiasing: true
                            }
                        }

                        Item {
                            id: artHolder
                            anchors.fill: parent
                            anchors.margins: 3

                            Image {
                                id: artImg
                                anchors.fill: parent
                                source: {
                                    if (!popupWindow.active) return ""
                                    const u = popupWindow.player.trackArtUrl || ""
                                    if (!u) return ""
                                    return (u.startsWith("file://") || u.startsWith("http")) ? u : "file://" + u
                                }
                                fillMode: Image.PreserveAspectCrop
                                visible: false
                                asynchronous: true
                            }

                            Rectangle {
                                id: artMask
                                anchors.fill: parent
                                radius: width / 2
                                visible: false
                                layer.enabled: true
                            }

                            MultiEffect {
                                anchors.fill: parent
                                source: artImg
                                maskEnabled: true
                                maskSource: artMask
                                opacity: (popupWindow.active && artImg.status === Image.Ready && artImg.source !== "") ? 1.0 : 0.0
                                Behavior on opacity { NumberAnimation { duration: 400 } }
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: width / 2
                                color: Colors.surfaceContainer
                                opacity: (popupWindow.active && artImg.status === Image.Ready && artImg.source !== "") ? 0.0 : 1.0
                                Behavior on opacity { NumberAnimation { duration: 300 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "\uf001"
                                    font.family: Appearance.fontFamily
                                    font.pixelSize: parent.width * 0.26
                                    color: Colors.textSecondary
                                }
                            }
                        }

                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width * 0.26
                            height: width
                            radius: width / 2
                            color: Colors.background
                            border.width: 1
                            border.color: Colors.outline

                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width * 0.32
                                height: width
                                radius: width / 2
                                color: Colors.surfaceContainerHigh
                            }
                        }
                    }
                }
            }

            // --- Title / artist ---------------------------------------------
            Item {
                id: titleClip
                Layout.fillWidth: true
                implicitHeight: titleMain.implicitHeight
                clip: true

                property int marqueeSpacing: 24
                property real scrollProgress: 0.0
                readonly property bool overflow: titleMain.implicitWidth > titleClip.width

                Item {
                    id: marqueeContainer
                    height: parent.height
                    x: titleClip.overflow ? -titleClip.scrollProgress * (titleMain.implicitWidth + titleClip.marqueeSpacing) : 0

                    Row {
                        spacing: titleClip.marqueeSpacing

                        Text {
                            id: titleMain
                            text: popupWindow.active ? (popupWindow.player.trackTitle || "Unknown Track") : "Nothing playing"
                            font.family: Appearance.fontFamily
                            font.bold: true
                            font.pixelSize: Appearance.fontSizeNormal
                            color: Colors.textPrimary
                            onTextChanged: titleClip.scrollProgress = 0.0
                        }

                        Text {
                            text: titleMain.text
                            font.family: Appearance.fontFamily
                            font.bold: true
                            font.pixelSize: Appearance.fontSizeNormal
                            color: Colors.textPrimary
                            visible: titleClip.overflow
                        }
                    }
                }

                SequentialAnimation {
                    loops: Animation.Infinite
                    running: titleClip.overflow

                    PauseAnimation { duration: 2500 }
                    NumberAnimation {
                        target: titleClip
                        property: "scrollProgress"
                        from: 0.0
                        to: 1.0
                        duration: (titleMain.implicitWidth + titleClip.marqueeSpacing) * 22
                    }
                    PropertyAction { target: titleClip; property: "scrollProgress"; value: 0.0 }
                }
            }

            Text {
                Layout.fillWidth: true
                text: popupWindow.active ? (popupWindow.player.trackArtist || "Unknown Artist") : ""
                font.family: Appearance.fontFamily
                font.pixelSize: Appearance.fontSizeSmall
                color: Colors.textSecondary
                elide: Text.ElideRight
                visible: popupWindow.active
            }

            // --- Progress ----------------------------------------------------
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                visible: popupWindow.active && popupWindow.player.length > 0

                Slider {
                    id: seekSlider
                    Layout.fillWidth: true
                    value: (popupWindow.active && popupWindow.player.length > 0) ? (popupWindow.displayPosition / popupWindow.player.length) : 0
                    onMoved: (v) => {
                        if (popupWindow.active && popupWindow.player.length > 0) {
                            popupWindow.displayPosition = v * popupWindow.player.length
                            popupWindow.player.position = popupWindow.displayPosition
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: popupWindow.formatTime(popupWindow.displayPosition)
                        color: Colors.textSecondary
                        font.family: Appearance.fontFamily
                        font.pixelSize: Appearance.fontSizeSmall
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: popupWindow.active ? popupWindow.formatTime(popupWindow.player.length) : "--:--"
                        color: Colors.textSecondary
                        font.family: Appearance.fontFamily
                        font.pixelSize: Appearance.fontSizeSmall
                    }
                }
            }

            // --- Controls ------------------------------------------------
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Appearance.spacingLarge

                Item {
                    implicitWidth: 30; implicitHeight: 30
                    Text {
                        anchors.centerIn: parent
                        text: "\uf048"
                        color: prevFx.containsMouse ? Colors.textPrimary : Colors.textSecondary
                        font.family: Appearance.fontFamily
                        font.pixelSize: Appearance.fontSizeLarge
                    }
                    PressFx {
                        id: prevFx
                        anchors.fill: parent
                        onActivated: if (popupWindow.active && popupWindow.player.canGoPrevious) popupWindow.player.previous()
                    }
                }

                Item {
                    implicitWidth: 44; implicitHeight: 44
                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: Colors.primary
                        scale: playFx.popScale * (playFx.pressed ? 0.9 : 1.0)
                        Behavior on scale { NumberAnimation { duration: Appearance.animFast; easing.type: Easing.OutQuint } }

                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: "#ffffff"
                            opacity: playFx.flashOpacity
                        }

                        Text {
                            anchors.centerIn: parent
                            text: popupWindow.playing ? "\uf04c" : "\uf04b"
                            color: Colors.primaryText
                            font.family: Appearance.fontFamily
                            font.pixelSize: Appearance.fontSizeLarge
                        }
                    }
                    PressFx {
                        id: playFx
                        anchors.fill: parent
                        onActivated: if (popupWindow.active && popupWindow.player.canTogglePlaying) popupWindow.player.togglePlaying()
                    }
                }

                Item {
                    implicitWidth: 30; implicitHeight: 30
                    Text {
                        anchors.centerIn: parent
                        text: "\uf051"
                        color: nextFx.containsMouse ? Colors.textPrimary : Colors.textSecondary
                        font.family: Appearance.fontFamily
                        font.pixelSize: Appearance.fontSizeLarge
                    }
                    PressFx {
                        id: nextFx
                        anchors.fill: parent
                        onActivated: if (popupWindow.active && popupWindow.player.canGoNext) popupWindow.player.next()
                    }
                }
            }
        }
    }
}
