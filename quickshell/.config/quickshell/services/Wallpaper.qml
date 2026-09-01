pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string wallpaperDir: "/home/yor/Pictures/Wallpapers"
    readonly property string stateFile: "/home/yor/.cache/quickshell/wallpaper_current"
    readonly property string fallback: "/home/yor/Pictures/wallpaper.jpg"

    property string currentPath: fallback
    // [{ path, name, isVideo }]
    property var items: []

    readonly property var videoExts: ["mp4", "webm", "mkv", "mov", "gif"]

    function isVideoPath(path) {
        const ext = path.split(".").pop().toLowerCase()
        return videoExts.indexOf(ext) !== -1
    }

    function scan() {
        scanProc.running = true
    }

    function apply(path) {
        if (!path) return
        currentPath = path
        killProc.command = ["bash", "-c", "pkill -x swaybg; pkill -x mpvpaper; sleep 0.15"]
        killProc.running = true
        saveProc.command = ["bash", "-c", "mkdir -p ~/.cache/quickshell && printf '%s' " + shellQuote(path) + " > " + shellQuote(stateFile)]
        saveProc.running = true
    }

    function shellQuote(s) {
        return "'" + s.replace(/'/g, "'\\''") + "'"
    }

    Process {
        id: killProc
        onExited: launchProc.running = true
    }

    Process {
        id: launchProc
        command: root.isVideoPath(root.currentPath)
            ? ["mpvpaper", "-o", "no-audio loop", "*", root.currentPath]
            : ["swaybg", "-i", root.currentPath]
    }

    Process { id: saveProc }

    Process {
        id: scanProc
        command: ["bash", "-c",
            "find " + shellQuote(wallpaperDir) + " -maxdepth 1 -type f \\( " +
            "-iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.avif' -o " +
            "-iname '*.mp4' -o -iname '*.webm' -o -iname '*.mkv' -o -iname '*.mov' -o -iname '*.gif' " +
            "\\) 2>/dev/null | sort"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.split("\n").filter(l => l.length > 0)
                root.items = lines.map(p => ({
                    path: p,
                    name: p.substring(p.lastIndexOf("/") + 1),
                    isVideo: root.isVideoPath(p)
                }))
            }
        }
    }

    Process {
        id: loadStateProc
        command: ["bash", "-c", "cat " + shellQuote(stateFile) + " 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const saved = this.text.trim()
                root.currentPath = saved.length > 0 ? saved : root.fallback
                // Kill whatever autostart (or a previous quickshell instance)
                // may already have launched before starting our own renderer.
                killProc.command = ["bash", "-c", "pkill -x swaybg; pkill -x mpvpaper; sleep 0.15"]
                killProc.running = true
            }
        }
    }

    Component.onCompleted: {
        scan()
        loadStateProc.running = true
    }
}
