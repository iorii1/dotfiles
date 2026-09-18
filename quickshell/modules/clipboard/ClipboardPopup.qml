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
        scale: UiState.clipboardOpen ? 1 : Appearance.popupFromScale
        Behavior on opacity { Anim {} }
        Behavior on scale { PopAnim {} }

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
                    height: row.modelData.isImage ? 52 : 40
                    radius: Appearance.radiusSmall
                    color: itemFx.containsMouse ? Colors.surfaceContainer : "transparent"
                    clip: true
                    Behavior on color { ColorAnimation { duration: Appearance.animFast } }

                    scale: Appearance.popFromScale
                    opacity: 0
                    transformOrigin: Item.Left

                    Component.onCompleted: entranceAnim.start()
                    PopIn { id: entranceAnim; target: row; delay: Appearance.staggerDelay(row.index) }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Appearance.spacingNormal
                        anchors.rightMargin: Appearance.spacingNormal
                        spacing: Appearance.spacingSmall

                        Image {
                            visible: row.modelData.isImage
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            source: row.modelData.isImage ? "file://" + Clipboard.thumbDir + "/" + row.modelData.id : ""

                            Rectangle {
                                anchors.fill: parent
                                color: "transparent"
                                border.width: 1
                                border.color: Colors.outline
                                opacity: 0.35
                            }
                        }

                        Text {
                            visible: !row.modelData.isImage
                            text: "\uf0ea"
                            color: Colors.textSecondary
                            font.family: Appearance.fontFamilyIcons
                            font.pixelSize: Appearance.fontSizeNormal
                        }

                        Text {
                            Layout.fillWidth: true
                            text: row.modelData.isImage ? "Image" : row.modelData.preview
                            color: Colors.textPrimary
                            font.family: Appearance.fontFamily
                            font.pixelSize: Appearance.fontSizeSmall
                            elide: Text.ElideRight
                        }
                    }

                    Rectangle {
                        id: copyFlash
                        anchors.fill: parent
                        radius: row.radius
                        color: "#ffffff"
                        opacity: 0
                    }

                    Timer {
                        id: closeTimer
                        interval: 180
                        onTriggered: UiState.clipboardOpen = false
                    }

                    NumberAnimation {
                        id: flashFade
                        target: copyFlash
                        property: "opacity"
                        to: 0
                        duration: Appearance.animNormal
                        easing.type: Easing.Bezier
                        easing.bezierCurve: Appearance.easeAccelerate
                    }

                    MouseArea {
                        id: itemFx
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Clipboard.select(row.modelData.id)
                            copyFlash.opacity = 0.5
                            flashFade.restart()
                            closeTimer.restart()
                        }
                    }
                }
            }
        }
    }
}
