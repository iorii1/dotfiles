import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../config"
import "../../services"
import "../common"

ShellPanel {
    id: clipWindow

    name: "clipboard"

    property string query: ""

    // The selection is managed, never bound -- the same trap the launcher fell
    // into, where the first arrow key destroyed a `currentIndex: 0` binding and
    // the highlight then stopped tracking the filtered list.
    onQueryChanged: list.currentIndex = 0

    IpcHandler {
        target: "clipboard"
        function toggle(): void { UiState.toggle("clipboard") }
        function open(): void { UiState.show("clipboard") }
        function close(): void { UiState.hide("clipboard") }
    }

    onVisibleChanged: if (visible) Clipboard.refresh()

    function _step(delta) {
        const n = list.count
        if (n === 0) return
        list.currentIndex = ((list.currentIndex + delta) % n + n) % n
    }

    function _activateCurrent() {
        if (list.currentItem) list.currentItem.activate()
    }

    // Back to the top each time it opens, so the keyboard always starts on the
    // most recent entry rather than wherever it was left last time.
    onOpenChanged: {
        if (!open) return
        clipWindow.query = ""
        list.currentIndex = 0
        search.forceActiveFocus()
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

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacingSmall

                Text {
                    Layout.fillWidth: true
                    text: "Clipboard History"
                    color: Colors.textPrimary
                    font.family: Appearance.fontFamily
                    font.bold: true
                    font.pixelSize: Appearance.fontSizeNormal
                }

                // Clipboard.clearAll() already existed but nothing ever called
                // it -- there was no Clear anywhere in the UI.
                Text {
                    text: "Clear"
                    visible: Clipboard.entries.length > 0
                    color: clearFx.containsMouse ? Colors.error : Colors.textSecondary
                    font.family: Appearance.fontFamily
                    font.pixelSize: Appearance.fontSizeSmall
                    Behavior on color { ColorAnimation { duration: Appearance.animFast } }

                    scale: clearFx.gestureScale
                    Behavior on scale { Anim { duration: Appearance.animFast } }

                    PressFx {
                        id: clearFx
                        anchors.fill: parent
                        anchors.margins: -6
                        hoverScale: 1.0
                        pressScale: Appearance.pressScaleSubtle
                        onActivated: Clipboard.clearAll()
                    }
                }
            }

            TextField {
                id: search
                Layout.fillWidth: true
                placeholder: "Search clipboard…"
                icon: "\uf002"
                onTextChanged: clipWindow.query = text

                // The field keeps focus so you can keep typing; it drives the
                // list rather than letting the list take the keyboard.
                Keys.onDownPressed: clipWindow._step(1)
                Keys.onUpPressed: clipWindow._step(-1)
                Keys.onReturnPressed: clipWindow._activateCurrent()
                Keys.onEnterPressed: clipWindow._activateCurrent()
                Keys.onEscapePressed: UiState.hide("clipboard")
                Keys.onPressed: (event) => {
                    if (event.key !== Qt.Key_Delete) return
                    if (list.currentItem) {
                        Clipboard.remove(list.currentItem.modelData.id)
                        event.accepted = true
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Colors.outline; opacity: 0.4 }

            ListView {
                id: list
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: Clipboard.filtered(clipWindow.query)
                spacing: 2
                highlightMoveDuration: Appearance.animFast

                delegate: Rectangle {
                    id: row
                    required property var modelData
                    required property int index
                    width: list.width
                    height: row.modelData.isImage ? 52 : 40
                    radius: Appearance.radiusSmall
                    color: (itemFx.containsMouse || row.ListView.isCurrentItem)
                        ? Colors.surfaceContainer : "transparent"
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

                        // Pinned entries float to the top and survive being
                        // scrolled past; cliphist has no concept of this, so
                        // the shell keeps the list.
                        Text {
                            visible: itemFx.containsMouse || row.ListView.isCurrentItem
                                || Clipboard.isPinned(row.modelData.id)
                            text: ""
                            color: Clipboard.isPinned(row.modelData.id)
                                ? Colors.primary
                                : (pinFx.containsMouse ? Colors.textPrimary : Colors.textSecondary)
                            font.family: Appearance.fontFamilyIcons
                            font.pixelSize: Appearance.fontSizeSmall
                            Behavior on color { ColorAnimation { duration: Appearance.animFast } }

                            scale: pinFx.gestureScale
                            Behavior on scale { Anim { duration: Appearance.animFast } }

                            PressFx {
                                id: pinFx
                                anchors.fill: parent
                                anchors.margins: -6
                                onActivated: Clipboard.togglePin(row.modelData)
                            }
                        }

                        // Remove one entry. cliphist has always supported this;
                        // the shell only offered wipe-everything, and not even
                        // that from the UI.
                        Text {
                            visible: itemFx.containsMouse || row.ListView.isCurrentItem
                            text: ""
                            color: delFx.containsMouse ? Colors.error : Colors.textSecondary
                            font.family: Appearance.fontFamilyIcons
                            font.pixelSize: Appearance.fontSizeSmall
                            Behavior on color { ColorAnimation { duration: Appearance.animFast } }

                            scale: delFx.gestureScale
                            Behavior on scale { Anim { duration: Appearance.animFast } }

                            PressFx {
                                id: delFx
                                anchors.fill: parent
                                anchors.margins: -6
                                popOvershoot: 2.4
                                onActivated: Clipboard.remove(row.modelData.id)
                            }
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
                        onTriggered: UiState.hide("clipboard")
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

                    // One path for both pointer and keyboard, so Return gets the
                    // same flash and the same close delay a click does.
                    function activate() {
                        Clipboard.select(row.modelData.id)
                        copyFlash.opacity = 0.5
                        flashFade.restart()
                        closeTimer.restart()
                    }

                    MouseArea {
                        id: itemFx
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            list.currentIndex = row.index
                            row.activate()
                        }
                    }
                }
            }
        }
    }
}
