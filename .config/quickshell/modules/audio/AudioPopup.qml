import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import qs.config

PopupWindow {
    id: root

    required property Item anchorItem

    // Used to ignore the click that dismissed the popup (see VolumeStatus)
    property double closedAt: 0

    readonly property int padding: 8

    anchor.item: root.anchorItem
    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Left
    anchor.margins.bottom: -9

    implicitWidth: panel.width
    implicitHeight: panel.height
    grabFocus: true
    visible: false
    color: "transparent"

    function open() {
        root.visible = true;
    }

    function selectSink(node) {
        if (node)
            Pipewire.preferredDefaultAudioSink = node;
    }

    function selectSource(node) {
        if (node)
            Pipewire.preferredDefaultAudioSource = node;
    }

    onVisibleChanged: {
        if (visible) {
            panel.opacity = 0;
            panel.y = -10;
            openAnim.restart();
        } else {
            closedAt = Date.now();
        }
    }

    // Hardware devices only (isStream = application streams)
    ScriptModel {
        id: sinks
        values: Pipewire.nodes.values.filter(n => n.audio && !n.isStream && n.isSink)
    }

    ScriptModel {
        id: sources
        values: Pipewire.nodes.values.filter(n => n.audio && !n.isStream && !n.isSink)
    }

    // Applications currently playing into the default output
    PwNodeLinkTracker {
        id: appTracker
        node: Pipewire.defaultAudioSink
    }

    Rectangle {
        id: panel

        width: 300
        height: content.implicitHeight + root.padding * 2

        radius: 14
        color: Qt.rgba(Colors.base.r, Colors.base.g, Colors.base.b, Appearance.popup)
        border.width: Appearance.borderLine
        border.color: Colors.surface1
        transformOrigin: Item.TopRight
        focus: root.visible

        Keys.onEscapePressed: root.visible = false

        // Keep clicks inside the popup from reaching the window behind it
        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            id: content
            x: root.padding
            y: root.padding
            width: panel.width - root.padding * 2
            spacing: 4

            Text {
                Layout.leftMargin: 6
                Layout.topMargin: 4
                text: "Output"
                color: Colors.subtext0
                font.family: Appearance.fontFamily
                font.pixelSize: Appearance.fontSmall
                font.bold: true
            }

            AudioControl {
                id: output
                Layout.fillWidth: true
                Layout.leftMargin: 6
                Layout.rightMargin: 6

                node: Pipewire.defaultAudioSink
                maxVolume: 1.5
                icon: output.muted || output.volume === 0 ? "\uf026" : output.volume < 0.5 ? "\uf027" : "\uf028"
            }

            DeviceList {
                visible: sinks.values.length > 1
                Layout.fillWidth: true
                model: sinks
                current: Pipewire.preferredDefaultAudioSink ?? Pipewire.defaultAudioSink
                onSelected: node => {
                    root.selectSink(node);
                }
            }

            Rectangle {
                visible: appList.count > 0
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Colors.surface1
            }

            Text {
                visible: appList.count > 0
                Layout.leftMargin: 6
                text: "Applications"
                color: Colors.subtext0
                font.family: Appearance.fontFamily
                font.pixelSize: Appearance.fontSmall
                font.bold: true
            }

            ListView {
                id: appList

                visible: count > 0
                Layout.fillWidth: true
                Layout.leftMargin: 6
                Layout.rightMargin: 6
                Layout.preferredHeight: visible ? Math.min(contentHeight, 232) : 0

                model: appTracker.linkGroups
                clip: true
                spacing: 8
                boundsBehavior: Flickable.StopAtBounds
                interactive: contentHeight > height

                delegate: AppMixerEntry {
                    required property var modelData

                    width: ListView.view.width
                    // Each link group goes from an application (source) to the default sink
                    node: modelData.source
                }
            }

            Rectangle {
                visible: Pipewire.defaultAudioSource !== null
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Colors.surface1
            }

            Text {
                visible: Pipewire.defaultAudioSource !== null
                Layout.leftMargin: 6
                text: "Input"
                color: Colors.subtext0
                font.family: Appearance.fontFamily
                font.pixelSize: Appearance.fontSmall
                font.bold: true
            }

            AudioControl {
                id: input
                visible: Pipewire.defaultAudioSource !== null
                Layout.fillWidth: true
                Layout.leftMargin: 6
                Layout.rightMargin: 6

                node: Pipewire.defaultAudioSource
                icon: input.muted ? "\uf131" : "\uf130"
            }

            DeviceList {
                visible: Pipewire.defaultAudioSource !== null && sources.values.length > 1
                Layout.fillWidth: true
                model: sources
                current: Pipewire.preferredDefaultAudioSource ?? Pipewire.defaultAudioSource
                onSelected: node => {
                    root.selectSource(node);
                }
            }
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
