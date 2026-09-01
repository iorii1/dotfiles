import QtQuick
import QtQuick.Layouts
import "../services"

Item {
    id: root

    readonly property bool expanded: hoverHandler.hovered
    readonly property int windowSize: Math.min(5, Workspaces.count)

    readonly property int windowStart: {
        const maxStart = Math.max(1, Workspaces.count - windowSize + 1)
        const centered = Workspaces.activeWorkspace - Math.floor(windowSize / 2)
        return Math.min(Math.max(centered, 1), maxStart)
    }

    implicitWidth: expanded ? expandedRow.implicitWidth : collapsedDot.implicitWidth
    implicitHeight: 24

    Behavior on implicitWidth {
        NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
    }

    HoverHandler {
        id: hoverHandler
    }

    Rectangle {
        id: collapsedDot
        visible: !root.expanded
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: 24
        implicitHeight: 24
        radius: 4
        color: "#cba6f7"

        Text {
            anchors.centerIn: parent
            text: Workspaces.activeWorkspace
            color: "#11111b"
            font.pixelSize: 13
            font.weight: Font.Bold
            font.family: "JetBrainsMono Nerd Font"
            renderType: Text.NativeRendering
        }
    }

    Item {
        id: expandedRow
        visible: root.expanded
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: dotsRow.implicitWidth
        implicitHeight: 24

        // Sliding highlight pill (inspired by serpantinum's WorkspacesWidget) that
        // glides between dots instead of each dot flipping color instantly.
        Rectangle {
            id: highlight
            radius: 4
            color: "#cba6f7"
            width: 24
            height: 24
            y: 0
            x: (Workspaces.activeWorkspace - root.windowStart) * (24 + dotsRow.spacing)
            visible: Workspaces.activeWorkspace >= root.windowStart
                     && Workspaces.activeWorkspace < root.windowStart + root.windowSize

            Behavior on x {
                NumberAnimation { duration: 460; easing.type: Easing.OutExpo }
            }
        }

        RowLayout {
            id: dotsRow
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Repeater {
                model: root.windowSize

                Item {
                    id: tagDot

                    property int wsIndex: root.windowStart + index
                    property bool isActive: Workspaces.activeWorkspace === wsIndex

                    implicitWidth: 24
                    implicitHeight: 24
                    scale: isActive ? 1.0 : (hoverHandler2.hovered ? 1.05 : 0.88)

                    Behavior on scale {
                        NumberAnimation { duration: 230; easing.type: Easing.OutBack; easing.overshoot: 1.6 }
                    }

                    Component.onCompleted: {
                        opacity = 0
                        staggerTimer.start()
                    }
                    Timer {
                        id: staggerTimer
                        interval: index * 35
                        onTriggered: appearAnim.start()
                    }
                    NumberAnimation {
                        id: appearAnim
                        target: tagDot
                        property: "opacity"
                        to: 1
                        duration: 260
                        easing.type: Easing.OutQuad
                    }

                    Text {
                        anchors.centerIn: parent
                        text: parent.wsIndex
                        color: parent.isActive ? "#11111b" : "#a6adc8"
                        font.pixelSize: 13
                        font.weight: parent.isActive ? Font.Bold : Font.Normal
                        font.family: "JetBrainsMono Nerd Font"
                        renderType: Text.NativeRendering

                        Behavior on color {
                            ColorAnimation { duration: 220 }
                        }
                    }

                    HoverHandler { id: hoverHandler2 }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Workspaces.setWorkspace(parent.wsIndex)
                    }
                }
            }
        }
    }
}
