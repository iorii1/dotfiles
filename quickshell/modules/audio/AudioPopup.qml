import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../config"
import "../../services"
import "../common"

// The mixer: output level, microphone level, the devices to route them
// through, and a row per app that is currently making sound.
ShellPanel {
    id: audioWindow

    name: "audio"

    // Which device list is open, if any. Only one at a time -- two long lists
    // open at once would push the mixer off the bottom of the screen.
    property string openSelect: ""

    function _expand(which) {
        audioWindow.openSelect = (audioWindow.openSelect === which) ? "" : which
    }

    onOpenChanged: if (!open) audioWindow.openSelect = ""

    IpcHandler {
        target: "audio"
        function toggle(): void { UiState.toggle("audio") }
        function open(): void { UiState.show("audio") }
        function close(): void { UiState.hide("audio") }
    }

    PopupCard {
        id: card
        anchors.right: parent.right
        anchors.rightMargin: Appearance.spacingLarge
        readonly property int restY: BarConfig.barHeight + BarConfig.barMargin + Appearance.spacingSmall
        width: 320
        height: content.implicitHeight + Appearance.spacingNormal * 2

        opacity: UiState.audioOpen ? 1 : 0
        y: UiState.audioOpen ? restY : restY - 12
        scale: UiState.audioOpen ? 1 : Appearance.popupFromScale
        transformOrigin: Item.TopRight
        Behavior on opacity { Anim {} }
        Behavior on y { Anim {} }
        Behavior on scale { PopAnim {} }
        Behavior on height { Anim {} }

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            id: content
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Appearance.spacingNormal
            spacing: Appearance.spacingNormal

            // ---- Output ----------------------------------------------------

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacingSmall

                Text {
                    text: Audio.iconFor(Audio.volume, Audio.muted)
                    color: Audio.muted ? Colors.textSecondary : Colors.primary
                    font.family: Appearance.fontFamilyIcons
                    font.pixelSize: Appearance.fontSizeNormal

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Audio.toggleMute()
                    }
                }

                Slider {
                    Layout.fillWidth: true
                    value: Audio.volume
                    accentColor: Audio.muted ? Colors.outline : Colors.primary
                    onMoved: (v) => Audio.setVolume(v)
                }

                Text {
                    Layout.preferredWidth: 34
                    horizontalAlignment: Text.AlignRight
                    text: Math.round(Audio.volume * 100) + "%"
                    color: Colors.textSecondary
                    font.family: Appearance.fontFamily
                    font.pixelSize: Appearance.fontSizeSmall
                }
            }

            // ---- Input -----------------------------------------------------

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacingSmall
                visible: Audio.source !== null

                Text {
                    text: Audio.micIconFor(Audio.micMuted)
                    color: Audio.micMuted ? Colors.error : Colors.primary
                    font.family: Appearance.fontFamilyIcons
                    font.pixelSize: Appearance.fontSizeNormal

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Audio.toggleMicMute()
                    }
                }

                Slider {
                    Layout.fillWidth: true
                    value: Audio.micVolume
                    accentColor: Audio.micMuted ? Colors.outline : Colors.primary
                    onMoved: (v) => Audio.setMicVolume(v)
                }

                Text {
                    Layout.preferredWidth: 34
                    horizontalAlignment: Text.AlignRight
                    text: Math.round(Audio.micVolume * 100) + "%"
                    color: Colors.textSecondary
                    font.family: Appearance.fontFamily
                    font.pixelSize: Appearance.fontSizeSmall
                }
            }

            // ---- Devices ---------------------------------------------------
            //
            // Collapsed to one row each. Listing every device inline was fine
            // with a laptop's single sink and single source, and a wall of rows
            // the moment a dock or a headset adds more.

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Colors.outline
                opacity: 0.4
            }

            Select {
                Layout.fillWidth: true
                label: "Output"
                icon: "\uf028"
                model: Audio.sinks
                textFor: (item) => Audio.deviceName(item)
                isCurrent: (item) => Audio.sink === item
                expanded: audioWindow.openSelect === "sink"
                onExpandRequested: audioWindow._expand("sink")
                onPicked: (item) => {
                    Audio.setDefaultSink(item)
                    audioWindow.openSelect = ""
                }
            }

            Select {
                Layout.fillWidth: true
                label: "Input"
                icon: "\uf130"
                model: Audio.sources
                textFor: (item) => Audio.deviceName(item)
                isCurrent: (item) => Audio.source === item
                expanded: audioWindow.openSelect === "source"
                onExpandRequested: audioWindow._expand("source")
                onPicked: (item) => {
                    Audio.setDefaultSource(item)
                    audioWindow.openSelect = ""
                }
            }

            // ---- Per-app ---------------------------------------------------

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Colors.outline
                opacity: 0.4
                visible: Audio.streams.length > 0
            }

            Column {
                Layout.fillWidth: true
                spacing: Appearance.spacingSmall
                visible: Audio.streams.length > 0

                Repeater {
                    model: Audio.streams

                    delegate: RowLayout {
                        id: streamRow
                        required property var modelData
                        required property int index
                        width: parent.width
                        spacing: Appearance.spacingSmall

                        Text {
                            Layout.preferredWidth: 88
                            text: Audio.streamName(streamRow.modelData)
                            color: Colors.textPrimary
                            font.family: Appearance.fontFamily
                            font.pixelSize: Appearance.fontSizeSmall
                            elide: Text.ElideRight

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Audio.toggleStreamMute(streamRow.modelData)
                            }
                        }

                        Slider {
                            Layout.fillWidth: true
                            value: streamRow.modelData.audio ? streamRow.modelData.audio.volume : 0
                            accentColor: (streamRow.modelData.audio && streamRow.modelData.audio.muted)
                                ? Colors.outline : Colors.primary
                            onMoved: (v) => Audio.setStreamVolume(streamRow.modelData, v)
                        }
                    }
                }
            }
        }
    }
}
