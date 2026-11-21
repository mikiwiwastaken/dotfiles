import Quickshell
import QtQuick
import qs.config

PopupWindow {
    id: root

    required property Item anchorItem
    required property var handle

    // Used to ignore a click that dismissed the menu immediately after opening it
    property double closedAt: 0

    readonly property int padding: 6

    // Open below the icon, extending down and to the left (tray sits at the right edge)
    anchor.item: root.anchorItem
    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Left
    anchor.margins.bottom: -15
    anchor.margins.right: -30

    grabFocus: true
    color: "transparent"

    implicitWidth: panel.width
    implicitHeight: panel.height

    onVisibleChanged: {
        if (visible) {
            panel.opacity = 0;
            panel.y = -10;
            openAnim.restart();
        } else {
            closedAt = Date.now();
        }
    }

    Rectangle {
        id: panel

        width: list.width + root.padding * 2
        height: list.height + root.padding * 2

        radius: 14
        color: Qt.rgba(Colors.base.r, Colors.base.g, Colors.base.b, Appearance.popup)
        border.width: Appearance.borderLine
        border.color: Colors.surface1
        transformOrigin: Item.TopRight

        MenuList {
            id: list
            x: root.padding
            y: root.padding
            menu: root.handle
            width: Math.max(implicitWidth, 200)

            onActivated: root.visible = false
        }
    }

    ParallelAnimation {
        id: openAnim

        NumberAnimation {
            target: panel
            property: "opacity"
            from: 0
            to: 1
            duration: Appearance.normal
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: panel
            property: "y"
            from: -10
            to: 0
            duration: Appearance.normal
            easing.type: Easing.OutCubic
        }
    }
}
