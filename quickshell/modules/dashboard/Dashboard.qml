import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../config"
import "../../services"
import "../common"

// What the machine is doing. The shell had no system monitoring at all, so
// this is CPU, memory, temperature, disk and network in one place.
ShellPanel {
    id: dashWindow

    name: "dashboard"

    IpcHandler {
        target: "dashboard"
        function toggle(): void { UiState.toggle("dashboard") }
        function open(): void { UiState.show("dashboard") }
        function close(): void { UiState.hide("dashboard") }
    }

    PopupCard {
        id: card
        anchors.right: parent.right
        anchors.rightMargin: Appearance.spacingLarge
        readonly property int restY: BarConfig.barHeight + BarConfig.barMargin + Appearance.spacingSmall
        width: 300
        height: content.implicitHeight + Appearance.spacingNormal * 2

        opacity: UiState.dashboardOpen ? 1 : 0
        y: UiState.dashboardOpen ? restY : restY - 12
        scale: UiState.dashboardOpen ? 1 : Appearance.popupFromScale
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

            RowLayout {
                Layout.fillWidth: true

                Text {
                    Layout.fillWidth: true
                    text: "System"
                    color: Colors.textPrimary
                    font.family: Appearance.fontFamily
                    font.bold: true
                    font.pixelSize: Appearance.fontSizeNormal
                }

                Text {
                    text: Resources.cpuCores > 0 ? Resources.cpuCores + " cores" : ""
                    color: Colors.textSecondary
                    font.family: Appearance.fontFamily
                    font.pixelSize: Appearance.fontSizeSmall
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Colors.outline; opacity: 0.4 }

            StatRow {
                Layout.fillWidth: true
                icon: ""
                label: "Processor"
                value: Math.round(Resources.cpuUsage * 100) + "%"
                fraction: Resources.cpuUsage
                warnAbove: 0.9
            }

            StatRow {
                Layout.fillWidth: true
                // database; the memory-chip glyph U+F538 is not in
                // JetBrainsMono Nerd Font and would render as tofu
                icon: ""
                label: "Memory"
                value: Resources.formatBytes(Resources.memoryUsed) + " / " + Resources.formatBytes(Resources.memoryTotal)
                fraction: Resources.memoryUsage
                warnAbove: 0.9
            }

            // Hidden rather than shown as zero when no sensor was found -- not
            // every machine exposes a package temperature.
            StatRow {
                Layout.fillWidth: true
                visible: Resources.temperature > 0
                icon: ""
                label: "Temperature"
                value: Math.round(Resources.temperature) + "°C"
                // 30-100C is the range worth seeing; below 30 the bar would
                // read empty on an idle machine that is working perfectly.
                fraction: Math.max(0, (Resources.temperature - 30) / 70)
                warnAbove: (85 - 30) / 70
            }

            StatRow {
                Layout.fillWidth: true
                icon: ""
                label: "Disk"
                value: Resources.formatBytes(Resources.diskUsed) + " / " + Resources.formatBytes(Resources.diskTotal)
                fraction: Resources.diskUsage
                warnAbove: 0.9
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Colors.outline; opacity: 0.4 }

            StatRow {
                Layout.fillWidth: true
                icon: ""
                label: "Download"
                value: Resources.formatRate(Resources.netRxRate)
                fraction: -1
            }

            StatRow {
                Layout.fillWidth: true
                icon: ""
                label: "Upload"
                value: Resources.formatRate(Resources.netTxRate)
                fraction: -1
            }
        }
    }
}
