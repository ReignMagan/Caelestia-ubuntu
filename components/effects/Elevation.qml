import QtQuick
import QtQuick.Effects
import qs.components
import qs.services

Item {
    id: root

    property int level
    property real dp: [0, 1, 3, 6, 8, 12][level]
    property real radius
    // Qt 6.10 has no per-corner RectangularShadow radii. Retain the public
    // interface while using a uniform shadow; foreground corner shapes stay intact.
    property real topLeftRadius: radius
    property real topRightRadius: radius
    property real bottomLeftRadius: radius
    property real bottomRightRadius: radius
    property alias color: shadow.color
    property alias blur: shadow.blur
    property alias spread: shadow.spread
    property alias offset: shadow.offset

    RectangularShadow {
        id: shadow
        anchors.fill: parent
        radius: root.radius
        color: Qt.alpha(Colours.palette.m3shadow, 0.7)
        blur: (root.dp * 5) ** 0.7
        spread: -root.dp * 0.3 + (root.dp * 0.1) ** 2
        offset.y: root.dp / 2
    }

    Behavior on dp {
        Anim {
            type: Anim.SlowEffects
        }
    }
}
