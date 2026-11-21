pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool enabled: false

    function setEnabled(value) {
        root.enabled = value;
        store.setText(value ? "true" : "false");
    }

    function toggle() {
        root.setEnabled(!root.enabled);
    }

    FileView {
        id: store

        path: Quickshell.statePath("dnd")
        printErrors: false
        blockLoading: true
        atomicWrites: true

        onLoaded: root.enabled = text().trim() === "true"
    }

    IpcHandler {
        target: "dnd"

        function toggle(): void {
            root.toggle();
        }

        function enable(): void {
            root.setEnabled(true);
        }

        function disable(): void {
            root.setEnabled(false);
        }
    }
}
