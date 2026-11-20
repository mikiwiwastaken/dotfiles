import QtQuick
import QtQuick.Layouts
import qs.config

Rectangle {
    id: root

    property var notification: null
    property bool transientToast: false
    property bool toastStyle: false
    property bool hovered: false
    property real swipeLimit: width

    signal dismissed
    signal toastExpired

    function dismiss() {
        if (root.notification)
            root.notification.dismiss();
        root.dismissed();
    }

    implicitHeight: content.implicitHeight + 18
    radius: root.toastStyle ? 14 : 10
    color: {
        if (root.toastStyle) {
            const c = root.hovered ? Colors.surface0 : Colors.base;
            return Qt.rgba(c.r, c.g, c.b, Appearance.popup);
        }
        return root.hovered ? Qt.rgba(Colors.surface1.r, Colors.surface1.g, Colors.surface1.b, 0.92) : Qt.rgba(Colors.surface0.r, Colors.surface0.g, Colors.surface0.b, 0.75);
    }
    border.width: root.toastStyle ? Appearance.borderLine : 0
    border.color: root.toastStyle && root.hovered ? Colors.mauve : Colors.surface1

    Behavior on color {
        ColorAnimation {
            duration: Appearance.fast
        }
    }

    Behavior on border.color {
        ColorAnimation {
            duration: Appearance.fast
        }
    }

    HoverHandler {
        onHoveredChanged: {
            root.hovered = hovered;
        }
    }

    DragHandler {
        target: null
        xAxis.enabled: true
        yAxis.enabled: false

        onTranslationChanged: {
            if (active)
                root.x = Math.min(root.swipeLimit, Math.max(0, translation.x));
        }

        onActiveChanged: {
            if (active)
                return;
            if (root.x > root.swipeLimit * 0.35)
                root.dismiss();
            else
                resetPosition.restart();
        }
    }

    NumberAnimation {
        id: resetPosition

        target: root
        property: "x"
        to: 0
        duration: Appearance.normal
        easing.type: Easing.OutCubic
    }

    Timer {
        interval: 5000
        running: root.transientToast && !root.hovered
        onTriggered: root.toastExpired()
    }

    ColumnLayout {
        id: content

        anchors {
            fill: parent
            margins: 9
        }
        spacing: 5

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                Layout.fillWidth: true
                text: root.notification ? root.notification.appName || "Notification" : ""
                color: Colors.subtext0
                elide: Text.ElideRight
                font.family: Appearance.fontFamily
                font.pixelSize: Appearance.fontSmall
            }

            Rectangle {
                implicitWidth: 24
                implicitHeight: 24
                radius: 6
                color: closeHover.hovered ? Qt.rgba(Colors.red.r, Colors.red.g, Colors.red.b, 0.2) : "transparent"

                Behavior on color {
                    ColorAnimation {
                        duration: Appearance.fast
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: "\uf00d"
                    color: closeHover.hovered ? Colors.red : Colors.subtext0
                    font.family: Appearance.fontFamily
                    font.pixelSize: Appearance.fontSmall

                    Behavior on color {
                        ColorAnimation {
                            duration: Appearance.fast
                        }
                    }
                }

                HoverHandler {
                    id: closeHover
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.dismiss()
                }
            }
        }

        Text {
            Layout.fillWidth: true
            visible: root.notification && root.notification.summary !== ""
            text: root.notification ? root.notification.summary : ""
            color: Colors.text
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            maximumLineCount: 2
            elide: Text.ElideRight
            textFormat: Text.PlainText
            font.family: Appearance.fontFamily
            font.pixelSize: Appearance.fontNormal
            font.bold: true
        }

        Text {
            Layout.fillWidth: true
            visible: root.notification && root.notification.body !== ""
            text: root.notification ? root.notification.body : ""
            color: Colors.subtext1
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            maximumLineCount: root.toastStyle ? 3 : 4
            elide: Text.ElideRight
            textFormat: Text.PlainText
            font.family: Appearance.fontFamily
            font.pixelSize: Appearance.fontSmall
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            visible: root.notification && root.notification.actions.length > 0

            Repeater {
                model: root.notification ? root.notification.actions : []

                delegate: Rectangle {
                    required property var modelData

                    implicitWidth: actionLabel.implicitWidth + 16
                    implicitHeight: actionLabel.implicitHeight + 8
                    radius: 6
                    color: actionHover.hovered ? Qt.rgba(Colors.mauve.r, Colors.mauve.g, Colors.mauve.b, 0.2) : "transparent"

                    Text {
                        id: actionLabel

                        anchors.centerIn: parent
                        text: modelData ? modelData.text : ""
                        color: Colors.mauve
                        font.family: Appearance.fontFamily
                        font.pixelSize: Appearance.fontSmall
                    }

                    HoverHandler {
                        id: actionHover
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (modelData)
                                modelData.invoke();
                            root.dismissed();
                        }
                    }
                }
            }
        }
    }
}
