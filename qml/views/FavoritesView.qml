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
                            text: "в… FAVORITES"
                            color: SkinTheme.textPrimary
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: SkinTheme.fontSizeTitle
                            font.bold: true
                            font.letterSpacing: 1.0
                        }

                        Text {
                            text: "// " + favoritesList.length + " starred"
                            color: SkinTheme.textMuted
                            font.family: SkinTheme.fontMono
                            font.pixelSize: 10
                            font.letterSpacing: 0.5
                        }
                    }

                    Text {
                        text: "Quickly access and batch-install your personal favorite hero skins and mods."
                        color: SkinTheme.textMuted
                        font.pixelSize: 11
                    }
                }

                Item { Layout.fillWidth: true }

                // Search Input
                Rectangle {
                    width: 240
                    height: 36
                    radius: SkinTheme.radiusMedium
                    color: SkinTheme.bgInput
                    border.color: searchFavInput.activeFocus ? SkinTheme.accentCyan : SkinTheme.borderMuted
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
                            id: searchFavInput
                            Layout.fillWidth: true
                            color: SkinTheme.textPrimary
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: 12
                            clip: true
                            selectByMouse: true
                            text: favoritesView.searchQuery

                            onTextChanged: favoritesView.searchQuery = text

                            Text {
                                text: "Filter favorites..."
                                color: SkinTheme.textMuted
                                font.pixelSize: 12
                                visible: !searchFavInput.text && !searchFavInput.activeFocus
                            }
                        }

                        Rectangle {
                            width: 18
                            height: 18
                            radius: 9
                            color: SkinTheme.bgCardHover
                            visible: searchFavInput.text !== ""

                            Text {
                                anchors.centerIn: parent
                                text: "вњ•"
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

        // Mod Cards Grid
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ScrollBar.vertical: NeonScrollBar {}

            GridView {
                id: favGrid
                width: parent.width
                cellWidth: Math.max(220, Math.floor(width / Math.max(1, Math.floor(width / 240))))
                cellHeight: 270
                model: filteredList
                displayMarginBeginning: 20
                displayMarginEnd: 20

                delegate: Item {
                    id: favCardDelegate
                    width: favGrid.cellWidth
                    height: favGrid.cellHeight

                    // Staggered cascade entrance
                    opacity: 0
                    scale: 0.95
                    SequentialAnimation on opacity {
                        running: favCardDelegate.visible
                        PauseAnimation { duration: (index % 18) * 30 }
                        NumberAnimation { to: 1; duration: 300; easing.type: Easing.OutCubic }
                    }
                    SequentialAnimation on scale {
                        running: favCardDelegate.visible
                        PauseAnimation { duration: (index % 18) * 30 }
                        NumberAnimation { to: 1; duration: 320; easing.type: Easing.OutBack }
                    }

                    SkinModCard {
                        anchors.centerIn: parent
                        width: favGrid.cellWidth - 12
                        modData: modelData

                        onClicked: favoritesView.modClicked(modelData)
                        onInstallRequested: favoritesView.modInstall(modelData)
                        onUninstallRequested: favoritesView.modUninstall(modelData)
                        onAddToCartRequested: favoritesView.modAddToCart(modelData)
                    }
                }

                // Empty State
                Item {
                    anchors.centerIn: parent
                    visible: filteredList.length === 0

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 12

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "★"
                            font.pixelSize: 32
                            color: SkinTheme.accentCyan
                            opacity: 0.5
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: favoritesList.length === 0
                                  ? "NO FAVORITES YET"
                                  : "NO MATCHES FOUND"
                            color: SkinTheme.textPrimary
                            font.family: SkinTheme.fontMono
                            font.pixelSize: 13
                            font.bold: true
                            font.letterSpacing: 1.5
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Click в… on any mod card to save it here"
                            color: SkinTheme.textMuted
                            font.pixelSize: 12
                        }
                    }
                }
            }
        }
    }
}

