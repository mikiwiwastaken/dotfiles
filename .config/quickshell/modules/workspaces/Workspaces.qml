import Quickshell
import Quickshell.Hyprland
import QtQuick
import qs.config

Row {
    id: root
    spacing: 12

    readonly property int fixedCount: 5
    readonly property var fixedIds: Array.from({
        length: fixedCount
    }, (_, i) => i + 1)

    // Existing workspaces beyond the fixed ones (named/special ones have negative ids)
    readonly property var extraIds: {
        const out = [];
        const list = Hyprland.workspaces.values;
        for (let i = 0; i < list.length; i++) {
            if (list[i].id > root.fixedCount)
                out.push(list[i].id);
        }
        return out;
    }

    Component {
        id: pill

        Rectangle {
            id: cell

            required property int modelData
            readonly property int wsId: modelData

            readonly property var ws: {
                const list = Hyprland.workspaces.values;
                for (let i = 0; i < list.length; i++) {
                    if (list[i].id === wsId)
                        return list[i];
                }
                return null;
            }

            readonly property bool focused: ws !== null && ws.focused
            readonly property bool occupied: ws !== null && ws.toplevels.values.length > 0
            // Urgent is only meaningful on workspaces you are not looking at
            readonly property bool urgent: ws !== null && ws.urgent && !focused

            anchors.verticalCenter: parent.verticalCenter

            implicitHeight: 12
            implicitWidth: focused ? 32 : 12

            radius: height / 2

            color: urgent ? Colors.red : focused ? Colors.mauve : occupied ? Colors.text : Colors.surface2

            Behavior on implicitWidth {
                NumberAnimation {
                    duration: Appearance.normal
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on color {
                ColorAnimation {
                    duration: Appearance.fast
                }
            }

            // Pulse while urgent, like waybar's blinking urgent state
            SequentialAnimation on opacity {
                running: cell.urgent
                loops: Animation.Infinite

                NumberAnimation {
                    to: 0.4
                    duration: 600
                    easing.type: Easing.InOutSine
                }

                NumberAnimation {
                    to: 1
                    duration: 600
                    easing.type: Easing.InOutSine
                }

                onRunningChanged: {
                    // Make sure the pill is fully visible again once urgent clears
                    if (!running)
                        cell.opacity = 1;
                }
            }

            // Becomes true after a short hover delay so quick passes do not flash the tooltip
            property bool tipReady: false

            Timer {
                id: tipTimer

                interval: 300
                running: area.containsMouse
                onTriggered: cell.tipReady = true
            }

            MouseArea {
                id: area

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onContainsMouseChanged: {
                    if (!containsMouse)
                        cell.tipReady = false;
                }

                onClicked: {
                    // Hide the tooltip while the pill animates; it comes back after the mouse re-enters
                    cell.tipReady = false;
                    tipTimer.stop();

                    if (Hyprland.usingLua)
                        Hyprland.dispatch(`hl.dsp.focus({ workspace = "${cell.wsId}" })`);
                    else
                        Hyprland.dispatch(`workspace ${cell.wsId}`);
                }
            }

            PopupWindow {
                id: tooltip

                // Centered below the pill, just under the bar
                anchor.item: cell
                anchor.rect.x: 0
                anchor.rect.y: 0
                anchor.rect.width: cell.focused ? 32 : 12
                anchor.rect.height: cell.height + (Appearance.barHeight - cell.height) / 2 + 4
                anchor.edges: Edges.Bottom
                anchor.gravity: Edges.Bottom

                implicitWidth: tipPanel.width
                implicitHeight: tipPanel.height
                visible: cell.tipReady && area.containsMouse
                color: "transparent"

                Rectangle {
                    id: tipPanel

                    width: tipLabel.implicitWidth + 20
                    height: tipLabel.implicitHeight + 12
                    radius: 8
                    color: Qt.rgba(Colors.base.r, Colors.base.g, Colors.base.b, Appearance.tooltip)
                    border.width: Appearance.borderLine
                    border.color: Colors.surface1

                    Text {
                        id: tipLabel

                        anchors.centerIn: parent
                        text: cell.wsId
                        color: Colors.text
                        font.family: Appearance.fontFamily
                        font.pixelSize: Appearance.fontSmall
                    }
                }
            }
        }
    }

    Repeater {
        model: root.fixedIds
        delegate: pill
    }

    Repeater {
        model: root.extraIds
        delegate: pill
    }
}
