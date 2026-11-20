import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import qs.config

RowLayout {
    id: root

    // PwNode of the application stream (may be null while streams change)
    property var node: null

    readonly property var audio: node?.audio ?? null
    readonly property bool muted: audio?.muted ?? false
    readonly property real volume: audio?.volume ?? 0

    readonly property string appName: {
        const props = root.node ? root.node.properties : null;
        if (props && props["application.name"])
            return props["application.name"];
        return root.node ? (root.node.description || root.node.name) : "";
    }

    readonly property string iconName: {
        const props = root.node ? root.node.properties : null;
        return props && props["application.icon-name"] ? props["application.icon-name"] : "";
    }

    spacing: 10

    // Required, otherwise volume/muted/properties are invalid
    PwObjectTracker {
        objects: [root.node]
    }

    Item {
        implicitWidth: 28
        implicitHeight: 28
        Layout.alignment: Qt.AlignVCenter

        Image {
            id: appIcon
            anchors.centerIn: parent
            width: 22
            height: 22
            sourceSize.width: 22
            sourceSize.height: 22
            fillMode: Image.PreserveAspectFit
            source: root.iconName !== "" ? "image://icon/" + root.iconName : ""
            visible: status === Image.Ready
            opacity: root.muted ? 0.35 : 1.0

            Behavior on opacity {
                NumberAnimation {
                    duration: Appearance.fast
                }
            }
        }

        Text {
            visible: !appIcon.visible
            anchors.centerIn: parent
            text: "\uf001"
            font.family: Appearance.fontFamily
            font.pixelSize: 16
            color: root.muted ? Colors.surface2 : Colors.text
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (root.audio)
                    root.audio.muted = !root.audio.muted;
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        RowLayout {
            Layout.fillWidth: true

            Text {
                Layout.fillWidth: true
                text: root.appName
                elide: Text.ElideRight
                color: root.muted ? Colors.surface2 : Colors.text
                font.family: Appearance.fontFamily
                font.pixelSize: Appearance.fontNormal
            }

            Text {
                text: Math.round(root.volume * 100) + "%"
                color: root.muted ? Colors.surface2 : root.volume > 1.0001 ? Colors.yellow : Colors.subtext0
                font.family: Appearance.fontFamily
                font.pixelSize: Appearance.fontSmall
            }
        }

        VolumeSlider {
            Layout.fillWidth: true
            maxValue: 1.5
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
    }
}
