import QtQuick
import QtQuick.Layouts
import Quickshell
import "./widgets"

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: barWindow
            required property var modelData
            screen: modelData

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: 34
            exclusiveZone: 34

            color: "#00000000"
            Behavior on color {
                ColorAnimation { duration: 460; easing.type: Easing.OutCubic }
            }
            Component.onCompleted: color = "#991e1e2e"

            Item {
                id: content
                anchors.fill: parent

                opacity: 0
                y: -6
                Behavior on opacity {
                    NumberAnimation { duration: 380; easing.type: Easing.OutCubic }
                }
                Behavior on y {
                    NumberAnimation { duration: 380; easing.type: Easing.OutCubic }
                }
                Component.onCompleted: {
                    opacity = 1
                    y = 0
                }

                RowLayout {
                    id: leftRow
                    anchors {
                        left: parent.left
                        leftMargin: 14
                        verticalCenter: parent.verticalCenter
                    }

                    StartMenuWidget {}
                    WorkspaceWidget {}
                }

                ClockWidget {
                    id: clockWidget
                    anchors.centerIn: parent
                    z: 1
                    barWindow: barWindow
                }

                NotificationWidget {
                    anchors.right: clockWidget.left
                    anchors.rightMargin: 10
                    anchors.verticalCenter: clockWidget.verticalCenter
                    z: 1
                    barWindow: barWindow
                }

                RowLayout {
                    anchors {
                        right: parent.right
                        rightMargin: 14
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: 16

                    CavaWidget {}
                    MediaWidget { barWindow: barWindow }
                    AudioWidget {}
                    BatteryWidget {}
                    NetworkWidget {}
                    ControlCenterButton { barWindow: barWindow }
                }

                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                    }
                    height: 1
                    color: "#33cdd6f4"
                }
            }
          }
        }
      }




