import QtQuick
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "../../config"
import "../common"

Item {
    id: root

    implicitWidth: SystemTray.items.values.length > 0 ? row.implicitWidth : 0
    implicitHeight: 20
    clip: true

    Behavior on implicitWidth { Anim {} }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: Appearance.spacingSmall

        Repeater {
            model: SystemTray.items

            Item {
                id: trayItem
                required property var modelData

                width: 18
                height: 18

                // A `NumberAnimation on opacity` value source here fought the
                // `opacity: 0` next to it. Started explicitly instead, which is
                // what PopIn does everywhere else -- and only opacity moves,
                // because `scale` below carries a binding that animating would
                // tear down for good.
                opacity: 0
                Component.onCompleted: fadeIn.start()
                NumberAnimation {
                    id: fadeIn
                    target: trayItem
                    property: "opacity"
                    to: 1.0
                    duration: Appearance.animNormal
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Appearance.easeDecelerate
                }

                scale: fx.gestureScale
                Behavior on scale { Anim { duration: Appearance.animFast } }

                IconImage {
                    anchors.fill: parent
                    source: trayItem.modelData.icon
                    asynchronous: true
                }

                PressFx {
                    id: fx
                    anchors.fill: parent
                    anchors.margins: -4
                    onActivated: trayItem.modelData.activate()
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton
                    onClicked: trayItem.modelData.secondaryActivate()
                }
            }
        }
    }
}
