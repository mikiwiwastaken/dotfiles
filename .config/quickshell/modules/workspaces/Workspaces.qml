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

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onClicked: {
                    if (Hyprland.usingLua)
                        Hyprland.dispatch(`hl.dsp.focus({ workspace = "${cell.wsId}" })`);
                    else
                        Hyprland.dispatch(`workspace ${cell.wsId}`);
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
