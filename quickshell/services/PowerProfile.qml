pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.UPower as UPower

// power-profiles-daemon over DBus. Reads are a property, writes are an
// assignment; the old version ran `powerprofilesctl get` on a 15 second timer
// and `powerprofilesctl set` as a subprocess.
Singleton {
    id: root

    readonly property var available: ["power-saver", "balanced", "performance"]

    readonly property string current: {
        switch (UPower.PowerProfiles.profile) {
        case UPower.PowerProfile.PowerSaver: return "power-saver"
        case UPower.PowerProfile.Performance: return "performance"
        default: return "balanced"
        }
    }

    function set(profile) {
        switch (profile) {
        case "power-saver": UPower.PowerProfiles.profile = UPower.PowerProfile.PowerSaver; break
        case "performance": UPower.PowerProfiles.profile = UPower.PowerProfile.Performance; break
        default: UPower.PowerProfiles.profile = UPower.PowerProfile.Balanced
        }
    }
}
