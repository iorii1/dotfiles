import QtQuick
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "../../config"
import "../../services"
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

                // The menu opens below the item, in the coordinate space of a
                // full-screen layer surface -- which is the screen, because the
                // bar spans it and every overlay is anchored to all four edges.
                function openMenu() {
                    if (!trayItem.modelData.hasMenu) return
                    const p = trayItem.mapToItem(null, 0, trayItem.height)
                    Menu.show(trayItem.modelData.menu, p.x - 8, p.y + BarConfig.barMargin + 4)
                }

                PressFx {
                    id: fx
                    anchors.fill: parent
                    anchors.margins: -4

                    // An item that says onlyMenu has no activate action at all,
                    // so left-clicking it used to do precisely nothing.
                    onActivated: {
                        if (trayItem.modelData.onlyMenu) trayItem.openMenu()
                        else trayItem.modelData.activate()
                    }

                    // SNI items can take scroll -- volume applets and the like
                    // use it. This was never forwarded.
                    onWheel: (wheel) => {
                        const dx = wheel.angleDelta.x
                        const dy = wheel.angleDelta.y
                        if (dy !== 0) trayItem.modelData.scroll(dy, false)
                        if (dx !== 0) trayItem.modelData.scroll(dx, true)
                        wheel.accepted = true
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton | Qt.MiddleButton
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.MiddleButton) {
                            trayItem.modelData.secondaryActivate()
                            return
                        }
                        // The real menu, where there is one. secondaryActivate
                        // is a fallback an item may implement, not its menu.
                        if (trayItem.modelData.hasMenu) trayItem.openMenu()
                        else trayItem.modelData.secondaryActivate()
                    }
                }
            }
        }
    }
}
