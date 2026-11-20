import Quickshell.Services.SystemTray
import QtQuick

Row {
    spacing: 10
    visible: SystemTray.items.values.length > 0

    Repeater {
        model: SystemTray.items
        delegate: TrayItem {}
    }
}
