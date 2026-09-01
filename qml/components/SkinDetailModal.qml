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

    // Dismiss by clicking backdrop
    MouseArea {
        anchors.fill: parent
        onClicked: detailModal.closeRequested()
    }

    // Modal Card
    Rectangle {
        id: modalBox
        width: Math.min(880, parent.width - 48)
        height: Math.min(620, parent.height - 48)
        anchors.centerIn: parent
        radius: SkinTheme.radiusXLarge
        color: SkinTheme.bgModal
        border.color: SkinTheme.borderLight
        border.width: 1
        clip: true

        scale: detailModal.modData !== null ? 1.0 : 0.96
        Behavior on scale { NumberAnimation { duration: SkinTheme.animNormal; easing.type: Easing.OutBack } }

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // ── Modal Header ──
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 56
                color: SkinTheme.bgDark

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: SkinTheme.borderSubtle
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
                        font.pixelSize: SkinTheme.fontSizeHeader
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
                        color: closeMouse.containsMouse ? SkinTheme.accentCrimsonHover : "transparent"
                        border.color: closeMouse.containsMouse ? "transparent" : SkinTheme.borderMuted
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            color: closeMouse.containsMouse ? "#FFFFFF" : SkinTheme.textMuted
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

            // ── Modal Body: Image Preview + Details ──
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 20
                spacing: 20

                // Preview Image Frame
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
                            visible: bigPreview.status === Image.Error || !getCurrentPreviewUrl()
                        }
                    }
                }

                // Details Column
                ColumnLayout {
                    Layout.preferredWidth: 320
                    Layout.fillHeight: true
                    spacing: 12

                    // Information Tags
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            text: "MOD DETAILS"
                            color: SkinTheme.textMuted
                            font.family: SkinTheme.fontMono
                            font.pixelSize: SkinTheme.fontSizeTiny
                            font.bold: true
                            font.letterSpacing: 1.0
                        }

                        RowLayout {
                            spacing: 6

                            // Category Tag
                            Rectangle {
                                height: 24
                                radius: SkinTheme.radiusSmall
                                implicitWidth: catPillText.implicitWidth + 14
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

                            // Hero Tag
                            Rectangle {
                                height: 24
                                radius: SkinTheme.radiusSmall
                                implicitWidth: heroPillText.implicitWidth + 14
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

                    // Variants / Styles
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        visible: Boolean(modData && modData.styles && modData.styles.length > 0)

                        Text {
                            text: "SELECT VARIANT (" + (modData && modData.styles ? modData.styles.length : 0) + ")"
                            color: SkinTheme.textMuted
                            font.family: SkinTheme.fontMono
                            font.pixelSize: SkinTheme.fontSizeTiny
                            font.bold: true
                            font.letterSpacing: 1.0
                        }

                        Flow {
                            Layout.fillWidth: true
                            spacing: 6

                            Repeater {
                                model: modData && modData.styles ? modData.styles : []
                                delegate: Rectangle {
                                    height: 28
                                    radius: SkinTheme.radiusSmall
                                    implicitWidth: styleLabel.implicitWidth + 18
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
                                        color: selectedStyleIndex === index ? "#FFFFFF" : SkinTheme.textSecondary
                                        font.family: SkinTheme.fontFamily
                                        font.pixelSize: SkinTheme.fontSizeSmall
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

                    // File / Package info
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Text {
                            text: "PACKAGE FILE"
                            color: SkinTheme.textMuted
                            font.family: SkinTheme.fontMono
                            font.pixelSize: SkinTheme.fontSizeTiny
                            font.bold: true
                            font.letterSpacing: 1.0
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 28
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
                                color: SkinTheme.textSecondary
                                font.pixelSize: SkinTheme.fontSizeSmall
                                font.family: SkinTheme.fontMono
                                elide: Text.ElideMiddle
                            }
                        }
                    }

                    // Audio & Voice Line Preview
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
                            spacing: 10

                            Rectangle {
                                width: 28
                                height: 28
                                radius: SkinTheme.radiusSmall
                                color: isAudioPlaying ? SkinTheme.accentCyan : SkinTheme.bgElevated

                                Text {
                                    anchors.centerIn: parent
                                    text: isAudioPlaying ? "❚❚" : "▶"
                                    color: isAudioPlaying ? "#FFFFFF" : SkinTheme.accentCyan
                                    font.pixelSize: 10
                                    font.bold: true
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    text: isAudioPlaying ? "PLAYING AUDIO" : "AUDIO PREVIEW"
                                    color: isAudioPlaying ? SkinTheme.accentCyan : SkinTheme.textPrimary
                                    font.family: SkinTheme.fontMono
                                    font.pixelSize: 10
                                    font.bold: true
                                }

                                Text {
                                    text: isAudioPlaying ? "Click to stop" : "Voice lines & sounds"
                                    color: SkinTheme.textMuted
                                    font.family: SkinTheme.fontFamily
                                    font.pixelSize: 11
                                }
                            }

                            // Waveform bars animation
                            Row {
                                spacing: 3
                                Layout.alignment: Qt.AlignVCenter
                                visible: isAudioPlaying

                                Repeater {
                                    model: 5
                                    delegate: Rectangle {
                                        width: 3
                                        height: 6
                                        color: SkinTheme.accentCyan
                                        radius: 1

                                        SequentialAnimation on height {
                                            running: isAudioPlaying
                                            loops: Animation.Infinite
                                            NumberAnimation { to: (index % 2 === 0 ? 14 : 7); duration: 200 + index * 50; easing.type: Easing.InOutQuad }
                                            NumberAnimation { to: (index % 2 === 0 ? 5 : 16); duration: 200 + index * 50; easing.type: Easing.InOutQuad }
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

                    // Action Buttons (Install / Queue / Uninstall)
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        // Install Button
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 40
                            radius: SkinTheme.radiusMedium
                            color: instModalMouse.containsMouse ? SkinTheme.accentCyanHover : SkinTheme.accentCyan

                            Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

                            Text {
                                anchors.centerIn: parent
                                text: "⚡ INSTALL SKIN"
                                color: "#FFFFFF"
                                font.family: SkinTheme.fontFamily
                                font.pixelSize: SkinTheme.fontSizeBody
                                font.bold: true
                                font.letterSpacing: 0.5
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
                            Layout.preferredHeight: 34
                            radius: SkinTheme.radiusMedium
                            color: addQueueMouse.containsMouse ? SkinTheme.bgCardHover : "transparent"
                            border.color: SkinTheme.borderMuted
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "+ ADD TO QUEUE"
                                color: SkinTheme.textPrimary
                                font.family: SkinTheme.fontFamily
                                font.pixelSize: SkinTheme.fontSizeSmall
                                font.bold: true
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

                        // Uninstall Button (if installed)
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 34
                            radius: SkinTheme.radiusMedium
                            color: uninstMouse.containsMouse ? SkinTheme.accentCrimsonHover : SkinTheme.accentCrimson
                            visible: modData ? app.isModInstalled(modData.name, modData.categoryId) : false

                            Text {
                                anchors.centerIn: parent
                                text: "⊘ UNINSTALL"
                                color: "#FFFFFF"
                                font.family: SkinTheme.fontFamily
                                font.pixelSize: SkinTheme.fontSizeSmall
                                font.bold: true
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
