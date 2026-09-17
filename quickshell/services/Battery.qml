pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool present: false
    property int percent: 0
    property bool charging: false
    property string state: ""
    property string timeText: ""
    property int chargeEndThreshold: 100

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
                root.state = state ? state[1] : ""
                root.charging = state ? ["charging", "fully-charged", "pending-charge"].indexOf(state[1]) !== -1 : false

                const toEmpty = text.match(/time to empty:\s*(.+)/)
                const toFull = text.match(/time to full:\s*(.+)/)
                if (toEmpty) root.timeText = toEmpty[1].trim() + " remaining"
                else if (toFull) root.timeText = toFull[1].trim() + " until full"
                else root.timeText = ""

                const end = text.match(/charge-end-threshold:\s*(\d+)%/)
                root.chargeEndThreshold = end ? parseInt(end[1]) : 100
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
