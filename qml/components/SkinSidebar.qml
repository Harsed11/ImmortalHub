import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"

Rectangle {
    id: sidebar
    width: isHovered ? SkinTheme.sidebarExpanded : SkinTheme.sidebarCollapsed
    implicitWidth: width
    Layout.preferredWidth: width
    Layout.minimumWidth: width
    Layout.maximumWidth: width
    color: SkinTheme.bgSidebar
    z: 20
    clip: true

    property string currentTab: "heroes"
    property bool isHovered: false
    property bool isExpanded: width > (SkinTheme.sidebarCollapsed + 30)
    signal tabSelected(string tabId)

    Behavior on width {
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }

    // Debounce timer: prevents flickering/jittering when mouse moves across child elements or borders
    Timer {
        id: collapseTimer
        interval: 220
        repeat: false
        onTriggered: {
            sidebar.isHovered = false
        }
    }

    function expandSidebar() {
        collapseTimer.stop()
        sidebar.isHovered = true
    }

    function scheduleCollapse() {
        collapseTimer.restart()
    }

    // Right edge neon border
    Rectangle {
        anchors.right: parent.right
        width: 1
        height: parent.height
        color: SkinTheme.borderMuted
    }

    // Scanning line effect — slow horizontal sweep
    Rectangle {
        id: scanLine
        width: parent.width
        height: 1
        color: SkinTheme.accentCyan
        opacity: 0.08
        y: 0

        SequentialAnimation on y {
            running: true
            loops: Animation.Infinite
            NumberAnimation { to: sidebar.height; duration: SkinTheme.animScanline; easing.type: Easing.Linear }
            NumberAnimation { to: 0; duration: 0 }
        }
    }

    // Scanning line glow trail
    Rectangle {
        width: parent.width
        height: 30
        y: scanLine.y - 15
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.5; color: SkinTheme.accentCyanGlow }
            GradientStop { position: 1.0; color: "transparent" }
        }
        opacity: 0.15
    }

    // Master hover area (background)
    MouseArea {
        id: masterHoverArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        z: -1
        onEntered: sidebar.expandSidebar()
        onExited: sidebar.scheduleCollapse()
        onPositionChanged: sidebar.expandSidebar()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Top spacer
        Item { Layout.preferredHeight: 8 }

        // ─── BROWSE Section ───
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: sidebar.isHovered ? 28 : 16
            Layout.leftMargin: 16

            Behavior on Layout.preferredHeight { NumberAnimation { duration: SkinTheme.animFast } }

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "BROWSE"
                color: SkinTheme.textMuted
                font.family: SkinTheme.fontMono
                font.pixelSize: 9
                font.bold: true
                font.letterSpacing: 2.0
                opacity: sidebar.isHovered ? 1.0 : 0.0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: SkinTheme.animFast } }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.leftMargin: 2
                anchors.verticalCenter: parent.verticalCenter
                width: 4
                height: 4
                radius: 2
                color: SkinTheme.accentCyan
                opacity: sidebar.isHovered ? 0.0 : 0.4
                Behavior on opacity { NumberAnimation { duration: SkinTheme.animFast } }
            }
        }

        // Navigation Items — Browse
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3
            Layout.leftMargin: 4
            Layout.rightMargin: 4

            Repeater {
                model: [
                    { id: "heroes",    label: "Hero Skins",        icon: "⚔" },
                    { id: "favorites", label: "Favorites",         icon: "★" },
                    { id: "effects",   label: "Effects & Shaders", icon: "✦" },
                    { id: "map",       label: "Terrain & World",   icon: "◈" },
                    { id: "audio",     label: "Voice & Music",     icon: "♪" },
                    { id: "misc",      label: "Items & Misc",      icon: "◆" }
                ]

                delegate: Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 42
                    radius: SkinTheme.radiusMedium
                    color: sidebar.currentTab === modelData.id
                           ? SkinTheme.bgCardHover
                           : (navMouse.containsMouse ? "#0E1422" : "transparent")

                    Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

                    // Active neon indicator — left edge
                    Rectangle {
                        anchors.left: parent.left
                        anchors.leftMargin: 0
                        anchors.verticalCenter: parent.verticalCenter
                        width: 3
                        height: sidebar.currentTab === modelData.id ? 26 : 0
                        radius: 1.5
                        color: SkinTheme.accentCyan

                        Behavior on height { NumberAnimation { duration: SkinTheme.animNormal; easing.type: Easing.OutBack } }

                        // Neon glow
                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width + 8
                            height: parent.height + 8
                            radius: parent.radius + 4
                            color: SkinTheme.accentCyan
                            opacity: 0.25
                            z: -1
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 8
                        spacing: 12

                        // Icon container — stays fixed at 24px
                        Item {
                            Layout.preferredWidth: 24
                            Layout.preferredHeight: 24
                            Layout.alignment: Qt.AlignVCenter

                            // Icon Glow
                            Text {
                                anchors.centerIn: parent
                                text: modelData.icon
                                font.pixelSize: 16
                                color: SkinTheme.accentCyan
                                opacity: sidebar.currentTab === modelData.id ? 0.45 : 0
                                visible: opacity > 0
                                scale: 1.15
                                Behavior on opacity { NumberAnimation { duration: SkinTheme.animFast } }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: modelData.icon
                                font.pixelSize: 16
                                color: sidebar.currentTab === modelData.id
                                       ? SkinTheme.accentCyan
                                       : (navMouse.containsMouse ? SkinTheme.textPrimary : SkinTheme.textSecondary)

                                Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }
                            }
                        }

                        // Label — appears on expand with active glow
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            opacity: sidebar.isHovered ? 1.0 : 0.0
                            visible: opacity > 0
                            Behavior on opacity { NumberAnimation { duration: SkinTheme.animFast } }

                            Text {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.label
                                color: SkinTheme.accentCyan
                                font.family: SkinTheme.fontFamily
                                font.pixelSize: 14
                                font.weight: Font.Bold
                                opacity: sidebar.currentTab === modelData.id ? 0.35 : 0
                                visible: opacity > 0
                            }

                            Text {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.label
                                color: sidebar.currentTab === modelData.id
                                       ? SkinTheme.textPrimary
                                       : (navMouse.containsMouse ? SkinTheme.textPrimary : SkinTheme.textSecondary)
                                font.family: SkinTheme.fontFamily
                                font.pixelSize: 14
                                font.weight: sidebar.currentTab === modelData.id ? Font.Bold : Font.Medium
                                elide: Text.ElideRight
                                width: parent.width

                                Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }
                            }
                        }
                    }

                    MouseArea {
                        id: navMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: sidebar.expandSidebar()
                        onPositionChanged: sidebar.expandSidebar()
                        onExited: sidebar.scheduleCollapse()
                        onClicked: {
                            sidebar.currentTab = modelData.id
                            sidebar.tabSelected(modelData.id)
                        }
                    }
                }
            }
        }

        // ─── TOOLS Section separator ───
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: sidebar.isHovered ? 28 : 16
            Layout.topMargin: 8
            Layout.leftMargin: 16

            Behavior on Layout.preferredHeight { NumberAnimation { duration: SkinTheme.animFast } }

            // Thin separator line
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: sidebar.isHovered ? 0 : 4
                anchors.rightMargin: sidebar.isHovered ? 16 : 8
                height: 1
                color: SkinTheme.borderMuted
            }

            Text {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                text: "SYSTEM"
                color: SkinTheme.textMuted
                font.family: SkinTheme.fontMono
                font.pixelSize: 9
                font.bold: true
                font.letterSpacing: 2.0
                opacity: sidebar.isHovered ? 1.0 : 0.0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: SkinTheme.animFast } }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.leftMargin: 2
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 4
                width: 4
                height: 4
                radius: 2
                color: SkinTheme.accentViolet
                opacity: sidebar.isHovered ? 0.0 : 0.4
                Behavior on opacity { NumberAnimation { duration: SkinTheme.animFast } }
            }
        }

        // Tools Navigation Items
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3
            Layout.leftMargin: 4
            Layout.rightMargin: 4

            Repeater {
                model: [
                    { id: "fpsboost",  label: "Performance",      icon: "⚡", color: SkinTheme.accentViolet },
                    { id: "installed", label: "Active Mods",      icon: "☰", color: SkinTheme.accentEmerald },
                    { id: "settings",  label: "Settings",         icon: "⚙", color: "" }
                ]

                delegate: Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 42
                    radius: SkinTheme.radiusMedium
                    color: sidebar.currentTab === modelData.id
                           ? SkinTheme.bgCardHover
                           : (toolNavMouse.containsMouse ? "#0E1422" : "transparent")

                    Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

                    // Active neon indicator
                    Rectangle {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: 3
                        height: sidebar.currentTab === modelData.id ? 26 : 0
                        radius: 1.5
                        color: modelData.color || SkinTheme.accentViolet

                        Behavior on height { NumberAnimation { duration: SkinTheme.animNormal; easing.type: Easing.OutBack } }

                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width + 8
                            height: parent.height + 8
                            radius: parent.radius + 4
                            color: parent.color
                            opacity: 0.25
                            z: -1
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 8
                        spacing: 12

                        Item {
                            Layout.preferredWidth: 24
                            Layout.preferredHeight: 24
                            Layout.alignment: Qt.AlignVCenter

                            Text {
                                anchors.centerIn: parent
                                text: modelData.icon
                                font.pixelSize: 16
                                color: sidebar.currentTab === modelData.id
                                       ? (modelData.color || SkinTheme.accentViolet)
                                       : (toolNavMouse.containsMouse ? SkinTheme.textPrimary : SkinTheme.textSecondary)

                                Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }
                            }
                        }

                        Text {
                            text: modelData.label
                            color: sidebar.currentTab === modelData.id
                                   ? SkinTheme.textPrimary
                                   : (toolNavMouse.containsMouse ? SkinTheme.textPrimary : SkinTheme.textSecondary)
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: 14
                            font.weight: sidebar.currentTab === modelData.id ? Font.Bold : Font.Medium
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            opacity: sidebar.isHovered ? 1.0 : 0.0
                            visible: opacity > 0

                            Behavior on opacity { NumberAnimation { duration: SkinTheme.animFast } }
                            Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }
                        }
                    }

                    MouseArea {
                        id: toolNavMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: sidebar.expandSidebar()
                        onPositionChanged: sidebar.expandSidebar()
                        onExited: sidebar.scheduleCollapse()
                        onClicked: {
                            sidebar.currentTab = modelData.id
                            sidebar.tabSelected(modelData.id)
                        }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }

        // ─── Bottom Status Card ───
        Rectangle {
            Layout.fillWidth: true
            Layout.margins: sidebar.isHovered ? 8 : 4
            Layout.preferredHeight: sidebar.isHovered ? 104 : 48
            radius: SkinTheme.radiusMedium
            color: SkinTheme.bgCard
            border.color: SkinTheme.borderMuted
            border.width: 1
            clip: true

            Behavior on Layout.margins { NumberAnimation { duration: SkinTheme.animFast } }
            Behavior on Layout.preferredHeight { NumberAnimation { duration: SkinTheme.animNormal } }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: sidebar.isHovered ? 10 : 6
                spacing: 6

                // Dota status indicator
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        color: app.dotaDetected ? SkinTheme.accentEmerald : SkinTheme.accentCrimson

                        // Pulse animation
                        SequentialAnimation on opacity {
                            running: true
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.3; duration: 1500; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 1.0; duration: 1500; easing.type: Easing.InOutSine }
                        }
                    }

                    Text {
                        text: sidebar.isHovered ? (app.dotaDetected ? "DOTA 2 LINKED" : "NO GAME PATH") : ""
                        color: app.dotaDetected ? SkinTheme.accentEmerald : SkinTheme.accentCrimson
                        font.family: SkinTheme.fontMono
                        font.pixelSize: 10
                        font.bold: true
                        font.letterSpacing: 1.0
                        Layout.fillWidth: true
                        opacity: sidebar.isHovered ? 1.0 : 0.0
                        visible: opacity > 0
                        Behavior on opacity { NumberAnimation { duration: SkinTheme.animFast } }
                    }

                    Text {
                        text: sidebar.isHovered ? (app.installedCount + " MODS") : ""
                        color: app.installedCount > 0 ? SkinTheme.accentEmerald : SkinTheme.textMuted
                        font.family: SkinTheme.fontMono
                        font.pixelSize: 9
                        font.bold: true
                        visible: sidebar.isHovered
                    }
                }

                // Expanded: extra info
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: SkinTheme.borderMuted
                    visible: sidebar.isHovered
                }

                // Launch Dota button (expanded only)
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 28
                    radius: SkinTheme.radiusSmall
                    visible: sidebar.isHovered && app.dotaDetected
                    color: launchMouse.containsMouse ? SkinTheme.accentCyanGlow : SkinTheme.bgDark
                    border.color: SkinTheme.accentCyan
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "▶ LAUNCH DOTA 2"
                        color: SkinTheme.accentCyan
                        font.family: SkinTheme.fontMono
                        font.pixelSize: 10
                        font.bold: true
                        font.letterSpacing: 1.0
                    }

                    MouseArea {
                        id: launchMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: sidebar.expandSidebar()
                        onPositionChanged: sidebar.expandSidebar()
                        onExited: sidebar.scheduleCollapse()
                        onClicked: app.launchDota()
                    }
                }

                // Open Mod Folder
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 24
                    radius: SkinTheme.radiusSmall
                    visible: sidebar.isHovered
                    color: openMouse.containsMouse ? SkinTheme.bgCardHover : "transparent"
                    border.color: SkinTheme.borderMuted
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "📁 OPEN MOD FOLDER"
                        color: openMouse.containsMouse ? SkinTheme.textPrimary : SkinTheme.textMuted
                        font.family: SkinTheme.fontMono
                        font.pixelSize: 9
                        font.bold: true
                        font.letterSpacing: 0.5
                    }

                    MouseArea {
                        id: openMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: sidebar.expandSidebar()
                        onPositionChanged: sidebar.expandSidebar()
                        onExited: sidebar.scheduleCollapse()
                        onClicked: app.openPakFolder()
                    }
                }
            }
        }
    }
}
