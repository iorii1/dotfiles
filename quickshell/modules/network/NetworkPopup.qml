import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../config"
import "../../services"
import "../common"

PanelWindow {
    id: netWindow

    visible: UiState.networkOpen
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-popup"
    exclusionMode: ExclusionMode.Ignore
    focusable: false
    color: "transparent"

    anchors { top: true; bottom: true; left: true; right: true }

    IpcHandler {
        target: "network"
        function toggle(): void { UiState.networkOpen = !UiState.networkOpen }
        function open(): void { UiState.networkOpen = true }
        function close(): void { UiState.networkOpen = false }
    }

    onVisibleChanged: visible ? Network.scan() : Network.stopScan()

    MouseArea {
        anchors.fill: parent
        onClicked: UiState.networkOpen = false
    }

    PopupCard {
        id: card
        anchors.right: parent.right
        anchors.rightMargin: Appearance.spacingLarge
        readonly property int restY: BarConfig.barHeight + BarConfig.barMargin + Appearance.spacingSmall
        width: 300
        height: content.implicitHeight + Appearance.spacingNormal * 2

        opacity: UiState.networkOpen ? 1 : 0
        y: UiState.networkOpen ? restY : restY - 12
        scale: UiState.networkOpen ? 1 : Appearance.popupFromScale
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

            ToggleRow {
                Layout.fillWidth: true
                icon: ""
                label: Network.connected ? Network.ssid : "Wi-Fi"
                checked: Network.wifiEnabled
                active: UiState.networkOpen
                entranceDelay: 0
                expandable: false
                pulsing: Network.scanning
                onToggleRequested: Network.toggleWifi()
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Colors.outline; opacity: 0.4 }

            Column {
                Layout.fillWidth: true
                spacing: 2
                visible: Network.wifiEnabled

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

                        scale: Appearance.popFromScale
                        opacity: 0.0
                        transformOrigin: Item.Left

                        Component.onCompleted: netEntranceAnim.start()
                        PopIn { id: netEntranceAnim; target: netRow; delay: Appearance.staggerDelay(netRow.index) }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Appearance.spacingSmall
                            anchors.rightMargin: Appearance.spacingSmall
                            spacing: Appearance.spacingSmall

                            Text {
                                text: modelData && modelData.connected ? "" : (Network.isSecure(modelData) ? "" : "")
                                color: modelData && modelData.connected ? Colors.primary : Colors.textSecondary
                                font.family: Appearance.fontFamilyIcons
                                font.pixelSize: Appearance.fontSizeSmall
                                Layout.preferredWidth: 14
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData && modelData.name ? modelData.name : ""
                                color: Colors.textPrimary
                                font.family: Appearance.fontFamily
                                font.pixelSize: Appearance.fontSizeSmall
                                elide: Text.ElideRight
                            }

                            Text {
                                visible: Network.connectingTo === (netRow.modelData ? netRow.modelData.name : "")
                                text: "connecting…"
                                color: Colors.textSecondary
                                font.family: Appearance.fontFamily
                                font.pixelSize: Appearance.fontSizeSmall
                            }
                        }

                        MouseArea {
                            id: netFx
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Network.connectTo(modelData)
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

                Text {
                    width: parent.width
                    visible: Network.lastError !== ""
                    text: Network.lastError
                    color: Colors.error
                    font.family: Appearance.fontFamily
                    font.pixelSize: Appearance.fontSizeSmall
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
}
