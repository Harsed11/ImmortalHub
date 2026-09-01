import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"

Rectangle {
    id: addModModal
    anchors.fill: parent
    color: SkinTheme.bgModalOverlay
    visible: opacity > 0
    opacity: isOpen ? 1.0 : 0.0
    z: 600

    Behavior on opacity { NumberAnimation { duration: SkinTheme.animFast } }

    property bool isOpen: false
    property string creatorId: ""
    property string creatorName: ""
    property string modName: ""
    property string heroName: "Invoker"
    property string vpkFilePath: ""
    property string previewImagePath: ""
    property string modDesc: ""

    function openForCreator(cId, cName, prefillVpk) {
        creatorId = cId
        creatorName = cName
        vpkFilePath = prefillVpk || ""
        previewImagePath = ""
        modDesc = ""
        
        if (prefillVpk) {
            var base = prefillVpk.split("/").pop().split("\\").pop()
            var clean = base.replace(/\.[^/.]+$/, "").replace(/_/g, " ").replace(/-/g, " ")
            modName = clean
        } else {
            modName = ""
        }
        
        heroName = "Invoker"
        isOpen = true
        modNameInput.forceActiveFocus()
    }

    function close() {
        isOpen = false
    }

    function submit() {
        if (!modName.trim()) {
            toast.show("Please enter a skin name", "error")
            return
        }
        if (!vpkFilePath.trim()) {
            toast.show("Please select a .vpk or .zip mod file", "error")
            return
        }

        var ok = app.addCreatorMod(creatorId, modName, heroName, vpkFilePath, previewImagePath, modDesc)
        if (ok) {
            close()
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: addModModal.close()
    }

    Rectangle {
        id: card
        width: Math.min(560, parent.width - 40)
        height: Math.min(640, parent.height - 40)
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
            spacing: 14

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
                        text: "⚔️"
                        font.pixelSize: 16
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "ADD CUSTOM VPK SKIN"
                        color: SkinTheme.textPrimary
                        font.family: SkinTheme.fontMono
                        font.pixelSize: 13
                        font.bold: true
                        font.letterSpacing: 1.5
                    }

                    Text {
                        text: "Creator / Channel: " + (addModModal.creatorName || "Custom")
                        color: SkinTheme.accentCyan
                        font.pixelSize: 11
                        font.bold: true
                    }
                }

                Rectangle {
                    width: 28
                    height: 28
                    radius: 14
                    color: closeModMouse.containsMouse ? SkinTheme.bgCardHover : "transparent"
                    border.color: closeModMouse.containsMouse ? SkinTheme.borderMuted : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        color: SkinTheme.textMuted
                        font.pixelSize: 12
                    }

                    MouseArea {
                        id: closeModMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: addModModal.close()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: SkinTheme.borderMuted
            }

            // Form Fields
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10

                // Skin Name
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        text: "SKIN NAME *"
                        color: SkinTheme.textSecondary
                        font.family: SkinTheme.fontMono
                        font.pixelSize: 10
                        font.bold: true
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        radius: SkinTheme.radiusSmall
                        color: SkinTheme.bgVoid
                        border.color: modNameInput.activeFocus ? SkinTheme.accentCyan : SkinTheme.borderMuted
                        border.width: 1

                        TextInput {
                            id: modNameInput
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            verticalAlignment: TextInput.AlignVCenter
                            color: SkinTheme.textPrimary
                            font.pixelSize: 12
                            font.family: SkinTheme.fontFamily
                            text: addModModal.modName
                            onTextChanged: addModModal.modName = text

                            Text {
                                text: "e.g., Bloodstained Magus Arcana"
                                color: SkinTheme.textMuted
                                font.pixelSize: 12
                                anchors.verticalCenter: parent.verticalCenter
                                visible: !modNameInput.text.length && !modNameInput.activeFocus
                            }
                        }
                    }
                }

                // Hero & Category
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        text: "DOTA 2 HERO *"
                        color: SkinTheme.textSecondary
                        font.family: SkinTheme.fontMono
                        font.pixelSize: 10
                        font.bold: true
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        radius: SkinTheme.radiusSmall
                        color: SkinTheme.bgVoid
                        border.color: heroInput.activeFocus ? SkinTheme.accentCyan : SkinTheme.borderMuted
                        border.width: 1

                        TextInput {
                            id: heroInput
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            verticalAlignment: TextInput.AlignVCenter
                            color: SkinTheme.textPrimary
                            font.pixelSize: 12
                            font.family: SkinTheme.fontFamily
                            text: addModModal.heroName
                            onTextChanged: addModModal.heroName = text

                            Text {
                                text: "Type Hero (e.g. Invoker, Juggernaut, Pudge, Shadow Fiend, Global)"
                                color: SkinTheme.textMuted
                                font.pixelSize: 12
                                anchors.verticalCenter: parent.verticalCenter
                                visible: !heroInput.text.length && !heroInput.activeFocus
                            }
                        }
                    }
                }

                // VPK / ZIP Mod File Picker
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        text: "VPK OR ZIP MOD FILE *"
                        color: SkinTheme.textSecondary
                        font.family: SkinTheme.fontMono
                        font.pixelSize: 10
                        font.bold: true
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 36
                            radius: SkinTheme.radiusSmall
                            color: SkinTheme.bgVoid
                            border.color: addModModal.vpkFilePath ? SkinTheme.accentCyan : SkinTheme.borderMuted
                            border.width: 1

                            Text {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                verticalAlignment: Text.AlignVCenter
                                text: addModModal.vpkFilePath ? addModModal.vpkFilePath : "Select .vpk or .zip file..."
                                color: addModModal.vpkFilePath ? SkinTheme.accentCyan : SkinTheme.textMuted
                                font.pixelSize: 11
                                font.family: SkinTheme.fontMono
                                elide: Text.ElideMiddle
                            }
                        }

                        Rectangle {
                            width: 86
                            height: 36
                            radius: SkinTheme.radiusSmall
                            color: browseVpkMouse.containsMouse ? SkinTheme.accentCyanGlow : SkinTheme.bgCard
                            border.color: SkinTheme.accentCyan
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "SELECT"
                                color: SkinTheme.accentCyan
                                font.family: SkinTheme.fontMono
                                font.pixelSize: 10
                                font.bold: true
                            }

                            MouseArea {
                                id: browseVpkMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var f = app.chooseFile("Select Mod File", "VPK / ZIP Archives (*.vpk *.zip)")
                                    if (f) {
                                        addModModal.vpkFilePath = f
                                        if (!addModModal.modName) {
                                            var base = f.split("/").pop().split("\\").pop()
                                            addModModal.modName = base.replace(/\.[^/.]+$/, "").replace(/_/g, " ").replace(/-/g, " ")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Preview Image Picker
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        text: "PREVIEW IMAGE (OPTIONAL)"
                        color: SkinTheme.textSecondary
                        font.family: SkinTheme.fontMono
                        font.pixelSize: 10
                        font.bold: true
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle {
                            width: 36
                            height: 36
                            radius: SkinTheme.radiusSmall
                            color: SkinTheme.bgVoid
                            border.color: SkinTheme.borderMuted
                            border.width: 1
                            clip: true

                            Image {
                                anchors.fill: parent
                                source: addModModal.previewImagePath ? "file:///" + addModModal.previewImagePath.replace(/\\/g, "/") : ""
                                fillMode: Image.PreserveAspectCrop
                                visible: addModModal.previewImagePath !== ""
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "🖼️"
                                font.pixelSize: 14
                                visible: !addModModal.previewImagePath
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 36
                            radius: SkinTheme.radiusSmall
                            color: SkinTheme.bgVoid
                            border.color: SkinTheme.borderMuted
                            border.width: 1

                            Text {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                verticalAlignment: Text.AlignVCenter
                                text: addModModal.previewImagePath ? addModModal.previewImagePath : "No preview image selected"
                                color: addModModal.previewImagePath ? SkinTheme.textPrimary : SkinTheme.textMuted
                                font.pixelSize: 11
                                font.family: SkinTheme.fontMono
                                elide: Text.ElideMiddle
                            }
                        }

                        Rectangle {
                            width: 86
                            height: 36
                            radius: SkinTheme.radiusSmall
                            color: browseImgMouse.containsMouse ? SkinTheme.accentCyanGlow : SkinTheme.bgCard
                            border.color: SkinTheme.accentCyan
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "SELECT"
                                color: SkinTheme.accentCyan
                                font.family: SkinTheme.fontMono
                                font.pixelSize: 10
                                font.bold: true
                            }

                            MouseArea {
                                id: browseImgMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var f = app.chooseFile("Select Preview Image", "Image Files (*.png *.jpg *.jpeg *.webp)")
                                    if (f) {
                                        addModModal.previewImagePath = f
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }

            // Actions
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    radius: SkinTheme.radiusSmall
                    color: cancelModMouse.containsMouse ? SkinTheme.bgCardHover : "transparent"
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
                        id: cancelModMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: addModModal.close()
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    radius: SkinTheme.radiusSmall
                    color: submitModMouse.containsMouse ? SkinTheme.accentCyanHover : SkinTheme.accentCyan

                    Text {
                        anchors.centerIn: parent
                        text: "+ ADD SKIN"
                        color: "#050811"
                        font.family: SkinTheme.fontMono
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 1.0
                    }

                    MouseArea {
                        id: submitModMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: addModModal.submit()
                    }
                }
            }
        }
    }
}
