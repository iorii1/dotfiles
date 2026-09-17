import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../config"
import "../../services"
import "../common"

PanelWindow {
    id: calWindow

    visible: UiState.calendarOpen
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-popup"
    exclusionMode: ExclusionMode.Ignore
    focusable: false
    color: "transparent"

    anchors { top: true; bottom: true; left: true; right: true }

    property var viewDate: new Date()
    readonly property date today: new Date()
    property var gridCells: buildGrid()

    onVisibleChanged: if (visible) gridCells = buildGrid()

    IpcHandler {
        target: "calendar"
        function toggle(): void { UiState.calendarOpen = !UiState.calendarOpen }
        function open(): void { UiState.calendarOpen = true }
        function close(): void { UiState.calendarOpen = false }
    }

    onViewDateChanged: gridCells = buildGrid()

    function shiftMonth(delta) {
        const d = new Date(viewDate)
        d.setDate(1)
        d.setMonth(d.getMonth() + delta)
        viewDate = d
    }

    function buildGrid() {
        const y = viewDate.getFullYear()
        const m = viewDate.getMonth()
        const firstDow = new Date(y, m, 1).getDay()
        const daysInThisMonth = new Date(y, m + 1, 0).getDate()
        const daysInPrevMonth = new Date(y, m, 0).getDate()
        const cells = []
        for (let i = 0; i < firstDow; i++) {
            cells.push({ day: daysInPrevMonth - firstDow + 1 + i, inMonth: false, isToday: false })
        }
        for (let d = 1; d <= daysInThisMonth; d++) {
            const isToday = d === today.getDate() && m === today.getMonth() && y === today.getFullYear()
            cells.push({ day: d, inMonth: true, isToday: isToday })
        }
        let nextDay = 1
        while (cells.length < 42) {
            cells.push({ day: nextDay, inMonth: false, isToday: false })
            nextDay++
        }
        return cells
    }

    MouseArea {
        anchors.fill: parent
        onClicked: UiState.calendarOpen = false
    }

    PopupCard {
        id: card
        anchors.horizontalCenter: parent.horizontalCenter
        readonly property int restY: Appearance.barHeight + Appearance.barMargin + Appearance.spacingSmall
        width: 320
        height: layout.implicitHeight + Appearance.spacingNormal * 2

        opacity: UiState.calendarOpen ? 1 : 0
        y: UiState.calendarOpen ? restY : restY - 12
        scale: UiState.calendarOpen ? 1 : 0.95
        transformOrigin: Item.Top
        Behavior on opacity { NumberAnimation { duration: Appearance.animNormal; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: Appearance.animNormal; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: Appearance.animNormal; easing.type: Easing.OutBack; easing.overshoot: Appearance.overshootCard } }

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            id: layout
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Appearance.spacingNormal
            spacing: Appearance.spacingSmall

            RowLayout {
                Layout.fillWidth: true

                Item {
                    id: prevBtn
                    implicitWidth: 28; implicitHeight: 28

                    scale: prevFx.popScale * (prevFx.pressed ? 0.85 : (prevFx.containsMouse ? 1.1 : 1.0))
                    Behavior on scale { NumberAnimation { duration: Appearance.animFast; easing.type: Easing.OutQuint } }

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: prevFx.containsMouse ? Colors.surfaceContainerHigh : "transparent"
                        Behavior on color { ColorAnimation { duration: Appearance.animFast } }

                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: "#ffffff"
                            opacity: prevFx.flashOpacity
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "\uf053"
                            color: Colors.textSecondary
                            font.family: Appearance.fontFamily
                            font.pixelSize: Appearance.fontSizeLarge
                        }
                    }

                    PressFx {
                        id: prevFx
                        anchors.fill: parent
                        onActivated: calWindow.shiftMonth(-1)
                    }
                }

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: Qt.formatDate(calWindow.viewDate, "MMMM yyyy")
                    color: Colors.textPrimary
                    font.family: Appearance.fontFamily
                    font.bold: true
                    font.pixelSize: Appearance.fontSizeNormal
                }

                Item {
                    id: nextBtn
                    implicitWidth: 28; implicitHeight: 28

                    scale: nextFx.popScale * (nextFx.pressed ? 0.85 : (nextFx.containsMouse ? 1.1 : 1.0))
                    Behavior on scale { NumberAnimation { duration: Appearance.animFast; easing.type: Easing.OutQuint } }

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: nextFx.containsMouse ? Colors.surfaceContainerHigh : "transparent"
                        Behavior on color { ColorAnimation { duration: Appearance.animFast } }

                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: "#ffffff"
                            opacity: nextFx.flashOpacity
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "\uf054"
                            color: Colors.textSecondary
                            font.family: Appearance.fontFamily
                            font.pixelSize: Appearance.fontSizeLarge
                        }
                    }

                    PressFx {
                        id: nextFx
                        anchors.fill: parent
                        onActivated: calWindow.shiftMonth(1)
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                visible: Weather.ready
                spacing: Appearance.spacingSmall

                Item {
                    id: weatherIcon
                    implicitWidth: 30
                    implicitHeight: 30

                    readonly property string cat: Weather.category(Weather.weatherCode)

                    Item {
                        id: sunGroup
                        visible: weatherIcon.cat === "clear"
                        anchors.centerIn: parent
                        width: 20; height: 20

                        NumberAnimation on rotation {
                            running: weatherIcon.cat === "clear"
                            loops: Animation.Infinite
                            from: 0; to: 360; duration: 9000
                        }

                        Repeater {
                            model: 8
                            Item {
                                required property int index
                                anchors.centerIn: parent
                                rotation: index * 45

                                Rectangle {
                                    x: -1; y: -13
                                    width: 2; height: 7
                                    radius: 1
                                    color: Colors.primary
                                }
                            }
                        }

                        Rectangle {
                            anchors.centerIn: parent
                            width: 13; height: 13
                            radius: 6.5
                            color: Colors.primary
                        }
                    }

                    Item {
                        id: cloudGroup
                        visible: weatherIcon.cat !== "clear"
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: bobOffset
                        width: 26; height: 16

                        property real bobOffset: 0
                        SequentialAnimation on bobOffset {
                            running: weatherIcon.cat !== "clear"
                            loops: Animation.Infinite
                            NumberAnimation { to: -2; duration: 1300; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 2; duration: 1300; easing.type: Easing.InOutSine }
                        }

                        Rectangle { x: 0; y: 6; width: 14; height: 10; radius: 5; color: Colors.textSecondary }
                        Rectangle { x: 8; y: 0; width: 14; height: 14; radius: 7; color: Colors.textSecondary }
                        Rectangle { x: 14; y: 6; width: 12; height: 10; radius: 5; color: Colors.textSecondary }
                    }

                    Item {
                        id: particleArea
                        visible: weatherIcon.cat === "rain" || weatherIcon.cat === "snow"
                        anchors.top: cloudGroup.bottom
                        anchors.topMargin: -2
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 22
                        height: 10
                        clip: true

                        Repeater {
                            model: 3
                            Rectangle {
                                id: particle
                                required property int index
                                width: weatherIcon.cat === "snow" ? 3 : 2
                                height: weatherIcon.cat === "snow" ? 3 : 6
                                radius: weatherIcon.cat === "snow" ? 1.5 : 1
                                color: weatherIcon.cat === "snow" ? "#ffffff" : Colors.primary
                                x: 2 + particle.index * 7
                                y: -height

                                SequentialAnimation {
                                    running: particleArea.visible
                                    loops: Animation.Infinite
                                    PauseAnimation { duration: particle.index * 280 }
                                    NumberAnimation { target: particle; property: "y"; to: particleArea.height; duration: weatherIcon.cat === "snow" ? 1600 : 650; easing.type: Easing.Linear }
                                    PropertyAction { target: particle; property: "y"; value: -particle.height }
                                    PauseAnimation { duration: 150 }
                                }
                            }
                        }
                    }

                    Text {
                        id: boltIcon
                        visible: weatherIcon.cat === "thunder"
                        anchors.top: cloudGroup.bottom
                        anchors.topMargin: -4
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: ""
                        color: Colors.primary
                        font.family: Appearance.fontFamily
                        font.pixelSize: 14

                        SequentialAnimation {
                            running: weatherIcon.cat === "thunder"
                            loops: Animation.Infinite
                            NumberAnimation { target: boltIcon; property: "opacity"; to: 1.0; duration: 80 }
                            NumberAnimation { target: boltIcon; property: "opacity"; to: 0.25; duration: 200 }
                            NumberAnimation { target: boltIcon; property: "opacity"; to: 1.0; duration: 80 }
                            NumberAnimation { target: boltIcon; property: "opacity"; to: 0.25; duration: 200 }
                            PauseAnimation { duration: 1800 }
                        }
                    }
                }

                Text {
                    text: Math.round(Weather.temperature) + "°C"
                    color: Colors.textPrimary
                    font.family: Appearance.fontFamily
                    font.pixelSize: Appearance.fontSizeSmall
                }

                Text {
                    Layout.fillWidth: true
                    text: Weather.cityName
                    color: Colors.textSecondary
                    font.family: Appearance.fontFamily
                    font.pixelSize: Appearance.fontSizeSmall
                    elide: Text.ElideRight
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Colors.outline; opacity: 0.4; visible: Weather.ready }

            GridLayout {
                Layout.fillWidth: true
                columns: 7
                rowSpacing: 4
                columnSpacing: 4

                Repeater {
                    model: ["S", "M", "T", "W", "T", "F", "S"]
                    Text {
                        required property string modelData
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData
                        color: Colors.textSecondary
                        font.family: Appearance.fontFamily
                        font.pixelSize: Appearance.fontSizeSmall
                        font.bold: true
                    }
                }

                Repeater {
                    model: calWindow.gridCells
                    Item {
                        id: dayCell
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        Layout.preferredHeight: 32

                        scale: 0.4
                        opacity: 0.0

                        Component.onCompleted: cellEntranceAnim.start()
                        PopIn {
                            id: cellEntranceAnim
                            target: dayCell
                            delay: Math.min((dayCell.index % 7 + Math.floor(dayCell.index / 7)) * 18, 260)
                            fromScale: 0.4
                            scaleDuration: 260
                            overshoot: 1.7
                        }

                        Rectangle {
                            id: pill
                            anchors.fill: parent
                            radius: height / 2
                            color: dayCell.modelData.isToday ? Colors.primary : "transparent"
                            clip: true
                            Behavior on color { ColorAnimation { duration: Appearance.animFast } }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: dayCell.modelData.day
                            color: dayCell.modelData.isToday ? Colors.primaryText : (dayCell.modelData.inMonth ? Colors.textPrimary : Colors.textSecondary)
                            font.family: Appearance.fontFamily
                            font.pixelSize: Appearance.fontSizeSmall
                            opacity: dayCell.modelData.inMonth ? 1.0 : 0.35
                        }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Colors.outline; opacity: 0.4 }

            ToggleRow {
                Layout.fillWidth: true
                icon: ""
                label: "Keep Awake"
                checked: IdleInhibit.keepAwake
                active: UiState.calendarOpen
                entranceDelay: 0
                expandable: false
                onToggleRequested: IdleInhibit.toggle()
            }
        }
    }
}
