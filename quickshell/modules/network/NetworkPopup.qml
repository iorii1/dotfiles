import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../config"
import "../../services"
import "../common"

// Wi-Fi: the master toggle, the networks in range, and -- new -- somewhere to
// type a passphrase. This panel used to be focusable: false, so even if it had
// had a password field nothing could have been typed into it.
ShellPanel {
    id: netWindow

    name: "network"

    IpcHandler {
        target: "network"
        function toggle(): void { UiState.toggle("network") }
        function open(): void { UiState.show("network") }
        function close(): void { UiState.hide("network") }
    }

    onVisibleChanged: visible ? Network.scan() : Network.stopScan()
    onOpenChanged: if (!open) Network.cancelPassword()

    PopupCard {
        id: card
        anchors.right: parent.right
        anchors.rightMargin: Appearance.spacingLarge
        readonly property int restY: BarConfig.barHeight + BarConfig.barMargin + Appearance.spacingSmall
        width: 320
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

            // Only worth a line when there is a cable in the socket.
            RowLayout {
                Layout.fillWidth: true
                visible: Network.wiredHasLink
                spacing: Appearance.spacingSmall

                Text {
                    // sitemap; the usual ethernet glyphs (U+F6FF, U+E12C)
                    // are not in JetBrainsMono Nerd Font.
                    text: ""
                    color: Network.wiredConnected ? Colors.primary : Colors.textSecondary
                    font.family: Appearance.fontFamilyIcons
                    font.pixelSize: Appearance.fontSizeSmall
                }

                Text {
                    Layout.fillWidth: true
                    text: Network.wiredConnected ? "Ethernet connected" : "Ethernet cable detected"
                    color: Colors.textSecondary
                    font.family: Appearance.fontFamily
                    font.pixelSize: Appearance.fontSizeSmall
                    elide: Text.ElideRight
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Colors.outline; opacity: 0.4 }

            Column {
                Layout.fillWidth: true
                spacing: 2
                visible: Network.wifiEnabled

                Repeater {
                    model: Network.networks

                    // Row plus, for exactly one network at a time, the password
                    // field underneath it.
                    Column {
                        id: netEntry
                        required property var modelData
                        required property int index
                        width: parent ? parent.width : 0
                        spacing: 2

                        readonly property bool isConnected: !!netEntry.modelData && netEntry.modelData.connected
                        readonly property bool wantsPassword: Network.passwordFor === netEntry.modelData

                        Rectangle {
                            id: netRow
                            width: parent.width
                            height: 34
                            radius: Appearance.radiusSmall
                            color: (netFx.containsMouse || netEntry.wantsPassword)
                                ? Colors.surfaceContainerHigh : "transparent"
                            Behavior on color { ColorAnimation { duration: Appearance.animFast } }

                            scale: Appearance.popFromScale
                            opacity: 0.0
                            transformOrigin: Item.Left

                            Component.onCompleted: netEntranceAnim.start()
                            PopIn { id: netEntranceAnim; target: netRow; delay: Appearance.staggerDelay(netEntry.index) }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: Appearance.spacingSmall
                                anchors.rightMargin: Appearance.spacingSmall
                                spacing: Appearance.spacingSmall

                                SignalBars {
                                    strength: netEntry.modelData ? netEntry.modelData.signalStrength : 0
                                    active: netEntry.isConnected
                                }

                                Text {
                                    visible: Network.isSecure(netEntry.modelData)
                                    text: ""
                                    color: Colors.textSecondary
                                    font.family: Appearance.fontFamilyIcons
                                    font.pixelSize: Appearance.fontSizeSmall
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: netEntry.modelData && netEntry.modelData.name ? netEntry.modelData.name : ""
                                    color: netEntry.isConnected ? Colors.primary : Colors.textPrimary
                                    font.family: Appearance.fontFamily
                                    font.pixelSize: Appearance.fontSizeSmall
                                    font.bold: netEntry.isConnected
                                    elide: Text.ElideRight
                                }

                                Text {
                                    visible: Network.connectingTo === (netEntry.modelData ? netEntry.modelData.name : "")
                                    text: "connecting…"
                                    color: Colors.textSecondary
                                    font.family: Appearance.fontFamily
                                    font.pixelSize: Appearance.fontSizeSmall
                                }

                                // Saved-but-not-current networks can be
                                // forgotten; the live one can be dropped.
                                Text {
                                    visible: netFx.containsMouse && netEntry.isConnected
                                    text: "disconnect"
                                    color: Colors.textSecondary
                                    font.family: Appearance.fontFamily
                                    font.pixelSize: Appearance.fontSizeSmall

                                    MouseArea {
                                        anchors.fill: parent
                                        anchors.margins: -4
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Network.disconnectFrom(netEntry.modelData)
                                    }
                                }

                                Text {
                                    visible: netFx.containsMouse && !netEntry.isConnected
                                        && !!netEntry.modelData && netEntry.modelData.known
                                    text: "forget"
                                    color: Colors.error
                                    font.family: Appearance.fontFamily
                                    font.pixelSize: Appearance.fontSizeSmall

                                    MouseArea {
                                        anchors.fill: parent
                                        anchors.margins: -4
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Network.forget(netEntry.modelData)
                                    }
                                }

                                Text {
                                    visible: netEntry.isConnected
                                    text: ""
                                    color: Colors.primary
                                    font.family: Appearance.fontFamilyIcons
                                    font.pixelSize: Appearance.fontSizeSmall
                                }
                            }

                            MouseArea {
                                id: netFx
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                z: -1
                                onClicked: Network.connectTo(netEntry.modelData)
                            }
                        }

                        // Revealed by NM answering NoSecrets for this network.
                        Item {
                            width: parent.width
                            visible: netEntry.wantsPassword
                            height: visible ? pwField.implicitHeight + Appearance.spacingSmall : 0

                            TextField {
                                id: pwField
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.leftMargin: Appearance.spacingSmall
                                anchors.rightMargin: Appearance.spacingSmall
                                anchors.bottom: parent.bottom
                                placeholder: "Password for " + (netEntry.modelData ? netEntry.modelData.name : "")
                                icon: ""
                                password: true

                                onVisibleChanged: if (visible) { clear(); forceActiveFocus() }
                                onAccepted: (text) => {
                                    if (text.length > 0) Network.connectWithPassword(netEntry.modelData, text)
                                }
                                onCancelled: Network.cancelPassword()
                            }
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
