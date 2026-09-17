import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../config"
import "../media"

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

            implicitHeight: Appearance.barHeight
            exclusiveZone: Appearance.barHeight
            color: "transparent"

            Rectangle {
                anchors.fill: parent
                anchors.margins: Appearance.barMargin
                anchors.bottomMargin: 0
                radius: Appearance.radiusLarge
                color: Colors.background
                border.width: 1
                border.color: Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.22)
                opacity: 0
                y: -6

                Behavior on color { ColorAnimation { duration: Appearance.animSlow } }
                Behavior on opacity { NumberAnimation { duration: Appearance.animSlow; easing.type: Easing.OutCubic } }
                Behavior on y { NumberAnimation { duration: Appearance.animSlow; easing.type: Easing.OutCubic } }
                Component.onCompleted: { opacity = 0.88; y = 0 }

                RowLayout {
                    anchors {
                        left: parent.left
                        leftMargin: Appearance.spacingLarge
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: Appearance.spacingNormal
                    Workspaces {}
                    Taskbar {}
                    CavaVisualizer {}
                    MediaWidget {}
                }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: Appearance.spacingNormal

                    NotificationIndicator {}
                    Clock {}
                }

                RowLayout {
                    anchors.right: parent.right
                    anchors.rightMargin: Appearance.spacingLarge
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Appearance.spacingNormal

                    TrayWidget {}
                    BatteryWidget {}
                    WifiWidget {}
                    BluetoothWidget {}
                    PowerButton {}
                }
            }
        }
    }
}
