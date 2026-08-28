import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"
import "../components"

Item {
    id: categoryView

    property var categoryIds: []
    property string activeCategoryId: categoryIds.length > 0 ? categoryIds[0] : ""
    property string searchQuery: ""
    property string filterMode: "all" // "all", "installed", "favorites"
    property var currentMods: []
    property var cachedMods: []

    signal modClicked(var mod)
    signal modInstall(var mod)
    signal modUninstall(var mod)
    signal modAddToCart(var mod)

    onCategoryIdsChanged: {
        if (categoryIds.length > 0) {
            activeCategoryId = categoryIds[0]
            loadCategoryData()
        }
    }

    onActiveCategoryIdChanged: {
        loadCategoryData()
    }

    onSearchQueryChanged: {
        filterMods()
    }

    onFilterModeChanged: {
        filterMods()
    }

    Connections {
        target: app
        function onModsLoaded() { loadCategoryData() }
        function onInstalledModsChanged() { filterMods() }
        function onFavoritesChanged() { filterMods() }
    }

    function loadCategoryData() {
        if (!activeCategoryId) return
        var raw = app.getModsForCategory(activeCategoryId)
        try {
            cachedMods = JSON.parse(raw)
        } catch(e) {
            cachedMods = []
        }
        filterMods()
    }

    function filterMods() {
        var result = cachedMods

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

        currentMods = result
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header Bar
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

                ColumnLayout {
                    spacing: 3
                    RowLayout {
                        spacing: 8
                        Text {
                            text: app.translate(activeCategoryId)
                            color: SkinTheme.textPrimary
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: SkinTheme.fontSizeTitle
                            font.bold: true
                        }

                        Text {
                            text: "// " + currentMods.length + " items"
                            color: SkinTheme.textMuted
                            font.family: SkinTheme.fontMono
                            font.pixelSize: 10
                            font.letterSpacing: 0.5
                        }
                    }

                    Text {
                        text: "Custom mod collections, visual effects, world assets, and game modifications."
                        color: SkinTheme.textMuted
                        font.pixelSize: 11
                    }
                }

                Item { Layout.fillWidth: true }

                // Quick Filter Segmented Buttons (All / Installed / Favorites)
                Rectangle {
                    height: 36
                    radius: SkinTheme.radiusMedium
                    color: SkinTheme.bgInput
                    border.color: SkinTheme.borderMuted
                    border.width: 1
                    implicitWidth: segRow.implicitWidth + 8

                    RowLayout {
                        id: segRow
                        anchors.centerIn: parent
                        spacing: 2

                        Repeater {
                            model: [
                                { id: "all",       label: "All" },
                                { id: "installed", label: "Installed" },
                                { id: "favorites", label: "в­ђ Starred" }
                            ]

                            delegate: Rectangle {
                                height: 28
                                radius: SkinTheme.radiusSmall
                                implicitWidth: segText.implicitWidth + 18
                                                color: categoryView.filterMode === modelData.id ? SkinTheme.accentCyan : (catSegMouse.containsMouse ? SkinTheme.bgCardHover : "transparent")

                                Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

                                Text {
                                    id: segText
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: categoryView.filterMode === modelData.id ? "#060810" : SkinTheme.textSecondary
                                    font.family: SkinTheme.fontMono
                                    font.pixelSize: 10
                                    font.letterSpacing: 0.8
                                    font.bold: categoryView.filterMode === modelData.id
                                }

                                MouseArea {
                                    id: catSegMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: categoryView.filterMode = modelData.id
                                }
                            }
                        }
                    }
                }

                // Search Input
                Rectangle {
                    width: 240
                    height: 36
                    radius: SkinTheme.radiusMedium
                    color: SkinTheme.bgInput
                    border.color: searchInput.activeFocus ? SkinTheme.accentCyan : SkinTheme.borderMuted
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 8
                        spacing: 8

                        Text {
                            text: "⌕"
                            font.pixelSize: 11
                            color: SkinTheme.textMuted
                        }

                        TextInput {
                            id: searchInput
                            Layout.fillWidth: true
                            color: SkinTheme.textPrimary
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: 12
                            clip: true
                            selectByMouse: true
                            text: categoryView.searchQuery

                            onTextChanged: categoryView.searchQuery = text

                            Text {
                                text: "Search in category..."
                                color: SkinTheme.textMuted
                                font.pixelSize: 12
                                visible: !searchInput.text && !searchInput.activeFocus
                            }
                        }

                        Rectangle {
                            width: 18
                            height: 18
                            radius: 9
                            color: SkinTheme.bgCardHover
                            visible: searchInput.text !== ""

                            Text {
                                anchors.centerIn: parent
                                text: "вњ•"
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

        // Subcategory Tabs Bar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            color: SkinTheme.bgDark
            visible: categoryIds.length > 1

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: SkinTheme.borderMuted
            }

            ListView {
                id: tabsList
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                orientation: ListView.Horizontal
                spacing: 8
                clip: true
                model: categoryIds

                delegate: Rectangle {
                    height: 30
                    anchors.verticalCenter: parent.verticalCenter
                    radius: SkinTheme.radiusPill
                    implicitWidth: tabLabel.implicitWidth + 24
                    color: activeCategoryId === modelData
                           ? SkinTheme.accentViolet
                           : (tabMouse.containsMouse ? SkinTheme.bgCardHover : SkinTheme.bgCard)
                    border.color: activeCategoryId === modelData ? SkinTheme.accentVioletHover : SkinTheme.borderMuted
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

                    Text {
                        id: tabLabel
                        anchors.centerIn: parent
                        text: app.translate(modelData)
                        color: activeCategoryId === modelData
                               ? "#ffffff"
                               : (tabMouse.containsMouse ? SkinTheme.textPrimary : SkinTheme.textSecondary)
                        font.family: SkinTheme.fontFamily
                        font.pixelSize: 11
                        font.bold: activeCategoryId === modelData
                    }

                    MouseArea {
                        id: tabMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: activeCategoryId = modelData
                    }
                }
            }
        }

        // Mod Cards Grid
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ScrollBar.vertical: NeonScrollBar {}

            GridView {
                id: grid
                width: parent.width
                cellWidth: Math.max(220, Math.floor(width / Math.max(1, Math.floor(width / 240))))
                cellHeight: 270
                model: currentMods
                displayMarginBeginning: 20
                displayMarginEnd: 20

                delegate: Item {
                    id: cardDelegate
                    width: grid.cellWidth
                    height: grid.cellHeight

                    // Staggered cascade entrance (per-row delay, capped so
                    // far-down rows don't wait forever)
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
                        width: grid.cellWidth - 12
                        modData: modelData

                        onClicked: categoryView.modClicked(modelData)
                        onInstallRequested: categoryView.modInstall(modelData)
                        onUninstallRequested: categoryView.modUninstall(modelData)
                        onAddToCartRequested: categoryView.modAddToCart(modelData)
                    }
                }

                // Empty State
                Item {
                    anchors.centerIn: parent
                    visible: currentMods.length === 0

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 12

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "📦"
                            font.pixelSize: 42
                            opacity: 0.6
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "NO ITEMS AVAILABLE"
                            color: SkinTheme.textPrimary
                            font.family: SkinTheme.fontMono
                            font.pixelSize: 13
                            font.bold: true
                            font.letterSpacing: 1.5
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Try changing subcategories or resetting search filter."
                            color: SkinTheme.textMuted
                            font.pixelSize: 12
                        }

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: 8
                            height: 32
                            radius: SkinTheme.radiusSmall
                            implicitWidth: resetCatText.implicitWidth + 24
                            color: resetCatMouse.containsMouse ? SkinTheme.bgCardHover : "transparent"
                            border.color: SkinTheme.accentCyan
                            border.width: 1

                            Text {
                                id: resetCatText
                                anchors.centerIn: parent
                                text: "RESET FILTER"
                                color: SkinTheme.accentCyan
                                font.family: SkinTheme.fontMono
                                font.pixelSize: 11
                                font.bold: true
                            }

                            MouseArea {
                                id: resetCatMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    categoryView.searchQuery = ""
                                    categoryView.filterMode = "all"
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

