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
            // Hidden when there is nothing to choose between, which on a laptop
            // with no dock or headset is most of the time.

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Colors.outline
                opacity: 0.4
                visible: deviceColumn.visible
            }

            Column {
                id: deviceColumn
                Layout.fillWidth: true
                spacing: 2
                visible: Audio.sinks.length > 1 || Audio.sources.length > 1

                Repeater {
                    model: Audio.sinks.length > 1 ? Audio.sinks : []
                    delegate: DeviceRow {
                        required property var modelData
                        width: deviceColumn.width
                        node: modelData
                        current: Audio.sink === modelData
                        icon: ""
                        onPicked: Audio.setDefaultSink(modelData)
                    }
                }

                Repeater {
                    model: Audio.sources.length > 1 ? Audio.sources : []
                    delegate: DeviceRow {
                        required property var modelData
                        width: deviceColumn.width
                        node: modelData
                        current: Audio.source === modelData
                        icon: ""
                        onPicked: Audio.setDefaultSource(modelData)
                    }
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
