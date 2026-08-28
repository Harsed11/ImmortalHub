import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"

Rectangle {
    id: detailModal
    anchors.fill: parent
    color: SkinTheme.bgModalOverlay
    visible: opacity > 0
    opacity: modData !== null ? 1 : 0
    z: 500

    Behavior on opacity { NumberAnimation { duration: SkinTheme.animFast } }

    property var modData: null
    property int selectedStyleIndex: 0
    property bool isAudioPlaying: Boolean(modData && modData.audioUrl && app.isPlayingAudio && app.currentAudioUrl === modData.audioUrl)

    signal addToCartRequested(var mod)
    signal closeRequested()

    onModDataChanged: {
        selectedStyleIndex = 0
    }

    function getCurrentPreviewUrl() {
        if (!modData) return ""
        if (modData.styles && modData.styles.length > selectedStyleIndex && modData.styles[selectedStyleIndex].previewUrl) {
            return modData.styles[selectedStyleIndex].previewUrl
        }
        return modData.previewUrl || ""
    }

    function getCurrentFile() {
        if (!modData) return ""
        if (modData.styles && modData.styles.length > selectedStyleIndex && modData.styles[selectedStyleIndex].file) {
            return modData.styles[selectedStyleIndex].file
        }
        return modData.file || ""
    }

    function getCurrentFileUrl() {
        if (!modData) return ""
        if (modData.styles && modData.styles.length > selectedStyleIndex && modData.styles[selectedStyleIndex].fileUrl) {
            return modData.styles[selectedStyleIndex].fileUrl
        }
        return modData.fileUrl || ""
    }

    function getCurrentAudioUrl() {
        if (!modData) return ""
        if (modData.audioUrl) return modData.audioUrl
        if (modData.links && modData.links.length > 0) {
            for (var i = 0; i < modData.links.length; i++) {
                var l = modData.links[i]
                if (l.url && (l.url.indexOf(".mp4") !== -1 || l.url.indexOf(".mp3") !== -1 || l.url.indexOf(".wav") !== -1)) {
                    return l.url
                }
            }
        }
        return ""
    }

    function getSelectedModPayload() {
        if (!modData) return null
        var copy = JSON.parse(JSON.stringify(modData))
        if (copy.styles && copy.styles.length > selectedStyleIndex) {
            copy.file = copy.styles[selectedStyleIndex].file
            copy.fileUrl = copy.styles[selectedStyleIndex].fileUrl
            copy.previewUrl = copy.styles[selectedStyleIndex].previewUrl
            if (copy.styles[selectedStyleIndex].label) {
                copy.name = copy.name + " (" + copy.styles[selectedStyleIndex].label + ")"
            }
        }
        return copy
    }

    // Background Click Dismiss
    MouseArea {
        anchors.fill: parent
        onClicked: detailModal.closeRequested()
    }

    // Scanning lines on backdrop
    Column {
        anchors.fill: parent
        opacity: 0.02
        z: -1
        Repeater {
            model: Math.floor(parent.height / 3)
            Rectangle {
                width: parent.width
                height: 1
                color: "#FFFFFF"
                visible: index % 2 === 0
            }
        }
    }

    // Modal Content
    Rectangle {
        id: modalBox
        width: Math.min(880, parent.width - 40)
        height: Math.min(640, parent.height - 40)
        anchors.centerIn: parent
        radius: SkinTheme.radiusXLarge
        color: SkinTheme.bgModal
        border.color: SkinTheme.borderLight
        border.width: 1
        clip: true

        scale: detailModal.modData !== null ? 1.0 : 0.95
        Behavior on scale { NumberAnimation { duration: SkinTheme.animNormal; easing.type: Easing.OutCubic } }

        // Neon outline glow
        Rectangle {
            anchors.centerIn: parent
            width: parent.width + 4
            height: parent.height + 4
            radius: parent.radius + 2
            color: "transparent"
            border.color: SkinTheme.accentCyan
            border.width: 1
            opacity: 0.15
            z: -1
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // Header
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                color: SkinTheme.bgDark

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: SkinTheme.borderMuted
                }

                // Top neon accent
                Rectangle {
                    anchors.top: parent.top
                    width: parent.width
                    height: 1
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 0.3; color: SkinTheme.accentCyan }
                        GradientStop { position: 0.7; color: SkinTheme.accentViolet }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                    opacity: 0.6
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 16
                    spacing: 12

                    Text {
                        text: modData ? modData.name : ""
                        color: SkinTheme.textPrimary
                        font.family: SkinTheme.fontFamily
                        font.pixelSize: SkinTheme.fontSizeTitle
                        font.bold: true
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    // Favorite Button
                    Rectangle {
                        width: 32
                        height: 32
                        radius: SkinTheme.radiusSmall
                        color: modData && app.isFavorite(modData.name, modData.categoryId)
                               ? SkinTheme.accentAmberGlow
                               : (favModalMouse.containsMouse ? SkinTheme.bgCardHover : "transparent")
                        border.color: modData && app.isFavorite(modData.name, modData.categoryId)
                                      ? SkinTheme.accentAmber
                                      : SkinTheme.borderMuted
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "★"
                            color: modData && app.isFavorite(modData.name, modData.categoryId)
                                   ? SkinTheme.accentAmber
                                   : SkinTheme.textMuted
                            font.pixelSize: 14
                        }

                        MouseArea {
                            id: favModalMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modData) {
                                    app.toggleFavorite(JSON.stringify(modData))
                                }
                            }
                        }
                    }

                    // Close Button
                    Rectangle {
                        width: 32
                        height: 32
                        radius: SkinTheme.radiusSmall
                        color: closeMouse.containsMouse ? SkinTheme.accentCrimson : "transparent"
                        border.color: closeMouse.containsMouse ? "transparent" : SkinTheme.borderMuted
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            color: closeMouse.containsMouse ? "#ffffff" : SkinTheme.textMuted
                            font.pixelSize: 12
                            font.bold: true
                        }

                        MouseArea {
                            id: closeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: detailModal.closeRequested()
                        }
                    }
                }
            }

            // Body — Preview + Details
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 20
                spacing: 20

                // Preview
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 480
                    radius: SkinTheme.radiusLarge
                    color: SkinTheme.bgDark
                    border.color: SkinTheme.borderMuted
                    border.width: 1
                    clip: true

                    Image {
                        id: bigPreview
                        anchors.fill: parent
                        anchors.margins: 4
                        source: getCurrentPreviewUrl()
                        fillMode: Image.PreserveAspectFit
                        sourceSize.width: 960
                        sourceSize.height: 540
                        asynchronous: true
                        cache: true

                        BusyIndicator {
                            anchors.centerIn: parent
                            running: bigPreview.status === Image.Loading
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "NO PREVIEW AVAILABLE"
                            color: SkinTheme.textMuted
                            font.family: SkinTheme.fontMono
                            font.pixelSize: 11
                            font.letterSpacing: 1.0
                            visible: bigPreview.status === Image.Error || !getCurrentPreviewUrl()
                        }
                    }
                }

                // Details Panel
                ColumnLayout {
                    Layout.preferredWidth: 340
                    Layout.fillHeight: true
                    spacing: 14

                    // Category & Hero Info
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            text: "// MOD INFORMATION"
                            color: SkinTheme.textMuted
                            font.family: SkinTheme.fontMono
                            font.pixelSize: 9
                            font.bold: true
                            font.letterSpacing: 1.5
                        }

                        RowLayout {
                            spacing: 6

                            Rectangle {
                                height: 24
                                radius: SkinTheme.radiusSmall
                                implicitWidth: catPillText.implicitWidth + 16
                                color: SkinTheme.accentCyanGlow
                                border.color: SkinTheme.accentCyan
                                border.width: 1

                                Text {
                                    id: catPillText
                                    anchors.centerIn: parent
                                    text: modData ? app.translate(modData.categoryId) : ""
                                    color: SkinTheme.accentCyan
                                    font.family: SkinTheme.fontMono
                                    font.pixelSize: 10
                                    font.bold: true
                                }
                            }

                            Rectangle {
                                height: 24
                                radius: SkinTheme.radiusSmall
                                implicitWidth: heroPillText.implicitWidth + 16
                                color: SkinTheme.accentVioletGlow
                                border.color: SkinTheme.accentViolet
                                border.width: 1
                                visible: Boolean(modData && modData.hero)

                                Text {
                                    id: heroPillText
                                    anchors.centerIn: parent
                                    text: modData && modData.hero ? modData.hero : ""
                                    color: SkinTheme.accentViolet
                                    font.family: SkinTheme.fontMono
                                    font.pixelSize: 10
                                    font.bold: true
                                }
                            }
                        }
                    }

                    // Styles Selection
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        visible: Boolean(modData && modData.styles && modData.styles.length > 0)

                        Text {
                            text: "// SELECT VARIANT (" + (modData && modData.styles ? modData.styles.length : 0) + ")"
                            color: SkinTheme.textMuted
                            font.family: SkinTheme.fontMono
                            font.pixelSize: 9
                            font.bold: true
                            font.letterSpacing: 1.5
                        }

                        Flow {
                            Layout.fillWidth: true
                            spacing: 6

                            Repeater {
                                model: modData && modData.styles ? modData.styles : []
                                delegate: Rectangle {
                                    height: 28
                                    radius: SkinTheme.radiusSmall
                                    implicitWidth: styleLabel.implicitWidth + 20
                                    color: selectedStyleIndex === index
                                           ? SkinTheme.accentViolet
                                           : (styleMouse.containsMouse ? SkinTheme.bgCardHover : SkinTheme.bgCard)
                                    border.color: selectedStyleIndex === index ? SkinTheme.accentVioletHover : SkinTheme.borderMuted
                                    border.width: 1

                                    Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

                                    Text {
                                        id: styleLabel
                                        anchors.centerIn: parent
                                        text: modelData.label ? modelData.label : "Style " + (index + 1)
                                        color: selectedStyleIndex === index ? "#ffffff" : SkinTheme.textSecondary
                                        font.family: SkinTheme.fontFamily
                                        font.pixelSize: 11
                                        font.bold: true
                                    }

                                    MouseArea {
                                        id: styleMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: selectedStyleIndex = index
                                    }
                                }
                            }
                        }
                    }

                    // Package File
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Text {
                            text: "// PACKAGE FILE"
                            color: SkinTheme.textMuted
                            font.family: SkinTheme.fontMono
                            font.pixelSize: 9
                            font.bold: true
                            font.letterSpacing: 1.5
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 30
                            radius: SkinTheme.radiusSmall
                            color: SkinTheme.bgInput
                            border.color: SkinTheme.borderMuted
                            border.width: 1

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.margins: 10
                                text: getCurrentFile()
                                color: SkinTheme.accentCyan
                                font.pixelSize: 10
                                font.family: SkinTheme.fontMono
                                elide: Text.ElideMiddle
                                opacity: 0.8
                            }
                        }
                    }

                    // Interactive Audio & Voice Line Preview with Waveform
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        radius: SkinTheme.radiusMedium
                        color: isAudioPlaying ? SkinTheme.accentCyanGlow : (playDemoMouse.containsMouse ? SkinTheme.bgCardHover : SkinTheme.bgCard)
                        border.color: isAudioPlaying ? SkinTheme.accentCyan : SkinTheme.borderMuted
                        border.width: 1
                        visible: Boolean(modData && getCurrentAudioUrl() !== "")

                        Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12

                            Rectangle {
                                width: 28
                                height: 28
                                radius: SkinTheme.radiusSmall
                                color: isAudioPlaying ? SkinTheme.accentCyan : SkinTheme.bgCardActive

                                Text {
                                    anchors.centerIn: parent
                                    text: isAudioPlaying ? "❚❚" : "▶"
                                    color: isAudioPlaying ? "#060810" : SkinTheme.accentCyan
                                    font.pixelSize: 10
                                    font.bold: true
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    text: isAudioPlaying ? "PLAYING AUDIO PREVIEW" : "LISTEN AUDIO & VOICE LINE"
                                    color: isAudioPlaying ? SkinTheme.accentCyan : SkinTheme.textPrimary
                                    font.family: SkinTheme.fontMono
                                    font.pixelSize: 10
                                    font.bold: true
                                    font.letterSpacing: 0.8
                                }

                                Text {
                                    text: isAudioPlaying ? "Click to stop playback" : "Voice lines, spell sounds, and music pack"
                                    color: SkinTheme.textMuted
                                    font.family: SkinTheme.fontFamily
                                    font.pixelSize: 11
                                }
                            }

                            // Animated Neon Waveform Bars
                            Row {
                                spacing: 3
                                Layout.alignment: Qt.AlignVCenter
                                visible: isAudioPlaying

                                Repeater {
                                    model: 6
                                    delegate: Rectangle {
                                        width: 3
                                        height: 6
                                        color: SkinTheme.accentCyan
                                        radius: 1

                                        SequentialAnimation on height {
                                            running: isAudioPlaying
                                            loops: Animation.Infinite
                                            NumberAnimation { to: (index % 2 === 0 ? 16 : 8); duration: 200 + index * 60; easing.type: Easing.InOutQuad }
                                            NumberAnimation { to: (index % 2 === 0 ? 6 : 18); duration: 200 + index * 60; easing.type: Easing.InOutQuad }
                                        }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: playDemoMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                var aUrl = getCurrentAudioUrl()
                                if (aUrl) {
                                    app.toggleAudio(aUrl)
                                } else if (modData) {
                                    app.playDemoVoiceLine(modData.name, modData.hero || "", modData.categoryId)
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    // Action Buttons
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        // Install Button — neon gradient
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 42
                            radius: SkinTheme.radiusMedium
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: instModalMouse.containsMouse ? SkinTheme.accentCyanHover : SkinTheme.accentCyan }
                                GradientStop { position: 1.0; color: instModalMouse.containsMouse ? SkinTheme.accentVioletHover : SkinTheme.accentViolet }
                            }

                            // Glow
                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width + 6
                                height: parent.height + 6
                                radius: parent.radius + 3
                                color: "transparent"
                                border.color: SkinTheme.accentCyan
                                border.width: 1
                                opacity: instModalMouse.containsMouse ? 0.3 : 0
                                Behavior on opacity { NumberAnimation { duration: SkinTheme.animFast } }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "⚡ INSTALL SKIN"
                                color: "#060810"
                                font.family: SkinTheme.fontMono
                                font.pixelSize: 12
                                font.bold: true
                                font.letterSpacing: 1.0
                            }

                            MouseArea {
                                id: instModalMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var payload = getSelectedModPayload()
                                    if (payload) {
                                        app.installMod(JSON.stringify(payload), payload.categoryId)
                                    }
                                }
                            }
                        }

                        // Add to Queue
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 36
                            radius: SkinTheme.radiusMedium
                            color: addQueueMouse.containsMouse ? SkinTheme.bgCardHover : "transparent"
                            border.color: SkinTheme.accentCyan
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "+ ADD TO QUEUE"
                                color: SkinTheme.accentCyan
                                font.family: SkinTheme.fontMono
                                font.pixelSize: 11
                                font.bold: true
                                font.letterSpacing: 0.8
                            }

                            MouseArea {
                                id: addQueueMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var payload = getSelectedModPayload()
                                    if (payload) {
                                        detailModal.addToCartRequested(payload)
                                    }
                                }
                            }
                        }

                        // Uninstall
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 36
                            radius: SkinTheme.radiusMedium
                            color: uninstMouse.containsMouse ? SkinTheme.accentCrimsonGlow : "transparent"
                            border.color: SkinTheme.accentCrimson
                            border.width: 1
                            visible: modData ? app.isModInstalled(modData.name, modData.categoryId) : false

                            Text {
                                anchors.centerIn: parent
                                text: "⊘ UNINSTALL"
                                color: SkinTheme.accentCrimson
                                font.family: SkinTheme.fontMono
                                font.pixelSize: 11
                                font.bold: true
                                font.letterSpacing: 0.8
                            }

                            MouseArea {
                                id: uninstMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (modData) {
                                        app.uninstallMod(modData.name, modData.categoryId)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
