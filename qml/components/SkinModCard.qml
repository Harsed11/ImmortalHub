import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"

Item {
    id: cardRoot
    width: parent ? parent.width - 16 : 320
    height: parent ? parent.height - 16 : 195

    property var modData: null
    property bool isInstalled: modData && modData.isInstalled !== undefined
                               ? modData.isInstalled
                               : (modData ? app.isModInstalled(modData.name, modData.categoryId) : false)
    property bool isFav: modData && modData.isFavorite !== undefined
                         ? modData.isFavorite
                         : (modData ? app.isFavorite(modData.name, modData.categoryId) : false)
    property bool isAudioPlaying: Boolean(modData && modData.audioUrl && app.isPlayingAudio && app.currentAudioUrl === modData.audioUrl)

    // Master hover state combining card body and interactive action buttons
    property bool isHovered: cardMouse.containsMouse || installBtnMouse.containsMouse || addBtnMouse.containsMouse || favBtnMouse.containsMouse || toggleMouse.containsMouse

    // Determine rarity tone from modData or name
    function getRarityColor() {
        if (!modData) return SkinTheme.accentCyan
        var r = (modData.rarity || "").toLowerCase()
        if (r === "arcana") return SkinTheme.rarityArcana
        if (r === "immortal") return SkinTheme.rarityImmortal
        if (r === "persona") return SkinTheme.rarityPersona
        if (r === "mythical") return SkinTheme.rarityMythical
        if (r === "rare") return SkinTheme.rarityRare
        
        var n = (modData.name || "").toLowerCase()
        if (n.indexOf("arcana") !== -1) return SkinTheme.rarityArcana
        if (n.indexOf("immortal") !== -1) return SkinTheme.rarityImmortal
        if (n.indexOf("persona") !== -1) return SkinTheme.rarityPersona
        if (n.indexOf("mythical") !== -1 || n.indexOf("collector") !== -1) return SkinTheme.rarityMythical
        if (n.indexOf("rare") !== -1) return SkinTheme.rarityRare
        return SkinTheme.accentCyan
    }

    function getRarityLabel() {
        if (!modData) return "MOD"
        var r = (modData.rarity || "").toUpperCase()
        if (r && r !== "STANDARD") return r
        var n = (modData.name || "").toLowerCase()
        if (n.indexOf("arcana") !== -1) return "ARCANA"
        if (n.indexOf("immortal") !== -1) return "IMMORTAL"
        if (n.indexOf("persona") !== -1) return "PERSONA"
        if (n.indexOf("mythical") !== -1 || n.indexOf("collector") !== -1) return "MYTHICAL"
        return "ITEM"
    }

    signal clicked()
    signal installRequested()
    signal uninstallRequested()
    signal addToCartRequested()

    Rectangle {
        id: card
        anchors.fill: parent
        radius: SkinTheme.radiusLarge
        color: "transparent"
        border.color: "transparent"
        border.width: 0

        scale: cardMouse.pressed ? 0.98 : (cardRoot.isHovered ? 1.025 : 1.0)
        Behavior on scale { NumberAnimation { duration: SkinTheme.animNormal; easing.type: Easing.OutCubic } }

        // Subtle outer border glow on hover or when installed
        Rectangle {
            anchors.centerIn: parent
            width: parent.width + 2
            height: parent.height + 2
            radius: parent.radius + 1
            color: "transparent"
            border.color: isInstalled ? SkinTheme.accentEmerald : (cardRoot.isHovered ? cardRoot.getRarityColor() : "transparent")
            border.width: (isInstalled || cardRoot.isHovered) ? 1 : 0
            opacity: isInstalled ? 0.8 : (cardRoot.isHovered ? 0.6 : 0.0)
            z: -1

            Behavior on opacity { NumberAnimation { duration: SkinTheme.animFast; easing.type: Easing.OutCubic } }
            Behavior on border.color { ColorAnimation { duration: SkinTheme.animFast } }
        }

        // Main Card Surface
        Rectangle {
            anchors.fill: parent
            radius: SkinTheme.radiusLarge
            color: SkinTheme.bgCard
            clip: true
            border.color: isInstalled ? SkinTheme.accentEmeraldDark : SkinTheme.borderMuted
            border.width: 1

            // Shimmer skeleton placeholder
            Rectangle {
                id: previewSkeleton
                anchors.fill: parent
                color: SkinTheme.bgDark
                visible: previewImg.status !== Image.Ready

                Rectangle {
                    width: parent.width * 0.6
                    height: parent.height
                    visible: previewSkeleton.visible
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 0.5; color: "#0DFFFFFF" }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                    SequentialAnimation on x {
                        loops: Animation.Infinite
                        running: previewSkeleton.visible
                        NumberAnimation { from: -parent.width; to: parent.width; duration: 1300 }
                    }
                }
            }

            // Preview Image
            Image {
                id: previewImg
                anchors.fill: parent
                source: modData && modData.previewUrl ? modData.previewUrl : ""
                fillMode: Image.PreserveAspectCrop
                sourceSize.width: 380
                sourceSize.height: 214
                asynchronous: true
                cache: true
                opacity: status === Image.Ready ? 1.0 : 0.0
                scale: cardRoot.isHovered ? 1.05 : 1.0

                Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
            }

            // Dark vignette overlay
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#20000000" }
                    GradientStop { position: 0.4; color: "#3508080E" }
                    GradientStop { position: 1.0; color: "#F508080E" }
                }
            }

            // Top rarity color bar
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 3
                color: cardRoot.getRarityColor()
                opacity: cardRoot.isHovered ? 1.0 : 0.6
                Behavior on opacity { NumberAnimation { duration: SkinTheme.animFast } }
            }

            // Hover Actions Overlay
            Rectangle {
                anchors.fill: parent
                color: "#6508080E"
                opacity: (cardRoot.isHovered && !toggleMouse.containsMouse) ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: SkinTheme.animFast; easing.type: Easing.OutCubic } }

                // Centered Action Button
                Rectangle {
                    id: actionBtn
                    anchors.centerIn: parent
                    width: 130
                    height: 36
                    radius: SkinTheme.radiusMedium
                    opacity: cardRoot.isHovered ? 1.0 : 0.0
                    scale: installBtnMouse.containsMouse ? 1.05 : (cardRoot.isHovered ? 1.0 : 0.9)

                    Behavior on opacity { NumberAnimation { duration: SkinTheme.animFast } }
                    Behavior on scale { NumberAnimation { duration: SkinTheme.animFast; easing.type: Easing.OutCubic } }

                    color: isInstalled
                           ? (installBtnMouse.containsMouse ? SkinTheme.accentCrimsonHover : SkinTheme.accentCrimson)
                           : (installBtnMouse.containsMouse ? SkinTheme.accentCyanHover : SkinTheme.accentCyan)

                    Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: isInstalled ? "⊘" : "⚡"
                            color: "#FFFFFF"
                            font.pixelSize: 11
                        }

                        Text {
                            text: isInstalled ? "UNINSTALL" : "INSTALL"
                            color: "#FFFFFF"
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: SkinTheme.fontSizeSmall
                            font.bold: true
                            font.letterSpacing: 0.8
                        }
                    }

                    MouseArea {
                        id: installBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (isInstalled) cardRoot.uninstallRequested()
                            else cardRoot.installRequested()
                        }
                    }
                }
            }

            // Bottom Glassmorphic Footer Info
            RowLayout {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.margins: 12
                spacing: 8

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: modData ? (modData.hero || (typeof app !== "undefined" && app && app.translate ? app.translate(modData.categoryId) : (modData.categoryId || ""))) : ""
                        color: cardRoot.getRarityColor()
                        font.family: SkinTheme.fontMono
                        font.pixelSize: SkinTheme.fontSizeTiny
                        font.bold: true
                        font.letterSpacing: 1.0
                        opacity: 0.9
                    }

                    Text {
                        text: modData ? modData.name : ""
                        color: SkinTheme.textPrimary
                        font.family: SkinTheme.fontFamily
                        font.pixelSize: SkinTheme.fontSizeBody
                        font.bold: true
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }

                // Direct 1-Click Quick Toggle Switch
                Rectangle {
                    width: 36
                    height: 20
                    radius: 10
                    color: isInstalled ? SkinTheme.accentEmerald : SkinTheme.bgCardActive
                    border.color: isInstalled ? SkinTheme.accentEmerald : SkinTheme.borderMuted
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

                    // Knob
                    Rectangle {
                        width: 14
                        height: 14
                        radius: 7
                        color: "#FFFFFF"
                        anchors.verticalCenter: parent.verticalCenter
                        x: isInstalled ? parent.width - width - 3 : 3

                        Behavior on x { NumberAnimation { duration: SkinTheme.animFast; easing.type: Easing.OutCubic } }
                    }

                    MouseArea {
                        id: toggleMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (isInstalled) cardRoot.uninstallRequested()
                            else cardRoot.installRequested()
                        }
                    }
                }
            }

            // Top-Left Badges Row
            RowLayout {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.margins: 8
                spacing: 6

                // Rarity Tag
                Rectangle {
                    height: 18
                    radius: SkinTheme.radiusSmall
                    implicitWidth: rarityPillTxt.implicitWidth + 10
                    color: "#D008080E"
                    border.color: cardRoot.getRarityColor()
                    border.width: 1

                    Text {
                        id: rarityPillTxt
                        anchors.centerIn: parent
                        text: cardRoot.getRarityLabel()
                        color: cardRoot.getRarityColor()
                        font.family: SkinTheme.fontMono
                        font.pixelSize: 7
                        font.bold: true
                    }
                }

                // Active Badge
                Rectangle {
                    height: 18
                    radius: SkinTheme.radiusSmall
                    implicitWidth: installedText.implicitWidth + 10
                    color: "#D008080E"
                    border.color: SkinTheme.accentEmerald
                    border.width: 1
                    visible: isInstalled

                    Text {
                        id: installedText
                        anchors.centerIn: parent
                        text: "● ACTIVE"
                        color: SkinTheme.accentEmerald
                        font.family: SkinTheme.fontMono
                        font.pixelSize: 7
                        font.bold: true
                    }
                }

                // Audio Playing Indicator
                Rectangle {
                    height: 18
                    width: 18
                    radius: SkinTheme.radiusSmall
                    color: "#D008080E"
                    border.color: SkinTheme.accentViolet
                    border.width: 1
                    visible: isAudioPlaying

                    Text {
                        anchors.centerIn: parent
                        text: "♪"
                        color: SkinTheme.accentViolet
                        font.pixelSize: 10
                    }

                    SequentialAnimation on opacity {
                        running: isAudioPlaying
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.4; duration: 600 }
                        NumberAnimation { to: 1.0; duration: 600 }
                    }
                }
            }

            // Top-Right Action Buttons
            RowLayout {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 8
                spacing: 4

                // Favorite Star Button
                Rectangle {
                    width: 26
                    height: 26
                    radius: SkinTheme.radiusSmall
                    color: isFav ? SkinTheme.accentAmberGlow : "#A008080E"
                    border.color: isFav ? SkinTheme.accentAmber : (favBtnMouse.containsMouse ? SkinTheme.textPrimary : SkinTheme.borderMuted)
                    border.width: 1
                    opacity: (cardRoot.isHovered || isFav) ? 1.0 : 0.0

                    Behavior on opacity { NumberAnimation { duration: SkinTheme.animFast } }
                    Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

                    Text {
                        anchors.centerIn: parent
                        text: isFav ? "★" : "☆"
                        color: isFav ? SkinTheme.accentAmber : (favBtnMouse.containsMouse ? SkinTheme.textPrimary : SkinTheme.textMuted)
                        font.pixelSize: 11
                    }

                    MouseArea {
                        id: favBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (modData && app) {
                                app.toggleFavorite(JSON.stringify(modData))
                            }
                        }
                    }
                }

                // Add to Queue (+) Button
                Rectangle {
                    width: 26
                    height: 26
                    radius: SkinTheme.radiusSmall
                    color: addBtnMouse.containsMouse ? SkinTheme.accentCyanGlow : "#A008080E"
                    border.color: addBtnMouse.containsMouse ? SkinTheme.accentCyan : SkinTheme.borderMuted
                    border.width: 1
                    opacity: cardRoot.isHovered ? 1.0 : 0.0

                    Behavior on opacity { NumberAnimation { duration: SkinTheme.animFast } }

                    Text {
                        anchors.centerIn: parent
                        text: "+"
                        color: addBtnMouse.containsMouse ? SkinTheme.accentCyan : SkinTheme.textPrimary
                        font.family: SkinTheme.fontFamily
                        font.pixelSize: 15
                        font.weight: Font.Light
                    }

                    MouseArea {
                        id: addBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: cardRoot.addToCartRequested()
                    }
                }
            }
        }

        MouseArea {
            id: cardMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            z: -1
            onClicked: cardRoot.clicked()
        }
    }
}
