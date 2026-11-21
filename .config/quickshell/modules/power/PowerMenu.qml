import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import qs.config

PanelWindow {
    id: root

    property var actions: [
        {
            label: "Lock",
            key: Qt.Key_L,
            icon: "\uf023",
            command: ["hyprlock"],
            confirm: false
        },
        {
            label: "Logout",
            key: Qt.Key_O,
            icon: "\uf08b",
            command: ["hyprctl", "dispatch", "hl.dsp.exit()"],
            confirm: true
        },
        {
            label: "Suspend",
            key: Qt.Key_S,
            icon: "\uf186",
            command: ["systemctl", "suspend"],
            confirm: false
        },
        {
            label: "Reboot",
            key: Qt.Key_R,
            icon: "\uf021",
            command: ["systemctl", "reboot"],
            confirm: true
        },
        {
            label: "Shutdown",
            key: Qt.Key_H,
            icon: "\uf011",
            command: ["systemctl", "poweroff"],
            confirm: true
        }
    ]

    property int selectedIndex: 0
    property int armedIndex: -1

    readonly property int padding: 16

    // Full-screen transparent overlay: clicking outside the panel closes the menu
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    visible: false
    exclusionMode: ExclusionMode.Ignore

    BackgroundEffect.blurRegion: Region {
        item: panel
    }

    property real slideOffset: -10
    property bool closing: false

    WlrLayershell.namespace: "qs-power"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    function open() {
        if (root.visible) {
            if (root.closing) {
                closeAnim.stop();
                root.closing = false;
                openAnim.restart();
            }
            return;
        }

        const mon = Hyprland.focusedMonitor;
        const target = mon ? Array.from(Quickshell.screens).find(s => s.name === mon.name) : null;

        root.screen = target ?? Quickshell.screens[0];
        root.visible = true;
    }

    function close() {
        if (!root.visible || root.closing)
            return;

        root.closing = true;
        openAnim.stop();
        closeAnim.restart();
    }

    function toggle() {
        if (root.visible)
            close();
        else
            open();
    }

    function moveSelection(delta) {
        const count = root.actions.length;
        root.selectedIndex = (root.selectedIndex + delta + count) % count;
    }

    function activate(index) {
        const action = root.actions[index];
        if (!action)
            return;

        if (action.confirm && root.armedIndex !== index) {
            root.armedIndex = index;
            disarmTimer.restart();
            return;
        }

        Quickshell.execDetached(action.command);
        root.close();
    }

    onSelectedIndexChanged: armedIndex = -1

    onVisibleChanged: {
        if (visible) {
            root.closing = false;
            root.selectedIndex = 0;
            root.armedIndex = -1;

            panel.opacity = 0;
            root.slideOffset = -10;

            openAnim.restart();
            Qt.callLater(() => panel.forceActiveFocus());
        } else {
            root.closing = false;
        }
    }

    Timer {
        id: disarmTimer
        interval: 3000
        onTriggered: root.armedIndex = -1
    }

    IpcHandler {
        target: "power"

        function toggle(): void {
            root.toggle();
        }

        function open(): void {
            root.open();
        }

        function close(): void {
            root.close();
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Rectangle {
        id: panel

        anchors.horizontalCenter: parent.horizontalCenter
        y: Appearance.barHeight + 14 + root.slideOffset
        width: 520
        height: content.implicitHeight + root.padding * 2
        radius: 16
        color: Qt.rgba(Colors.base.r, Colors.base.g, Colors.base.b, Appearance.popup)
        border.width: Appearance.borderLine
        border.color: Colors.surface1
        transformOrigin: Item.Top
        focus: root.visible

        Keys.onEscapePressed: root.close()
        Keys.onLeftPressed: root.moveSelection(-1)
        Keys.onUpPressed: root.moveSelection(-1)
        Keys.onRightPressed: root.moveSelection(1)
        Keys.onDownPressed: root.moveSelection(1)
        Keys.onReturnPressed: root.activate(root.selectedIndex)
        Keys.onEnterPressed: root.activate(root.selectedIndex)

        Keys.onPressed: event => {
            if (event.modifiers !== Qt.NoModifier)
                return;
            const index = root.actions.findIndex(action => action.key === event.key);
            if (index < 0)
                return;
            root.selectedIndex = index;
            root.activate(index);
            event.accepted = true;
        }

        MouseArea {
            anchors.fill: parent
        }

        RowLayout {
            id: content
            x: root.padding
            y: root.padding
            width: panel.width - root.padding * 2
            spacing: 8

            Repeater {
                model: root.actions

                delegate: Rectangle {
                    id: actionItem

                    required property var modelData
                    required property int index

                    readonly property bool selected: root.selectedIndex === index
                    readonly property bool armed: root.armedIndex === index

                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 108
                    radius: 12
                    color: armed ? Colors.red : selected ? Qt.rgba(Colors.surface0.r, Colors.surface0.g, Colors.surface0.b, 0) : "transparent"
                    border.width: 1
                    border.color: armed ? Colors.red : selected ? Colors.mauve : Colors.surface1

                    Behavior on color {
                        ColorAnimation {
                            duration: Appearance.fast
                        }
                    }

                    Behavior on border.color {
                        ColorAnimation {
                            duration: Appearance.fast
                        }
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: actionItem.modelData.icon
                            font.family: Appearance.fontFamily
                            font.pixelSize: 28
                            color: actionItem.armed ? Colors.base : actionItem.selected ? Colors.mauve : Colors.text
                            scale: actionItem.selected ? 1.1 : 1
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: actionItem.armed ? "Confirm?" : actionItem.modelData.label
                            font.family: Appearance.fontFamily
                            font.pixelSize: Appearance.fontNormal
                            font.bold: actionItem.armed
                            color: actionItem.armed ? Colors.base : Colors.subtext0
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onPositionChanged: root.selectedIndex = actionItem.index
                        onClicked: {
                            root.selectedIndex = actionItem.index;
                            root.activate(actionItem.index);
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
            duration: Appearance.fast
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: root
            property: "slideOffset"
            from: -10
            to: 0
            duration: Appearance.fast
            easing.type: Easing.OutCubic
        }
    }

    ParallelAnimation {
        id: closeAnim

        NumberAnimation {
            target: panel
            property: "opacity"
            from: 1
            to: 0
            duration: Appearance.fast
            easing.type: Easing.InQuad
        }

        NumberAnimation {
            target: root
            property: "slideOffset"
            from: 0
            to: -10
            duration: Appearance.fast
            easing.type: Easing.InQuad
        }

        onFinished: {
            root.visible = false;
        }
    }
}
