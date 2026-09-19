import QtQuick
import QtQuick.Layouts
import "../../config"

// A collapsible picker: one row showing what is selected, which opens into the
// list when there is more than one thing to choose from.
//
// Inline rather than a floating menu on purpose. PopupCard sets `clip: true`,
// so an overlay extending past the card would be cut off at its edge; growing
// the card instead lets its `Behavior on height` animate the whole thing open.
//
// The model holds whatever the caller has -- PipeWire nodes, strings, objects
// -- and the callbacks say how to render and compare them:
//
//     Select {
//         label: "Output"
//         model: Audio.sinks
//         textFor:   (item) => Audio.deviceName(item)
//         isCurrent: (item) => Audio.sink === item
//         onPicked:  (item) => Audio.setDefaultSink(item)
//     }
Item {
    id: root

    property string label: ""
    property string icon: ""
    property var model: []

    property var textFor: (item) => String(item)
    property var isCurrent: (item) => false

    // Owned by the caller, so a panel holding several of these can keep only
    // one open at a time.
    property bool expanded: false

    signal picked(var item)
    signal expandRequested()

    readonly property int count: root.model ? root.model.length : 0

    // Nothing to choose between: still shows what is selected, but there is no
    // point opening a list of one.
    readonly property bool expandable: root.count > 1
    readonly property bool listOpen: root.expanded && root.expandable

    readonly property string currentText: {
        const m = root.model
        if (!m || m.length === 0) return "None"
        for (let i = 0; i < m.length; i++) {
            if (root.isCurrent(m[i])) return root.textFor(m[i])
        }
        return root.textFor(m[0])
    }

    readonly property int headerHeight: 30

    // Computed rather than taken from `column.implicitHeight`.
    //
    // A Column counts a child's height when it is created, but does not
    // recompute its own implicitHeight when that child's height changes later.
    // Measured: with the list open the wrapper below was correctly 86 high and
    // the Column still reported 30. Deriving it here is exact, and gives one
    // place to animate.
    implicitHeight: root.headerHeight
        + (root.listOpen ? column.spacing + list.implicitHeight : 0)
    Behavior on implicitHeight { Anim {} }

    Column {
        id: column
        width: parent.width
        spacing: 2

        // ---- The row that is always visible -----------------------------

        Item {
            width: parent.width
            height: root.headerHeight

            Rectangle {
                anchors.fill: parent
                radius: Appearance.radiusSmall
                color: (headerFx.containsMouse && root.expandable)
                    ? Colors.alpha(Colors.surfaceContainerHigh, Appearance.layerOpacity)
                    : "transparent"
                Behavior on color { ColorAnimation { duration: Appearance.animFast } }

                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: "#ffffff"
                    opacity: headerFx.flashOpacity
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Appearance.spacingSmall
                anchors.rightMargin: Appearance.spacingSmall
                spacing: Appearance.spacingSmall

                Text {
                    visible: root.icon !== ""
                    text: root.icon
                    color: Colors.textSecondary
                    font.family: Appearance.fontFamilyIcons
                    font.pixelSize: Appearance.fontSizeSmall
                }

                Text {
                    text: root.label
                    color: Colors.textSecondary
                    font.family: Appearance.fontFamily
                    font.pixelSize: Appearance.fontSizeSmall
                }

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                    text: root.currentText
                    color: Colors.textPrimary
                    font.family: Appearance.fontFamily
                    font.pixelSize: Appearance.fontSizeSmall
                    elide: Text.ElideLeft
                }

                // Turning the chevron rather than swapping the glyph keeps it
                // on the shell's motion tokens.
                Text {
                    visible: root.expandable
                    text: ""
                    color: Colors.textSecondary
                    font.family: Appearance.fontFamilyIcons
                    font.pixelSize: Appearance.fontSizeSmall
                    rotation: root.expanded ? 180 : 0
                    Behavior on rotation { Anim { duration: Appearance.animFast } }
                }
            }

            PressFx {
                id: headerFx
                anchors.fill: parent
                enabled: root.expandable
                hoverScale: 1.0
                pressScale: Appearance.pressScaleSubtle
                focusRadius: Appearance.radiusSmall
                onActivated: root.expandRequested()
            }
        }

        // ---- The list ----------------------------------------------------
        //
        // A clipping wrapper whose height animates, rather than toggling the
        // Column's `visible`. Visibility propagates in Qt: every child of an
        // invisible Column reports visible == false, so the Column measures 0
        // -- and it does not reliably recompute when shown again. Measured: it
        // stayed 0 high with its three rows already inside it. Keeping the
        // Column visible and clipping it to nothing sidesteps that, and slides
        // open instead of popping.

        Item {
            width: parent.width
            clip: true
            height: root.listOpen ? list.implicitHeight : 0
            opacity: root.listOpen ? 1 : 0
            Behavior on height { Anim {} }
            Behavior on opacity { Anim { duration: Appearance.animFast } }

            Column {
                id: list
                width: parent.width
                spacing: 1

                Repeater {
                    model: root.model

                    Item {
                        id: entry
                        required property var modelData
                        width: parent ? parent.width : 0
                        height: 28

                        readonly property bool current: root.isCurrent(entry.modelData)

                        Rectangle {
                            anchors.fill: parent
                            anchors.leftMargin: Appearance.spacingNormal
                            radius: Appearance.radiusSmall
                            color: entry.current
                                ? Colors.alpha(Colors.primary, 0.18)
                                : (entryFx.containsMouse
                                    ? Colors.alpha(Colors.surfaceContainerHigh, Appearance.layerOpacity)
                                    : "transparent")
                            Behavior on color { ColorAnimation { duration: Appearance.animFast } }

                            Rectangle {
                                anchors.fill: parent
                                radius: parent.radius
                                color: "#ffffff"
                                opacity: entryFx.flashOpacity
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: Appearance.spacingSmall
                                anchors.rightMargin: Appearance.spacingSmall
                                spacing: Appearance.spacingSmall

                                Text {
                                    Layout.fillWidth: true
                                    text: root.textFor(entry.modelData)
                                    color: entry.current ? Colors.textPrimary : Colors.textSecondary
                                    font.family: Appearance.fontFamily
                                    font.pixelSize: Appearance.fontSizeSmall
                                    font.bold: entry.current
                                    elide: Text.ElideRight
                                }

                                Text {
                                    visible: entry.current
                                    text: ""
                                    color: Colors.primary
                                    font.family: Appearance.fontFamilyIcons
                                    font.pixelSize: Appearance.fontSizeSmall
                                }
                            }
                        }

                        PressFx {
                            id: entryFx
                            anchors.fill: parent
                            anchors.leftMargin: Appearance.spacingNormal
                            hoverScale: 1.0
                            pressScale: Appearance.pressScaleSubtle
                            focusRadius: Appearance.radiusSmall
                            onActivated: root.picked(entry.modelData)
                        }
                    }
                }
            }
        }
    }
}
