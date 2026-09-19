import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../config"
import "../../services"
import "../common"

ShellPanel {
    id: overviewWindow

    name: "overview"

    // Which tile the keyboard is on. Starts on whichever workspace is already
    // focused, so SUPER+TAB then Return is a no-op rather than a surprise jump.
    property int selectedIndex: 0

    readonly property int workspaceCount: Hyprland.workspaces.values.length

    onOpenChanged: {
        if (!open) return
        const list = Hyprland.workspaces.values
        overviewWindow.selectedIndex = 0
        for (let i = 0; i < list.length; i++) {
            if (list[i].focused) { overviewWindow.selectedIndex = i; break }
        }
        keyCatcher.forceActiveFocus()
    }

    function _move(delta) {
        if (overviewWindow.workspaceCount === 0) return
        const n = overviewWindow.workspaceCount
        overviewWindow.selectedIndex = ((overviewWindow.selectedIndex + delta) % n + n) % n
    }

    // Dragged window icons are reparented here while they move. The workspace
    // tiles are PopupCards, which clip, so an icon dragged inside one would be
    // sliced off at its edge and could never reach another tile.
    property Item dragLayer: null

    function _activateSelected() {
        const list = Hyprland.workspaces.values
        if (overviewWindow.selectedIndex < list.length) {
            overviewWindow.goTo(list[overviewWindow.selectedIndex].id)
        }
    }

    IpcHandler {
        target: "overview"
        function toggle(): void { UiState.toggle("overview") }
        function open(): void { UiState.show("overview") }
        function close(): void { UiState.hide("overview") }
    }

    function goTo(workspaceId) {
        UiState.hide("overview")
        Compositor.focusWorkspace(workspaceId)
    }

    function focusWindow(address) {
        UiState.hide("overview")
        Compositor.focusWindow(address)
    }

    // The grid is a Repeater inside a plain Grid, so there is no ListView to
    // hand key events to -- this Item holds focus and drives selectedIndex.
    Item {
        id: keyCatcher
        anchors.fill: parent
        focus: true

        Keys.onPressed: (event) => {
            switch (event.key) {
            case Qt.Key_Left:  overviewWindow._move(-1); break
            case Qt.Key_Right: overviewWindow._move(1); break
            case Qt.Key_Up:    overviewWindow._move(-grid.columns); break
            case Qt.Key_Down:  overviewWindow._move(grid.columns); break
            case Qt.Key_Home:  overviewWindow.selectedIndex = 0; break
            case Qt.Key_End:   overviewWindow.selectedIndex = Math.max(0, overviewWindow.workspaceCount - 1); break
            case Qt.Key_Return:
            case Qt.Key_Enter:
            case Qt.Key_Space:
                overviewWindow._activateSelected(); break
            default:
                return
            }
            event.accepted = true
        }
    }

    Item {
        anchors.centerIn: parent
        width: grid.implicitWidth
        height: grid.implicitHeight

        Component.onCompleted: overviewWindow.dragLayer = dragLayer

        Item {
            id: dragLayer
            anchors.fill: parent
            z: 100
        }

        opacity: UiState.overviewOpen ? 1 : 0
        scale: UiState.overviewOpen ? 1 : Appearance.popupFromScale
        Behavior on opacity { Anim {} }
        Behavior on scale { PopAnim {} }

        Grid {
            id: grid
            columns: Math.max(1, Math.min(4, Hyprland.workspaces.values.length))
            spacing: Appearance.spacingNormal

            Repeater {
                model: Hyprland.workspaces

                PopupCard {
                    id: tile
                    required property var modelData
                    required property int index
                    width: 320
                    height: 220

                    readonly property bool hovered: tileHoverFx.containsMouse

                    scale: Appearance.popFromScale
                    opacity: 0
                    Component.onCompleted: entranceAnim.start()
                    PopIn { id: entranceAnim; target: tile; delay: Appearance.staggerDelay(index) }

                    DropArea {
                        id: tileDrop
                        anchors.fill: parent

                        onDropped: (drop) => {
                            const src = drop.source
                            if (!src || !src.modelData) return
                            // Dropping a window back where it started is a
                            // no-op, not a move.
                            if (src.workspaceId === tile.modelData.id) return
                            Compositor.moveWindowToWorkspace(src.modelData.address,
                                                             tile.modelData.id)
                            drop.accept()
                        }
                    }

                    // Lights up the tile the pointer is over while dragging.
                    Rectangle {
                        anchors.fill: parent
                        radius: Appearance.radiusLarge
                        color: "transparent"
                        border.width: 2
                        border.color: Colors.primary
                        opacity: tileDrop.containsDrag ? 1 : 0
                        visible: opacity > 0
                        Behavior on opacity { Anim { duration: Appearance.animFast } }
                        z: 50
                    }

                    MouseArea {
                        id: tileHoverFx
                        anchors.fill: parent
                        hoverEnabled: true
                        z: -1
                        onClicked: {
                            overviewWindow.selectedIndex = tile.index
                            overviewWindow.goTo(tile.modelData.id)
                        }
                    }

                    // "Screen" inset, like a monitor bezel around the windows.
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 8
                        radius: Appearance.radiusNormal
                        color: Colors.background
                        opacity: tile.hovered ? 1.0 : 0.92
                        Behavior on opacity { NumberAnimation { duration: Appearance.animFast } }
                    }

                    // Keyboard selection. Deliberately a separate ring from
                    // focusBorder below: one says "the keyboard is here", the
                    // other "this is the workspace you are on", and during
                    // SUPER+TAB navigation those are usually different tiles.
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -3
                        radius: Appearance.radiusLarge + 3
                        color: "transparent"
                        border.width: 2
                        border.color: Colors.primary
                        opacity: tile.index === overviewWindow.selectedIndex ? 1 : 0
                        visible: opacity > 0
                        Behavior on opacity { Anim { duration: Appearance.animFast } }
                    }

                    Rectangle {
                        id: focusBorder
                        anchors.fill: parent
                        radius: Appearance.radiusLarge
                        color: "transparent"
                        border.width: tile.modelData.focused ? 2 : (tile.hovered ? 1 : 0)
                        border.color: Colors.primary
                        opacity: tile.modelData.focused ? glowOpacity : 1.0
                        Behavior on border.width { NumberAnimation { duration: Appearance.animFast } }

                        property real glowOpacity: 1.0
                        SequentialAnimation {
                            running: tile.modelData.focused
                            loops: Animation.Infinite
                            NumberAnimation { target: focusBorder; property: "glowOpacity"; to: 0.5; duration: Appearance.animPulse; easing.type: Easing.InOutSine }
                            NumberAnimation { target: focusBorder; property: "glowOpacity"; to: 1.0; duration: Appearance.animPulse; easing.type: Easing.InOutSine }
                        }
                    }

                    Item {
                        visible: tile.modelData.toplevels.values.length === 0
                        anchors.fill: parent
                        anchors.margins: 8

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 2

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: ""
                                color: Colors.textSecondary
                                opacity: 0.35
                                font.family: Appearance.fontFamilyIcons
                                font.pixelSize: 30
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "Empty"
                                color: Colors.textSecondary
                                opacity: 0.6
                                font.family: Appearance.fontFamily
                                font.pixelSize: Appearance.fontSizeSmall
                            }
                        }
                    }

                    Flow {
                        visible: tile.modelData.toplevels.values.length > 0
                        anchors.fill: parent
                        anchors.margins: Appearance.spacingNormal + 8
                        spacing: Appearance.spacingNormal

                        Repeater {
                            model: tile.modelData.toplevels

                            ColumnLayout {
                                id: winTile
                                required property var modelData
                                required property int index

                                // Read by the DropArea to ignore a drop back
                                // onto the workspace the window already lives
                                // on.
                                readonly property int workspaceId: tile.modelData.id
                                width: 60
                                spacing: 4

                                scale: 0.7
                                opacity: 0
                                Component.onCompleted: winEntranceAnim.start()
                                PopIn { id: winEntranceAnim; target: winTile; delay: Appearance.staggerDelay(winTile.index); fromScale: 0.7 }

                                // A fixed slot the layout keeps, so the icon
                                // can be lifted out of it mid-drag without the
                                // row collapsing and reflowing under the
                                // pointer.
                                Item {
                                    id: slot
                                    Layout.alignment: Qt.AlignHCenter
                                    width: 48
                                    height: 48

                                Rectangle {
                                    id: iconBg
                                    width: 48
                                    height: 48
                                    radius: Appearance.radiusNormal
                                    color: winFx.containsMouse ? Colors.surfaceContainerHigh : Colors.surfaceContainer
                                    Behavior on color { ColorAnimation { duration: Appearance.animFast } }

                                    scale: winFx.gestureScale
                                    Behavior on scale { Anim { duration: Appearance.animFast } }

                                    Drag.active: winFx.drag.active
                                    Drag.source: winTile
                                    Drag.hotSpot.x: 24
                                    Drag.hotSpot.y: 24

                                    opacity: winFx.drag.active ? 0.75 : 1

                                    // Reparented to the drag layer for the
                                    // duration, because the workspace tile
                                    // clips and would otherwise cut the icon
                                    // off at its own edge.
                                    states: State {
                                        name: "dragging"
                                        when: winFx.drag.active
                                        ParentChange {
                                            target: iconBg
                                            parent: overviewWindow.dragLayer
                                        }
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: parent.radius
                                        color: "#ffffff"
                                        opacity: winFx.flashOpacity
                                    }

                                    Image {
                                        anchors.centerIn: parent
                                        width: 26
                                        height: 26
                                        source: winTile.modelData.wayland && winTile.modelData.wayland.appId
                                            ? "image://icon/" + winTile.modelData.wayland.appId : ""
                                        fillMode: Image.PreserveAspectFit
                                        asynchronous: true
                                    }

                                    PressFx {
                                        id: winFx
                                        hoverScale: 1.0
                                        pressScale: Appearance.pressScaleSubtle
                                        anchors.fill: parent
                                        drag.target: iconBg
                                        drag.threshold: 8

                                        // Qt does not emit clicked after a
                                        // drag, but drag.active is already
                                        // false by release, so relying on it
                                        // alone would be a guard that never
                                        // fires. This latches instead.
                                        property bool didDrag: false
                                        onPressed: winFx.didDrag = false
                                        Connections {
                                            target: winFx.drag
                                            function onActiveChanged() {
                                                if (winFx.drag.active) winFx.didDrag = true
                                            }
                                        }

                                        // Only a click focuses -- a drag that
                                        // happens to end over the tile it
                                        // started on must not also focus the
                                        // window and close the overview.
                                        onActivated: {
                                            if (winFx.didDrag) return
                                            overviewWindow.focusWindow(winTile.modelData.address)
                                        }

                                        // Whether or not a DropArea took it,
                                        // the icon has to go home: ParentChange
                                        // restores the parent but leaves x and
                                        // y wherever the drag ended.
                                        onReleased: {
                                            iconBg.Drag.drop()
                                            iconBg.x = 0
                                            iconBg.y = 0
                                        }
                                    }
                                }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignHCenter
                                    horizontalAlignment: Text.AlignHCenter
                                    text: winTile.modelData.title || "Window"
                                    color: Colors.textSecondary
                                    font.family: Appearance.fontFamily
                                    font.pixelSize: 10
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                }
                            }
                        }
                    }

                    // Corner badge with the workspace number/name.
                    Rectangle {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.margins: 10
                        implicitWidth: badgeLabel.implicitWidth + 14
                        implicitHeight: 22
                        radius: implicitHeight / 2
                        color: tile.modelData.focused ? Colors.primary : Colors.surfaceContainerHigh

                        Text {
                            id: badgeLabel
                            anchors.centerIn: parent
                            text: tile.modelData.name || ("" + tile.modelData.id)
                            color: tile.modelData.focused ? Colors.primaryText : Colors.textPrimary
                            font.family: Appearance.fontFamily
                            font.bold: true
                            font.pixelSize: Appearance.fontSizeSmall
                        }
                    }
                }
            }
        }
    }
}
