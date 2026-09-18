pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Warms the screen after dark, via wlsunset.
//
// wlsunset has been installed all along and nothing in the repo ever mentioned
// it -- there was no night light, no gamma control and no way to get one
// without dropping to a terminal.
//
// wlsunset has no DBus interface and no runtime controls: it is configured by
// its arguments and stopped by signal, so "on" and "off" here mean running and
// not running, and a temperature change is a restart.
Singleton {
    id: root

    property bool enabled: false

    // Kelvin. The high value applies during the day, the low one at night; the
    // gap between them is what you actually see.
    property int dayTemp: 6500
    property int nightTemp: 4000

    // wlsunset needs to know where you are to know when the sun sets. The
    // calendar's weather already geolocates, so that answer is reused rather
    // than asking again or making the user type coordinates.
    readonly property real latitude: Weather.latitude
    readonly property real longitude: Weather.longitude
    readonly property bool hasLocation: Weather.hasLocation

    Persist {
        id: store
        fileName: "nightlight.json"
        defaults: ({ enabled: false, dayTemp: 6500, nightTemp: 4000 })
        onLoaded: {
            root.dayTemp = store.value("dayTemp") || 6500
            root.nightTemp = store.value("nightTemp") || 4000
            // Adopt the saved state by actually starting it, not just by
            // setting a flag that claims it is on.
            if (store.value("enabled") === true) root.start()
            else root.refresh()
        }
    }

    function _persist() {
        store.patch({ enabled: root.enabled, dayTemp: root.dayTemp, nightTemp: root.nightTemp })
    }

    function toggle() {
        if (root.enabled) root.stop()
        else root.start()
    }

    function start() {
        const args = ["wlsunset", "-t", String(root.nightTemp), "-T", String(root.dayTemp)]
        if (root.hasLocation) {
            args.push("-l", String(root.latitude), "-L", String(root.longitude))
        } else {
            // With no coordinates wlsunset refuses to guess, so fall back to a
            // fixed evening rather than silently doing nothing.
            args.push("-S", "07:00", "-s", "19:00")
        }
        startProc.command = ["bash", "-c",
            "pkill -x wlsunset 2>/dev/null; sleep 0.2; setsid -f " + args.join(" ") + " >/dev/null 2>&1"]
        startProc.running = true
        root.enabled = true
        root._persist()
    }

    function stop() {
        stopProc.running = true
        root.enabled = false
        root._persist()
    }

    // Reconciles the flag with reality, so a wlsunset killed from elsewhere
    // does not leave the toggle claiming it is still on.
    function refresh() {
        if (!checkProc.running) checkProc.running = true
    }

    function setTemps(night, day) {
        root.nightTemp = night
        root.dayTemp = day
        root._persist()
        if (root.enabled) root.start()
    }

    Process { id: startProc }
    Process { id: stopProc; command: ["bash", "-c", "pkill -x wlsunset 2>/dev/null || true"] }

    Process {
        id: checkProc
        command: ["bash", "-c", "pgrep -x wlsunset >/dev/null && echo on || echo off"]
        stdout: StdioCollector {
            onStreamFinished: root.enabled = (text.trim() === "on")
        }
    }
}
