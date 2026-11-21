import Quickshell
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts
import qs.config

PopupWindow {
    id: root

    required property Item anchorItem

    // Passed from BatteryStatus so the popup always matches the bar icon
    property string icon: ""
    property color iconColor: Colors.text

    // Used to ignore the click that dismissed the popup (see BatteryStatus)
    property double closedAt: 0

    readonly property var dev: UPower.displayDevice
    readonly property int level: Math.round(dev.percentage * 100)
    readonly property bool charging: dev.state === UPowerDeviceState.Charging
    readonly property int padding: 8

    readonly property string stateText: {
        const s = dev.state;
        if (s === UPowerDeviceState.Charging)
            return "Charging";
        if (s === UPowerDeviceState.Discharging)
            return "On battery";
        if (s === UPowerDeviceState.FullyCharged)
            return "Fully charged";
        if (s === UPowerDeviceState.PendingCharge)
            return "Plugged in";
        if (s === UPowerDeviceState.Empty)
            return "Empty";
        return "Unknown";
    }

    // Seconds remaining until empty (on battery) or full (charging)
    readonly property real seconds: charging ? dev.timeToFull : dev.timeToEmpty

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

    function formatTime(sec) {
        const totalMinutes = Math.round(sec / 60);
        const h = Math.floor(totalMinutes / 60);
        const m = totalMinutes % 60;
        return h > 0 ? h + "h " + m + "m" : m + "m";
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
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 6
                Layout.rightMargin: 6
                Layout.topMargin: 4
                spacing: 12

                Text {
                    text: root.icon
                    font.family: Appearance.fontFamily
                    font.pixelSize: 26
                    color: root.iconColor
                }

                ColumnLayout {
                    spacing: 0

                    Text {
                        text: root.level + "%"
                        color: Colors.text
                        font.family: Appearance.fontFamily
                        font.pixelSize: 22
                        font.bold: true
                    }

                    Text {
                        text: root.stateText
                        color: Colors.subtext0
                        font.family: Appearance.fontFamily
                        font.pixelSize: Appearance.fontSmall
                    }
                }

                Item {
                    Layout.fillWidth: true
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 6
                Layout.rightMargin: 6
                Layout.preferredHeight: 6
                radius: 3
                color: Colors.surface1

                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, root.dev.percentage))
                    height: parent.height
                    radius: parent.radius
                    color: root.iconColor

                    Behavior on width {
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
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 6
                Layout.rightMargin: 6
                spacing: 0

                InfoRow {
                    visible: root.seconds > 0
                    Layout.fillWidth: true
                    label: root.charging ? "Time to full" : "Time remaining"
                    value: root.formatTime(root.seconds)
                }

                InfoRow {
                    visible: Math.abs(root.dev.changeRate) > 0.05
                    Layout.fillWidth: true
                    label: root.charging ? "Charge rate" : "Power draw"
                    value: Math.abs(root.dev.changeRate).toFixed(1) + " W"
                }

                InfoRow {
                    visible: root.dev.healthSupported
                    Layout.fillWidth: true
                    label: "Battery health"
                    value: {
                        const h = root.dev.healthPercentage;
                        return Math.round(h <= 1 ? h * 100 : h) + "%";
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Colors.surface1
            }

            Text {
                Layout.leftMargin: 6
                text: "Power profile"
                color: Colors.subtext0
                font.family: Appearance.fontFamily
                font.pixelSize: Appearance.fontSmall
                font.bold: true
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 6
                Layout.rightMargin: 6
                Layout.bottomMargin: 4
                spacing: 6

                Repeater {
                    model: [
                        {
                            profile: PowerProfile.PowerSaver,
                            icon: "\uf06c",
                            label: "Saver"
                        },
                        {
                            profile: PowerProfile.Balanced,
                            icon: "\uf24e",
                            label: "Balanced"
                        },
                        {
                            profile: PowerProfile.Performance,
                            icon: "\uf135",
                            label: "Performance"
                        }
                    ]

                    delegate: Rectangle {
                        id: btn

                        required property var modelData

                        readonly property bool selected: PowerProfiles.profile === modelData.profile
                        readonly property bool available: modelData.profile !== PowerProfile.Performance || PowerProfiles.hasPerformanceProfile

                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 50
                        radius: 10
                        opacity: available ? 1 : 0.4
                        color: selected ? Colors.mauve : mouse.containsMouse && available ? Colors.surface1 : Colors.surface0

                        Behavior on color {
                            ColorAnimation {
                                duration: Appearance.fast
                            }
                        }

                        Column {
                            anchors.centerIn: parent
                            spacing: 3

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: btn.modelData.icon
                                font.family: Appearance.fontFamily
                                font.pixelSize: 16
                                color: btn.selected ? Colors.base : Colors.text
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: btn.modelData.label
                                font.family: Appearance.fontFamily
                                font.pixelSize: Appearance.fontSmall
                                color: btn.selected ? Colors.base : Colors.subtext0
                            }
                        }

                        MouseArea {
                            id: mouse
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: btn.available
                            cursorShape: Qt.PointingHandCursor
                            onClicked: PowerProfiles.profile = btn.modelData.profile
                        }
                    }
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
