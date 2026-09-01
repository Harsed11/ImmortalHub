import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"

Rectangle {
    id: presetsModal
    anchors.fill: parent
    color: SkinTheme.bgModalOverlay
    visible: isOpen
    opacity: isOpen ? 1 : 0
    z: 600

    Behavior on opacity { NumberAnimation { duration: SkinTheme.animFast } }

    property bool isOpen: false
    property var presetsList: []
    property string activeTagFilter: "all" // "all", "pro", "curated", "user"
    property var filteredPresets: []

    signal closeRequested()
    signal applyPresetRequested(var preset)
    signal saveCurrentRequested(string name, string desc)
    signal deletePresetRequested(string presetId)

    function refreshPresets() {
        if (typeof app !== "undefined" && app && app.getPresetsJson) {
            try {
                presetsList = JSON.parse(app.getPresetsJson())
            } catch (e) {
                presetsList = []
            }
        }
        filterPresets()
    }

    function filterPresets() {
        if (activeTagFilter === "pro") {
            filteredPresets = presetsList.filter(function(p) { return p.badge === "PRO LOADOUT" })
        } else if (activeTagFilter === "curated") {
            filteredPresets = presetsList.filter(function(p) { return p.badge === "CURATED" || p.badge === "EXCLUSIVE" || p.badge === "PERFORMANCE" })
        } else if (activeTagFilter === "user") {
            filteredPresets = presetsList.filter(function(p) { return !p.isBuiltin })
        } else {
            filteredPresets = presetsList
        }
    }

    onIsOpenChanged: {
        if (isOpen) {
            refreshPresets()
        }
    }

    onActiveTagFilterChanged: filterPresets()

    // Background Click Dismiss
    MouseArea {
        anchors.fill: parent
        onClicked: presetsModal.closeRequested()
    }

    // Modal Card
    Rectangle {
        anchors.centerIn: parent
        width: Math.min(880, parent.width - 40)
        height: Math.min(640, parent.height - 40)
        radius: SkinTheme.radiusXLarge
        color: SkinTheme.bgModal
        border.color: SkinTheme.borderLight
        border.width: 1
        clip: true

        // Stop propagation
        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        // Top Accent Neon Bar
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 3
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: SkinTheme.accentCyan }
                GradientStop { position: 0.5; color: SkinTheme.accentViolet }
                GradientStop { position: 1.0; color: SkinTheme.accentEmerald }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 14

            // ── Header ──
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Text {
                    text: "🎭"
                    font.pixelSize: 22
                }

                ColumnLayout {
                    spacing: 2
                    Text {
                        text: "PRO LOADOUTS & PRESETS"
                        color: SkinTheme.textPrimary
                        font.family: SkinTheme.fontDisplay
                        font.pixelSize: 18
                        font.bold: true
                        font.letterSpacing: 1.5
                    }

                    Text {
                        text: "1-Click equip professional tournament sets, meta combos, or share custom builds"
                        color: SkinTheme.textSecondary
                        font.family: SkinTheme.fontFamily
                        font.pixelSize: SkinTheme.fontSizeSmall
                    }
                }

                Item { Layout.fillWidth: true }

                // Close Button
                Rectangle {
                    width: 32
                    height: 32
                    radius: SkinTheme.radiusSmall
                    color: closePmMouse.containsMouse ? SkinTheme.accentCrimsonHover : "transparent"
                    border.color: closePmMouse.containsMouse ? "transparent" : SkinTheme.borderMuted
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        color: closePmMouse.containsMouse ? "#FFFFFF" : SkinTheme.textMuted
                        font.pixelSize: 12
                        font.bold: true
                    }

                    MouseArea {
                        id: closePmMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: presetsModal.closeRequested()
                    }
                }
            }

            // ── Category Filter Tabs & Share Code Bar ──
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                // Filter Tabs
                RowLayout {
                    spacing: 4

                    Repeater {
                        model: [
                            { id: "all", label: "ALL PRESETS", count: presetsList.length },
                            { id: "pro", label: "🏆 PRO LOADOUTS", count: 3 },
                            { id: "curated", label: "✨ CURATED", count: 3 },
                            { id: "user", label: "💾 MY PRESETS", count: presetsList.filter(function(p){ return !p.isBuiltin }).length }
                        ]

                        delegate: Rectangle {
                            height: 30
                            radius: SkinTheme.radiusSmall
                            implicitWidth: pFilterRow.implicitWidth + 16
                            color: presetsModal.activeTagFilter === modelData.id
                                   ? SkinTheme.accentCyan
                                   : (pTabMouse.containsMouse ? SkinTheme.bgCardHover : SkinTheme.bgCard)
                            border.color: presetsModal.activeTagFilter === modelData.id ? "transparent" : SkinTheme.borderMuted
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

                            RowLayout {
                                id: pFilterRow
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: modelData.label
                                    color: presetsModal.activeTagFilter === modelData.id ? "#050811" : SkinTheme.textPrimary
                                    font.family: SkinTheme.fontFamily
                                    font.pixelSize: SkinTheme.fontSizeSmall
                                    font.bold: true
                                }
                            }

                            MouseArea {
                                id: pTabMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: presetsModal.activeTagFilter = modelData.id
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Import Code Box
                Rectangle {
                    width: 220
                    height: 30
                    radius: SkinTheme.radiusSmall
                    color: SkinTheme.bgInput
                    border.color: importCodeInput.activeFocus ? SkinTheme.accentCyan : SkinTheme.borderMuted
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 4
                        spacing: 4

                        TextInput {
                            id: importCodeInput
                            Layout.fillWidth: true
                            color: SkinTheme.textPrimary
                            font.family: SkinTheme.fontMono
                            font.pixelSize: SkinTheme.fontSizeSmall
                            clip: true
                            selectByMouse: true

                            Text {
                                text: "Paste IHUB-... code"
                                color: SkinTheme.textMuted
                                font.family: SkinTheme.fontMono
                                font.pixelSize: SkinTheme.fontSizeSmall
                                visible: !importCodeInput.text && !importCodeInput.activeFocus
                            }
                        }

                        Rectangle {
                            height: 22
                            radius: SkinTheme.radiusSmall
                            implicitWidth: 54
                            color: importCodeInput.text.trim() !== "" ? SkinTheme.accentCyan : SkinTheme.bgCard
                            border.color: SkinTheme.borderMuted
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "IMPORT"
                                color: importCodeInput.text.trim() !== "" ? "#050811" : SkinTheme.textMuted
                                font.family: SkinTheme.fontMono
                                font.pixelSize: 8
                                font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (importCodeInput.text.trim() !== "" && typeof app !== "undefined" && app) {
                                        app.importPresetCode(importCodeInput.text.trim())
                                        importCodeInput.text = ""
                                        presetsModal.refreshPresets()
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── Save Current Loadout Row ──
            Rectangle {
                Layout.fillWidth: true
                height: 44
                radius: SkinTheme.radiusMedium
                color: SkinTheme.bgCard
                border.color: SkinTheme.borderMuted
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 8
                    spacing: 10

                    Text {
                        text: "💾"
                        font.pixelSize: 12
                    }

                    TextInput {
                        id: presetNameInput
                        Layout.fillWidth: true
                        color: SkinTheme.textPrimary
                        font.family: SkinTheme.fontFamily
                        font.pixelSize: SkinTheme.fontSizeBody
                        clip: true
                        selectByMouse: true

                        Text {
                            text: "Save currently equipped loadout as custom preset..."
                            color: SkinTheme.textMuted
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: SkinTheme.fontSizeBody
                            visible: !presetNameInput.text && !presetNameInput.activeFocus
                        }
                    }

                    Rectangle {
                        height: 28
                        radius: SkinTheme.radiusSmall
                        implicitWidth: savePresetBtnText.implicitWidth + 18
                        color: savePresetMouse.containsMouse ? SkinTheme.accentEmeraldHover : SkinTheme.accentEmerald

                        Text {
                            id: savePresetBtnText
                            anchors.centerIn: parent
                            text: "SAVE LOADOUT"
                            color: "#FFFFFF"
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: SkinTheme.fontSizeSmall
                            font.bold: true
                        }

                        MouseArea {
                            id: savePresetMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (presetNameInput.text.trim() !== "") {
                                    presetsModal.saveCurrentRequested(presetNameInput.text.trim(), "User created preset")
                                    presetNameInput.text = ""
                                    presetsModal.refreshPresets()
                                }
                            }
                        }
                    }
                }
            }

            // ── Presets Grid / List View ──
            ListView {
                id: presetsListView
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 8
                clip: true
                model: presetsModal.filteredPresets

                ScrollBar.vertical: NeonScrollBar {}

                delegate: Rectangle {
                    width: presetsListView.width
                    height: 72
                    radius: SkinTheme.radiusLarge
                    color: pRowMouse.containsMouse ? SkinTheme.bgCardHover : SkinTheme.bgCard
                    border.color: pRowMouse.containsMouse ? SkinTheme.borderLight : SkinTheme.borderMuted
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

                    MouseArea {
                        id: pRowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 12

                        // Icon Pill
                        Rectangle {
                            width: 44
                            height: 44
                            radius: SkinTheme.radiusMedium
                            color: SkinTheme.bgDark
                            border.color: SkinTheme.borderMuted
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: modelData.icon || "🎭"
                                font.pixelSize: 20
                            }
                        }

                        // Info Column
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
                                    font.bold: true
                                }

                                Rectangle {
                                    height: 16
                                    radius: SkinTheme.radiusPill
                                    implicitWidth: badgeLabel.implicitWidth + 8
                                    color: modelData.badge === "PRO LOADOUT" ? SkinTheme.accentAmberGlow
                                         : (modelData.badge === "CURATED" ? SkinTheme.accentCyanGlow : SkinTheme.bgSurface)
                                    border.color: modelData.badge === "PRO LOADOUT" ? SkinTheme.accentAmber
                                                : (modelData.badge === "CURATED" ? SkinTheme.accentCyan : SkinTheme.borderMuted)
                                    border.width: 1

                                    Text {
                                        id: badgeLabel
                                        anchors.centerIn: parent
                                        text: modelData.badge || "PRESET"
                                        color: modelData.badge === "PRO LOADOUT" ? SkinTheme.accentAmber
                                             : (modelData.badge === "CURATED" ? SkinTheme.accentCyan : SkinTheme.textMuted)
                                        font.family: SkinTheme.fontMono
                                        font.pixelSize: 7
                                        font.bold: true
                                    }
                                }
                            }

                            Text {
                                text: modelData.description || ""
                                color: SkinTheme.textSecondary
                                font.family: SkinTheme.fontFamily
                                font.pixelSize: SkinTheme.fontSizeSmall
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        // Share / Export Code Button
                        Rectangle {
                            height: 30
                            radius: SkinTheme.radiusSmall
                            implicitWidth: 32
                            color: exportMouse.containsMouse ? SkinTheme.bgCardHover : "transparent"
                            border.color: SkinTheme.borderMuted
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "🔗"
                                font.pixelSize: 11
                            }

                            MouseArea {
                                id: exportMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (typeof app !== "undefined" && app) {
                                        app.exportPresetCode(JSON.stringify(modelData))
                                    }
                                }
                            }
                        }

                        // Delete (if user preset)
                        Rectangle {
                            visible: !modelData.isBuiltin
                            height: 30
                            width: 30
                            radius: SkinTheme.radiusSmall
                            color: delPresetMouse.containsMouse ? SkinTheme.accentCrimsonHover : "transparent"
                            border.color: SkinTheme.borderMuted
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "✕"
                                color: delPresetMouse.containsMouse ? "#FFFFFF" : SkinTheme.textMuted
                                font.pixelSize: 10
                            }

                            MouseArea {
                                id: delPresetMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    presetsModal.deletePresetRequested(modelData.id)
                                    presetsModal.refreshPresets()
                                }
                            }
                        }

                        // Apply Button
                        Rectangle {
                            height: 34
                            radius: SkinTheme.radiusSmall
                            implicitWidth: applyText.implicitWidth + 20
                            color: applyMouse.containsMouse ? SkinTheme.accentCyanHover : SkinTheme.accentCyan

                            Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

                            RowLayout {
                                id: applyText
                                anchors.centerIn: parent
                                spacing: 5
                                Text { text: "⚡"; font.pixelSize: 10; color: "#050811" }
                                Text {
                                    text: "EQUIP (" + (modelData.itemCount || (modelData.items ? modelData.items.length : 0)) + ")"
                                    color: "#050811"
                                    font.family: SkinTheme.fontFamily
                                    font.pixelSize: SkinTheme.fontSizeSmall
                                    font.bold: true
                                }
                            }

                            MouseArea {
                                id: applyMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    presetsModal.applyPresetRequested(modelData)
                                    presetsModal.closeRequested()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
