import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"
import "../components"

Item {
    id: heroesView

    property string selectedHero: ""
    property var selectedHeroData: null
    property string searchQuery: ""
    property string selectedAttr: "all"  // "all", "str", "agi", "int", "uni", "installed"
    property string selectedSlot: "all"  // "all", "set", "weapon", "fx", "audio"
    property var heroMods: []
    property var heroCards: []
    property var filteredHeroCards: []

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
        function onInstalledModsChanged() {
            loadHeroCards()
            filterMods()
        }
        function onFavoritesChanged() { filterMods() }
    }

    function loadData() {
        loadHeroCards()
        filterMods()
    }

    function loadHeroCards() {
        try {
            heroCards = JSON.parse(app.getHeroCards())
        } catch(e) {
            heroCards = []
        }
        filterHeroCards()
    }

    function filterHeroCards() {
        var result = heroCards
        if (selectedAttr !== "all") {
            if (selectedAttr === "installed") {
                result = result.filter(function(c) { return c.installedCount > 0 })
            } else {
                result = result.filter(function(c) { return c.attr === selectedAttr })
            }
        }
        if (searchQuery.trim() !== "") {
            var q = searchQuery.toLowerCase().trim()
            result = result.filter(function(c) {
                return c.name.toLowerCase().indexOf(q) !== -1
            })
        }
        filteredHeroCards = result
    }

    function selectHero(heroCard) {
        selectedHero = heroCard.name
        selectedHeroData = heroCard
        searchQuery = ""
        selectedSlot = "all"
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
            baseList = []
        }

        var result = baseList

        if (selectedSlot !== "all") {
            result = result.filter(function(m) {
                var s = (m.slot || "").toLowerCase()
                if (selectedSlot === "set") return s === "set" || (m.rarity && m.rarity === "arcana")
                if (selectedSlot === "weapon") return s === "weapon"
                if (selectedSlot === "fx") return s === "fx"
                if (selectedSlot === "audio") return s === "audio"
                return true
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

    function getAttrColor(attr) {
        if (attr === "str") return SkinTheme.attrStr
        if (attr === "agi") return SkinTheme.attrAgi
        if (attr === "int") return SkinTheme.attrInt
        return SkinTheme.attrUni
    }

    function getAttrLabel(attr) {
        if (attr === "str") return "STRENGTH"
        if (attr === "agi") return "AGILITY"
        if (attr === "int") return "INTELLIGENCE"
        return "UNIVERSAL"
    }

    onSelectedHeroChanged: {
        filterHeroCards()
        filterMods()
    }
    onSearchQueryChanged: {
        filterHeroCards()
        filterMods()
    }
    onSelectedAttrChanged: filterHeroCards()
    onSelectedSlotChanged: filterMods()
    
    onVisibleChanged: {
        if (visible) {
            selectedHero = ""
            selectedHeroData = null
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ═══════════════════════════════════════════
        // TOP CONTROL HEADER
        // ═══════════════════════════════════════════
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 64
            color: SkinTheme.bgHeader

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: SkinTheme.borderSubtle
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: SkinTheme.spacingLG
                anchors.rightMargin: SkinTheme.spacingLG
                spacing: SkinTheme.spacingMD

                // Back Button (when hero is open)
                Rectangle {
                    visible: selectedHero !== ""
                    width: 34
                    height: 34
                    radius: SkinTheme.radiusMedium
                    color: backMouse.containsMouse ? SkinTheme.bgCardHover : SkinTheme.bgCard
                    border.color: SkinTheme.borderMuted
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

                    Text {
                        anchors.centerIn: parent
                        text: "←"
                        font.family: SkinTheme.fontFamily
                        font.pixelSize: 16
                        color: SkinTheme.accentCyan
                        font.bold: true
                    }

                    MouseArea {
                        id: backMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            heroesView.selectedHero = ""
                            heroesView.selectedHeroData = null
                        }
                    }
                }

                // Breadcrumb & Title
                ColumnLayout {
                    spacing: 2
                    RowLayout {
                        spacing: 8
                        Text {
                            text: selectedHero === "" ? "HERO BROWSER" : "HEROES"
                            color: selectedHero === "" ? SkinTheme.textPrimary : SkinTheme.textMuted
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: SkinTheme.fontSizeTitle
                            font.bold: true
                            font.letterSpacing: 0.5
                        }

                        Text {
                            visible: selectedHero !== ""
                            text: "›"
                            color: SkinTheme.textMuted
                            font.pixelSize: SkinTheme.fontSizeTitle
                        }

                        Text {
                            visible: selectedHero !== ""
                            text: selectedHero.toUpperCase()
                            color: selectedHeroData ? getAttrColor(selectedHeroData.attr) : SkinTheme.accentCyan
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: SkinTheme.fontSizeTitle
                            font.bold: true
                            font.letterSpacing: 0.5
                        }
                    }

                    Text {
                        text: selectedHero === ""
                              ? filteredHeroCards.length + " heroes • Select a hero to customize skins and loadouts"
                              : heroMods.length + " custom sets, weapons, and particle effects available"
                        color: SkinTheme.textSecondary
                        font.family: SkinTheme.fontFamily
                        font.pixelSize: SkinTheme.fontSizeSmall
                    }
                }

                Item { Layout.fillWidth: true }

                // Search Input Field
                Rectangle {
                    width: 220
                    height: 34
                    radius: SkinTheme.radiusMedium
                    color: SkinTheme.bgInput
                    border.color: searchInput.activeFocus ? SkinTheme.accentCyan : SkinTheme.borderMuted
                    border.width: 1

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
                            color: searchInput.activeFocus ? SkinTheme.accentCyan : SkinTheme.textMuted
                        }

                        TextInput {
                            id: searchInput
                            Layout.fillWidth: true
                            color: SkinTheme.textPrimary
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: SkinTheme.fontSizeBody
                            clip: true
                            selectByMouse: true
                            text: heroesView.searchQuery

                            onTextChanged: heroesView.searchQuery = text

                            Text {
                                text: selectedHero === "" ? "Search heroes..." : "Search skins..."
                                color: SkinTheme.textMuted
                                font.family: SkinTheme.fontFamily
                                font.pixelSize: SkinTheme.fontSizeBody
                                visible: !searchInput.text && !searchInput.activeFocus
                            }
                        }

                        Rectangle {
                            width: 18
                            height: 18
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

                // Randomize Button
                Rectangle {
                    visible: selectedHero === ""
                    height: 34
                    radius: SkinTheme.radiusMedium
                    implicitWidth: randomRow.implicitWidth + 20
                    color: randomMouse.containsMouse ? SkinTheme.accentVioletHover : SkinTheme.accentViolet

                    Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

                    RowLayout {
                        id: randomRow
                        anchors.centerIn: parent
                        spacing: 6
                        Text { text: "🎲"; font.pixelSize: 11; color: "#FFFFFF" }
                        Text {
                            text: "RANDOMIZE"
                            color: "#FFFFFF"
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: SkinTheme.fontSizeSmall
                            font.bold: true
                            font.letterSpacing: 0.5
                        }
                    }

                    MouseArea {
                        id: randomMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: app.randomizeLoadout()
                    }
                }
            }
        }

        // ═══════════════════════════════════════════
        // ATTRIBUTE FILTER TABS (When browsing all heroes)
        // ═══════════════════════════════════════════
        Rectangle {
            visible: selectedHero === ""
            Layout.fillWidth: true
            Layout.preferredHeight: 46
            color: SkinTheme.bgDark

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: SkinTheme.borderSubtle
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: SkinTheme.spacingLG
                anchors.rightMargin: SkinTheme.spacingLG
                spacing: 8

                Repeater {
                    model: [
                        { id: "all",       label: "ALL HEROES",    color: SkinTheme.textPrimary, icon: "⚔️" },
                        { id: "str",       label: "STRENGTH",      color: SkinTheme.attrStr,     icon: "🔴" },
                        { id: "agi",       label: "AGILITY",       color: SkinTheme.attrAgi,     icon: "🟢" },
                        { id: "int",       label: "INTELLIGENCE",  color: SkinTheme.attrInt,     icon: "🔵" },
                        { id: "uni",       label: "UNIVERSAL",     color: SkinTheme.attrUni,     icon: "🟣" },
                        { id: "installed", label: "ACTIVE LOADOUT",color: SkinTheme.accentEmerald,icon: "⚡" }
                    ]

                    delegate: Rectangle {
                        height: 30
                        radius: SkinTheme.radiusPill
                        implicitWidth: attrTabRow.implicitWidth + 24
                        color: selectedAttr === modelData.id
                               ? modelData.color
                               : (attrTabMouse.containsMouse ? SkinTheme.bgCardHover : SkinTheme.bgCard)
                        border.color: selectedAttr === modelData.id ? modelData.color : SkinTheme.borderMuted
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

                        RowLayout {
                            id: attrTabRow
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: modelData.icon
                                font.pixelSize: 10
                            }

                            Text {
                                text: modelData.label
                                color: selectedAttr === modelData.id ? "#08080E" : SkinTheme.textSecondary
                                font.family: SkinTheme.fontFamily
                                font.pixelSize: SkinTheme.fontSizeSmall
                                font.bold: selectedAttr === modelData.id
                            }
                        }

                        MouseArea {
                            id: attrTabMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: selectedAttr = modelData.id
                        }
                    }
                }
            }
        }

        // ═══════════════════════════════════════════
        // HERO SELECTION GRID (Portrait Cards)
        // ═══════════════════════════════════════════
        GridView {
            id: heroesGrid
            visible: heroesView.selectedHero === ""
            Layout.fillWidth: true
            Layout.fillHeight: true
            cellWidth: Math.max(150, Math.floor(width / Math.max(1, Math.floor(width / 165))))
            cellHeight: cellWidth * 1.35
            model: filteredHeroCards
            displayMarginBeginning: 20
            displayMarginEnd: 20
            clip: true

            ScrollBar.vertical: NeonScrollBar {}

            delegate: Item {
                width: heroesGrid.cellWidth
                height: heroesGrid.cellHeight

                Rectangle {
                    id: heroCardBox
                    anchors.fill: parent
                    anchors.margins: 6
                    radius: SkinTheme.radiusLarge
                    color: SkinTheme.bgCard
                    border.color: heroMouse.containsMouse
                                  ? getAttrColor(modelData.attr)
                                  : (modelData.installedCount > 0 ? SkinTheme.accentEmeraldDark : SkinTheme.borderMuted)
                    border.width: 1
                    clip: true

                    scale: heroMouse.containsMouse ? 1.04 : 1.0
                    Behavior on scale { NumberAnimation { duration: SkinTheme.animFast; easing.type: Easing.OutCubic } }
                    Behavior on border.color { ColorAnimation { duration: SkinTheme.animFast } }

                    // Hero Portrait Image
                    Image {
                        anchors.fill: parent
                        source: modelData.imageUrl ? modelData.imageUrl : ""
                        fillMode: Image.PreserveAspectCrop
                        opacity: heroMouse.containsMouse ? 1.0 : 0.78
                        asynchronous: true
                        
                        Behavior on opacity { NumberAnimation { duration: SkinTheme.animFast } }
                    }

                    // Top Attribute & Skin Count Header
                    Rectangle {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 32
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#D008080E" }
                            GradientStop { position: 1.0; color: "transparent" }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8

                            // Attribute dot
                            Rectangle {
                                width: 8
                                height: 8
                                radius: 4
                                color: getAttrColor(modelData.attr)
                            }

                            Item { Layout.fillWidth: true }

                            // Skin count badge
                            Text {
                                text: modelData.skinCount + " skins"
                                color: SkinTheme.textSecondary
                                font.family: SkinTheme.fontMono
                                font.pixelSize: 8
                                font.bold: true
                            }
                        }
                    }

                    // Bottom Vignette
                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 56
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "transparent" }
                            GradientStop { position: 0.4; color: "#A008080E" }
                            GradientStop { position: 1.0; color: "#F008080E" }
                        }
                    }

                    // Active loadout tag
                    Rectangle {
                        anchors.bottom: heroNameText.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottomMargin: 4
                        height: 16
                        radius: SkinTheme.radiusSmall
                        implicitWidth: activeModText.implicitWidth + 10
                        color: "#D008080E"
                        border.color: SkinTheme.accentEmerald
                        border.width: 1
                        visible: modelData.installedCount > 0

                        Text {
                            id: activeModText
                            anchors.centerIn: parent
                            text: "● " + modelData.installedCount + " ACTIVE"
                            color: SkinTheme.accentEmerald
                            font.family: SkinTheme.fontMono
                            font.pixelSize: 7
                            font.bold: true
                        }
                    }

                    // Hero Name
                    Text {
                        id: heroNameText
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 8
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData.name
                        color: heroMouse.containsMouse ? getAttrColor(modelData.attr) : SkinTheme.textPrimary
                        font.family: SkinTheme.fontFamily
                        font.pixelSize: SkinTheme.fontSizeBody
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        id: heroMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: heroesView.selectHero(modelData)
                    }
                }
            }
        }

        // ═══════════════════════════════════════════
        // HERO SHOWCASE STUDIO (When Hero is Selected)
        // ═══════════════════════════════════════════
        Item {
            visible: selectedHero !== ""
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // ── Hero Stage Banner ──
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 130
                    color: SkinTheme.bgCard
                    border.color: SkinTheme.borderMuted
                    border.width: 1
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: "../../assets/banner_dota2_arcana.jpg"
                        fillMode: Image.PreserveAspectCrop
                        opacity: 0.4
                        asynchronous: true
                    }

                    Rectangle {
                        anchors.fill: parent
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "#FA08080E" }
                            GradientStop { position: 0.4; color: "#D008080E" }
                            GradientStop { position: 1.0; color: "#5008080E" }
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 18
                        spacing: 16

                        // Large Hero Avatar
                        Rectangle {
                            Layout.preferredWidth: 96
                            Layout.preferredHeight: 96
                            radius: SkinTheme.radiusLarge
                            color: SkinTheme.bgVoid
                            border.color: selectedHeroData ? getAttrColor(selectedHeroData.attr) : SkinTheme.accentCyan
                            border.width: 2
                            clip: true

                            Image {
                                anchors.fill: parent
                                source: selectedHeroData ? selectedHeroData.imageUrl : ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }
                        }

                        // Hero Info
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            RowLayout {
                                spacing: 8
                                Text {
                                    text: selectedHero.toUpperCase()
                                    color: SkinTheme.textPrimary
                                    font.family: SkinTheme.fontDisplay
                                    font.pixelSize: SkinTheme.fontSizeHeader
                                    font.bold: true
                                    font.letterSpacing: 1.0
                                }

                                Rectangle {
                                    height: 20
                                    radius: SkinTheme.radiusSmall
                                    implicitWidth: attrPillTxt.implicitWidth + 12
                                    color: selectedHeroData ? getAttrColor(selectedHeroData.attr) : SkinTheme.accentCyan
                                    opacity: 0.9

                                    Text {
                                        id: attrPillTxt
                                        anchors.centerIn: parent
                                        text: selectedHeroData ? getAttrLabel(selectedHeroData.attr) : "HERO"
                                        color: "#FFFFFF"
                                        font.family: SkinTheme.fontMono
                                        font.pixelSize: 8
                                        font.bold: true
                                    }
                                }
                            }

                            Text {
                                text: heroMods.length + " custom sets, weapons, effects and audio lines available"
                                color: SkinTheme.textSecondary
                                font.family: SkinTheme.fontFamily
                                font.pixelSize: SkinTheme.fontSizeSmall
                            }

                            RowLayout {
                                spacing: 12
                                Layout.topMargin: 4

                                // Equipped count
                                Text {
                                    text: "Active in Loadout: " + (selectedHeroData ? selectedHeroData.installedCount : 0)
                                    color: SkinTheme.accentEmerald
                                    font.family: SkinTheme.fontMono
                                    font.pixelSize: SkinTheme.fontSizeSmall
                                    font.bold: true
                                }
                            }
                        }
                    }
                }

                // ── Slot Filter Chips Bar ──
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    color: SkinTheme.bgDark

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 1
                        color: SkinTheme.borderSubtle
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: SkinTheme.spacingLG
                        anchors.rightMargin: SkinTheme.spacingLG
                        spacing: 8

                        Repeater {
                            model: [
                                { id: "all",    label: "ALL ITEMS" },
                                { id: "set",    label: "👑 SETS & ARCANA" },
                                { id: "weapon", label: "⚔️ WEAPONS" },
                                { id: "fx",     label: "✨ PARTICLES & FX" },
                                { id: "audio",  label: "🎙️ SOUNDS & VOICE" }
                            ]

                            delegate: Rectangle {
                                height: 28
                                radius: SkinTheme.radiusSmall
                                implicitWidth: slotTxt.implicitWidth + 18
                                color: selectedSlot === modelData.id
                                       ? SkinTheme.accentCyan
                                       : (slotMouse.containsMouse ? SkinTheme.bgCardHover : SkinTheme.bgCard)
                                border.color: selectedSlot === modelData.id ? SkinTheme.accentCyan : SkinTheme.borderMuted
                                border.width: 1

                                Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

                                Text {
                                    id: slotTxt
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: selectedSlot === modelData.id ? "#08080E" : SkinTheme.textSecondary
                                    font.family: SkinTheme.fontFamily
                                    font.pixelSize: SkinTheme.fontSizeSmall
                                    font.bold: selectedSlot === modelData.id
                                }

                                MouseArea {
                                    id: slotMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: selectedSlot = modelData.id
                                }
                            }
                        }
                    }
                }

                // ── Hero Skin Cards Grid ──
                GridView {
                    id: heroSkinGrid
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    cellWidth: Math.max(300, Math.floor(width / Math.max(1, Math.floor(width / 340))))
                    cellHeight: cellWidth * 0.58 + 16
                    model: heroMods
                    displayMarginBeginning: 20
                    displayMarginEnd: 20
                    clip: true

                    ScrollBar.vertical: NeonScrollBar {}

                    delegate: Item {
                        width: heroSkinGrid.cellWidth
                        height: heroSkinGrid.cellHeight

                        SkinModCard {
                            anchors.centerIn: parent
                            modData: modelData

                            onClicked: heroesView.modClicked(modelData)
                            onInstallRequested: heroesView.modInstall(modelData)
                            onUninstallRequested: heroesView.modUninstall(modelData)
                            onAddToCartRequested: heroesView.modAddToCart(modelData)
                        }
                    }
                }
            }
        }

        // ═══════════════════════════════════════════
        // EMPTY STATE
        // ═══════════════════════════════════════════
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: (heroesView.selectedHero === "" && filteredHeroCards.length === 0) ||
                     (heroesView.selectedHero !== "" && heroMods.length === 0)

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 12

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "⊘"
                    color: SkinTheme.textMuted
                    font.pixelSize: 32
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "NO HEROES OR SKINS FOUND"
                    color: SkinTheme.textPrimary
                    font.family: SkinTheme.fontFamily
                    font.pixelSize: SkinTheme.fontSizeTitle
                    font.bold: true
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Try clearing your search query or selecting another attribute tab"
                    color: SkinTheme.textSecondary
                    font.family: SkinTheme.fontFamily
                    font.pixelSize: SkinTheme.fontSizeBody
                }

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 8
                    height: 32
                    radius: SkinTheme.radiusMedium
                    implicitWidth: resetText.implicitWidth + 24
                    color: resetMouse.containsMouse ? SkinTheme.accentCyanHover : SkinTheme.accentCyan

                    Text {
                        id: resetText
                        anchors.centerIn: parent
                        text: "RESET FILTERS"
                        color: "#08080E"
                        font.family: SkinTheme.fontFamily
                        font.pixelSize: SkinTheme.fontSizeSmall
                        font.bold: true
                    }

                    MouseArea {
                        id: resetMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            heroesView.searchQuery = ""
                            heroesView.selectedAttr = "all"
                            heroesView.selectedSlot = "all"
                        }
                    }
                }
            }
        }
    }
}
