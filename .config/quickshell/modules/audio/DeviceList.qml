import QtQuick
import QtQuick.Layouts
import qs.config

ColumnLayout {
    id: root

    property var model: null
    property var current: null

    signal selected(var node)

    spacing: 2

    Repeater {
        model: root.model

        delegate: Item {
            id: row

            required property var modelData

            readonly property bool isCurrent: root.current !== null && modelData.id === root.current.id

            Layout.fillWidth: true
            implicitHeight: 30

            Rectangle {
                anchors.fill: parent
                radius: 8
                color: Colors.surface0
                opacity: area.containsMouse ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Appearance.fast
                    }
                }
            }

            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: 10
                    rightMargin: 10
                }
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: row.modelData.description || row.modelData.nickname || row.modelData.name
                    elide: Text.ElideRight
                    color: row.isCurrent ? Colors.mauve : Colors.text
                    font.family: Appearance.fontFamily
                    font.pixelSize: Appearance.fontNormal
                    font.bold: row.isCurrent
                }

                Text {
                    visible: row.isCurrent
                    text: "\uf00c"
                    color: Colors.mauve
                    font.family: Appearance.fontFamily
                    font.pixelSize: Appearance.fontNormal
                }
            }

            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.selected(row.modelData)
            }
        }
    }
}
