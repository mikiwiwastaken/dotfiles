import Quickshell
import Quickshell.Networking
import QtQuick
import qs.config
import qs.modules.bar

StatusItem {
    id: root

    readonly property var wifiDev: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wiredDev: Networking.devices.values.find(d => d.type === DeviceType.Wired) ?? null
    readonly property var activeWifi: wifiDev ? (wifiDev.networks.values.find(n => n.connected) ?? null) : null
    readonly property bool onWired: wiredDev !== null && wiredDev.connected

    icon: root.onWired ? "\uf0e8" : "\uf1eb"

    iconColor: {
        if (root.onWired)
            return Colors.text;
        if (!root.activeWifi)
            return Colors.surface2;
        const s = root.activeWifi.signalStrength;
        return s > 0.5 ? Colors.text : s > 0.25 ? Colors.yellow : Colors.red;
    }

    NetworkPopup {
        id: popup
        anchorItem: root.parent.parent
    }

    onClicked: button => {
        if (button === Qt.LeftButton) {
            // Ignore the click that dismissed the popup (focus grab)
            if (Date.now() - popup.closedAt < 200)
                return;
            popup.open();
        }
    }
}
