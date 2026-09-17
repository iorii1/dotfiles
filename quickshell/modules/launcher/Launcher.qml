import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../config"
import "../../services"
import "../common"

PanelWindow {
    id: launcherWindow

    property bool open: false
    property string query: ""
    property var results: Apps.filtered(query)

    visible: open
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-popup"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    anchors { top: true; bottom: true; left: true; right: true }

    IpcHandler {
        target: "launcher"
        function toggle(): void { launcherWindow.open = !launcherWindow.open }
        function open(): void { launcherWindow.open = true }
        function close(): void { launcherWindow.open = false }
    }

    onOpenChanged: {
        if (open) {
            query = ""
            resultsList.currentIndex = 0
            searchInput.forceActiveFocus()
        }
    }

    function _launch(item) {
        Apps.launch(item)
        open = false
    }

    function _launchCurrent() {
        if (results.length > 0) _launch(results[resultsList.currentIndex])
    }

    MouseArea {
        anchors.fill: parent
        onClicked: launcherWindow.open = false
    }

    PopupCard {
        id: card
        width: 480
        height: Math.min(420, 76 + resultsList.contentHeight)
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.28

        opacity: launcherWindow.open ? 1 : 0
        scale: launcherWindow.open ? 1 : 0.94
        Behavior on opacity { NumberAnimation { duration: Appearance.animNormal; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: Appearance.animNormal; easing.type: Easing.OutBack; easing.overshoot: Appearance.overshootCard } }

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Appearance.spacingNormal
            spacing: Appearance.spacingSmall

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: searchInput.implicitHeight

                Text {
                    visible: searchInput.text === ""
                    text: "Search apps…"
                    color: Colors.textSecondary
                    font.family: Appearance.fontFamily
                    font.pixelSize: Appearance.fontSizeLarge
                }

                TextInput {
                    id: searchInput
                    anchors.fill: parent
                    font.family: Appearance.fontFamily
                    font.pixelSize: Appearance.fontSizeLarge
                    color: Colors.textPrimary
                    clip: true
                    text: launcherWindow.query
                    onTextChanged: launcherWindow.query = text

                    Keys.onDownPressed: resultsList.incrementCurrentIndex()
                    Keys.onUpPressed: resultsList.decrementCurrentIndex()
                    Keys.onReturnPressed: launcherWindow._launchCurrent()
                    Keys.onEscapePressed: launcherWindow.open = false
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Colors.outline; opacity: 0.4 }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: Appearance.spacingLarge
                spacing: 2
                visible: launcherWindow.results.length === 0

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: ""
                    color: Colors.textSecondary
                    opacity: 0.35
                    font.family: Appearance.fontFamily
                    font.pixelSize: 30
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "No apps found"
                    color: Colors.textSecondary
                    opacity: 0.6
                    font.family: Appearance.fontFamily
                    font.pixelSize: Appearance.fontSizeSmall
                }
            }

            ListView {
                id: resultsList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                visible: launcherWindow.results.length > 0
                model: launcherWindow.results
                spacing: 2
                currentIndex: 0
                highlightMoveDuration: Appearance.animFast

                delegate: AppItem {
                    width: resultsList.width
                    appName: modelData.name
                    appComment: modelData.comment
                    appIcon: modelData.icon
                    active: ListView.isCurrentItem
                    onActivated: launcherWindow._launch(modelData)
                }
            }
        }
    }
}
