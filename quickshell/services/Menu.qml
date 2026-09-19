pragma Singleton
import QtQuick
import Quickshell

// The shell's one context menu, as state.
//
// There was no menu of any kind before this. The tray in particular suffered
// for it: StatusNotifierItem carries `hasMenu` and `menu`, and the bar used
// neither -- right click called secondaryActivate(), which is the *fallback*
// an item may implement, not its menu. Items that set `onlyMenu` have no click
// action at all, so those did nothing whatsoever.
//
// One menu exists at a time and it is a single window, so this holds which
// handle is showing and where, and modules/menu renders it.
Singleton {
    id: root

    // A QsMenuHandle, or null when nothing is open.
    property var handle: null

    // Where the menu's top-left should sit, in the coordinate space of a
    // full-screen layer surface -- which is the screen, since every panel is
    // anchored to all four edges.
    property real anchorX: 0
    property real anchorY: 0

    readonly property bool open: root.handle !== null

    function show(menuHandle, x, y) {
        if (!menuHandle) return
        root.anchorX = x
        root.anchorY = y
        root.handle = menuHandle
    }

    function hide() {
        root.handle = null
    }
}
