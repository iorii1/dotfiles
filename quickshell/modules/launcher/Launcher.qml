import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../config"
import "../../services"
import "../common"

ShellPanel {
    id: launcherWindow

    name: "launcher"

    property string query: ""
    property var results: Apps.filtered(query)

    // The selection is *not* a binding on currentIndex.
    //
    // It used to be `currentIndex: 0` on the ListView, which the first
    // incrementCurrentIndex() from an arrow key destroyed for good -- and
    // nothing reset it as the query changed. So after one arrow press the
    // highlight stopped tracking what you were typing, the list re-filtered
    // underneath a stale index, and Return launched whatever had drifted into
    // that row. Resetting it explicitly on every query change is the fix.
    onQueryChanged: resultsList.currentIndex = 0

    IpcHandler {
        target: "launcher"
        function toggle(): void { UiState.toggle("launcher") }
        function open(): void { UiState.show("launcher") }
        function close(): void { UiState.hide("launcher") }
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
        UiState.hide("launcher")
    }

    function _launchCurrent() {
        const i = resultsList.currentIndex
        if (i >= 0 && i < results.length) _launch(results[i])
    }

    // Wraps, so Up from the top lands on the last result rather than sticking.
    function _step(delta) {
        const n = launcherWindow.results.length
        if (n === 0) return
        resultsList.currentIndex = ((resultsList.currentIndex + delta) % n + n) % n
    }

    PopupCard {
        id: card
        width: 480
        height: Math.min(420, 76 + resultsList.contentHeight)
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.28

        opacity: launcherWindow.open ? 1 : 0
        scale: launcherWindow.open ? 1 : Appearance.popupFromScale
        Behavior on opacity { Anim {} }
        Behavior on scale { PopAnim {} }

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

                    Keys.onDownPressed: launcherWindow._step(1)
                    Keys.onUpPressed: launcherWindow._step(-1)
                    Keys.onReturnPressed: launcherWindow._launchCurrent()
                    Keys.onEnterPressed: launcherWindow._launchCurrent()
                    Keys.onEscapePressed: UiState.hide("launcher")
                    Keys.onTabPressed: launcherWindow._step(1)
                    Keys.onBacktabPressed: launcherWindow._step(-1)
                    Keys.onPressed: (event) => {
                        const n = launcherWindow.results.length
                        if (n === 0) return
                        switch (event.key) {
                        case Qt.Key_Home:     resultsList.currentIndex = 0; break
                        case Qt.Key_End:      resultsList.currentIndex = n - 1; break
                        case Qt.Key_PageDown: launcherWindow._step(5); break
                        case Qt.Key_PageUp:   launcherWindow._step(-5); break
                        default: return
                        }
                        event.accepted = true
                    }
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
                    font.family: Appearance.fontFamilyIcons
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
