import QtQuick
import qs.config

Item {
    id: root

    property string icon: ""
    property string label: ""
    property color iconColor: Colors.text

    signal clicked(int button)
    signal scrolled(int delta)

    implicitWidth: row.implicitWidth
    implicitHeight: Appearance.barItemHeight

    Behavior on scale {
        NumberAnimation {
            duration: Appearance.fast
            easing.type: Easing.OutCubic
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.icon
            color: root.iconColor
            font.family: Appearance.fontFamily
            font.pixelSize: Appearance.fontNormal

            Behavior on color {
                ColorAnimation {
                    duration: Appearance.fast
                }
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.label !== ""
            text: root.label
            color: Colors.text
            font.family: Appearance.fontFamily
            font.pixelSize: Appearance.fontNormal
            font.bold: true
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor

        onClicked: mouse => root.clicked(mouse.button)
        onWheel: wheel => root.scrolled(wheel.angleDelta.y)
    }
}
