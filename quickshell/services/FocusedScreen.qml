pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

// "The monitor the user is looking at", as a ShellScreen a PanelWindow can be
// assigned to.
//
// Thirteen of the shell's fifteen windows set no screen at all, so the
// launcher, the OSD, the toasts and every popup landed on whichever output the
// compositor happened to pick rather than the one in front of you.
Singleton {
    id: root

    // Hyprland populates this from its event socket about a second after
    // startup, so it is briefly null; the focused workspace knows its monitor
    // and settles at the same time, as a second source.
    //
    // HyprlandMonitor.focused is deliberately not consulted: measured against
    // this Hyprland it stays false on every monitor, including the focused one.
    readonly property var monitor: {
        if (Hyprland.focusedMonitor) return Hyprland.focusedMonitor

        const ws = Hyprland.focusedWorkspace
        if (ws && ws.monitor) return ws.monitor

        return null
    }

    // null means "let the compositor place it", which is what every window did
    // before this existed -- so a null here is a no-op, not a broken panel.
    readonly property var screen: {
        const mon = root.monitor
        if (!mon) return null
        const screens = Quickshell.screens
        for (let i = 0; i < screens.length; i++) {
            if (screens[i].name === mon.name) return screens[i]
        }
        return null
    }

    readonly property string name: root.monitor ? root.monitor.name : ""
}
