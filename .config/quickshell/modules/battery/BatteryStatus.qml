import Quickshell.Services.UPower
import QtQuick
import qs.config
import qs.modules.bar

StatusItem {
    id: root

    readonly property var dev: UPower.displayDevice

    // Docs: percentage = energy / energyCapacity, so it is a 0..1 fraction
    readonly property int level: Math.round(dev.percentage * 100)
    readonly property bool charging: dev.state === UPowerDeviceState.Charging
    readonly property bool low: level <= 15 && !charging

    visible: dev.ready && dev.isLaptopBattery

    icon: {
        const glyph = root.level >= 88 ? "\uf240"
        : root.level >= 63 ? "\uf241"
        : root.level >= 38 ? "\uf242"
        : root.level >= 13 ? "\uf243"
        : "\uf244";
        return root.charging ? "\uf0e7 " + glyph : glyph;
    }

    iconColor: root.charging ? Colors.green : root.low ? Colors.red : Colors.text

    BatteryPopup {
        id: popup
        anchorItem: root.parent.parent
        icon: root.icon
        iconColor: root.iconColor
    }

    onClicked: button => {
        if (button !== Qt.LeftButton)
            return;

        // Ignore the click that dismissed the popup (focus grab), see VolumeStatus
        if (Date.now() - popup.closedAt < 200)
            return;

        popup.open();
    }
}
