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
                            text: "INSTALLED MODS"
                            color: SkinTheme.textPrimary
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: SkinTheme.fontSizeTitle
                            font.bold: true
                            font.letterSpacing: 0.5
                        }

                        Rectangle {
                            height: 20
                            radius: SkinTheme.radiusPill
                            implicitWidth: instCountBadge.implicitWidth + 14
                            color: installedList.length > 0 ? SkinTheme.accentEmeraldGlow : SkinTheme.bgCard
                            border.color: installedList.length > 0 ? SkinTheme.accentEmerald : SkinTheme.borderMuted
                            border.width: 1

                            Text {
                                id: instCountBadge
                                anchors.centerIn: parent
                                text: installedList.length + " ACTIVE"
                                color: installedList.length > 0 ? SkinTheme.accentEmerald : SkinTheme.textMuted
                                font.family: SkinTheme.fontMono
                                font.pixelSize: 8
                                font.bold: true
                            }
                        }
                    }

                    Text {
                        text: "Active custom skins, terrain, sound packs, and effects deployed in Dota 2"
                        color: SkinTheme.textSecondary
                        font.family: SkinTheme.fontFamily
                        font.pixelSize: SkinTheme.fontSizeSmall
                    }
                }

                Item { Layout.fillWidth: true }

                // Search Filter Input
                Rectangle {
                    width: 220
                    height: 34
                    radius: SkinTheme.radiusMedium
                    color: SkinTheme.bgInput
                    border.color: searchInstInput.activeFocus ? SkinTheme.accentCyan : SkinTheme.borderMuted
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
                            color: searchInstInput.activeFocus ? SkinTheme.accentCyan : SkinTheme.textMuted
                        }

                        TextInput {
                            id: searchInstInput
                            Layout.fillWidth: true
                            color: SkinTheme.textPrimary
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: SkinTheme.fontSizeBody
                            clip: true
                            selectByMouse: true
                            text: installedView.searchQuery

                            onTextChanged: installedView.searchQuery = text

                            Text {
                                text: "Filter active mods..."
                                color: SkinTheme.textMuted
                                font.family: SkinTheme.fontFamily
                                font.pixelSize: SkinTheme.fontSizeBody
                                visible: !searchInstInput.text && !searchInstInput.activeFocus
                            }
                        }

                        Rectangle {
                            width: 18
                            height: 18
                            radius: SkinTheme.radiusSmall
                            color: SkinTheme.bgCardHover
                            visible: searchInstInput.text !== ""

                            Text {
                                anchors.centerIn: parent
                                text: "✕"
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

                // Sync All Button
                Rectangle {
                    height: 34
                    radius: SkinTheme.radiusMedium
                    implicitWidth: syncText.implicitWidth + 20
                    color: syncMouse.containsMouse ? SkinTheme.accentCyanHover : SkinTheme.accentCyan

                    Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

                    RowLayout {
                        id: syncText
                        anchors.centerIn: parent
                        spacing: 6
                        Text { text: "🔄"; font.pixelSize: 11; color: "#FFFFFF" }
                        Text {
                            text: "SYNC ALL"
                            color: "#FFFFFF"
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: SkinTheme.fontSizeSmall
                            font.bold: true
                            font.letterSpacing: 0.5
                        }
                    }

                    MouseArea {
                        id: syncMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: app.syncAllMods()
                    }
                }

                // Uninstall All Button
                Rectangle {
                    height: 34
                    radius: SkinTheme.radiusMedium
                    implicitWidth: uninstAllText.implicitWidth + 20
                    color: uninstAllMouse.containsMouse ? SkinTheme.accentCrimsonHover : SkinTheme.accentCrimson
                    visible: installedList.length > 0

                    Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

                    RowLayout {
                        id: uninstAllText
                        anchors.centerIn: parent
                        spacing: 6

                        Text { text: "✕"; font.pixelSize: 10; color: "#FFFFFF" }
                        Text {
                            text: "UNINSTALL ALL"
                            color: "#FFFFFF"
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: SkinTheme.fontSizeSmall
                            font.bold: true
                            font.letterSpacing: 0.5
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

        // ═══════════════════════════════════════════
        // LIST OF INSTALLED MODS
        // ═══════════════════════════════════════════
        ListView {
            id: installedListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: SkinTheme.spacingLG
            model: filteredList
            clip: true
            spacing: SkinTheme.spacingSM

            ScrollBar.vertical: NeonScrollBar {}

            delegate: Rectangle {
                width: installedListView.width
                height: 72
                radius: SkinTheme.radiusLarge
                color: rowMouse.containsMouse ? SkinTheme.bgCardHover : SkinTheme.bgCard
                border.color: rowMouse.containsMouse ? SkinTheme.borderLight : SkinTheme.borderMuted
                border.width: 1

                Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }
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

                    // Thumbnail Preview
                    Rectangle {
                        width: 64
                        height: 50
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

                    // Metadata Labels
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3

                        RowLayout {
                            spacing: 8
                            Text {
                                text: modelData.name
                                color: SkinTheme.textPrimary
                                font.family: SkinTheme.fontFamily
                                font.pixelSize: SkinTheme.fontSizeBody
                                font.weight: Font.DemiBold
                            }

                            Rectangle {
                                height: 18
                                radius: SkinTheme.radiusSmall
                                implicitWidth: itemCatText.implicitWidth + 10
                                color: SkinTheme.accentCyanGlow
                                border.color: SkinTheme.accentCyan
                                border.width: 1

                                Text {
                                    id: itemCatText
                                    anchors.centerIn: parent
                                    text: (typeof app !== "undefined" && app && app.translate) ? app.translate(modelData.categoryId) : (modelData.categoryId || "")
                                    color: SkinTheme.accentCyan
                                    font.family: SkinTheme.fontMono
                                    font.pixelSize: 8
                                    font.bold: true
                                }
                            }

                            Rectangle {
                                height: 18
                                radius: SkinTheme.radiusSmall
                                implicitWidth: 48
                                color: SkinTheme.accentEmeraldGlow
                                border.color: SkinTheme.accentEmerald
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: "ACTIVE"
                                    color: SkinTheme.accentEmerald
                                    font.family: SkinTheme.fontMono
                                    font.pixelSize: 8
                                    font.bold: true
                                }
                            }
                        }

                        Text {
                            text: (modelData.hero ? "Hero: " + modelData.hero + " • " : "") +
                                  "Installed: " + (modelData.installedAt || "Recent")
                            color: SkinTheme.textSecondary
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: SkinTheme.fontSizeSmall
                        }
                    }

                    // Single Item Uninstall Button
                    Rectangle {
                        width: 90
                        height: 32
                        radius: SkinTheme.radiusSmall
                        color: itemUninstMouse.containsMouse ? SkinTheme.accentCrimsonHover : SkinTheme.accentCrimson

                        Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 4
                            Text { text: "✕"; font.pixelSize: 9; color: "#FFFFFF" }
                            Text {
                                text: "UNINSTALL"
                                color: "#FFFFFF"
                                font.family: SkinTheme.fontFamily
                                font.pixelSize: SkinTheme.fontSizeSmall
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

            // ═══════════════════════════════════════════
            // EMPTY STATE
            // ═══════════════════════════════════════════
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
                        opacity: 0.4
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: installedList.length === 0
                              ? "NO ACTIVE MODS INSTALLED"
                              : "NO MODS MATCHING YOUR SEARCH"
                        color: SkinTheme.textPrimary
                        font.family: SkinTheme.fontFamily
                        font.pixelSize: SkinTheme.fontSizeTitle
                        font.bold: true
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Explore heroes, terrains, and sound packs to install your first skins!"
                        color: SkinTheme.textSecondary
                        font.family: SkinTheme.fontFamily
                        font.pixelSize: SkinTheme.fontSizeBody
                    }
                }
            }
        }
    }

    // ═══════════════════════════════════════════
    // CONFIRMATION MODAL (Uninstall All)
    // ═══════════════════════════════════════════
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
            width: 420
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
                spacing: 12

                RowLayout {
                    spacing: 10
                    Text { text: "⚠"; font.pixelSize: 20; color: SkinTheme.accentCrimson }
                    Text {
                        text: "Uninstall All Mods?"
                        color: SkinTheme.textPrimary
                        font.family: SkinTheme.fontFamily
                        font.pixelSize: SkinTheme.fontSizeTitle
                        font.bold: true
                    }
                }

                Text {
                    text: "This will remove all " + installedList.length + " active mods from your Dota 2 game directory. This action cannot be undone."
                    color: SkinTheme.textSecondary
                    font.family: SkinTheme.fontFamily
                    font.pixelSize: SkinTheme.fontSizeBody
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
                        radius: SkinTheme.radiusMedium
                        color: cancelUninstMouse.containsMouse ? SkinTheme.bgCardHover : SkinTheme.bgCard
                        border.color: SkinTheme.borderMuted
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "Cancel"
                            color: SkinTheme.textPrimary
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: SkinTheme.fontSizeBody
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
                        radius: SkinTheme.radiusMedium
                        color: confirmUninstMouse.containsMouse ? SkinTheme.accentCrimsonHover : SkinTheme.accentCrimson

                        Text {
                            anchors.centerIn: parent
                            text: "Yes, Uninstall All"
                            color: "#FFFFFF"
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: SkinTheme.fontSizeBody
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
