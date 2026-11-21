import Quickshell
import QtQuick
import qs.config

Item {
    id: root

    property Item anchorItem: root

    implicitWidth: clockText.implicitWidth
    implicitHeight: clockText.implicitHeight

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Text {
        id: clockText
        anchors.centerIn: parent

        text: Qt.formatDateTime(clock.date, "ddd dd/MM  HH:mm")
        color: Colors.text
        font.pixelSize: Appearance.fontNormal
        font.bold: true
        font.family: Appearance.fontFamily

    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: calendar.visible = !calendar.visible
    }

    CalendarPopup {
        id: calendar

        anchorItem: root.anchorItem
        today: clock.date
    }
}
