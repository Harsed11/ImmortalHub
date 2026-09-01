import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"

Rectangle {
    id: searchModal
    anchors.fill: parent
    color: SkinTheme.bgModalOverlay
    visible: opacity > 0
    opacity: isOpen ? 1 : 0
    z: 750

    Behavior on opacity { NumberAnimation { duration: SkinTheme.animFast } }

    property bool isOpen: false
    property var results: []
    property int selectedIndex: 0
    property string lastQuery: ""

    signal modPicked(var mod)
    signal closeRequested()

    function tr(key, defStr) {
        return (typeof app !== "undefined" && app && app.t) ? app.t(key) : (defStr || "")
    }

    function openWith() {
        isOpen = true
        lastQuery = ""
        results = []
        selectedIndex = 0
        searchField.text = ""
        focusTimer.restart()
    }

    function close() {
        isOpen = false
        closeRequested()
    }

    function runSearch() {
        var q = searchField.text
        lastQuery = q
        if (q.trim().length < 2) {
            results = []
            selectedIndex = 0
            return
        }
        try {
            results = JSON.parse(app.searchMods(q))
            selectedIndex = 0
        } catch (e) {
            results = []
        }
    }

    function moveSelection(delta) {
        if (results.length === 0) return
        var next = selectedIndex + delta
        if (next < 0) next = results.length - 1
        if (next >= results.length) next = 0
        selectedIndex = next
        resultsList.positionViewAtIndex(selectedIndex, ListView.Contain)
    }

    function accept(index) {
        if (index < 0 || index >= results.length) return
        isOpen = false
        modPicked(results[index])
    }

    Timer {
        id: focusTimer
        interval: 60
        onTriggered: searchField.forceActiveFocus()
    }

    // Dismiss on backdrop click
    MouseArea {
        anchors.fill: parent
        enabled: searchModal.isOpen
        onClicked: searchModal.close()
    }

    // Search Dialog Box
    Rectangle {
        id: panel
        anchors.top: parent.top
        anchors.topMargin: 80
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(640, parent.width - 64)
        height: Math.min(500, parent.height - 140)
        radius: SkinTheme.radiusXLarge
        color: SkinTheme.bgModal
        border.color: SkinTheme.borderLight
        border.width: 1
        clip: true

        scale: searchModal.isOpen ? 1.0 : 0.96
        Behavior on scale { NumberAnimation { duration: SkinTheme.animNormal; easing.type: Easing.OutBack } }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // ── Input Bar ──
            RowLayout {
                Layout.fillWidth: true
                Layout.margins: 14
                spacing: 10

                Text {
                    text: "\uE721"
                    font.family: "Segoe MDL2 Assets"
                    font.pixelSize: 14
                    color: searchField.activeFocus ? SkinTheme.accentCyan : SkinTheme.textMuted
                }

                TextField {
                    id: searchField
                    Layout.fillWidth: true
                    placeholderText: searchModal.tr("search.placeholder", "Search skins, heroes, effects...")
                    placeholderTextColor: SkinTheme.textMuted
                    font.family: SkinTheme.fontFamily
                    font.pixelSize: SkinTheme.fontSizeBody
                    color: SkinTheme.textPrimary
                    selectByMouse: true
                    background: Rectangle {
                        radius: SkinTheme.radiusMedium
                        color: SkinTheme.bgInput
                        border.color: searchField.activeFocus ? SkinTheme.accentCyan : SkinTheme.borderMuted
                        border.width: 1
                    }
                    onTextChanged: debounceTimer.restart()
                    onActiveFocusChanged: if (!activeFocus && searchModal.isOpen) searchModal.close()

                    Timer {
                        id: debounceTimer
                        interval: 100
                        onTriggered: searchModal.runSearch()
                    }

                    Keys.priority: Keys.BeforeItem
                    Keys.onPressed: function(event) {
                        if (event.key === Qt.Key_Down) {
                            searchModal.moveSelection(1)
                            event.accepted = true
                        } else if (event.key === Qt.Key_Up) {
                            searchModal.moveSelection(-1)
                            event.accepted = true
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            searchModal.accept(searchModal.selectedIndex)
                            event.accepted = true
                        } else if (event.key === Qt.Key_Escape) {
                            searchModal.close()
                            event.accepted = true
                        }
                    }
                }

                Rectangle {
                    width: 38
                    height: 24
                    radius: SkinTheme.radiusSmall
                    color: SkinTheme.bgCard
                    border.color: SkinTheme.borderMuted
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "ESC"
                        color: SkinTheme.textMuted
                        font.family: SkinTheme.fontMono
                        font.pixelSize: 9
                        font.bold: true
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: SkinTheme.borderSubtle
            }

            // ── Results Area ──
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 8
                    visible: searchModal.results.length === 0

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: searchModal.lastQuery.trim().length < 2
                              ? searchModal.tr("search.min_chars", "Type at least 2 characters to search")
                              : searchModal.tr("search.no_results", "No results found for") + " \"" + searchModal.lastQuery + "\""
                        color: SkinTheme.textMuted
                        font.family: SkinTheme.fontFamily
                        font.pixelSize: SkinTheme.fontSizeBody
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        visible: searchModal.lastQuery.trim().length >= 2
                        text: searchModal.tr("search.hint", "Press Enter to open, Esc to close")
                        color: SkinTheme.textDisabled
                        font.family: SkinTheme.fontMono
                        font.pixelSize: SkinTheme.fontSizeSmall
                    }
                }

                ListView {
                    id: resultsList
                    anchors.fill: parent
                    anchors.margins: 8
                    model: searchModal.results
                    spacing: 4
                    visible: searchModal.results.length > 0
                    boundsBehavior: Flickable.StopAtBounds
                    currentIndex: searchModal.selectedIndex
                    clip: true

                    ScrollBar.vertical: NeonScrollBar {}

                    delegate: Rectangle {
                        width: resultsList.width
                        height: 52
                        radius: SkinTheme.radiusMedium
                        color: resultsList.currentIndex === index
                               ? SkinTheme.bgCardHover
                               : (rowHover.containsMouse ? SkinTheme.bgCard : "transparent")
                        border.color: resultsList.currentIndex === index ? SkinTheme.accentCyan : "transparent"
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12

                            // Left Accent Bar
                            Rectangle {
                                width: 3
                                height: resultsList.currentIndex === index ? 28 : 0
                                radius: 1.5
                                color: SkinTheme.accentCyan
                                Layout.alignment: Qt.AlignVCenter

                                Behavior on height { NumberAnimation { duration: SkinTheme.animFast } }
                            }

                            // Preview Thumbnail
                            Rectangle {
                                Layout.preferredWidth: 40
                                Layout.preferredHeight: 36
                                radius: SkinTheme.radiusSmall
                                color: SkinTheme.bgDark
                                clip: true

                                Image {
                                    anchors.fill: parent
                                    source: modelData.previewUrl || ""
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    visible: status === Image.Ready
                                }
                                Text {
                                    anchors.centerIn: parent
                                    visible: (modelData.previewUrl || "") === ""
                                    text: "🛡"
                                    font.pixelSize: 14
                                    opacity: 0.3
                                }
                            }

                            // Info
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.name
                                    color: SkinTheme.textPrimary
                                    font.family: SkinTheme.fontFamily
                                    font.pixelSize: SkinTheme.fontSizeBody
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: (modelData.hero && modelData.hero !== "" ? modelData.hero + "  •  " : "")
                                          + app.translate(String(modelData.categoryId))
                                    color: SkinTheme.textSecondary
                                    font.family: SkinTheme.fontFamily
                                    font.pixelSize: SkinTheme.fontSizeSmall
                                    elide: Text.ElideRight
                                }
                            }

                            // Active Tag
                            Rectangle {
                                height: 18
                                radius: SkinTheme.radiusSmall
                                implicitWidth: 46
                                color: SkinTheme.accentEmeraldGlow
                                border.color: SkinTheme.accentEmerald
                                border.width: 1
                                visible: Boolean(modelData.isInstalled)

                                Text {
                                    anchors.centerIn: parent
                                    text: "ACTIVE"
                                    color: SkinTheme.accentEmerald
                                    font.family: SkinTheme.fontMono
                                    font.pixelSize: 8
                                    font.bold: true
                                }
                            }

                            // Favorite Star
                            Text {
                                text: "★"
                                color: SkinTheme.accentAmber
                                font.pixelSize: 12
                                visible: Boolean(modelData.isFavorite)
                            }

                            // Return Shortcut Arrow
                            Text {
                                text: "↵"
                                color: SkinTheme.accentCyan
                                font.family: SkinTheme.fontMono
                                font.pixelSize: 12
                                opacity: resultsList.currentIndex === index ? 1.0 : 0.2
                            }
                        }

                        MouseArea {
                            id: rowHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                resultsList.currentIndex = index
                                searchModal.accept(index)
                            }
                        }
                    }
                }
            }

            // ── Footer Hints ──
            Rectangle {
                Layout.fillWidth: true
                height: 32
                color: SkinTheme.bgDark
                border.color: SkinTheme.borderSubtle
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 16

                    Text {
                        text: "↑↓ " + searchModal.tr("search.navigate", "Navigate")
                        color: SkinTheme.textMuted
                        font.family: SkinTheme.fontMono
                        font.pixelSize: SkinTheme.fontSizeTiny
                    }
                    Text {
                        text: "↵ " + searchModal.tr("search.open", "Select")
                        color: SkinTheme.textMuted
                        font.family: SkinTheme.fontMono
                        font.pixelSize: SkinTheme.fontSizeTiny
                    }
                    Text {
                        text: "ESC " + searchModal.tr("search.close", "Close")
                        color: SkinTheme.textMuted
                        font.family: SkinTheme.fontMono
                        font.pixelSize: SkinTheme.fontSizeTiny
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: "Ctrl+K"
                        color: SkinTheme.accentCyan
                        font.family: SkinTheme.fontMono
                        font.pixelSize: SkinTheme.fontSizeTiny
                        font.bold: true
                    }
                }
            }
        }
    }
}
