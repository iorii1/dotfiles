import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../config"
import "../../services"
import "../common"

PanelWindow {
    id: qsWindow

    visible: UiState.quickSettingsOpen
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-popup"
    exclusionMode: ExclusionMode.Ignore
    focusable: false
    color: "transparent"

    anchors { top: true; bottom: true; left: true; right: true }

    property real volumeValue: 0
    property real brightnessValue: 0

    IpcHandler {
        target: "quicksettings"
        function toggle(): void { UiState.quickSettingsOpen = !UiState.quickSettingsOpen }
        function open(): void { UiState.quickSettingsOpen = true }
        function close(): void { UiState.quickSettingsOpen = false }
    }

    property bool sliderRowsEntered: false

    onVisibleChanged: {
        if (visible) {
            Network.refreshStatus()
            Bluetooth.refresh()
            PowerProfile.refresh()
            volQuery.running = true
            briQuery.running = true
            qsWindow.sliderRowsEntered = false
            sliderEntranceTimer.restart()
        } else {
            qsWindow.sliderRowsEntered = false
        }
    }

    Timer {
        id: sliderEntranceTimer
        interval: 210
        onTriggered: qsWindow.sliderRowsEntered = true
    }

    MouseArea {
        anchors.fill: parent
        onClicked: UiState.quickSettingsOpen = false
    }

    Process {
        id: volQuery
        command: ["bash", "-c", "wpctl get-volume @DEFAULT_SINK@"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = text.match(/Volume:\s*([\d.]+)/)
                qsWindow.volumeValue = m ? Math.min(1, parseFloat(m[1])) : 0
            }
        }
    }
    Process { id: volSet }
    Timer {
        id: volDebounce
        interval: 60
        onTriggered: {
            volSet.command = ["bash", "-c", "wpctl set-volume @DEFAULT_SINK@ " + qsWindow.volumeValue.toFixed(2)]
            volSet.running = true
        }
    }
    function setVolume(v) { qsWindow.volumeValue = v; volDebounce.restart() }

    Process {
        id: briQuery
        command: ["bash", "-c", "brightnessctl -m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(",")
                const pct = parts.length >= 4 ? parseInt(parts[3]) : 0
                qsWindow.brightnessValue = (isNaN(pct) ? 0 : pct) / 100
            }
        }
    }
    Process { id: briSet }
    Timer {
        id: briDebounce
        interval: 60
        onTriggered: {
            briSet.command = ["bash", "-c", "brightnessctl set " + Math.round(qsWindow.brightnessValue * 100) + "%"]
            briSet.running = true
        }
    }
    function setBrightness(v) { qsWindow.brightnessValue = v; briDebounce.restart() }

    PopupCard {
        id: card
        anchors.right: parent.right
        anchors.rightMargin: Appearance.spacingLarge
        readonly property int restY: Appearance.barHeight + Appearance.barMargin + Appearance.spacingSmall
        width: 320
        height: content.implicitHeight + Appearance.spacingNormal * 2

        opacity: UiState.quickSettingsOpen ? 1 : 0
        y: UiState.quickSettingsOpen ? restY : restY - 12
        scale: UiState.quickSettingsOpen ? 1 : 0.96
        Behavior on opacity { NumberAnimation { duration: Appearance.animNormal; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: Appearance.animNormal; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: Appearance.animNormal; easing.type: Easing.OutBack; easing.overshoot: Appearance.overshootCard } }
        Behavior on height { NumberAnimation { duration: Appearance.animNormal; easing.type: Easing.OutCubic } }

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            id: content
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Appearance.spacingNormal
            spacing: Appearance.spacingNormal

            ToggleRow {
                Layout.fillWidth: true
                icon: ""
                label: Network.connected ? Network.ssid : "Wi-Fi"
                checked: Network.wifiEnabled
                active: UiState.quickSettingsOpen
                entranceDelay: 0
                expanded: UiState.quickSettingsSection === "wifi"
                onToggleRequested: Network.toggleWifi()
                onExpandRequested: UiState.quickSettingsSection = (UiState.quickSettingsSection === "wifi" ? "" : "wifi")

                expandedContent: Column {
                    width: parent ? parent.width : 0
                    spacing: 2

                    Repeater {
                        model: Network.networks

                        Rectangle {
                            id: netRow
                            required property var modelData
                            required property int index
                            width: parent ? parent.width : 0
                            height: 34
                            radius: Appearance.radiusSmall
                            color: netFx.containsMouse ? Colors.surfaceContainerHigh : "transparent"
                            Behavior on color { ColorAnimation { duration: Appearance.animFast } }

                            property real entranceScale: 0.85
                            property real entranceOpacity: 0.0
                            scale: entranceScale
                            opacity: entranceOpacity
                            transformOrigin: Item.Left

                            Component.onCompleted: netEntranceAnim.start()
                            SequentialAnimation {
                                id: netEntranceAnim
                                PauseAnimation { duration: Math.min(netRow.index * 25, 200) }
                                ParallelAnimation {
                                    NumberAnimation { target: netRow; property: "entranceScale"; to: 1.0; duration: 220; easing.type: Easing.OutBack; easing.overshoot: 1.4 }
                                    NumberAnimation { target: netRow; property: "entranceOpacity"; to: 1.0; duration: 180; easing.type: Easing.OutQuad }
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: Appearance.spacingSmall
                                anchors.rightMargin: Appearance.spacingSmall
                                spacing: Appearance.spacingSmall

                                Text {
                                    text: modelData.active ? "" : (modelData.secure ? "" : "")
                                    color: modelData.active ? Colors.primary : Colors.textSecondary
                                    font.family: Appearance.fontFamily
                                    font.pixelSize: Appearance.fontSizeSmall
                                    Layout.preferredWidth: 14
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.ssid
                                    color: Colors.textPrimary
                                    font.family: Appearance.fontFamily
                                    font.pixelSize: Appearance.fontSizeSmall
                                    elide: Text.ElideRight
                                }
                            }

                            MouseArea {
                                id: netFx
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Network.connectTo(modelData.ssid)
                            }
                        }
                    }

                    Text {
                        visible: Network.scanning
                        text: "Scanning…"
                        color: Colors.textSecondary
                        font.family: Appearance.fontFamily
                        font.pixelSize: Appearance.fontSizeSmall
                    }
                }
            }

            ToggleRow {
                Layout.fillWidth: true
                icon: ""
                label: "Bluetooth"
                checked: Bluetooth.powered
                active: UiState.quickSettingsOpen
                entranceDelay: 70
                expanded: UiState.quickSettingsSection === "bluetooth"
                onToggleRequested: Bluetooth.toggle()
                onExpandRequested: UiState.quickSettingsSection = (UiState.quickSettingsSection === "bluetooth" ? "" : "bluetooth")

                expandedContent: Column {
                    width: parent ? parent.width : 0
                    spacing: 2

                    Repeater {
                        model: Bluetooth.devices

                        Rectangle {
                            id: btRow
                            required property var modelData
                            required property int index
                            width: parent ? parent.width : 0
                            height: 34
                            radius: Appearance.radiusSmall
                            color: btFx.containsMouse ? Colors.surfaceContainerHigh : "transparent"
                            Behavior on color { ColorAnimation { duration: Appearance.animFast } }

                            property real entranceScale: 0.85
                            property real entranceOpacity: 0.0
                            scale: entranceScale
                            opacity: entranceOpacity
                            transformOrigin: Item.Left

                            Component.onCompleted: btEntranceAnim.start()
                            SequentialAnimation {
                                id: btEntranceAnim
                                PauseAnimation { duration: Math.min(btRow.index * 25, 200) }
                                ParallelAnimation {
                                    NumberAnimation { target: btRow; property: "entranceScale"; to: 1.0; duration: 220; easing.type: Easing.OutBack; easing.overshoot: 1.4 }
                                    NumberAnimation { target: btRow; property: "entranceOpacity"; to: 1.0; duration: 180; easing.type: Easing.OutQuad }
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: Appearance.spacingSmall
                                anchors.rightMargin: Appearance.spacingSmall
                                spacing: Appearance.spacingSmall

                                Text {
                                    text: modelData.connected ? "" : ""
                                    color: Colors.primary
                                    font.family: Appearance.fontFamily
                                    font.pixelSize: Appearance.fontSizeSmall
                                    Layout.preferredWidth: 14
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.name
                                    color: Colors.textPrimary
                                    font.family: Appearance.fontFamily
                                    font.pixelSize: Appearance.fontSizeSmall
                                    elide: Text.ElideRight
                                }
                            }

                            MouseArea {
                                id: btFx
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: modelData.connected ? Bluetooth.disconnectDevice(modelData.mac) : Bluetooth.connectDevice(modelData.mac)
                            }
                        }
                    }
                }
            }

            ToggleRow {
                Layout.fillWidth: true
                icon: ""
                label: "Do Not Disturb"
                checked: Notifications.dnd
                active: UiState.quickSettingsOpen
                entranceDelay: 140
                expandable: false
                onToggleRequested: Notifications.dnd = !Notifications.dnd
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                opacity: qsWindow.sliderRowsEntered ? 1 : 0
                scale: qsWindow.sliderRowsEntered ? 1 : 0.85
                transformOrigin: Item.Left
                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
                Behavior on scale { NumberAnimation { duration: 340; easing.type: Easing.OutBack; easing.overshoot: 1.6 } }

                Text {
                    text: "Power Mode"
                    color: Colors.textSecondary
                    font.family: Appearance.fontFamily
                    font.pixelSize: Appearance.fontSizeSmall
                }

                SegmentedControl {
                    Layout.fillWidth: true
                    options: [
                        { value: "power-saver", label: "Saver" },
                        { value: "balanced", label: "Balanced" },
                        { value: "performance", label: "Performance" }
                    ]
                    currentValue: PowerProfile.current
                    onSelected: (v) => PowerProfile.set(v)
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Colors.outline; opacity: 0.4 }

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacingNormal
                opacity: qsWindow.sliderRowsEntered ? 1 : 0
                scale: qsWindow.sliderRowsEntered ? 1 : 0.85
                transformOrigin: Item.Left
                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
                Behavior on scale { NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.6 } }
                DialIcon {
                    icon: ""
                    value: qsWindow.volumeValue
                    accentColor: Colors.primary
                }
                Slider {
                    Layout.fillWidth: true
                    value: qsWindow.volumeValue
                    onMoved: (v) => qsWindow.setVolume(v)
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacingNormal
                opacity: qsWindow.sliderRowsEntered ? 1 : 0
                scale: qsWindow.sliderRowsEntered ? 1 : 0.85
                transformOrigin: Item.Left
                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
                Behavior on scale { NumberAnimation { duration: 380; easing.type: Easing.OutBack; easing.overshoot: 1.6 } }
                DialIcon {
                    icon: ""
                    value: qsWindow.brightnessValue
                    accentColor: Colors.primary
                }
                Slider {
                    Layout.fillWidth: true
                    value: qsWindow.brightnessValue
                    onMoved: (v) => qsWindow.setBrightness(v)
                }
            }
        }
    }
}
