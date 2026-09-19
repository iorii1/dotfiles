import QtQuick
import Quickshell
import Quickshell.Io

// Toasts for state the shell knows about but never told you: the charger going
// in or out, do-not-disturb flipping, the default audio device changing, caps
// lock.
//
// These go through notify-send rather than straight into the Notifications
// service so they behave like any other notification -- they land in history,
// respect do-not-disturb, and can be muted per-app like anything else.
//
// Not a singleton: it has no public API and nothing would ever reference it,
// and a singleton nothing references is never created. shell.qml instantiates
// it instead.
//
// Everything here is armed on a delay. Without it every one of these fires
// once at startup, when the bindings settle for the first time, and you get a
// fistful of toasts on login telling you the state has "changed" to what it
// already was.
Scope {
    id: root

    property bool armed: false

    Timer {
        interval: 4000
        running: true
        onTriggered: {
            // Seed the "what was it before" values at the moment of arming.
            // The Connections below are disabled until then, so they miss the
            // signal that fires as the services first settle -- which left
            // these empty and made the first real change look like the initial
            // one, and get swallowed.
            root._lastSink = Audio.deviceName(Audio.sink)
            root._lastSource = Audio.deviceName(Audio.source)
            root.armed = true
        }
    }

    function _notify(appName, icon, summary, body) {
        if (!root.armed) return
        notifyProc.command = ["notify-send", "-a", appName, "-i", icon, summary, body || ""]
        notifyProc.running = true
    }

    Process { id: notifyProc }

    // ---- Power -------------------------------------------------------------

    Connections {
        target: Battery
        enabled: root.armed

        function onChargingChanged() {
            if (!Battery.present) return
            root._notify("Power",
                Battery.charging ? "battery-charging" : "battery",
                Battery.charging ? "Charging" : "On battery",
                Math.round(Battery.percent) + "%"
                    + (Battery.timeText ? " — " + Battery.timeText : ""))
        }
    }

    // A low battery is worth saying once per threshold crossed, not every time
    // the percentage ticks down inside the same band.
    property int _lastBatteryBand: -1

    Connections {
        target: Battery
        enabled: root.armed

        function onPercentChanged() {
            if (!Battery.present || Battery.charging) { root._lastBatteryBand = -1; return }
            const p = Battery.percent
            const band = p <= 5 ? 5 : (p <= 10 ? 10 : (p <= 20 ? 20 : -1))
            if (band === -1 || band === root._lastBatteryBand) {
                if (band === -1) root._lastBatteryBand = -1
                return
            }
            root._lastBatteryBand = band
            root._notify("Power", "battery-caution",
                band <= 5 ? "Battery critical" : "Battery low",
                Math.round(p) + "% remaining")
        }
    }

    // ---- Notifications -----------------------------------------------------

    Connections {
        target: Notifications
        enabled: root.armed

        function onDndChanged() {
            root._notify("Notifications",
                Notifications.dnd ? "notification-disabled" : "notification",
                Notifications.dnd ? "Do not disturb on" : "Do not disturb off",
                Notifications.dnd ? "Notifications will be held in the centre" : "")
        }
    }

    // ---- Audio -------------------------------------------------------------
    //
    // Only the device changing is worth a toast; volume has the OSD, and
    // announcing every nudge would be unbearable.

    property string _lastSink: ""
    property string _lastSource: ""

    Connections {
        target: Audio
        enabled: root.armed

        function onSinkChanged() {
            const name = Audio.deviceName(Audio.sink)
            if (name === "" || name === root._lastSink) return
            root._lastSink = name
            root._notify("Audio", "audio-speakers", "Output changed", name)
        }

        function onSourceChanged() {
            const name = Audio.deviceName(Audio.source)
            if (name === "" || name === root._lastSource) return
            root._lastSource = name
            root._notify("Audio", "audio-input-microphone", "Input changed", name)
        }
    }

    // ---- Night light and keep awake ----------------------------------------

    Connections {
        target: NightLight
        enabled: root.armed
        function onEnabledChanged() {
            root._notify("Display", "weather-clear-night",
                NightLight.enabled ? "Night light on" : "Night light off",
                NightLight.enabled ? NightLight.nightTemp + "K after dark" : "")
        }
    }

    Connections {
        target: IdleInhibit
        enabled: root.armed
        function onKeepAwakeChanged() {
            root._notify("Session", "preferences-desktop-screensaver",
                IdleInhibit.keepAwake ? "Keep awake on" : "Keep awake off",
                IdleInhibit.keepAwake ? "The screen will not lock or sleep" : "")
        }
    }
}
