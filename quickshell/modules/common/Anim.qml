import QtQuick
import "../../config"

// The shell's default animation: the standard curve at the default duration,
// for the state changes that make up most of the motion here. Override what
// differs and nothing else -- `Behavior on x { Anim { duration: Appearance.animFast } }`,
// or `Anim { easing.bezierCurve: Appearance.easeDecelerate }` for an entrance.
NumberAnimation {
    duration: Appearance.animNormal
    easing.type: Easing.Bezier
    easing.bezierCurve: Appearance.easeStandard
}
