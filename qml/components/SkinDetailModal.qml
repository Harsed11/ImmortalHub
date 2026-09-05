import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtMultimedia
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
    property bool isOpen: modData !== null
    property int selectedStyleIndex: 0
    property var customSpells: []
    property bool isAudioPlaying: Boolean(modData && getCurrentAudioUrl() !== "" && app.isPlayingAudio && app.currentAudioUrl === getCurrentAudioUrl())
    property bool isVideoMode: false
    property bool isVideoPlaying: false
    property bool isVideoMuted: true

    signal addToCartRequested(var mod)
    signal closeRequested()
    signal installRequested(var mod)
    signal uninstallRequested(var mod)

    onCloseRequested: isOpen = false

    Shortcut {
        enabled: isOpen
        sequence: "Escape"
        onActivated: detailModal.closeRequested()
    }

    onModDataChanged: {
        selectedStyleIndex = 0
        isVideoMode = false
        if (typeof videoPlayer !== "undefined" && videoPlayer.playbackState === MediaPlayer.PlayingState) {
            videoPlayer.stop()
        }
        loadCustomSpells()
    }

    onIsOpenChanged: {
        if (!isOpen) {
            isVideoMode = false
            if (typeof videoPlayer !== "undefined" && videoPlayer.playbackState === MediaPlayer.PlayingState) {
                videoPlayer.stop()
            }
        }
    }

    function getCurrentVideoUrl() {
        if (!modData) return ""
        return modData.videoUrl || ""
    }

    function formatAudioTime(ms) {
        if (!ms || isNaN(ms) || ms < 0) return "00:00"
        var totalSec = Math.floor(ms / 1000)
        var m = Math.floor(totalSec / 60)
        var s = totalSec % 60
        return (m < 10 ? "0" + m : m) + ":" + (s < 10 ? "0" + s : s)
    }

    function loadCustomSpells() {
        if (!modData) {
            customSpells = []
            return
        }
        if (typeof app !== "undefined" && app && app.getModSpellIcons) {
            try {
                var jsonStr = app.getModSpellIcons(modData.name || "", modData.hero || "")
                customSpells = JSON.parse(jsonStr)
            } catch(e) {
                customSpells = []
            }
        } else {
            customSpells = []
        }
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

                // Preview Frame (Image & Animation Video)
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 480
                    radius: SkinTheme.radiusLarge
                    color: SkinTheme.bgDark
                    border.color: isVideoMode ? SkinTheme.accentCyan : SkinTheme.borderMuted
                    border.width: 1
                    clip: true

                    // Video Player
                    MediaPlayer {
                        id: videoPlayer
                        source: (detailModal.isOpen && isVideoMode && getCurrentVideoUrl() !== "") ? getCurrentVideoUrl() : ""
                        videoOutput: videoOut
                        audioOutput: videoAudio
                        loops: MediaPlayer.Infinite
                        onPlaybackStateChanged: {
                            detailModal.isVideoPlaying = (playbackState === MediaPlayer.PlayingState)
                        }
                    }

                    AudioOutput {
                        id: videoAudio
                        muted: detailModal.isVideoMuted
                        volume: 0.7
                    }

                    VideoOutput {
                        id: videoOut
                        anchors.fill: parent
                        anchors.margins: 4
                        visible: isVideoMode && getCurrentVideoUrl() !== ""
                        fillMode: VideoOutput.PreserveAspectFit
                    }

                    // Static Image Preview
                    Image {
                        id: bigPreview
                        anchors.fill: parent
                        anchors.margins: 4
                        visible: !isVideoMode || !getCurrentVideoUrl()
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

                    // Media Mode Switcher (Top Right Bar)
                    RowLayout {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 10
                        spacing: 6
                        z: 10
                        visible: Boolean(getCurrentVideoUrl() !== "")

                        // Photo Tab
                        Rectangle {
                            height: 26
                            implicitWidth: photoText.implicitWidth + 16
                            radius: SkinTheme.radiusSmall
                            color: !isVideoMode ? SkinTheme.accentCyan : "#3006070B"
                            border.color: !isVideoMode ? SkinTheme.accentCyanHover : SkinTheme.borderMuted
                            border.width: 1

                            Text {
                                id: photoText
                                anchors.centerIn: parent
                                text: "🖼️ PHOTO"
                                color: !isVideoMode ? "#000000" : SkinTheme.textSecondary
                                font.family: SkinTheme.fontMono
                                font.pixelSize: 10
                                font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    detailModal.isVideoMode = false
                                    videoPlayer.pause()
                                }
                            }
                        }

                        // Animation Tab
                        Rectangle {
                            height: 26
                            implicitWidth: videoText.implicitWidth + 22
                            radius: SkinTheme.radiusSmall
                            color: isVideoMode ? SkinTheme.accentViolet : "#3006070B"
                            border.color: isVideoMode ? SkinTheme.accentVioletHover : SkinTheme.accentViolet
                            border.width: 1

                            RowLayout {
                                id: videoText
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    text: "🎬 ANIMATION"
                                    color: isVideoMode ? "#FFFFFF" : SkinTheme.accentViolet
                                    font.family: SkinTheme.fontMono
                                    font.pixelSize: 10
                                    font.bold: true
                                }

                                Rectangle {
                                    width: 6
                                    height: 6
                                    radius: 3
                                    color: isVideoMode ? "#00FF88" : SkinTheme.accentViolet
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    detailModal.isVideoMode = true
                                    videoPlayer.play()
                                }
                            }
                        }
                    }

                    // Video Controls Bar
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 36
                        color: "#DD06070B"
                        visible: isVideoMode && getCurrentVideoUrl() !== ""
                        z: 10

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 8

                            Rectangle {
                                width: 24
                                height: 24
                                radius: 12
                                color: SkinTheme.bgCardHover

                                Text {
                                    anchors.centerIn: parent
                                    text: detailModal.isVideoPlaying ? "⏸" : "▶"
                                    color: "#FFFFFF"
                                    font.pixelSize: 10
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (detailModal.isVideoPlaying) {
                                            videoPlayer.pause()
                                        } else {
                                            videoPlayer.play()
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                width: 24
                                height: 24
                                radius: 12
                                color: SkinTheme.bgCardHover

                                Text {
                                    anchors.centerIn: parent
                                    text: detailModal.isVideoMuted ? "🔇" : "🔊"
                                    color: "#FFFFFF"
                                    font.pixelSize: 10
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: detailModal.isVideoMuted = !detailModal.isVideoMuted
                                }
                            }

                            Text {
                                text: "HD ANIMATION LOOP"
                                color: SkinTheme.textMuted
                                font.family: SkinTheme.fontMono
                                font.pixelSize: 9
                                font.bold: true
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                height: 16
                                radius: 8
                                implicitWidth: 46
                                color: "#2500ff88"
                                border.color: "#00ff88"
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: "LOOP ↻"
                                    color: "#00ff88"
                                    font.family: SkinTheme.fontMono
                                    font.pixelSize: 8
                                    font.bold: true
                                }
                            }
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

                    // ═══════════════════════════════════════════
                    // INTERACTIVE AUDIO PLAYER (Announcers, Music, Voice)
                    // ═══════════════════════════════════════════
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 70
                        radius: SkinTheme.radiusMedium
                        color: isAudioPlaying ? SkinTheme.accentCyanGlow : SkinTheme.bgCard
                        border.color: isAudioPlaying ? SkinTheme.accentCyan : SkinTheme.borderMuted
                        border.width: 1
                        visible: Boolean(modData && getCurrentAudioUrl() !== "")
                        clip: true

                        Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }
                        Behavior on border.color { ColorAnimation { duration: SkinTheme.animFast } }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 6

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                // Play / Pause circular button
                                Rectangle {
                                    width: 32
                                    height: 32
                                    radius: 16
                                    color: isAudioPlaying ? SkinTheme.accentCyan : (playBtnMouse.containsMouse ? SkinTheme.accentCyanSoft : SkinTheme.bgElevated)
                                    border.color: SkinTheme.accentCyan
                                    border.width: 1
                                    scale: playBtnMouse.pressed ? 0.92 : 1.0

                                    Behavior on scale { NumberAnimation { duration: SkinTheme.animFast } }
                                    Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: isAudioPlaying ? "❚❚" : "▶"
                                        color: isAudioPlaying ? "#08080E" : SkinTheme.accentCyan
                                        font.pixelSize: 11
                                        font.bold: true
                                    }

                                    MouseArea {
                                        id: playBtnMouse
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

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1

                                    Text {
                                        text: isAudioPlaying ? "PLAYING AUDIO PREVIEW" : "AUDIO PREVIEW & CUES"
                                        color: isAudioPlaying ? SkinTheme.accentCyan : SkinTheme.textPrimary
                                        font.family: SkinTheme.fontMono
                                        font.pixelSize: 9
                                        font.bold: true
                                        font.letterSpacing: 0.5
                                    }

                                    Text {
                                        text: modData ? (modData.name + " (" + (modData.categoryId || "audio") + ")") : ""
                                        color: SkinTheme.textSecondary
                                        font.family: SkinTheme.fontFamily
                                        font.pixelSize: 10
                                        elide: Text.ElideRight
                                    }
                                }

                                // Waveform bars animation
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
                                                NumberAnimation { to: (index % 2 === 0 ? 16 : 8); duration: 180 + index * 40; easing.type: Easing.InOutQuad }
                                                NumberAnimation { to: (index % 2 === 0 ? 4 : 18); duration: 180 + index * 40; easing.type: Easing.InOutQuad }
                                            }
                                        }
                                    }
                                }

                                // Track Time Display
                                Text {
                                    text: formatAudioTime(app ? app.audioPosition : 0) + " / " + formatAudioTime(app ? app.audioDuration : 0)
                                    color: SkinTheme.textMuted
                                    font.family: SkinTheme.fontMono
                                    font.pixelSize: 9
                                }
                            }

                            // Interactive Progress Scrubber
                            Rectangle {
                                Layout.fillWidth: true
                                height: 6
                                radius: 3
                                color: SkinTheme.bgDark
                                clip: true

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    radius: 3
                                    color: SkinTheme.accentCyan
                                    width: (app && app.audioDuration > 0)
                                           ? Math.min(parent.width, Math.max(0, parent.width * (app.audioPosition / app.audioDuration)))
                                           : 0

                                    Behavior on width {
                                        enabled: !scrubMouse.pressed
                                        NumberAnimation { duration: 100 }
                                    }
                                }

                                MouseArea {
                                    id: scrubMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: function(mouse) {
                                        if (app && app.audioDuration > 0 && width > 0) {
                                            var pct = Math.max(0.0, Math.min(1.0, mouse.x / width))
                                            app.seekAudio(Math.floor(pct * app.audioDuration))
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ═══════════════════════════════════════════
                    // CUSTOM SPELL & ABILITY ICONS SHOWCASE
                    // ═══════════════════════════════════════════
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        visible: customSpells.length > 0

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "⚡ CUSTOM SPELL ICONS & ABILITY EFFECTS (" + customSpells.length + ")"
                                color: SkinTheme.accentCyan
                                font.family: SkinTheme.fontMono
                                font.pixelSize: SkinTheme.fontSizeTiny
                                font.bold: true
                                font.letterSpacing: 0.8
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: "Arcana / Immortal"
                                color: SkinTheme.textMuted
                                font.family: SkinTheme.fontMono
                                font.pixelSize: 8
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Repeater {
                                model: customSpells
                                delegate: Rectangle {
                                    width: 48
                                    height: 48
                                    radius: SkinTheme.radiusSmall
                                    color: SkinTheme.bgDark
                                    border.color: spellMouse.containsMouse ? SkinTheme.accentCyan : SkinTheme.borderMuted
                                    border.width: 1
                                    clip: true
                                    scale: spellMouse.containsMouse ? 1.08 : 1.0

                                    Behavior on scale { NumberAnimation { duration: SkinTheme.animFast; easing.type: Easing.OutCubic } }
                                    Behavior on border.color { ColorAnimation { duration: SkinTheme.animFast } }

                                    Image {
                                        anchors.fill: parent
                                        source: modelData.icon || ""
                                        fillMode: Image.PreserveAspectFit
                                        asynchronous: true
                                    }

                                    // Video indicator badge
                                    Rectangle {
                                        anchors.bottom: parent.bottom
                                        anchors.right: parent.right
                                        anchors.margins: 2
                                        width: 12
                                        height: 12
                                        radius: 6
                                        color: SkinTheme.accentCyan
                                        visible: Boolean(modelData.video)

                                        Text {
                                            anchors.centerIn: parent
                                            text: "▶"
                                            font.pixelSize: 7
                                            color: "#08080E"
                                        }
                                    }

                                    MouseArea {
                                        id: spellMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (modelData.video && typeof app !== "undefined" && app) {
                                                app.openUrl(modelData.video)
                                            }
                                        }
                                    }

                                    ToolTip.visible: spellMouse.containsMouse
                                    ToolTip.text: modelData.name + "\n" + modelData.description + (modelData.video ? "\n\n(Click to watch official video clip)" : "")
                                    ToolTip.delay: 200
                                }
                            }

                            Item { Layout.fillWidth: true }
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
