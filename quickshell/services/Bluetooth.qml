pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Bluetooth as Bluez

// BlueZ over DBus. Power state and per-device connection state are properties
// that announce themselves, so the 10-second `bluetoothctl` poll -- and the
// scraping of its human-readable output -- are gone.
Singleton {
    id: root

    readonly property var adapter: Bluez.Bluetooth.defaultAdapter

    readonly property bool powered: !!adapter && adapter.enabled
    readonly property bool refreshing: !!adapter && adapter.discovering

    // Live BluetoothDevice objects: the popup lists what you have paired, and
    // each row binds straight to its device, so a connection made from
    // anywhere else shows up here without asking.
    readonly property var devices: {
        if (!adapter) return []
        const all = Bluez.Bluetooth.devices.values
        const paired = []
        for (let i = 0; i < all.length; i++)
            if (all[i].paired) paired.push(all[i])
        return paired
    }

    function toggle() {
        if (adapter) adapter.enabled = !adapter.enabled
    }

    function connectDevice(device) {
        if (device) device.connect()
    }

    function disconnectDevice(device) {
        if (device) device.disconnect()
    }
}
