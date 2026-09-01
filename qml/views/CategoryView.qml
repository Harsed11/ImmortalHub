import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"
import "../components"

Item {
    id: categoryView

    property var categoryIds: []
    property string activeCategoryId: categoryIds.length === 1 ? categoryIds[0] : ""
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
            activeCategoryId = categoryIds.length === 1 ? categoryIds[0] : ""
            if (activeCategoryId !== "") {
                loadCategoryData()
            }
        }
    }

    onVisibleChanged: {
        if (visible && categoryIds.length > 1) {
            activeCategoryId = ""
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

                // Back button (when inside a subcategory)
                Rectangle {
                    visible: categoryIds.length > 1 && categoryView.activeCategoryId !== ""
                    width: 32
                    height: 32
                    radius: SkinTheme.radiusMedium
                    color: catBackMouse.containsMouse ? SkinTheme.bgCardHover : SkinTheme.bgCard
                    border.color: SkinTheme.borderMuted
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

                    Text {
                        anchors.centerIn: parent
                        text: "←"
                        font.family: SkinTheme.fontFamily
                        font.pixelSize: 14
                        color: SkinTheme.textPrimary
                    }

                    MouseArea {
                        id: catBackMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: categoryView.activeCategoryId = ""
                    }
                }

                // Title / Breadcrumb
                ColumnLayout {
                    spacing: 2
                    RowLayout {
                        spacing: 6
                        Text {
                            text: activeCategoryId === "" ? "COLLECTIONS" : "COLLECTIONS"
                            color: activeCategoryId === "" ? SkinTheme.textPrimary : SkinTheme.textMuted
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: SkinTheme.fontSizeTitle
                            font.bold: true
                            font.letterSpacing: 0.5
                        }

                        Text {
                            visible: activeCategoryId !== ""
                            text: "›"
                            color: SkinTheme.textMuted
                            font.pixelSize: SkinTheme.fontSizeTitle
                        }

                        Text {
                            visible: activeCategoryId !== ""
                            text: app.translate(activeCategoryId).toUpperCase()
                            color: SkinTheme.accentCyan
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: SkinTheme.fontSizeTitle
                            font.bold: true
                            font.letterSpacing: 0.5
                        }
                    }

                    Text {
                        text: activeCategoryId === ""
                              ? categoryIds.length + " categories available"
                              : currentMods.length + " mods available in this collection"
                        color: SkinTheme.textSecondary
                        font.family: SkinTheme.fontFamily
                        font.pixelSize: SkinTheme.fontSizeSmall
                    }
                }

                Item { Layout.fillWidth: true }

                // Filter Pills (when inside a category)
                Rectangle {
                    visible: activeCategoryId !== ""
                    height: 34
                    radius: SkinTheme.radiusMedium
                    color: SkinTheme.bgCard
                    border.color: SkinTheme.borderMuted
                    border.width: 1
                    implicitWidth: segRow.implicitWidth + 8

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
                                color: categoryView.filterMode === modelData.id
                                       ? SkinTheme.accentCyan
                                       : (catSegMouse.containsMouse ? SkinTheme.bgCardHover : "transparent")

                                Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

                                Text {
                                    id: segText
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: categoryView.filterMode === modelData.id ? "#FFFFFF" : SkinTheme.textSecondary
                                    font.family: SkinTheme.fontFamily
                                    font.pixelSize: SkinTheme.fontSizeSmall
                                    font.bold: true
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
                            text: categoryView.searchQuery

                            onTextChanged: categoryView.searchQuery = text

                            Text {
                                text: "Search category..."
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
            }
        }

        // ═══════════════════════════════════════════
        // CATEGORY SELECTION GRID (Multiple Categories)
        // ═══════════════════════════════════════════
        GridView {
            id: catsGrid
            visible: categoryView.activeCategoryId === "" && categoryIds.length > 1
            Layout.fillWidth: true
            Layout.fillHeight: true
            cellWidth: Math.max(180, Math.floor(width / Math.max(1, Math.floor(width / 200))))
            cellHeight: cellWidth * 0.7 + 14
            model: categoryIds
            displayMarginBeginning: 20
            displayMarginEnd: 20
            clip: true

            ScrollBar.vertical: NeonScrollBar {}

            delegate: Item {
                width: catsGrid.cellWidth
                height: catsGrid.cellHeight

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 6
                    radius: SkinTheme.radiusMedium
                    color: SkinTheme.bgCard
                    border.color: catCardMouse.containsMouse ? SkinTheme.accentCyan : SkinTheme.borderMuted
                    border.width: 1
                    clip: true

                    scale: catCardMouse.containsMouse ? 1.03 : 1.0
                    Behavior on scale { NumberAnimation { duration: SkinTheme.animFast; easing.type: Easing.OutCubic } }
                    Behavior on border.color { ColorAnimation { duration: SkinTheme.animFast } }

                    Image {
                        anchors.fill: parent
                        source: app.getCategoryPreviewImage(modelData)
                        fillMode: Image.PreserveAspectCrop
                        opacity: catCardMouse.containsMouse ? 0.9 : 0.6
                        asynchronous: true
                        Behavior on opacity { NumberAnimation { duration: SkinTheme.animFast } }
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 52
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "transparent" }
                            GradientStop { position: 1.0; color: "#EE08080E" }
                        }
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 10
                        horizontalAlignment: Text.AlignHCenter
                        text: app.translate(modelData)
                        color: catCardMouse.containsMouse ? SkinTheme.accentCyan : SkinTheme.textPrimary
                        font.family: SkinTheme.fontFamily
                        font.pixelSize: SkinTheme.fontSizeBody
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        id: catCardMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: categoryView.activeCategoryId = modelData
                    }
                }
            }
        }

        // ═══════════════════════════════════════════
        // MOD CARDS GRID (When Category is Active)
        // ═══════════════════════════════════════════
        GridView {
            id: grid
            visible: categoryView.activeCategoryId !== ""
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
                width: grid.cellWidth
                height: grid.cellHeight

                SkinModCard {
                    anchors.centerIn: parent
                    modData: modelData

                    onClicked: categoryView.modClicked(modelData)
                    onInstallRequested: categoryView.modInstall(modelData)
                    onUninstallRequested: categoryView.modUninstall(modelData)
                    onAddToCartRequested: categoryView.modAddToCart(modelData)
                }
            }
        }

        // ═══════════════════════════════════════════
        // EMPTY STATE
        // ═══════════════════════════════════════════
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: categoryView.activeCategoryId !== "" && currentMods.length === 0

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 12

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "⊘"
                    font.pixelSize: 32
                    color: SkinTheme.textMuted
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "NO MODS FOUND IN THIS CATEGORY"
                    color: SkinTheme.textPrimary
                    font.family: SkinTheme.fontFamily
                    font.pixelSize: SkinTheme.fontSizeTitle
                    font.bold: true
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Try adjusting your search query or filter"
                    color: SkinTheme.textSecondary
                    font.family: SkinTheme.fontFamily
                    font.pixelSize: SkinTheme.fontSizeBody
                }
            }
        }
    }
}
