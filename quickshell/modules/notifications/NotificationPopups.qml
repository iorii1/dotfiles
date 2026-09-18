import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../config"
import "../../services"

PanelWindow {
    id: popupWindow

    visible: Notifications.active.count > 0
    WlrLayershell.layer: WlrLayer.Overlay
    // This was the only overlay without a namespace, so it fell under the
    // ^quickshell$ layer rule meant for the bar and got the bar's slide
    // animation instead of the popup fade.
    WlrLayershell.namespace: "quickshell-popup"
    exclusionMode: ExclusionMode.Ignore
    focusable: false
    color: "transparent"

    // Toasts had no screen at all, so on a dual-head setup they appeared on
    // whichever output the compositor picked.
    screen: FocusedScreen.screen

    anchors { top: true; right: true; bottom: true }
    margins { top: BarConfig.barHeight + BarConfig.barMargin + Appearance.spacingNormal; right: Appearance.spacingNormal }

    implicitWidth: 360

    mask: Region { item: list }

    ListView {
        id: list
        anchors.top: parent.top
        anchors.right: parent.right
        width: parent.width
        height: Math.min(parent.height, contentHeight)
        model: Notifications.active
        spacing: Appearance.spacingNormal
        interactive: false
        boundsBehavior: Flickable.StopAtBounds

        add: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Appearance.animNormal; easing.type: Easing.Bezier; easing.bezierCurve: Appearance.easeDecelerate }
                NumberAnimation { property: "x"; from: width * 0.35; to: 0; duration: Appearance.animNormal; easing.type: Easing.Bezier; easing.bezierCurve: Appearance.easeDecelerate }
            }
        }

        remove: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; to: 0; duration: Appearance.animFast; easing.type: Easing.Bezier; easing.bezierCurve: Appearance.easeAccelerate }
                NumberAnimation { property: "x"; to: width * 0.35; duration: Appearance.animFast; easing.type: Easing.Bezier; easing.bezierCurve: Appearance.easeAccelerate }
            }
        }

        displaced: Transition {
            NumberAnimation { property: "y"; duration: Appearance.animNormal; easing.type: Easing.Bezier; easing.bezierCurve: Appearance.easeStandard }
        }

        delegate: Item {
            id: delegateRoot
            width: list.width
            implicitHeight: card.implicitHeight

            required property var model

            readonly property int effectiveTimeout: model.urgency === 2 ? 0 : 6000

            Timer {
                interval: delegateRoot.effectiveTimeout
                running: delegateRoot.effectiveTimeout > 0 && !card.hovered
                // Timed out rather than closed: keep the notification alive so
                // its actions still work from the notification centre.
                onTriggered: Notifications.expire(model.uid)
            }

            NotificationCard {
                id: card
                width: parent.width
                appName: model.appName
                summary: model.summary
                body: model.body
                icon: model.icon
                urgency: model.urgency
                timeoutMs: delegateRoot.effectiveTimeout
                actions: {
                    try { return JSON.parse(model.actionsJson) } catch (e) { return [] }
                }
                onDismissRequested: Notifications.dismiss(model.uid)
                onActionRequested: (actionId) => Notifications.invokeAction(model.uid, actionId)
            }
        }
    }
}
