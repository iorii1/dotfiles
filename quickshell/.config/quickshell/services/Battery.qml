pragma Singleton

import Quickshell
import Quickshell.Services.UPower
import QtQuick

Singleton {
    id: root

    property var _devices: UPower.devices

    readonly property var device: UPower.displayDevice
    readonly property int percentage: device ? Math.round(device.percentage * 100) : 100
    readonly property bool isCharging: device ? device.state === UPowerDeviceState.Charging : false
    readonly property bool isPresent: device ? device.isPresent : false
    readonly property int timeToEmpty: device ? device.timeToEmpty : 0
    readonly property int timeToFull: device ? device.timeToFull : 0

    function formatTime(seconds) {
        if (seconds <= 0) return ""
        const h = Math.floor(seconds / 3600)
        const m = Math.round((seconds % 3600) / 60)
        return h > 0 ? `${h}h ${m}m` : `${m}m`
    }

    readonly property string statusLabel: {
        if (!isPresent) return "No battery"
        if (isCharging && timeToFull > 0) return `${formatTime(timeToFull)} until full`
        if (!isCharging && timeToEmpty > 0) return `${formatTime(timeToEmpty)} remaining`
        return isCharging ? "Charging" : "On battery"
    }
}
