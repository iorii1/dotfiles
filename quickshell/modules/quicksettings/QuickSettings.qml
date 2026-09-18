import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../config"
import "../../services"
import "../common"

// One panel for the switches that were scattered or missing.
//
// ToggleRow has carried an expandable/expandedContent/Loader mechanism since it
// was written, and all three of its call sites disabled it -- it was built for
// a panel like this, which never got written. "Keep awake" meanwhile lived
// inside the *calendar* popup, because there was nowhere else to put it.
ShellPanel {
    id: qsWindow

    name: "quickSettings"

    IpcHandler {
        target: "quicksettings"
        function toggle(): void { UiState.toggle("quickSettings") }
        function open(): void { UiState.show("quickSettings") }
        function close(): void { UiState.hide("quickSettings") }
    }

    onOpenChanged: if (open) NightLight.refresh()

    // Only one row expanded at a time; the panel would otherwise grow past the
    // screen with everything open.
    property string expandedRow: ""

    function _expand(name) {
        qsWindow.expandedRow = (qsWindow.expandedRow === name) ? "" : name
    }

    PopupCard {
        id: card
        anchors.right: parent.right
        anchors.rightMargin: Appearance.spacingLarge
        readonly property int restY: BarConfig.barHeight + BarConfig.barMargin + Appearance.spacingSmall
        width: 320
        height: content.implicitHeight + Appearance.spacingNormal * 2

        opacity: UiState.quickSettingsOpen ? 1 : 0
        y: UiState.quickSettingsOpen ? restY : restY - 12
        scale: UiState.quickSettingsOpen ? 1 : Appearance.popupFromScale
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
            spacing: Appearance.spacingSmall

            // ---- Appearance -------------------------------------------------

            ToggleRow {
                Layout.fillWidth: true
                icon: Theme.isDark ? "" : ""
                label: Theme.applying ? "Applying theme…" : (Theme.isDark ? "Dark mode" : "Light mode")
                checked: Theme.isDark
                pulsing: Theme.applying
                active: UiState.quickSettingsOpen
                entranceDelay: 0
                expandable: false
                onToggleRequested: Theme.toggle()
            }

            // ---- Night light ------------------------------------------------

            ToggleRow {
                Layout.fillWidth: true
                icon: ""
                label: "Night light"
                checked: NightLight.enabled
                active: UiState.quickSettingsOpen
                entranceDelay: 40
                expandable: true
                expanded: qsWindow.expandedRow === "night"
                onToggleRequested: NightLight.toggle()
                onExpandRequested: qsWindow._expand("night")

                expandedContent: Component {
                    ColumnLayout {
                        width: parent ? parent.width : 0
                        spacing: 2

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                Layout.fillWidth: true
                                text: "Night temperature"
                                color: Colors.textSecondary
                                font.family: Appearance.fontFamily
                                font.pixelSize: Appearance.fontSizeSmall
                            }
                            Text {
                                text: NightLight.nightTemp + "K"
                                color: Colors.textSecondary
                                font.family: Appearance.fontFamily
                                font.pixelSize: Appearance.fontSizeSmall
                            }
                        }

                        Slider {
                            Layout.fillWidth: true
                            // 2500K (very warm) to 6500K (daylight).
                            value: (NightLight.nightTemp - 2500) / 4000
                            onMoved: (v) => NightLight.setTemps(
                                Math.round(2500 + v * 4000), NightLight.dayTemp)
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: !NightLight.hasLocation
                            text: "No location yet — using 07:00–19:00 until the weather service reports one."
                            color: Colors.textSecondary
                            opacity: 0.7
                            font.family: Appearance.fontFamily
                            font.pixelSize: Appearance.fontSizeSmall
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }

            // ---- Keep awake --------------------------------------------------

            ToggleRow {
                Layout.fillWidth: true
                icon: ""
                label: "Keep awake"
                checked: IdleInhibit.keepAwake
                active: UiState.quickSettingsOpen
                entranceDelay: 80
                expandable: false
                onToggleRequested: IdleInhibit.toggle()
            }

            Text {
                Layout.fillWidth: true
                visible: IdleInhibit.lastError !== ""
                text: IdleInhibit.lastError
                color: Colors.error
                font.family: Appearance.fontFamily
                font.pixelSize: Appearance.fontSizeSmall
                wrapMode: Text.WordWrap
            }

            // ---- Do not disturb ----------------------------------------------

            ToggleRow {
                Layout.fillWidth: true
                icon: Notifications.dnd ? "" : ""
                label: "Do not disturb"
                checked: Notifications.dnd
                active: UiState.quickSettingsOpen
                entranceDelay: 120
                expandable: Notifications.mutedApps.length > 0
                expanded: qsWindow.expandedRow === "dnd"
                onToggleRequested: Notifications.dnd = !Notifications.dnd
                onExpandRequested: qsWindow._expand("dnd")

                expandedContent: Component {
                    ColumnLayout {
                        width: parent ? parent.width : 0
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: "Muted apps"
                            color: Colors.textSecondary
                            font.family: Appearance.fontFamily
                            font.pixelSize: Appearance.fontSizeSmall
                        }

                        Repeater {
                            model: Notifications.mutedApps

                            RowLayout {
                                id: mutedRow
                                required property var modelData
                                Layout.fillWidth: true

                                Text {
                                    Layout.fillWidth: true
                                    text: mutedRow.modelData
                                    color: Colors.textPrimary
                                    font.family: Appearance.fontFamily
                                    font.pixelSize: Appearance.fontSizeSmall
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: "unmute"
                                    color: unmuteFx.containsMouse ? Colors.primary : Colors.textSecondary
                                    font.family: Appearance.fontFamily
                                    font.pixelSize: Appearance.fontSizeSmall
                                    Behavior on color { ColorAnimation { duration: Appearance.animFast } }

                                    PressFx {
                                        id: unmuteFx
                                        anchors.fill: parent
                                        anchors.margins: -6
                                        hoverScale: 1.0
                                        pressScale: Appearance.pressScaleSubtle
                                        onActivated: Notifications.toggleAppMute(mutedRow.modelData)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Colors.outline; opacity: 0.4 }

            // ---- Volume ------------------------------------------------------

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
        }
    }
}
