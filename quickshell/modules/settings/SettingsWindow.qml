import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../config"
import "../../services"
import "../common"

ShellPanel {
    id: settingsWindow

    name: "settings"

    readonly property var sliders: [
        { key: "barHeight", label: "Height", min: 24, max: 56, step: 1, suffix: "px" },
        { key: "barMargin", label: "Side margin", min: 0, max: 24, step: 1, suffix: "px" },
        { key: "barRadius", label: "Corner radius", min: 0, max: 28, step: 1, suffix: "px" },
        { key: "barOpacity", label: "Opacity", min: 0.3, max: 1.0, step: 0.01, suffix: "%" },
        { key: "animScale", label: "Animation speed", min: 0.0, max: 2.0, step: 0.05, suffix: "x" },
        { key: "roundingScale", label: "Roundness", min: 0.0, max: 2.0, step: 0.05, suffix: "x" }
    ]

    readonly property var widgets: [
        { key: "showWorkspaces", label: "Workspaces", icon: "" },
        { key: "showWindowTitle", label: "Window title", icon: "" },
        { key: "showTaskbar", label: "Dock", icon: "" },
        { key: "showCava", label: "Audio visualizer", icon: "" },
        { key: "showMedia", label: "Media", icon: "" },
        { key: "showNotifications", label: "Notification bell", icon: "" },
        { key: "showClock", label: "Clock", icon: "" },
        { key: "showTray", label: "System tray", icon: "" },
        { key: "showVolume", label: "Volume", icon: "" },
        { key: "showDashboard", label: "System monitor", icon: "" },
        { key: "showQuickSettings", label: "Quick settings", icon: "" },
        { key: "showBattery", label: "Battery", icon: "" },
        { key: "showWifi", label: "Wi-Fi", icon: "" },
        { key: "showBluetooth", label: "Bluetooth", icon: "" },
        { key: "showPower", label: "Power button", icon: "" }
    ]

    IpcHandler {
        target: "settings"
        function toggle(): void { UiState.toggle("settings") }
        function open(): void { UiState.show("settings") }
        function close(): void { UiState.hide("settings") }
    }

    // Slider and Toggle both write their own value imperatively on interaction,
    // which tears down any incoming binding -- so control state is pushed back
    // in explicitly whenever the values change from elsewhere (e.g. Reset).
    function syncControls() {
        for (let i = 0; i < sliderRepeater.count; i++) {
            const item = sliderRepeater.itemAt(i)
            if (item) item.syncFromConfig()
        }
        for (let i = 0; i < widgetRepeater.count; i++) {
            const item = widgetRepeater.itemAt(i)
            if (item) item.syncFromConfig()
        }
    }

    onVisibleChanged: if (visible) syncControls()

    PopupCard {
        id: card
        width: 460
        height: Math.min(720, layout.implicitHeight + Appearance.spacingLarge * 2)
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.12

        opacity: UiState.settingsOpen ? 1 : 0
        scale: UiState.settingsOpen ? 1 : Appearance.popupFromScale
        Behavior on opacity { Anim {} }
        Behavior on scale { PopAnim {} }
        Behavior on height { Anim {} }

        MouseArea { anchors.fill: parent }

        focus: UiState.settingsOpen

        ColumnLayout {
            id: layout
            anchors.fill: parent
            anchors.margins: Appearance.spacingLarge
            spacing: Appearance.spacingNormal

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacingSmall

                Text {
                    text: "Bar Settings"
                    color: Colors.textPrimary
                    font.family: Appearance.fontFamily
                    font.pixelSize: Appearance.fontSizeLarge
                    font.bold: true
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    implicitWidth: resetLabel.implicitWidth + Appearance.spacingNormal * 2
                    implicitHeight: 28
                    radius: Appearance.radiusSmall
                    color: resetFx.containsMouse ? Colors.surfaceContainerHigh : "transparent"
                    border.width: 1
                    border.color: Colors.alpha(Colors.outline, 0.3)
                    Behavior on color { ColorAnimation { duration: Appearance.animFast } }

                    scale: resetFx.gestureScale

                    Text {
                        id: resetLabel
                        anchors.centerIn: parent
                        text: "Reset"
                        color: Colors.textSecondary
                        font.family: Appearance.fontFamily
                        font.pixelSize: Appearance.fontSizeSmall
                    }

                    PressFx {
                        id: resetFx
                        hoverScale: 1.0
                        pressScale: Appearance.pressScaleSubtle
                        anchors.fill: parent
                        onActivated: {
                            BarConfig.reset()
                            settingsWindow.syncControls()
                        }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Colors.outline; opacity: 0.4 }

            Text {
                text: "Layout"
                color: Colors.textSecondary
                font.family: Appearance.fontFamily
                font.pixelSize: Appearance.fontSizeSmall
                font.bold: true
            }

            Repeater {
                id: sliderRepeater
                model: settingsWindow.sliders

                RowLayout {
                    id: sliderRow
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: Appearance.spacingNormal

                    readonly property real span: modelData.max - modelData.min
                    readonly property real current: BarConfig[modelData.key]

                    function syncFromConfig() {
                        slider.value = span > 0 ? (current - modelData.min) / span : 0
                    }

                    Component.onCompleted: syncFromConfig()

                    Text {
                        Layout.preferredWidth: 110
                        text: sliderRow.modelData.label
                        color: Colors.textPrimary
                        font.family: Appearance.fontFamily
                        font.pixelSize: Appearance.fontSizeNormal
                    }

                    Slider {
                        id: slider
                        Layout.fillWidth: true
                        onMoved: (v) => {
                            const raw = sliderRow.modelData.min + v * sliderRow.span
                            const step = sliderRow.modelData.step
                            const snapped = Math.round(raw / step) * step
                            BarConfig[sliderRow.modelData.key] = snapped
                            BarConfig.save()
                        }
                    }

                    Text {
                        Layout.preferredWidth: 46
                        horizontalAlignment: Text.AlignRight
                        text: {
                            const v = sliderRow.current
                            if (sliderRow.modelData.suffix === "%") return Math.round(v * 100) + "%"
                            if (sliderRow.modelData.suffix === "x") return v.toFixed(2) + "x"
                            return v + "px"
                        }
                        color: Colors.textSecondary
                        font.family: Appearance.fontFamilyMono
                        font.pixelSize: Appearance.fontSizeSmall
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Colors.outline; opacity: 0.4 }

            Text {
                text: "Widgets"
                color: Colors.textSecondary
                font.family: Appearance.fontFamily
                font.pixelSize: Appearance.fontSizeSmall
                font.bold: true
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Repeater {
                    id: widgetRepeater
                    model: settingsWindow.widgets

                    RowLayout {
                        id: widgetRow
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: Appearance.spacingSmall

                        function syncFromConfig() {
                            widgetToggle.checked = BarConfig[modelData.key]
                        }

                        Component.onCompleted: syncFromConfig()

                        Text {
                            Layout.preferredWidth: 22
                            text: widgetRow.modelData.icon
                            color: Colors.textSecondary
                            font.family: Appearance.fontFamilyIcons
                            font.pixelSize: Appearance.fontSizeNormal
                        }

                        Text {
                            Layout.fillWidth: true
                            text: widgetRow.modelData.label
                            color: Colors.textPrimary
                            font.family: Appearance.fontFamily
                            font.pixelSize: Appearance.fontSizeNormal
                        }

                        Toggle {
                            id: widgetToggle
                            onToggled: (checked) => {
                                BarConfig[widgetRow.modelData.key] = checked
                                BarConfig.save()
                            }
                        }
                    }
                }
            }
        }
    }
}
