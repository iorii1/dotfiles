pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../config"

// Runtime-editable bar settings, persisted outside the repo (~/.config/quickshell
// is a symlink to the dotfiles checkout, so writing there would litter the tree).
Singleton {
    id: root

    readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/quickshell"
    readonly property string configPath: stateDir + "/bar.json"

    property int barHeight: Appearance.barHeight
    property int barMargin: Appearance.barMargin
    property int barRadius: Appearance.radiusLarge
    property real barOpacity: 0.88

    // Whole-shell knobs that live on Appearance. They are mirrored here so
    // they persist and so the settings app can drive them the same way it
    // drives everything else; the bindings below push them back.
    property real animScale: 1.0
    property real roundingScale: 1.0

    onAnimScaleChanged: Appearance.animScale = root.animScale
    onRoundingScaleChanged: Appearance.roundingScale = root.roundingScale

    property bool showWorkspaces: true
    property bool showWindowTitle: true
    property bool showTaskbar: true
    property bool showCava: true
    property bool showMedia: true
    property bool showNotifications: true
    property bool showClock: true
    property bool showTray: true
    property bool showVolume: true
    property bool showQuickSettings: true
    property bool showDashboard: true
    property bool showBattery: true
    property bool showWifi: true
    property bool showBluetooth: true
    property bool showPower: true

    readonly property var defaults: ({
        barHeight: Appearance.barHeight,
        barMargin: Appearance.barMargin,
        barRadius: Appearance.radiusLarge,
        barOpacity: 0.88,
        animScale: 1.0,
        roundingScale: 1.0,
        showWorkspaces: true,
        showWindowTitle: true,
        showTaskbar: true,
        showCava: true,
        showMedia: true,
        showNotifications: true,
        showClock: true,
        showTray: true,
        showVolume: true,
        showQuickSettings: true,
        showDashboard: true,
        showBattery: true,
        showWifi: true,
        showBluetooth: true,
        showPower: true
    })

    // Guards the load -> property-write -> save loop from writing the file back
    // while it is still being applied.
    property bool _loaded: false

    function reset() {
        applyObject(root.defaults)
        save()
    }

    function applyObject(c) {
        if (typeof c.barHeight === "number") root.barHeight = c.barHeight
        if (typeof c.barMargin === "number") root.barMargin = c.barMargin
        if (typeof c.barRadius === "number") root.barRadius = c.barRadius
        if (typeof c.barOpacity === "number") root.barOpacity = c.barOpacity
        if (typeof c.animScale === "number") root.animScale = c.animScale
        if (typeof c.roundingScale === "number") root.roundingScale = c.roundingScale
        if (typeof c.showWorkspaces === "boolean") root.showWorkspaces = c.showWorkspaces
        if (typeof c.showWindowTitle === "boolean") root.showWindowTitle = c.showWindowTitle
        if (typeof c.showTaskbar === "boolean") root.showTaskbar = c.showTaskbar
        if (typeof c.showCava === "boolean") root.showCava = c.showCava
        if (typeof c.showMedia === "boolean") root.showMedia = c.showMedia
        if (typeof c.showNotifications === "boolean") root.showNotifications = c.showNotifications
        if (typeof c.showClock === "boolean") root.showClock = c.showClock
        if (typeof c.showTray === "boolean") root.showTray = c.showTray
        if (typeof c.showVolume === "boolean") root.showVolume = c.showVolume
        if (typeof c.showQuickSettings === "boolean") root.showQuickSettings = c.showQuickSettings
        if (typeof c.showDashboard === "boolean") root.showDashboard = c.showDashboard
        if (typeof c.showBattery === "boolean") root.showBattery = c.showBattery
        if (typeof c.showWifi === "boolean") root.showWifi = c.showWifi
        if (typeof c.showBluetooth === "boolean") root.showBluetooth = c.showBluetooth
        if (typeof c.showPower === "boolean") root.showPower = c.showPower
    }

    function serialize() {
        return {
            barHeight: root.barHeight,
            barMargin: root.barMargin,
            barRadius: root.barRadius,
            barOpacity: root.barOpacity,
            animScale: root.animScale,
            roundingScale: root.roundingScale,
            showWorkspaces: root.showWorkspaces,
            showWindowTitle: root.showWindowTitle,
            showTaskbar: root.showTaskbar,
            showCava: root.showCava,
            showMedia: root.showMedia,
            showNotifications: root.showNotifications,
            showClock: root.showClock,
            showTray: root.showTray,
            showVolume: root.showVolume,
            showQuickSettings: root.showQuickSettings,
            showDashboard: root.showDashboard,
            showBattery: root.showBattery,
            showWifi: root.showWifi,
            showBluetooth: root.showBluetooth,
            showPower: root.showPower
        }
    }

    function save() {
        if (!root._loaded) return
        saveTimer.restart()
    }

    Timer {
        id: saveTimer
        interval: 300
        onTriggered: configFile.setText(JSON.stringify(root.serialize(), null, 2) + "\n")
    }

    Process {
        id: mkdir
        command: ["mkdir", "-p", root.stateDir]
        running: true
        onExited: configFile.reload()
    }

    FileView {
        id: configFile
        path: root.configPath
        printErrors: false

        onLoaded: {
            try {
                root.applyObject(JSON.parse(text()))
            } catch (e) {
                console.warn("BarConfig: failed to parse bar.json:", e)
            }
            root._loaded = true
        }

        // No settings file yet -- start from defaults and write one on first change.
        onLoadFailed: root._loaded = true
    }
}
