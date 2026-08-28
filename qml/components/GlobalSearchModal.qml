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

    // Click outside the panel closes the modal
    MouseArea {
        anchors.fill: parent
        enabled: searchModal.isOpen
        onClicked: searchModal.close()
    }

    // Search panel
    Rectangle {
        id: panel
        anchors.top: parent.top
        anchors.topMargin: 90
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(620, parent.width - 80)
        height: Math.min(480, parent.height - 150)
        radius: SkinTheme.radiusLarge
        color: SkinTheme.bgCard
        border.color: SkinTheme.accentCyan
        border.width: 1
        clip: true

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: SkinTheme.accentCyan
            opacity: 0.03
            z: -1
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // Input row
            RowLayout {
                Layout.fillWidth: true
                Layout.margins: 12
                spacing: 10

                Text {
                    text: "🔍"
                    font.pixelSize: 15
                    color: SkinTheme.accentCyan
                }

                TextField {
                    id: searchField
                    Layout.fillWidth: true
                    placeholderText: app.t("search.placeholder")
                    font.family: SkinTheme.fontFamily
                    font.pixelSize: 14
                    color: SkinTheme.textPrimary
                    selectByMouse: true
                    background: Rectangle {
                        radius: SkinTheme.radiusMedium
                        color: SkinTheme.bgVoid
                        border.color: searchField.activeFocus ? SkinTheme.accentCyan : SkinTheme.borderMuted
                        border.width: 1
                    }
                    onTextChanged: debounceTimer.restart()
                    onActiveFocusChanged: if (!activeFocus && searchModal.isOpen) searchModal.close()

                    // Debounce: avoid re-serializing the whole catalog on every keystroke
                    Timer {
                        id: debounceTimer
                        interval: 120
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

                Text {
                    text: "ESC"
                    color: SkinTheme.textMuted
                    font.family: SkinTheme.fontMono
                    font.pixelSize: 10
                    opacity: 0.7
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: SkinTheme.borderMuted
            }

            // Results area
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
                              ? app.t("search.min_chars")
                              : app.t("search.no_results") + " \"" + searchModal.lastQuery + "\""
                        color: SkinTheme.textMuted
                        font.family: SkinTheme.fontFamily
                        font.pixelSize: 12
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        visible: searchModal.lastQuery.trim().length >= 2
                        text: app.t("search.hint")
                        color: SkinTheme.borderMuted
                        font.family: SkinTheme.fontMono
                        font.pixelSize: 10
                    }
                }

                ListView {
                    id: resultsList
                    anchors.fill: parent
                    anchors.margins: 6
                    model: searchModal.results
                    spacing: 2
                    visible: searchModal.results.length > 0
                    boundsBehavior: Flickable.StopAtBounds
                    currentIndex: searchModal.selectedIndex
                    clip: true

                    delegate: Rectangle {
                        width: resultsList.width
                        height: 52
                        radius: SkinTheme.radiusMedium
                        color: resultsList.currentIndex === index
                               ? SkinTheme.bgCardHover
                               : (rowHover.containsMouse ? "#0E1422" : "transparent")
                        border.color: resultsList.currentIndex === index ? SkinTheme.accentCyan : "transparent"
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 12

                            Rectangle {
                                width: 3
                                height: resultsList.currentIndex === index ? 30 : 0
                                radius: 1.5
                                color: SkinTheme.accentCyan
                                Layout.alignment: Qt.AlignVCenter

                                Behavior on height { NumberAnimation { duration: SkinTheme.animFast } }
                            }

                            Rectangle {
                                Layout.preferredWidth: 36
                                Layout.preferredHeight: 36
                                radius: SkinTheme.radiusSmall
                                color: SkinTheme.bgVoid
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
                                    opacity: 0.4
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.name
                                    color: SkinTheme.textPrimary
                                    font.family: SkinTheme.fontFamily
                                    font.pixelSize: 13
                                    font.bold: true
                                    elide: Text.ElideRight
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: (modelData.hero && modelData.hero !== "" ? modelData.hero + "  ·  " : "")
                                          + app.translate(String(modelData.categoryId))
                                    color: SkinTheme.textSecondary
                                    font.family: SkinTheme.fontFamily
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }
                            }

                            Text {
                                text: modelData.isInstalled
                                      ? app.t("search.installed_badge")
                                      : app.t("search.install_action")
                                color: modelData.isInstalled ? SkinTheme.accentCyan : SkinTheme.textMuted
                                font.family: SkinTheme.fontMono
                                font.pixelSize: 10
                                font.bold: true
                                font.letterSpacing: 1.0
                            }

                            Text {
                                text: "♥"
                                color: SkinTheme.accentViolet
                                font.pixelSize: 13
                                visible: modelData.isFavorite === true
                            }

                            Text {
                                text: "↵"
                                color: SkinTheme.accentCyan
                                font.family: SkinTheme.fontMono
                                font.pixelSize: 12
                                opacity: resultsList.currentIndex === index ? 0.9 : 0.25
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

            // Footer hints
            Rectangle {
                Layout.fillWidth: true
                height: 30
                color: SkinTheme.bgVoid
                border.color: SkinTheme.borderMuted
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 16

                    Text {
                        text: "↑↓ " + app.t("search.navigate")
                        color: SkinTheme.textMuted
                        font.family: SkinTheme.fontMono
                        font.pixelSize: 10
                    }
                    Text {
                        text: "↵ " + app.t("search.open")
                        color: SkinTheme.textMuted
                        font.family: SkinTheme.fontMono
                        font.pixelSize: 10
                    }
                    Text {
                        text: "ESC " + app.t("search.close")
                        color: SkinTheme.textMuted
                        font.family: SkinTheme.fontMono
                        font.pixelSize: 10
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: "Ctrl+K"
                        color: SkinTheme.accentCyan
                        font.family: SkinTheme.fontMono
                        font.pixelSize: 10
                        font.bold: true
                    }
                }
            }
        }
    }
}
