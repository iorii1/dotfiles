import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../config"
import "../../services"
import "../common"

// Renders whatever Menu is holding, at the point it was asked for.
//
// Built from QsMenuOpener rather than StatusNotifierItem.display(), which
// would hand the job to Qt and produce a menu that looks like nothing else in
// this shell. Doing it here means it is a PopupCard like every other surface.
ShellPanel {
    id: menuWindow

    // Driven by the service, not by UiState: a context menu is opened by a
    // gesture on something else, not toggled.
    open: Menu.open
    onDismissed: Menu.hide()
    onEscapePressed: Menu.hide()

    QsMenuOpener {
        id: opener
        menu: Menu.handle
    }

    PopupCard {
        id: card
        width: Math.max(160, menuWindow.widest + Appearance.spacingNormal * 2)
        height: column.implicitHeight + Appearance.spacingSmall * 2
        elevation: 2

        // Kept on screen: a tray icon near the right edge would otherwise open
        // a menu that runs off it.
        x: Math.max(Appearance.spacingSmall,
             Math.min(Menu.anchorX, menuWindow.width - card.width - Appearance.spacingSmall))
        y: Math.max(Appearance.spacingSmall,
             Math.min(Menu.anchorY, menuWindow.height - card.height - Appearance.spacingSmall))

        opacity: Menu.open ? 1 : 0
        scale: Menu.open ? 1 : Appearance.popupFromScale
        transformOrigin: Item.TopLeft
        Behavior on opacity { Anim { duration: Appearance.animFast } }
        Behavior on scale { PopAnim { duration: Appearance.animFast } }

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            id: column
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Appearance.spacingSmall
            spacing: 1

            Repeater {
                model: opener.children

                MenuRow {
                    required property var modelData
                    Layout.fillWidth: true
                    entry: modelData
                    onChosen: Menu.hide()
                }
            }

            Text {
                Layout.fillWidth: true
                Layout.margins: Appearance.spacingSmall
                visible: opener.children.values.length === 0
                text: "No menu items"
                color: Colors.textSecondary
                opacity: 0.7
                font.family: Appearance.fontFamily
                font.pixelSize: Appearance.fontSizeSmall
            }
        }
    }

    // The card is sized to its longest label; measuring them needs a Text that
    // is never drawn.
    property real widest: 0

    TextMetrics {
        id: metrics
        font.family: Appearance.fontFamily
        font.pixelSize: Appearance.fontSizeSmall
    }

    Connections {
        target: opener.children
        function onValuesChanged() { menuWindow.measure() }
    }

    onOpenChanged: if (open) menuWindow.measure()

    function measure() {
        let w = 0
        const items = opener.children.values
        for (let i = 0; i < items.length; i++) {
            if (items[i].isSeparator) continue
            metrics.text = items[i].text || ""
            // icon, label, submenu arrow
            w = Math.max(w, metrics.width + 52)
        }
        menuWindow.widest = w
    }
}
