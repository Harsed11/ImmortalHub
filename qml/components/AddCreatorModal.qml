import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"

Rectangle {
    id: addCreatorModal
    anchors.fill: parent
    color: SkinTheme.bgModalOverlay
    visible: opacity > 0
    opacity: isOpen ? 1.0 : 0.0
    z: 600

    Behavior on opacity { NumberAnimation { duration: SkinTheme.animFast } }

    property bool isOpen: false
    property string creatorName: ""
    property string telegramHandle: ""
    property string creatorDesc: ""
    property string avatarPath: ""

    function openWith(initialTg) {
        creatorName = ""
        telegramHandle = initialTg || ""
        creatorDesc = ""
        avatarPath = ""
        isOpen = true
        nameInput.forceActiveFocus()
    }

    function close() {
        isOpen = false
    }

    function submit() {
        if (!creatorName.trim()) {
            toast.show("Please enter a creator / channel name", "error")
            return
        }
        var ok = app.createCreator(creatorName, telegramHandle, creatorDesc, avatarPath)
        if (ok) {
            close()
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: addCreatorModal.close()
    }

    Rectangle {
        id: card
        width: Math.min(520, parent.width - 40)
        height: Math.min(540, parent.height - 40)
        anchors.centerIn: parent
        radius: SkinTheme.radiusLarge
        color: SkinTheme.bgDark
        border.color: SkinTheme.accentCyan
        border.width: 1
        clip: true

        MouseArea {
            anchors.fill: parent
            // Prevent click-through
        }

        // Top Accent Neon Line
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 2
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.5; color: SkinTheme.accentCyan }
                GradientStop { position: 1.0; color: "transparent" }
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

                Rectangle {
                    width: 36
                    height: 36
                    radius: 18
                    color: SkinTheme.accentCyanGlow
                    border.color: SkinTheme.accentCyan
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "✈️"
                        font.pixelSize: 16
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "ADD TELEGRAM / CREATOR"
                        color: SkinTheme.textPrimary
                        font.family: SkinTheme.fontMono
                        font.pixelSize: 13
                        font.bold: true
                        font.letterSpacing: 1.5
                    }

                    Text {
                        text: "Add a Telegram channel or modder collection to ImmortalHub"
                        color: SkinTheme.textMuted
                        font.pixelSize: 11
                    }
                }

                Rectangle {
                    width: 28
                    height: 28
                    radius: 14
                    color: closeMouse.containsMouse ? SkinTheme.bgCardHover : "transparent"
                    border.color: closeMouse.containsMouse ? SkinTheme.borderMuted : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        color: SkinTheme.textMuted
                        font.pixelSize: 12
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: addCreatorModal.close()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: SkinTheme.borderMuted
            }

            // Form Inputs
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 12

                // Name Input
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        text: "CHANNEL / CREATOR NAME *"
                        color: SkinTheme.textSecondary
                        font.family: SkinTheme.fontMono
                        font.pixelSize: 10
                        font.bold: true
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 38
                        radius: SkinTheme.radiusSmall
                        color: SkinTheme.bgVoid
                        border.color: nameInput.activeFocus ? SkinTheme.accentCyan : SkinTheme.borderMuted
                        border.width: 1

                        TextInput {
                            id: nameInput
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            verticalAlignment: TextInput.AlignVCenter
                            color: SkinTheme.textPrimary
                            font.pixelSize: 12
                            font.family: SkinTheme.fontFamily
                            text: addCreatorModal.creatorName
                            onTextChanged: addCreatorModal.creatorName = text

                            Text {
                                text: "e.g., Dota 2 Anime Skins or @modder_name"
                                color: SkinTheme.textMuted
                                font.pixelSize: 12
                                anchors.verticalCenter: parent.verticalCenter
                                visible: !nameInput.text.length && !nameInput.activeFocus
                            }
                        }
                    }
                }

                // Telegram Handle Input
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        text: "TELEGRAM HANDLE OR LINK"
                        color: SkinTheme.textSecondary
                        font.family: SkinTheme.fontMono
                        font.pixelSize: 10
                        font.bold: true
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 38
                        radius: SkinTheme.radiusSmall
                        color: SkinTheme.bgVoid
                        border.color: tgInput.activeFocus ? SkinTheme.accentCyan : SkinTheme.borderMuted
                        border.width: 1

                        TextInput {
                            id: tgInput
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            verticalAlignment: TextInput.AlignVCenter
                            color: SkinTheme.textPrimary
                            font.pixelSize: 12
                            font.family: SkinTheme.fontMono
                            text: addCreatorModal.telegramHandle
                            onTextChanged: addCreatorModal.telegramHandle = text

                            Text {
                                text: "@channel_name or https://t.me/channel"
                                color: SkinTheme.textMuted
                                font.pixelSize: 12
                                anchors.verticalCenter: parent.verticalCenter
                                visible: !tgInput.text.length && !tgInput.activeFocus
                            }
                        }
                    }
                }

                // Description Input
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        text: "DESCRIPTION / NOTES"
                        color: SkinTheme.textSecondary
                        font.family: SkinTheme.fontMono
                        font.pixelSize: 10
                        font.bold: true
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 56
                        radius: SkinTheme.radiusSmall
                        color: SkinTheme.bgVoid
                        border.color: descInput.activeFocus ? SkinTheme.accentCyan : SkinTheme.borderMuted
                        border.width: 1

                        TextInput {
                            id: descInput
                            anchors.fill: parent
                            anchors.margins: 10
                            color: SkinTheme.textPrimary
                            font.pixelSize: 12
                            font.family: SkinTheme.fontFamily
                            text: addCreatorModal.creatorDesc
                            onTextChanged: addCreatorModal.creatorDesc = text

                            Text {
                                text: "Optional description about these custom skins..."
                                color: SkinTheme.textMuted
                                font.pixelSize: 12
                                visible: !descInput.text.length && !descInput.activeFocus
                            }
                        }
                    }
                }

                // Avatar File Picker
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        text: "AVATAR / LOGO IMAGE (OPTIONAL)"
                        color: SkinTheme.textSecondary
                        font.family: SkinTheme.fontMono
                        font.pixelSize: 10
                        font.bold: true
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle {
                            width: 38
                            height: 38
                            radius: 19
                            color: SkinTheme.bgVoid
                            border.color: SkinTheme.borderMuted
                            border.width: 1
                            clip: true

                            Image {
                                anchors.fill: parent
                                source: addCreatorModal.avatarPath ? "file:///" + addCreatorModal.avatarPath.replace(/\\/g, "/") : ""
                                fillMode: Image.PreserveAspectCrop
                                visible: addCreatorModal.avatarPath !== ""
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "🎨"
                                font.pixelSize: 14
                                visible: !addCreatorModal.avatarPath
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 38
                            radius: SkinTheme.radiusSmall
                            color: SkinTheme.bgVoid
                            border.color: SkinTheme.borderMuted
                            border.width: 1

                            Text {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                verticalAlignment: Text.AlignVCenter
                                text: addCreatorModal.avatarPath ? addCreatorModal.avatarPath : "No avatar selected"
                                color: addCreatorModal.avatarPath ? SkinTheme.textPrimary : SkinTheme.textMuted
                                font.pixelSize: 11
                                elide: Text.ElideMiddle
                            }
                        }

                        Rectangle {
                            width: 80
                            height: 38
                            radius: SkinTheme.radiusSmall
                            color: browseMouse.containsMouse ? SkinTheme.accentCyanGlow : SkinTheme.bgCard
                            border.color: SkinTheme.accentCyan
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "BROWSE"
                                color: SkinTheme.accentCyan
                                font.family: SkinTheme.fontMono
                                font.pixelSize: 10
                                font.bold: true
                            }

                            MouseArea {
                                id: browseMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var f = app.chooseFile("Select Creator Avatar", "Image Files (*.png *.jpg *.jpeg *.webp)")
                                    if (f) {
                                        addCreatorModal.avatarPath = f
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }

            // Bottom Action Buttons
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    radius: SkinTheme.radiusSmall
                    color: cancelMouse.containsMouse ? SkinTheme.bgCardHover : "transparent"
                    border.color: SkinTheme.borderMuted
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "CANCEL"
                        color: SkinTheme.textSecondary
                        font.family: SkinTheme.fontMono
                        font.pixelSize: 11
                        font.bold: true
                    }

                    MouseArea {
                        id: cancelMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: addCreatorModal.close()
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    radius: SkinTheme.radiusSmall
                    color: submitMouse.containsMouse ? SkinTheme.accentCyanHover : SkinTheme.accentCyan

                    Text {
                        anchors.centerIn: parent
                        text: "CREATE CHANNEL"
                        color: "#050811"
                        font.family: SkinTheme.fontMono
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 1.0
                    }

                    MouseArea {
                        id: submitMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: addCreatorModal.submit()
                    }
                }
            }
        }
    }
}
