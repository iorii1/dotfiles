pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool present: false
    property int percent: 0
    property bool charging: false

    function refresh() {
        if (!proc.running) proc.running = true
    }

    Process {
        id: proc
        command: ["bash", "-c", "upower -i $(upower -e | grep -m1 'BAT') 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.present = text.trim() !== ""
                const pct = text.match(/percentage:\s*(\d+)%/)
                const state = text.match(/state:\s*(\S+)/)
                root.percent = pct ? parseInt(pct[1]) : 0
                root.charging = state ? ["charging", "fully-charged", "pending-charge"].indexOf(state[1]) !== -1 : false
            }
        }
    }

    Timer {
        interval: 20000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
