import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../services/"

PopupWindow {
    id: root

    property bool open: false
    property alias hovered: hoverHandler.hovered

    property bool wifiExpanded: false
    property bool btExpanded: false
    property bool outputExpanded: false
    property bool inputExpanded: false
    property var pskTarget: null
    property string pskInput: ""

    implicitWidth: 340
    implicitHeight: content.implicitHeight + 28
    color: "transparent"
    visible: open || closeHold.running

    Timer {
        id: closeHold
        interval: 220
    }
    onOpenChanged: if (!open) closeHold.start()

    HoverHandler { id: hoverHandler }

    Process { id: powerProc }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: 14
        color: "#e61e1e2e"
        border.width: 1
        border.color: "#33cdd6f4"

        opacity: root.open ? 1 : 0
        scale: root.open ? 1 : 0.96
        transformOrigin: Item.Top

        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: 260; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
        }

        ColumnLayout {
            id: content
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 14
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                ToggleChip {
                    Layout.fillWidth: true
                    active: Wifi.enabled
                    iconText: Wifi.enabled ? (Wifi.activeNetwork ? "󰤨" : "󰖩") : "󰤭"
                    label: Wifi.enabled ? (Wifi.activeNetwork ? Wifi.activeNetwork.name : "Wi-Fi") : "Wi-Fi off"
                    expanded: root.wifiExpanded
                    onToggled: Wifi.toggle()
                    onExpandRequested: root.wifiExpanded = !root.wifiExpanded
                }

                ToggleChip {
                    Layout.fillWidth: true
                    active: Bluetooth.enabled
                    iconText: Bluetooth.enabled ? "󰂯" : "󰂲"
                    label: Bluetooth.enabled ? (Bluetooth.connectedDevices.length > 0 ? Bluetooth.connectedDevices[0].name : "Bluetooth") : "Bluetooth off"
                    expanded: root.btExpanded
                    onToggled: Bluetooth.toggle()
                    onExpandRequested: root.btExpanded = !root.btExpanded
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                visible: root.wifiExpanded && Wifi.enabled

                Repeater {
                    model: Wifi.networks

                    delegate: Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: netCol.implicitHeight + 12
                        radius: 8
                        color: modelData.connected ? "#26a6e3a1" : (netHover.hovered ? "#141e1e2e" : "transparent")

                        HoverHandler { id: netHover }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (modelData.connected) {
                                    Wifi.disconnectNetwork(modelData)
                                } else if (modelData.known || Wifi.isOpen(modelData)) {
                                    Wifi.connectNetwork(modelData)
                                } else {
                                    root.pskInput = ""
                                    root.pskTarget = modelData
                                }
                            }
                        }

                        ColumnLayout {
                            id: netCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 6

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: modelData.signalStrength > 66 ? "󰤨" : modelData.signalStrength > 33 ? "󰤥" : "󰤟"
                                    color: "#cdd6f4"
                                    font.pixelSize: 13
                                    font.family: "JetBrainsMono Nerd Font"
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.name
                                    color: "#cdd6f4"
                                    font.pixelSize: 12
                                    font.family: "JetBrainsMono Nerd Font"
                                    elide: Text.ElideRight
                                }

                                Text {
                                    visible: modelData.connected
                                    text: "󰄬"
                                    color: "#a6e3a1"
                                    font.pixelSize: 12
                                    font.family: "JetBrainsMono Nerd Font"
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6
                                visible: root.pskTarget === modelData

                                Rectangle {
                                    Layout.fillWidth: true
                                    implicitHeight: 26
                                    radius: 6
                                    color: "#1e1e2e"
                                    border.width: 1
                                    border.color: "#45475a"

                                    TextInput {
                                        anchors.fill: parent
                                        anchors.margins: 6
                                        color: "#cdd6f4"
                                        font.pixelSize: 12
                                        font.family: "JetBrainsMono Nerd Font"
                                        echoMode: TextInput.Password
                                        focus: root.pskTarget === modelData
                                        onTextChanged: root.pskInput = text
                                        onAccepted: {
                                            Wifi.connectWithPsk(modelData, text)
                                            root.pskTarget = null
                                        }
                                    }
                                }

                                Text {
                                    text: "Connect"
                                    color: "#89b4fa"
                                    font.pixelSize: 12
                                    font.family: "JetBrainsMono Nerd Font"

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            Wifi.connectWithPsk(modelData, root.pskInput)
                                            root.pskTarget = null
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                visible: root.btExpanded && Bluetooth.enabled

                Repeater {
                    model: Bluetooth.devices

                    delegate: Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 34
                        radius: 8
                        color: modelData.connected ? "#26a6e3a1" : (btHover.hovered ? "#141e1e2e" : "transparent")

                        HoverHandler { id: btHover }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (modelData.connected) Bluetooth.disconnectDevice(modelData)
                                else if (modelData.paired) Bluetooth.connectDevice(modelData)
                                else Bluetooth.pairDevice(modelData)
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 8

                            Text {
                                text: modelData.paired ? "󰂱" : "󰂯"
                                color: "#cdd6f4"
                                font.pixelSize: 13
                                font.family: "JetBrainsMono Nerd Font"
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.name || modelData.deviceName
                                color: "#cdd6f4"
                                font.pixelSize: 12
                                font.family: "JetBrainsMono Nerd Font"
                                elide: Text.ElideRight
                            }

                            Text {
                                visible: modelData.batteryAvailable
                                text: Math.round(modelData.battery * 100) + "%"
                                color: "#7f849c"
                                font.pixelSize: 11
                                font.family: "JetBrainsMono Nerd Font"
                            }

                            Text {
                                text: modelData.connected ? "󰄬" : (modelData.paired ? "connect" : "pair")
                                color: modelData.connected ? "#a6e3a1" : "#89b4fa"
                                font.pixelSize: 11
                                font.family: "JetBrainsMono Nerd Font"
                            }
                        }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: "#26cdd6f4" }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: [Power.profSaver, Power.profBalanced, Power.profPerformance]

                    delegate: Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 46
                        radius: 10
                        color: Power.profile === modelData ? "#33f9e2af" : (profHover.hovered ? "#141e1e2e" : "transparent")
                        border.width: Power.profile === modelData ? 1 : 0
                        border.color: "#f9e2af"

                        HoverHandler { id: profHover }

                        MouseArea {
                            anchors.fill: parent
                            enabled: modelData !== Power.profPerformance || Power.hasPerformanceProfile
                            onClicked: Power.setProfile(modelData)
                        }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 2

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: Power.icon(modelData)
                                color: Power.profile === modelData ? "#f9e2af" : "#cdd6f4"
                                font.pixelSize: 15
                                font.family: "JetBrainsMono Nerd Font"
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: Power.label(modelData)
                                color: Power.profile === modelData ? "#f9e2af" : "#7f849c"
                                font.pixelSize: 10
                                font.family: "JetBrainsMono Nerd Font"
                            }
                        }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: "#26cdd6f4" }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: Audio.isMuted ? "󰝟" : "󰕾"
                        color: Audio.isMuted ? "#f38ba8" : "#cdd6f4"
                        font.pixelSize: 15
                        font.family: "JetBrainsMono Nerd Font"

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6
                            onClicked: Audio.toggleMute()
                        }
                    }

                    VolumeSlider {
                        Layout.fillWidth: true
                        value: Audio.volume
                        fillColor: "#89b4fa"
                        onMoved: (v) => Audio.setVolume(v)
                    }

                    Text {
                        Layout.preferredWidth: 32
                        text: Math.round(Audio.volume) + "%"
                        color: "#7f849c"
                        font.pixelSize: 11
                        font.family: "JetBrainsMono Nerd Font"
                        horizontalAlignment: Text.AlignRight
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 25
                    spacing: 4

                    Text {
                        Layout.fillWidth: true
                        text: Audio.sink ? Audio.deviceLabel(Audio.sink) : "No output device"
                        color: "#7f849c"
                        font.pixelSize: 10
                        font.family: "JetBrainsMono Nerd Font"
                        elide: Text.ElideRight

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.outputExpanded = !root.outputExpanded
                        }
                    }

                    Text {
                        text: root.outputExpanded ? "󰅃" : "󰅀"
                        color: "#7f849c"
                        font.pixelSize: 10
                        font.family: "JetBrainsMono Nerd Font"

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6
                            onClicked: root.outputExpanded = !root.outputExpanded
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 25
                    spacing: 2
                    visible: root.outputExpanded

                    Repeater {
                        model: Audio.sinks

                        delegate: Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 26
                            radius: 6
                            color: modelData === Audio.sink ? "#1ea6e3a1" : (sinkHover.hovered ? "#141e1e2e" : "transparent")

                            HoverHandler { id: sinkHover }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: Audio.setSink(modelData)
                            }

                            Text {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                text: Audio.deviceLabel(modelData)
                                color: "#cdd6f4"
                                font.pixelSize: 11
                                font.family: "JetBrainsMono Nerd Font"
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: Audio.isInputMuted ? "󰍭" : "󰍬"
                        color: Audio.isInputMuted ? "#f38ba8" : "#cdd6f4"
                        font.pixelSize: 15
                        font.family: "JetBrainsMono Nerd Font"

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6
                            onClicked: Audio.toggleInputMute()
                        }
                    }

                    VolumeSlider {
                        Layout.fillWidth: true
                        value: Audio.inputVolume
                        fillColor: "#a6e3a1"
                        onMoved: (v) => Audio.setInputVolume(v)
                    }

                    Text {
                        Layout.preferredWidth: 32
                        text: Math.round(Audio.inputVolume) + "%"
                        color: "#7f849c"
                        font.pixelSize: 11
                        font.family: "JetBrainsMono Nerd Font"
                        horizontalAlignment: Text.AlignRight
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 25
                    spacing: 4

                    Text {
                        Layout.fillWidth: true
                        text: Audio.source ? Audio.deviceLabel(Audio.source) : "No input device"
                        color: "#7f849c"
                        font.pixelSize: 10
                        font.family: "JetBrainsMono Nerd Font"
                        elide: Text.ElideRight

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.inputExpanded = !root.inputExpanded
                        }
                    }

                    Text {
                        text: root.inputExpanded ? "󰅃" : "󰅀"
                        color: "#7f849c"
                        font.pixelSize: 10
                        font.family: "JetBrainsMono Nerd Font"

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6
                            onClicked: root.inputExpanded = !root.inputExpanded
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 25
                    spacing: 2
                    visible: root.inputExpanded

                    Repeater {
                        model: Audio.sources

                        delegate: Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 26
                            radius: 6
                            color: modelData === Audio.source ? "#1ea6e3a1" : (sourceHover.hovered ? "#141e1e2e" : "transparent")

                            HoverHandler { id: sourceHover }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: Audio.setSource(modelData)
                            }

                            Text {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                text: Audio.deviceLabel(modelData)
                                color: "#cdd6f4"
                                font.pixelSize: 11
                                font.family: "JetBrainsMono Nerd Font"
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: "#26cdd6f4"; visible: Battery.isPresent }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                visible: Battery.isPresent

                Text {
                    text: Battery.isCharging ? "󰂄" : "󰁹"
                    color: Battery.percentage < 20 ? "#f38ba8" : "#f9e2af"
                    font.pixelSize: 15
                    font.family: "JetBrainsMono Nerd Font"
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        text: Battery.percentage + "%"
                        color: "#cdd6f4"
                        font.pixelSize: 12
                        font.family: "JetBrainsMono Nerd Font"
                    }

                    Text {
                        text: Battery.statusLabel
                        color: "#7f849c"
                        font.pixelSize: 10
                        font.family: "JetBrainsMono Nerd Font"
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: "#26cdd6f4" }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 40
                radius: 10
                color: clipboardHover.hovered ? "#141e1e2e" : "transparent"

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }

                HoverHandler { id: clipboardHover }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        clipboardPopup.open = !clipboardPopup.open
                        if (clipboardPopup.open) wallpaperPopup.open = false
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8

                    Text {
                        text: "󰅍"
                        color: "#fab387"
                        font.pixelSize: 15
                        font.family: "JetBrainsMono Nerd Font"
                    }
                    Text {
                        Layout.fillWidth: true
                        text: "Clipboard History"
                        color: "#cdd6f4"
                        font.pixelSize: 12
                        font.family: "JetBrainsMono Nerd Font"
                    }
                    Text {
                        text: "󰅂"
                        color: "#7f849c"
                        font.pixelSize: 11
                        font.family: "JetBrainsMono Nerd Font"
                    }
                }
            }

            ClipboardPopup {
                id: clipboardPopup
                parentWindow: root.parentWindow

                // Sit just to the left of the control center panel itself,
                // at the same vertical position.
                relativeX: root.parentWindow
                    ? root.parentWindow.width - root.implicitWidth - 14 - clipboardPopup.implicitWidth - 14
                    : 0
                relativeY: root.parentWindow ? root.parentWindow.height + 8 : 8
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 40
                radius: 10
                color: wallpaperHover.hovered ? "#141e1e2e" : "transparent"

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }

                HoverHandler { id: wallpaperHover }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        wallpaperPopup.open = !wallpaperPopup.open
                        if (wallpaperPopup.open) clipboardPopup.open = false
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8

                    Text {
                        text: "󰸉"
                        color: "#fab387"
                        font.pixelSize: 15
                        font.family: "JetBrainsMono Nerd Font"
                    }
                    Text {
                        Layout.fillWidth: true
                        text: "Wallpaper"
                        color: "#cdd6f4"
                        font.pixelSize: 12
                        font.family: "JetBrainsMono Nerd Font"
                    }
                    Text {
                        text: "󰅂"
                        color: "#7f849c"
                        font.pixelSize: 11
                        font.family: "JetBrainsMono Nerd Font"
                    }
                }
            }

            WallpaperPopup {
                id: wallpaperPopup
                parentWindow: root.parentWindow

                relativeX: root.parentWindow
                    ? root.parentWindow.width - root.implicitWidth - 14 - wallpaperPopup.implicitWidth - 14
                    : 0
                relativeY: root.parentWindow ? root.parentWindow.height + 8 : 8
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: "#26cdd6f4" }

            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 2
                spacing: 8

                Repeater {
                    model: [
                        { icon: "󰌾", cmd: ["swaylock"], danger: false },
                        { icon: "󰤄", cmd: ["systemctl", "suspend"], danger: false },
                        { icon: "󰜉", cmd: ["systemctl", "reboot"], danger: true },
                        { icon: "󰐥", cmd: ["systemctl", "poweroff"], danger: true },
                        { icon: "󰍃", cmd: ["loginctl", "terminate-session", "self"], danger: true }
                    ]

                    delegate: Rectangle {
                        id: pmDelegate
                        Layout.fillWidth: true
                        implicitHeight: 36
                        radius: 10
                        property bool confirming: false
                        color: confirming ? "#33f38ba8" : (pmHover.hovered ? "#141e1e2e" : "transparent")

                        HoverHandler { id: pmHover }

                        Timer {
                            id: confirmTimer
                            interval: 2200
                            onTriggered: pmDelegate.confirming = false
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (!modelData.danger || pmDelegate.confirming) {
                                    powerProc.command = modelData.cmd
                                    powerProc.running = true
                                    pmDelegate.confirming = false
                                } else {
                                    pmDelegate.confirming = true
                                    confirmTimer.restart()
                                }
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: pmDelegate.confirming ? "󰄬" : modelData.icon
                            color: pmDelegate.confirming ? "#f38ba8" : "#cdd6f4"
                            font.pixelSize: 14
                            font.family: "JetBrainsMono Nerd Font"
                        }
                    }
                }
            }
        }
    }

    component ToggleChip: Rectangle {
        id: chip
        property bool active: false
        property string iconText: ""
        property string label: ""
        property bool expanded: false
        signal toggled()
        signal expandRequested()

        implicitHeight: 46
        radius: 10
        color: active ? "#26a6e3a1" : (chipHover.hovered ? "#141e1e2e" : "#0d1e1e2e")
        border.width: active ? 1 : 0
        border.color: "#a6e3a1"

        HoverHandler { id: chipHover }

        MouseArea {
            anchors.fill: parent
            onClicked: chip.toggled()
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 8
            spacing: 8

            Text {
                text: chip.iconText
                color: chip.active ? "#a6e3a1" : "#cdd6f4"
                font.pixelSize: 15
                font.family: "JetBrainsMono Nerd Font"
            }

            Text {
                Layout.fillWidth: true
                text: chip.label
                color: chip.active ? "#a6e3a1" : "#cdd6f4"
                font.pixelSize: 11
                font.family: "JetBrainsMono Nerd Font"
                elide: Text.ElideRight
            }

            Text {
                text: chip.expanded ? "󰅃" : "󰅀"
                color: "#7f849c"
                font.pixelSize: 10
                font.family: "JetBrainsMono Nerd Font"

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    onClicked: chip.expandRequested()
                }
            }
        }
    }

    component VolumeSlider: Item {
        id: sliderRoot
        property real value: 0
        property color fillColor: "#89b4fa"
        signal moved(real value)

        implicitHeight: 18

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 6
            radius: 3
            color: "#26cdd6f4"

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, sliderRoot.value / 100))
                height: parent.height
                radius: 3
                color: sliderRoot.fillColor
            }
        }

        MouseArea {
            anchors.fill: parent
            preventStealing: true
            onPressed: (mouse) => sliderRoot.moved(Math.max(0, Math.min(100, mouse.x / width * 100)))
            onPositionChanged: (mouse) => { if (pressed) sliderRoot.moved(Math.max(0, Math.min(100, mouse.x / width * 100))) }
        }
    }
}
