import Quickshell
import Quickshell.Networking
import QtQuick
import QtQuick.Layouts
import qs.config

PopupWindow {
    id: root

    required property Item anchorItem

    // The network whose password field is shown (only one at a time)
    property var promptNetwork: null

    readonly property int padding: 8

    readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null

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

    onVisibleChanged: {
        if (root.wifi)
            root.wifi.scannerEnabled = visible;

        if (visible) {
            panel.opacity = 0;
            panel.y = -10;
            openAnim.restart();
        } else {
            root.promptNetwork = null;
        }
    }

    // Stable ordering: connected, known, then signal (in 4 steps to avoid jitter), then name
    ScriptModel {
        id: networks

        values: root.wifi ? [...root.wifi.networks.values].filter(n => n.name !== "").sort((a, b) => {
            if (a.connected !== b.connected)
                return a.connected ? -1 : 1;
            if (a.known !== b.known)
                return a.known ? -1 : 1;
            const sa = Math.round(a.signalStrength * 4);
            const sb = Math.round(b.signalStrength * 4);
            if (sa !== sb)
                return sb - sa;
            return a.name.localeCompare(b.name);
        }) : []
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

        // Keep clicks inside the popup from reaching the window behind it.
        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            id: content
            x: root.padding
            y: root.padding
            width: panel.width - root.padding * 2
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                Layout.leftMargin: 6
                Layout.rightMargin: 6
                spacing: 10

                Text {
                    text: "\uf1eb"
                    font.family: Appearance.fontFamily
                    font.pixelSize: 16
                    color: Networking.wifiEnabled ? Colors.mauve : Colors.surface2
                }

                Text {
                    Layout.fillWidth: true
                    text: "Wi-Fi"
                    color: Colors.text
                    font.family: Appearance.fontFamily
                    font.pixelSize: 14
                    font.bold: true
                }

                Item {
                    id: wifiSwitch

                    readonly property bool checked: Networking.wifiEnabled
                    signal toggled

                    implicitWidth: 36
                    implicitHeight: 20

                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color: wifiSwitch.checked ? Colors.mauve : Colors.surface1

                        Behavior on color {
                            ColorAnimation {
                                duration: Appearance.fast
                            }
                        }

                        Rectangle {
                            width: 16
                            height: 16
                            anchors {
                                verticalCenter: parent.verticalCenter
                                left: wifiSwitch.checked ? undefined : parent.left
                                right: wifiSwitch.checked ? parent.right : undefined
                                leftMargin: 2
                                rightMargin: 2
                            }
                            radius: 8
                            color: wifiSwitch.checked ? Colors.base : Colors.surface2

                            Behavior on anchors.leftMargin {
                                NumberAnimation {
                                    duration: Appearance.normal
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Networking.wifiEnabled = !wifiSwitch.checked;
                            wifiSwitch.toggled();
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Colors.surface1
            }

            ListView {
                id: list

                visible: Networking.wifiEnabled && root.wifi !== null && count > 0
                Layout.fillWidth: true
                Layout.preferredHeight: visible ? Math.min(contentHeight, 320) : 0

                model: networks
                clip: true
                spacing: 2
                boundsBehavior: Flickable.StopAtBounds
                interactive: contentHeight > height

                delegate: WifiRow {
                    required property var modelData

                    width: ListView.view.width
                    network: modelData
                    promptTarget: root.promptNetwork

                    onPromptRequested: root.promptNetwork = modelData
                    onPromptCleared: {
                        if (root.promptNetwork === modelData)
                            root.promptNetwork = null;
                    }
                }
            }

            Text {
                visible: !list.visible
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: Colors.surface2
                font.family: Appearance.fontFamily
                font.pixelSize: 13
                text: {
                    if (!root.wifi)
                        return "No Wi-Fi adapter";
                    if (!Networking.wifiHardwareEnabled)
                        return "Wi-Fi is disabled by a hardware switch";
                    if (!Networking.wifiEnabled)
                        return "Wi-Fi is off";
                    return "Searching for networks...";
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
