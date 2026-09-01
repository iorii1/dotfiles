import QtQuick

Item {
    id: root

    property real nowMs: Date.now()

    // Original hand/tick dimensions were tuned for a 140px face; scale them
    // proportionally so the clock still looks right at other sizes.
    readonly property real s: width / 140

    // Fast tick + a short linear Behavior on each hand = a continuous sweep
    // instead of a once-a-second nudge that reads as "stuck".
    Timer {
        interval: 50
        running: true
        repeat: true
        onTriggered: root.nowMs = Date.now()
    }

    // Date.now() is UTC epoch ms - shift it by the local timezone offset so
    // the hands track wall-clock local time, not UTC.
    readonly property real localMs: {
        const d = new Date(root.nowMs)
        return root.nowMs - d.getTimezoneOffset() * 60000
    }

    // Continuously increasing angles (no modulo) so the Behavior below always
    // sweeps forward smoothly instead of snapping backwards at 59 -> 0.
    readonly property real secAngle: (root.localMs / 1000) * 6
    readonly property real minAngle: (root.localMs / 60000) * 6
    readonly property real hourAngle: (root.localMs / 3600000) * 30

    // Outer glow ring, breathing in and out so the clock reads as alive.
    Rectangle {
        id: glowRing
        anchors.fill: parent
        radius: width / 2
        color: "transparent"
        border.width: 3 * root.s
        border.color: "#40fab387"
        scale: 1.0
        opacity: 0.7

        SequentialAnimation on opacity {
            loops: Animation.Infinite
            NumberAnimation { to: 1.0; duration: 1800; easing.type: Easing.InOutSine }
            NumberAnimation { to: 0.45; duration: 1800; easing.type: Easing.InOutSine }
        }
        SequentialAnimation on scale {
            loops: Animation.Infinite
            NumberAnimation { to: 1.035; duration: 1800; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1.0; duration: 1800; easing.type: Easing.InOutSine }
        }
    }

    Rectangle {
        id: face
        anchors.fill: parent
        anchors.margins: 3 * root.s
        radius: width / 2
        color: "#1e2a44"
        border.width: 2
        border.color: "#fab387"

        Rectangle {
            anchors.centerIn: parent
            width: parent.width - 16 * root.s
            height: width
            radius: width / 2
            color: "#182338"
        }

        Repeater {
            model: 12
            Rectangle {
                required property int index
                readonly property bool major: index % 3 === 0
                width: (major ? 3 : 1.5) * root.s
                height: (major ? 9 : 5) * root.s
                radius: width / 2
                color: major ? "#fab387" : "#94a3b8"
                anchors.horizontalCenter: parent.horizontalCenter
                y: 7 * root.s
                transform: Rotation {
                    origin.x: width / 2
                    origin.y: face.height / 2 - 7 * root.s
                    angle: index * 30
                }
            }
        }

        // hour hand
        Rectangle {
            width: 4 * root.s
            height: face.height * 0.26
            radius: width / 2
            color: "#cdd6f4"
            anchors.horizontalCenter: parent.horizontalCenter
            y: face.height / 2 - height
            transformOrigin: Item.Bottom
            rotation: root.hourAngle
            Behavior on rotation {
                NumberAnimation { duration: 60; easing.type: Easing.Linear }
            }
        }

        // minute hand
        Rectangle {
            width: 3 * root.s
            height: face.height * 0.36
            radius: width / 2
            color: "#cdd6f4"
            anchors.horizontalCenter: parent.horizontalCenter
            y: face.height / 2 - height
            transformOrigin: Item.Bottom
            rotation: root.minAngle
            Behavior on rotation {
                NumberAnimation { duration: 60; easing.type: Easing.Linear }
            }
        }

        // second hand
        Rectangle {
            width: 1.5 * root.s
            height: face.height * 0.4
            radius: width / 2
            color: "#fab387"
            anchors.horizontalCenter: parent.horizontalCenter
            y: face.height / 2 - height
            transformOrigin: Item.Bottom
            rotation: root.secAngle
            Behavior on rotation {
                NumberAnimation { duration: 60; easing.type: Easing.Linear }
            }
        }

        Rectangle {
            anchors.centerIn: parent
            width: 6 * root.s
            height: 6 * root.s
            radius: width / 2
            color: "#fab387"
        }
    }
}
