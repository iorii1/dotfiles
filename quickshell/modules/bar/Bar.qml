import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../config"
import "../../services"
import "../media"
import "../common"

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

            implicitHeight: BarConfig.barHeight
            exclusiveZone: BarConfig.barHeight
            color: "transparent"

            Rectangle {
                property bool entered: false

                anchors.fill: parent
                anchors.margins: BarConfig.barMargin
                anchors.bottomMargin: 0
                radius: BarConfig.barRadius
                color: Colors.background
                border.width: 1
                border.color: Colors.alpha(Colors.outline, 0.22)
                opacity: entered ? BarConfig.barOpacity : 0
                y: entered ? 0 : -6

                Behavior on color { ColorAnimation { duration: Appearance.animSlow } }
                Behavior on opacity { Anim { duration: Appearance.animSlow } }
                Behavior on y { Anim { duration: Appearance.animSlow } }
                Behavior on radius { Anim {} }
                Component.onCompleted: entered = true

                RowLayout {
                    anchors {
                        left: parent.left
                        leftMargin: Appearance.spacingLarge
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: Appearance.spacingNormal
                    Workspaces { visible: BarConfig.showWorkspaces }
                    CavaVisualizer { visible: BarConfig.showCava }
                    MediaWidget { visible: BarConfig.showMedia }
                }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: Appearance.spacingNormal

                    NotificationIndicator { visible: BarConfig.showNotifications }
                    Clock { visible: BarConfig.showClock }
                }

                RowLayout {
                    anchors.right: parent.right
                    anchors.rightMargin: Appearance.spacingLarge
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Appearance.spacingNormal

                    TrayWidget { visible: BarConfig.showTray }
                    BatteryWidget { visible: BarConfig.showBattery }
                    WifiWidget { visible: BarConfig.showWifi }
                    BluetoothWidget { visible: BarConfig.showBluetooth }
                    PowerButton { visible: BarConfig.showPower }
                }
            }
        }
    }
}
