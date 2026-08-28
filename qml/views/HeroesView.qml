import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"
import "../components"

Item {
    id: heroesView

    property string selectedHero: ""
    property string searchQuery: ""
    property string filterMode: "all" // "all", "installed", "favorites"
    property var heroMods: []
    property var allHeroModsCache: []

    signal modClicked(var mod)
    signal modInstall(var mod)
    signal modUninstall(var mod)
    signal modAddToCart(var mod)

    Component.onCompleted: {
        loadData()
    }

    Connections {
        target: app
        function onModsLoaded() { loadData() }
        function onInstalledModsChanged() { filterMods() }
        function onFavoritesChanged() { filterMods() }
    }

    function loadData() {
        var raw = app.getModsForCategory("heroes")
        try {
            allHeroModsCache = JSON.parse(raw)
        } catch(e) {
            allHeroModsCache = []
        }
        filterMods()
    }

    function filterMods() {
        var baseList = []
        if (selectedHero !== "") {
            var rawHero = app.getHeroMods(selectedHero)
            try {
                baseList = JSON.parse(rawHero)
            } catch(e) {
                baseList = []
            }
        } else {
            baseList = allHeroModsCache
        }

        var result = baseList

        if (filterMode === "installed") {
            result = result.filter(function(m) {
                return app.isModInstalled(m.name, m.categoryId)
            })
        } else if (filterMode === "favorites") {
            result = result.filter(function(m) {
                return app.isFavorite(m.name, m.categoryId)
            })
        }

        if (searchQuery.trim() !== "") {
            var q = searchQuery.toLowerCase().trim()
            result = result.filter(function(m) {
                return m.name.toLowerCase().indexOf(q) !== -1 || (m.hero && m.hero.toLowerCase().indexOf(q) !== -1)
            })
        }

        heroMods = result
    }

    onSelectedHeroChanged: filterMods()
    onSearchQueryChanged: filterMods()
    onFilterModeChanged: filterMods()

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Top Control Header — Minimalist
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            color: SkinTheme.bgHeader

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: SkinTheme.borderMuted
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                spacing: 16

                // Title
                ColumnLayout {
                    spacing: 2

                    Text {
                        text: selectedHero === "" ? "HERO SKINS" : selectedHero.toUpperCase()
                        color: SkinTheme.textPrimary
                        font.family: SkinTheme.fontFamily
                        font.pixelSize: SkinTheme.fontSizeTitle
                        font.bold: true
                        font.letterSpacing: 1.0
                    }

                    Text {
                        text: heroMods.length + " skins available"
                        color: SkinTheme.textMuted
                        font.family: SkinTheme.fontMono
                        font.pixelSize: 10
                        font.letterSpacing: 0.5
                    }
                }

                Item { Layout.fillWidth: true }

                // Filter Segments
                Rectangle {
                    height: 32
                    radius: SkinTheme.radiusSmall
                    color: SkinTheme.bgInput
                    border.color: SkinTheme.borderMuted
                    border.width: 1
                    implicitWidth: segRow.implicitWidth + 6

                    RowLayout {
                        id: segRow
                        anchors.centerIn: parent
                        spacing: 2

                        Repeater {
                            model: [
                                { id: "all",       label: "ALL" },
                                { id: "installed", label: "INSTALLED" },
                                { id: "favorites", label: "★ STARRED" }
                            ]

                            delegate: Rectangle {
                                height: 26
                                radius: SkinTheme.radiusSmall
                                implicitWidth: segText.implicitWidth + 16
                                color: heroesView.filterMode === modelData.id
                                       ? SkinTheme.accentCyan
                                       : (segMouse.containsMouse ? SkinTheme.bgCardHover : "transparent")

                                Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

                                Text {
                                    id: segText
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: heroesView.filterMode === modelData.id ? "#060810" : SkinTheme.textSecondary
                                    font.family: SkinTheme.fontMono
                                    font.pixelSize: 9
                                    font.bold: true
                                    font.letterSpacing: 0.8
                                }

                                MouseArea {
                                    id: segMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: heroesView.filterMode = modelData.id
                                }
                            }
                        }
                    }
                }

                // Search Bar — Cyberpunk style
                Rectangle {
                    width: 260
                    height: 34
                    radius: SkinTheme.radiusSmall
                    color: SkinTheme.bgInput
                    border.color: searchInput.activeFocus ? SkinTheme.accentCyan : SkinTheme.borderMuted
                    border.width: 1

                    Behavior on border.color { ColorAnimation { duration: SkinTheme.animFast } }

                    // Focus glow
                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width + 4
                        height: parent.height + 4
                        radius: parent.radius + 2
                        color: "transparent"
                        border.color: SkinTheme.accentCyan
                        border.width: 1
                        opacity: searchInput.activeFocus ? 0.2 : 0
                        Behavior on opacity { NumberAnimation { duration: SkinTheme.animFast } }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 10
                        spacing: 8

                        Text {
                            text: "⌕"
                            font.pixelSize: 14
                            color: searchInput.activeFocus ? SkinTheme.accentCyan : SkinTheme.textMuted
                            Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }
                        }

                        TextInput {
                            id: searchInput
                            Layout.fillWidth: true
                            color: SkinTheme.textPrimary
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: 12
                            clip: true
                            selectByMouse: true
                            text: heroesView.searchQuery

                            onTextChanged: heroesView.searchQuery = text

                            Text {
                                text: "Search mods, heroes..."
                                color: SkinTheme.textMuted
                                font.pixelSize: 12
                                visible: !searchInput.text && !searchInput.activeFocus
                            }
                        }

                        Rectangle {
                            width: 20
                            height: 20
                            radius: SkinTheme.radiusSmall
                            color: SkinTheme.bgCardHover
                            visible: searchInput.text !== ""

                            Text {
                                anchors.centerIn: parent
                                text: "✕"
                                color: SkinTheme.textSecondary
                                font.pixelSize: 9
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: searchInput.text = ""
                            }
                        }
                    }
                }
            }
        }

        // Hero Filter Chips Bar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            color: SkinTheme.bgDark

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: SkinTheme.borderMuted
            }

            ListView {
                id: heroChipsView
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                orientation: ListView.Horizontal
                spacing: 6
                clip: true

                model: ["All Heroes"].concat(app.heroesList)

                delegate: Rectangle {
                    height: 28
                    y: 8
                    radius: SkinTheme.radiusSmall
                    implicitWidth: chipText.implicitWidth + 20
                    color: (selectedHero === "" && modelData === "All Heroes") || selectedHero === modelData
                           ? SkinTheme.accentViolet
                           : (chipMouse.containsMouse ? SkinTheme.bgCardHover : SkinTheme.bgCard)
                    border.color: (selectedHero === "" && modelData === "All Heroes") || selectedHero === modelData
                                  ? SkinTheme.accentVioletHover
                                  : SkinTheme.borderMuted
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

                    Text {
                        id: chipText
                        anchors.centerIn: parent
                        text: modelData
                        color: (selectedHero === "" && modelData === "All Heroes") || selectedHero === modelData
                               ? "#ffffff"
                               : (chipMouse.containsMouse ? SkinTheme.textPrimary : SkinTheme.textSecondary)
                        font.family: SkinTheme.fontFamily
                        font.pixelSize: 11
                        font.bold: (selectedHero === "" && modelData === "All Heroes") || selectedHero === modelData
                    }

                    MouseArea {
                        id: chipMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (modelData === "All Heroes") {
                                selectedHero = ""
                            } else {
                                selectedHero = modelData
                            }
                        }
                    }
                }
            }
        }

        // Mod Cards Grid
        GridView {
            id: grid
            Layout.fillWidth: true
            Layout.fillHeight: true
            cellWidth: Math.max(300, Math.floor(width / Math.max(1, Math.floor(width / 340))))
            cellHeight: cellWidth * 0.5625 + 16
            model: heroMods
            displayMarginBeginning: 20
            displayMarginEnd: 20
            clip: true

            ScrollBar.vertical: NeonScrollBar {}

            // Featured Banner
            header: Item {
                width: grid.width
                height: 220
                visible: true

                Rectangle {
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    anchors.topMargin: 20
                    anchors.bottomMargin: 10
                    radius: SkinTheme.radiusLarge
                    color: SkinTheme.bgCard
                    border.color: SkinTheme.borderMuted
                    border.width: 1
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: "../../assets/banner_dota2_arcana.jpg"
                        fillMode: Image.Stretch
                        opacity: 0.95
                        asynchronous: true
                    }

                    // Cyberpunk gradient overlay (darker on left for text legibility)
                    Rectangle {
                        anchors.fill: parent
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "#F0080C14" }
                            GradientStop { position: 0.36; color: "#C0080C14" }
                            GradientStop { position: 0.72; color: "#35080C14" }
                            GradientStop { position: 1.0; color: "#05080C14" }
                        }
                    }

                    // Neon left accent
                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 3
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: SkinTheme.accentCyan }
                            GradientStop { position: 1.0; color: SkinTheme.accentViolet }
                        }
                        opacity: 0.85
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 28
                        spacing: 6

                        // Mode / Category badge
                        Rectangle {
                            height: 22
                            radius: 3
                            implicitWidth: badgeText.implicitWidth + 14
                            color: SkinTheme.accentCyanGlow
                            border.color: SkinTheme.accentCyan
                            border.width: 1

                            Text {
                                id: badgeText
                                anchors.centerIn: parent
                                text: {
                                    if (heroesView.selectedHero !== "") return "HERO • " + heroesView.selectedHero.toUpperCase()
                                    if (heroesView.searchQuery !== "") return "SEARCH RESULTS"
                                    return "DOTA 2 ARCANA COLLECTION"
                                }
                                color: SkinTheme.accentCyan
                                font.family: SkinTheme.fontDisplay
                                font.pixelSize: 10
                                font.bold: true
                                font.letterSpacing: 1.5
                            }
                        }

                        // Main Header Title
                        Text {
                            id: headerTitleText
                            text: {
                                if (heroesView.selectedHero !== "") return heroesView.selectedHero.toUpperCase() + " SKINS"
                                if (heroesView.searchQuery !== "") return "RESULTS: \"" + heroesView.searchQuery.toUpperCase() + "\""
                                return "CUSTOM HERO SKINS"
                            }
                            color: "#ffffff"
                            font.family: SkinTheme.fontDisplay
                            font.pixelSize: 22
                            font.bold: true
                            font.letterSpacing: 1.5
                        }

                        // Subtitle / Info
                        Text {
                            text: {
                                if (heroesView.selectedHero !== "") return heroMods.length + " custom Arcana sets & items available for " + heroesView.selectedHero
                                if (heroesView.searchQuery !== "") return heroMods.length + " skins matching your search"
                                return "Exclusive community-made Arcana, Immortals and Persona sets"
                            }
                            color: SkinTheme.textSecondary
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: 14
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Item { Layout.fillHeight: true }

                        // Quick Reset Button (when filtered)
                        Rectangle {
                            height: 26
                            radius: SkinTheme.radiusSmall
                            color: resetBannerMouse.containsMouse ? SkinTheme.accentCyanGlow : "transparent"
                            border.color: SkinTheme.accentCyan
                            border.width: 1
                            implicitWidth: resetBannerLabel.implicitWidth + 18
                            visible: heroesView.selectedHero !== "" || heroesView.searchQuery !== ""

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6
                                Text {
                                    id: resetBannerLabel
                                    text: "✕ SHOW ALL HEROES"
                                    color: SkinTheme.accentCyan
                                    font.family: SkinTheme.fontMono
                                    font.pixelSize: 10
                                    font.bold: true
                                }
                            }

                            MouseArea {
                                id: resetBannerMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    heroesView.selectedHero = ""
                                    heroesView.searchQuery = ""
                                }
                            }
                        }
                    }
                }
            }

            add: Transition {
                NumberAnimation { property: "opacity"; from: 0; to: 1.0; duration: 250; easing.type: Easing.OutCubic }
            }

            delegate: Item {
                id: cardDelegate
                width: grid.cellWidth
                height: grid.cellHeight

                // Staggered cascade entrance (capped delay so far-down
                // rows don't wait forever). Re-runs when scrolled back in.
                opacity: 0
                scale: 0.95
                SequentialAnimation on opacity {
                    running: cardDelegate.visible
                    PauseAnimation { duration: (index % 18) * 30 }
                    NumberAnimation { to: 1; duration: 300; easing.type: Easing.OutCubic }
                }
                SequentialAnimation on scale {
                    running: cardDelegate.visible
                    PauseAnimation { duration: (index % 18) * 30 }
                    NumberAnimation { to: 1; duration: 320; easing.type: Easing.OutBack }
                }

                SkinModCard {
                    anchors.centerIn: parent
                    modData: modelData

                    onClicked: heroesView.modClicked(modelData)
                    onInstallRequested: heroesView.modInstall(modelData)
                    onUninstallRequested: heroesView.modUninstall(modelData)
                    onAddToCartRequested: heroesView.modAddToCart(modelData)
                }
            }

                // Empty State
                Item {
                    anchors.centerIn: parent
                    visible: heroMods.length === 0

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 12

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            width: 48
                            height: 48
                            radius: SkinTheme.radiusSmall
                            color: "transparent"
                            border.color: SkinTheme.borderMuted
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "⊘"
                                color: SkinTheme.textMuted
                                font.pixelSize: 20
                            }
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "NO RESULTS FOUND"
                            color: SkinTheme.textPrimary
                            font.family: SkinTheme.fontMono
                            font.pixelSize: 13
                            font.bold: true
                            font.letterSpacing: 1.5
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Try changing your search term or filter mode"
                            color: SkinTheme.textMuted
                            font.pixelSize: 12
                        }

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: 8
                            height: 30
                            radius: SkinTheme.radiusSmall
                            implicitWidth: resetText.implicitWidth + 20
                            color: resetMouse.containsMouse ? SkinTheme.bgCardHover : "transparent"
                            border.color: SkinTheme.accentCyan
                            border.width: 1

                            Text {
                                id: resetText
                                anchors.centerIn: parent
                                text: "RESET FILTERS"
                                color: SkinTheme.accentCyan
                                font.family: SkinTheme.fontMono
                                font.pixelSize: 10
                                font.bold: true
                                font.letterSpacing: 0.8
                            }

                            MouseArea {
                                id: resetMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    heroesView.selectedHero = ""
                                    heroesView.searchQuery = ""
                                    heroesView.filterMode = "all"
                                }
                            }
                        }
                    }
                }
            }
        }
    }
