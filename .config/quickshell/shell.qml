//@ pragma UseQApplication
//@ pragma IconTheme Papirus-Dark

import Quickshell
import Quickshell.Services.Notifications
import qs.modules.bar
import qs.modules.launcher
import qs.modules.osd
import qs.modules.power

ShellRoot {
    NotificationServer {
        id: notifications

        actionsSupported: true

        onNotification: notification => notification.tracked = true
    }

    Variants {
        model: Quickshell.screens
        Bar {
            notificationServer: notifications
        }
    }

    Launcher {}
    PowerMenu {}
    OnScreenDisplay {}
}
