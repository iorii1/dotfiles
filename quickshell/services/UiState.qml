pragma Singleton
import QtQuick
import Quickshell

Singleton {
    property bool powerMenuOpen: false
    property bool quickSettingsOpen: false
    property string quickSettingsSection: ""
    property bool calendarOpen: false
    property bool clipboardOpen: false
    property bool mediaPopupOpen: false
}
