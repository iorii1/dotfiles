pragma Singleton
import QtQuick
import Quickshell

// Which panels are open.
//
// The booleans stay the public surface -- panels bind their `visible` and their
// entrance animations straight to them -- but open/close should go through
// show()/hide()/toggle(), which keep only one panel up at a time. Without that
// the network, bluetooth, battery and notification popups all sit at the same
// top-right corner at the same restY and simply draw on top of each other.
Singleton {
    id: root

    property bool powerMenuOpen: false
    property bool networkOpen: false
    property bool bluetoothOpen: false
    property bool batteryOpen: false
    property bool audioOpen: false
    property bool quickSettingsOpen: false
    property bool calendarOpen: false
    property bool clipboardOpen: false
    property bool mediaPopupOpen: false
    property bool notificationCenterOpen: false
    property bool overviewOpen: false
    property bool launcherOpen: false
    property bool settingsOpen: false

    // Not exclusive: the dock is pinned rather than opened, so it stays put
    // while other panels come and go.
    property bool dockOpen: false

    readonly property var exclusive: [
        "powerMenu", "network", "bluetooth", "battery", "audio", "quickSettings",
        "calendar", "clipboard", "mediaPopup", "notificationCenter", "overview",
        "launcher", "settings"
    ]

    function _prop(name) {
        return name + "Open"
    }

    function isOpen(name) {
        return root[root._prop(name)] === true
    }

    function show(name) {
        for (let i = 0; i < root.exclusive.length; i++) {
            const other = root.exclusive[i]
            if (other !== name) root[root._prop(other)] = false
        }
        root[root._prop(name)] = true
    }

    function hide(name) {
        root[root._prop(name)] = false
    }

    function toggle(name) {
        if (root.isOpen(name)) root.hide(name)
        else root.show(name)
    }

    // Closes every exclusive panel. The escape hatch for "something else took
    // over the screen" -- a lock, a polkit prompt, a capture overlay.
    function hideAll() {
        for (let i = 0; i < root.exclusive.length; i++) {
            root[root._prop(root.exclusive[i])] = false
        }
    }
}
