pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Bluetooth as Bluez

// BlueZ over DBus. Power state and per-device connection state are properties
// that announce themselves, so the 10-second `bluetoothctl` poll -- and the
// scraping of its human-readable output -- are gone.
//
// This used to list only already-paired devices and never set
// adapter.discovering, which meant `refreshing` could never become true and a
// new device could not be paired without dropping to bluetoothctl.
Singleton {
    id: root

    readonly property var adapter: Bluez.Bluetooth.defaultAdapter

    readonly property bool powered: !!adapter && adapter.enabled
    readonly property bool discovering: !!adapter && adapter.discovering

    // Kept for the pulse ring that already binds to it.
    readonly property bool refreshing: root.discovering

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

    // Everything in range that is not already paired. Only populated while a
    // scan is running, and it empties again when the scan stops.
    readonly property var discovered: {
        if (!adapter) return []
        const all = Bluez.Bluetooth.devices.values
        const out = []
        for (let i = 0; i < all.length; i++) {
            const d = all[i]
            if (d.paired) continue
            // BlueZ reports plenty of nameless beacons; a row with no name is
            // not something anyone can meaningfully choose.
            if (!d.name && !d.deviceName) continue
            out.push(d)
        }
        return out
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

    // ---- Pairing ----------------------------------------------------------

    function startScan() {
        if (!adapter || !root.powered) return
        adapter.discovering = true
    }

    function stopScan() {
        if (adapter) adapter.discovering = false
    }

    function pair(device) {
        if (!device) return
        device.pair()
    }

    function cancelPair(device) {
        if (device) device.cancelPair()
    }

    // Drops the bond entirely, so the device leaves `devices` and reappears
    // under `discovered` while a scan is running.
    function forget(device) {
        if (device) device.forget()
    }

    // BlueZ hands us an icon name like "audio-headset" or "input-mouse".
    // Mapping it to a glyph is nicer than giving every device the same one.
    function iconFor(device) {
        const name = device && device.icon ? String(device.icon) : ""
        if (name.indexOf("headset") !== -1 || name.indexOf("headphone") !== -1) return ""
        if (name.indexOf("audio") !== -1 || name.indexOf("speaker") !== -1) return ""
        if (name.indexOf("mouse") !== -1) return ""
        if (name.indexOf("keyboard") !== -1) return ""
        if (name.indexOf("phone") !== -1) return ""
        if (name.indexOf("computer") !== -1) return ""
        if (name.indexOf("watch") !== -1) return ""
        if (name.indexOf("gaming") !== -1 || name.indexOf("joypad") !== -1) return ""
        if (name.indexOf("printer") !== -1) return ""
        return ""
    }

    function displayName(device) {
        if (!device) return ""
        return device.name || device.deviceName || device.address || "Unknown device"
    }
}
