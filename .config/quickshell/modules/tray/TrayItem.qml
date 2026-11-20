import Quickshell.Widgets
import QtQuick
import qs.config

Item {
    id: root

    required property var modelData
    readonly property var item: modelData

    implicitWidth: 20
    implicitHeight: Appearance.barItemHeight

    IconImage {
        anchors.centerIn: parent
        implicitSize: 18
        source: root.item.icon
    }

    TrayMenu {
        id: menu
        anchorItem: root
        handle: root.item.menu
    }

    function openMenu() {
        if (!root.item.hasMenu)
            return
        if (Date.now() - menu.closedAt < 200)
            return
        menu.visible = !menu.visible
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor

        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton) {
                if (root.item.onlyMenu)
                    root.openMenu()
                else
                    root.item.activate()
            } else if (mouse.button === Qt.RightButton) {
                if (root.item.hasMenu)
                    root.openMenu()
                else
                    root.item.secondaryActivate()
            } else {
                root.item.secondaryActivate()
            }
        }

        onWheel: wheel => root.item.scroll(wheel.angleDelta.y, false)
    }
}
