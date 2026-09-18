import QtQuick
import "../../config"

// The overshooting counterpart to Anim, for things that pop rather than
// settle: a popup card arriving, a toggle handle snapping across. Small
// elements should overshoot harder -- `PopAnim { easing.overshoot: Appearance.overshootPop }`.
NumberAnimation {
    duration: Appearance.animNormal
    easing.type: Easing.OutBack
    easing.overshoot: Appearance.overshootCard
}
