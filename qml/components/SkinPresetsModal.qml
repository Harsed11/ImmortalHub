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
    }

    onIsOpenChanged: {
        if (isOpen) {
            refreshPresets()
        }
    }

    // Background Click Dismiss
    MouseArea {
        anchors.fill: parent
        onClicked: presetsModal.closeRequested()
    }

    // Modal Card
    Rectangle {
        anchors.centerIn: parent
        width: Math.min(840, parent.width - 60)
        height: Math.min(620, parent.height - 60)
        radius: SkinTheme.radiusLarge
        color: SkinTheme.bgModal
        border.color: SkinTheme.borderMuted
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
            spacing: 16

            // Header
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
                        text: "SKIN PRESETS & COMBO SETS"
                        color: SkinTheme.textPrimary
                        font.family: SkinTheme.fontDisplay
                        font.pixelSize: 18
                        font.bold: true
                        font.letterSpacing: 1.5
                    }

                    Text {
                        text: "One-click loadouts for full Arcana collections, competitive FPS tweaks, or custom setups."
                        color: SkinTheme.textSecondary
                        font.family: SkinTheme.fontFamily
                        font.pixelSize: 12
                    }
                }

                Item { Layout.fillWidth: true }

                // Close Button
                Rectangle {
                    width: 32
                    height: 32
                    radius: SkinTheme.radiusSmall
                    color: closeMouse.containsMouse ? SkinTheme.bgCardHover : "transparent"
                    border.color: closeMouse.containsMouse ? SkinTheme.accentCyan : SkinTheme.borderMuted
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        color: closeMouse.containsMouse ? SkinTheme.accentCyan : SkinTheme.textSecondary
                        font.family: SkinTheme.fontMono
                        font.pixelSize: 13
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: presetsModal.closeRequested()
                    }
                }
            }

            // Save Current Setup Bar
            Rectangle {
                Layout.fillWidth: true
                height: 48
                radius: SkinTheme.radiusMedium
                color: SkinTheme.bgCard
                border.color: SkinTheme.borderMuted
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 10

                    Text {
                        text: "💾"
                        font.pixelSize: 14
                    }

                    TextInput {
                        id: presetNameInput
                        Layout.fillWidth: true
                        color: SkinTheme.textPrimary
                        font.family: SkinTheme.fontFamily
                        font.pixelSize: 13
                        selectByMouse: true
                        clip: true

                        Text {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Enter custom preset name to save active skins..."
                            color: SkinTheme.textMuted
                            font: parent.font
                            visible: !parent.text && !parent.activeFocus
                        }
                    }

                    Rectangle {
                        height: 32
                        radius: SkinTheme.radiusSmall
                        implicitWidth: saveBtnLabel.implicitWidth + 24
                        color: savePresetMouse.containsMouse ? SkinTheme.accentVioletHover : SkinTheme.accentViolet
                        border.color: SkinTheme.accentVioletHover
                        border.width: 1

                        Text {
                            id: saveBtnLabel
                            anchors.centerIn: parent
                            text: "SAVE SETUP"
                            color: "#ffffff"
                            font.family: SkinTheme.fontMono
                            font.pixelSize: 10
                            font.bold: true
                            font.letterSpacing: 1.0
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

            // Presets List
            ListView {
                id: presetsListView
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12
                clip: true
                model: presetsModal.presetsList

                ScrollBar.vertical: ScrollBar {
                    width: 4
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle {
                        radius: 2
                        color: SkinTheme.accentCyan
                        opacity: 0.4
                    }
                }

                delegate: Rectangle {
                    width: presetsListView.width - 10
                    height: 100
                    radius: SkinTheme.radiusMedium
                    color: itemHoverMouse.containsMouse ? SkinTheme.bgCardHover : SkinTheme.bgCard
                    border.color: itemHoverMouse.containsMouse ? SkinTheme.accentCyan : SkinTheme.borderMuted
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }
                    Behavior on border.color { ColorAnimation { duration: SkinTheme.animFast } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 16

                        // Icon
                        Rectangle {
                            width: 52
                            height: 52
                            radius: SkinTheme.radiusMedium
                            color: SkinTheme.bgDark
                            border.color: SkinTheme.borderMuted
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: modelData.icon || "🎭"
                                font.pixelSize: 24
                            }
                        }

                        // Details
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            RowLayout {
                                spacing: 8

                                Text {
                                    text: modelData.name
                                    color: SkinTheme.textPrimary
                                    font.family: SkinTheme.fontDisplay
                                    font.pixelSize: 14
                                    font.bold: true
                                }

                                Rectangle {
                                    height: 18
                                    radius: 3
                                    implicitWidth: badgeLabel.implicitWidth + 10
                                    color: modelData.badge === "PERFORMANCE" ? SkinTheme.accentEmeraldGlow :
                                           (modelData.badge === "USER" ? SkinTheme.accentVioletGlow : SkinTheme.accentCyanGlow)
                                    border.color: modelData.badge === "PERFORMANCE" ? SkinTheme.accentEmerald :
                                                  (modelData.badge === "USER" ? SkinTheme.accentViolet : SkinTheme.accentCyan)
                                    border.width: 1

                                    Text {
                                        id: badgeLabel
                                        anchors.centerIn: parent
                                        text: modelData.badge
                                        color: modelData.badge === "PERFORMANCE" ? SkinTheme.accentEmerald :
                                               (modelData.badge === "USER" ? SkinTheme.accentViolet : SkinTheme.accentCyan)
                                        font.family: SkinTheme.fontMono
                                        font.pixelSize: 8
                                        font.bold: true
                                        font.letterSpacing: 0.8
                                    }
                                }

                                Text {
                                    text: "• " + modelData.itemCount + " skins"
                                    color: SkinTheme.textMuted
                                    font.family: SkinTheme.fontMono
                                    font.pixelSize: 11
                                }
                            }

                            Text {
                                text: modelData.description
                                color: SkinTheme.textSecondary
                                font.family: SkinTheme.fontFamily
                                font.pixelSize: 12
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                maximumLineCount: 2
                                wrapMode: Text.WordWrap
                            }
                        }

                        // Actions
                        RowLayout {
                            spacing: 8

                            // Delete (if user preset)
                            Rectangle {
                                visible: !modelData.isBuiltin
                                width: 34
                                height: 34
                                radius: SkinTheme.radiusSmall
                                color: delPresetMouse.containsMouse ? SkinTheme.accentCrimsonGlow : "transparent"
                                border.color: SkinTheme.accentCrimson
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: "✕"
                                    color: SkinTheme.accentCrimson
                                    font.family: SkinTheme.fontMono
                                    font.pixelSize: 12
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
                                implicitWidth: applyBtnText.implicitWidth + 24
                                color: applyMouse.containsMouse ? SkinTheme.accentCyanHover : SkinTheme.accentCyan
                                border.color: "transparent"

                                Text {
                                    id: applyBtnText
                                    anchors.centerIn: parent
                                    text: "⚡ APPLY PRESET"
                                    color: "#060810"
                                    font.family: SkinTheme.fontMono
                                    font.pixelSize: 10
                                    font.bold: true
                                    font.letterSpacing: 0.8
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

                    MouseArea {
                        id: itemHoverMouse
                        anchors.fill: parent
                        hoverEnabled: true
                    }
                }
            }
        }
    }
}
