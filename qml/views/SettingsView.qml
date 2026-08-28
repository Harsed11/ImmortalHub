import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"
import "../components"

Item {
    id: settingsViewRoot
    anchors.fill: parent

    Flickable {
        id: flick
        anchors.fill: parent
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        anchors.topMargin: 20
        anchors.bottomMargin: 24
        contentWidth: width
        contentHeight: settingsCol.implicitHeight + 40
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            width: 8
            contentItem: Rectangle {
                radius: 4
                color: SkinTheme.accentCyan
                opacity: 0.4
            }
        }

        ColumnLayout {
            id: settingsCol
            width: flick.width
            spacing: 22

            // Header Title
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                RowLayout {
                    spacing: 10
                    Text {
                        text: "⚙"
                        font.pixelSize: 22
                    }
                    Text {
                        text: "Settings & System Configuration"
                        color: SkinTheme.textPrimary
                        font.family: SkinTheme.fontFamily
                        font.pixelSize: SkinTheme.fontSizeHeader
                        font.bold: true
                    }
                }

                Text {
                    text: "Configure Dota 2 game path, installation target language, Source 2 search paths, and system preferences."
                    color: SkinTheme.textMuted
                    font.family: SkinTheme.fontFamily
                    font.pixelSize: SkinTheme.fontSizeBody
                }
            }

            // 0. Premium Stats & Savings
            Rectangle {
                Layout.fillWidth: true
                height: 100
                radius: SkinTheme.radiusXLarge
                color: SkinTheme.bgCard
                border.color: SkinTheme.borderMuted
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 20

                    Rectangle {
                        width: 60
                        height: 60
                        radius: 30
                        color: SkinTheme.bgGlass
                        border.color: SkinTheme.accentViolet
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "💰"
                            font.pixelSize: 28
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Text {
                            text: "MONEY SAVED WITH IMMORTALHUB"
                            color: SkinTheme.accentViolet
                            font.family: SkinTheme.fontMono
                            font.pixelSize: 12
                            font.bold: true
                            font.letterSpacing: 1.5
                        }

                        RowLayout {
                            spacing: 8
                            Text {
                                text: "$" + (typeof app !== "undefined" && app ? app.totalSavings : "0")
                                color: SkinTheme.textPrimary
                                font.family: SkinTheme.fontDisplay
                                font.pixelSize: 36
                                font.bold: true
                            }
                            Text {
                                text: ".00"
                                color: SkinTheme.textMuted
                                font.family: SkinTheme.fontDisplay
                                font.pixelSize: 24
                                font.bold: true
                                Layout.alignment: Qt.AlignBottom
                                Layout.bottomMargin: 4
                            }
                        }
                    }
                }
            }

            // 0.5 Visual Theme Section
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: themeCol.implicitHeight + 40
                radius: SkinTheme.radiusXLarge
                color: SkinTheme.bgCard
                border.color: SkinTheme.borderMuted
                border.width: 1

                ColumnLayout {
                    id: themeCol
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 16

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Text {
                            text: "🎨"
                            font.pixelSize: 18
                        }

                        Text {
                            text: "Visual Theme"
                            color: SkinTheme.textPrimary
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: SkinTheme.fontSizeTitle
                            font.bold: true
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Repeater {
                            model: [
                                { id: "cyberpunk", name: "Cyberpunk", color: "#00F0FF", icon: "🤖" },
                                { id: "dire", name: "Dire Crimson", color: "#FF0033", icon: "🌋" },
                                { id: "radiant", name: "Radiant Emerald", color: "#00FFAA", icon: "🌿" },
                                { id: "true_black", name: "True Black", color: "#FFFFFF", icon: "🌑" }
                            ]
                            
                            Rectangle {
                                Layout.fillWidth: true
                                height: 80
                                radius: SkinTheme.radiusLarge
                                color: (typeof app !== "undefined" && app && app.themeMode === modelData.id) ? SkinTheme.bgCardActive : SkinTheme.bgInput
                                border.color: (typeof app !== "undefined" && app && app.themeMode === modelData.id) ? modelData.color : SkinTheme.borderMuted
                                border.width: (typeof app !== "undefined" && app && app.themeMode === modelData.id) ? 2 : 1
                                
                                Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }
                                Behavior on border.color { ColorAnimation { duration: SkinTheme.animFast } }

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 8
                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: modelData.icon
                                        font.pixelSize: 24
                                    }
                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: modelData.name
                                        color: (typeof app !== "undefined" && app && app.themeMode === modelData.id) ? modelData.color : SkinTheme.textSecondary
                                        font.family: SkinTheme.fontFamily
                                        font.pixelSize: SkinTheme.fontSizeSmall
                                        font.bold: true
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (app) app.themeMode = modelData.id
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // 1. Dota 2 Path Section Card
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: dotaSectionCol.implicitHeight + 40
                radius: SkinTheme.radiusXLarge
                color: SkinTheme.bgCard
                border.color: SkinTheme.borderMuted
                border.width: 1

                ColumnLayout {
                    id: dotaSectionCol
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 16

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Text {
                            text: "🎮"
                            font.pixelSize: 18
                        }

                        Text {
                            text: "Dota 2 Game Directory"
                            color: SkinTheme.textPrimary
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: SkinTheme.fontSizeTitle
                            font.bold: true
                        }

                        Item { Layout.fillWidth: true }

                        // Validation badge
                        Rectangle {
                            height: 24
                            radius: 12
                            implicitWidth: valBadgeText.implicitWidth + 20
                            color: (typeof app !== "undefined" && app && app.dotaDetected) ? "#122e23" : "#38171c"
                            border.color: (typeof app !== "undefined" && app && app.dotaDetected) ? SkinTheme.accentEmerald : SkinTheme.accentCrimson
                            border.width: 1

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6
                                Rectangle {
                                    width: 6
                                    height: 6
                                    radius: 3
                                    color: (typeof app !== "undefined" && app && app.dotaDetected) ? SkinTheme.accentEmerald : SkinTheme.accentCrimson
                                }
                                Text {
                                    id: valBadgeText
                                    text: (typeof app !== "undefined" && app && app.dotaDetected) ? "Game Detected вњ“" : "Game Not Found"
                                    color: (typeof app !== "undefined" && app && app.dotaDetected) ? SkinTheme.accentEmerald : SkinTheme.accentCrimson
                                    font.family: SkinTheme.fontFamily
                                    font.pixelSize: 10
                                    font.bold: true
                                }
                            }
                        }
                    }

                    Text {
                        text: "Directory should point to your Dota 2 'game' folder (e.g. C:/Program Files (x86)/Steam/steamapps/common/dota 2 beta/game)"
                        color: SkinTheme.textMuted
                        font.family: SkinTheme.fontFamily
                        font.pixelSize: SkinTheme.fontSizeSmall
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }

                    // Path Input Field
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        radius: SkinTheme.radiusMedium
                        color: SkinTheme.bgInput
                        border.color: pathInput.activeFocus ? SkinTheme.accentCyan : SkinTheme.borderMuted
                        border.width: 1

                        TextInput {
                            id: pathInput
                            anchors.fill: parent
                            anchors.margins: 12
                            color: SkinTheme.textPrimary
                            font.family: "Consolas, monospace"
                            font.pixelSize: 12
                            clip: true
                            selectByMouse: true
                            text: (typeof app !== "undefined" && app) ? app.dotaPath : ""

                            onTextChanged: {
                                if (typeof app !== "undefined" && app && text !== app.dotaPath) {
                                    app.dotaPath = text
                                }
                            }
                        }
                    }

                    // Action Buttons
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        // Auto-Detect Button
                        Rectangle {
                            Layout.preferredHeight: 38
                            implicitWidth: autoText.implicitWidth + 28
                            radius: SkinTheme.radiusMedium
                            color: autoMouse.containsMouse ? SkinTheme.accentCyanHover : SkinTheme.accentCyan

                            RowLayout {
                                id: autoText
                                anchors.centerIn: parent
                                spacing: 8
                                Text { text: "⚡"; font.pixelSize: 12 }
                                Text {
                                    text: "Auto-Detect Dota 2"
                                    color: "#000000"
                                    font.family: SkinTheme.fontFamily
                                    font.pixelSize: 12
                                    font.bold: true
                                }
                            }

                            MouseArea {
                                id: autoMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: app.autoDetectDotaPath()
                            }
                        }

                        // Browse Button
                        Rectangle {
                            Layout.preferredHeight: 38
                            implicitWidth: browseText.implicitWidth + 28
                            radius: SkinTheme.radiusMedium
                            color: browseMouse.containsMouse ? SkinTheme.bgCardHover : SkinTheme.bgDark
                            border.color: SkinTheme.borderMuted
                            border.width: 1

                            RowLayout {
                                id: browseText
                                anchors.centerIn: parent
                                spacing: 8
                                Text { text: "📁"; font.pixelSize: 12 }
                                Text {
                                    text: "Browse Folder..."
                                    color: SkinTheme.textPrimary
                                    font.family: SkinTheme.fontFamily
                                    font.pixelSize: 12
                                    font.bold: true
                                }
                            }

                            MouseArea {
                                id: browseMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: app.browseDotaPath()
                            }
                        }

                        // Open Pak Folder Button
                        Rectangle {
                            Layout.preferredHeight: 38
                            implicitWidth: openPakText.implicitWidth + 28
                            radius: SkinTheme.radiusMedium
                            color: openPakMouse.containsMouse ? SkinTheme.bgCardHover : SkinTheme.bgDark
                            border.color: SkinTheme.borderMuted
                            border.width: 1

                            RowLayout {
                                id: openPakText
                                anchors.centerIn: parent
                                spacing: 8
                                Text { text: "📂"; font.pixelSize: 12 }
                                Text {
                                    text: "Open Mod Folder"
                                    color: SkinTheme.textPrimary
                                    font.family: SkinTheme.fontFamily
                                    font.pixelSize: 12
                                    font.bold: true
                                }
                            }

                            MouseArea {
                                id: openPakMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: app.openPakFolder()
                            }
                        }

                        Item { Layout.fillWidth: true }
                    }
                }
            }

            // 1.5 Advanced Launch Options
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: launchSectionCol.implicitHeight + 40
                radius: SkinTheme.radiusXLarge
                color: SkinTheme.bgCard
                border.color: SkinTheme.borderMuted
                border.width: 1

                ColumnLayout {
                    id: launchSectionCol
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 16

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Text {
                            text: "🚀"
                            font.pixelSize: 18
                        }

                        Text {
                            text: "Advanced Launch Options"
                            color: SkinTheme.textPrimary
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: SkinTheme.fontSizeTitle
                            font.bold: true
                        }
                    }

                    Text {
                        text: "Add custom parameters when starting Dota 2 via the Play button (e.g., '-novid -console -dx11')."
                        color: SkinTheme.textMuted
                        font.family: SkinTheme.fontFamily
                        font.pixelSize: SkinTheme.fontSizeSmall
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }

                    // Launch Options Input Field
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        radius: SkinTheme.radiusMedium
                        color: SkinTheme.bgInput
                        border.color: launchInput.activeFocus ? SkinTheme.accentCyan : SkinTheme.borderMuted
                        border.width: 1

                        TextInput {
                            id: launchInput
                            anchors.fill: parent
                            anchors.margins: 12
                            color: SkinTheme.textPrimary
                            font.family: "Consolas, monospace"
                            font.pixelSize: 12
                            clip: true
                            selectByMouse: true
                            text: (typeof app !== "undefined" && app) ? app.launchOptions : ""

                            onEditingFinished: {
                                if (typeof app !== "undefined" && app && text !== app.launchOptions) {
                                    app.launchOptions = text
                                }
                            }
                        }
                    }
                }
            }

            // 2. Language & Target Folder Section Card
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: langSectionCol.implicitHeight + 40
                radius: SkinTheme.radiusXLarge
                color: SkinTheme.bgCard
                border.color: SkinTheme.borderMuted
                border.width: 1

                ColumnLayout {
                    id: langSectionCol
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 16

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Text {
                            text: "🌐"
                            font.pixelSize: 18
                        }

                        Text {
                            text: "Installation Target Language"
                            color: SkinTheme.textPrimary
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: SkinTheme.fontSizeTitle
                            font.bold: true
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            height: 22
                            radius: 11
                            implicitWidth: curLangPill.implicitWidth + 16
                            color: "#182236"
                            border.color: SkinTheme.accentCyan
                            border.width: 1

                            Text {
                                id: curLangPill
                                anchors.centerIn: parent
                                text: "Active: " + ((typeof app !== "undefined" && app) ? app.installLanguage.toUpperCase() : "BOTH")
                                color: SkinTheme.accentCyan
                                font.family: SkinTheme.fontFamily
                                font.pixelSize: 10
                                font.bold: true
                            }
                        }
                    }

                    Text {
                        text: "VPK files, hero skins, and audio packs are placed in 'dota 2 beta/game/dota_russian' or 'dota 2 beta/game/dota'. " +
                              "Selecting 'All / Both' installs files to both directories, ensuring all skins and sound packs work seamlessly regardless of your Steam language settings."
                        color: SkinTheme.textMuted
                        font.family: SkinTheme.fontFamily
                        font.pixelSize: SkinTheme.fontSizeSmall
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }

                    // Language Choice Cards
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Repeater {
                            model: (typeof app !== "undefined" && app) ? app.availableLanguages : []

                            delegate: Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 50
                                radius: SkinTheme.radiusMedium
                                color: (typeof app !== "undefined" && app && app.installLanguage === modelData.id)
                                       ? "#192842"
                                       : (langOptMouse.containsMouse ? SkinTheme.bgCardHover : SkinTheme.bgDark)
                                border.color: (typeof app !== "undefined" && app && app.installLanguage === modelData.id)
                                              ? SkinTheme.accentCyan
                                              : SkinTheme.borderMuted
                                border.width: 1

                                Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 16
                                    spacing: 12

                                    // Radio Circle
                                    Rectangle {
                                        width: 18
                                        height: 18
                                        radius: 9
                                        color: "transparent"
                                        border.color: (typeof app !== "undefined" && app && app.installLanguage === modelData.id) ? SkinTheme.accentCyan : SkinTheme.borderActive
                                        border.width: 2

                                        Rectangle {
                                            anchors.centerIn: parent
                                            width: 8
                                            height: 8
                                            radius: 4
                                            color: SkinTheme.accentCyan
                                            visible: typeof app !== "undefined" && app && app.installLanguage === modelData.id
                                        }
                                    }

                                    Text {
                                        text: modelData.emoji
                                        font.pixelSize: 18
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        Text {
                                            text: modelData.name
                                            color: (typeof app !== "undefined" && app && app.installLanguage === modelData.id) ? SkinTheme.textPrimary : SkinTheme.textSecondary
                                            font.family: SkinTheme.fontFamily
                                            font.pixelSize: 12
                                            font.bold: typeof app !== "undefined" && app && app.installLanguage === modelData.id
                                        }

                                        Text {
                                            text: modelData.id === "both"
                                                  ? "Installs directly into game/dota and game/dota_russian (Recommended)"
                                                  : "Installs directly into game/" + modelData.folder
                                            color: SkinTheme.textMuted
                                            font.family: SkinTheme.fontFamily
                                            font.pixelSize: 10
                                        }
                                    }

                                    Rectangle {
                                        height: 20
                                        radius: 4
                                        implicitWidth: recBadge.implicitWidth + 10
                                        color: "#28200d"
                                        border.color: SkinTheme.accentCyan
                                        border.width: 1
                                        visible: modelData.id === "both"

                                        Text {
                                            id: recBadge
                                            anchors.centerIn: parent
                                            text: "RECOMMENDED"
                                            color: SkinTheme.accentCyan
                                            font.family: SkinTheme.fontFamily
                                            font.pixelSize: 9
                                            font.bold: true
                                        }
                                    }
                                }

                                MouseArea {
                                    id: langOptMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: app.setInstallLanguage(modelData.id)
                                }
                            }
                        }
                    }
                }
            }

            // 4. Source 2 Mod Search Paths (gameinfo.gi) Card
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: giSectionCol.implicitHeight + 40
                radius: SkinTheme.radiusXLarge
                color: SkinTheme.bgCard
                border.color: SkinTheme.borderMuted
                border.width: 1

                ColumnLayout {
                    id: giSectionCol
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 16

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Text {
                            text: "⚙"
                            font.pixelSize: 18
                        }

                        Text {
                            text: "Source 2 Search Paths (gameinfo.gi)"
                            color: SkinTheme.textPrimary
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: SkinTheme.fontSizeTitle
                            font.bold: true
                        }

                        Item { Layout.fillWidth: true }

                        // Validation badge
                        Rectangle {
                            height: 24
                            radius: 12
                            implicitWidth: giBadgeText.implicitWidth + 20
                            color: (typeof app !== "undefined" && app && app.gameinfoPatched) ? "#122e23" : "#2e2412"
                            border.color: (typeof app !== "undefined" && app && app.gameinfoPatched) ? SkinTheme.accentEmerald : SkinTheme.accentCyan
                            border.width: 1

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6
                                Rectangle {
                                    width: 6
                                    height: 6
                                    radius: 3
                                    color: (typeof app !== "undefined" && app && app.gameinfoPatched) ? SkinTheme.accentEmerald : SkinTheme.accentCyan
                                }
                                Text {
                                    id: giBadgeText
                                    text: (typeof app !== "undefined" && app && app.gameinfoPatched) ? "Search Paths Active" : "Default (Unpatched)"
                                    color: (typeof app !== "undefined" && app && app.gameinfoPatched) ? SkinTheme.accentEmerald : SkinTheme.accentCyan
                                    font.family: SkinTheme.fontFamily
                                    font.pixelSize: 10
                                    font.bold: true
                                }
                            }
                        }
                    }

                    Text {
                        text: "Patching gameinfo.gi ensures Source 2 prioritizes your custom skins and sounds over default assets. " +
                              "A safe backup (gameinfo.gi.bak) is automatically created before any modification."
                        color: SkinTheme.textMuted
                        font.family: SkinTheme.fontFamily
                        font.pixelSize: SkinTheme.fontSizeSmall
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        // Patch Button
                        Rectangle {
                            Layout.preferredHeight: 38
                            implicitWidth: patchGiText.implicitWidth + 28
                            radius: SkinTheme.radiusMedium
                            color: (typeof app !== "undefined" && app && app.gameinfoPatched)
                                   ? SkinTheme.borderMuted
                                   : (patchGiMouse.containsMouse ? SkinTheme.accentEmeraldHover : SkinTheme.accentEmerald)
                            enabled: typeof app !== "undefined" && app && !app.gameinfoPatched && app.dotaDetected

                            RowLayout {
                                id: patchGiText
                                anchors.centerIn: parent
                                spacing: 8
                                Text { text: "⚡"; font.pixelSize: 12 }
                                Text {
                                    text: (typeof app !== "undefined" && app && app.gameinfoPatched) ? "Already Patched вњ“" : "Patch gameinfo.gi"
                                    color: (typeof app !== "undefined" && app && app.gameinfoPatched) ? SkinTheme.textMuted : "#000000"
                                    font.family: SkinTheme.fontFamily
                                    font.pixelSize: 12
                                    font.bold: true
                                }
                            }

                            MouseArea {
                                id: patchGiMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: app.patchGameinfo()
                            }
                        }

                        // Restore Button
                        Rectangle {
                            Layout.preferredHeight: 38
                            implicitWidth: restGiText.implicitWidth + 28
                            radius: SkinTheme.radiusMedium
                            color: restGiMouse.containsMouse ? SkinTheme.bgCardHover : SkinTheme.bgDark
                            border.color: SkinTheme.borderMuted
                            border.width: 1
                            visible: typeof app !== "undefined" && app && app.gameinfoPatched

                            RowLayout {
                                id: restGiText
                                anchors.centerIn: parent
                                spacing: 8
                                Text { text: "в†©пёЏ"; font.pixelSize: 12 }
                                Text {
                                    text: "Restore Default"
                                    color: SkinTheme.textPrimary
                                    font.family: SkinTheme.fontFamily
                                    font.pixelSize: 12
                                    font.bold: true
                                }
                            }

                            MouseArea {
                                id: restGiMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: app.restoreGameinfo()
                            }
                        }

                        Item { Layout.fillWidth: true }
                    }
                }
            }

            // 4. Overplus Live Match & In-Game Overlay Integration Card
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: overlaySectionCol.implicitHeight + 40
                radius: SkinTheme.radiusXLarge
                color: SkinTheme.bgCard
                border.color: SkinTheme.borderMuted
                border.width: 1

                ColumnLayout {
                    id: overlaySectionCol
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 16

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Text {
                            text: "🎯"
                            font.pixelSize: 18
                        }

                        Text {
                            text: "Overplus In-Game Match & Draft Overlay"
                            color: SkinTheme.textPrimary
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: SkinTheme.fontSizeTitle
                            font.bold: true
                        }

                        Item { Layout.fillWidth: true }

                        // GSI Status badge
                        Rectangle {
                            height: 24
                            radius: 12
                            implicitWidth: gsiBadgeText.implicitWidth + 20
                            color: (typeof app !== "undefined" && app && app.gsiInstalled) ? "#122e23" : "#38171c"
                            border.color: (typeof app !== "undefined" && app && app.gsiInstalled) ? SkinTheme.accentEmerald : SkinTheme.accentCyan
                            border.width: 1

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6
                                Rectangle {
                                    width: 6
                                    height: 6
                                    radius: 3
                                    color: (typeof app !== "undefined" && app && app.gsiInstalled) ? SkinTheme.accentEmerald : SkinTheme.accentCyan
                                }
                                Text {
                                    id: gsiBadgeText
                                    text: (typeof app !== "undefined" && app && app.gsiInstalled) ? "GSI Config Active вњ“" : "GSI Not Configured"
                                    color: (typeof app !== "undefined" && app && app.gsiInstalled) ? SkinTheme.accentEmerald : SkinTheme.accentCyan
                                    font.family: SkinTheme.fontFamily
                                    font.pixelSize: 10
                                    font.bold: true
                                }
                            }
                        }
                    }

                    Text {
                        text: "Dota 2 Game State Integration (GSI) automatically alerts ImmortalHub when you find a match and enter hero drafting. " +
                              "The transparent overlay displays player winrates, streaks, signature heroes, and enemy spammer ban warnings directly in game (Press F2 to toggle)."
                        color: SkinTheme.textMuted
                        font.family: SkinTheme.fontFamily
                        font.pixelSize: SkinTheme.fontSizeSmall
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        // Install GSI Config Button
                        Rectangle {
                            Layout.preferredHeight: 38
                            implicitWidth: gsiBtnText.implicitWidth + 28
                            radius: SkinTheme.radiusMedium
                            color: gsiBtnMouse.containsMouse ? SkinTheme.accentCyanHover : SkinTheme.accentCyan

                            RowLayout {
                                id: gsiBtnText
                                anchors.centerIn: parent
                                spacing: 8
                                Text { text: "⚙"; font.pixelSize: 12 }
                                Text {
                                    text: "Install GSI Config"
                                    color: "#000000"
                                    font.family: SkinTheme.fontFamily
                                    font.pixelSize: 12
                                    font.bold: true
                                }
                            }

                            MouseArea {
                                id: gsiBtnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: app.installGsiConfig()
                            }
                        }

                        // Toggle Overlay Button
                        Rectangle {
                            Layout.preferredHeight: 38
                            implicitWidth: togOvlText.implicitWidth + 28
                            radius: SkinTheme.radiusMedium
                            color: app.overlayVisible ? "#16283d" : (togOvlMouse.containsMouse ? SkinTheme.bgCardHover : SkinTheme.bgDark)
                            border.color: app.overlayVisible ? SkinTheme.accentCyan : SkinTheme.borderMuted
                            border.width: 1

                            RowLayout {
                                id: togOvlText
                                anchors.centerIn: parent
                                spacing: 8
                                Text { text: "◫"; font.pixelSize: 12 }
                                Text {
                                    text: app.overlayVisible ? "Hide Overlay (F2)" : "Show Overlay Window"
                                    color: app.overlayVisible ? SkinTheme.accentCyan : SkinTheme.textPrimary
                                    font.family: SkinTheme.fontFamily
                                    font.pixelSize: 12
                                    font.bold: true
                                }
                            }

                            MouseArea {
                                id: togOvlMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: app.toggleOverlay()
                            }
                        }

                        // Test Demo Match Button
                        Rectangle {
                            Layout.preferredHeight: 38
                            implicitWidth: testOvlText.implicitWidth + 28
                            radius: SkinTheme.radiusMedium
                            color: testOvlMouse.containsMouse ? SkinTheme.bgCardHover : SkinTheme.bgDark
                            border.color: SkinTheme.borderMuted
                            border.width: 1

                            RowLayout {
                                id: testOvlText
                                anchors.centerIn: parent
                                spacing: 8
                                Text { text: "⚡"; font.pixelSize: 12 }
                                Text {
                                    text: "Test Demo Match"
                                    color: SkinTheme.textPrimary
                                    font.family: SkinTheme.fontFamily
                                    font.pixelSize: 12
                                    font.bold: true
                                }
                            }

                            MouseArea {
                                id: testOvlMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: app.triggerDemoMatch()
                            }
                        }

                        Item { Layout.fillWidth: true }
                    }
                }
            }

            // 5. How It Works / Modding Info Card
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: guideCol.implicitHeight + 40
                radius: SkinTheme.radiusXLarge
                color: SkinTheme.bgCard
                border.color: SkinTheme.borderMuted
                border.width: 1

                ColumnLayout {
                    id: guideCol
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 12

                    RowLayout {
                        spacing: 8
                        Text { text: "в„№пёЏ"; font.pixelSize: 16 }
                        Text {
                            text: "How Dota 2 Skin Modding Works"
                            color: SkinTheme.textPrimary
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: SkinTheme.fontSizeTitle
                            font.bold: true
                        }
                    }

                    Text {
                        text: "• VPK mods and custom resources are placed directly into your local Dota 2 directory (`.../game/dota` or `.../game/dota_russian`).\n" +
                              "• Skins and visual effects are rendered entirely client-side (visible only to you) with zero impact on game server synchronization.\n" +
                              "• You can uninstall any skin at any time via the Installed tab or click 'Uninstall All' for a full reset."
                        color: SkinTheme.textSecondary
                        font.family: SkinTheme.fontFamily
                        font.pixelSize: SkinTheme.fontSizeBody
                        lineHeight: 1.4
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }
                }
            }

            // 5. About & Version Info Card
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: aboutCol.implicitHeight + 40
                radius: SkinTheme.radiusXLarge
                color: SkinTheme.bgCard
                border.color: SkinTheme.borderMuted
                border.width: 1

                ColumnLayout {
                    id: aboutCol
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 12

                    RowLayout {
                        spacing: 8

                        AegisIcon {
                            width: 22
                            height: 22
                        }

                        Text {
                            text: "ImmortalHub"
                            color: SkinTheme.textPrimary
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: SkinTheme.fontSizeTitle
                            font.bold: true
                        }

                        Rectangle {
                            height: 20
                            radius: 10
                            implicitWidth: vText.implicitWidth + 12
                            color: "#241808"
                            border.color: SkinTheme.accentCyan
                            border.width: 1

                            Text {
                                id: vText
                                anchors.centerIn: parent
                                text: (typeof app !== "undefined" && app.appVersion) ? app.appVersion : "v1.0.0-ALPHA"
                                color: SkinTheme.accentCyan
                                font.family: SkinTheme.fontMono
                                font.pixelSize: 9
                                font.bold: true
                            }
                        }
                    }

                    Text {
                        text: "ImmortalHub — Modern, zero-latency, high-performance skin changer for Dota 2.\n" +
                              "Features Game State Integration, automatic conflict cleanup, and custom announcers."
                        color: SkinTheme.textSecondary
                        font.family: SkinTheme.fontFamily
                        font.pixelSize: SkinTheme.fontSizeBody
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        spacing: 12

                        Rectangle {
                            height: 34
                            radius: SkinTheme.radiusSmall
                            implicitWidth: updateBtnText.implicitWidth + 24
                            color: updateBtnMouse.containsMouse ? SkinTheme.accentCyanHover : SkinTheme.accentCyan
                            border.color: SkinTheme.accentCyan
                            border.width: 1

                            RowLayout {
                                id: updateBtnText
                                anchors.centerIn: parent
                                spacing: 6
                                Text { text: "🔄"; font.pixelSize: 11 }
                                Text {
                                    text: "Check for Updates"
                                    color: SkinTheme.bgDarkest
                                    font.family: SkinTheme.fontFamily
                                    font.pixelSize: 11
                                    font.bold: true
                                }
                            }

                            MouseArea {
                                id: updateBtnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: app.checkForUpdates()
                            }
                        }

                        Rectangle {
                            height: 34
                            radius: SkinTheme.radiusSmall
                            implicitWidth: ghText.implicitWidth + 24
                            color: ghMouse.containsMouse ? SkinTheme.bgCardHover : SkinTheme.bgDark
                            border.color: SkinTheme.borderMuted
                            border.width: 1

                            RowLayout {
                                id: ghText
                                anchors.centerIn: parent
                                spacing: 6
                                Text { text: "★"; font.pixelSize: 11 }
                                Text {
                                    text: "GitHub: ImmortalHub"
                                    color: SkinTheme.accentCyan
                                    font.family: SkinTheme.fontFamily
                                    font.pixelSize: 11
                                    font.bold: true
                                }
                            }

                            MouseArea {
                                id: ghMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: app.openUrl("https://github.com/HarsedXVII/ImmortalHub")
                            }
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: 20 }
        }
    }
}

