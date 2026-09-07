import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../config"
import "../../services"
import "../common"

PanelWindow {
    id: clipWindow

    visible: UiState.clipboardOpen
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-popup"
    WlrLayershell.keyboardFocus: UiState.clipboardOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    anchors { top: true; bottom: true; left: true; right: true }

    IpcHandler {
        target: "clipboard"
        function toggle(): void { UiState.clipboardOpen = !UiState.clipboardOpen }
        function open(): void { UiState.clipboardOpen = true }
        function close(): void { UiState.clipboardOpen = false }
    }

    onVisibleChanged: if (visible) Clipboard.refresh()

    MouseArea {
        anchors.fill: parent
        onClicked: UiState.clipboardOpen = false
    }

    PopupCard {
        id: card
        width: 460
        height: Math.min(420, 76 + list.contentHeight)
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.22

        opacity: UiState.clipboardOpen ? 1 : 0
        scale: UiState.clipboardOpen ? 1 : 0.94
        Behavior on opacity { NumberAnimation { duration: Appearance.animNormal; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: Appearance.animNormal; easing.type: Easing.OutBack; easing.overshoot: Appearance.overshootCard } }

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Appearance.spacingNormal
            spacing: Appearance.spacingSmall

            Text {
                text: "Clipboard History"
                color: Colors.textPrimary
                font.family: Appearance.fontFamily
                font.bold: true
                font.pixelSize: Appearance.fontSizeNormal
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Colors.outline; opacity: 0.4 }

            ListView {
                id: list
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: Clipboard.entries
                spacing: 2

                delegate: Rectangle {
                    id: row
                    required property var modelData
                    required property int index
                    width: list.width
                    height: 40
                    radius: Appearance.radiusSmall
                    color: itemFx.containsMouse ? Colors.surfaceContainer : "transparent"
                    Behavior on color { ColorAnimation { duration: Appearance.animFast } }

                    property real entranceScale: 0.85
                    property real entranceOpacity: 0
                    scale: entranceScale
                    opacity: entranceOpacity
                    transformOrigin: Item.Left

                    Component.onCompleted: entranceAnim.start()
                    SequentialAnimation {
                        id: entranceAnim
                        PauseAnimation { duration: Math.min(row.index * 18, 220) }
                        ParallelAnimation {
                            NumberAnimation { target: row; property: "entranceScale"; to: 1.0; duration: 240; easing.type: Easing.OutBack; easing.overshoot: 1.4 }
                            NumberAnimation { target: row; property: "entranceOpacity"; to: 1.0; duration: 200; easing.type: Easing.OutQuad }
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Appearance.spacingNormal
                        anchors.rightMargin: Appearance.spacingNormal
                        spacing: Appearance.spacingSmall

                        Text {
                            text: row.modelData.isImage ? "\uf03e" : "\uf0ea"
                            color: Colors.textSecondary
                            font.family: Appearance.fontFamily
                            font.pixelSize: Appearance.fontSizeNormal
                        }

                        Text {
                            Layout.fillWidth: true
                            text: row.modelData.preview
                            color: Colors.textPrimary
                            font.family: Appearance.fontFamily
                            font.pixelSize: Appearance.fontSizeSmall
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: itemFx
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Clipboard.select(row.modelData.id)
                            UiState.clipboardOpen = false
                        }
                    }
                }
            }
        }
    }
}
