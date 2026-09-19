import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../config"
import "../../services"
import "../common"

ShellPanel {
    id: centerWindow

    name: "notificationCenter"

    // Which app's group is expanded, if any. One at a time.
    property string expandedApp: ""

    onOpenChanged: if (open) { list.currentIndex = 0; centerWindow.expandedApp = "" }

    IpcHandler {
        target: "notifications"
        function toggle(): void { UiState.toggle("notificationCenter") }
        function open(): void { UiState.show("notificationCenter") }
        function close(): void { UiState.hide("notificationCenter") }
    }

    PopupCard {
        id: card
        anchors.right: parent.right
        anchors.rightMargin: Appearance.spacingLarge
        readonly property int restY: BarConfig.barHeight + BarConfig.barMargin + Appearance.spacingSmall
        width: 380
        height: Math.min(520, 76 + Math.max(list.contentHeight, empty.implicitHeight))

        opacity: UiState.notificationCenterOpen ? 1 : 0
        y: UiState.notificationCenterOpen ? restY : restY - 12
        scale: UiState.notificationCenterOpen ? 1 : Appearance.popupFromScale
        transformOrigin: Item.TopRight
        Behavior on opacity { Anim {} }
        Behavior on y { Anim {} }
        Behavior on scale { PopAnim {} }
        Behavior on height { Anim {} }

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
                        font.family: Appearance.fontFamilyIcons
                        font.pixelSize: Appearance.fontSizeNormal
                        Behavior on color { ColorAnimation { duration: Appearance.animFast } }
                    }

                    SequentialAnimation {
                        id: ringAnim
                        loops: 2
                        NumberAnimation { target: bellIcon; property: "rotation"; to: 22; duration: Appearance.animInstant; easing.type: Easing.OutQuad }
                        NumberAnimation { target: bellIcon; property: "rotation"; to: -22; duration: Appearance.animFast; easing.type: Easing.InOutQuad }
                        NumberAnimation { target: bellIcon; property: "rotation"; to: 0; duration: Appearance.animInstant; easing.type: Easing.InQuad }
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
                    scale: clearFx.gestureScale
                    Behavior on scale { Anim { duration: Appearance.animFast } }

                    PressFx {
                        id: clearFx
                        hoverScale: 1.0
                        pressScale: Appearance.pressScaleSubtle
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

                // Up/Down walk the history; Delete and Backspace dismiss the
                // row under the cursor, which is the whole interaction this
                // list offers by pointer too.
                focus: true
                currentIndex: 0
                highlightMoveDuration: Appearance.animFast
                keyNavigationWraps: true

                Keys.onPressed: (event) => {
                    if (event.key !== Qt.Key_Delete && event.key !== Qt.Key_Backspace) return
                    if (list.currentItem) {
                        Notifications.dismissHistory(list.currentItem.modelData.uid)
                        event.accepted = true
                    }
                }

                delegate: Rectangle {
                    id: row
                    required property var modelData
                    required property int index
                    width: list.width
                    radius: Appearance.radiusSmall
                    color: (itemFx.containsMouse || row.ListView.isCurrentItem)
                        ? Colors.surfaceContainer : "transparent"
                    Behavior on color { ColorAnimation { duration: Appearance.animFast } }

                    scale: Appearance.popFromScale
                    opacity: 0
                    Component.onCompleted: entranceAnim.start()
                    PopIn { id: entranceAnim; target: row; delay: Appearance.staggerDelay(row.index) }

                    readonly property color accent: row.modelData.urgency === 2 ? Colors.error : Colors.primary

                    // Consecutive rows from one app collapse into the newest,
                    // which carries the count. Ten messages from one chat were
                    // ten full cards.
                    readonly property int runLength: Notifications.runLength(row.index)
                    readonly property bool continuation: Notifications.isContinuation(row.index)
                    readonly property bool grouped: row.runLength > 1
                    readonly property bool groupOpen: centerWindow.expandedApp === row.modelData.appName

                    visible: !row.continuation || row.groupOpen
                    height: visible ? rowContent.implicitHeight + Appearance.spacingSmall * 2 : 0

                    // Parsed once per row rather than per action pill.
                    readonly property var actions: {
                        try {
                            return JSON.parse(row.modelData.actionsJson || "[]")
                        } catch (e) {
                            return []
                        }
                    }

                    // freedesktop convention: the action identified as
                    // "default" is what activating the notification itself
                    // means. It is not shown as a pill -- clicking the row is
                    // how you invoke it.
                    readonly property var defaultAction: {
                        for (let i = 0; i < row.actions.length; i++) {
                            if (row.actions[i].id === "default") return row.actions[i]
                        }
                        return null
                    }

                    readonly property var pillActions: row.actions.filter(a => a.id !== "default")

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
                                Rectangle {
                                    visible: row.grouped && !row.continuation
                                    implicitWidth: countLabel.implicitWidth + 10
                                    implicitHeight: 16
                                    radius: 8
                                    color: Colors.alpha(row.accent, 0.22)

                                    Text {
                                        id: countLabel
                                        anchors.centerIn: parent
                                        // runLength counts the header row too, and it is
                                        // the one already on screen.
                                        text: row.groupOpen ? "collapse" : (row.runLength - 1) + " more"
                                        color: Colors.textPrimary
                                        font.family: Appearance.fontFamily
                                        font.pixelSize: Appearance.fontSizeSmall
                                    }

                                    PressFx {
                                        anchors.fill: parent
                                        hoverScale: 1.0
                                        pressScale: Appearance.pressScaleSubtle
                                        focusRadius: 8
                                        onActivated: centerWindow.expandedApp =
                                            row.groupOpen ? "" : row.modelData.appName
                                    }
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

                            // Actions used to exist only on the live toast, so
                            // once one timed out its buttons were gone for good
                            // even though the notification was still alive.
                            Flow {
                                Layout.fillWidth: true
                                Layout.topMargin: 2
                                spacing: Appearance.spacingSmall
                                visible: row.pillActions.length > 0

                                Repeater {
                                    model: row.pillActions

                                    Rectangle {
                                        id: actionPill
                                        required property var modelData
                                        height: 22
                                        width: actionLabel.implicitWidth + Appearance.spacingNormal
                                        radius: height / 2
                                        color: actionFx.containsMouse
                                            ? Colors.alpha(row.accent, 0.28)
                                            : Colors.alpha(Colors.surfaceContainerHigh, Appearance.layerOpacity)
                                        Behavior on color { ColorAnimation { duration: Appearance.animFast } }

                                        scale: actionFx.gestureScale
                                        Behavior on scale { Anim { duration: Appearance.animFast } }

                                        Text {
                                            id: actionLabel
                                            anchors.centerIn: parent
                                            text: actionPill.modelData.text
                                            color: Colors.textPrimary
                                            font.family: Appearance.fontFamily
                                            font.pixelSize: Appearance.fontSizeSmall
                                        }

                                        PressFx {
                                            id: actionFx
                                            anchors.fill: parent
                                            hoverScale: 1.0
                                            pressScale: Appearance.pressScaleSubtle
                                            focusRadius: parent.radius
                                            onActivated: Notifications.invokeAction(row.modelData.uid, actionPill.modelData.id)
                                        }
                                    }
                                }
                            }

                            TextField {
                                id: replyField
                                Layout.fillWidth: true
                                Layout.topMargin: 2
                                visible: row.modelData.hasReply === true
                                placeholder: Notifications.replyPlaceholder(row.modelData.uid)
                                icon: "\uf112"
                                accentColor: row.accent
                                onAccepted: (text) => {
                                    if (text.length > 0) Notifications.sendReply(row.modelData.uid, text)
                                }
                            }
                        }

                        // Silence this app specifically. DND was the only
                        // control before, and it is all-or-nothing.
                        Text {
                            Layout.alignment: Qt.AlignTop
                            visible: itemFx.containsMouse || Notifications.isMuted(row.modelData.appName)
                            text: Notifications.isMuted(row.modelData.appName) ? "" : ""
                            color: Notifications.isMuted(row.modelData.appName) ? Colors.error : Colors.textSecondary
                            font.family: Appearance.fontFamilyIcons
                            font.pixelSize: Appearance.fontSizeSmall

                            scale: muteFx.gestureScale
                            Behavior on scale { Anim { duration: Appearance.animFast } }

                            PressFx {
                                id: muteFx
                                anchors.fill: parent
                                anchors.margins: -6
                                onActivated: Notifications.toggleAppMute(row.modelData.appName)
                            }
                        }

                        Text {
                            Layout.alignment: Qt.AlignTop
                            text: ""
                            color: Colors.textSecondary
                            font.family: Appearance.fontFamilyIcons
                            font.pixelSize: Appearance.fontSizeSmall

                            scale: dismissFx.gestureScale
                            Behavior on scale { Anim { duration: Appearance.animFast } }

                            PressFx {
                                id: dismissFx
                                anchors.fill: parent
                                anchors.margins: -6
                                popOvershoot: 2.4
                                onActivated: (row.grouped && !row.groupOpen)
                                    ? Notifications.dismissRun(row.index)
                                    : Notifications.dismissHistory(row.modelData.uid)
                            }
                        }
                    }

                    // Behind rowContent (z: -1), so the action pills, the reply
                    // field, the mute bell and the dismiss X all get their
                    // clicks first and this only sees the empty space around
                    // them. It was hover-only before, which meant clicking a
                    // notification to open the app that sent it did nothing.
                    MouseArea {
                        id: itemFx
                        anchors.fill: parent
                        hoverEnabled: true
                        z: -1
                        acceptedButtons: row.defaultAction ? Qt.LeftButton : Qt.NoButton
                        cursorShape: row.defaultAction ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: if (row.defaultAction) Notifications.invokeAction(row.modelData.uid, row.defaultAction.id)
                    }
                }
            }
        }
    }
}
