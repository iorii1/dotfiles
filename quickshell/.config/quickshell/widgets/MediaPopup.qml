import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Services.Pipewire
import "../services"

PopupWindow {
    id: root

    property bool open: false
    property alias hovered: hoverHandler.hovered

    implicitWidth: 300
    implicitHeight: 420
    color: "transparent"
    visible: open || closeHold.running

    Timer {
        id: closeHold
        interval: 180
    }
    onOpenChanged: if (!open) closeHold.start()

    HoverHandler { id: hoverHandler }

    readonly property real discSize: 148
    readonly property real ringRadius: discSize / 2
    readonly property real maxBarHeight: 26

    // Spotify (and others) blank out identity/artist/art for a moment during
    // ad breaks - keep showing the last known-good app identity instead of
    // flashing the icon/name away for a few seconds.
    property string stickyIdentity: ""
    property string stickyDesktopEntry: ""
    Connections {
        target: Mpris
        function onIdentityChanged() { if (Mpris.identity) root.stickyIdentity = Mpris.identity }
        function onDesktopEntryChanged() { if (Mpris.desktopEntry) root.stickyDesktopEntry = Mpris.desktopEntry }
        function onHasPlayerChanged() {
            if (!Mpris.hasPlayer) { root.stickyIdentity = ""; root.stickyDesktopEntry = "" }
        }
    }
    Component.onCompleted: {
        if (Mpris.identity) stickyIdentity = Mpris.identity
        if (Mpris.desktopEntry) stickyDesktopEntry = Mpris.desktopEntry
    }

    // Find the PipeWire playback stream owned by whatever app MPRIS says is
    // active, so the volume bar controls only that app - not the master sink.
    readonly property var mediaStreamNode: {
        if (!Mpris.hasPlayer || !Pipewire.ready) return null
        const target = (root.stickyIdentity || root.stickyDesktopEntry || "").toLowerCase()
        if (!target) return null
        const streams = Pipewire.nodes.values.filter(n => n.isStream && n.audio
            && (n.type & PwNodeType.AudioOutStream) === PwNodeType.AudioOutStream)
        const matches = n => {
            const candidates = [
                n.properties["application.name"] || "",
                n.name || "",
                n.description || "",
                n.nickname || ""
            ].map(s => s.toLowerCase()).filter(s => s.length > 0)
            return candidates.some(c => c === target || c.indexOf(target) !== -1 || target.indexOf(c) !== -1)
        }
        const found = streams.find(matches)
        return found || (streams.length === 1 ? streams[0] : null)
    }
    readonly property real mediaVolume: mediaStreamNode && mediaStreamNode.audio
        ? Math.round(mediaStreamNode.audio.volume * 100) : 0
    readonly property bool mediaMuted: mediaStreamNode && mediaStreamNode.audio
        ? mediaStreamNode.audio.muted : false

    function setMediaVolume(pct) {
        if (mediaStreamNode && mediaStreamNode.audio) {
            mediaStreamNode.audio.volume = Math.max(0, Math.min(150, pct)) / 100
        }
    }
    function toggleMediaMute() {
        if (mediaStreamNode && mediaStreamNode.audio) {
            mediaStreamNode.audio.muted = !mediaStreamNode.audio.muted
        }
    }

    PwObjectTracker {
        objects: root.mediaStreamNode ? [root.mediaStreamNode] : []
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: 14
        color: "#e61e1e2e"
        border.width: 1
        border.color: "#33cdd6f4"

        opacity: root.open ? 1 : 0
        scale: root.open ? 1 : 0.92
        transformOrigin: Item.Top

        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: 260; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: Mpris.hasPlayer ? "Now Playing" : "Nothing Playing"
                color: "#a6adc8"
                font.pixelSize: 12
                font.bold: true
                font.family: "JetBrainsMono Nerd Font"
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                visible: Mpris.hasPlayer
                spacing: 6

                Image {
                    id: appIconImg
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16
                    source: {
                        const name = root.stickyDesktopEntry || root.stickyIdentity.toLowerCase()
                        return name ? Quickshell.iconPath(name, "") : ""
                    }
                    visible: status === Image.Ready
                }

                Text {
                    text: root.stickyIdentity
                    color: "#fab387"
                    font.pixelSize: 12
                    font.bold: true
                    font.family: "JetBrainsMono Nerd Font"
                }
            }

            Item {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: root.discSize + root.maxBarHeight * 2 + 10
                Layout.preferredHeight: root.discSize + root.maxBarHeight * 2 + 10

                // Radial cava spectrum ring around the disc
                Item {
                    anchors.centerIn: parent

                    Repeater {
                        model: Cava.barCount

                        Item {
                            required property int index
                            readonly property real level: Cava.barLevels[index] || 0

                            anchors.centerIn: parent
                            width: 0
                            height: 0
                            rotation: index * (360 / Cava.barCount)

                            Rectangle {
                                anchors.bottom: parent.top
                                anchors.bottomMargin: root.ringRadius + 4
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 3
                                radius: 1.5
                                height: Math.max(2, parent.level * root.maxBarHeight)
                                color: Qt.tint("#fab387", Qt.rgba(1, 1, 1, parent.level * 0.4))
                                opacity: 0.5 + parent.level * 0.5

                                Behavior on height {
                                    NumberAnimation { duration: 130; easing.type: Easing.OutCubic }
                                }
                            }
                        }
                    }
                }

                // Spinning vinyl disc
                Item {
                    id: disc
                    anchors.centerIn: parent
                    width: root.discSize
                    height: root.discSize

                    Rectangle {
                        id: vinylBase
                        anchors.fill: parent
                        radius: width / 2
                        color: "#45475a"
                        border.width: 2
                        border.color: Mpris.isPlaying ? "#fab387" : "#585b70"

                        Behavior on border.color {
                            ColorAnimation { duration: 550 }
                        }

                        NumberAnimation on rotation {
                            from: 0; to: 360; duration: 18000
                            loops: Animation.Infinite
                            running: true
                            paused: !Mpris.isPlaying
                        }

                        Item {
                            id: artMaskedContainer
                            anchors.fill: parent
                            anchors.margins: 3
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                maskEnabled: true
                                maskSource: maskRect
                            }

                            Rectangle {
                                anchors.fill: parent
                                color: "#1e1e2e"
                            }

                            Image {
                                anchors.fill: parent
                                source: Mpris.artUrl
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                visible: status === Image.Ready
                            }

                            // vinyl grooves + label when there's no art
                            Item {
                                anchors.fill: parent
                                visible: !Mpris.artUrl

                                Repeater {
                                    model: 3
                                    Rectangle {
                                        required property int index
                                        anchors.centerIn: parent
                                        width: parent.width - (index + 1) * 22
                                        height: width
                                        radius: width / 2
                                        color: "transparent"
                                        border.width: 1
                                        border.color: "#33cdd6f4"
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰎈"
                                    color: "#7f849c"
                                    font.pixelSize: 22
                                    font.family: "JetBrainsMono Nerd Font"
                                }
                            }
                        }

                        Rectangle {
                            id: maskRect
                            anchors.fill: artMaskedContainer
                            radius: width / 2
                            visible: false
                            layer.enabled: true
                        }

                        // vinyl spindle
                        Rectangle {
                            anchors.centerIn: parent
                            width: 12
                            height: 12
                            radius: 6
                            color: "#11111b"
                            border.width: 1
                            border.color: "#585b70"
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: Mpris.title || "Nothing is playing"
                    color: "#cdd6f4"
                    font.bold: true
                    font.pixelSize: 14
                    font.family: "JetBrainsMono Nerd Font"
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: Mpris.artist || ""
                    color: "#a6adc8"
                    font.pixelSize: 12
                    font.family: "JetBrainsMono Nerd Font"
                    elide: Text.ElideRight
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 20

                Repeater {
                    model: [
                        { icon: "󰒮", action: () => Mpris.previous(), enabled: Mpris.canGoPrevious },
                        { icon: Mpris.isPlaying ? "󰏤" : "󰐊", action: () => Mpris.playPause(), enabled: Mpris.hasPlayer },
                        { icon: "󰒭", action: () => Mpris.next(), enabled: Mpris.canGoNext }
                    ]

                    Rectangle {
                        required property var modelData
                        width: 34
                        height: 34
                        radius: 17
                        color: btnMouse.containsMouse ? "#33cdd6f4" : "transparent"
                        opacity: modelData.enabled ? 1.0 : 0.35

                        Behavior on color {
                            ColorAnimation { duration: 220 }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: modelData.icon
                            color: "#cdd6f4"
                            font.pixelSize: 15
                            font.family: "JetBrainsMono Nerd Font"
                        }

                        MouseArea {
                            id: btnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            enabled: modelData.enabled
                            onClicked: modelData.action()
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 2
                visible: root.mediaStreamNode !== null
                spacing: 8

                Text {
                    text: root.mediaMuted ? "󰝟" : (root.mediaVolume >= 50 ? "󰕾" : (root.mediaVolume > 0 ? "󰖀" : "󰕿"))
                    color: volHover.hovered ? "#fab387" : "#a6adc8"
                    font.pixelSize: 13
                    font.family: "JetBrainsMono Nerd Font"

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }

                    HoverHandler { id: volHover }
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.toggleMediaMute()
                    }
                }

                Item {
                    id: mediaVolSlider
                    Layout.fillWidth: true
                    implicitHeight: 18

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: 6
                        radius: 3
                        color: "#26cdd6f4"

                        Rectangle {
                            width: parent.width * Math.max(0, Math.min(1, (root.mediaMuted ? 0 : root.mediaVolume) / 100))
                            height: parent.height
                            radius: 3
                            color: "#fab387"

                            Behavior on width {
                                NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        preventStealing: true
                        function apply(mx) {
                            root.setMediaVolume(Math.max(0, Math.min(100, mx / width * 100)))
                        }
                        onPressed: mouse => apply(mouse.x)
                        onPositionChanged: mouse => { if (pressed) apply(mouse.x) }
                    }
                }

                Text {
                    text: (root.mediaMuted ? 0 : root.mediaVolume) + "%"
                    color: "#7f849c"
                    font.pixelSize: 11
                    font.family: "JetBrainsMono Nerd Font"
                    Layout.preferredWidth: 30
                }
            }
        }
    }
}
