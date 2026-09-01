import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"
import "../components"

Item {
    id: dashboardView

    property var statsData: ({})
    property var recentMods: []
    property var favoriteMods: []
    property bool dotaLinked: typeof app !== "undefined" && app ? app.dotaDetected : false
    property int totalInstalled: typeof app !== "undefined" && app ? app.installedCount : 0
    property bool isGiPatched: typeof app !== "undefined" && app ? app.gameinfoPatched : false
    property int savings: typeof app !== "undefined" && app ? app.totalSavings : 0

    signal navigateToHeroes()
    signal navigateToInstalled()
    signal navigateToPresets()
    signal modClicked(var mod)

    Component.onCompleted: loadDashboard()

    Connections {
        target: app
        function onModsLoaded() { loadDashboard() }
        function onInstalledModsChanged() { loadDashboard() }
        function onFavoritesChanged() { loadFavorites() }
    }

    function loadDashboard() {
        if (typeof app === "undefined" || !app) return
        statsData = {
            heroes: app.heroesList ? app.heroesList.length : 0,
            totalSkins: app.getTotalSkinsCount ? app.getTotalSkinsCount() : 0,
            installed: app.installedCount || 0,
            favorites: app.favoritesCount || 0
        }
        loadRecent()
        loadFavorites()
    }

    function loadRecent() {
        try {
            recentMods = JSON.parse(app.getRecentlyInstalled())
        } catch(e) {
            recentMods = []
        }
    }

    function loadFavorites() {
        try {
            favoriteMods = JSON.parse(app.getFavorites())
        } catch(e) {
            favoriteMods = []
        }
    }

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: dashContent.implicitHeight + 40
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: NeonScrollBar {}

        ColumnLayout {
            id: dashContent
            width: parent.width
            spacing: 0

            // ═══════════════════════════════════════════
            // HERO CINEMATIC SPOTLIGHT
            // ═══════════════════════════════════════════
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 230
                Layout.leftMargin: SkinTheme.spacingLG
                Layout.rightMargin: SkinTheme.spacingLG
                Layout.topMargin: SkinTheme.spacingLG

                Rectangle {
                    anchors.fill: parent
                    radius: SkinTheme.radiusXLarge
                    color: SkinTheme.bgCard
                    border.color: SkinTheme.borderMuted
                    border.width: 1
                    clip: true

                    // High-res Arcana banner
                    Image {
                        anchors.fill: parent
                        source: "../../assets/banner_dota2_arcana.jpg"
                        fillMode: Image.PreserveAspectCrop
                        opacity: 0.65
                        asynchronous: true
                    }

                    // Multistage dark cinematic gradient
                    Rectangle {
                        anchors.fill: parent
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "#FA08080E" }
                            GradientStop { position: 0.45; color: "#CC08080E" }
                            GradientStop { position: 0.75; color: "#6008080E" }
                            GradientStop { position: 1.0; color: "#2508080E" }
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        gradient: Gradient {
                            GradientStop { position: 0.5; color: "transparent" }
                            GradientStop { position: 1.0; color: "#E008080E" }
                        }
                    }

                    // Content
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 28
                        spacing: 8

                        // Platform Pill
                        RowLayout {
                            spacing: 8
                            Rectangle {
                                height: 22
                                radius: SkinTheme.radiusSmall
                                implicitWidth: bannerBadge.implicitWidth + 14
                                color: SkinTheme.accentCyanGlow
                                border.color: SkinTheme.accentCyan
                                border.width: 1

                                Text {
                                    id: bannerBadge
                                    anchors.centerIn: parent
                                    text: "DOTA 2 CUSTOMIZATION PLATFORM"
                                    color: SkinTheme.accentCyan
                                    font.family: SkinTheme.fontDisplay
                                    font.pixelSize: 9
                                    font.bold: true
                                    font.letterSpacing: 1.5
                                }
                            }

                            Rectangle {
                                height: 22
                                radius: SkinTheme.radiusSmall
                                implicitWidth: vpkPill.implicitWidth + 12
                                color: "#4008080E"
                                border.color: SkinTheme.borderMuted
                                border.width: 1

                                Text {
                                    id: vpkPill
                                    anchors.centerIn: parent
                                    text: "SOURCE 2 VPK ENGINE"
                                    color: SkinTheme.textSecondary
                                    font.family: SkinTheme.fontMono
                                    font.pixelSize: 8
                                    font.bold: true
                                }
                            }
                        }

                        // Hero Title
                        Text {
                            text: "IMMORTAL COLLECTION"
                            color: "#FFFFFF"
                            font.family: SkinTheme.fontDisplay
                            font.pixelSize: 26
                            font.bold: true
                            font.letterSpacing: 1.5
                        }

                        // Subtitle
                        Text {
                            text: "Deploy community Arcanas, Immortals, high-FPS terrains, and sound packs."
                            color: SkinTheme.textSecondary
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: SkinTheme.fontSizeBody
                        }

                        Item { Layout.fillHeight: true }

                        // Action Buttons Row
                        RowLayout {
                            spacing: 12

                            Rectangle {
                                height: 36
                                radius: SkinTheme.radiusMedium
                                implicitWidth: ctaText.implicitWidth + 28
                                color: exploreMouse.containsMouse ? SkinTheme.accentCyanHover : SkinTheme.accentCyan

                                Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

                                Text {
                                    id: ctaText
                                    anchors.centerIn: parent
                                    text: "EXPLORE HEROES →"
                                    color: "#08080E"
                                    font.family: SkinTheme.fontFamily
                                    font.pixelSize: SkinTheme.fontSizeBody
                                    font.bold: true
                                    font.letterSpacing: 0.5
                                }

                                MouseArea {
                                    id: exploreMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: dashboardView.navigateToHeroes()
                                }
                            }

                            Rectangle {
                                height: 36
                                radius: SkinTheme.radiusMedium
                                implicitWidth: instModsBtn.implicitWidth + 24
                                color: instModsMouse.containsMouse ? SkinTheme.bgCardHover : "transparent"
                                border.color: SkinTheme.borderMuted
                                border.width: 1

                                Text {
                                    id: instModsBtn
                                    anchors.centerIn: parent
                                    text: "ACTIVE LOADOUT (" + (statsData.installed || 0) + ")"
                                    color: SkinTheme.textPrimary
                                    font.family: SkinTheme.fontFamily
                                    font.pixelSize: SkinTheme.fontSizeBody
                                    font.bold: true
                                }

                                MouseArea {
                                    id: instModsMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: dashboardView.navigateToInstalled()
                                }
                            }

                            Rectangle {
                                height: 36
                                radius: SkinTheme.radiusMedium
                                implicitWidth: proPresetsBtn.implicitWidth + 24
                                color: proPresetsMouse.containsMouse ? SkinTheme.accentVioletGlow : "transparent"
                                border.color: SkinTheme.accentViolet
                                border.width: 1

                                RowLayout {
                                    id: proPresetsBtn
                                    anchors.centerIn: parent
                                    spacing: 6

                                    Text {
                                        text: "🎭"
                                        font.pixelSize: 12
                                    }

                                    Text {
                                        text: "PRO LOADOUTS"
                                        color: SkinTheme.accentViolet
                                        font.family: SkinTheme.fontFamily
                                        font.pixelSize: SkinTheme.fontSizeBody
                                        font.bold: true
                                        font.letterSpacing: 0.5
                                    }
                                }

                                MouseArea {
                                    id: proPresetsMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: dashboardView.navigateToPresets()
                                }
                            }
                        }
                    }
                }
            }

            // ═══════════════════════════════════════════
            // QUICK STATS TILES
            // ═══════════════════════════════════════════
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: SkinTheme.spacingLG
                Layout.rightMargin: SkinTheme.spacingLG
                Layout.topMargin: SkinTheme.spacingMD
                spacing: SkinTheme.spacingSM

                Repeater {
                    model: [
                        { value: statsData.heroes || 0, label: "HEROES",    icon: "⚔️", color: SkinTheme.accentCyan, sub: "All attributes" },
                        { value: statsData.totalSkins || 0, label: "SKINS",     icon: "👑", color: SkinTheme.accentViolet, sub: "Arcana & Immortals" },
                        { value: statsData.installed || 0, label: "EQUIPPED", icon: "⚡", color: SkinTheme.accentEmerald, sub: "Active in Dota 2" },
                        { value: "$" + dashboardView.savings, label: "SAVINGS",  icon: "💰", color: SkinTheme.accentAmber, sub: "Money saved" }
                    ]

                    delegate: Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 88
                        radius: SkinTheme.radiusLarge
                        color: statMouse.containsMouse ? SkinTheme.bgCardHover : SkinTheme.bgCard
                        border.color: statMouse.containsMouse ? modelData.color : SkinTheme.borderMuted
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }
                        Behavior on border.color { ColorAnimation { duration: SkinTheme.animFast } }

                        scale: statMouse.containsMouse ? 1.02 : 1.0
                        Behavior on scale { NumberAnimation { duration: SkinTheme.animFast; easing.type: Easing.OutCubic } }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 4

                            RowLayout {
                                spacing: 6
                                Text {
                                    text: modelData.icon
                                    font.pixelSize: 12
                                }
                                Text {
                                    text: modelData.label
                                    color: SkinTheme.textMuted
                                    font.family: SkinTheme.fontMono
                                    font.pixelSize: SkinTheme.fontSizeTiny
                                    font.bold: true
                                    font.letterSpacing: 1.0
                                }
                                Item { Layout.fillWidth: true }
                            }

                            Text {
                                text: modelData.value.toString()
                                color: SkinTheme.textPrimary
                                font.family: SkinTheme.fontDisplay
                                font.pixelSize: 22
                                font.bold: true
                            }

                            Text {
                                text: modelData.sub
                                color: SkinTheme.textSecondary
                                font.family: SkinTheme.fontFamily
                                font.pixelSize: SkinTheme.fontSizeSmall
                            }
                        }

                        MouseArea {
                            id: statMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.label === "HEROES") dashboardView.navigateToHeroes()
                                else if (modelData.label === "EQUIPPED") dashboardView.navigateToInstalled()
                            }
                        }
                    }
                }
            }

            // ═══════════════════════════════════════════
            // RECENTLY INSTALLED CAROUSEL
            // ═══════════════════════════════════════════
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: recentMods.length > 0 ? recentSection.implicitHeight : 0
                Layout.leftMargin: SkinTheme.spacingLG
                Layout.rightMargin: SkinTheme.spacingLG
                Layout.topMargin: SkinTheme.spacingLG
                visible: recentMods.length > 0

                ColumnLayout {
                    id: recentSection
                    width: parent.width
                    spacing: SkinTheme.spacingSM

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "RECENTLY INSTALLED"
                            color: SkinTheme.textPrimary
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: SkinTheme.fontSizeTitle
                            font.bold: true
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            height: 24
                            radius: SkinTheme.radiusSmall
                            implicitWidth: viewAllText.implicitWidth + 16
                            color: viewAllMouse.containsMouse ? SkinTheme.bgCardHover : "transparent"
                            border.color: SkinTheme.borderMuted
                            border.width: 1

                            Text {
                                id: viewAllText
                                anchors.centerIn: parent
                                text: "VIEW ALL"
                                color: SkinTheme.textSecondary
                                font.family: SkinTheme.fontFamily
                                font.pixelSize: SkinTheme.fontSizeSmall
                                font.bold: true
                            }

                            MouseArea {
                                id: viewAllMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: dashboardView.navigateToInstalled()
                            }
                        }
                    }

                    // Horizontal Carousel
                    Flickable {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 165
                        contentWidth: recentRow.implicitWidth
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        Row {
                            id: recentRow
                            spacing: SkinTheme.spacingSM

                            Repeater {
                                model: recentMods

                                delegate: Rectangle {
                                    width: 210
                                    height: 155
                                    radius: SkinTheme.radiusLarge
                                    color: recentCardMouse.containsMouse ? SkinTheme.bgCardHover : SkinTheme.bgCard
                                    border.color: recentCardMouse.containsMouse ? SkinTheme.accentEmerald : SkinTheme.borderMuted
                                    border.width: 1
                                    clip: true

                                    scale: recentCardMouse.containsMouse ? 1.03 : 1.0
                                    Behavior on scale { NumberAnimation { duration: SkinTheme.animFast; easing.type: Easing.OutCubic } }

                                    Image {
                                        anchors.fill: parent
                                        source: modelData.previewUrl || ""
                                        fillMode: Image.PreserveAspectCrop
                                        opacity: recentCardMouse.containsMouse ? 0.9 : 0.65
                                        asynchronous: true
                                        Behavior on opacity { NumberAnimation { duration: SkinTheme.animFast } }
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        gradient: Gradient {
                                            GradientStop { position: 0.3; color: "transparent" }
                                            GradientStop { position: 1.0; color: "#F008080E" }
                                        }
                                    }

                                    // Active badge
                                    Rectangle {
                                        anchors.top: parent.top
                                        anchors.left: parent.left
                                        anchors.margins: 8
                                        height: 18
                                        radius: SkinTheme.radiusSmall
                                        implicitWidth: activeTxt.implicitWidth + 10
                                        color: "#D008080E"
                                        border.color: SkinTheme.accentEmerald
                                        border.width: 1

                                        Text {
                                            id: activeTxt
                                            anchors.centerIn: parent
                                            text: "● ACTIVE"
                                            color: SkinTheme.accentEmerald
                                            font.family: SkinTheme.fontMono
                                            font.pixelSize: 7
                                            font.bold: true
                                        }
                                    }

                                    ColumnLayout {
                                        anchors.left: parent.left
                                        anchors.bottom: parent.bottom
                                        anchors.right: parent.right
                                        anchors.margins: 10
                                        spacing: 2

                                        Text {
                                            text: modelData.hero || modelData.categoryId || ""
                                            color: SkinTheme.accentCyan
                                            font.family: SkinTheme.fontMono
                                            font.pixelSize: 8
                                            font.bold: true
                                            font.letterSpacing: 1.0
                                        }

                                        Text {
                                            text: modelData.name || ""
                                            color: "#FFFFFF"
                                            font.family: SkinTheme.fontFamily
                                            font.pixelSize: SkinTheme.fontSizeBody
                                            font.bold: true
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }
                                    }

                                    MouseArea {
                                        id: recentCardMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: dashboardView.modClicked(modelData)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ═══════════════════════════════════════════
            // FAVORITES CAROUSEL
            // ═══════════════════════════════════════════
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: favoriteMods.length > 0 ? favSection.implicitHeight : 0
                Layout.leftMargin: SkinTheme.spacingLG
                Layout.rightMargin: SkinTheme.spacingLG
                Layout.topMargin: SkinTheme.spacingLG
                visible: favoriteMods.length > 0

                ColumnLayout {
                    id: favSection
                    width: parent.width
                    spacing: SkinTheme.spacingSM

                    Text {
                        text: "STARRED FAVORITES"
                        color: SkinTheme.textPrimary
                        font.family: SkinTheme.fontFamily
                        font.pixelSize: SkinTheme.fontSizeTitle
                        font.bold: true
                    }

                    Flickable {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 165
                        contentWidth: favRow.implicitWidth
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        Row {
                            id: favRow
                            spacing: SkinTheme.spacingSM

                            Repeater {
                                model: favoriteMods

                                delegate: Rectangle {
                                    width: 210
                                    height: 155
                                    radius: SkinTheme.radiusLarge
                                    color: favCardMouse.containsMouse ? SkinTheme.bgCardHover : SkinTheme.bgCard
                                    border.color: favCardMouse.containsMouse ? SkinTheme.accentAmber : SkinTheme.borderMuted
                                    border.width: 1
                                    clip: true

                                    scale: favCardMouse.containsMouse ? 1.03 : 1.0
                                    Behavior on scale { NumberAnimation { duration: SkinTheme.animFast; easing.type: Easing.OutCubic } }

                                    Image {
                                        anchors.fill: parent
                                        source: modelData.previewUrl || ""
                                        fillMode: Image.PreserveAspectCrop
                                        opacity: favCardMouse.containsMouse ? 0.9 : 0.65
                                        asynchronous: true
                                        Behavior on opacity { NumberAnimation { duration: SkinTheme.animFast } }
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        gradient: Gradient {
                                            GradientStop { position: 0.3; color: "transparent" }
                                            GradientStop { position: 1.0; color: "#F008080E" }
                                        }
                                    }

                                    // Star
                                    Text {
                                        anchors.top: parent.top
                                        anchors.right: parent.right
                                        anchors.margins: 8
                                        text: "★"
                                        color: SkinTheme.accentAmber
                                        font.pixelSize: 14
                                    }

                                    ColumnLayout {
                                        anchors.left: parent.left
                                        anchors.bottom: parent.bottom
                                        anchors.right: parent.right
                                        anchors.margins: 10
                                        spacing: 2

                                        Text {
                                            text: modelData.hero || modelData.categoryId || ""
                                            color: SkinTheme.accentCyan
                                            font.family: SkinTheme.fontMono
                                            font.pixelSize: 8
                                            font.bold: true
                                            font.letterSpacing: 1.0
                                        }

                                        Text {
                                            text: modelData.name || ""
                                            color: "#FFFFFF"
                                            font.family: SkinTheme.fontFamily
                                            font.pixelSize: SkinTheme.fontSizeBody
                                            font.bold: true
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }
                                    }

                                    MouseArea {
                                        id: favCardMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: dashboardView.modClicked(modelData)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ═══════════════════════════════════════════
            // SYSTEM STATUS
            // ═══════════════════════════════════════════
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: SkinTheme.spacingLG
                Layout.rightMargin: SkinTheme.spacingLG
                Layout.topMargin: SkinTheme.spacingLG
                Layout.bottomMargin: SkinTheme.spacingLG
                Layout.preferredHeight: statusContent.implicitHeight + 32
                radius: SkinTheme.radiusLarge
                color: SkinTheme.bgCard
                border.color: SkinTheme.borderMuted
                border.width: 1

                ColumnLayout {
                    id: statusContent
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: SkinTheme.spacingSM

                    Text {
                        text: "ENGINE STATUS & CONNECTIVITY"
                        color: SkinTheme.textPrimary
                        font.family: SkinTheme.fontFamily
                        font.pixelSize: SkinTheme.fontSizeTitle
                        font.bold: true
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: SkinTheme.borderSubtle
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: SkinTheme.spacingXL

                        // Dota 2
                        RowLayout {
                            spacing: 10
                            Rectangle {
                                width: 10; height: 10; radius: 5
                                color: dashboardView.dotaLinked ? SkinTheme.accentEmerald : SkinTheme.accentCrimson
                            }
                            ColumnLayout {
                                spacing: 2
                                Text {
                                    text: "DOTA 2"
                                    color: SkinTheme.textPrimary
                                    font.family: SkinTheme.fontFamily
                                    font.pixelSize: SkinTheme.fontSizeBody
                                    font.bold: true
                                }
                                Text {
                                    text: dashboardView.dotaLinked ? "Connected" : "Not Found"
                                    color: dashboardView.dotaLinked ? SkinTheme.accentEmerald : SkinTheme.accentCrimson
                                    font.family: SkinTheme.fontMono
                                    font.pixelSize: SkinTheme.fontSizeSmall
                                }
                            }
                        }

                        // Mods active
                        RowLayout {
                            spacing: 10
                            Rectangle {
                                width: 10; height: 10; radius: 5
                                color: dashboardView.totalInstalled > 0 ? SkinTheme.accentEmerald : SkinTheme.textMuted
                            }
                            ColumnLayout {
                                spacing: 2
                                Text {
                                    text: "ACTIVE LOADOUT"
                                    color: SkinTheme.textPrimary
                                    font.family: SkinTheme.fontFamily
                                    font.pixelSize: SkinTheme.fontSizeBody
                                    font.bold: true
                                }
                                Text {
                                    text: dashboardView.totalInstalled + " mods equipped"
                                    color: dashboardView.totalInstalled > 0 ? SkinTheme.accentEmerald : SkinTheme.textMuted
                                    font.family: SkinTheme.fontMono
                                    font.pixelSize: SkinTheme.fontSizeSmall
                                }
                            }
                        }

                        // Gameinfo
                        RowLayout {
                            spacing: 10
                            Rectangle {
                                width: 10; height: 10; radius: 5
                                color: dashboardView.isGiPatched ? SkinTheme.accentEmerald : SkinTheme.accentAmber
                            }
                            ColumnLayout {
                                spacing: 2
                                Text {
                                    text: "GAMEINFO.GI"
                                    color: SkinTheme.textPrimary
                                    font.family: SkinTheme.fontFamily
                                    font.pixelSize: SkinTheme.fontSizeBody
                                    font.bold: true
                                }
                                Text {
                                    text: dashboardView.isGiPatched ? "Patched & Active" : "Unpatched"
                                    color: dashboardView.isGiPatched ? SkinTheme.accentEmerald : SkinTheme.accentAmber
                                    font.family: SkinTheme.fontMono
                                    font.pixelSize: SkinTheme.fontSizeSmall
                                }
                            }
                        }

                        // Savings
                        RowLayout {
                            spacing: 10
                            ColumnLayout {
                                spacing: 2
                                Text {
                                    text: "TOTAL SAVED"
                                    color: SkinTheme.textPrimary
                                    font.family: SkinTheme.fontFamily
                                    font.pixelSize: SkinTheme.fontSizeBody
                                    font.bold: true
                                }
                                Text {
                                    text: "$" + dashboardView.savings + ".00 USD"
                                    color: SkinTheme.accentEmerald
                                    font.family: SkinTheme.fontMono
                                    font.pixelSize: SkinTheme.fontSizeSmall
                                    font.bold: true
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
