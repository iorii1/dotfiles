import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../config"
import "../common"

// One entry: a separator, a leaf, or a submenu that expands in place.
//
// Submenus expand inline rather than flying out sideways. A flyout has to
// decide which side of the screen it fits on and chase the pointer across a
// gap; inline is the same interaction the rest of this shell already uses
// (Select, ToggleRow) and cannot land off-screen.
Item {
    id: root

    property var entry: null
    property int depth: 0

    signal chosen()

    readonly property bool separator: !!root.entry && root.entry.isSeparator
    readonly property bool hasChildren: !!root.entry && root.entry.hasChildren
    readonly property bool checkable: !!root.entry
        && root.entry.buttonType !== QsMenuButtonType.None
    readonly property bool checked: !!root.entry && root.entry.checkState === Qt.Checked

    property bool expanded: false

    implicitHeight: column.implicitHeight

    Column {
        id: column
        width: parent.width
        spacing: 1

        // ---- Separator ---------------------------------------------------
        Item {
            width: parent.width
            visible: root.separator
            height: visible ? 7 : 0

            Rectangle {
                anchors.centerIn: parent
                width: parent.width - Appearance.spacingSmall * 2
                height: 1
                color: Colors.outline
                opacity: 0.4
            }
        }

        // ---- The entry itself ---------------------------------------------
        Item {
            width: parent.width
            visible: !root.separator
            height: visible ? 28 : 0

            Rectangle {
                anchors.fill: parent
                radius: Appearance.radiusSmall
                color: (fx.containsMouse && root.entry && root.entry.enabled)
                    ? Colors.alpha(Colors.surfaceContainerHigh, Appearance.layerOpacity)
                    : "transparent"
                Behavior on color { ColorAnimation { duration: Appearance.animFast } }

                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: "#ffffff"
                    opacity: fx.flashOpacity
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Appearance.spacingSmall + root.depth * Appearance.spacingNormal
                anchors.rightMargin: Appearance.spacingSmall
                spacing: Appearance.spacingSmall
                opacity: (root.entry && root.entry.enabled) ? 1 : 0.4

                // Checkbox, radio, or the entry's own icon -- never two at once.
                Item {
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16

                    Text {
                        anchors.centerIn: parent
                        visible: root.checkable
                        text: root.checked ? "" : ""
                        color: Colors.primary
                        font.family: Appearance.fontFamilyIcons
                        font.pixelSize: Appearance.fontSizeSmall
                    }

                    Image {
                        anchors.fill: parent
                        visible: !root.checkable && root.entry && root.entry.icon !== ""
                        source: (root.entry && root.entry.icon) ? root.entry.icon : ""
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: root.entry ? (root.entry.text || "") : ""
                    color: Colors.textPrimary
                    font.family: Appearance.fontFamily
                    font.pixelSize: Appearance.fontSizeSmall
                    elide: Text.ElideRight
                }

                Text {
                    visible: root.hasChildren
                    text: ""
                    color: Colors.textSecondary
                    font.family: Appearance.fontFamilyIcons
                    font.pixelSize: Appearance.fontSizeSmall
                    rotation: root.expanded ? 180 : 0
                    Behavior on rotation { Anim { duration: Appearance.animFast } }
                }
            }

            PressFx {
                id: fx
                anchors.fill: parent
                enabled: !!root.entry && root.entry.enabled
                hoverScale: 1.0
                pressScale: Appearance.pressScaleSubtle
                focusRadius: Appearance.radiusSmall

                onActivated: {
                    if (!root.entry) return
                    if (root.hasChildren) {
                        root.expanded = !root.expanded
                        return
                    }
                    // DBusMenu wants to know the menu was opened before an item
                    // is triggered; some apps build their menu lazily on it.
                    root.entry.triggered()
                    root.chosen()
                }
            }
        }

        // ---- Submenu -------------------------------------------------------
        //
        // The opener is only given a handle once expanded, so a menu with
        // several submenus does not fetch all of them up front.
        Item {
            width: parent.width
            clip: true
            height: root.expanded ? sub.implicitHeight : 0
            Behavior on height { Anim { duration: Appearance.animFast } }

            QsMenuOpener {
                id: subOpener
                menu: root.expanded ? root.entry : null
            }

            Column {
                id: sub
                width: parent.width
                spacing: 1

                Repeater {
                    model: subOpener.children

                    // A Loader, because QML refuses to let a component
                    // instantiate itself directly -- "MenuRow is instantiated
                    // recursively" is a load-time error, not a runtime one, so
                    // it takes the whole shell down. Naming the file as a
                    // string defers resolution past that check.
                    Loader {
                        id: subRow
                        required property var modelData
                        width: sub.width

                        Component.onCompleted: setSource("MenuRow.qml", {
                            entry: subRow.modelData,
                            depth: root.depth + 1
                        })

                        onLoaded: item.chosen.connect(root.chosen)
                    }
                }
            }
        }
    }
}
