pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool wifiEnabled: true
    property bool connected: false
    property string ssid: ""
    property int signalStrength: 0
    property var networks: []
    property bool scanning: false
    property string connectingTo: ""
    property string lastError: ""

    function refreshStatus() {
        if (!statusProc.running) statusProc.running = true
    }

    function scan() {
        if (scanProc.running) return
        root.scanning = true
        scanProc.running = true
    }

    function toggleWifi() {
        toggleProc.command = ["bash", "-c", "nmcli radio wifi " + (root.wifiEnabled ? "off" : "on")]
        toggleProc.running = true
    }

    // argv directly rather than `bash -c` -- an SSID is attacker-controlled
    // (it is whatever a nearby AP broadcasts), so it must never reach a shell.
    function connectTo(ssid) {
        root.lastError = ""
        root.connectingTo = ssid
        connectProc.command = ["nmcli", "device", "wifi", "connect", ssid]
        connectProc.running = true
    }

    Process {
        id: statusProc
        command: ["bash", "-c", "nmcli -t -f WIFI radio; nmcli -t -f ACTIVE,SSID,SIGNAL dev wifi 2>/dev/null | grep '^yes'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")
                root.wifiEnabled = lines[0] === "enabled"
                if (lines.length > 1 && lines[1]) {
                    const parts = lines[1].split(":")
                    root.connected = true
                    root.ssid = parts[1] || ""
                    root.signalStrength = parseInt(parts[2]) || 0
                } else {
                    root.connected = false
                    root.ssid = ""
                    root.signalStrength = 0
                }
            }
        }
    }

    Process {
        id: scanProc
        command: ["bash", "-c", "nmcli -t -f SSID,SECURITY,SIGNAL,ACTIVE dev wifi list --rescan yes 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const seen = {}
                const list = []
                const lines = text.trim().split("\n")
                for (const line of lines) {
                    if (!line) continue
                    const parts = line.split(":")
                    const ssid = parts[0]
                    if (!ssid || seen[ssid]) continue
                    seen[ssid] = true
                    list.push({
                        ssid: ssid,
                        secure: (parts[1] || "") !== "",
                        signal: parseInt(parts[2]) || 0,
                        active: parts[3] === "yes"
                    })
                }
                list.sort((a, b) => b.signal - a.signal)
                root.networks = list
                root.scanning = false
                root.refreshStatus()
            }
        }
    }

    Process { id: toggleProc; onExited: root.refreshStatus() }

    Process {
        id: connectProc
        stderr: StdioCollector { id: connectErr }
        onExited: (exitCode) => {
            if (exitCode !== 0) {
                // nmcli cannot prompt for a passphrase from here, so an unsaved
                // secured network lands in this branch rather than connecting.
                const msg = connectErr.text.trim().replace(/^Error:\s*/, "")
                root.lastError = msg.length > 0 ? msg : "Could not connect to " + root.connectingTo
            }
            root.connectingTo = ""
            root.refreshStatus()
            root.scan()
        }
    }

    Timer {
        interval: 8000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshStatus()
    }
}
