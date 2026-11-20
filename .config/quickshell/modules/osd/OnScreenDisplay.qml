import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import qs.config

PanelWindow {
    id: root

    // Transparent room above the panel so the slide-down is not clipped
    readonly property int headroom: 12

    property string mode: "volume"    // volume | microphone | brightness
    property real value: 0            // volume: 0..1.5, others: 0..1
    property bool muted: false

    property bool ready: false

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    readonly property real maxValue: mode === "volume" ? 1.5 : 1.0
    readonly property bool boosted: mode === "volume" && !muted && value > 1.0001
    readonly property color accent: muted ? Colors.red : boosted ? Colors.yellow : Colors.mauve

    readonly property string icon: {
        if (mode === "microphone")
            return muted ? "\uf131" : "\uf130";
        if (mode === "brightness")
            return "\uf185";
        if (muted || value === 0)
            return "\uf026";
        return value < 0.5 ? "\uf027" : "\uf028";
    }

    readonly property string title: mode === "volume" ? "Volume" : mode === "microphone" ? "Microphone" : "Brightness"

    readonly property string valueText: {
        if (mode === "microphone")
            return muted ? "Muted" : "On";
        if (muted)
            return "Muted";
        return Math.round(value * 100) + "%";
    }

    // Top center, just below the bar. Ignoring other surfaces' exclusive zones keeps the
    // margin relative to the screen edge
    anchors {
        bottom: true
        left: true
        right: true
    }
    margins.bottom: 60
    implicitHeight: panel.height + root.headroom
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: true

    mask: Region {}

    WlrLayershell.namespace: "qs-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    function show(newMode, newValue, newMuted) {
        root.mode = newMode;
        root.value = newValue;
        root.muted = newMuted;

        const mon = Hyprland.focusedMonitor;
        const target = mon ? Array.from(Quickshell.screens).find(s => s.name === mon.name) : null;
        root.screen = target ?? Quickshell.screens[0];

        hideTimer.restart();

        if (hideAnim.running) {
            hideAnim.stop();
            showAnim.restart();
            return;
        }

        if (showAnim.running)
            return;

        if (panel.opacity < 1) {
            panel.opacity = 0;
            panel.scale = 0.94;
            showAnim.restart();
        }
    }

    Timer {
        id: hideTimer
        interval: 1500
        onTriggered: hideAnim.restart()
    }

    ParallelAnimation {
        id: showAnim

        NumberAnimation {
            target: panel
            property: "opacity"
            from: 0
            to: 1
            duration: Appearance.fast
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: panel
            property: "scale"
            from: 0.94
            to: 1.0
            duration: Appearance.fast
            easing.type: Easing.OutCubic
        }
    }

    ParallelAnimation {
        id: hideAnim

        NumberAnimation {
            target: panel
            property: "opacity"
            to: 0
            duration: Appearance.fast
            easing.type: Easing.InCubic
        }

        NumberAnimation {
            target: panel
            property: "scale"
            to: 0.96
            duration: Appearance.fast
            easing.type: Easing.InCubic
        }
    }

    // Required, otherwise volume/muted are invalid
    PwObjectTracker {
        objects: [root.sink, root.source]
    }

    // Do not show the OSD for the initial values after startup
    Timer {
        running: true
        interval: 2000
        onTriggered: root.ready = true
    }

    function notifySink() {
        const audio = root.sink?.audio;
        if (!root.ready || !audio)
            return;
        root.show("volume", audio.volume, audio.muted);
    }

    function notifySource() {
        const audio = root.source?.audio;
        if (!root.ready || !audio)
            return;
        root.show("microphone", audio.volume, audio.muted);
    }

    Connections {
        target: root.sink?.audio ?? null

        function onVolumeChanged() {
            root.notifySink();
        }

        function onMutedChanged() {
            root.notifySink();
        }
    }

    // Only mute changes: apps with automatic gain control change the level all the time
    Connections {
        target: root.source?.audio ?? null

        function onMutedChanged() {
            root.notifySource();
        }
    }

    function changeVolume(delta) {
        const audio = root.sink?.audio;
        if (!audio)
            return;

        const v = Math.max(0, Math.min(1.5, Math.round((audio.volume + delta) * 100) / 100));
        audio.muted = false;
        audio.volume = v;
        root.show("volume", v, false);
    }

    function toggleMute(node, newMode) {
        const audio = node?.audio;
        if (!audio)
            return;

        const muted = !audio.muted;
        audio.muted = muted;
        root.show(newMode, audio.volume, muted);
    }

    Process {
        id: brightnessProc

        stdout: StdioCollector {
            onStreamFinished: root.showBrightness(text)
        }
    }

    function runBrightness(args) {
        if (brightnessProc.running)
            return;
        brightnessProc.command = ["brightnessctl", "-m", ...args];
        brightnessProc.running = true;
    }

    function showBrightness(output) {
        // brightnessctl -m prints: device,class,current,percent,max
        const parts = output.trim().split("\n")[0].split(",");
        if (parts.length < 5)
            return;

        const percent = parseInt(parts[3]);
        if (!isNaN(percent))
            root.show("brightness", percent / 100, false);
    }

    IpcHandler {
        target: "osd"

        function volumeUp(): void {
            root.changeVolume(0.05);
        }

        function volumeDown(): void {
            root.changeVolume(-0.05);
        }

        function volumeMute(): void {
            root.toggleMute(root.sink, "volume");
        }

        function micMute(): void {
            root.toggleMute(root.source, "microphone");
        }

        function brightnessUp(): void {
            root.runBrightness(["set", "5%+"]);
        }

        function brightnessDown(): void {
            root.runBrightness(["set", "5%-"]);
        }

        function brightness(): void {
            root.runBrightness([]);
        }
    }

    Rectangle {
        id: panel

        anchors.horizontalCenter: parent.horizontalCenter
        y: root.headroom

        width: 280
        height: 48
        radius: height / 2

        opacity: 0
        color: Qt.rgba(Colors.base.r, Colors.base.g, Colors.base.b, Appearance.popup)
        border.width: Appearance.borderLine
        border.color: Colors.surface1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 12

            Text {
                Layout.preferredWidth: 26
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                text: root.icon
                color: root.accent
                font.family: Appearance.fontFamily
                font.pixelSize: 21

                Behavior on color {
                    ColorAnimation {
                        duration: Appearance.fast
                    }
                }
            }

            Rectangle {
                id: track

                Layout.fillWidth: true
                Layout.preferredHeight: 6
                Layout.alignment: Qt.AlignVCenter

                radius: 3
                color: Colors.surface1

                Rectangle {
                    width: root.mode === "microphone" ? (root.muted ? 0 : track.width) : (root.muted ? 0 : track.width * Math.max(0, Math.min(1, root.value / root.maxValue)))

                    height: parent.height
                    radius: parent.radius
                    color: root.accent

                    Behavior on width {
                        NumberAnimation {
                            duration: Appearance.fast
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: Appearance.fast
                        }
                    }
                }

                // 100% marker for volume boost
                Rectangle {
                    visible: root.mode === "volume"
                    anchors.verticalCenter: parent.verticalCenter
                    x: track.width / root.maxValue - width / 2
                    width: 2
                    height: 10
                    radius: 1
                    color: Colors.surface2
                }
            }

            Text {
                Layout.preferredWidth: 42
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter

                text: root.mode === "microphone" ? (root.muted ? "Muted" : "On") : Math.round(root.value * 100) + "%"

                color: root.muted ? Colors.red : Colors.text
                font.family: Appearance.fontFamily
                font.pixelSize: Appearance.fontSmall
                font.bold: true
            }
        }
    }
}
