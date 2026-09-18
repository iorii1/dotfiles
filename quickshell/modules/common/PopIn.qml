import QtQuick
import "../../config"

// Shared "pop in" entrance animation: pause, then scale+fade up with a
// slight overshoot. Give the target an initial `scale: fromScale` and
// `opacity: 0` binding (so it doesn't flash at full size during the
// pause), then call start() -- or restart() to replay it.
SequentialAnimation {
    id: root

    required property Item target

    // Usually Appearance.staggerDelay(index). A delegate's index goes to -1
    // while it is being destroyed, so clamp rather than hand PauseAnimation a
    // negative duration, which it rejects with a warning.
    property int delay: 0

    property real fromScale: Appearance.popFromScale
    property int scaleDuration: Appearance.animNormal
    property int opacityDuration: Appearance.animFast
    property real overshoot: Appearance.overshootPop

    PauseAnimation { duration: Math.max(0, root.delay) }
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
            easing.type: Easing.Bezier
            easing.bezierCurve: Appearance.easeDecelerate
        }
    }
}
