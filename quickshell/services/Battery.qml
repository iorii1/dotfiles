pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

// Everything here arrives as a DBus property change from UPower. There is no
// timer: the old version shelled out to `bash -c "upower -i $(upower -e | ...)"`
// every 20 seconds -- four processes a tick, on a laptop, to learn a number
// that UPower will simply tell you when it changes.
Singleton {
    id: root

    // UPower's own aggregate of whatever this machine treats as "the" battery,
    // which is exactly what a bar widget wants.
    readonly property var device: UPower.displayDevice

    // The real battery behind it, for the one thing the aggregate leaves
    // blank: its sysfs name.
    readonly property var cell: {
        const devices = UPower.devices.values
        for (let i = 0; i < devices.length; i++)
            if (devices[i].isLaptopBattery) return devices[i]
        return null
    }

    readonly property bool present: !!device && device.ready && device.isLaptopBattery
    readonly property int percent: Math.round((device ? device.percentage : 0) * 100)

    // Kept in upower's spelling rather than the enum's, so the popups that
    // compare against "fully-charged" and "pending-charge" keep working.
    readonly property string state: {
        if (!device) return ""
        switch (device.state) {
        case UPowerDeviceState.Charging: return "charging"
        case UPowerDeviceState.Discharging: return "discharging"
        case UPowerDeviceState.Empty: return "empty"
        case UPowerDeviceState.FullyCharged: return "fully-charged"
        case UPowerDeviceState.PendingCharge: return "pending-charge"
        case UPowerDeviceState.PendingDischarge: return "pending-discharge"
        default: return "unknown"
        }
    }

    readonly property bool charging: state === "charging" || state === "fully-charged" || state === "pending-charge"

    readonly property string timeText: {
        if (!device) return ""
        if (!charging && device.timeToEmpty > 0) return _duration(device.timeToEmpty) + " remaining"
        if (charging && device.timeToFull > 0) return _duration(device.timeToFull) + " until full"
        return ""
    }

    // UPower reports seconds; upower(1) rendered "3.3 hours", and the popup was
    // written around that shape.
    function _duration(seconds) {
        const mins = Math.round(seconds / 60)
        if (mins < 60) return mins + (mins === 1 ? " minute" : " minutes")
        return (seconds / 3600).toFixed(1) + " hours"
    }

    // Charge limit, for the "Paused at 80%" line. UPower does not carry it, so
    // it comes from sysfs -- read when the battery is found and again whenever
    // charging state changes, since sysfs will not announce it and the user is
    // the only thing that moves it.
    property int chargeEndThreshold: 100

    readonly property string thresholdPath: cell && cell.nativePath
        ? "/sys/class/power_supply/" + cell.nativePath + "/charge_control_end_threshold"
        : ""

    onStateChanged: if (thresholdFile.path) thresholdFile.reload()

    FileView {
        id: thresholdFile
        path: root.thresholdPath
        printErrors: false
        onLoaded: {
            const v = parseInt(text())
            root.chargeEndThreshold = (v > 0 && v <= 100) ? v : 100
        }
        onLoadFailed: root.chargeEndThreshold = 100
    }
}
