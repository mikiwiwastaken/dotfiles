import Quickshell.Services.Pipewire
import QtQuick
import qs.config
import qs.modules.bar

StatusItem {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property real volume: sink?.audio?.volume ?? 0

    // Required, otherwise volume/muted are invalid
    PwObjectTracker {
        objects: [root.sink]
    }

    icon: {
        if (root.muted || root.volume === 0)
            return "\uf026";
        if (root.volume < 0.5)
            return "\uf027";
        return "\uf028";
    }

    iconColor: root.muted ? Colors.surface2 : root.volume > 1.0001 ? Colors.yellow : Colors.text

    AudioPopup {
        id: popup
        anchorItem: root.parent.parent
    }

    onClicked: button => {
        if (button === Qt.LeftButton) {
            // Clicking the icon while the popup is open first dismisses it (focus grab),
            // so ignore the click that would immediately reopen it
            if (Date.now() - popup.closedAt < 200)
                return;
            popup.open();
        } else if (button === Qt.RightButton && root.sink?.audio) {
            root.sink.audio.muted = !root.sink.audio.muted;
        }
    }

    onScrolled: delta => {
        const audio = root.sink?.audio;
        if (!audio)
            return;
        audio.muted = false;
        audio.volume = Math.max(0, Math.min(1.5, audio.volume + (delta > 0 ? 0.05 : -0.05)));
    }
}
