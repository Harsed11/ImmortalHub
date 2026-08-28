import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"
import "../components"

Item {
    id: installedView

    property var installedList: []
    property var filteredList: []
    property string searchQuery: ""
    property bool showConfirmUninstallAll: false

    Component.onCompleted: loadInstalled()

    Connections {
        target: app
        function onInstalledModsChanged() { loadInstalled() }
    }

    function loadInstalled() {
        var raw = app.getInstalledMods()
        try {
            installedList = JSON.parse(raw)
        } catch(e) {
            installedList = []
        }
        filterInstalled()
    }

    function filterInstalled() {
        if (searchQuery.trim() !== "") {
            var q = searchQuery.toLowerCase().trim()
            filteredList = installedList.filter(function(m) {
                return m.name.toLowerCase().indexOf(q) !== -1 || (m.hero && m.hero.toLowerCase().indexOf(q) !== -1)
            })
        } else {
            filteredList = installedList
        }
    }

    onSearchQueryChanged: filterInstalled()

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header Bar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 68
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
                            text: "INSTALLED MODS & ACTIVE SKINS"
                            color: SkinTheme.textPrimary
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: SkinTheme.fontSizeTitle
                            font.bold: true
                        }

                        Rectangle {
                            height: 20
                            radius: 10
                            implicitWidth: instCountBadge.implicitWidth + 14
                            color: installedList.length > 0 ? "#122e23" : "#24181b"
                            border.color: installedList.length > 0 ? SkinTheme.accentEmerald : SkinTheme.borderMuted
                            border.width: 1

                            Text {
                                id: instCountBadge
                                anchors.centerIn: parent
                                text: installedList.length + " ACTIVE"
                                color: installedList.length > 0 ? SkinTheme.accentEmerald : SkinTheme.textMuted
                                font.family: SkinTheme.fontFamily
                                font.pixelSize: 9
                                font.bold: true
                                font.letterSpacing: 0.5
                            }
                        }
                    }

                    Text {
                        text: "Manage active custom skins, sound packs, terrain, and visual effects inside Dota 2."
                        color: SkinTheme.textMuted
                        font.pixelSize: 11
                    }
                }

                Item { Layout.fillWidth: true }

                // Search Input
                Rectangle {
                    width: 220
                    height: 36
                    radius: SkinTheme.radiusMedium
                    color: SkinTheme.bgInput
                    border.color: searchInstInput.activeFocus ? SkinTheme.accentCyan : SkinTheme.borderMuted
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
                            id: searchInstInput
                            Layout.fillWidth: true
                            color: SkinTheme.textPrimary
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: 12
                            clip: true
                            selectByMouse: true
                            text: installedView.searchQuery

                            onTextChanged: installedView.searchQuery = text

                            Text {
                                text: "Filter installed..."
                                color: SkinTheme.textMuted
                                font.pixelSize: 12
                                visible: !searchInstInput.text && !searchInstInput.activeFocus
                            }
                        }

                        Rectangle {
                            width: 18
                            height: 18
                            radius: 9
                            color: SkinTheme.bgCardHover
                            visible: searchInstInput.text !== ""

                            Text {
                                anchors.centerIn: parent
                                text: "вњ•"
                                color: SkinTheme.textSecondary
                                font.pixelSize: 9
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: searchInstInput.text = ""
                            }
                        }
                    }
                }

                // Clean Reset / Uninstall All Button
                Rectangle {
                    height: 36
                    radius: SkinTheme.radiusMedium
                    implicitWidth: uninstAllText.implicitWidth + 28
                    color: uninstAllMouse.containsMouse ? "#42161b" : "#281216"
                    border.color: SkinTheme.accentCrimson
                    border.width: 1
                    visible: installedList.length > 0

                    RowLayout {
                        id: uninstAllText
                        anchors.centerIn: parent
                        spacing: 6

                        Text { text: "✕"; font.pixelSize: 11 }
                        Text {
                            text: "Uninstall All"
                            color: SkinTheme.accentCrimsonHover
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: 12
                            font.bold: true
                        }
                    }

                    MouseArea {
                        id: uninstAllMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: installedView.showConfirmUninstallAll = true
                    }
                }
            }
        }

        // List of Installed Mods
        ListView {
            id: installedListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 16
            model: filteredList
            clip: true
            spacing: 8

            ScrollBar.vertical: ScrollBar {
                width: 8
                policy: ScrollBar.AsNeeded
                contentItem: Rectangle {
                    radius: 4
                    color: SkinTheme.accentCyan
                    opacity: 0.4
                }
            }

            delegate: Rectangle {
                width: installedListView.width
                height: 72
                radius: SkinTheme.radiusLarge
                color: SkinTheme.bgCard
                border.color: rowMouse.containsMouse ? SkinTheme.borderActive : SkinTheme.borderMuted
                border.width: 1

                Behavior on border.color { ColorAnimation { duration: SkinTheme.animFast } }

                MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 16
                    spacing: 14

                    // Thumbnail
                    Rectangle {
                        width: 64
                        height: 52
                        radius: SkinTheme.radiusSmall
                        color: SkinTheme.bgDark
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: modelData.previewUrl || ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }

                        Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                            border.color: SkinTheme.borderMuted
                            border.width: 1
                            radius: SkinTheme.radiusSmall
                        }
                    }

                    // Metadata
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3

                        RowLayout {
                            spacing: 8
                            Text {
                                text: modelData.name
                                color: SkinTheme.textPrimary
                                font.family: SkinTheme.fontFamily
                                font.pixelSize: 13
                                font.bold: true
                            }

                            Rectangle {
                                height: 18
                                radius: 4
                                implicitWidth: itemCatText.implicitWidth + 8
                                color: "#172338"
                                border.color: SkinTheme.borderMuted
                                border.width: 1

                                Text {
                                    id: itemCatText
                                    anchors.centerIn: parent
                                    text: app.translate(modelData.categoryId)
                                    color: SkinTheme.accentCyan
                                    font.family: SkinTheme.fontFamily
                                    font.pixelSize: 9
                                    font.bold: true
                                }
                            }

                            Rectangle {
                                height: 18
                                radius: 4
                                implicitWidth: 50
                                color: "#16382b"
                                border.color: SkinTheme.accentEmerald
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: "ACTIVE"
                                    color: SkinTheme.accentEmerald
                                    font.family: SkinTheme.fontFamily
                                    font.pixelSize: 8
                                    font.bold: true
                                }
                            }
                        }

                        Text {
                            text: (modelData.hero ? "Hero: " + modelData.hero + " • " : "") +
                                  "Installed on: " + (modelData.installedAt || "Recent")
                            color: SkinTheme.textMuted
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: 11
                        }
                    }

                    // Uninstall Button
                    Rectangle {
                        width: 100
                        height: 34
                        radius: SkinTheme.radiusSmall
                        color: itemUninstMouse.containsMouse ? "#4a1b22" : "#281216"
                        border.color: SkinTheme.accentCrimson
                        border.width: 1

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            Text { text: "✕"; font.pixelSize: 10 }
                            Text {
                                text: "Uninstall"
                                color: SkinTheme.accentCrimsonHover
                                font.family: SkinTheme.fontFamily
                                font.pixelSize: 11
                                font.bold: true
                            }
                        }

                        MouseArea {
                            id: itemUninstMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: app.uninstallMod(modelData.name, modelData.categoryId)
                        }
                    }
                }
            }

            // Empty State
            Item {
                anchors.centerIn: parent
                visible: filteredList.length === 0

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 12

                    AegisIcon {
                        Layout.alignment: Qt.AlignHCenter
                        width: 48
                        height: 48
                        opacity: 0.5
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: installedList.length === 0
                              ? "No skins currently installed"
                              : "No installed mods matching your search"
                        color: SkinTheme.textPrimary
                        font.family: SkinTheme.fontFamily
                        font.pixelSize: 15
                        font.bold: true
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Browse hero skins, visual effects, and sound packs to install mods!"
                        color: SkinTheme.textMuted
                        font.pixelSize: 12
                    }
                }
            }
        }
    }

    // Confirmation Modal for Uninstall All
    Rectangle {
        anchors.fill: parent
        color: SkinTheme.bgModalOverlay
        visible: installedView.showConfirmUninstallAll
        z: 999

        MouseArea {
            anchors.fill: parent
            onClicked: installedView.showConfirmUninstallAll = false
        }

        Rectangle {
            width: 400
            height: 200
            radius: SkinTheme.radiusLarge
            anchors.centerIn: parent
            color: SkinTheme.bgModal
            border.color: SkinTheme.accentCrimson
            border.width: 1

            MouseArea {
                anchors.fill: parent
                onClicked: {}
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 14

                RowLayout {
                    spacing: 10
                    Text { text: "⚠"; font.pixelSize: 22 }
                    Text {
                        text: "Uninstall All Mods?"
                        color: SkinTheme.textPrimary
                        font.family: SkinTheme.fontFamily
                        font.pixelSize: 16
                        font.bold: true
                    }
                }

                Text {
                    text: "This will remove all " + installedList.length + " active mods from your Dota 2 game directory. This action cannot be undone."
                    color: SkinTheme.textSecondary
                    font.family: SkinTheme.fontFamily
                    font.pixelSize: 12
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }

                Item { Layout.fillHeight: true }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        radius: SkinTheme.radiusSmall
                        color: cancelUninstMouse.containsMouse ? SkinTheme.bgCardHover : SkinTheme.bgCard
                        border.color: SkinTheme.borderMuted
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "Cancel"
                            color: SkinTheme.textPrimary
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: 12
                            font.bold: true
                        }

                        MouseArea {
                            id: cancelUninstMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: installedView.showConfirmUninstallAll = false
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        radius: SkinTheme.radiusSmall
                        color: confirmUninstMouse.containsMouse ? SkinTheme.accentCrimsonHover : SkinTheme.accentCrimson

                        Text {
                            anchors.centerIn: parent
                            text: "Yes, Uninstall All"
                            color: "#ffffff"
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: 12
                            font.bold: true
                        }

                        MouseArea {
                            id: confirmUninstMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                installedView.showConfirmUninstallAll = false
                                app.uninstallAllMods()
                            }
                        }
                    }
                }
            }
        }
    }
}

