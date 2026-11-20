import QtQuick
import QtQuick.Layouts
import qs.config

RowLayout {
    id: root

    property string label: ""
    property string value: ""

    implicitHeight: 24

    Text {
        Layout.fillWidth: true
        text: root.label
        color: Colors.subtext0
        font.family: Appearance.fontFamily
        font.pixelSize: Appearance.fontNormal
    }

    Text {
        text: root.value
        color: Colors.text
        font.family: Appearance.fontFamily
        font.pixelSize: Appearance.fontNormal
        font.bold: true
    }
}
