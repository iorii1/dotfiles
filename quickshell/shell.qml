import Quickshell
import "./services"
import "./modules/bar"
import "./modules/launcher"
import "./modules/lock"
import "./modules/notifications"
import "./modules/polkit"
import "./modules/power"
import "./modules/osd"
import "./modules/menu"
import "./modules/network"
import "./modules/bluetooth"
import "./modules/audio"
import "./modules/battery"
import "./modules/dashboard"
import "./modules/capture"
import "./modules/calendar"
import "./modules/clipboard"
import "./modules/media"
import "./modules/overview"
import "./modules/quicksettings"
import "./modules/settings"
import "./modules/dock"

Scope {
    Bar {}
    Launcher {}
    NotificationPopups {}
    NotificationCenter {}
    PowerMenu {}
    PolkitDialog {}
    CapturePopup {}
    Osd {}
    NetworkPopup {}
    BluetoothPopup {}
    BatteryPopup {}
    AudioPopup {}
    CalendarPopup {}
    ClipboardPopup {}
    MediaPopup {}
    Overview {}
    Dashboard {}
    QuickSettings {}
    SettingsWindow {}
    Dock {}

    // Announces state the shell knows about but never said out loud.
    StateToasts {}

    // Present but not bound to anything: locking is deliberate, via
    // `qs ipc call lock lock`, until it has been tried. hyprlock stays on
    // SUPER+Escape as the known-good path.
    Lock {}

    // One context menu, shown wherever it was asked for.
    ContextMenu {}
}
