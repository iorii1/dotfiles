import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../config"
import "../../services"

PanelWindow {
    id: popupWindow

    visible: Notifications.active.count > 0
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore
    focusable: false
    color: "transparent"

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
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Appearance.animNormal; easing.type: Easing.OutCubic }
                NumberAnimation { property: "x"; from: width * 0.35; to: 0; duration: Appearance.animNormal; easing.type: Easing.OutCubic }
            }
        }

        remove: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; to: 0; duration: Appearance.animFast; easing.type: Easing.OutCubic }
                NumberAnimation { property: "x"; to: width * 0.35; duration: Appearance.animFast; easing.type: Easing.OutCubic }
            }
        }

        displaced: Transition {
            NumberAnimation { property: "y"; duration: Appearance.animNormal; easing.type: Easing.OutCubic }
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
                onTriggered: Notifications.dismiss(model.uid)
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
