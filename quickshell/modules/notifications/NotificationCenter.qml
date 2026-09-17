import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../config"
import "../../services"
import "../common"

PanelWindow {
    id: centerWindow

    visible: UiState.notificationCenterOpen
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-popup"
    WlrLayershell.keyboardFocus: UiState.notificationCenterOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    anchors { top: true; bottom: true; left: true; right: true }

    IpcHandler {
        target: "notifications"
        function toggle(): void { UiState.notificationCenterOpen = !UiState.notificationCenterOpen }
        function open(): void { UiState.notificationCenterOpen = true }
        function close(): void { UiState.notificationCenterOpen = false }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: UiState.notificationCenterOpen = false
    }

    PopupCard {
        id: card
        anchors.right: parent.right
        anchors.rightMargin: Appearance.spacingLarge
        readonly property int restY: Appearance.barHeight + Appearance.barMargin + Appearance.spacingSmall
        width: 380
        height: Math.min(520, 76 + Math.max(list.contentHeight, empty.implicitHeight))

        opacity: UiState.notificationCenterOpen ? 1 : 0
        y: UiState.notificationCenterOpen ? restY : restY - 12
        scale: UiState.notificationCenterOpen ? 1 : 0.96
        Behavior on opacity { NumberAnimation { duration: Appearance.animNormal; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: Appearance.animNormal; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: Appearance.animNormal; easing.type: Easing.OutBack; easing.overshoot: Appearance.overshootCard } }
        Behavior on height { NumberAnimation { duration: Appearance.animNormal; easing.type: Easing.OutCubic } }

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Appearance.spacingNormal
            spacing: Appearance.spacingSmall

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacingSmall

                Item {
                    id: bellBadge
                    implicitWidth: 26
                    implicitHeight: 26

                    property int lastCount: Notifications.history.count

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: Notifications.dnd ? Colors.surfaceContainerHigh : Colors.primary
                        Behavior on color { ColorAnimation { duration: Appearance.animFast } }
                    }

                    Text {
                        id: bellIcon
                        anchors.centerIn: parent
                        transformOrigin: Item.Top
                        text: Notifications.dnd ? "" : ""
                        color: Notifications.dnd ? Colors.textSecondary : Colors.primaryText
                        font.family: Appearance.fontFamily
                        font.pixelSize: Appearance.fontSizeNormal
                        Behavior on color { ColorAnimation { duration: Appearance.animFast } }
                    }

                    SequentialAnimation {
                        id: ringAnim
                        loops: 2
                        NumberAnimation { target: bellIcon; property: "rotation"; to: 22; duration: 80; easing.type: Easing.OutQuad }
                        NumberAnimation { target: bellIcon; property: "rotation"; to: -22; duration: 140; easing.type: Easing.InOutQuad }
                        NumberAnimation { target: bellIcon; property: "rotation"; to: 0; duration: 80; easing.type: Easing.InQuad }
                    }

                    Connections {
                        target: Notifications.history
                        function onCountChanged() {
                            if (Notifications.history.count > bellBadge.lastCount && !Notifications.dnd) ringAnim.restart()
                            bellBadge.lastCount = Notifications.history.count
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: "Notifications"
                    color: Colors.textPrimary
                    font.family: Appearance.fontFamily
                    font.bold: true
                    font.pixelSize: Appearance.fontSizeNormal
                }

                Text {
                    text: "Clear"
                    visible: Notifications.history.count > 0
                    color: clearFx.containsMouse ? Colors.textPrimary : Colors.textSecondary
                    font.family: Appearance.fontFamily
                    font.pixelSize: Appearance.fontSizeSmall

                    Behavior on color { ColorAnimation { duration: Appearance.animFast } }
                    scale: clearFx.popScale * (clearFx.pressed ? 0.9 : 1.0)
                    Behavior on scale { NumberAnimation { duration: Appearance.animFast; easing.type: Easing.OutQuint } }

                    PressFx {
                        id: clearFx
                        anchors.fill: parent
                        anchors.margins: -6
                        onActivated: Notifications.clearHistory()
                    }
                }

                Text {
                    text: "DND"
                    color: Colors.textSecondary
                    font.family: Appearance.fontFamily
                    font.pixelSize: Appearance.fontSizeSmall
                }

                Toggle {
                    checked: Notifications.dnd
                    onToggled: (checked) => Notifications.dnd = checked
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Colors.outline; opacity: 0.4 }

            Text {
                id: empty
                visible: Notifications.history.count === 0
                Layout.fillWidth: true
                Layout.topMargin: Appearance.spacingLarge
                horizontalAlignment: Text.AlignHCenter
                text: "No notifications"
                color: Colors.textSecondary
                font.family: Appearance.fontFamily
                font.pixelSize: Appearance.fontSizeSmall
            }

            ListView {
                id: list
                visible: Notifications.history.count > 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: Notifications.history
                spacing: 4

                delegate: Rectangle {
                    id: row
                    required property var modelData
                    required property int index
                    width: list.width
                    height: rowContent.implicitHeight + Appearance.spacingSmall * 2
                    radius: Appearance.radiusSmall
                    color: itemFx.containsMouse ? Colors.surfaceContainer : "transparent"
                    Behavior on color { ColorAnimation { duration: Appearance.animFast } }

                    scale: 0.94
                    opacity: 0
                    Component.onCompleted: entranceAnim.start()
                    PopIn { id: entranceAnim; target: row; delay: Math.min(row.index * 15, 180) }

                    readonly property color accent: row.modelData.urgency === 2 ? Colors.error : Colors.primary

                    Rectangle {
                        width: 3
                        radius: 1.5
                        color: row.accent
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.margins: 6
                    }

                    RowLayout {
                        id: rowContent
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: Appearance.spacingSmall + 8
                        anchors.rightMargin: Appearance.spacingSmall
                        spacing: Appearance.spacingSmall

                        Image {
                            visible: row.modelData.icon !== ""
                            Layout.preferredWidth: 28
                            Layout.preferredHeight: 28
                            Layout.alignment: Qt.AlignTop
                            source: row.modelData.icon ? "image://icon/" + row.modelData.icon : ""
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    Layout.fillWidth: true
                                    text: row.modelData.appName
                                    color: Colors.textSecondary
                                    font.family: Appearance.fontFamily
                                    font.pixelSize: Appearance.fontSizeSmall
                                    elide: Text.ElideRight
                                }
                                Text {
                                    text: row.modelData.time
                                    color: Colors.textSecondary
                                    font.family: Appearance.fontFamily
                                    font.pixelSize: Appearance.fontSizeSmall
                                }
                            }

                            Text {
                                visible: row.modelData.summary !== ""
                                Layout.fillWidth: true
                                text: row.modelData.summary
                                color: Colors.textPrimary
                                font.family: Appearance.fontFamily
                                font.pixelSize: Appearance.fontSizeSmall
                                font.bold: true
                                wrapMode: Text.Wrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                            }

                            Text {
                                visible: row.modelData.body !== ""
                                Layout.fillWidth: true
                                text: row.modelData.body
                                color: Colors.textSecondary
                                font.family: Appearance.fontFamily
                                font.pixelSize: Appearance.fontSizeSmall
                                wrapMode: Text.Wrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                            }
                        }

                        Text {
                            Layout.alignment: Qt.AlignTop
                            text: ""
                            color: Colors.textSecondary
                            font.family: Appearance.fontFamily
                            font.pixelSize: Appearance.fontSizeSmall

                            scale: dismissFx.popScale * (dismissFx.pressed ? 0.85 : (dismissFx.containsMouse ? 1.15 : 1.0))
                            Behavior on scale { NumberAnimation { duration: Appearance.animFast; easing.type: Easing.OutQuint } }

                            PressFx {
                                id: dismissFx
                                anchors.fill: parent
                                anchors.margins: -6
                                popOvershoot: 2.4
                                onActivated: Notifications.dismissHistory(row.modelData.uid)
                            }
                        }
                    }

                    MouseArea {
                        id: itemFx
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                    }
                }
            }
        }
    }
}
