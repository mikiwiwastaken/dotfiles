import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import qs.config

RowLayout {
    id: root

    // PwNode, may briefly be null (e.g. while the default device changes)
    property var node: null
    property string icon: ""
    property real maxVolume: 1.0

    readonly property var audio: node?.audio ?? null
    readonly property bool muted: audio?.muted ?? false
    readonly property real volume: audio?.volume ?? 0

    spacing: 10

    // Required, otherwise volume/muted are invalid
    PwObjectTracker {
        objects: [root.node]
    }

    Item {
        implicitWidth: 28
        implicitHeight: 28

        Text {
            anchors.centerIn: parent
            text: root.icon
            font.family: Appearance.fontFamily
            font.pixelSize: 18
            color: root.muted ? Colors.surface2 : Colors.text
            scale: muteArea.containsMouse ? 1.1 : 1.0

            Behavior on color {
                ColorAnimation {
                    duration: Appearance.fast
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
            id: muteArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (root.audio)
                    root.audio.muted = !root.audio.muted;
            }
        }
    }

    VolumeSlider {
        Layout.fillWidth: true
        maxValue: root.maxVolume
        value: root.volume
        dimmed: root.muted

        onMoved: v => {
            if (!root.audio)
                return;
            if (root.muted)
                root.audio.muted = false;
            root.audio.volume = v;
        }
    }

    Text {
        Layout.preferredWidth: 36
        horizontalAlignment: Text.AlignRight
        text: Math.round(root.volume * 100) + "%"
        color: root.muted ? Colors.surface2 : root.volume > 1.0001 ? Colors.yellow : Colors.subtext0
        font.family: Appearance.fontFamily
        font.pixelSize: Appearance.fontSmall
    }
}
