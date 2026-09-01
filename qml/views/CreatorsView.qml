import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"
import "../components"

Item {
    id: creatorsView

    property var creatorsList: []
    property string selectedCreatorId: ""
    property var selectedCreatorData: null
    property var creatorMods: []
    property var filteredMods: []
    property string searchQuery: ""
    property string heroFilter: ""
    property string filterMode: "all" // "all", "installed", "favorites"

    signal modClicked(var mod)
    signal modInstall(var mod)
    signal modUninstall(var mod)
    signal modAddToCart(var mod)

    function tr(key) {
        return (typeof app !== "undefined" && app && app.t) ? app.t(key) : ""
    }

    Component.onCompleted: {
        loadCreators()
    }

    Connections {
        target: app
        function onCreatorsChanged() {
            loadCreators()
            if (selectedCreatorId !== "") {
                loadCreatorMods()
            }
        }
        function onInstalledModsChanged() {
            if (selectedCreatorId !== "") {
                loadCreatorMods()
            } else {
                loadCreators()
            }
        }
        function onFavoritesChanged() {
            if (selectedCreatorId !== "") {
                filterMods()
            }
        }
    }

    function loadCreators() {
        try {
            creatorsList = JSON.parse(app.getCreators())
        } catch(e) {
            creatorsList = []
        }
        if (selectedCreatorId !== "") {
            for (var i = 0; i < creatorsList.length; i++) {
                if (creatorsList[i].id === selectedCreatorId) {
                    selectedCreatorData = creatorsList[i]
                    break
                }
            }
        }
    }

    function selectCreator(cId) {
        selectedCreatorId = cId
        searchQuery = ""
        heroFilter = ""
        filterMode = "all"
        for (var i = 0; i < creatorsList.length; i++) {
            if (creatorsList[i].id === cId) {
                selectedCreatorData = creatorsList[i]
                break
            }
        }
        loadCreatorMods()
    }

    function backToCreators() {
        selectedCreatorId = ""
        selectedCreatorData = null
        creatorMods = []
        filteredMods = []
        loadCreators()
    }

    function loadCreatorMods() {
        if (!selectedCreatorId) return
        try {
            creatorMods = JSON.parse(app.getCreatorMods(selectedCreatorId))
        } catch(e) {
            creatorMods = []
        }
        filterMods()
    }

    function getUniqueHeroes() {
        var map = {}
        for (var i = 0; i < creatorMods.length; i++) {
            var h = creatorMods[i].hero || "Custom"
            map[h] = true
        }
        return Object.keys(map).sort()
    }

    function filterMods() {
        var result = creatorMods

        if (filterMode === "installed") {
            result = result.filter(function(m) {
                return app.isModInstalled(m.name, m.categoryId) || app.isModInstalled(m.name, "custom")
            })
        } else if (filterMode === "favorites") {
            result = result.filter(function(m) {
                return app.isFavorite(m.name, m.categoryId)
            })
        }

        if (heroFilter !== "") {
            result = result.filter(function(m) {
                return (m.hero || "Custom").toLowerCase() === heroFilter.toLowerCase()
            })
        }

        if (searchQuery.trim() !== "") {
            var q = searchQuery.toLowerCase().trim()
            result = result.filter(function(m) {
                return m.name.toLowerCase().indexOf(q) !== -1 || (m.hero && m.hero.toLowerCase().indexOf(q) !== -1)
            })
        }

        filteredMods = result
    }

    onSearchQueryChanged: filterMods()
    onHeroFilterChanged: filterMods()
    onFilterModeChanged: filterMods()

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Top Navigation / Header Bar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 64
            color: SkinTheme.bgHeader

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: SkinTheme.borderMuted
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 24
                anchors.rightMargin: 24
                spacing: 16

                // Back Button (when in creator detail)
                Rectangle {
                    visible: selectedCreatorId !== ""
                    width: 34
                    height: 34
                    radius: SkinTheme.radiusSmall
                    color: backMouse.containsMouse ? SkinTheme.accentCyanGlow : SkinTheme.bgCard
                    border.color: SkinTheme.borderMuted
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "←"
                        color: SkinTheme.accentCyan
                        font.pixelSize: 16
                        font.bold: true
                    }

                    MouseArea {
                        id: backMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: backToCreators()
                    }
                }

                // Title info
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    RowLayout {
                        spacing: 8

                        Text {
                            text: selectedCreatorId === "" ? creatorsView.tr("creators.title") : (selectedCreatorData ? selectedCreatorData.name : "Creator Skins")
                            color: SkinTheme.textPrimary
                            font.family: SkinTheme.fontMono
                            font.pixelSize: 14
                            font.bold: true
                            font.letterSpacing: 1.5
                        }

                        // Telegram pill
                        Rectangle {
                            visible: selectedCreatorData && selectedCreatorData.telegram
                            height: 20
                            radius: 10
                            color: SkinTheme.accentCyanGlow
                            border.color: SkinTheme.accentCyan
                            border.width: 1
                            Layout.leftMargin: 4
                            implicitWidth: tgPillRow.implicitWidth + 16

                            RowLayout {
                                id: tgPillRow
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    text: "✈️"
                                    font.pixelSize: 10
                                }

                                Text {
                                    text: selectedCreatorData ? selectedCreatorData.telegram : ""
                                    color: SkinTheme.accentCyan
                                    font.family: SkinTheme.fontMono
                                    font.pixelSize: 10
                                    font.bold: true
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (selectedCreatorData && selectedCreatorData.telegram) {
                                        app.openExternalUrl(selectedCreatorData.telegram)
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        text: selectedCreatorId === "" ? creatorsView.tr("creators.subtitle") : ((selectedCreatorData ? selectedCreatorData.description : "") || "Custom VPK mods")
                        color: SkinTheme.textMuted
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }
                }

                // Action Buttons
                RowLayout {
                    spacing: 10

                    // Button when in Overview: "+ ADD CREATOR / CHANNEL"
                    Rectangle {
                        visible: selectedCreatorId === ""
                        Layout.preferredHeight: 34
                        Layout.preferredWidth: 190
                        radius: SkinTheme.radiusSmall
                        color: addChannelMouse.containsMouse ? SkinTheme.accentCyanHover : SkinTheme.accentCyan

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: creatorsView.tr("creators.add_creator")
                                color: "#050811"
                                font.family: SkinTheme.fontMono
                                font.pixelSize: 11
                                font.bold: true
                                font.letterSpacing: 0.5
                            }
                        }

                        MouseArea {
                            id: addChannelMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: addCreatorModalInstance.openWith("")
                        }
                    }

                    // Button when in Overview: "📦 IMPORT PACK"
                    Rectangle {
                        visible: selectedCreatorId === ""
                        Layout.preferredHeight: 34
                        Layout.preferredWidth: 140
                        radius: SkinTheme.radiusSmall
                        color: importPackMouse.containsMouse ? SkinTheme.bgCardHover : "transparent"
                        border.color: SkinTheme.borderMuted
                        border.width: 1

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: creatorsView.tr("creators.import_pack")
                                color: SkinTheme.textSecondary
                                font.family: SkinTheme.fontMono
                                font.pixelSize: 11
                                font.bold: true
                            }
                        }

                        MouseArea {
                            id: importPackMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                var packFile = app.chooseFile("Import Creator Pack", "Pack Archives (*.zip *.ihpack)")
                                if (packFile) {
                                    app.importCreatorPack(packFile)
                                }
                            }
                        }
                    }

                    // Button when inside Creator Detail: "+ ADD VPK SKIN"
                    Rectangle {
                        visible: selectedCreatorId !== ""
                        Layout.preferredHeight: 34
                        Layout.preferredWidth: 150
                        radius: SkinTheme.radiusSmall
                        color: addModBtnMouse.containsMouse ? SkinTheme.accentCyanHover : SkinTheme.accentCyan

                        Text {
                            anchors.centerIn: parent
                            text: creatorsView.tr("creators.add_mod")
                            color: "#050811"
                            font.family: SkinTheme.fontMono
                            font.pixelSize: 11
                            font.bold: true
                        }

                        MouseArea {
                            id: addModBtnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (selectedCreatorData) {
                                    addModModalInstance.openForCreator(selectedCreatorData.id, selectedCreatorData.name, "")
                                }
                            }
                        }
                    }

                    // Button when inside Creator Detail: "📁 SCAN FOLDER"
                    Rectangle {
                        visible: selectedCreatorId !== ""
                        Layout.preferredHeight: 34
                        Layout.preferredWidth: 140
                        radius: SkinTheme.radiusSmall
                        color: scanFolderBtnMouse.containsMouse ? SkinTheme.bgCardHover : "transparent"
                        border.color: SkinTheme.borderMuted
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: creatorsView.tr("creators.import_folder")
                            color: SkinTheme.textSecondary
                            font.family: SkinTheme.fontMono
                            font.pixelSize: 11
                            font.bold: true
                        }

                        MouseArea {
                            id: scanFolderBtnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                var folder = app.chooseFolder("Select Folder with VPK skins")
                                if (folder && selectedCreatorId) {
                                    app.importCreatorFolder(selectedCreatorId, folder)
                                }
                            }
                        }
                    }

                    // Button when inside Creator Detail: "📦 EXPORT PACK"
                    Rectangle {
                        visible: selectedCreatorId !== ""
                        Layout.preferredHeight: 34
                        Layout.preferredWidth: 40
                        radius: SkinTheme.radiusSmall
                        color: exportPackMouse.containsMouse ? SkinTheme.bgCardHover : "transparent"
                        border.color: SkinTheme.borderMuted
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "📦"
                            font.pixelSize: 14
                        }

                        MouseArea {
                            id: exportPackMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (selectedCreatorData) {
                                    var saveFile = app.chooseSaveFile("Export Creator Pack", selectedCreatorData.name + "_pack.zip", "ZIP Archive (*.zip)")
                                    if (saveFile) {
                                        app.exportCreatorPack(selectedCreatorId, saveFile)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ==========================================
        // 1. CREATOR CARDS HUB (selectedCreatorId == "")
        // ==========================================
        Item {
            visible: selectedCreatorId === ""
            Layout.fillWidth: true
            Layout.fillHeight: true

            ScrollView {
                anchors.fill: parent
                anchors.margins: 24
                clip: true
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical: NeonScrollBar { }

                ColumnLayout {
                    width: parent.width
                    spacing: 20

                    // Search Creators Input
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 40
                            radius: SkinTheme.radiusSmall
                            color: SkinTheme.bgCard
                            border.color: SkinTheme.borderMuted
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 8

                                Text {
                                    text: "🔍"
                                    font.pixelSize: 12
                                    opacity: 0.6
                                }

                                TextInput {
                                    id: creatorSearchInput
                                    Layout.fillWidth: true
                                    verticalAlignment: TextInput.AlignVCenter
                                    color: SkinTheme.textPrimary
                                    font.pixelSize: 12
                                    font.family: SkinTheme.fontFamily

                                    Text {
                                        text: "Search channels, creators, tags..."
                                        color: SkinTheme.textMuted
                                        font.pixelSize: 12
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: !creatorSearchInput.text.length && !creatorSearchInput.activeFocus
                                    }
                                }
                            }
                        }
                    }

                    // Empty Creators State
                    Rectangle {
                        visible: creatorsList.length === 0
                        Layout.fillWidth: true
                        Layout.preferredHeight: 280
                        radius: SkinTheme.radiusLarge
                        color: SkinTheme.bgCard
                        border.color: SkinTheme.borderMuted
                        border.width: 1

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 12

                            Text {
                                text: "✈️"
                                font.pixelSize: 42
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Text {
                                text: creatorsView.tr("creators.no_creators")
                                color: SkinTheme.textPrimary
                                font.family: SkinTheme.fontMono
                                font.pixelSize: 14
                                font.bold: true
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Rectangle {
                                Layout.alignment: Qt.AlignHCenter
                                Layout.preferredHeight: 36
                                Layout.preferredWidth: 200
                                radius: SkinTheme.radiusSmall
                                color: SkinTheme.accentCyan

                                Text {
                                    anchors.centerIn: parent
                                    text: creatorsView.tr("creators.add_creator")
                                    color: "#050811"
                                    font.family: SkinTheme.fontMono
                                    font.pixelSize: 11
                                    font.bold: true
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: addCreatorModalInstance.openWith("")
                                }
                            }
                        }
                    }

                    // Creators Grid Flow
                    Flow {
                        Layout.fillWidth: true
                        spacing: 20

                        Repeater {
                            model: {
                                var q = creatorSearchInput.text.toLowerCase().trim()
                                if (!q) return creatorsList
                                return creatorsList.filter(function(c) {
                                    return (c.name && c.name.toLowerCase().indexOf(q) !== -1) ||
                                           (c.telegram && c.telegram.toLowerCase().indexOf(q) !== -1) ||
                                           (c.description && c.description.toLowerCase().indexOf(q) !== -1)
                                })
                            }

                            delegate: Rectangle {
                                width: Math.max(340, (parent.width - 40) / 3)
                                height: 210
                                radius: SkinTheme.radiusLarge
                                color: creatorMouse.containsMouse ? SkinTheme.bgCardHover : SkinTheme.bgCard
                                border.color: creatorMouse.containsMouse ? SkinTheme.accentCyan : SkinTheme.borderMuted
                                border.width: 1
                                clip: true

                                Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }
                                Behavior on border.color { ColorAnimation { duration: SkinTheme.animFast } }

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 18
                                    spacing: 12

                                    // Top Row: Avatar + Name + Badge
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 12

                                        Rectangle {
                                            width: 46
                                            height: 46
                                            radius: 23
                                            color: SkinTheme.bgVoid
                                            border.color: SkinTheme.accentCyan
                                            border.width: 1
                                            clip: true

                                            Image {
                                                anchors.fill: parent
                                                source: modelData.avatar ? "file:///" + modelData.avatar.replace(/\\/g, "/") : ""
                                                fillMode: Image.PreserveAspectCrop
                                                visible: modelData.avatar !== ""
                                            }

                                            Text {
                                                anchors.centerIn: parent
                                                text: "✈️"
                                                font.pixelSize: 20
                                                visible: !modelData.avatar
                                            }
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 2

                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 6

                                                Text {
                                                    text: modelData.name || "Custom Creator"
                                                    color: SkinTheme.textPrimary
                                                    font.family: SkinTheme.fontMono
                                                    font.pixelSize: 13
                                                    font.bold: true
                                                    Layout.fillWidth: true
                                                    elide: Text.ElideRight
                                                }

                                                Rectangle {
                                                    height: 16
                                                    radius: 8
                                                    color: SkinTheme.accentViolet
                                                    opacity: 0.8
                                                    implicitWidth: badgeText.implicitWidth + 10

                                                    Text {
                                                        id: badgeText
                                                        anchors.centerIn: parent
                                                        text: modelData.badge || "TELEGRAM"
                                                        color: "#FFFFFF"
                                                        font.family: SkinTheme.fontMono
                                                        font.pixelSize: 8
                                                        font.bold: true
                                                    }
                                                }
                                            }

                                            // Telegram Link Button
                                            RowLayout {
                                                spacing: 4
                                                visible: Boolean(modelData.telegram)

                                                Text {
                                                    text: modelData.telegram
                                                    color: tgClickMouse.containsMouse ? SkinTheme.accentCyanHover : SkinTheme.accentCyan
                                                    font.family: SkinTheme.fontMono
                                                    font.pixelSize: 11
                                                    font.bold: true

                                                    MouseArea {
                                                        id: tgClickMouse
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: app.openExternalUrl(modelData.telegram)
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // Description
                                    Text {
                                        text: modelData.description || "Custom Dota 2 mod collection"
                                        color: SkinTheme.textSecondary
                                        font.pixelSize: 11
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        elide: Text.ElideRight
                                        maximumLineCount: 2
                                        wrapMode: Text.WordWrap
                                    }

                                    // Bottom Row: Stats & Action Buttons
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8

                                        Rectangle {
                                            height: 24
                                            radius: SkinTheme.radiusSmall
                                            color: SkinTheme.bgVoid
                                            border.color: SkinTheme.borderMuted
                                            border.width: 1
                                            implicitWidth: countText.implicitWidth + 16

                                            Text {
                                                id: countText
                                                anchors.centerIn: parent
                                                text: (modelData.modsCount || (modelData.mods ? modelData.mods.length : 0)) + " " + creatorsView.tr("creators.mods_count") + (modelData.installedCount > 0 ? (" • " + modelData.installedCount + " active") : "")
                                                color: modelData.installedCount > 0 ? SkinTheme.accentEmerald : SkinTheme.textMuted
                                                font.family: SkinTheme.fontMono
                                                font.pixelSize: 9
                                                font.bold: true
                                            }
                                        }

                                        Item { Layout.fillWidth: true }

                                        // Quick Scan Folder
                                        Rectangle {
                                            width: 28
                                            height: 28
                                            radius: SkinTheme.radiusSmall
                                            color: quickScanMouse.containsMouse ? SkinTheme.accentCyanGlow : "transparent"
                                            border.color: SkinTheme.borderMuted
                                            border.width: 1

                                            Text {
                                                anchors.centerIn: parent
                                                text: "📁"
                                                font.pixelSize: 12
                                            }

                                            MouseArea {
                                                id: quickScanMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    var f = app.chooseFolder("Select Folder with VPK skins")
                                                    if (f) {
                                                        app.importCreatorFolder(modelData.id, f)
                                                    }
                                                }
                                            }
                                        }

                                        // Delete Creator
                                        Rectangle {
                                            width: 28
                                            height: 28
                                            radius: SkinTheme.radiusSmall
                                            color: deleteCreatorMouse.containsMouse ? SkinTheme.accentCrimson : "transparent"
                                            border.color: SkinTheme.borderMuted
                                            border.width: 1

                                            Text {
                                                anchors.centerIn: parent
                                                text: "🗑️"
                                                font.pixelSize: 11
                                            }

                                            MouseArea {
                                                id: deleteCreatorMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    app.deleteCreator(modelData.id)
                                                }
                                            }
                                        }

                                        // Explore Button
                                        Rectangle {
                                            height: 28
                                            radius: SkinTheme.radiusSmall
                                            color: exploreMouse.containsMouse ? SkinTheme.accentCyanHover : SkinTheme.accentCyan
                                            implicitWidth: exploreText.implicitWidth + 18

                                            Text {
                                                id: exploreText
                                                anchors.centerIn: parent
                                                text: "SKINS →"
                                                color: "#050811"
                                                font.family: SkinTheme.fontMono
                                                font.pixelSize: 10
                                                font.bold: true
                                                font.letterSpacing: 0.5
                                            }

                                            MouseArea {
                                                id: exploreMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: selectCreator(modelData.id)
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    id: creatorMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    z: -1
                                    onClicked: selectCreator(modelData.id)
                                }
                            }
                        }
                    }
                }
            }
        }

        // ==========================================
        // 2. CREATOR SKINS EXPLORER (selectedCreatorId != "")
        // ==========================================
        Item {
            visible: selectedCreatorId !== ""
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // Filter & Search Bar
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    color: SkinTheme.bgCard

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
                        spacing: 12

                        // Search Skin Input
                        Rectangle {
                            Layout.preferredWidth: 260
                            Layout.preferredHeight: 34
                            radius: SkinTheme.radiusSmall
                            color: SkinTheme.bgVoid
                            border.color: SkinTheme.borderMuted
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 6

                                Text {
                                    text: "🔍"
                                    font.pixelSize: 11
                                    opacity: 0.6
                                }

                                TextInput {
                                    id: skinSearchInput
                                    Layout.fillWidth: true
                                    verticalAlignment: TextInput.AlignVCenter
                                    color: SkinTheme.textPrimary
                                    font.pixelSize: 11
                                    font.family: SkinTheme.fontFamily
                                    text: creatorsView.searchQuery
                                    onTextChanged: creatorsView.searchQuery = text

                                    Text {
                                        text: "Filter skins by name..."
                                        color: SkinTheme.textMuted
                                        font.pixelSize: 11
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: !skinSearchInput.text.length && !skinSearchInput.activeFocus
                                    }
                                }
                            }
                        }

                        // State Filters (All / Installed / Favorites)
                        RowLayout {
                            spacing: 4

                            Repeater {
                                model: [
                                    { id: "all", label: "ALL" },
                                    { id: "installed", label: "INSTALLED" },
                                    { id: "favorites", label: "⭐ FAVORITES" }
                                ]

                                delegate: Rectangle {
                                    height: 30
                                    radius: SkinTheme.radiusSmall
                                    color: creatorsView.filterMode === modelData.id ? SkinTheme.accentCyanGlow : "transparent"
                                    border.color: creatorsView.filterMode === modelData.id ? SkinTheme.accentCyan : SkinTheme.borderMuted
                                    border.width: 1
                                    implicitWidth: tabText.implicitWidth + 16

                                    Text {
                                        id: tabText
                                        anchors.centerIn: parent
                                        text: modelData.label
                                        color: creatorsView.filterMode === modelData.id ? SkinTheme.accentCyan : SkinTheme.textMuted
                                        font.family: SkinTheme.fontMono
                                        font.pixelSize: 10
                                        font.bold: true
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: creatorsView.filterMode = modelData.id
                                    }
                                }
                            }
                        }

                        // Hero quick-filter pills (horizontal scroll)
                        ScrollView {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 34
                            clip: true
                            ScrollBar.vertical.policy: ScrollBar.AlwaysOff
                            ScrollBar.horizontal: NeonScrollBar { }

                            RowLayout {
                                spacing: 6

                                Rectangle {
                                    height: 28
                                    radius: 14
                                    color: creatorsView.heroFilter === "" ? SkinTheme.accentViolet : SkinTheme.bgVoid
                                    border.color: creatorsView.heroFilter === "" ? SkinTheme.accentViolet : SkinTheme.borderMuted
                                    border.width: 1
                                    implicitWidth: allHeroText.implicitWidth + 14

                                    Text {
                                        id: allHeroText
                                        anchors.centerIn: parent
                                        text: "All Heroes"
                                        color: creatorsView.heroFilter === "" ? "#FFFFFF" : SkinTheme.textSecondary
                                        font.pixelSize: 10
                                        font.bold: true
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: creatorsView.heroFilter = ""
                                    }
                                }

                                Repeater {
                                    model: getUniqueHeroes()

                                    delegate: Rectangle {
                                        height: 28
                                        radius: 14
                                        color: creatorsView.heroFilter === modelData ? SkinTheme.accentViolet : SkinTheme.bgVoid
                                        border.color: creatorsView.heroFilter === modelData ? SkinTheme.accentViolet : SkinTheme.borderMuted
                                        border.width: 1
                                        implicitWidth: hText.implicitWidth + 14

                                        Text {
                                            id: hText
                                            anchors.centerIn: parent
                                            text: modelData
                                            color: creatorsView.heroFilter === modelData ? "#FFFFFF" : SkinTheme.textSecondary
                                            font.pixelSize: 10
                                            font.bold: true
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: creatorsView.heroFilter = (creatorsView.heroFilter === modelData ? "" : modelData)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Skins Grid
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                    ScrollBar.vertical: NeonScrollBar { }

                    ColumnLayout {
                        width: parent.width
                        anchors.margins: 20
                        spacing: 16

                        // Empty Skins State
                        Rectangle {
                            visible: filteredMods.length === 0
                            Layout.fillWidth: true
                            Layout.preferredHeight: 320
                            radius: SkinTheme.radiusLarge
                            color: SkinTheme.bgCard
                            border.color: SkinTheme.borderMuted
                            border.width: 1

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 14

                                Text {
                                    text: "📦"
                                    font.pixelSize: 42
                                    Layout.alignment: Qt.AlignHCenter
                                }

                                Text {
                                    text: creatorsView.tr("creators.no_mods")
                                    color: SkinTheme.textPrimary
                                    font.family: SkinTheme.fontMono
                                    font.pixelSize: 14
                                    font.bold: true
                                    Layout.alignment: Qt.AlignHCenter
                                }

                                RowLayout {
                                    Layout.alignment: Qt.AlignHCenter
                                    spacing: 12

                                    Rectangle {
                                        Layout.preferredHeight: 36
                                        Layout.preferredWidth: 160
                                        radius: SkinTheme.radiusSmall
                                        color: SkinTheme.accentCyan

                                        Text {
                                            anchors.centerIn: parent
                                            text: creatorsView.tr("creators.add_mod")
                                            color: "#050811"
                                            font.family: SkinTheme.fontMono
                                            font.pixelSize: 11
                                            font.bold: true
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (selectedCreatorData) {
                                                    addModModalInstance.openForCreator(selectedCreatorData.id, selectedCreatorData.name, "")
                                                }
                                            }
                                        }
                                    }

                                    Rectangle {
                                        Layout.preferredHeight: 36
                                        Layout.preferredWidth: 160
                                        radius: SkinTheme.radiusSmall
                                        color: "transparent"
                                        border.color: SkinTheme.accentCyan
                                        border.width: 1

                                        Text {
                                            anchors.centerIn: parent
                                            text: creatorsView.tr("creators.import_folder")
                                            color: SkinTheme.accentCyan
                                            font.family: SkinTheme.fontMono
                                            font.pixelSize: 11
                                            font.bold: true
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                var folder = app.chooseFolder("Select Folder with VPK skins")
                                                if (folder && selectedCreatorId) {
                                                    app.importCreatorFolder(selectedCreatorId, folder)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Flow Grid of Mod Cards
                        Flow {
                            Layout.fillWidth: true
                            spacing: 16

                            Repeater {
                                model: filteredMods

                                delegate: Item {
                                    width: Math.max(260, (parent.width - 48) / 4)
                                    height: 190

                                    SkinModCard {
                                        anchors.fill: parent
                                        modData: modelData
                                        onClicked: {
                                            creatorsView.modClicked(modelData)
                                        }
                                        onInstallRequested: {
                                            creatorsView.modInstall(modelData)
                                        }
                                        onUninstallRequested: {
                                            creatorsView.modUninstall(modelData)
                                        }
                                        onAddToCartRequested: {
                                            creatorsView.modAddToCart(modelData)
                                        }
                                    }

                                    // Quick Delete Custom Skin Button
                                    Rectangle {
                                        anchors.top: parent.top
                                        anchors.right: parent.right
                                        anchors.margins: 8
                                        width: 24
                                        height: 24
                                        radius: 12
                                        color: delSkinMouse.containsMouse ? SkinTheme.accentCrimson : "#99000000"
                                        border.color: SkinTheme.borderMuted
                                        border.width: 1
                                        z: 10

                                        Text {
                                            anchors.centerIn: parent
                                            text: "✕"
                                            color: "#FFFFFF"
                                            font.pixelSize: 10
                                            font.bold: true
                                        }

                                        MouseArea {
                                            id: delSkinMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                app.deleteCreatorMod(selectedCreatorId, modelData.id)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
