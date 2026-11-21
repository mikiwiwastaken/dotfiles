import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import qs.config
import qs.modules.audio
import qs.modules.clock
import qs.modules.battery
import qs.modules.workspaces
import qs.modules.network
import qs.modules.notifications
import qs.modules.tray

PanelWindow {
    id: win

    required property var modelData
    required property var notificationServer
    screen: modelData

    readonly property int gapSide: Appearance.barSideMargin
    readonly property int gapTop: 5
    readonly property int gapBottom: 0

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: Appearance.barHeight + gapTop + gapBottom
    color: "transparent"

    WlrLayershell.namespace: "qs-bar"

    mask: Region {
        item: barBg
    }

    Rectangle {
        id: barBg

        anchors {
            fill: parent
            topMargin: win.gapTop
            leftMargin: win.gapSide
            rightMargin: win.gapSide
            bottomMargin: win.gapBottom
        }

        radius: Appearance.rounding
        color: Qt.rgba(Colors.base.r, Colors.base.g, Colors.base.b, Appearance.bar)
        border.width: Appearance.borderLine
        border.color: Colors.surface1

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#000000"
            shadowOpacity: Appearance.shadow
            shadowBlur: 0.8
            shadowVerticalOffset: 4
            shadowHorizontalOffset: 0
        }
    }

    Item {
        anchors.fill: barBg

        Workspaces {
            anchors {
                left: parent.left
                leftMargin: 16
                verticalCenter: parent.verticalCenter
            }
        }

        Clock {
            anchors.centerIn: parent
            anchorItem: parent
        }

        Row {
            id: rightModules

            anchors {
                right: parent.right
                rightMargin: Appearance.barContentMargin
                verticalCenter: parent.verticalCenter
            }

            spacing: 16

            Tray {}
            NetworkStatus {}
            VolumeStatus {}
            BatteryStatus {}
            NotificationCenter {
                notificationServer: win.notificationServer
                screen: win.modelData
                anchorItem: parent.parent
            }
        }
    }
}
