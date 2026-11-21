import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import qs.config

PanelWindow {
    id: root

    // Terminal used for apps and commands that need one
    property var terminalCommand: ["kitty", "-e"]

    property string query: ""
    property string initialQuery: ""
    property string mode: "apps"
    readonly property bool clipboardMode: root.mode === "clipboard"
    property var clipEntries: []

    readonly property int maxRows: 6
    readonly property int rowHeight: 44
    readonly property int rowSpacing: 2
    readonly property int padding: 8
    readonly property int searchHeight: 42
    readonly property int maxPanelHeight: padding * 2 + searchHeight + 8 + maxRows * (rowHeight + rowSpacing)

    // Full-screen transparent overlay: clicking outside the panel closes the launcher
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
    readonly property real panelTop: Math.round(root.height * 0.18)

    WlrLayershell.namespace: "qs-launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Calculator {
        id: calc
    }

    FileView {
        id: usageFile

        path: Quickshell.statePath("launcher-usage.json")
        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            id: usageData
            property var counts: ({})
        }
    }

    Process {
        id: clipProc

        command: ["cliphist", "list"]

        stdout: StdioCollector {
            onStreamFinished: {
                const entries = [];
                for (const line of text.split("\n")) {
                    const tab = line.indexOf("\t");
                    if (tab < 0)
                        continue;

                    const preview = line.slice(tab + 1).trim();
                    const isImage = preview.startsWith("[[ binary data");
                    entries.push({
                        kind: "clip",
                        id: line.slice(0, tab),
                        line: line,
                        name: preview.slice(0, 200),
                        subtitle: isImage ? "Image" : "",
                        glyph: isImage ? "\uf03e" : "\uf0ea"
                    });
                }
                root.clipEntries = entries;
            }
        }
    }

    // All launchable applications, built once and kept stable so the list does not rebuild while typing
    readonly property var appItems: DesktopEntries.applications.values.filter(e => !e.noDisplay).map(e => ({
                kind: "app",
                id: e.id,
                name: e.name,
                subtitle: e.genericName || e.comment,
                icon: e.icon,
                glyph: "\uf2d0",
                entry: e
            })).sort((a, b) => (root.usageCount(b.id) - root.usageCount(a.id)) || a.name.localeCompare(b.name))

    function usageCount(id) {
        return usageData.counts[id] ?? 0;
    }

    function recordAppLaunch(entry) {
        const id = entry?.id;
        if (!id)
            return;

        const counts = Object.assign({}, usageData.counts);
        counts[id] = (counts[id] ?? 0) + 1;
        usageData.counts = counts;
    }

    function open(initial, mode) {
        root.mode = mode ?? "apps";
        root.initialQuery = initial ?? "";

        if (root.clipboardMode)
            root.refreshClipboard();

        if (root.visible) {
            if (root.closing) {
                closeAnim.stop();
                root.closing = false;
                openAnim.restart();
            }

            input.text = root.initialQuery;
            return;
        }

        const mon = Hyprland.focusedMonitor;
        const target = mon ? Array.from(Quickshell.screens).find(s => s.name === mon.name) : null;
        root.screen = target ?? Quickshell.screens[0];
        root.visible = true;
    }

    function toggleClipboard() {
        if (root.visible && root.clipboardMode && !root.closing)
            close();
        else
            open("", "clipboard");
    }

    function refreshClipboard() {
        if (!clipProc.running)
            clipProc.running = true;
    }

    function deleteClip(item) {
        if (!item || item.kind !== "clip")
            return;

        Quickshell.execDetached(["sh", "-c", "printf '%s\\n' \"$1\" | cliphist delete", "sh", item.line]);
        root.clipEntries = root.clipEntries.filter(e => e.id !== item.id);
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
            open("");
    }

    function launch(entry) {
        if (!entry)
            return;

        root.recordAppLaunch(entry);

        if (entry.runInTerminal)
            Quickshell.execDetached([...root.terminalCommand, ...Array.from(entry.command)]);
        else
            entry.execute();

        root.close();
    }

    function activate(item, inTerminal) {
        if (!item)
            return;

        if (item.kind === "app") {
            launch(item.entry);
            return;
        }

        if (item.kind === "clip") {
            Quickshell.execDetached(["sh", "-c", "cliphist decode \"$1\" | wl-copy", "sh", item.id]);
        } else if (item.kind === "calc") {
            Quickshell.execDetached(["wl-copy", item.payload]);
        } else if (item.kind === "cmd") {
            if (item.payload === "")
                return;
            if (inTerminal)
                Quickshell.execDetached([...root.terminalCommand, "sh", "-c", item.payload + "; exec \"$SHELL\""]);
            else
                Quickshell.execDetached(["sh", "-c", item.payload]);
        }

        root.close();
    }

    function isSubsequence(q, s) {
        let i = 0;
        for (const c of s) {
            if (c === q[i] && ++i === q.length)
                return true;
        }
        return false;
    }

    function matchScore(item, q) {
        const name = (item.name ?? "").toLowerCase();
        let best = 0;

        if (name === q)
            best = 100;
        else if (name.startsWith(q))
            best = 90;
        else if (name.split(/[\s\-_.]+/).some(w => w.startsWith(q)))
            best = 75;
        else if (name.includes(q))
            best = 60;
        else if (isSubsequence(q, name))
            best = 40;

        if (best < 40) {
            const generic = (item.entry.genericName ?? "").toLowerCase();
            const comment = (item.entry.comment ?? "").toLowerCase();
            const keywords = Array.from(item.entry.keywords ?? []).join(" ").toLowerCase();

            if (generic.includes(q) || keywords.includes(q))
                best = Math.max(best, 30);
            else if (comment.includes(q))
                best = Math.max(best, 15);
        }
        return best;
    }

    onVisibleChanged: {
        if (visible) {
            root.closing = false;
            input.text = root.initialQuery;
            list.currentIndex = 0;

            panel.opacity = 0;
            root.slideOffset = -10;

            openAnim.restart();
            Qt.callLater(() => input.forceActiveFocus());
        } else {
            root.closing = false;
        }
    }

    // Control from the compositor: qs ipc call launcher toggle|open|close
    IpcHandler {
        target: "launcher"

        function toggle(): void {
            root.toggle();
        }

        function open(): void {
            root.open("");
        }

        function close(): void {
            root.close();
        }

        function clipboard(): void {
            root.toggleClipboard();
        }
    }

    ScriptModel {
        id: results

        values: {
            const raw = root.query;

            if (root.clipboardMode) {
                const cq = raw.trim().toLowerCase();
                if (cq === "")
                    return root.clipEntries;
                return root.clipEntries.filter(e => e.name.toLowerCase().includes(cq));
            }

            if (raw.startsWith(">")) {
                const cmd = raw.slice(1).trim();
                return [
                    {
                        kind: "cmd",
                        name: cmd !== "" ? cmd : "Run a command",
                        subtitle: cmd !== "" ? "Enter to run, Shift+Enter in a terminal" : "Type a command after >",
                        glyph: "\uf120",
                        payload: cmd
                    }
                ];
            }

            const q = raw.trim().toLowerCase();
            if (q === "")
                return root.appItems;

            const out = [];

            const value = calc.evaluate(q);
            if (value !== null) {
                const text = calc.format(value);
                out.push({
                    kind: "calc",
                    name: "= " + text,
                    subtitle: raw.trim() + "  -  Enter to copy",
                    glyph: "\uf1ec",
                    payload: text
                });
            }

            const apps = root.appItems.map(item => ({
                        item: item,
                        score: root.matchScore(item, q),
                        usageBoost: Math.min(24, Math.log2(root.usageCount(item.id) + 1) * 4)
                    })).filter(r => r.score > 0).sort((a, b) => ((b.score + b.usageBoost) - (a.score + a.usageBoost)) || a.item.name.localeCompare(b.item.name)).map(r => r.item);

            return out.concat(apps);
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Rectangle {
        id: panel

        anchors.horizontalCenter: parent.horizontalCenter
        y: root.panelTop + root.slideOffset
        width: 460
        height: content.implicitHeight + root.padding * 2

        radius: 16
        color: Qt.rgba(Colors.base.r, Colors.base.g, Colors.base.b, Appearance.popup)
        border.width: Appearance.borderLine
        border.color: Colors.surface1

        // Keep clicks inside the panel from closing the launcher
        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            id: content
            x: root.padding
            y: root.padding
            width: panel.width - root.padding * 2
            spacing: 8

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: root.searchHeight
                radius: 11
                color: "transparent"
                border.width: 1
                border.color: input.activeFocus ? Colors.mauve : Colors.surface1

                Behavior on border.color {
                    ColorAnimation {
                        duration: Appearance.fast
                    }
                }

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: 12
                        rightMargin: 12
                    }
                    spacing: 10

                    Text {
                        text: root.clipboardMode ? "\uf0ea" : root.query.startsWith(">") ? "\uf120" : "\uf002"
                        font.family: Appearance.fontFamily
                        font.pixelSize: 15
                        color: input.text !== "" ? Colors.mauve : Colors.surface2

                        Behavior on color {
                            ColorAnimation {
                                duration: Appearance.fast
                            }
                        }
                    }

                    TextInput {
                        id: input

                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        color: Colors.text
                        font.family: Appearance.fontFamily
                        font.pixelSize: 14
                        clip: true
                        selectByMouse: true

                        onTextChanged: {
                            root.query = text;
                            list.currentIndex = 0;
                        }

                        onAccepted: {
                            root.activate(results.values[list.currentIndex], false);
                        }

                        Keys.onEscapePressed: root.close()

                        Keys.onUpPressed: list.decrementCurrentIndex()

                        Keys.onDownPressed: list.incrementCurrentIndex()

                        Keys.onLeftPressed: event => event.accepted = false

                        Keys.onRightPressed: event => event.accepted = false

                        Keys.onTabPressed: list.incrementCurrentIndex()

                        Keys.onPressed: event => {
                            // Shift+Enter: run the command in a terminal
                            if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && (event.modifiers & Qt.ShiftModifier)) {
                                root.activate(results.values[list.currentIndex], true);
                                event.accepted = true;
                                return;
                            }

                            if (!(event.modifiers & Qt.ControlModifier))
                                return;

                            if (event.key === Qt.Key_D && root.clipboardMode) {
                                root.deleteClip(results.values[list.currentIndex]);
                                event.accepted = true;
                                return;
                            }

                            const next = event.key === Qt.Key_J || event.key === Qt.Key_N;
                            const prev = event.key === Qt.Key_K || event.key === Qt.Key_P;
                            if (!next && !prev)
                                return;

                            if (next)
                                list.incrementCurrentIndex();
                            else
                                list.decrementCurrentIndex();
                            event.accepted = true;
                        }

                        Text {
                            visible: input.text === ""
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.clipboardMode ? "Search clipboard" : "Search apps"
                            color: Colors.surface2
                            font: input.font
                        }
                    }
                }
            }

            ListView {
                id: list

                Layout.fillWidth: true
                Layout.preferredHeight: Math.max(0, Math.min(results.values.length, root.maxRows) * (root.rowHeight + root.rowSpacing) - root.rowSpacing)

                Behavior on Layout.preferredHeight {
                    NumberAnimation {
                        duration: Appearance.fast
                        easing.type: Easing.OutCubic
                    }
                }

                model: results
                clip: true
                spacing: root.rowSpacing
                boundsBehavior: Flickable.StopAtBounds
                interactive: contentHeight > height

                currentIndex: 0
                highlightFollowsCurrentItem: true
                highlightMoveDuration: Appearance.fast
                highlightMoveVelocity: -1
                highlightResizeDuration: 0

                onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
                onCountChanged: {
                    if (count > 0 && currentIndex < 0)
                        currentIndex = 0;
                }

                delegate: Item {
                    id: row

                    required property var modelData
                    required property int index

                    readonly property bool isApp: modelData.kind === "app"
                    readonly property bool isCompact: modelData.kind === "app" || modelData.kind === "clip"

                    width: ListView.view.width
                    height: root.rowHeight

                    RowLayout {
                        anchors {
                            fill: parent
                            leftMargin: 10
                            rightMargin: 10
                        }
                        spacing: 12

                        Item {
                            implicitWidth: 28
                            implicitHeight: 28

                            Image {
                                id: appIcon
                                anchors.fill: parent
                                sourceSize.width: 28
                                sourceSize.height: 28
                                fillMode: Image.PreserveAspectFit
                                source: row.isApp && row.modelData.icon !== "" ? "image://icon/" + row.modelData.icon : ""
                                visible: status === Image.Ready
                            }

                            Text {
                                visible: !appIcon.visible
                                anchors.centerIn: parent
                                text: row.modelData.glyph
                                font.family: Appearance.fontFamily
                                font.pixelSize: row.isApp ? 18 : 20
                                color: row.isApp ? Colors.surface2 : Colors.mauve
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 0

                            Text {
                                Layout.fillWidth: true
                                text: row.modelData.name
                                elide: Text.ElideRight
                                color: row.ListView.isCurrentItem ? Colors.mauve : Colors.text
                                font.family: Appearance.fontFamily
                                font.pixelSize: row.isCompact ? 13 : 15
                                font.bold: true

                                Behavior on color {
                                    ColorAnimation {
                                        duration: Appearance.fast
                                    }
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                visible: text !== ""
                                text: row.modelData.subtitle
                                elide: Text.ElideRight
                                color: Colors.subtext0
                                font.family: Appearance.fontFamily
                                font.pixelSize: Appearance.fontSmall
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        // Only real mouse movement changes the selection (not scrolling or typing)
                        onPositionChanged: list.currentIndex = row.index
                        onClicked: root.activate(row.modelData, false)
                    }
                }
            }

            Text {
                visible: results.values.length === 0
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: root.clipboardMode && root.query === "" ? "Clipboard is empty" : "No results"
                color: Colors.surface2
                font.family: Appearance.fontFamily
                font.pixelSize: Appearance.fontNormal
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
