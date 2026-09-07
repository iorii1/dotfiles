pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool powered: false
    property var devices: []

    function refresh() {
        if (!refreshProc.running) refreshProc.running = true
    }

    function toggle() {
        toggleProc.command = ["bash", "-c", "bluetoothctl power " + (root.powered ? "off" : "on")]
        toggleProc.running = true
    }

    function connectDevice(mac) {
        actionProc.command = ["bash", "-c", "bluetoothctl connect " + mac]
        actionProc.running = true
    }

    function disconnectDevice(mac) {
        actionProc.command = ["bash", "-c", "bluetoothctl disconnect " + mac]
        actionProc.running = true
    }

    Process {
        id: refreshProc
        command: ["bash", "-c", "echo POWERED:$(bluetoothctl show | grep -m1 'Powered:' | awk '{print $2}'); bluetoothctl devices Paired; echo CONNECTED; bluetoothctl devices Connected"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")
                let section = "paired"
                const connectedMacs = {}
                const list = []
                for (const line of lines) {
                    if (line.startsWith("POWERED:")) {
                        root.powered = line.split(":")[1] === "yes"
                        continue
                    }
                    if (line === "CONNECTED") { section = "connected"; continue }
                    const m = line.match(/^Device\s+(\S+)\s+(.*)$/)
                    if (!m) continue
                    if (section === "connected") {
                        connectedMacs[m[1]] = true
                    } else {
                        list.push({ mac: m[1], name: m[2] })
                    }
                }
                for (const d of list) d.connected = !!connectedMacs[d.mac]
                root.devices = list
            }
        }
    }

    Process { id: toggleProc; onExited: root.refresh() }
    Process { id: actionProc; onExited: root.refresh() }

    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
