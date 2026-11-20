import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.modules.bar

Item {
    id: root

    required property var notificationServer
    required property var screen
    required property Item anchorItem

    readonly property int toastWidth: 360
    readonly property int toastSwipeSpace: toastWidth
    property int nextToastToken: 0
    property var seenNotificationIds: ({})

    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight

    ListModel {
        id: toastNotifications
    }

    ScriptModel {
        id: sortedNotifications

        values: root.notificationServer.trackedNotifications.values.slice().reverse()
    }

    Component.onCompleted: {
        for (const notification of root.notificationServer.trackedNotifications.values)
            root.seenNotificationIds[String(notification.id)] = true;
    }

    Timer {
        id: toastHideTimer

        interval: Appearance.normal + 50
        onTriggered: {
            if (toastNotifications.count === 0)
                toast.visible = false;
        }
    }

    function removeToast(toastToken) {
        for (let i = toastNotifications.count - 1; i >= 0; --i) {
            if (toastNotifications.get(i).toastToken === toastToken) {
                toastNotifications.remove(i);
                break;
            }
        }

        if (toastNotifications.count === 0)
            toastHideTimer.restart();
    }

    Connections {
        target: root.notificationServer

        function onNotification(notification) {
            if (root.screen !== Quickshell.screens[0])
                return;

            const notificationKey = String(notification.id);
            if (root.seenNotificationIds[notificationKey])
                return;
            root.seenNotificationIds[notificationKey] = true;
            if (notification.lastGeneration)
                return;
            if (popup.visible)
                return;

            toastHideTimer.stop();
            toastNotifications.insert(0, {
                "notificationId": notification.id,
                "toastToken": ++root.nextToastToken
            });
            if (toastNotifications.count > 5)
                toastNotifications.remove(toastNotifications.count - 1);
            toast.visible = true;
        }
    }

    StatusItem {
        id: button

        icon: "\uf0f3"
        iconColor: root.notificationServer.trackedNotifications.values.length > 0 ? Colors.red : Colors.text

        onClicked: mouseButton => {
            if (mouseButton === Qt.LeftButton)
                popup.visible = !popup.visible;
        }
    }

    PopupWindow {
        id: toast

        anchor.item: root.anchorItem
        anchor.rect.x: root.anchorItem.width + root.toastSwipeSpace - 1
        anchor.rect.y: root.anchorItem.height - 1
        anchor.rect.width: 1
        anchor.rect.height: 1
        anchor.edges: Edges.Bottom | Edges.Right
        anchor.gravity: Edges.Bottom | Edges.Left
        anchor.adjustment: PopupAdjustment.None
        anchor.margins.bottom: -9

        implicitWidth: toastPanel.width
        implicitHeight: toastPanel.height
        visible: false
        color: "transparent"
        BackgroundEffect.blurRegion: Region {
            item: toastPanel
        }

        Rectangle {
            id: toastPanel

            width: root.toastWidth + root.toastSwipeSpace
            height: Math.max(120, toastList.contentHeight + 12)
            radius: 14
            color: "transparent"
            border.width: 0

            ListView {
                id: toastList

                anchors {
                    fill: parent
                    margins: 0
                }
                model: toastNotifications
                spacing: 8
                clip: true
                interactive: false

                delegate: NotificationRow {
                    required property var notificationId
                    required property int toastToken

                    width: root.toastWidth
                    notification: root.notificationServer.trackedNotifications.values.find(item => item.id === notificationId) ?? null
                    transientToast: notification !== null
                    toastStyle: true
                    swipeLimit: root.toastSwipeSpace
                    onDismissed: root.removeToast(toastToken)
                    onToastExpired: root.removeToast(toastToken)
                }

                add: Transition {
                    ParallelAnimation {
                        NumberAnimation {
                            property: "x"
                            from: root.toastSwipeSpace
                            to: 0
                            duration: Appearance.normal
                            easing.type: Easing.OutCubic
                        }
                        NumberAnimation {
                            property: "opacity"
                            from: 0
                            to: 1
                            duration: Appearance.normal
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                addDisplaced: Transition {
                    NumberAnimation {
                        property: "y"
                        duration: Appearance.normal
                        easing.type: Easing.OutCubic
                    }
                }

                remove: Transition {
                    enabled: !popup.visible

                    ParallelAnimation {
                        NumberAnimation {
                            property: "x"
                            to: root.toastSwipeSpace
                            duration: Appearance.normal
                            easing.type: Easing.OutCubic
                        }
                        NumberAnimation {
                            property: "opacity"
                            to: 0
                            duration: Appearance.normal
                        }
                    }
                }
            }
        }

        onVisibleChanged: {
            if (visible) {
                toastPanel.opacity = 0;
                toastPanel.y = -10;
                toastOpenAnim.restart();
            }
        }

        ParallelAnimation {
            id: toastOpenAnim

            NumberAnimation {
                target: toastPanel
                property: "opacity"
                from: 0
                to: 1
                duration: Appearance.normal
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: toastPanel
                property: "y"
                from: -10
                to: 0
                duration: Appearance.normal
                easing.type: Easing.OutCubic
            }
        }
    }

    PopupWindow {
        id: popup

        anchor.item: root.anchorItem
        anchor.edges: Edges.Bottom | Edges.Right
        anchor.gravity: Edges.Bottom | Edges.Left
        anchor.margins.bottom: -9

        implicitWidth: panel.width
        implicitHeight: panel.height
        grabFocus: true
        visible: false
        color: "transparent"

        BackgroundEffect.blurRegion: Region {
            item: panel
        }

        Rectangle {
            id: panel

            width: 360
            height: Math.min(content.implicitHeight + 20, 520)
            radius: 14
            color: Qt.rgba(Colors.base.r, Colors.base.g, Colors.base.b, Appearance.popup)
            border.width: Appearance.borderLine
            border.color: Colors.surface1
            focus: popup.visible

            Keys.onEscapePressed: popup.visible = false

            MouseArea {
                anchors.fill: parent
            }

            ColumnLayout {
                id: content

                x: 10
                y: 10
                width: panel.width - 20
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 34
                    Layout.leftMargin: 6
                    Layout.rightMargin: 6
                    spacing: 10

                    Text {
                        text: "\uf0f3"
                        color: Colors.mauve
                        font.family: Appearance.fontFamily
                        font.pixelSize: Appearance.fontLarge
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "Notifications"
                        color: Colors.text
                        font.family: Appearance.fontFamily
                        font.pixelSize: Appearance.fontNormal
                        font.bold: true
                    }

                    Rectangle {
                        visible: root.notificationServer.trackedNotifications.values.length > 0
                        implicitWidth: clearLabel.implicitWidth + 16
                        implicitHeight: 26
                        radius: 7
                        color: clearHover.hovered ? Qt.rgba(Colors.mauve.r, Colors.mauve.g, Colors.mauve.b, 0.18) : "transparent"

                        Behavior on color {
                            ColorAnimation {
                                duration: Appearance.fast
                            }
                        }

                        Text {
                            id: clearLabel

                            anchors.centerIn: parent
                            text: "Clear all"
                            color: clearHover.hovered ? Colors.mauve : Colors.subtext0
                            font.family: Appearance.fontFamily
                            font.pixelSize: Appearance.fontSmall

                            Behavior on color {
                                ColorAnimation {
                                    duration: Appearance.fast
                                }
                            }
                        }

                        HoverHandler {
                            id: clearHover
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                const notifications = root.notificationServer.trackedNotifications.values.slice();
                                for (const notification of notifications)
                                    notification.dismiss();
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Colors.surface1
                }

                ListView {
                    id: notificationList

                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(contentHeight, 420)
                    model: sortedNotifications
                    clip: true
                    spacing: 6
                    boundsBehavior: Flickable.StopAtBounds
                    interactive: contentHeight > height

                    delegate: NotificationRow {
                        required property var modelData

                        width: ListView.view.width
                        notification: modelData
                    }
                }

                Text {
                    visible: root.notificationServer.trackedNotifications.values.length === 0
                    Layout.fillWidth: true
                    Layout.preferredHeight: 100
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: "No notifications"
                    color: Colors.surface2
                    font.family: Appearance.fontFamily
                    font.pixelSize: Appearance.fontNormal
                }
            }
        }

        onVisibleChanged: {
            if (visible) {
                toastHideTimer.stop();
                toastNotifications.clear();
                toast.visible = false;
                panel.opacity = 0;
                panel.y = -10;
                popupOpenAnim.restart();
            } else if (toastNotifications.count > 0) {
                toastHideTimer.stop();
                toast.visible = true;
            }
        }

        ParallelAnimation {
            id: popupOpenAnim

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
}
