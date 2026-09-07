import QtQuick

// Shared "pop in" entrance animation: pause, then scale+fade up with a
// slight overshoot. Give the target an initial `scale: fromScale` and
// `opacity: 0` binding (so it doesn't flash at full size during the
// pause), then call start() -- or restart() to replay it.
SequentialAnimation {
    id: root

    required property Item target
    property int delay: 0
    property real fromScale: 0.85
    property int scaleDuration: 240
    property int opacityDuration: 200
    property real overshoot: 1.4

    PauseAnimation { duration: root.delay }
    ParallelAnimation {
        NumberAnimation {
            target: root.target
            property: "scale"
            from: root.fromScale
            to: 1.0
            duration: root.scaleDuration
            easing.type: Easing.OutBack
            easing.overshoot: root.overshoot
        }
        NumberAnimation {
            target: root.target
            property: "opacity"
            from: 0.0
            to: 1.0
            duration: root.opacityDuration
            easing.type: Easing.OutQuad
        }
    }
}
