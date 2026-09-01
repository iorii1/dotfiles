pragma Singleton

import Quickshell
import Quickshell.Services.UPower
import QtQuick

Singleton {
    id: root

    readonly property int profile: PowerProfiles.profile
    readonly property bool hasPerformanceProfile: PowerProfiles.hasPerformanceProfile

    readonly property int profSaver: PowerProfile.PowerSaver
    readonly property int profBalanced: PowerProfile.Balanced
    readonly property int profPerformance: PowerProfile.Performance

    function setProfile(p) {
        PowerProfiles.profile = p
    }

    function label(p) {
        switch (p) {
        case PowerProfile.PowerSaver: return "Saver"
        case PowerProfile.Performance: return "Performance"
        default: return "Balanced"
        }
    }

    function icon(p) {
        switch (p) {
        case PowerProfile.PowerSaver: return "󰌪"
        case PowerProfile.Performance: return "󰓅"
        default: return "󰗑"
        }
    }
}
