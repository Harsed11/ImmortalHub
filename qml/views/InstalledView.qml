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
        if (typeof app === "undefined" || !app) return
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
                return (m.name && m.name.toLowerCase().indexOf(q) !== -1) ||
                       (m.hero && m.hero.toLowerCase().indexOf(q) !== -1) ||
                       (m.categoryId && m.categoryId.toLowerCase().indexOf(q) !== -1)
            })
        } else {
            filteredList = installedList
        }
    }

    function getCategoryName(catId) {
        if (!catId) return ""
        return (typeof app !== "undefined" && app && app.translate) ? app.translate(catId) : catId
    }

    onSearchQueryChanged: filterInstalled()

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ═══════════════════════════════════════════
        // TOP CONTROL BAR
        // ═══════════════════════════════════════════
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 52
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

                // Section Title & Badge
                RowLayout {
                    spacing: 8

                    Text {
                        text: "ACTIVE LOADOUT"
                        color: SkinTheme.textPrimary
                        font.family: SkinTheme.fontFamily
                        font.pixelSize: SkinTheme.fontSizeTitle
                        font.bold: true
                        font.letterSpacing: 0.5
                    }

                    Rectangle {
                        height: 20
                        radius: SkinTheme.radiusPill
                        implicitWidth: instCountBadge.implicitWidth + 12
                        color: installedList.length > 0 ? SkinTheme.accentEmeraldGlow : SkinTheme.bgCard
                        border.color: installedList.length > 0 ? SkinTheme.accentEmerald : SkinTheme.borderMuted
                        border.width: 1

                        Text {
                            id: instCountBadge
                            anchors.centerIn: parent
                            text: installedList.length + " EQUIPPED"
                            color: installedList.length > 0 ? SkinTheme.accentEmerald : SkinTheme.textMuted
                            font.family: SkinTheme.fontMono
                            font.pixelSize: 8
                            font.bold: true
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Search Filter Input
                Rectangle {
                    width: 200
                    height: 32
                    radius: SkinTheme.radiusMedium
                    color: SkinTheme.bgInput
                    border.color: searchInstInput.activeFocus ? SkinTheme.accentCyan : SkinTheme.borderMuted
                    border.width: 1

                    Behavior on border.color { ColorAnimation { duration: SkinTheme.animFast } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 6
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
                                text: "Filter loadout..."
                                color: SkinTheme.textMuted
                                font.family: SkinTheme.fontFamily
                                font.pixelSize: SkinTheme.fontSizeBody
                                visible: !searchInstInput.text && !searchInstInput.activeFocus
                            }
                        }

                        Rectangle {
                            width: 16
                            height: 16
                            radius: SkinTheme.radiusSmall
                            color: SkinTheme.bgCardHover
                            visible: searchInstInput.text !== ""

                            Text {
                                anchors.centerIn: parent
                                text: "✕"
                                color: SkinTheme.textSecondary
                                font.pixelSize: 8
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
                    height: 32
                    radius: SkinTheme.radiusMedium
                    implicitWidth: syncText.implicitWidth + 18
                    color: syncMouse.containsMouse ? SkinTheme.accentCyanHover : SkinTheme.accentCyan

                    Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

                    RowLayout {
                        id: syncText
                        anchors.centerIn: parent
                        spacing: 5
                        Text { text: "🔄"; font.pixelSize: 10; color: "#FFFFFF" }
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
                        onClicked: {
                            if (typeof app !== "undefined" && app) {
                                app.syncAllInstalled()
                            }
                        }
                    }
                }

                // Uninstall All Button
                Rectangle {
                    visible: installedList.length > 0
                    height: 32
                    radius: SkinTheme.radiusMedium
                    implicitWidth: uninstAllText.implicitWidth + 18
                    color: uninstAllMouse.containsMouse ? SkinTheme.accentCrimsonHover : "transparent"
                    border.color: SkinTheme.accentCrimson
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

                    RowLayout {
                        id: uninstAllText
                        anchors.centerIn: parent
                        spacing: 5
                        Text { text: "🗑️"; font.pixelSize: 10 }
                        Text {
                            text: "UNINSTALL ALL"
                            color: uninstAllMouse.containsMouse ? "#FFFFFF" : SkinTheme.accentCrimson
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
        // TABLE COLUMN HEADERS (ONE ALIGNED LINE)
        // ═══════════════════════════════════════════
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            color: SkinTheme.bgDark

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: SkinTheme.borderSubtle
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: SkinTheme.spacingLG + 12
                anchors.rightMargin: SkinTheme.spacingLG + 16
                spacing: 12

                // Col 1: Preview Icon (60px)
                Text {
                    Layout.preferredWidth: 60
                    text: "PREVIEW"
                    color: SkinTheme.textMuted
                    font.family: SkinTheme.fontMono
                    font.pixelSize: 8
                    font.bold: true
                    font.letterSpacing: 1.0
                }

                // Col 2: Skin Name (Fill)
                Text {
                    Layout.fillWidth: true
                    text: "SKIN / ITEM NAME"
                    color: SkinTheme.textMuted
                    font.family: SkinTheme.fontMono
                    font.pixelSize: 8
                    font.bold: true
                    font.letterSpacing: 1.0
                }

                // Col 3: Hero / Category (160px)
                Text {
                    Layout.preferredWidth: 160
                    text: "HERO / CATEGORY"
                    color: SkinTheme.textMuted
                    font.family: SkinTheme.fontMono
                    font.pixelSize: 8
                    font.bold: true
                    font.letterSpacing: 1.0
                }

                // Col 4: Installed Date (120px)
                Text {
                    Layout.preferredWidth: 120
                    text: "DATE ADDED"
                    color: SkinTheme.textMuted
                    font.family: SkinTheme.fontMono
                    font.pixelSize: 8
                    font.bold: true
                    font.letterSpacing: 1.0
                }

                // Col 5: Status (90px)
                Text {
                    Layout.preferredWidth: 90
                    text: "STATUS"
                    color: SkinTheme.textMuted
                    font.family: SkinTheme.fontMono
                    font.pixelSize: 8
                    font.bold: true
                    font.letterSpacing: 1.0
                }

                // Col 6: Action (100px)
                Text {
                    Layout.preferredWidth: 100
                    horizontalAlignment: Text.AlignHCenter
                    text: "ACTION"
                    color: SkinTheme.textMuted
                    font.family: SkinTheme.fontMono
                    font.pixelSize: 8
                    font.bold: true
                    font.letterSpacing: 1.0
                }
            }
        }

        // ═══════════════════════════════════════════
        // TABLE LIST VIEW (PERFECTLY ALIGNED ROWS)
        // ═══════════════════════════════════════════
        ListView {
            id: installedListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: SkinTheme.spacingLG
            model: filteredList
            clip: true
            spacing: 6

            ScrollBar.vertical: NeonScrollBar {}

            delegate: Rectangle {
                width: installedListView.width
                height: 56
                radius: SkinTheme.radiusMedium
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
                    anchors.rightMargin: 12
                    spacing: 12

                    // Col 1: Thumbnail (60px)
                    Rectangle {
                        Layout.preferredWidth: 50
                        Layout.preferredHeight: 38
                        radius: SkinTheme.radiusSmall
                        color: SkinTheme.bgDark
                        border.color: SkinTheme.borderMuted
                        border.width: 1
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: modelData.previewUrl || ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                    }

                    // Col 2: Skin Name (Fill)
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle {
                            width: 6
                            height: 6
                            radius: 3
                            color: SkinTheme.accentCyan
                        }

                        Text {
                            Layout.fillWidth: true
                            text: modelData.name || "Custom Skin"
                            color: SkinTheme.textPrimary
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: SkinTheme.fontSizeBody
                            font.bold: true
                            elide: Text.ElideRight
                        }
                    }

                    // Col 3: Hero / Category Badge (160px)
                    Rectangle {
                        Layout.preferredWidth: 150
                        Layout.preferredHeight: 24
                        radius: SkinTheme.radiusSmall
                        color: SkinTheme.bgDark
                        border.color: SkinTheme.borderMuted
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: modelData.hero ? modelData.hero.toUpperCase() : installedView.getCategoryName(modelData.categoryId).toUpperCase()
                            color: modelData.hero ? SkinTheme.accentCyan : SkinTheme.textSecondary
                            font.family: SkinTheme.fontMono
                            font.pixelSize: 8
                            font.bold: true
                            elide: Text.ElideRight
                        }
                    }

                    // Col 4: Date Added (120px)
                    Text {
                        Layout.preferredWidth: 120
                        text: modelData.installedAt ? modelData.installedAt : "Active"
                        color: SkinTheme.textMuted
                        font.family: SkinTheme.fontMono
                        font.pixelSize: SkinTheme.fontSizeSmall
                        elide: Text.ElideRight
                    }

                    // Col 5: Status Badge (90px)
                    Rectangle {
                        Layout.preferredWidth: 80
                        Layout.preferredHeight: 22
                        radius: SkinTheme.radiusPill
                        color: SkinTheme.accentEmeraldGlow
                        border.color: SkinTheme.accentEmerald
                        border.width: 1

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 4
                            Rectangle { width: 5; height: 5; radius: 2.5; color: SkinTheme.accentEmerald }
                            Text {
                                text: "ACTIVE"
                                color: SkinTheme.accentEmerald
                                font.family: SkinTheme.fontMono
                                font.pixelSize: 7
                                font.bold: true
                            }
                        }
                    }

                    // Col 6: Uninstall Button (100px)
                    Rectangle {
                        Layout.preferredWidth: 96
                        Layout.preferredHeight: 28
                        radius: SkinTheme.radiusSmall
                        color: itemUninstMouse.containsMouse ? SkinTheme.accentCrimsonHover : "transparent"
                        border.color: SkinTheme.accentCrimson
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 4
                            Text { text: "✕"; font.pixelSize: 8; color: itemUninstMouse.containsMouse ? "#FFFFFF" : SkinTheme.accentCrimson }
                            Text {
                                text: "UNINSTALL"
                                color: itemUninstMouse.containsMouse ? "#FFFFFF" : SkinTheme.accentCrimson
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
                            onClicked: {
                                if (typeof app !== "undefined" && app) {
                                    app.uninstallMod(modelData.name, modelData.categoryId)
                                }
                            }
                        }
                    }
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

                AegisIcon {
                    Layout.alignment: Qt.AlignHCenter
                    width: 48
                    height: 48
                    opacity: 0.4
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: installedList.length === 0
                          ? "NO ACTIVE MODS EQUIPPED"
                          : "NO MODS MATCHING YOUR SEARCH"
                    color: SkinTheme.textPrimary
                    font.family: SkinTheme.fontFamily
                    font.pixelSize: SkinTheme.fontSizeTitle
                    font.bold: true
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Explore Hero Studio, Collections, or Creators to equip skins!"
                    color: SkinTheme.textSecondary
                    font.family: SkinTheme.fontFamily
                    font.pixelSize: SkinTheme.fontSizeBody
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
        visible: showConfirmUninstallAll
        z: 999

        Rectangle {
            anchors.centerIn: parent
            width: Math.min(460, parent.width - 40)
            height: 230
            radius: SkinTheme.radiusLarge
            color: SkinTheme.bgModal
            border.color: SkinTheme.accentCrimson
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 14

                Text {
                    text: "⚠️ UNINSTALL ALL MODS"
                    color: SkinTheme.accentCrimson
                    font.family: SkinTheme.fontFamily
                    font.pixelSize: SkinTheme.fontSizeTitle
                    font.bold: true
                }

                Text {
                    Layout.fillWidth: true
                    text: "Are you sure you want to unequip all " + installedList.length + " active mods from Dota 2? Your game files will be restored to vanilla state."
                    color: SkinTheme.textSecondary
                    font.family: SkinTheme.fontFamily
                    font.pixelSize: SkinTheme.fontSizeBody
                    wrapMode: Text.WordWrap
                }

                Item { Layout.fillHeight: true }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        radius: SkinTheme.radiusMedium
                        color: cancelUninstMouse.containsMouse ? SkinTheme.bgCardHover : SkinTheme.bgCard
                        border.color: SkinTheme.borderMuted
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "CANCEL"
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
                            text: "UNINSTALL ALL"
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
                                if (typeof app !== "undefined" && app) {
                                    app.uninstallAll()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
