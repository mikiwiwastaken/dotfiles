import Quickshell.Networking
import QtQuick
import QtQuick.Layouts
import qs.config

Item {
    id: root

    // May briefly become null while the network list updates, so everything is guarded
    required property var network
    property var promptTarget: null

    signal promptRequested
    signal promptCleared

    readonly property bool connected: network?.connected ?? false
    readonly property bool busy: network?.stateChanging ?? false
    readonly property bool known: network?.known ?? false
    readonly property real strength: network?.signalStrength ?? 0
    readonly property int security: network?.security ?? WifiSecurityType.Unknown

    readonly property bool secured: security !== WifiSecurityType.Open && security !== WifiSecurityType.Owe
    readonly property bool needsPsk: security === WifiSecurityType.WpaPsk || security === WifiSecurityType.Wpa2Psk || security === WifiSecurityType.Sae

    readonly property bool askPassword: network !== null && promptTarget === network

    property bool submitted: false
    property bool connecting: false
    property string error: ""

    readonly property string subtitle: {
        if (error !== "")
            return error;
        if (connecting || busy)
            return "Connecting...";
        return connected ? "Connected" : "";
    }

    implicitHeight: header.height + (askPassword ? passwordBox.height + 4 : 0)

    onAskPasswordChanged: {
        if (askPassword)
            Qt.callLater(() => input.forceActiveFocus());
        else
            input.text = "";
    }

    onConnectedChanged: {
        if (connected) {
            connecting = false;
            connectionTimeout.stop();
            error = "";
            submitted = false;
            promptCleared();
        }
    }

    function beginConnection() {
        connecting = true;
        error = "";
        connectionTimeout.restart();
    }

    function submit() {
        if (input.text === "" || !root.network)
            return;
        root.submitted = true;
        root.beginConnection();
        const psk = input.text;
        root.promptCleared();
        root.network.connectWithPsk(psk);
    }

    Timer {
        id: connectionTimeout
        interval: 20000
        onTriggered: {
            if (root.connecting && !root.connected) {
                root.connecting = false;
                if (root.submitted && root.needsPsk) {
                    root.error = "Authentication failed";
                    root.promptRequested();
                } else {
                    root.error = "Connection failed";
                }
            }
        }
    }

    Connections {
        target: root.network

        function onConnectionFailed(reason) {
            root.connecting = false;
            connectionTimeout.stop();
            if ((reason === ConnectionFailReason.NoSecrets || reason === ConnectionFailReason.WifiClientFailed || reason === ConnectionFailReason.WifiAuthTimeout) && root.needsPsk) {
                // Supplicant failures and authentication timeouts can indicate an invalid PSK.
                root.error = root.submitted ? "Wrong password" : "";
                root.promptRequested();
            } else {
                root.error = "Connection failed";
                root.submitted = false;
            }
        }
    }

    Item {
        id: header
        width: root.width
        height: root.subtitle !== "" ? 44 : 34

        Behavior on height {
            NumberAnimation {
                duration: Appearance.fast
                easing.type: Easing.OutCubic
            }
        }

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
            spacing: 10

            Text {
                text: "\uf1eb"
                font.family: Appearance.fontFamily
                font.pixelSize: 16
                color: {
                    if (root.connected)
                        return Colors.mauve;
                    return root.strength > 0.5 ? Colors.text : root.strength > 0.25 ? Colors.yellow : Colors.red;
                }
            }

            Column {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter

                Text {
                    id: nameText
                    width: parent.width
                    text: root.network?.name ?? ""
                    elide: Text.ElideRight
                    color: root.connected ? Colors.mauve : Colors.text
                    font.family: Appearance.fontFamily
                    font.pixelSize: 13
                    font.bold: root.connected

                    SequentialAnimation on opacity {
                        running: root.busy
                        loops: Animation.Infinite

                        NumberAnimation {
                            to: 0.4
                            duration: 500
                        }
                        NumberAnimation {
                            to: 1.0
                            duration: 500
                        }

                        onRunningChanged: {
                            if (!running)
                                nameText.opacity = 1;
                        }
                    }
                }

                Text {
                    visible: root.subtitle !== ""
                    width: parent.width
                    text: root.subtitle
                    elide: Text.ElideRight
                    color: root.error !== "" ? Colors.red : Colors.surface2
                    font.family: Appearance.fontFamily
                    font.pixelSize: 11
                }
            }

            Text {
                visible: root.secured
                text: "\uf023"
                font.family: Appearance.fontFamily
                font.pixelSize: 13
                color: Colors.surface2
            }

            Item {
                implicitWidth: 14
                implicitHeight: 14

                Text {
                    visible: root.connected
                    anchors.centerIn: parent
                    text: "\uf00c"
                    font.family: Appearance.fontFamily
                    font.pixelSize: 13
                    color: Colors.mauve
                }
            }
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor

            onClicked: mouse => {
                if (!root.network)
                    return;

                // Right click: forget a saved network
                if (mouse.button === Qt.RightButton) {
                    if (root.known) {
                        connectionTimeout.stop();
                        root.connecting = false;
                        root.submitted = false;
                        root.error = "";
                        root.promptCleared();
                        root.network.forget();
                    }
                    return;
                }

                // Ignore clicks while a connect/disconnect is already in flight
                if (root.busy)
                    return;

                // Clicking the row that is asking for a password cancels the prompt
                if (root.askPassword) {
                    root.promptCleared();
                    return;
                }

                root.error = "";

                if (root.connected) {
                    connectionTimeout.stop();
                    root.connecting = false;
                    root.promptCleared();
                    root.network.disconnect();
                } else if (root.needsPsk && !root.known) {
                    // Unknown secured network: ask first, so the current connection
                    // is not dropped before we even have a password
                    root.submitted = false;
                    root.promptRequested();
                } else {
                    root.submitted = false;
                    root.beginConnection();
                    root.promptCleared();
                    root.network.connect();
                }
            }
        }
    }

    Rectangle {
        id: passwordBox
        visible: root.askPassword
        x: 10
        y: header.height + 4
        width: root.width - 20
        height: 32
        radius: 8
        color: Colors.surface0
        border.width: 1
        border.color: input.activeFocus ? Colors.mauve : Colors.surface1

        TextInput {
            id: input
            anchors {
                fill: parent
                leftMargin: 10
                rightMargin: 10
            }
            verticalAlignment: TextInput.AlignVCenter
            echoMode: TextInput.Password
            color: Colors.text
            font.family: Appearance.fontFamily
            font.pixelSize: 13
            clip: true
            selectByMouse: true

            onAccepted: root.submit()
            Keys.onEscapePressed: root.promptCleared()

            Text {
                visible: input.text === ""
                anchors.verticalCenter: parent.verticalCenter
                text: "Password"
                color: Colors.surface2
                font: input.font
            }
        }
    }
}
