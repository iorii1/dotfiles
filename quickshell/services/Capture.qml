pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Screenshots and screen recording.
//
// take-screenshot was a bare grim/slurp script: no window picking, no annotate
// step (satty is installed and was never called), and files dropped loose into
// ~/Pictures. Shots now land in a folder of their own and go through a preview
// where they can be copied, saved, annotated or thrown away -- so a mis-framed
// region costs nothing.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string saveDir: root.home + "/Pictures/Screenshots"
    readonly property string tmpDir: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/quickshell-capture"

    // The shot waiting in the preview, or "" when there is none.
    property string pending: ""

    property bool recording: false
    property string recordingPath: ""
    property string lastError: ""

    readonly property bool recorderAvailable: root._recorderChecked && root._recorderPath !== ""
    property bool _recorderChecked: false
    property string _recorderPath: ""

    function _stamp() {
        const d = new Date()
        const p = (n) => (n < 10 ? "0" : "") + n
        return d.getFullYear() + "-" + p(d.getMonth() + 1) + "-" + p(d.getDate())
            + "_" + p(d.getHours()) + "-" + p(d.getMinutes()) + "-" + p(d.getSeconds())
    }

    // ---- Taking a shot -----------------------------------------------------

    // Every shot lands on the same scratch file; the preview busts Qt's image
    // cache with a query string, and nothing is kept unless it is saved.
    readonly property string scratchShot: root.tmpDir + "/pending.png"

    function _shoot(geometryCmd) {
        shotProc.command = ["bash", "-c",
            "mkdir -p " + JSON.stringify(root.tmpDir) + "; " + geometryCmd]
        shotProc.running = true
    }

    function region() {
        root._shoot("geom=$(slurp) || exit 1; grim -g \"$geom\" " + JSON.stringify(root.scratchShot))
    }

    function output() {
        root._shoot("geom=$(slurp -o) || exit 1; grim -g \"$geom\" " + JSON.stringify(root.scratchShot))
    }

    function screen() {
        root._shoot("grim " + JSON.stringify(root.scratchShot))
    }

    // Window picking: hand slurp the geometry of every window on the active
    // workspaces and let it restrict the selection to those boxes, so a click
    // anywhere inside a window grabs exactly that window.
    function window() {
        root._shoot(
            "boxes=$(hyprctl clients -j | python3 -c \""
            + "import json,sys\n"
            + "for c in json.load(sys.stdin):\n"
            + "    if c.get('hidden') or not c.get('mapped'): continue\n"
            + "    x,y = c['at']; w,h = c['size']\n"
            + "    if w <= 0 or h <= 0: continue\n"
            + "    print(f'{x},{y} {w}x{h}')\n"
            + "\"); "
            + "[ -n \"$boxes\" ] || exit 1; "
            + "geom=$(printf '%s\\n' \"$boxes\" | slurp -r) || exit 1; "
            + "grim -g \"$geom\" " + JSON.stringify(root.scratchShot))
    }

    Process {
        id: shotProc
        // grim exits non-zero when slurp is cancelled, which is someone
        // changing their mind rather than a failure worth reporting.
        onExited: (code) => {
            if (code !== 0) return
            root.pending = root.scratchShot + "?t=" + Date.now()
        }
    }

    readonly property string pendingFile: {
        const q = root.pending.indexOf("?")
        return q === -1 ? root.pending : root.pending.substring(0, q)
    }

    // ---- What to do with it ------------------------------------------------

    function copyShot() {
        if (!root.pending) return
        actionProc.command = ["bash", "-c",
            "wl-copy --type image/png < " + JSON.stringify(root.pendingFile)]
        actionProc.running = true
        root.discard()
    }

    function saveShot() {
        if (!root.pending) return
        const dest = root.saveDir + "/" + root._stamp() + ".png"
        actionProc.command = ["bash", "-c",
            "mkdir -p " + JSON.stringify(root.saveDir) + "; "
            + "cp -- " + JSON.stringify(root.pendingFile) + " " + JSON.stringify(dest) + "; "
            + "wl-copy --type image/png < " + JSON.stringify(dest) + "; "
            + "notify-send -a Screenshot -i " + JSON.stringify(dest)
            + " 'Screenshot saved' " + JSON.stringify(dest)]
        actionProc.running = true
        root.discard()
    }

    // satty has been installed all along and nothing ever invoked it.
    function annotateShot() {
        if (!root.pending) return
        const dest = root.saveDir + "/" + root._stamp() + ".png"
        actionProc.command = ["bash", "-c",
            "mkdir -p " + JSON.stringify(root.saveDir) + "; "
            + "satty --filename " + JSON.stringify(root.pendingFile)
            + " --output-filename " + JSON.stringify(dest)
            + " --early-exit --copy-command wl-copy"]
        actionProc.running = true
        root.discard()
    }

    function discard() {
        root.pending = ""
    }

    Process { id: actionProc }

    // ---- Recording ---------------------------------------------------------

    function toggleRecording() {
        if (root.recording) root.stopRecording()
        else root.startRecording()
    }

    function startRecording() {
        if (root.recording) return
        if (!root.recorderAvailable) {
            root.lastError = "wf-recorder is not installed"
            return
        }
        const dest = root.home + "/Videos/Screencasts/" + root._stamp() + ".mp4"
        root.recordingPath = dest
        recordProc.command = ["bash", "-c",
            "mkdir -p " + JSON.stringify(root.home + "/Videos/Screencasts") + "; "
            + "geom=$(slurp) || exit 1; exec " + JSON.stringify(root._recorderPath)
            + " -g \"$geom\" -f " + JSON.stringify(dest)]
        recordProc.running = true
        root.recording = true
    }

    function stopRecording() {
        if (!root.recording) return
        // The recorder finalises the container on SIGINT; killing it outright
        // leaves an unplayable file. Named after whichever binary was found,
        // not assumed to be wf-recorder.
        stopProc.command = ["bash", "-c",
            "pkill -INT -x \"$(basename " + JSON.stringify(root._recorderPath) + ")\" || true"]
        stopProc.running = true
    }

    Process {
        id: recordProc
        onExited: (code) => {
            root.recording = false
            if (code === 0 && root.recordingPath) {
                notifyProc.command = ["notify-send", "-a", "Screen recording",
                    "Recording saved", root.recordingPath]
                notifyProc.running = true
            }
            root.recordingPath = ""
        }
    }

    Process { id: stopProc }
    Process { id: notifyProc }

    Process {
        id: whichProc
        command: ["bash", "-c", "command -v wf-recorder || command -v wl-screenrec || true"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root._recorderPath = text.trim()
                root._recorderChecked = true
            }
        }
    }
}
