import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.config

ColumnLayout {
    id: root

    // QsMenuHandle (tray item menu) or QsMenuEntry (submenu)
    property var menu: null

    signal activated

    spacing: 2

    QsMenuOpener {
        id: opener
        menu: root.menu
    }

    Repeater {
        model: opener.children

        delegate: Item {
            id: entry

            required property var modelData

            readonly property bool isSeparator: modelData.isSeparator
            readonly property bool hasChildren: modelData.hasChildren
            readonly property bool isEnabled: modelData.enabled
            readonly property bool hasButton: modelData.buttonType !== QsMenuButtonType.None
            readonly property bool hasIcon: modelData.icon !== ""

            property bool expanded: false
            property bool everExpanded: false

            onExpandedChanged: if (expanded)
                everExpanded = true

            Layout.fillWidth: true
            implicitWidth: isSeparator ? 0 : row.implicitWidth + 20 + (hasChildren ? 28 : 0)
            implicitHeight: isSeparator ? 9 : header.height + subClip.height

            Rectangle {
                visible: entry.isSeparator
                anchors {
                    left: parent.left
                    right: parent.right
                    leftMargin: 8
                    rightMargin: 8
                    verticalCenter: parent.verticalCenter
                }
                height: 1
                color: Colors.surface1
            }

            Item {
                id: header
                visible: !entry.isSeparator
                width: entry.width
                height: 32

                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    color: Colors.surface0
                    opacity: area.containsMouse && entry.isEnabled ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Appearance.fast
                        }
                    }
                }

                Row {
                    id: row

                    anchors {
                        left: parent.left
                        leftMargin: 10
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: 8

                    Item {
                        visible: entry.hasButton || entry.hasIcon
                        width: 18
                        height: 18
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            visible: entry.hasButton
                            anchors.centerIn: parent
                            font.family: Appearance.fontFamily
                            font.pixelSize: 15
                            color: entry.modelData.checkState === Qt.Checked ? Colors.mauve : Colors.surface2
                            text: {
                                const on = entry.modelData.checkState === Qt.Checked;
                                if (entry.modelData.buttonType === QsMenuButtonType.RadioButton)
                                    return on ? "\uf192" : "\uf10c";
                                return on ? "\uf14a" : "\uf096";
                            }
                        }

                        Image {
                            visible: !entry.hasButton && entry.hasIcon
                            anchors.centerIn: parent
                            width: Appearance.menuIconSize
                            height: Appearance.menuIconSize
                            source: entry.modelData.icon
                            sourceSize.width: Appearance.menuIconSize
                            sourceSize.height: Appearance.menuIconSize
                            fillMode: Image.PreserveAspectFit
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: entry.modelData.text
                        color: entry.isEnabled ? Colors.text : Colors.surface2
                        font.family: Appearance.fontFamily
                        font.pixelSize: Appearance.fontNormal
                    }
                }

                Text {
                    visible: entry.hasChildren
                    anchors {
                        right: parent.right
                        rightMargin: 12
                        verticalCenter: parent.verticalCenter
                    }
                    text: "\uf107"
                    color: Colors.surface2
                    font.family: Appearance.fontFamily
                    font.pixelSize: 14
                    rotation: entry.expanded ? 180 : 0

                    Behavior on rotation {
                        NumberAnimation {
                            duration: Appearance.normal
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: entry.isEnabled
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        if (entry.hasChildren) {
                            entry.expanded = !entry.expanded;
                        } else {
                            entry.modelData.triggered();
                            root.activated();
                        }
                    }
                }
            }

            Item {
                id: subClip
                y: header.height
                width: entry.width
                clip: true
                visible: height > 0

                height: entry.expanded ? (subLoader.item ? subLoader.item.implicitHeight : 0) : 0

                Behavior on height {
                    NumberAnimation {
                        duration: Appearance.normal
                        easing.type: Easing.OutCubic
                    }
                }

                Loader {
                    id: subLoader
                    x: 14
                    width: subClip.width - 14
                    active: entry.hasChildren && entry.everExpanded

                    // Loaded by path to avoid a static recursive instantiation error
                    source: "MenuList.qml"

                    onLoaded: {
                        item.menu = entry.modelData;
                        item.activated.connect(root.activated);
                    }
                }
            }
        }
    }
}
