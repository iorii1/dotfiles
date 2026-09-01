pragma Singleton

import Quickshell
import Quickshell.Networking
import QtQuick

Singleton {
    id: root

    readonly property bool enabled: Networking.wifiEnabled
    readonly property bool hardwareEnabled: Networking.wifiHardwareEnabled

    readonly property var wifiDevice: {
        const devices = Networking.devices ? Networking.devices.values : []
        for (const d of devices) {
            if (d.type === DeviceType.Wifi) return d
        }
        return null
    }

    readonly property var networks: wifiDevice ? wifiDevice.networks : null

    readonly property var activeNetwork: {
        const list = networks ? networks.values : []
        for (const n of list) {
            if (n.connected) return n
        }
        return null
    }

    function setEnabled(value) {
        Networking.wifiEnabled = value
    }

    function toggle() {
        setEnabled(!enabled)
    }

    function connectNetwork(network) {
        if (network) network.connect()
    }

    function connectWithPsk(network, psk) {
        if (network) network.connectWithPsk(psk)
    }

    function disconnectNetwork(network) {
        if (network) network.disconnect()
    }

    function forgetNetwork(network) {
        if (network) network.forget()
    }

    function securityLabel(sec) {
        return sec === WifiSecurityType.Open ? "Open" : "Secured"
    }

    function isOpen(network) {
        return network && network.security === WifiSecurityType.Open
    }
}
