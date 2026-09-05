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
    property string selectedAttr: "all"     // "all", "str", "agi", "int", "uni"
    property string selectedRole: "all"     // "all", "carry", "mid", "offlane", "support"
    property string selectedSpecial: "all"  // "all", "arcana", "persona", "immortal", "installed", "favorite"
    property string sortHeroesBy: "name"    // "name", "skins", "installed"
    property bool showSkinPreviews: true    // true = show epic custom skin preview, false = classic hero portrait

    property string selectedSlot: "all"     // "all", "arcana", "persona", "immortal", "set", "weapon", "fx", "audio", "installed", "favorite"
    property string sortModsBy: "rarity"    // "rarity", "name", "installed"

    property var heroMods: []
    property var heroCards: []
    property var filteredHeroCards: []
    property var heroAliasesMap: ({})

    // Dynamic item counts for current hero
    property var slotCounts: ({
        all: 0, arcana: 0, persona: 0, immortal: 0, set: 0, weapon: 0, fx: 0, audio: 0, installed: 0, favorite: 0
    })

    signal modClicked(var mod)
    signal modInstall(var mod)
    signal modUninstall(var mod)
    signal modAddToCart(var mod)

    Component.onCompleted: {
        loadHeroAliases()
        loadData()
    }

    Connections {
        target: app
        function onModsLoaded() { loadData() }
        function onInstalledModsChanged() {
            loadHeroCards()
            if (selectedHero !== "" && selectedHeroData) {
                for (var i = 0; i < heroCards.length; i++) {
                    if (heroCards[i].name === selectedHero) {
                        selectedHeroData = heroCards[i]
                        break
                    }
                }
            }
            filterMods()
        }
        function onFavoritesChanged() {
            loadHeroCards()
            filterMods()
        }
        function onHeroRolesUpdated() {
            loadHeroCards()
            if (selectedHero !== "" && selectedHeroData) {
                for (var i = 0; i < heroCards.length; i++) {
                    if (heroCards[i].name === selectedHero) {
                        selectedHeroData = heroCards[i]
                        break
                    }
                }
            }
        }
    }

    function loadHeroAliases() {
        if (typeof app !== "undefined" && app && typeof app.getHeroAliasesJson === "function") {
            try {
                heroAliasesMap = JSON.parse(app.getHeroAliasesJson())
            } catch(e) {
                heroAliasesMap = {}
            }
        }
    }

    function loadData() {
        loadHeroAliases()
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
            result = result.filter(function(c) { return c.attr === selectedAttr })
        }
        if (selectedRole !== "all") {
            result = result.filter(function(c) {
                if (c.role === selectedRole) return true
                if (c.roles && Array.isArray(c.roles) && c.roles.indexOf(selectedRole) !== -1) return true
                return false
            })
        }
        if (selectedSpecial !== "all") {
            if (selectedSpecial === "arcana") {
                result = result.filter(function(c) { return Boolean(c.hasArcana) })
            } else if (selectedSpecial === "persona") {
                result = result.filter(function(c) { return Boolean(c.hasPersona) })
            } else if (selectedSpecial === "immortal") {
                result = result.filter(function(c) { return Boolean(c.hasImmortal) })
            } else if (selectedSpecial === "installed") {
                result = result.filter(function(c) { return c.installedCount > 0 })
            } else if (selectedSpecial === "favorite") {
                result = result.filter(function(c) { return (c.favCount || 0) > 0 })
            }
        }
        if (searchQuery.trim() !== "") {
            var q = searchQuery.toLowerCase().trim()
            result = result.filter(function(c) {
                if (c.name.toLowerCase().indexOf(q) !== -1) return true
                var aliases = heroAliasesMap[c.name]
                if (aliases && Array.isArray(aliases)) {
                    for (var i = 0; i < aliases.length; i++) {
                        if (aliases[i].toLowerCase().indexOf(q) !== -1) return true
                    }
                }
                return false
            })
        }

        // Sorting heroes
        if (sortHeroesBy === "skins") {
            result.sort(function(a, b) { return (b.skinCount || 0) - (a.skinCount || 0) })
        } else if (sortHeroesBy === "installed") {
            result.sort(function(a, b) {
                var diff = (b.installedCount || 0) - (a.installedCount || 0)
                if (diff !== 0) return diff
                return a.name.localeCompare(b.name)
            })
        } else { // "name"
            result.sort(function(a, b) { return a.name.localeCompare(b.name) })
        }

        filteredHeroCards = result
    }

    function selectHero(heroCard) {
        selectedHero = heroCard.name
        selectedHeroData = heroCard
        searchQuery = ""
        selectedSlot = "all"
        sortModsBy = "rarity"
        filterMods()
    }

    function updateSlotCounts(list) {
        var counts = {
            all: list.length,
            arcana: 0, persona: 0, immortal: 0, set: 0, weapon: 0, fx: 0, audio: 0, installed: 0, favorite: 0
        }
        for (var i = 0; i < list.length; i++) {
            var m = list[i]
            var s = (m.slot || "").toLowerCase()
            var r = (m.rarity || "").toLowerCase()
            var n = (m.name || "").toLowerCase()

            if (r === "arcana" || s === "arcana" || n.indexOf("arcana") !== -1) counts.arcana++
            if (r === "persona" || s === "persona" || n.indexOf("persona") !== -1) counts.persona++
            if (r === "immortal" || s === "immortal" || n.indexOf("immortal") !== -1) counts.immortal++
            if (s === "set" || n.indexOf("set") !== -1 || n.indexOf("bundle") !== -1) counts.set++
            if (s === "weapon") counts.weapon++
            if (s === "fx") counts.fx++
            if (s === "audio") counts.audio++
            if (m.isInstalled) counts.installed++
            if (m.isFavorite) counts.favorite++
        }
        slotCounts = counts
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

        updateSlotCounts(baseList)

        var result = baseList

        if (selectedSlot !== "all") {
            result = result.filter(function(m) {
                var s = (m.slot || "").toLowerCase()
                var r = (m.rarity || "").toLowerCase()
                var n = (m.name || "").toLowerCase()

                if (selectedSlot === "arcana") return r === "arcana" || s === "arcana" || n.indexOf("arcana") !== -1
                if (selectedSlot === "persona") return r === "persona" || s === "persona" || n.indexOf("persona") !== -1
                if (selectedSlot === "immortal") return r === "immortal" || s === "immortal" || n.indexOf("immortal") !== -1
                if (selectedSlot === "set") return s === "set" || n.indexOf("set") !== -1 || n.indexOf("bundle") !== -1
                if (selectedSlot === "weapon") return s === "weapon"
                if (selectedSlot === "fx") return s === "fx"
                if (selectedSlot === "audio") return s === "audio"
                if (selectedSlot === "installed") return Boolean(m.isInstalled)
                if (selectedSlot === "favorite") return Boolean(m.isFavorite)
                return true
            })
        }

        if (searchQuery.trim() !== "") {
            var q = searchQuery.toLowerCase().trim()
            result = result.filter(function(m) {
                if (m.name && m.name.toLowerCase().indexOf(q) !== -1) return true
                if (m.hero && m.hero.toLowerCase().indexOf(q) !== -1) return true
                if (m.rarity && m.rarity.toLowerCase().indexOf(q) !== -1) return true
                if (m.slot && m.slot.toLowerCase().indexOf(q) !== -1) return true
                var heroAliases = m.hero ? heroAliasesMap[m.hero] : (selectedHero ? heroAliasesMap[selectedHero] : null)
                if (heroAliases && Array.isArray(heroAliases)) {
                    for (var a = 0; a < heroAliases.length; a++) {
                        if (heroAliases[a].toLowerCase().indexOf(q) !== -1) return true
                    }
                }
                return false
            })
        }

        // Sort items inside Hero Studio
        if (sortModsBy === "name") {
            result.sort(function(a, b) { return (a.name || "").localeCompare(b.name || "") })
        } else if (sortModsBy === "installed") {
            result.sort(function(a, b) {
                var aInst = a.isInstalled ? 1 : 0
                var bInst = b.isInstalled ? 1 : 0
                if (bInst !== aInst) return bInst - aInst
                return (a.name || "").localeCompare(b.name || "")
            })
        } else { // "rarity"
            var rarityOrder = { "arcana": 1, "persona": 2, "immortal": 3, "mythical": 4, "rare": 5, "standard": 6 }
            result.sort(function(a, b) {
                var rA = rarityOrder[(a.rarity || "").toLowerCase()] || 99
                var rB = rarityOrder[(b.rarity || "").toLowerCase()] || 99
                if (rA !== rB) return rA - rB
                return (a.name || "").localeCompare(b.name || "")
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

    function getRoleLabel(role) {
        if (role === "carry") return "POS 1 CARRY"
        if (role === "mid") return "POS 2 MID"
        if (role === "offlane") return "POS 3 OFFLANE"
        return "POS 4/5 SUPPORT"
    }

    function getRoleColor(role) {
        if (role === "carry") return SkinTheme.roleCarry
        if (role === "mid") return SkinTheme.roleMid
        if (role === "offlane") return SkinTheme.roleOfflane
        return SkinTheme.roleSupport
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
    onSelectedRoleChanged: filterHeroCards()
    onSelectedSpecialChanged: filterHeroCards()
    onSortHeroesByChanged: filterHeroCards()
    onSelectedSlotChanged: filterMods()
    onSortModsByChanged: filterMods()
    
    onVisibleChanged: {
        if (visible) {
            selectedHero = ""
            selectedHeroData = null
            loadData()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ═══════════════════════════════════════════
        // TOP CONTROL BAR
        // ═══════════════════════════════════════════
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 52
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

                // Back Button (when hero studio is open)
                Rectangle {
                    visible: selectedHero !== ""
                    width: 32
                    height: 32
                    radius: SkinTheme.radiusMedium
                    color: backMouse.containsMouse ? SkinTheme.bgCardHover : SkinTheme.bgCard
                    border.color: SkinTheme.borderMuted
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

                    Text {
                        anchors.centerIn: parent
                        text: "←"
                        font.family: SkinTheme.fontFamily
                        font.pixelSize: 15
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

                // Breadcrumb & Section Name
                RowLayout {
                    spacing: 8

                    Text {
                        text: selectedHero === "" ? "HERO STUDIO" : "HEROES"
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

                    Text {
                        text: "• " + (selectedHero === "" ? filteredHeroCards.length + " heroes" : heroMods.length + " items")
                        color: SkinTheme.textMuted
                        font.family: SkinTheme.fontMono
                        font.pixelSize: SkinTheme.fontSizeSmall
                    }
                }

                Item { Layout.fillWidth: true }

                // Search Field
                Rectangle {
                    width: 220
                    height: 32
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
                                text: selectedHero === "" ? "Search heroes..." : "Search items..."
                                color: SkinTheme.textMuted
                                font.family: SkinTheme.fontFamily
                                font.pixelSize: SkinTheme.fontSizeBody
                                visible: !searchInput.text && !searchInput.activeFocus
                            }
                        }

                        Rectangle {
                            width: 16
                            height: 16
                            radius: SkinTheme.radiusSmall
                            color: SkinTheme.bgCardHover
                            visible: searchInput.text !== ""

                            Text {
                                anchors.centerIn: parent
                                text: "✕"
                                color: SkinTheme.textSecondary
                                font.pixelSize: 8
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: searchInput.text = ""
                            }
                        }
                    }
                }

                // Skin Preview Toggle Button
                Rectangle {
                    visible: selectedHero === ""
                    height: 32
                    radius: SkinTheme.radiusMedium
                    implicitWidth: skinToggleRow.implicitWidth + 20
                    color: skinToggleMouse.containsMouse ? SkinTheme.bgCardHover : (heroesView.showSkinPreviews ? SkinTheme.accentCyanSoft : SkinTheme.bgCard)
                    border.color: heroesView.showSkinPreviews ? SkinTheme.accentCyan : SkinTheme.borderMuted
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }
                    Behavior on border.color { ColorAnimation { duration: SkinTheme.animFast } }

                    RowLayout {
                        id: skinToggleRow
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            text: heroesView.showSkinPreviews ? "✨" : "👤"
                            font.pixelSize: 11
                        }
                        Text {
                            text: heroesView.showSkinPreviews ? "SKINS ON" : "CLASSIC"
                            color: heroesView.showSkinPreviews ? SkinTheme.accentCyan : SkinTheme.textSecondary
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: SkinTheme.fontSizeSmall
                            font.bold: true
                            font.letterSpacing: 0.5
                        }
                    }

                    MouseArea {
                        id: skinToggleMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: heroesView.showSkinPreviews = !heroesView.showSkinPreviews
                    }
                }

                // Randomize Loadout Button
                Rectangle {
                    visible: selectedHero === ""
                    height: 32
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
        // DUAL-TIER FILTER & SORTING BAR (Attributes, Roles, Specials, Sorting)
        // ═══════════════════════════════════════════
        Rectangle {
            visible: selectedHero === ""
            Layout.fillWidth: true
            Layout.preferredHeight: 86
            color: SkinTheme.bgDark

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: SkinTheme.borderSubtle
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: 8
                anchors.bottomMargin: 8
                anchors.leftMargin: SkinTheme.spacingLG
                anchors.rightMargin: SkinTheme.spacingLG
                spacing: 6

                // Top Tier: Attribute & Role Filters + Sort Selector
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    // Attribute Pills
                    Repeater {
                        model: [
                            { id: "all",  label: "ALL",   color: SkinTheme.textPrimary, icon: "⚔️" },
                            { id: "str",  label: "STR",   color: SkinTheme.attrStr,     icon: "🔴" },
                            { id: "agi",  label: "AGI",   color: SkinTheme.attrAgi,     icon: "🟢" },
                            { id: "int",  label: "INT",   color: SkinTheme.attrInt,     icon: "🔵" },
                            { id: "uni",  label: "UNI",   color: SkinTheme.attrUni,     icon: "🟣" }
                        ]

                        delegate: Rectangle {
                            height: 28
                            radius: SkinTheme.radiusSmall
                            implicitWidth: attrRow.implicitWidth + 16
                            color: selectedAttr === modelData.id
                                   ? modelData.color
                                   : (attrMouse.containsMouse ? SkinTheme.bgCardHover : SkinTheme.bgCard)
                            border.color: selectedAttr === modelData.id ? modelData.color : SkinTheme.borderMuted
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

                            RowLayout {
                                id: attrRow
                                anchors.centerIn: parent
                                spacing: 5

                                Text { text: modelData.icon; font.pixelSize: 9 }
                                Text {
                                    text: modelData.label
                                    color: selectedAttr === modelData.id ? "#08080E" : SkinTheme.textSecondary
                                    font.family: SkinTheme.fontFamily
                                    font.pixelSize: SkinTheme.fontSizeSmall
                                    font.bold: true
                                }
                            }

                            MouseArea {
                                id: attrMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: selectedAttr = modelData.id
                            }
                        }
                    }

                    // Divider
                    Rectangle {
                        width: 1
                        height: 18
                        color: SkinTheme.borderMuted
                        Layout.leftMargin: 4
                        Layout.rightMargin: 4
                    }

                    // Role Pills (Pos 1-5)
                    Repeater {
                        model: [
                            { id: "all",       label: "ALL ROLES", color: SkinTheme.textPrimary, icon: "🛡️" },
                            { id: "carry",     label: "POS 1 CARRY", color: SkinTheme.roleCarry,   icon: "🗡️" },
                            { id: "mid",       label: "POS 2 MID",   color: SkinTheme.roleMid,     icon: "⚡" },
                            { id: "offlane",   label: "POS 3 OFFLANE", color: SkinTheme.roleOfflane, icon: "🛡️" },
                            { id: "support",   label: "SUPPORT",   color: SkinTheme.roleSupport, icon: "🪄" }
                        ]

                        delegate: Rectangle {
                            height: 28
                            radius: SkinTheme.radiusSmall
                            implicitWidth: roleRow.implicitWidth + 16
                            color: selectedRole === modelData.id
                                   ? modelData.color
                                   : (roleMouse.containsMouse ? SkinTheme.bgCardHover : "transparent")
                            border.color: selectedRole === modelData.id ? modelData.color : SkinTheme.borderMuted
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

                            RowLayout {
                                id: roleRow
                                anchors.centerIn: parent
                                spacing: 5

                                Text { text: modelData.icon; font.pixelSize: 9 }
                                Text {
                                    text: modelData.label
                                    color: selectedRole === modelData.id ? "#08080E" : SkinTheme.textSecondary
                                    font.family: SkinTheme.fontFamily
                                    font.pixelSize: SkinTheme.fontSizeSmall
                                    font.bold: true
                                }
                            }

                            MouseArea {
                                id: roleMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: selectedRole = modelData.id
                            }
                        }
                    }

                    // Dotabuff Meta Sync / Reload Button
                    Rectangle {
                        height: 28
                        radius: SkinTheme.radiusSmall
                        implicitWidth: metaRefreshRow.implicitWidth + 14
                        color: metaRefreshMouse.containsMouse ? SkinTheme.bgCardHover : "transparent"
                        border.color: metaRefreshMouse.containsMouse ? SkinTheme.accentCyan : SkinTheme.borderMuted
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }
                        Behavior on border.color { ColorAnimation { duration: SkinTheme.animFast } }

                        RowLayout {
                            id: metaRefreshRow
                            anchors.centerIn: parent
                            spacing: 5

                            Text {
                                text: "🔄"
                                font.pixelSize: 9
                                rotation: metaRefreshMouse.containsMouse ? 180 : 0
                                Behavior on rotation { NumberAnimation { duration: 300 } }
                            }
                            Text {
                                text: "DOTABUFF META"
                                color: metaRefreshMouse.containsMouse ? SkinTheme.accentCyan : SkinTheme.textMuted
                                font.family: SkinTheme.fontMono
                                font.pixelSize: SkinTheme.fontSizeTiny
                                font.bold: true
                            }
                        }

                        MouseArea {
                            id: metaRefreshMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (typeof app !== "undefined" && app && typeof app.refreshHeroRolesAsync === "function") {
                                    app.refreshHeroRolesAsync()
                                }
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Sort heroes selector
                    RowLayout {
                        spacing: 4
                        Text {
                            text: "SORT:"
                            color: SkinTheme.textMuted
                            font.family: SkinTheme.fontMono
                            font.pixelSize: SkinTheme.fontSizeTiny
                            font.bold: true
                        }

                        Repeater {
                            model: [
                                { id: "name", label: "🔤 A-Z" },
                                { id: "skins", label: "🎒 SKINS" },
                                { id: "installed", label: "⚡ ACTIVE" }
                            ]
                            delegate: Rectangle {
                                height: 26
                                radius: SkinTheme.radiusSmall
                                implicitWidth: sortTxt.implicitWidth + 12
                                color: sortHeroesBy === modelData.id ? SkinTheme.accentCyanSoft : "transparent"
                                border.color: sortHeroesBy === modelData.id ? SkinTheme.accentCyan : SkinTheme.borderMuted
                                border.width: 1

                                Text {
                                    id: sortTxt
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: sortHeroesBy === modelData.id ? SkinTheme.accentCyan : SkinTheme.textSecondary
                                    font.family: SkinTheme.fontMono
                                    font.pixelSize: 8
                                    font.bold: true
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: sortHeroesBy = modelData.id
                                }
                            }
                        }
                    }
                }

                // Bottom Tier: Special Filter Chips (Arcana, Persona, Immortal, Active, Favorites)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: "SPECIAL:"
                        color: SkinTheme.textMuted
                        font.family: SkinTheme.fontMono
                        font.pixelSize: SkinTheme.fontSizeTiny
                        font.bold: true
                    }

                    Repeater {
                        model: [
                            { id: "all",       label: "ALL HEROES", color: SkinTheme.textPrimary, icon: "✦" },
                            { id: "arcana",    label: "ARCANA",     color: SkinTheme.rarityArcana,  icon: "👑" },
                            { id: "persona",   label: "PERSONA",    color: SkinTheme.rarityPersona, icon: "💠" },
                            { id: "immortal",  label: "IMMORTAL",   color: SkinTheme.rarityImmortal, icon: "🟡" },
                            { id: "installed", label: "ACTIVE",     color: SkinTheme.accentEmerald, icon: "●" },
                            { id: "favorite",  label: "FAVORITES",  color: "#EC4899",               icon: "❤️" }
                        ]

                        delegate: Rectangle {
                            height: 26
                            radius: SkinTheme.radiusSmall
                            implicitWidth: specRow.implicitWidth + 14
                            color: selectedSpecial === modelData.id
                                   ? (modelData.color === SkinTheme.textPrimary ? SkinTheme.textPrimary : modelData.color)
                                   : (specMouse.containsMouse ? SkinTheme.bgCardHover : SkinTheme.bgCard)
                            border.color: selectedSpecial === modelData.id ? modelData.color : SkinTheme.borderMuted
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

                            RowLayout {
                                id: specRow
                                anchors.centerIn: parent
                                spacing: 4

                                Text { text: modelData.icon; font.pixelSize: 9 }
                                Text {
                                    text: modelData.label
                                    color: selectedSpecial === modelData.id ? "#08080E" : SkinTheme.textSecondary
                                    font.family: SkinTheme.fontFamily
                                    font.pixelSize: SkinTheme.fontSizeSmall
                                    font.bold: true
                                }
                            }

                            MouseArea {
                                id: specMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: selectedSpecial = modelData.id
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: filteredHeroCards.length + " heroes shown"
                        color: SkinTheme.textMuted
                        font.family: SkinTheme.fontMono
                        font.pixelSize: SkinTheme.fontSizeSmall
                    }
                }
            }
        }

        // ═══════════════════════════════════════════
        // HERO SELECTION GRID (Vertical Trading Cards)
        // ═══════════════════════════════════════════
        GridView {
            id: heroesGrid
            visible: heroesView.selectedHero === ""
            Layout.fillWidth: true
            Layout.fillHeight: true
            cellWidth: Math.max(145, Math.floor(width / Math.max(1, Math.floor(width / 155))))
            cellHeight: cellWidth * 1.36
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
                    anchors.margins: 5
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

                    // Hero Portrait Image (Epic custom skin preview by default, or classic portrait)
                    Image {
                        id: heroPortraitImg
                        anchors.fill: parent
                        source: (heroesView.showSkinPreviews && modelData.skinPreviewUrl)
                                ? modelData.skinPreviewUrl
                                : (modelData.imageUrl ? modelData.imageUrl : "")
                        fillMode: Image.PreserveAspectCrop
                        opacity: heroMouse.containsMouse ? 1.0 : 0.88
                        asynchronous: true
                        
                        Behavior on opacity { NumberAnimation { duration: SkinTheme.animFast } }
                    }

                    // Top Attribute & Role Bar
                    Rectangle {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 30
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#E008080E" }
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

                            // Role tag
                            Text {
                                text: heroesView.selectedRole !== "all"
                                      ? heroesView.selectedRole.toUpperCase()
                                      : (modelData.roleDisplay || (modelData.role ? modelData.role.toUpperCase() : ""))
                                color: getRoleColor(heroesView.selectedRole !== "all" ? heroesView.selectedRole : modelData.role)
                                font.family: SkinTheme.fontMono
                                font.pixelSize: 7
                                font.bold: true
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

                    // Special Hero Badges (Arcana, Persona, Immortal)
                    RowLayout {
                        anchors.top: parent.top
                        anchors.topMargin: 33
                        anchors.left: parent.left
                        anchors.leftMargin: 6
                        spacing: 3

                        Rectangle {
                            visible: Boolean(modelData.hasArcana)
                            height: 14
                            radius: 3
                            implicitWidth: arcBadgeTxt.implicitWidth + 6
                            color: "#E5EF4444"

                            Text {
                                id: arcBadgeTxt
                                anchors.centerIn: parent
                                text: "ARC"
                                color: "#FFFFFF"
                                font.family: SkinTheme.fontMono
                                font.pixelSize: 6
                                font.bold: true
                            }
                        }

                        Rectangle {
                            visible: Boolean(modelData.hasPersona)
                            height: 14
                            radius: 3
                            implicitWidth: perBadgeTxt.implicitWidth + 6
                            color: "#E506B6D4"

                            Text {
                                id: perBadgeTxt
                                anchors.centerIn: parent
                                text: "PER"
                                color: "#08080E"
                                font.family: SkinTheme.fontMono
                                font.pixelSize: 6
                                font.bold: true
                            }
                        }

                        Rectangle {
                            visible: Boolean(modelData.hasImmortal)
                            height: 14
                            radius: 3
                            implicitWidth: immoBadgeTxt.implicitWidth + 6
                            color: "#E5F59E0B"

                            Text {
                                id: immoBadgeTxt
                                anchors.centerIn: parent
                                text: "IMM"
                                color: "#08080E"
                                font.family: SkinTheme.fontMono
                                font.pixelSize: 6
                                font.bold: true
                            }
                        }
                    }

                    // Favorites Count Badge
                    Rectangle {
                        visible: Boolean(modelData.favCount && modelData.favCount > 0)
                        anchors.top: parent.top
                        anchors.topMargin: 33
                        anchors.right: parent.right
                        anchors.rightMargin: 6
                        height: 14
                        radius: 7
                        implicitWidth: favBadgeRow.implicitWidth + 8
                        color: "#CCEC4899"

                        RowLayout {
                            id: favBadgeRow
                            anchors.centerIn: parent
                            spacing: 2
                            Text { text: "❤️"; font.pixelSize: 6 }
                            Text {
                                text: "" + (modelData.favCount || 0)
                                color: "#FFFFFF"
                                font.family: SkinTheme.fontMono
                                font.pixelSize: 6
                                font.bold: true
                            }
                        }
                    }

                    // Bottom Vignette
                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 54
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "transparent" }
                            GradientStop { position: 0.4; color: "#B008080E" }
                            GradientStop { position: 1.0; color: "#F508080E" }
                        }
                    }

                    // Featured Skin Name Tag
                    Rectangle {
                        visible: heroesView.showSkinPreviews && Boolean(modelData.skinPreviewName)
                        anchors.bottom: modelData.installedCount > 0 ? activeModBox.top : heroNameText.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottomMargin: 2
                        height: 15
                        radius: 3
                        implicitWidth: Math.min(parent.width - 12, skinNameTxt.implicitWidth + 10)
                        color: "#E008080E"
                        border.color: modelData.featuredRarity === "arcana"
                                      ? SkinTheme.rarityArcana
                                      : (modelData.featuredRarity === "persona" ? SkinTheme.rarityPersona : (modelData.featuredRarity === "immortal" ? SkinTheme.rarityImmortal : SkinTheme.borderMuted))
                        border.width: 1

                        Text {
                            id: skinNameTxt
                            anchors.centerIn: parent
                            width: parent.width - 6
                            horizontalAlignment: Text.AlignHCenter
                            text: modelData.skinPreviewName
                            color: modelData.featuredRarity === "arcana"
                                   ? SkinTheme.rarityArcana
                                   : (modelData.featuredRarity === "persona" ? SkinTheme.rarityPersona : (modelData.featuredRarity === "immortal" ? SkinTheme.rarityImmortal : SkinTheme.textSecondary))
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: 8
                            font.bold: true
                            elide: Text.ElideRight
                        }
                    }

                    // Active loadout tag
                    Rectangle {
                        id: activeModBox
                        anchors.bottom: heroNameText.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottomMargin: 3
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
                        anchors.bottomMargin: 7
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
                    Layout.preferredHeight: 120
                    color: SkinTheme.bgCard
                    border.color: SkinTheme.borderMuted
                    border.width: 1
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: (selectedHeroData && selectedHeroData.skinPreviewUrl)
                                ? selectedHeroData.skinPreviewUrl
                                : (selectedHeroData && selectedHeroData.imageUrl ? selectedHeroData.imageUrl : "../../assets/banner_dota2_arcana.jpg")
                        fillMode: Image.PreserveAspectCrop
                        opacity: 0.36
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
                        anchors.margins: 16
                        spacing: 16

                        // Hero Avatar
                        Rectangle {
                            Layout.preferredWidth: 88
                            Layout.preferredHeight: 88
                            radius: SkinTheme.radiusLarge
                            color: SkinTheme.bgVoid
                            border.color: selectedHeroData ? getAttrColor(selectedHeroData.attr) : SkinTheme.accentCyan
                            border.width: 2
                            clip: true

                            Image {
                                anchors.fill: parent
                                source: (selectedHeroData && selectedHeroData.skinPreviewUrl)
                                        ? selectedHeroData.skinPreviewUrl
                                        : (selectedHeroData ? selectedHeroData.imageUrl : "")
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

                                // Multi-role pills
                                Repeater {
                                    model: (selectedHeroData && selectedHeroData.roles && selectedHeroData.roles.length > 0)
                                           ? selectedHeroData.roles
                                           : (selectedHeroData && selectedHeroData.role ? [selectedHeroData.role] : [])
                                    delegate: Rectangle {
                                        height: 20
                                        radius: SkinTheme.radiusSmall
                                        implicitWidth: multiRolePillTxt.implicitWidth + 12
                                        color: getRoleColor(modelData)
                                        opacity: 0.9

                                        Text {
                                            id: multiRolePillTxt
                                            anchors.centerIn: parent
                                            text: getRoleLabel(modelData)
                                            color: "#08080E"
                                            font.family: SkinTheme.fontMono
                                            font.pixelSize: 8
                                            font.bold: true
                                        }
                                    }
                                }

                                // Meta Lane Stats Badge
                                Rectangle {
                                    visible: selectedHeroData && selectedHeroData.laneStats && Object.keys(selectedHeroData.laneStats).length > 0
                                    height: 20
                                    radius: SkinTheme.radiusSmall
                                    color: SkinTheme.bgCardHover
                                    border.color: SkinTheme.borderMuted
                                    border.width: 1
                                    implicitWidth: lanePresenceTxt.implicitWidth + 12

                                    Text {
                                        id: lanePresenceTxt
                                        anchors.centerIn: parent
                                        text: {
                                            if (!selectedHeroData || !selectedHeroData.laneStats) return ""
                                            var parts = []
                                            var ls = selectedHeroData.laneStats
                                            if (ls.offlane) parts.push("Offlane " + Math.round(ls.offlane) + "%")
                                            if (ls.mid) parts.push("Mid " + Math.round(ls.mid) + "%")
                                            if (ls.safe) parts.push("Safe " + Math.round(ls.safe) + "%")
                                            if (ls.support) parts.push("Supp " + Math.round(ls.support) + "%")
                                            return "📊 " + (parts.length > 0 ? parts.join(" • ") : "Dotabuff Meta")
                                        }
                                        color: SkinTheme.accentCyan
                                        font.family: SkinTheme.fontMono
                                        font.pixelSize: 8
                                        font.bold: true
                                    }
                                }
                            }

                            Text {
                                text: heroMods.length + " custom sets, weapons, effects and voice lines available"
                                color: SkinTheme.textSecondary
                                font.family: SkinTheme.fontFamily
                                font.pixelSize: SkinTheme.fontSizeSmall
                            }

                            RowLayout {
                                spacing: 12
                                Layout.topMargin: 2

                                Text {
                                    text: "Active in Loadout: " + (selectedHeroData ? selectedHeroData.installedCount : 0)
                                    color: SkinTheme.accentEmerald
                                    font.family: SkinTheme.fontMono
                                    font.pixelSize: SkinTheme.fontSizeSmall
                                    font.bold: true
                                }

                                Text {
                                    visible: Boolean(selectedHeroData && selectedHeroData.favCount > 0)
                                    text: "• Favorites: " + (selectedHeroData ? selectedHeroData.favCount : 0)
                                    color: "#EC4899"
                                    font.family: SkinTheme.fontMono
                                    font.pixelSize: SkinTheme.fontSizeSmall
                                    font.bold: true
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }

                        // Hero Actions Row
                        RowLayout {
                            spacing: 8

                            // Reset Hero Mods Button
                            Rectangle {
                                visible: Boolean(selectedHeroData && selectedHeroData.installedCount > 0)
                                height: 32
                                radius: SkinTheme.radiusMedium
                                implicitWidth: resetHeroRow.implicitWidth + 20
                                color: resetHeroMouse.containsMouse ? "#35EF4444" : "#1AEF4444"
                                border.color: SkinTheme.accentCrimson
                                border.width: 1

                                Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

                                RowLayout {
                                    id: resetHeroRow
                                    anchors.centerIn: parent
                                    spacing: 5
                                    Text { text: "🗑️"; font.pixelSize: 11 }
                                    Text {
                                        text: "RESET HERO MODS"
                                        color: SkinTheme.accentCrimsonHover
                                        font.family: SkinTheme.fontFamily
                                        font.pixelSize: SkinTheme.fontSizeSmall
                                        font.bold: true
                                        font.letterSpacing: 0.5
                                    }
                                }

                                MouseArea {
                                    id: resetHeroMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (typeof app !== "undefined" && app && app.uninstallHeroMods) {
                                            app.uninstallHeroMods(heroesView.selectedHero)
                                        }
                                    }
                                }
                            }

                            // Export Loadout Code Button
                            Rectangle {
                                height: 32
                                radius: SkinTheme.radiusMedium
                                implicitWidth: exportHeroRow.implicitWidth + 20
                                color: exportHeroMouse.containsMouse ? SkinTheme.bgCardHover : SkinTheme.bgCard
                                border.color: SkinTheme.borderMuted
                                border.width: 1

                                Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

                                RowLayout {
                                    id: exportHeroRow
                                    anchors.centerIn: parent
                                    spacing: 5
                                    Text { text: "📋"; font.pixelSize: 11 }
                                    Text {
                                        text: "EXPORT CODE"
                                        color: SkinTheme.textPrimary
                                        font.family: SkinTheme.fontFamily
                                        font.pixelSize: SkinTheme.fontSizeSmall
                                        font.bold: true
                                        font.letterSpacing: 0.5
                                    }
                                }

                                MouseArea {
                                    id: exportHeroMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (typeof app !== "undefined" && app && app.exportHeroLoadoutCode) {
                                            app.exportHeroLoadoutCode(heroesView.selectedHero)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ── Slot Filter Chips & Sorting Bar ──
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
                        spacing: 6

                        Flickable {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            contentWidth: slotPillsRow.implicitWidth
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds

                            RowLayout {
                                id: slotPillsRow
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 6

                                Repeater {
                                    model: [
                                        { id: "all",       label: "ALL",       count: slotCounts.all,       color: SkinTheme.accentCyan,    icon: "✦", isSpecial: false },
                                        { id: "arcana",    label: "ARCANA",    count: slotCounts.arcana,    color: SkinTheme.rarityArcana,  icon: "👑", isSpecial: true },
                                        { id: "persona",   label: "PERSONA",   count: slotCounts.persona,   color: SkinTheme.rarityPersona, icon: "💠", isSpecial: true },
                                        { id: "immortal",  label: "IMMORTAL",  count: slotCounts.immortal,  color: SkinTheme.rarityImmortal,icon: "🟡", isSpecial: true },
                                        { id: "set",       label: "SETS",      count: slotCounts.set,       color: SkinTheme.accentCyan,    icon: "👑", isSpecial: false },
                                        { id: "weapon",    label: "WEAPONS",   count: slotCounts.weapon,    color: SkinTheme.accentCyan,    icon: "⚔️", isSpecial: false },
                                        { id: "fx",        label: "EFFECTS",   count: slotCounts.fx,        color: SkinTheme.accentCyan,    icon: "✨", isSpecial: false },
                                        { id: "audio",     label: "AUDIO",     count: slotCounts.audio,     color: SkinTheme.accentCyan,    icon: "🎙️", isSpecial: false },
                                        { id: "installed", label: "INSTALLED", count: slotCounts.installed, color: SkinTheme.accentEmerald, icon: "●",  isSpecial: false },
                                        { id: "favorite",  label: "FAVORITES", count: slotCounts.favorite,  color: "#EC4899",               icon: "❤️", isSpecial: false }
                                    ]

                                    delegate: Rectangle {
                                        visible: modelData.id === "all" || modelData.count > 0
                                        height: 28
                                        radius: SkinTheme.radiusSmall
                                        implicitWidth: slotRow.implicitWidth + 16
                                        color: selectedSlot === modelData.id
                                               ? (modelData.color || SkinTheme.accentCyan)
                                               : (slotMouse.containsMouse ? SkinTheme.bgCardHover : SkinTheme.bgCard)
                                        border.color: selectedSlot === modelData.id ? (modelData.color || SkinTheme.accentCyan) : SkinTheme.borderMuted
                                        border.width: 1

                                        Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

                                        RowLayout {
                                            id: slotRow
                                            anchors.centerIn: parent
                                            spacing: 4

                                            Text { text: modelData.icon; font.pixelSize: 9 }
                                            Text {
                                                text: modelData.label + " (" + modelData.count + ")"
                                                color: selectedSlot === modelData.id ? "#08080E" : SkinTheme.textSecondary
                                                font.family: SkinTheme.fontFamily
                                                font.pixelSize: SkinTheme.fontSizeSmall
                                                font.bold: selectedSlot === modelData.id
                                            }
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

                        // Divider
                        Rectangle {
                            width: 1
                            height: 18
                            color: SkinTheme.borderMuted
                            Layout.leftMargin: 4
                            Layout.rightMargin: 4
                        }

                        // Sort items selector
                        RowLayout {
                            spacing: 4
                            Text {
                                text: "SORT:"
                                color: SkinTheme.textMuted
                                font.family: SkinTheme.fontMono
                                font.pixelSize: SkinTheme.fontSizeTiny
                                font.bold: true
                            }

                            Repeater {
                                model: [
                                    { id: "rarity",    label: "👑 RARITY" },
                                    { id: "name",      label: "🔤 A-Z" },
                                    { id: "installed", label: "⚡ ACTIVE" }
                                ]
                                delegate: Rectangle {
                                    height: 26
                                    radius: SkinTheme.radiusSmall
                                    implicitWidth: sortModTxt.implicitWidth + 12
                                    color: sortModsBy === modelData.id ? SkinTheme.accentCyanSoft : "transparent"
                                    border.color: sortModsBy === modelData.id ? SkinTheme.accentCyan : SkinTheme.borderMuted
                                    border.width: 1

                                    Text {
                                        id: sortModTxt
                                        anchors.centerIn: parent
                                        text: modelData.label
                                        color: sortModsBy === modelData.id ? SkinTheme.accentCyan : SkinTheme.textSecondary
                                        font.family: SkinTheme.fontMono
                                        font.pixelSize: 8
                                        font.bold: true
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: sortModsBy = modelData.id
                                    }
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
                    text: "NO HEROES OR ITEMS FOUND"
                    color: SkinTheme.textPrimary
                    font.family: SkinTheme.fontFamily
                    font.pixelSize: SkinTheme.fontSizeTitle
                    font.bold: true
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Try resetting your search query or role/attribute filters"
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
                            heroesView.selectedRole = "all"
                            heroesView.selectedSpecial = "all"
                            heroesView.selectedSlot = "all"
                            heroesView.sortHeroesBy = "name"
                            heroesView.sortModsBy = "rarity"
                        }
                    }
                }
            }
        }
    }

    // Floating Quick Scroll Controls
    FastScrollButtons {
        id: heroScrollButtons
        target: (heroesView.selectedHero === "") ? heroesGrid : heroSkinGrid
    }
}
