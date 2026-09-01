import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"

Rectangle {
    id: sidebar
    width: isExpanded ? SkinTheme.sidebarExpanded : SkinTheme.sidebarCollapsed
    implicitWidth: width
    Layout.preferredWidth: width
    Layout.minimumWidth: width
    Layout.maximumWidth: width
    color: SkinTheme.bgSidebar
    z: 20
    clip: true

    property string currentTab: "dashboard"
    property bool isExpanded: true
    signal tabSelected(string tabId)

    Behavior on width {
        NumberAnimation { duration: SkinTheme.animNormal; easing.type: Easing.OutCubic }
    }

    // Right border
    Rectangle {
        anchors.right: parent.right
        width: 1
        height: parent.height
        color: SkinTheme.borderSubtle
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Top spacer
        Item { Layout.preferredHeight: 10 }

        // ─── BROWSE Section Header ───
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            Layout.leftMargin: 18

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "BROWSE"
                color: SkinTheme.textMuted
                font.family: SkinTheme.fontMono
                font.pixelSize: SkinTheme.fontSizeTiny
                font.bold: true
                font.letterSpacing: 2.0
                opacity: sidebar.isExpanded ? 1.0 : 0.0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: SkinTheme.animFast } }
            }
        }

        // ─── Browse Navigation Items ───
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Layout.leftMargin: 6
            Layout.rightMargin: 6

            Repeater {
                model: [
                    { id: "dashboard", label: app.uiLanguage.length && app.t("nav.dashboard"), icon: "\uE80F" },
                    { id: "heroes",    label: app.uiLanguage.length && app.t("nav.heroes"),    icon: "\uE716" },
                    { id: "favorites", label: app.uiLanguage.length && app.t("nav.favorites"), icon: "\uE734" },
                    { id: "creators",  label: app.uiLanguage.length && app.t("nav.creators"),  icon: "\uE77B" },
                    { id: "effects",   label: app.uiLanguage.length && app.t("nav.effects"),   icon: "\uE790" },
                    { id: "map",       label: app.uiLanguage.length && app.t("nav.map"),       icon: "\uE774" },
                    { id: "audio",     label: app.uiLanguage.length && app.t("nav.audio"),     icon: "\uE8D6" },
                    { id: "misc",      label: app.uiLanguage.length && app.t("nav.misc"),      icon: "\uE71D" }
                ]

                delegate: Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    radius: SkinTheme.radiusMedium
                    color: sidebar.currentTab === modelData.id
                           ? SkinTheme.bgCardHover
                           : (navMouse.containsMouse ? SkinTheme.bgCard : "transparent")

                    Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

                    // Active indicator — left accent bar
                    Rectangle {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: 3
                        height: sidebar.currentTab === modelData.id ? 22 : 0
                        radius: 2
                        color: SkinTheme.accentCyan

                        Behavior on height { NumberAnimation { duration: SkinTheme.animNormal; easing.type: Easing.OutBack } }

                        // Subtle glow
                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width + 6
                            height: parent.height + 6
                            radius: parent.radius + 3
                            color: SkinTheme.accentCyan
                            opacity: 0.15
                            z: -1
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 10
                        spacing: 12

                        // Icon
                        Item {
                            Layout.preferredWidth: 22
                            Layout.preferredHeight: 22
                            Layout.alignment: Qt.AlignVCenter

                            Text {
                                anchors.centerIn: parent
                                text: modelData.icon
                                font.family: "Segoe MDL2 Assets"
                                font.pixelSize: 14
                                color: sidebar.currentTab === modelData.id
                                       ? SkinTheme.accentCyan
                                       : (navMouse.containsMouse ? SkinTheme.textPrimary : SkinTheme.textSecondary)

                                Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }
                            }
                        }

                        // Label
                        Text {
                            text: modelData.label
                            color: sidebar.currentTab === modelData.id
                                   ? SkinTheme.textPrimary
                                   : (navMouse.containsMouse ? SkinTheme.textPrimary : SkinTheme.textSecondary)
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: SkinTheme.fontSizeBody
                            font.weight: sidebar.currentTab === modelData.id ? Font.DemiBold : Font.Medium
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            opacity: sidebar.isExpanded ? 1.0 : 0.0
                            visible: opacity > 0

                            Behavior on opacity { NumberAnimation { duration: SkinTheme.animFast } }
                            Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }
                        }
                    }

                    MouseArea {
                        id: navMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            sidebar.currentTab = modelData.id
                            sidebar.tabSelected(modelData.id)
                        }
                    }
                }
            }
        }

        // ─── SYSTEM Section ───
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            Layout.topMargin: 12
            Layout.leftMargin: 18

            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.rightMargin: 12
                height: 1
                color: SkinTheme.borderSubtle
            }

            Text {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                text: "SYSTEM"
                color: SkinTheme.textMuted
                font.family: SkinTheme.fontMono
                font.pixelSize: SkinTheme.fontSizeTiny
                font.bold: true
                font.letterSpacing: 2.0
                opacity: sidebar.isExpanded ? 1.0 : 0.0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: SkinTheme.animFast } }
            }
        }

        // ─── System Navigation Items ───
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Layout.leftMargin: 6
            Layout.rightMargin: 6

            Repeater {
                model: [
                    { id: "fpsboost",  label: app.uiLanguage.length && app.t("nav.fpsboost"),  icon: "\uE945", accent: SkinTheme.accentAmber },
                    { id: "installed", label: app.uiLanguage.length && app.t("nav.installed"), icon: "\uE8F1", accent: SkinTheme.accentEmerald, badge: app.installedCount },
                    { id: "settings",  label: app.uiLanguage.length && app.t("nav.settings"),  icon: "\uE713", accent: "", badge: 0 }
                ]

                delegate: Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    radius: SkinTheme.radiusMedium
                    color: sidebar.currentTab === modelData.id
                           ? SkinTheme.bgCardHover
                           : (toolNavMouse.containsMouse ? SkinTheme.bgCard : "transparent")

                    Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

                    // Active indicator
                    Rectangle {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: 3
                        height: sidebar.currentTab === modelData.id ? 22 : 0
                        radius: 2
                        color: modelData.accent || SkinTheme.accentViolet

                        Behavior on height { NumberAnimation { duration: SkinTheme.animNormal; easing.type: Easing.OutBack } }

                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width + 6
                            height: parent.height + 6
                            radius: parent.radius + 3
                            color: parent.color
                            opacity: 0.15
                            z: -1
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 10
                        spacing: 12

                        Item {
                            Layout.preferredWidth: 22
                            Layout.preferredHeight: 22
                            Layout.alignment: Qt.AlignVCenter

                            Text {
                                anchors.centerIn: parent
                                text: modelData.icon
                                font.family: "Segoe MDL2 Assets"
                                font.pixelSize: 14
                                color: sidebar.currentTab === modelData.id
                                       ? (modelData.accent || SkinTheme.accentViolet)
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
                            font.pixelSize: SkinTheme.fontSizeBody
                            font.weight: sidebar.currentTab === modelData.id ? Font.DemiBold : Font.Medium
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            opacity: sidebar.isExpanded ? 1.0 : 0.0
                            visible: opacity > 0

                            Behavior on opacity { NumberAnimation { duration: SkinTheme.animFast } }
                            Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }
                        }

                        // Badge counter (installed count)
                        Rectangle {
                            visible: sidebar.isExpanded && modelData.badge !== undefined && modelData.badge > 0
                            width: badgeText.implicitWidth + 10
                            height: 18
                            radius: SkinTheme.radiusPill
                            color: SkinTheme.bgSurface
                            border.color: SkinTheme.borderMuted
                            border.width: 1

                            Text {
                                id: badgeText
                                anchors.centerIn: parent
                                text: modelData.badge !== undefined ? modelData.badge.toString() : ""
                                color: modelData.accent || SkinTheme.textSecondary
                                font.family: SkinTheme.fontMono
                                font.pixelSize: 9
                                font.bold: true
                            }
                        }
                    }

                    MouseArea {
                        id: toolNavMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            sidebar.currentTab = modelData.id
                            sidebar.tabSelected(modelData.id)
                        }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }

        // ─── Collapse Toggle ───
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            Layout.leftMargin: 6
            Layout.rightMargin: 6
            Layout.bottomMargin: 4
            radius: SkinTheme.radiusMedium
            color: collapseMouse.containsMouse ? SkinTheme.bgCard : "transparent"

            Text {
                anchors.centerIn: parent
                text: sidebar.isExpanded ? "\uE76B" : "\uE76C"
                font.family: "Segoe MDL2 Assets"
                font.pixelSize: 12
                color: SkinTheme.textMuted
            }

            MouseArea {
                id: collapseMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: sidebar.isExpanded = !sidebar.isExpanded
            }
        }

        // ─── Bottom Status Card ───
        Rectangle {
            Layout.fillWidth: true
            Layout.margins: 6
            Layout.preferredHeight: sidebar.isExpanded ? 100 : 48
            radius: SkinTheme.radiusMedium
            color: SkinTheme.bgCard
            border.color: SkinTheme.borderMuted
            border.width: 1
            clip: true

            Behavior on Layout.preferredHeight { NumberAnimation { duration: SkinTheme.animNormal } }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: sidebar.isExpanded ? 10 : 6
                spacing: 6

                // Dota status
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        color: app.dotaDetected ? SkinTheme.accentEmerald : SkinTheme.accentCrimson

                        SequentialAnimation on opacity {
                            running: true
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.4; duration: 1500; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 1.0; duration: 1500; easing.type: Easing.InOutSine }
                        }
                    }

                    Text {
                        text: sidebar.isExpanded ? (app.dotaDetected ? "DOTA 2 LINKED" : "NO GAME PATH") : ""
                        color: app.dotaDetected ? SkinTheme.accentEmerald : SkinTheme.accentCrimson
                        font.family: SkinTheme.fontMono
                        font.pixelSize: SkinTheme.fontSizeLabel
                        font.bold: true
                        font.letterSpacing: 1.0
                        Layout.fillWidth: true
                        opacity: sidebar.isExpanded ? 1.0 : 0.0
                        visible: opacity > 0
                        Behavior on opacity { NumberAnimation { duration: SkinTheme.animFast } }
                    }

                    Text {
                        text: sidebar.isExpanded ? (app.installedCount + " MODS") : ""
                        color: app.installedCount > 0 ? SkinTheme.accentEmerald : SkinTheme.textMuted
                        font.family: SkinTheme.fontMono
                        font.pixelSize: 9
                        font.bold: true
                        visible: sidebar.isExpanded
                    }
                }

                // Separator
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: SkinTheme.borderSubtle
                    visible: sidebar.isExpanded
                }

                // Launch Dota button
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 28
                    radius: SkinTheme.radiusSmall
                    visible: sidebar.isExpanded && app.dotaDetected
                    color: launchMouse.containsMouse ? SkinTheme.accentCyanGlow : SkinTheme.bgDark
                    border.color: SkinTheme.accentCyan
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: app.uiLanguage.length && app.t("status.launch")
                        color: SkinTheme.accentCyan
                        font.family: SkinTheme.fontFamily
                        font.pixelSize: SkinTheme.fontSizeLabel
                        font.bold: true
                        font.letterSpacing: 1.0
                    }

                    MouseArea {
                        id: launchMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: app.launchDota()
                    }
                }

                // Open Mod Folder
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 24
                    radius: SkinTheme.radiusSmall
                    visible: sidebar.isExpanded
                    color: openMouse.containsMouse ? SkinTheme.bgCardHover : "transparent"
                    border.color: SkinTheme.borderMuted
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: app.uiLanguage.length && app.t("status.open_folder")
                        color: openMouse.containsMouse ? SkinTheme.textPrimary : SkinTheme.textMuted
                        font.family: SkinTheme.fontFamily
                        font.pixelSize: 9
                        font.bold: true
                    }

                    MouseArea {
                        id: openMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: app.openPakFolder()
                    }
                }
            }
        }
    }
}
