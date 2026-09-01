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

        // ═══════════════════════════════════════════
        // HEADER BAR
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

                ColumnLayout {
                    spacing: 2
                    RowLayout {
                        spacing: 8
                        Text {
                            text: "FPS BOOST & TWEAKS"
                            color: SkinTheme.textPrimary
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: SkinTheme.fontSizeTitle
                            font.bold: true
                            font.letterSpacing: 0.5
                        }

                        Rectangle {
                            height: 20
                            radius: SkinTheme.radiusPill
                            implicitWidth: fpsBadge.implicitWidth + 14
                            color: SkinTheme.accentAmberGlow
                            border.color: SkinTheme.accentAmber
                            border.width: 1

                            Text {
                                id: fpsBadge
                                anchors.centerIn: parent
                                text: "PERFORMANCE"
                                color: SkinTheme.accentAmber
                                font.family: SkinTheme.fontMono
                                font.pixelSize: 8
                                font.bold: true
                            }
                        }
                    }

                    Text {
                        text: "Simplified trees, minimal flat terrains, particle reduction, and shader tweaks"
                        color: SkinTheme.textSecondary
                        font.family: SkinTheme.fontFamily
                        font.pixelSize: SkinTheme.fontSizeSmall
                    }
                }

                Item { Layout.fillWidth: true }

                // Filter Pills
                Rectangle {
                    height: 34
                    radius: SkinTheme.radiusMedium
                    color: SkinTheme.bgCard
                    border.color: SkinTheme.borderMuted
                    border.width: 1
                    implicitWidth: segFpsRow.implicitWidth + 8

                    RowLayout {
                        id: segFpsRow
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
                                implicitWidth: segFpsText.implicitWidth + 16
                                color: fpsBoostView.filterMode === modelData.id
                                       ? SkinTheme.accentCyan
                                       : (segFpsMouse.containsMouse ? SkinTheme.bgCardHover : "transparent")

                                Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

                                Text {
                                    id: segFpsText
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: fpsBoostView.filterMode === modelData.id ? "#FFFFFF" : SkinTheme.textSecondary
                                    font.family: SkinTheme.fontFamily
                                    font.pixelSize: SkinTheme.fontSizeSmall
                                    font.bold: true
                                }

                                MouseArea {
                                    id: segFpsMouse
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
                    height: 34
                    radius: SkinTheme.radiusMedium
                    color: SkinTheme.bgInput
                    border.color: searchFpsInput.activeFocus ? SkinTheme.accentCyan : SkinTheme.borderMuted
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
                            color: searchFpsInput.activeFocus ? SkinTheme.accentCyan : SkinTheme.textMuted
                        }

                        TextInput {
                            id: searchFpsInput
                            Layout.fillWidth: true
                            color: SkinTheme.textPrimary
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: SkinTheme.fontSizeBody
                            clip: true
                            selectByMouse: true
                            text: fpsBoostView.searchQuery

                            onTextChanged: fpsBoostView.searchQuery = text

                            Text {
                                text: "Search tweaks..."
                                color: SkinTheme.textMuted
                                font.family: SkinTheme.fontFamily
                                font.pixelSize: SkinTheme.fontSizeBody
                                visible: !searchFpsInput.text && !searchFpsInput.activeFocus
                            }
                        }

                        Rectangle {
                            width: 18
                            height: 18
                            radius: SkinTheme.radiusSmall
                            color: SkinTheme.bgCardHover
                            visible: searchFpsInput.text !== ""

                            Text {
                                anchors.centerIn: parent
                                text: "✕"
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

        // ═══════════════════════════════════════════
        // SUBCATEGORY TABS BAR
        // ═══════════════════════════════════════════
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 46
            color: SkinTheme.bgDark

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: SkinTheme.borderSubtle
            }

            ListView {
                id: tabsList
                anchors.fill: parent
                anchors.leftMargin: SkinTheme.spacingLG
                anchors.rightMargin: SkinTheme.spacingLG
                orientation: ListView.Horizontal
                spacing: 8
                clip: true
                model: [
                    { id: "trees", label: "🌲 Simplified Trees" },
                    { id: "shaders", label: "🎨 Shaders & Outline" },
                    { id: "terrains", label: "🏝 Flat Terrains" },
                    { id: "optimization", label: "⚙ Optimization Configs" },
                    { id: "tools", label: "🛠 Game Tools" }
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
                        color: activeCategoryId === modelData.id ? "#FFFFFF" : SkinTheme.textSecondary
                        font.family: SkinTheme.fontFamily
                        font.pixelSize: SkinTheme.fontSizeSmall
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

        // ═══════════════════════════════════════════
        // COMPETITIVE LAUNCH OPTIONS QUICK BANNER
        // ═══════════════════════════════════════════
        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: SkinTheme.spacingLG
            Layout.rightMargin: SkinTheme.spacingLG
            Layout.topMargin: SkinTheme.spacingSM
            Layout.preferredHeight: 48
            radius: SkinTheme.radiusMedium
            color: SkinTheme.bgCard
            border.color: SkinTheme.borderMuted
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 12
                spacing: 12

                Text {
                    text: "🚀"
                    font.pixelSize: 14
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    Text {
                        text: "COMPETITIVE PRO LAUNCH OPTIONS (-novid -high -map dota -nohltv -nojoy +fps_max 0)"
                        color: SkinTheme.textPrimary
                        font.family: SkinTheme.fontMono
                        font.pixelSize: 10
                        font.bold: true
                    }
                    Text {
                        text: "Removes intro, pre-caches maps, maximizes CPU priority, and unlocks maximum framerate."
                        color: SkinTheme.textMuted
                        font.family: SkinTheme.fontFamily
                        font.pixelSize: 9
                    }
                }

                Rectangle {
                    height: 28
                    radius: SkinTheme.radiusSmall
                    implicitWidth: copyOptsText.implicitWidth + 18
                    color: copyOptsMouse.containsMouse ? SkinTheme.accentCyanHover : SkinTheme.accentCyan

                    RowLayout {
                        id: copyOptsText
                        anchors.centerIn: parent
                        spacing: 4
                        Text { text: "📋"; font.pixelSize: 9 }
                        Text {
                            text: "COPY LAUNCH OPTIONS"
                            color: "#050811"
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: SkinTheme.fontSizeTiny
                            font.bold: true
                        }
                    }

                    MouseArea {
                        id: copyOptsMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (typeof app !== "undefined" && app) {
                                app.getOptimizedLaunchOptions()
                            }
                        }
                    }
                }
            }
        }

        // ═══════════════════════════════════════════
        // MOD CARDS GRID
        // ═══════════════════════════════════════════
        GridView {
            id: fpsGrid
            Layout.fillWidth: true
            Layout.fillHeight: true
            cellWidth: Math.max(300, Math.floor(width / Math.max(1, Math.floor(width / 340))))
            cellHeight: cellWidth * 0.58 + 16
            model: currentMods
            displayMarginBeginning: 20
            displayMarginEnd: 20
            clip: true

            ScrollBar.vertical: NeonScrollBar {}

            delegate: Item {
                width: fpsGrid.cellWidth
                height: fpsGrid.cellHeight

                SkinModCard {
                    anchors.centerIn: parent
                    modData: modelData

                    onClicked: fpsBoostView.modClicked(modelData)
                    onInstallRequested: fpsBoostView.modInstall(modelData)
                    onUninstallRequested: fpsBoostView.modUninstall(modelData)
                    onAddToCartRequested: fpsBoostView.modAddToCart(modelData)
                }
            }
        }

        // ═══════════════════════════════════════════
        // EMPTY STATE
        // ═══════════════════════════════════════════
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: currentMods.length === 0

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 12

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "⚡"
                    font.pixelSize: 32
                    color: SkinTheme.textMuted
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "NO TWEAKS FOUND"
                    color: SkinTheme.textPrimary
                    font.family: SkinTheme.fontFamily
                    font.pixelSize: SkinTheme.fontSizeTitle
                    font.bold: true
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Try selecting another category or clearing your search filter"
                    color: SkinTheme.textSecondary
                    font.family: SkinTheme.fontFamily
                    font.pixelSize: SkinTheme.fontSizeBody
                }
            }
        }
    }
}
