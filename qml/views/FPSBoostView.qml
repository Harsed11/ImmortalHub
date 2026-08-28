import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"
import "../components"

Item {
    id: fpsBoostView

    property var categoryIds: ["trees", "shaders", "terrains", "optimization", "tools"]
    property string activeCategoryId: "trees"
    property string searchQuery: ""
    property string filterMode: "all" // "all", "installed", "favorites"
    property var currentMods: []
    property var cachedMods: []

    signal modClicked(var mod)
    signal modInstall(var mod)
    signal modUninstall(var mod)
    signal modAddToCart(var mod)

    onActiveCategoryIdChanged: loadCategoryData()
    onSearchQueryChanged: filterMods()
    onFilterModeChanged: filterMods()

    Component.onCompleted: loadCategoryData()

    Connections {
        target: app
        function onModsLoaded() { loadCategoryData() }
        function onInstalledModsChanged() { filterMods() }
        function onFavoritesChanged() { filterMods() }
    }

    function loadCategoryData() {
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

        // Header Bar with FPS Pro Banner
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 74
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
                            text: "⚡ FPS Boost & Game Tweaks"
                            color: SkinTheme.textPrimary
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: SkinTheme.fontSizeTitle
                            font.bold: true
                        }

                        Rectangle {
                            height: 20
                            radius: 10
                            implicitWidth: fpsBadge.implicitWidth + 14
                            color: "#122e23"
                            border.color: SkinTheme.accentEmerald
                            border.width: 1

                            Text {
                                id: fpsBadge
                                anchors.centerIn: parent
                                text: "PRO PERFORMANCE"
                                color: SkinTheme.accentEmerald
                                font.family: SkinTheme.fontFamily
                                font.pixelSize: 9
                                font.bold: true
                                font.letterSpacing: 0.6
                            }
                        }
                    }

                    Text {
                        text: "Simplified trees (vision & FPS), minimal flat terrains, particle reduction, and performance shaders."
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
                    implicitWidth: segFpsRow.implicitWidth + 8

                    RowLayout {
                        id: segFpsRow
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
                                implicitWidth: segFpsText.implicitWidth + 18
                                color: fpsBoostView.filterMode === modelData.id ? SkinTheme.accentCyan : "transparent"

                                Text {
                                    id: segFpsText
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: fpsBoostView.filterMode === modelData.id ? "#0a0d14" : SkinTheme.textSecondary
                                    font.family: SkinTheme.fontFamily
                                    font.pixelSize: 11
                                    font.bold: fpsBoostView.filterMode === modelData.id
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: fpsBoostView.filterMode = modelData.id
                                }
                            }
                        }
                    }
                }

                // Search Input
                Rectangle {
                    width: 220
                    height: 36
                    radius: SkinTheme.radiusMedium
                    color: SkinTheme.bgInput
                    border.color: searchFpsInput.activeFocus ? SkinTheme.accentCyan : SkinTheme.borderMuted
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
                            id: searchFpsInput
                            Layout.fillWidth: true
                            color: SkinTheme.textPrimary
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: 12
                            clip: true
                            selectByMouse: true
                            text: fpsBoostView.searchQuery

                            onTextChanged: fpsBoostView.searchQuery = text

                            Text {
                                text: "Search tweaks..."
                                color: SkinTheme.textMuted
                                font.pixelSize: 12
                                visible: !searchFpsInput.text && !searchFpsInput.activeFocus
                            }
                        }

                        Rectangle {
                            width: 18
                            height: 18
                            radius: 9
                            color: SkinTheme.bgCardHover
                            visible: searchFpsInput.text !== ""

                            Text {
                                anchors.centerIn: parent
                                text: "вњ•"
                                color: SkinTheme.textSecondary
                                font.pixelSize: 9
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: searchFpsInput.text = ""
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
                model: [
                    { id: "trees", label: "🌲 Simplified Trees (Vision & FPS)" },
                    { id: "shaders", label: "🎨 Shaders & Outline" },
                    { id: "terrains", label: "🏝 Flat & Minified Terrains" },
                    { id: "optimization", label: "⚙ Optimization Configs" },
                    { id: "tools", label: "⚙ Game Tools" }
                ]

                delegate: Rectangle {
                    height: 30
                    anchors.verticalCenter: parent.verticalCenter
                    radius: SkinTheme.radiusPill
                    implicitWidth: tabLabel.implicitWidth + 24
                    color: activeCategoryId === modelData.id
                           ? SkinTheme.accentCyan
                           : (tabMouse.containsMouse ? SkinTheme.bgCardHover : SkinTheme.bgCard)
                    border.color: activeCategoryId === modelData.id ? SkinTheme.accentCyan : SkinTheme.borderMuted
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

                    Text {
                        id: tabLabel
                        anchors.centerIn: parent
                        text: modelData.label
                        color: activeCategoryId === modelData.id
                               ? "#000000"
                               : (tabMouse.containsMouse ? SkinTheme.textPrimary : SkinTheme.textSecondary)
                        font.family: SkinTheme.fontFamily
                        font.pixelSize: 11
                        font.bold: activeCategoryId === modelData.id
                    }

                    MouseArea {
                        id: tabMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: activeCategoryId = modelData.id
                    }
                }
            }
        }

        // Mod Cards Grid
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ScrollBar.vertical: ScrollBar {
                width: 8
                policy: ScrollBar.AsNeeded
                contentItem: Rectangle {
                    radius: 4
                    color: SkinTheme.accentCyan
                    opacity: 0.4
                }
            }

            GridView {
                id: fpsGrid
                width: parent.width
                cellWidth: Math.max(220, Math.floor(width / Math.max(1, Math.floor(width / 240))))
                cellHeight: 270
                model: currentMods
                displayMarginBeginning: 20
                displayMarginEnd: 20

                delegate: Item {
                    width: fpsGrid.cellWidth
                    height: fpsGrid.cellHeight

                    SkinModCard {
                        anchors.centerIn: parent
                        width: fpsGrid.cellWidth - 12
                        modData: modelData

                        onClicked: fpsBoostView.modClicked(modelData)
                        onInstallRequested: fpsBoostView.modInstall(modelData)
                        onUninstallRequested: fpsBoostView.modUninstall(modelData)
                        onAddToCartRequested: fpsBoostView.modAddToCart(modelData)
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
                            text: "⚡"
                            font.pixelSize: 42
                            opacity: 0.6
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "No tweaks found in this category"
                            color: SkinTheme.textPrimary
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: 15
                            font.bold: true
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Try selecting another optimization tab or clearing search."
                            color: SkinTheme.textMuted
                            font.pixelSize: 12
                        }
                    }
                }
            }
        }
    }
}

