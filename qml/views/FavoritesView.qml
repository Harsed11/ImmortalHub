import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"
import "../components"

Item {
    id: favoritesView

    property var favoritesList: []
    property var filteredList: []
    property string searchQuery: ""

    signal modClicked(var mod)
    signal modInstall(var mod)
    signal modUninstall(var mod)
    signal modAddToCart(var mod)

    Component.onCompleted: loadFavorites()

    Connections {
        target: app
        function onFavoritesChanged() { loadFavorites() }
        function onInstalledModsChanged() { loadFavorites() }
    }

    function loadFavorites() {
        var raw = app.getFavorites()
        try {
            favoritesList = JSON.parse(raw)
        } catch(e) {
            favoritesList = []
        }
        filterFavorites()
    }

    function filterFavorites() {
        if (searchQuery.trim() !== "") {
            var q = searchQuery.toLowerCase().trim()
            filteredList = favoritesList.filter(function(m) {
                return m.name.toLowerCase().indexOf(q) !== -1 || (m.hero && m.hero.toLowerCase().indexOf(q) !== -1)
            })
        } else {
            filteredList = favoritesList
        }
    }

    onSearchQueryChanged: filterFavorites()

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
                            text: "FAVORITES"
                            color: SkinTheme.textPrimary
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: SkinTheme.fontSizeTitle
                            font.bold: true
                            font.letterSpacing: 0.5
                        }

                        Rectangle {
                            height: 20
                            radius: SkinTheme.radiusPill
                            implicitWidth: favCountBadge.implicitWidth + 14
                            color: favoritesList.length > 0 ? SkinTheme.accentAmberGlow : SkinTheme.bgCard
                            border.color: favoritesList.length > 0 ? SkinTheme.accentAmber : SkinTheme.borderMuted
                            border.width: 1

                            Text {
                                id: favCountBadge
                                anchors.centerIn: parent
                                text: favoritesList.length + " STARRED"
                                color: favoritesList.length > 0 ? SkinTheme.accentAmber : SkinTheme.textMuted
                                font.family: SkinTheme.fontMono
                                font.pixelSize: 8
                                font.bold: true
                            }
                        }
                    }

                    Text {
                        text: "Your curated list of preferred custom skins and items for quick access"
                        color: SkinTheme.textSecondary
                        font.family: SkinTheme.fontFamily
                        font.pixelSize: SkinTheme.fontSizeSmall
                    }
                }

                Item { Layout.fillWidth: true }

                // Search Input
                Rectangle {
                    width: 220
                    height: 34
                    radius: SkinTheme.radiusMedium
                    color: SkinTheme.bgInput
                    border.color: searchFavInput.activeFocus ? SkinTheme.accentCyan : SkinTheme.borderMuted
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
                            color: searchFavInput.activeFocus ? SkinTheme.accentCyan : SkinTheme.textMuted
                        }

                        TextInput {
                            id: searchFavInput
                            Layout.fillWidth: true
                            color: SkinTheme.textPrimary
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: SkinTheme.fontSizeBody
                            clip: true
                            selectByMouse: true
                            text: favoritesView.searchQuery

                            onTextChanged: favoritesView.searchQuery = text

                            Text {
                                text: "Filter favorites..."
                                color: SkinTheme.textMuted
                                font.family: SkinTheme.fontFamily
                                font.pixelSize: SkinTheme.fontSizeBody
                                visible: !searchFavInput.text && !searchFavInput.activeFocus
                            }
                        }

                        Rectangle {
                            width: 18
                            height: 18
                            radius: SkinTheme.radiusSmall
                            color: SkinTheme.bgCardHover
                            visible: searchFavInput.text !== ""

                            Text {
                                anchors.centerIn: parent
                                text: "✕"
                                color: SkinTheme.textSecondary
                                font.pixelSize: 9
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: searchFavInput.text = ""
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
            id: favGrid
            Layout.fillWidth: true
            Layout.fillHeight: true
            cellWidth: Math.max(300, Math.floor(width / Math.max(1, Math.floor(width / 340))))
            cellHeight: cellWidth * 0.58 + 16
            model: filteredList
            displayMarginBeginning: 20
            displayMarginEnd: 20
            clip: true

            ScrollBar.vertical: NeonScrollBar {}

            delegate: Item {
                width: favGrid.cellWidth
                height: favGrid.cellHeight

                SkinModCard {
                    anchors.centerIn: parent
                    modData: modelData

                    onClicked: favoritesView.modClicked(modelData)
                    onInstallRequested: favoritesView.modInstall(modelData)
                    onUninstallRequested: favoritesView.modUninstall(modelData)
                    onAddToCartRequested: favoritesView.modAddToCart(modelData)
                }
            }
        }

        // ═══════════════════════════════════════════
        // EMPTY STATE
        // ═══════════════════════════════════════════
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: filteredList.length === 0

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 12

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "★"
                    font.pixelSize: 36
                    color: SkinTheme.accentAmber
                    opacity: 0.6
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: favoritesList.length === 0
                          ? "NO FAVORITE SKINS YET"
                          : "NO FAVORITES MATCHING SEARCH"
                    color: SkinTheme.textPrimary
                    font.family: SkinTheme.fontFamily
                    font.pixelSize: SkinTheme.fontSizeTitle
                    font.bold: true
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Click the star icon ★ on any skin card to add it to your favorites"
                    color: SkinTheme.textSecondary
                    font.family: SkinTheme.fontFamily
                    font.pixelSize: SkinTheme.fontSizeBody
                }
            }
        }
    }
}
