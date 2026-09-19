pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// CPU, memory, temperature, disk and network, for the dashboard and anything
// in the bar that wants them. There was no system monitoring in the shell at
// all before this.
//
// Everything here is read straight out of /proc and /sys with FileView rather
// than by shelling out. A FileView reload is a read, not a fork, so sampling a
// few times a second costs effectively nothing -- which is the difference
// between this being always-on and having to be switched off.
Singleton {
    id: root

    // How often the cheap counters are resampled. Disk is far slower (below).
    property int interval: 2000

    // ---- CPU ---------------------------------------------------------------

    // 0..1 across all cores.
    property real cpuUsage: 0
    property int cpuCores: 0

    property real _lastCpuIdle: 0
    property real _lastCpuTotal: 0

    function _readCpu(text) {
        if (!text) return
        const lines = text.split("\n")

        // The aggregate line first, then one per core -- counting those is
        // cheaper than asking nproc.
        let cores = 0
        for (let i = 1; i < lines.length; i++) {
            if (lines[i].startsWith("cpu")) cores++
            else break
        }
        if (cores > 0) root.cpuCores = cores

        const f = lines[0].trim().split(/\s+/)
        if (f.length < 8 || f[0] !== "cpu") return

        // user nice system idle iowait irq softirq steal...
        let total = 0
        for (let i = 1; i < f.length; i++) total += parseFloat(f[i]) || 0
        const idle = (parseFloat(f[4]) || 0) + (parseFloat(f[5]) || 0)

        const dTotal = total - root._lastCpuTotal
        const dIdle = idle - root._lastCpuIdle
        root._lastCpuTotal = total
        root._lastCpuIdle = idle

        // The first sample has nothing to diff against.
        if (dTotal > 0 && root._lastCpuTotal !== dTotal) {
            root.cpuUsage = Math.max(0, Math.min(1, 1 - dIdle / dTotal))
        }
    }

    // ---- Memory ------------------------------------------------------------

    property real memoryTotal: 0      // bytes
    property real memoryUsed: 0
    readonly property real memoryUsage: root.memoryTotal > 0
        ? root.memoryUsed / root.memoryTotal : 0

    function _readMemory(text) {
        if (!text) return
        let total = 0, available = 0
        const lines = text.split("\n")
        for (let i = 0; i < lines.length; i++) {
            const l = lines[i]
            if (l.startsWith("MemTotal:")) total = parseFloat(l.split(/\s+/)[1]) * 1024
            else if (l.startsWith("MemAvailable:")) available = parseFloat(l.split(/\s+/)[1]) * 1024
            if (total > 0 && available > 0) break
        }
        if (total <= 0) return
        root.memoryTotal = total
        // MemAvailable, not MemFree: free excludes cache the kernel would hand
        // back on demand, and reports a machine with plenty of room as full.
        root.memoryUsed = total - available
    }

    // ---- Network -----------------------------------------------------------

    property real netRxRate: 0        // bytes/sec
    property real netTxRate: 0

    property real _lastRx: 0
    property real _lastTx: 0
    property real _lastNetAt: 0

    function _readNetwork(text) {
        if (!text) return
        let rx = 0, tx = 0
        const lines = text.split("\n")
        for (let i = 2; i < lines.length; i++) {
            const parts = lines[i].trim().split(/\s+/)
            if (parts.length < 10) continue
            const name = parts[0].replace(":", "")
            // Loopback and virtual bridges are not "the network".
            if (name === "lo" || name.startsWith("docker") || name.startsWith("veth")
                || name.startsWith("br-") || name.startsWith("virbr")) continue
            rx += parseFloat(parts[1]) || 0
            tx += parseFloat(parts[9]) || 0
        }

        const now = Date.now()
        const dt = (now - root._lastNetAt) / 1000
        if (root._lastNetAt > 0 && dt > 0) {
            // Counters wrap and reset when an interface goes away; a negative
            // delta is not a negative rate.
            root.netRxRate = Math.max(0, (rx - root._lastRx) / dt)
            root.netTxRate = Math.max(0, (tx - root._lastTx) / dt)
        }
        root._lastRx = rx
        root._lastTx = tx
        root._lastNetAt = now
    }

    // ---- Temperature -------------------------------------------------------

    // The CPU package, in celsius. 0 means no sensor was found.
    property real temperature: 0
    property string _tempPath: ""

    // hwmon indices are assigned in probe order and move between boots, so the
    // right one is found by name once at startup rather than hardcoded.
    Process {
        id: findTemp
        running: true
        command: ["bash", "-c",
            "for h in /sys/class/hwmon/hwmon*/; do "
            + "n=$(cat \"$h/name\" 2>/dev/null); "
            + "case \"$n\" in coretemp|k10temp|zenpower) "
            + "[ -r \"$h/temp1_input\" ] && printf '%s' \"$h/temp1_input\" && exit 0;; esac; done; "
            + "printf ''"]
        stdout: StdioCollector {
            onStreamFinished: root._tempPath = text.trim()
        }
    }

    FileView {
        id: tempFile
        path: root._tempPath
        printErrors: false
        onLoaded: {
            const v = parseFloat(text())
            if (!isNaN(v)) root.temperature = v / 1000
        }
    }

    // ---- Disk --------------------------------------------------------------

    property real diskTotal: 0        // bytes
    property real diskUsed: 0
    readonly property real diskUsage: root.diskTotal > 0
        ? root.diskUsed / root.diskTotal : 0

    // df forks, and a root filesystem does not move fast enough to be worth
    // doing at the sampling rate of everything else.
    Process {
        id: diskProc
        command: ["bash", "-c", "df -kP / | awk 'NR==2 {print $2, $3}'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim().split(/\s+/)
                if (p.length < 2) return
                root.diskTotal = (parseFloat(p[0]) || 0) * 1024
                root.diskUsed = (parseFloat(p[1]) || 0) * 1024
            }
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: if (!diskProc.running) diskProc.running = true
    }

    // ---- Sampling ----------------------------------------------------------

    FileView { id: statFile; path: "/proc/stat"; printErrors: false; onLoaded: root._readCpu(text()) }
    FileView { id: memFile; path: "/proc/meminfo"; printErrors: false; onLoaded: root._readMemory(text()) }
    FileView { id: netFile; path: "/proc/net/dev"; printErrors: false; onLoaded: root._readNetwork(text()) }

    Timer {
        interval: root.interval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            statFile.reload()
            memFile.reload()
            netFile.reload()
            if (root._tempPath !== "") tempFile.reload()
        }
    }

    // ---- Presentation ------------------------------------------------------

    function formatBytes(bytes) {
        const b = bytes || 0
        if (b >= 1073741824) return (b / 1073741824).toFixed(1) + " GB"
        if (b >= 1048576) return (b / 1048576).toFixed(0) + " MB"
        if (b >= 1024) return (b / 1024).toFixed(0) + " KB"
        return Math.round(b) + " B"
    }

    function formatRate(bytesPerSec) {
        const b = bytesPerSec || 0
        if (b >= 1048576) return (b / 1048576).toFixed(1) + " MB/s"
        if (b >= 1024) return (b / 1024).toFixed(0) + " KB/s"
        return Math.round(b) + " B/s"
    }
}
