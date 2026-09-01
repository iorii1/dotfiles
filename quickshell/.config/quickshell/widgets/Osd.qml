import QtQuick
import QtQuick.Layouts
import Quickshell
import "../services"

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: osdWindow
            required property var modelData
            screen: modelData

            anchors { bottom: true }
            margins.bottom: 46

            implicitWidth: 280
            implicitHeight: 64
            exclusiveZone: 0
            color: "transparent"

            property string kind: "" // "volume" | "brightness"
            property real value: 0
            property bool muted: false

            property bool osdVisible: false
            visible: osdVisible || closeHold.running

            Timer {
                id: hideTimer
                interval: 1500
                onTriggered: osdWindow.osdVisible = false
            }
            Timer {
                id: closeHold
                interval: 200
            }
            onOsdVisibleChanged: if (!osdVisible) closeHold.start()

            function show(newKind, newValue, newMuted) {
                kind = newKind
                value = newValue
                muted = newMuted ?? false
                osdVisible = true
                hideTimer.restart()
            }

            Connections {
                target: Audio
                function onVolumeChanged() { osdWindow.show("volume", Audio.volume, Audio.isMuted) }
                function onIsMutedChanged() { osdWindow.show("volume", Audio.volume, Audio.isMuted) }
            }

            Connections {
                target: Brightness
                function onLevelChanged() { osdWindow.show("brightness", Brightness.level, false) }
            }

            readonly property string icon: {
                if (kind === "brightness") {
                    if (value >= 66) return "󰃠"
                    if (value >= 33) return "󰃟"
                    return "󰃞"
                }
                if (muted) return "󰝟"
                if (value >= 66) return "󰕾"
                if (value >= 33) return "󰖀"
                if (value > 0) return "󰕿"
                return "󰸈"
            }

            Rectangle {
                anchors.fill: parent
                radius: 16
                color: "#e61e1e2e"
                border.width: 1
                border.color: "#33cdd6f4"

                opacity: osdWindow.osdVisible ? 1 : 0
                scale: osdWindow.osdVisible ? 1 : 0.9
                transformOrigin: Item.Bottom

                Behavior on opacity {
                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                }
                Behavior on scale {
                    NumberAnimation { duration: 260; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 14

                    Text {
                        text: osdWindow.icon
                        color: osdWindow.muted ? "#f38ba8" : "#fab387"
                        font.pixelSize: 22
                        font.family: "JetBrainsMono Nerd Font"

                        Behavior on color {
                            ColorAnimation { duration: 200 }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 6
                        radius: 3
                        color: "#33cdd6f4"

                        Rectangle {
                            height: parent.height
                            radius: 3
                            width: parent.width * Math.max(0, Math.min(100, osdWindow.muted ? 0 : osdWindow.value)) / 100
                            color: osdWindow.muted ? "#f38ba8" : "#fab387"

                            Behavior on width {
                                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                            }
                        }
                    }

                    Text {
                        text: (osdWindow.muted ? 0 : Math.round(osdWindow.value)) + "%"
                        color: "#cdd6f4"
                        font.pixelSize: 13
                        font.family: "JetBrainsMono Nerd Font"
                        Layout.preferredWidth: 34
                    }
                }
            }
        }
    }
}
