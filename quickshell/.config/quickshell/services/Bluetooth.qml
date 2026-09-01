pragma Singleton

import Quickshell
import Quickshell.Bluetooth
import QtQuick

Singleton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool available: adapter !== null
    readonly property bool enabled: adapter?.enabled ?? false
    readonly property bool discovering: adapter?.discovering ?? false
    readonly property var devices: adapter ? adapter.devices : null
    readonly property var connectedDevices: devices ? devices.values.filter(d => d.connected) : []

    function setEnabled(value) {
        if (adapter) adapter.enabled = value
    }

    function toggle() {
        setEnabled(!enabled)
    }

    function setDiscovering(value) {
        if (adapter) adapter.discovering = value
    }

    function connectDevice(device) {
        if (device) device.connect()
    }

    function disconnectDevice(device) {
        if (device) device.disconnect()
    }

    function pairDevice(device) {
        if (device) device.pair()
    }

    function forgetDevice(device) {
        if (device) device.forget()
    }
}
