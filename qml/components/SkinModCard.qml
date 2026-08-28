import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"

Item {
    id: cardRoot
    width: parent ? parent.width - 16 : 320
    height: parent ? parent.height - 16 : 180

    property var modData: null
    property bool isInstalled: modData && modData.isInstalled !== undefined
                               ? modData.isInstalled
                               : (modData ? app.isModInstalled(modData.name, modData.categoryId) : false)
    property bool isFav: modData && modData.isFavorite !== undefined
                         ? modData.isFavorite
                         : (modData ? app.isFavorite(modData.name, modData.categoryId) : false)
    property bool isAudioPlaying: Boolean(modData && modData.audioUrl && app.isPlayingAudio && app.currentAudioUrl === modData.audioUrl)

    // Master hover state combining card body and interactive action buttons
    property bool isHovered: cardMouse.containsMouse || installBtnMouse.containsMouse || addBtnMouse.containsMouse

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

        scale: cardRoot.isHovered ? 1.02 : 1.0
        Behavior on scale { NumberAnimation { duration: SkinTheme.animNormal; easing.type: Easing.OutCubic } }

        // Animated neon border glow (installed state)
        Rectangle {
            anchors.centerIn: parent
            width: parent.width + (isInstalled ? 4 : 0)
            height: parent.height + (isInstalled ? 4 : 0)
            radius: parent.radius + 2
            color: "transparent"
            border.color: SkinTheme.accentCyan
            border.width: isInstalled ? 1 : 0
            opacity: isInstalled ? 0.6 : 0.0
            z: -2

            Behavior on opacity { NumberAnimation { duration: SkinTheme.animNormal; easing.type: Easing.OutCubic } }

            // Outer glow pulse
            Rectangle {
                anchors.centerIn: parent
                width: parent.width + 6
                height: parent.height + 6
                radius: parent.radius + 3
                color: "transparent"
                border.color: SkinTheme.accentCyan
                border.width: 1
                opacity: 0.2

                SequentialAnimation on opacity {
                    running: isInstalled
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.05; duration: 1500; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 0.25; duration: 1500; easing.type: Easing.InOutSine }
                }
            }
        }

        // Hover neon border (cyan → violet animated)
        Rectangle {
            anchors.centerIn: parent
            width: parent.width + 2
            height: parent.height + 2
            radius: parent.radius + 1
            color: "transparent"
            border.color: SkinTheme.accentViolet
            border.width: cardRoot.isHovered && !isInstalled ? 1 : 0
            opacity: cardRoot.isHovered && !isInstalled ? 0.6 : 0.0
            z: -1

            Behavior on opacity { NumberAnimation { duration: SkinTheme.animFast; easing.type: Easing.OutCubic } }
        }

        // Main Card Content (Full Bleed Image)
        Rectangle {
            anchors.fill: parent
            radius: SkinTheme.radiusLarge
            color: SkinTheme.bgDark
            clip: true
            border.color: isInstalled ? SkinTheme.accentCyan : SkinTheme.borderMuted
            border.width: 1

            Image {
                id: previewImg
                anchors.fill: parent
                source: modData && modData.previewUrl ? modData.previewUrl : ""
                fillMode: Image.PreserveAspectCrop
                sourceSize.width: 380
                sourceSize.height: 214
                asynchronous: true
                cache: true

                BusyIndicator {
                    anchors.centerIn: parent
                    running: previewImg.status === Image.Loading
                    width: 28
                    height: 28
                }
            }

            // Heavy bottom gradient for text readability
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#00000000" }
                    GradientStop { position: 0.35; color: "#18000000" }
                    GradientStop { position: 1.0; color: "#F0060810" }
                }
            }

            // Hover Overlay — cyberpunk glassmorphism
            Rectangle {
                anchors.fill: parent
                color: "#75060810"
                opacity: cardRoot.isHovered ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: SkinTheme.animFast; easing.type: Easing.OutCubic } }

                // Hover action button
                Rectangle {
                    id: actionBtn
                    anchors.centerIn: parent
                    width: 124
                    height: 36
                    radius: SkinTheme.radiusMedium
                    opacity: cardRoot.isHovered ? 1.0 : 0.0
                    scale: installBtnMouse.containsMouse ? 1.05 : (cardRoot.isHovered ? 1.0 : 0.88)

                    Behavior on opacity { NumberAnimation { duration: SkinTheme.animFast; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: SkinTheme.animFast; easing.type: Easing.OutCubic } }

                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop {
                            position: 0.0
                            color: isInstalled
                                   ? (installBtnMouse.containsMouse ? SkinTheme.accentCrimsonHover : SkinTheme.accentCrimson)
                                   : (installBtnMouse.containsMouse ? SkinTheme.accentCyanHover : SkinTheme.accentCyan)
                        }
                        GradientStop {
                            position: 1.0
                            color: isInstalled
                                   ? SkinTheme.accentCrimsonDark
                                   : (installBtnMouse.containsMouse ? SkinTheme.accentVioletHover : SkinTheme.accentViolet)
                        }
                    }

                    // Button glow
                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width + 6
                        height: parent.height + 6
                        radius: parent.radius + 3
                        color: "transparent"
                        border.color: isInstalled ? SkinTheme.accentCrimson : SkinTheme.accentCyan
                        border.width: 1
                        opacity: installBtnMouse.containsMouse ? 0.6 : (cardRoot.isHovered ? 0.25 : 0)
                        Behavior on opacity { NumberAnimation { duration: SkinTheme.animFast } }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: isInstalled ? "⊘ REMOVE" : "⚡ INSTALL"
                        color: "#ffffff"
                        font.family: SkinTheme.fontMono
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 1.0
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

            // Text Content
            ColumnLayout {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.margins: 14
                spacing: 2

                Text {
                    text: modData ? (modData.hero || (typeof app !== "undefined" && app && app.translate ? app.translate(modData.categoryId) : (modData.categoryId || ""))) : ""
                    color: SkinTheme.accentCyan
                    font.family: SkinTheme.fontMono
                    font.pixelSize: 9
                    font.bold: true
                    font.letterSpacing: 1.2
                    opacity: 0.8
                }

                Text {
                    text: modData ? modData.name : ""
                    color: "#ffffff"
                    font.family: SkinTheme.fontFamily
                    font.pixelSize: 15
                    font.bold: true
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }

            // Installed badge — top left
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.margins: 10
                height: 22
                radius: SkinTheme.radiusSmall
                implicitWidth: installedText.implicitWidth + 14
                color: "#D0060810"
                border.color: SkinTheme.accentEmerald
                border.width: 1
                visible: isInstalled

                Text {
                    id: installedText
                    anchors.centerIn: parent
                    text: "● ACTIVE"
                    color: SkinTheme.accentEmerald
                    font.family: SkinTheme.fontMono
                    font.pixelSize: 8
                    font.bold: true
                    font.letterSpacing: 1.0
                }
            }

            // Add to Queue (+) Button — top right
            Rectangle {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 10
                width: 32
                height: 32
                radius: SkinTheme.radiusMedium
                color: "#A0060810"
                border.color: addBtnMouse.containsMouse ? SkinTheme.accentCyan : SkinTheme.borderLight
                border.width: 1
                opacity: cardRoot.isHovered ? 1.0 : 0.0

                Behavior on opacity { NumberAnimation { duration: SkinTheme.animFast } }
                Behavior on border.color { ColorAnimation { duration: SkinTheme.animFast } }

                // Neon glow on hover
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width + 4
                    height: parent.height + 4
                    radius: parent.radius + 2
                    color: "transparent"
                    border.color: SkinTheme.accentCyan
                    border.width: 1
                    opacity: addBtnMouse.containsMouse ? 0.3 : 0
                    Behavior on opacity { NumberAnimation { duration: SkinTheme.animFast } }
                }

                Text {
                    anchors.centerIn: parent
                    text: "+"
                    color: addBtnMouse.containsMouse ? SkinTheme.accentCyan : SkinTheme.textPrimary
                    font.family: SkinTheme.fontFamily
                    font.pixelSize: 18
                    font.weight: Font.Light

                    Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }
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
