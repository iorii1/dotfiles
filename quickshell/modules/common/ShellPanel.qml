import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../config"
import "../../services"

// The window every popup in the shell is made of.
//
// Each panel used to re-declare the same block: overlay layer, popup namespace,
// ignored exclusion zone, full-screen anchors, a backdrop MouseArea to dismiss
// and an inner one to swallow clicks. That much was harmless duplication. What
// was not is that six panels also copied
// `WlrLayershell.keyboardFocus: Exclusive` while only two ever wrote a
// Keys.onEscapePressed to go with it -- so the other four took the keyboard
// from the compositor and then dropped every key on the floor, leaving Escape
// dead and the panel dismissable only by clicking.
//
// Putting all of that here means a panel gets dismissal, Escape and focus by
// existing, and can only lose them deliberately.
//
//     ShellPanel {
//         id: panel
//         name: "network"
//         PopupCard { ... }
//     }
//
// Content is placed inside a FocusScope, so Tab walks the controls within the
// panel and stops there.
PanelWindow {
    id: root

    // The UiState key this panel opens and closes under. Setting it wires
    // `open`, Escape and outside-click dismissal to UiState with no further
    // code; leave it empty and drive `open` yourself instead.
    property string name: ""

    property bool open: root.name !== "" ? UiState.isOpen(root.name) : false

    // Whether the panel should take the keyboard while it is up. Panels that
    // are purely informational (toasts, the OSD) leave this false so typing
    // keeps going to the focused window.
    property bool takesFocus: true

    // Open on the monitor the user is actually looking at.
    property bool followFocus: true

    default property alias content: contentScope.data

    signal dismissed()
    signal escapePressed()

    // Not `visible: root.open` directly: the screen has to be chosen *before*
    // the surface maps, and writing both in one handler guarantees that order.
    visible: root._mapped
    property bool _mapped: false
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-popup"
    WlrLayershell.keyboardFocus: (root.open && root.takesFocus)
        ? WlrKeyboardFocus.Exclusive
        : WlrKeyboardFocus.None

    anchors { top: true; bottom: true; left: true; right: true }

    // Latched, not bound live -- and the latch is the whole point.
    //
    // A panel takes the keyboard when it opens, and Hyprland answers that by
    // re-deriving the focused monitor from where the *pointer* is. Binding
    // `screen` to the focused output therefore feeds back on itself: the panel
    // opens on the right monitor, grabbing focus moves "focused" to the monitor
    // under the cursor, and the panel promptly slides over to join it. Measured,
    // not theorised -- it flipped back within a frame of opening.
    //
    // Latching once, before the surface maps, breaks that loop.
    screen: root._latchedScreen
    property var _latchedScreen: null

    // Hyprland reports the focused output as a HyprlandMonitor, which is not
    // the ShellScreen a PanelWindow wants; the name is what the two share.
    //
    onOpenChanged: {
        if (root.open && root.followFocus) root._latchedScreen = FocusedScreen.screen
        root._mapped = root.open

        root._grabSettled = false
        if (root.open) grabSettle.restart()
        else grabSettle.stop()
    }

    function close() {
        if (root.name !== "") UiState.hide(root.name)
        root.dismissed()
    }

    // Dismiss when the user clicks any *other* window. The backdrop MouseArea
    // below only sees clicks that land on this surface, so without this a popup
    // survives being clicked away from -- which is how it behaves today.
    HyprlandFocusGrab {
        windows: [root]
        active: root.open && root.takesFocus

        // A grab cleared in the same instant it was requested is not somebody
        // dismissing anything -- it is the compositor declining a grab that
        // arrived with no input event behind it, which is exactly the case for
        // panels that appear on their own (a capture preview, an auth prompt).
        // Acting on that closed them the moment they opened.
        onCleared: if (root.open && root._grabSettled) root.close()
    }

    property bool _grabSettled: false

    Timer {
        id: grabSettle
        interval: Appearance.animNormal
        onTriggered: root._grabSettled = true
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    FocusScope {
        id: contentScope
        anchors.fill: parent
        focus: root.open

        Keys.onEscapePressed: (event) => {
            root.escapePressed()
            root.close()
            event.accepted = true
        }
    }
}
