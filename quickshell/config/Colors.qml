pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string colorsPath: Quickshell.env("HOME") + "/.config/quickshell/generated/colors.json"

    // Fallback palette so the shell never crashes before matugen has ever run.
    property color background: "#1e1e2e"
    property color surfaceContainer: "#292c3c"
    property color surfaceContainerHigh: "#363a4f"
    property color textPrimary: "#cad3f5"
    property color textSecondary: "#a5adcb"
    property color outline: "#8087a2"
    property color primary: "#8aadf4"
    property color primaryText: "#181926"
    property color error: "#ed8796"
    property color errorText: "#181926"

    // A palette colour at a given alpha. The shell's surfaces sit on a
    // compositor blur (see Appearance.surfaceOpacity), so most fills are
    // translucent versions of one of the colours above.
    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a)
    }

    function apply(json) {
        try {
            const c = JSON.parse(json)
            if (c.background) root.background = c.background
            if (c.surface_container) root.surfaceContainer = c.surface_container
            if (c.surface_container_high) root.surfaceContainerHigh = c.surface_container_high
            if (c.on_surface) root.textPrimary = c.on_surface
            if (c.on_surface_variant) root.textSecondary = c.on_surface_variant
            if (c.outline) root.outline = c.outline
            if (c.primary) root.primary = c.primary
            if (c.on_primary) root.primaryText = c.on_primary
            if (c.error) root.error = c.error
            if (c.on_error) root.errorText = c.on_error
        } catch (e) {
            console.warn("Colors: failed to parse colors.json:", e)
        }
    }

    IpcHandler {
        target: "theme"

        function reloadColors(): void {
            colorsFile.reload()
        }
    }

    FileView {
        id: colorsFile
        path: root.colorsPath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.apply(text())
    }
}
