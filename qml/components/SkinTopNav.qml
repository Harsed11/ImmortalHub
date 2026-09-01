import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"

Rectangle {
    id: topNav
    height: 56
    color: SkinTheme.bgHeader
    z: 100

    property var rootWindow: null
    property string currentTab: "dashboard"
    property int queueCount: 0
    property int installedCount: 0

    signal tabSelected(string tabId)
    signal queueClicked()
    signal presetsClicked()
    signal playDotaClicked()
    signal searchClicked()
    signal settingsClicked()

    // Bottom border
    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: SkinTheme.borderSubtle
    }

    // Top subtle accent glow line
    Rectangle {
        anchors.top: parent.top
        width: parent.width
        height: 1
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.2; color: SkinTheme.accentCyan }
            GradientStop { position: 0.8; color: SkinTheme.accentCyan }
            GradientStop { position: 1.0; color: "transparent" }
        }
        opacity: 0.4
    }

    // Window Drag Area
    MouseArea {
        id: dragArea
        anchors.fill: parent
        property point clickPos: "0,0"
        onPressed: function(mouse) { clickPos = Qt.point(mouse.x, mouse.y) }
        onPositionChanged: function(mouse) {
            if (pressed && rootWindow) {
                var delta = Qt.point(mouse.x - clickPos.x, mouse.y - clickPos.y)
                rootWindow.x += delta.x
                rootWindow.y += delta.y
            }
        }
        onDoubleClicked: {
            if (rootWindow) {
                if (rootWindow.visibility === Window.Maximized) rootWindow.showNormal()
                else rootWindow.showMaximized()
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 0
        spacing: 12

        // ═══════════════════════════════════════════
        // BRAND & DOTA 2 STATUS (Left)
        // ═══════════════════════════════════════════
        RowLayout {
            spacing: 10

            AegisIcon {
                width: 24
                height: 24
            }

            RowLayout {
                spacing: 2
                Text {
                    text: "IMMORTAL"
                    color: SkinTheme.textPrimary
                    font.family: SkinTheme.fontDisplay
                    font.pixelSize: 14
                    font.bold: true
                    font.letterSpacing: 2.0
                }
                Text {
                    text: "HUB"
                    color: SkinTheme.accentCyan
                    font.family: SkinTheme.fontDisplay
                    font.pixelSize: 14
                    font.bold: true
                    font.letterSpacing: 2.0
                }
            }

            // Dota 2 Status Pill
            Rectangle {
                property bool isLinked: typeof app !== "undefined" && app && app.dotaDetected
                height: 22
                radius: SkinTheme.radiusPill
                implicitWidth: statusPillRow.implicitWidth + 14
                color: isLinked ? SkinTheme.accentEmeraldGlow : SkinTheme.accentCrimsonGlow
                border.color: isLinked ? SkinTheme.accentEmerald : SkinTheme.accentCrimson
                border.width: 1

                RowLayout {
                    id: statusPillRow
                    anchors.centerIn: parent
                    spacing: 5

                    Rectangle {
                        width: 6
                        height: 6
                        radius: 3
                        color: parent.parent.isLinked ? SkinTheme.accentEmerald : SkinTheme.accentCrimson

                        SequentialAnimation on opacity {
                            running: true
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.3; duration: 1200; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 1.0; duration: 1200; easing.type: Easing.InOutSine }
                        }
                    }

                    Text {
                        text: parent.parent.isLinked ? "DOTA 2 LINKED" : "NO GAME PATH"
                        color: parent.parent.isLinked ? SkinTheme.accentEmerald : SkinTheme.accentCrimson
                        font.family: SkinTheme.fontMono
                        font.pixelSize: 8
                        font.bold: true
                        font.letterSpacing: 0.8
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: {
                        if (!parent.isLinked) {
                            topNav.settingsClicked()
                        }
                    }
                }
            }
        }

        Item { Layout.preferredWidth: 8 }

        // ═══════════════════════════════════════════
        // MAIN LAUNCHER TABS (Center)
        // ═══════════════════════════════════════════
        RowLayout {
            spacing: 4

            Repeater {
                model: [
                    { id: "dashboard", label: "DASHBOARD", icon: "\uE80F" },
                    { id: "heroes",    label: "HERO STUDIO", icon: "\uE716" },
                    { id: "effects",   label: "COLLECTIONS", icon: "\uE790" },
                    { id: "creators",  label: "CREATORS VAULT", icon: "\uE77B" },
                    { id: "installed", label: "LOADOUT", icon: "\uE8F1", badge: topNav.installedCount },
                    { id: "fpsboost",  label: "FPS BOOST", icon: "\uE945" }
                ]

                delegate: Rectangle {
                    height: 36
                    radius: SkinTheme.radiusMedium
                    implicitWidth: tabRow.implicitWidth + 24
                    color: topNav.currentTab === modelData.id
                           ? SkinTheme.bgCardHover
                           : (tabMouse.containsMouse ? SkinTheme.bgCard : "transparent")
                    border.color: topNav.currentTab === modelData.id ? SkinTheme.borderLight : "transparent"
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

                    // Bottom glowing indicator bar for active tab
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        height: 2
                        width: topNav.currentTab === modelData.id ? parent.width - 16 : 0
                        radius: 1
                        color: SkinTheme.accentCyan
                        visible: topNav.currentTab === modelData.id

                        Behavior on width { NumberAnimation { duration: SkinTheme.animNormal; easing.type: Easing.OutBack } }

                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width + 6
                            height: 6
                            radius: 3
                            color: SkinTheme.accentCyan
                            opacity: 0.3
                            z: -1
                        }
                    }

                    RowLayout {
                        id: tabRow
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            text: modelData.icon
                            font.family: "Segoe MDL2 Assets"
                            font.pixelSize: 12
                            color: topNav.currentTab === modelData.id
                                   ? SkinTheme.accentCyan
                                   : (tabMouse.containsMouse ? SkinTheme.textPrimary : SkinTheme.textSecondary)

                            Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }
                        }

                        Text {
                            text: modelData.label
                            color: topNav.currentTab === modelData.id
                                   ? SkinTheme.textPrimary
                                   : (tabMouse.containsMouse ? SkinTheme.textPrimary : SkinTheme.textSecondary)
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: SkinTheme.fontSizeSmall
                            font.weight: topNav.currentTab === modelData.id ? Font.Bold : Font.Medium
                            font.letterSpacing: 0.5

                            Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }
                        }

                        // Badge count (for loadout)
                        Rectangle {
                            visible: modelData.badge !== undefined && modelData.badge > 0
                            height: 16
                            radius: SkinTheme.radiusPill
                            implicitWidth: badgeText.implicitWidth + 8
                            color: topNav.currentTab === modelData.id ? SkinTheme.accentEmerald : SkinTheme.bgSurface
                            border.color: SkinTheme.accentEmerald
                            border.width: 1

                            Text {
                                id: badgeText
                                anchors.centerIn: parent
                                text: modelData.badge !== undefined ? modelData.badge.toString() : ""
                                color: topNav.currentTab === modelData.id ? "#FFFFFF" : SkinTheme.accentEmerald
                                font.family: SkinTheme.fontMono
                                font.pixelSize: 8
                                font.bold: true
                            }
                        }
                    }

                    MouseArea {
                        id: tabMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            topNav.currentTab = modelData.id
                            topNav.tabSelected(modelData.id)
                        }
                    }
                }
            }
        }

        Item { Layout.fillWidth: true }

        // ═══════════════════════════════════════════
        // ACTION CONTROLS (Right)
        // ═══════════════════════════════════════════
        RowLayout {
            spacing: 8

            // Search Button (Ctrl+K)
            Rectangle {
                height: 32
                width: 170
                radius: SkinTheme.radiusMedium
                color: searchBtnMouse.containsMouse ? SkinTheme.bgCardHover : SkinTheme.bgInput
                border.color: searchBtnMouse.containsMouse ? SkinTheme.accentCyan : SkinTheme.borderMuted
                border.width: 1

                Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }
                Behavior on border.color { ColorAnimation { duration: SkinTheme.animFast } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 8
                    spacing: 6

                    Text {
                        text: "\uE721"
                        font.family: "Segoe MDL2 Assets"
                        font.pixelSize: 11
                        color: SkinTheme.textMuted
                    }

                    Text {
                        text: "Search..."
                        color: SkinTheme.textMuted
                        font.family: SkinTheme.fontFamily
                        font.pixelSize: SkinTheme.fontSizeSmall
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        width: 38
                        height: 18
                        radius: 4
                        color: SkinTheme.bgCard
                        border.color: SkinTheme.borderMuted
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "Ctrl K"
                            color: SkinTheme.textMuted
                            font.family: SkinTheme.fontMono
                            font.pixelSize: 8
                            font.bold: true
                        }
                    }
                }

                MouseArea {
                    id: searchBtnMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: topNav.searchClicked()
                }
            }

            // Queue Button
            Rectangle {
                height: 32
                radius: SkinTheme.radiusMedium
                implicitWidth: queueBtnRow.implicitWidth + 20
                color: queueCount > 0
                       ? (queueBtnMouse.containsMouse ? SkinTheme.accentCyanHover : SkinTheme.accentCyan)
                       : (queueBtnMouse.containsMouse ? SkinTheme.bgCardHover : "transparent")
                border.color: queueCount > 0 ? "transparent" : (queueBtnMouse.containsMouse ? SkinTheme.borderActive : SkinTheme.borderMuted)
                border.width: 1

                Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

                RowLayout {
                    id: queueBtnRow
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: "\uE896"
                        font.family: "Segoe MDL2 Assets"
                        font.pixelSize: 11
                        color: queueCount > 0 ? "#FFFFFF" : (queueBtnMouse.containsMouse ? SkinTheme.textPrimary : SkinTheme.textSecondary)
                    }

                    Text {
                        text: queueCount > 0 ? "QUEUE " + queueCount : "QUEUE"
                        color: queueCount > 0 ? "#FFFFFF" : (queueBtnMouse.containsMouse ? SkinTheme.textPrimary : SkinTheme.textSecondary)
                        font.family: SkinTheme.fontFamily
                        font.pixelSize: SkinTheme.fontSizeSmall
                        font.bold: true
                        font.letterSpacing: 0.5
                    }
                }

                MouseArea {
                    id: queueBtnMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: topNav.queueClicked()
                }
            }

            // Settings Button
            Rectangle {
                height: 32
                width: 32
                radius: SkinTheme.radiusMedium
                color: topNav.currentTab === "settings" || settingsBtnMouse.containsMouse ? SkinTheme.bgCardHover : "transparent"
                border.color: topNav.currentTab === "settings" ? SkinTheme.accentCyan : SkinTheme.borderMuted
                border.width: 1

                Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

                Text {
                    anchors.centerIn: parent
                    text: "\uE713"
                    font.family: "Segoe MDL2 Assets"
                    font.pixelSize: 13
                    color: topNav.currentTab === "settings" || settingsBtnMouse.containsMouse ? SkinTheme.textPrimary : SkinTheme.textSecondary
                }

                MouseArea {
                    id: settingsBtnMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        topNav.currentTab = "settings"
                        topNav.settingsClicked()
                    }
                }
            }

            // Big Liquid PLAY DOTA 2 Button
            Rectangle {
                height: 34
                radius: SkinTheme.radiusMedium
                implicitWidth: playRow.implicitWidth + 24
                color: playDotaMouse.containsMouse ? SkinTheme.accentEmeraldHover : SkinTheme.accentEmerald

                Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

                // Outer ambient glow
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width + 6
                    height: parent.height + 6
                    radius: parent.radius + 3
                    color: SkinTheme.accentEmerald
                    opacity: playDotaMouse.containsMouse ? 0.35 : 0.15
                    z: -1
                    Behavior on opacity { NumberAnimation { duration: SkinTheme.animFast } }
                }

                RowLayout {
                    id: playRow
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: "▶"
                        color: "#FFFFFF"
                        font.pixelSize: 10
                    }

                    Text {
                        text: "PLAY DOTA 2"
                        color: "#FFFFFF"
                        font.family: SkinTheme.fontFamily
                        font.pixelSize: SkinTheme.fontSizeSmall
                        font.bold: true
                        font.letterSpacing: 0.8
                    }
                }

                MouseArea {
                    id: playDotaMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: topNav.playDotaClicked()
                }
            }
        }

        // ═══════════════════════════════════════════
        // WINDOW CONTROLS
        // ═══════════════════════════════════════════
        RowLayout {
            spacing: 0

            Repeater {
                model: [
                    { sym: "\uE921", action: "min" },
                    { sym: "\uE922", action: "max" },
                    { sym: "\uE8BB", action: "close" }
                ]

                delegate: Rectangle {
                    width: 44
                    height: 56
                    color: {
                        if (!wcMouse.containsMouse) return "transparent"
                        if (modelData.action === "close") return "#E23B3B"
                        return SkinTheme.bgCardHover
                    }

                    Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

                    Text {
                        anchors.centerIn: parent
                        text: modelData.action === "max" && rootWindow && rootWindow.visibility === Window.Maximized ? "\uE923" : modelData.sym
                        color: wcMouse.containsMouse ? "#FFFFFF" : SkinTheme.textMuted
                        font.family: "Segoe MDL2 Assets"
                        font.pixelSize: 10

                        Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }
                    }

                    MouseArea {
                        id: wcMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (modelData.action === "min") rootWindow.showMinimized()
                            else if (modelData.action === "max") {
                                if (rootWindow.visibility === Window.Maximized) rootWindow.showNormal()
                                else rootWindow.showMaximized()
                            }
                            else if (modelData.action === "close") rootWindow.close()
                        }
                    }
                }
            }
        }
    }
}
