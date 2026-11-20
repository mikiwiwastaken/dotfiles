import QtQuick
import qs.config

Item {
    id: root

    property real value: 0
    property real maxValue: 1.0
    property bool dimmed: false

    // Value shown while dragging, so the slider does not fight the async pipewire update
    property real dragValue: 0
    readonly property real shown: Math.max(0, Math.min(maxValue, area.pressed ? dragValue : value))

    signal moved(real value)

    implicitHeight: 22

    function clamp(v) {
        return Math.max(0, Math.min(root.maxValue, v));
    }

    function setFromX(x) {
        const usable = root.width - handle.width;
        let v = clamp(((x - handle.width / 2) / usable) * root.maxValue);

        // Snap to 100% when close
        if (root.maxValue > 1 && Math.abs(v - 1.0) < 0.025)
            v = 1.0;

        dragValue = v;
        moved(v);
    }

    Rectangle {
        id: track
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
        }
        height: 6
        radius: 3
        color: Colors.surface1

        Rectangle {
            width: handle.x + handle.width / 2
            height: parent.height
            radius: parent.radius
            color: root.dimmed ? Colors.surface2 : root.shown > 1.0001 ? Colors.yellow : Colors.mauve

            Behavior on color {
                ColorAnimation {
                    duration: Appearance.fast
                }
            }
        }
    }

    Rectangle {
        visible: root.maxValue > 1
        anchors.verticalCenter: parent.verticalCenter
        width: 2
        height: 12
        radius: 1
        color: Colors.surface2
        x: (1.0 / root.maxValue) * (root.width - handle.width) + handle.width / 2 - width / 2
    }

    Rectangle {
        id: handle
        width: 14
        height: 14
        radius: 7
        anchors.verticalCenter: parent.verticalCenter
        x: (root.shown / root.maxValue) * (root.width - width)
        color: Colors.text
        scale: area.pressed ? 1.2 : area.containsMouse ? 1.1 : 1.0

        Behavior on x {
            enabled: !area.pressed
            NumberAnimation {
                duration: Appearance.fast
                easing.type: Easing.OutCubic
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: Appearance.fast
                easing.type: Easing.OutCubic
            }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onPressed: mouse => root.setFromX(mouse.x)
        onPositionChanged: mouse => {
            if (pressed)
                root.setFromX(mouse.x);
        }
        onWheel: wheel => {
            const step = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
            root.moved(root.clamp(root.shown + step));
        }
    }
}
