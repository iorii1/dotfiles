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
        return !!network && network.security !== Net.WifiSecurityType.Open
    }

    property bool scanning: false
    property string connectingTo: ""
    property string lastError: ""
    property var pending: null

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
        root.connectingTo = network.name
        root.pending = network
        network.connect()
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
    // line of stderr. NoSecrets is the common one here: a secured network the
    // machine has no saved passphrase for, and this shell has nowhere to type
    // one yet.
    Connections {
        target: root.pending

        function onConnectionFailed(reason) {
            root.lastError = reason === Net.ConnectionFailReason.NoSecrets
                ? "\"" + root.connectingTo + "\" needs a password -- connect once with nmcli or nmtui"
                : "Could not connect to \"" + root.connectingTo + "\" ("
                    + Net.ConnectionFailReason.toString(reason) + ")"
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
