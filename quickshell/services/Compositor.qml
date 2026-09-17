pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

// Hyprland is configured in Lua here, and `hyprctl dispatch` evaluates its
// argument as Lua -- it wraps it as `return hl.dispatch(<arg>)`. The classic
// flat syntax ("workspace 3", "focuswindow address:0x...") is not valid Lua
// and fails with a parse error, silently doing nothing. Dispatches therefore
// have to be written as real hl.dsp calls, which is fiddly enough to be worth
// keeping in one place.
Singleton {
    id: root

    function focusWorkspace(id) {
        Hyprland.dispatch("hl.dsp.focus({ workspace = " + id + " })")
    }

    // Quickshell reports toplevel addresses without the 0x that Hyprland wants.
    function focusWindow(address) {
        Hyprland.dispatch("hl.dsp.focus({ window = 'address:0x" + address + "' })")
    }
}
