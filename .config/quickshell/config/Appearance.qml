pragma Singleton
import Quickshell
import QtQuick

Singleton {
    readonly property int barHeight: 38
    readonly property int border: 8
    readonly property int rounding: 20
    readonly property int borderLine: 2
    readonly property int barItemHeight: 26
    readonly property int menuIconSize: 16
    readonly property int barSideMargin: 10
    readonly property int barContentMargin: 16
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property int fontSmall: 11
    readonly property int fontNormal: 13
    readonly property int fontLarge: 16
    readonly property int fast: 150
    readonly property int normal: 280
    readonly property int slow: 450
    readonly property real popupScaleFrom: 0.94
    readonly property real bar: 0.65
    readonly property real popup: 0.75
    readonly property real tooltip: 0.90
    readonly property real shadow: 0.4
}
