import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.config

PopupWindow {
    id: root

    required property Item anchorItem
    required property date today

    readonly property int padding: 8
    readonly property int cellWidth: 40
    readonly property int cellHeight: 34

    property int viewYear: today.getFullYear()
    property int viewMonth: today.getMonth()

    readonly property var firstOfMonth: new Date(viewYear, viewMonth, 1)
    readonly property int startOffset: (firstOfMonth.getDay() + 6) % 7
    readonly property bool isCurrentMonth: viewYear === today.getFullYear() && viewMonth === today.getMonth()

    anchor.item: root.anchorItem
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.margins.bottom: -19

    implicitWidth: panel.width
    implicitHeight: panel.height
    grabFocus: true
    visible: false
    color: "transparent"

    function shiftMonth(delta) {
        const d = new Date(root.viewYear, root.viewMonth + delta, 1);
        root.viewYear = d.getFullYear();
        root.viewMonth = d.getMonth();
    }

    function goToday() {
        root.viewYear = root.today.getFullYear();
        root.viewMonth = root.today.getMonth();
    }

    onVisibleChanged: {
        if (visible) {
            root.goToday();
            panel.opacity = 0;
            panel.y = -10;
            openAnim.restart();
        }
    }

    component NavButton: Rectangle {
        id: nav

        property string glyph
        signal clicked

        implicitWidth: 26
        implicitHeight: 26
        radius: 7
        color: navHover.hovered ? Qt.rgba(Colors.mauve.r, Colors.mauve.g, Colors.mauve.b, 0.2) : "transparent"

        Behavior on color {
            ColorAnimation {
                duration: Appearance.fast
            }
        }

        Text {
            anchors.centerIn: parent
            text: nav.glyph
            color: navHover.hovered ? Colors.mauve : Colors.subtext0
            font.family: Appearance.fontFamily
            font.pixelSize: Appearance.fontSmall

            Behavior on color {
                ColorAnimation {
                    duration: Appearance.fast
                }
            }
        }

        HoverHandler {
            id: navHover
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: nav.clicked()
        }
    }

    Rectangle {
        id: panel

        width: root.cellWidth * 7 + root.padding * 2
        height: content.implicitHeight + root.padding * 2

        radius: 14
        color: Qt.rgba(Colors.base.r, Colors.base.g, Colors.base.b, Appearance.popup)
        border.width: Appearance.borderLine
        border.color: Colors.surface1
        focus: root.visible

        Keys.onEscapePressed: root.visible = false
        Keys.onLeftPressed: root.shiftMonth(-1)
        Keys.onRightPressed: root.shiftMonth(1)

        // Keep clicks inside the popup from reaching the window behind it.
        // Mouse wheel switches month.
        MouseArea {
            anchors.fill: parent
            onWheel: wheel => root.shiftMonth(wheel.angleDelta.y > 0 ? -1 : 1)
        }

        ColumnLayout {
            id: content

            x: root.padding
            y: root.padding
            width: panel.width - root.padding * 2
            spacing: 4

                RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                Layout.leftMargin: 6
                Layout.rightMargin: 2
                spacing: 4

                Text {
                    Layout.fillWidth: true
                    text: Qt.formatDate(root.firstOfMonth, "MMMM yyyy")
                    color: Colors.text
                    font.family: Appearance.fontFamily
                    font.pixelSize: Appearance.fontNormal
                    font.bold: true

                    // Click the title to jump back to the current month
                    MouseArea {
                        anchors.fill: parent
                        enabled: !root.isCurrentMonth
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: root.goToday()
                    }
                }

                NavButton {
                    glyph: "\uf053"
                    onClicked: root.shiftMonth(-1)
                }

                NavButton {
                    glyph: "\uf054"
                    onClicked: root.shiftMonth(1)
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Colors.surface1
            }

            Row {
                Layout.alignment: Qt.AlignHCenter

                Repeater {
                    model: 7

                    delegate: Item {
                        required property int index

                        width: root.cellWidth
                        height: 24

                        Text {
                            anchors.centerIn: parent
                            text: Qt.locale().dayName((index + 1) % 7, Locale.ShortFormat)
                            color: Colors.subtext0
                            font.family: Appearance.fontFamily
                            font.pixelSize: Appearance.fontSmall
                        }
                    }
                }
            }

            Grid {
                Layout.alignment: Qt.AlignHCenter
                columns: 7

                Repeater {
                    model: 42

                    delegate: Item {
                        id: cell

                        required property int index

                        readonly property var cellDate: new Date(root.viewYear, root.viewMonth, 1 - root.startOffset + index)
                        readonly property bool inMonth: cellDate.getMonth() === root.viewMonth
                        readonly property bool isToday: cellDate.getDate() === root.today.getDate() && cellDate.getMonth() === root.today.getMonth() && cellDate.getFullYear() === root.today.getFullYear()

                        width: root.cellWidth
                        height: root.cellHeight

                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width - 6
                            height: parent.height - 4
                            radius: 8
                            color: cell.isToday ? Colors.mauve : dayHover.hovered ? Qt.rgba(Colors.surface1.r, Colors.surface1.g, Colors.surface1.b, 0.6) : "transparent"

                            Behavior on color {
                                ColorAnimation {
                                    duration: Appearance.fast
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: cell.cellDate.getDate()
                                color: cell.isToday ? Colors.base : cell.inMonth ? Colors.text : Colors.surface2
                                font.family: Appearance.fontFamily
                                font.pixelSize: Appearance.fontSmall
                                font.bold: cell.isToday
                            }
                        }

                        HoverHandler {
                            id: dayHover
                        }
                    }
                }
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
            duration: Appearance.normal
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: panel
            property: "y"
            from: -10
            to: 0
            duration: Appearance.normal
            easing.type: Easing.OutCubic
        }
    }
}
