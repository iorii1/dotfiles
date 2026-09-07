import QtQuick
import QtQuick.Layouts
import "../../config"
import "../common"

Item {
    id: root
    implicitWidth: 340
    implicitHeight: content.implicitHeight + Appearance.spacingNormal * 2 + (root.timeoutMs > 0 ? 8 : 0)

    property string appName: ""
    property string summary: ""
    property string body: ""
    property string icon: ""
    property int urgency: 1
    property int timeoutMs: 0
    property var actions: []
    property bool hovered: ma.containsMouse

    signal dismissRequested()
    signal actionRequested(string actionId)

    readonly property color accent: urgency === 2 ? Colors.error : Colors.primary

    PopupCard {
        anchors.fill: parent

        scale: root.hovered ? 1.02 : 1.0
        Behavior on scale { NumberAnimation { duration: Appearance.animFast; easing.type: Easing.OutQuint } }

        Rectangle {
            width: 4
            radius: 2
            color: root.accent
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.margins: 6
        }

        Rectangle {
            id: countdownTrack
            visible: root.timeoutMs > 0
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 6
            height: 3
            radius: 1.5
            color: Colors.surfaceContainerHigh
            clip: true

            property real countdownProgress: 1.0

            NumberAnimation on countdownProgress {
                running: root.timeoutMs > 0 && !root.hovered
                from: 1.0
                to: 0.0
                duration: root.timeoutMs
                easing.type: Easing.Linear
            }

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                radius: 1.5
                width: parent.width * countdownTrack.countdownProgress
                color: root.accent
            }
        }

        RowLayout {
            id: content
            anchors.fill: parent
            anchors.margins: Appearance.spacingNormal
            anchors.leftMargin: Appearance.spacingNormal + 10
            spacing: Appearance.spacingNormal

            Image {
                visible: root.icon !== ""
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                Layout.alignment: Qt.AlignTop
                source: root.icon ? "image://icon/" + root.icon : ""
                fillMode: Image.PreserveAspectFit
                asynchronous: true
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        Layout.fillWidth: true
                        text: root.appName
                        color: Colors.textSecondary
                        font.family: Appearance.fontFamily
                        font.pixelSize: Appearance.fontSizeSmall
                        elide: Text.ElideRight
                    }

                    Text {
                        text: "\uf00d"
                        color: Colors.textSecondary
                        font.family: Appearance.fontFamily
                        font.pixelSize: Appearance.fontSizeSmall

                        scale: closeFx.popScale * (closeFx.pressed ? 0.85 : (closeFx.containsMouse ? 1.15 : 1.0))
                        Behavior on scale { NumberAnimation { duration: Appearance.animFast; easing.type: Easing.OutQuint } }

                        PressFx {
                            id: closeFx
                            anchors.fill: parent
                            anchors.margins: -4
                            popOvershoot: 2.4
                            onActivated: root.dismissRequested()
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: root.summary
                    color: Colors.textPrimary
                    font.family: Appearance.fontFamily
                    font.pixelSize: Appearance.fontSizeNormal
                    font.bold: true
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }

                Text {
                    visible: root.body !== ""
                    Layout.fillWidth: true
                    text: root.body
                    color: Colors.textSecondary
                    font.family: Appearance.fontFamily
                    font.pixelSize: Appearance.fontSizeSmall
                    wrapMode: Text.Wrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                }

                RowLayout {
                    visible: root.actions.length > 0
                    Layout.fillWidth: true
                    spacing: Appearance.spacingSmall

                    Repeater {
                        model: root.actions

                        Rectangle {
                            id: actionPill
                            required property var modelData
                            implicitWidth: actionLabel.implicitWidth + 20
                            implicitHeight: 26
                            radius: Appearance.radiusSmall
                            clip: true
                            color: actionFx.pressed ? Colors.surfaceContainerHigh : (actionFx.containsMouse ? Colors.surfaceContainerHigh : Colors.background)

                            Behavior on color { ColorAnimation { duration: Appearance.animFast } }
                            scale: actionFx.popScale * (actionFx.pressed ? 0.95 : 1.0)
                            Behavior on scale { NumberAnimation { duration: Appearance.animFast; easing.type: Easing.OutQuint } }

                            Rectangle {
                                anchors.fill: parent
                                radius: actionPill.radius
                                color: "#ffffff"
                                opacity: actionFx.flashOpacity
                            }

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
                                onActivated: root.actionRequested(actionPill.modelData.id)
                            }
                        }
                    }
                }
            }
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }
}
