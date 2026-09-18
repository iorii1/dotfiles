pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Networking as Net

// NetworkManager over DBus. Status, the visible networks and their signal
// strength all arrive as property changes, so nothing polls `nmcli` any more.
Singleton {
    id: root

    readonly property var device: {
        const devices = Net.Networking.devices.values
        for (let i = 0; i < devices.length; i++)
            if (devices[i].type === Net.DeviceType.Wifi) return devices[i]
        return null
    }

    readonly property bool wifiEnabled: Net.Networking.wifiEnabled

    readonly property var active: {
        if (!device) return null
        const nets = device.networks.values
        for (let i = 0; i < nets.length; i++)
            if (nets[i].connected) return nets[i]
        return null
    }

    readonly property bool connected: !!active
    readonly property string ssid: active ? active.name : ""
    // NM reports 0-1; the widget's icon thresholds are in percent.
    readonly property int signalStrength: active ? Math.round(active.signalStrength * 100) : 0

    // Live WifiNetwork objects, strongest first. NM only keeps the full list
    // populated while its scanner is running, which is why scan()/stopScan()
    // bracket the popup being open rather than running all the time.
    readonly property var networks: {
        if (!device) return []
        const list = device.networks.values.slice()
        list.sort((a, b) => b.signalStrength - a.signalStrength)
        return list
    }

    function isSecure(network) {
        if (!network) return false
        return network.security !== Net.WifiSecurityType.Open
            && network.security !== Net.WifiSecurityType.Owe
    }

    // Enterprise networks need a certificate or an identity, not just a
    // passphrase, so the password field cannot serve them and says so instead
    // of failing silently after the user has typed something.
    function isEnterprise(network) {
        if (!network) return false
        const s = network.security
        return s === Net.WifiSecurityType.Wpa2Eap
            || s === Net.WifiSecurityType.WpaEap
            || s === Net.WifiSecurityType.Wpa3SuiteB192
            || s === Net.WifiSecurityType.DynamicWep
            || s === Net.WifiSecurityType.Leap
    }

    function securityLabel(network) {
        if (!network) return ""
        if (!root.isSecure(network)) return "Open"
        return Net.WifiSecurityType.toString(network.security)
    }

    // ---- Wired ------------------------------------------------------------
    //
    // The wifi device was the only one this service ever looked at, so on a
    // desktop the bar showed "disconnected" forever even on a live cable.

    readonly property var wiredDevice: {
        const devices = Net.Networking.devices.values
        for (let i = 0; i < devices.length; i++)
            if (devices[i].type === Net.DeviceType.Wired) return devices[i]
        return null
    }

    readonly property bool wiredConnected: !!root.wiredDevice && root.wiredDevice.connected
    readonly property bool wiredHasLink: !!root.wiredDevice && root.wiredDevice.hasLink

    property bool scanning: false
    property string connectingTo: ""
    property string lastError: ""
    property var pending: null

    // Set when NM rejects a connection for want of a passphrase. The popup
    // watches this to reveal its password field for that one network, which is
    // the whole reason it exists -- this service used to answer NoSecrets by
    // telling the user to go and run nmtui.
    property var passwordFor: null

    function scan() {
        if (!device || device.scannerEnabled) return
        device.scannerEnabled = true
        root.scanning = true
        scanTimer.restart()
    }

    function stopScan() {
        if (device) device.scannerEnabled = false
        root.scanning = false
        scanTimer.stop()
    }

    function toggleWifi() {
        Net.Networking.wifiEnabled = !Net.Networking.wifiEnabled
    }

    function connectTo(network) {
        if (!network) return
        root.lastError = ""
        root.passwordFor = null
        root.connectingTo = network.name
        root.pending = network
        network.connect()
    }

    function connectWithPassword(network, psk) {
        if (!network) return
        root.lastError = ""
        root.passwordFor = null
        root.connectingTo = network.name
        root.pending = network
        network.connectWithPsk(psk)
    }

    function cancelPassword() {
        root.passwordFor = null
        root.connectingTo = ""
    }

    function disconnectFrom(network) {
        if (network) network.disconnect()
    }

    // Drops the saved connection profile, so the next attempt asks again.
    function forget(network) {
        if (!network) return
        if (root.passwordFor === network) root.passwordFor = null
        network.forget()
    }

    // The scan is a request, not a transaction: NM answers by filling the
    // network list over the next second or two, so the indicator is given a
    // deadline rather than a completion.
    Timer {
        id: scanTimer
        interval: 4000
        onTriggered: root.scanning = false
    }

    // NM says *why* a connection failed, which nmcli could only report as a
    // line of stderr. NoSecrets is the common one: a secured network the machine
    // has no saved passphrase for, which is now a prompt rather than a dead end.
    Connections {
        target: root.pending

        function onConnectionFailed(reason) {
            const net = root.pending

            if (reason === Net.ConnectionFailReason.NoSecrets) {
                // Ask for the passphrase rather than reporting a dead end.
                if (root.isEnterprise(net)) {
                    root.lastError = "\"" + root.connectingTo
                        + "\" is an enterprise network -- set it up once with nmtui"
                } else {
                    root.passwordFor = net
                    root.lastError = ""
                }
            } else {
                root.lastError = "Could not connect to \"" + root.connectingTo + "\" ("
                    + Net.ConnectionFailReason.toString(reason) + ")"
            }

            root.connectingTo = ""
            root.pending = null
        }

        function onConnectedChanged() {
            if (root.pending && root.pending.connected) {
                root.connectingTo = ""
                root.pending = null
            }
        }
    }
}
