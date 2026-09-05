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
    property bool showShareModal: false
    property bool showImportModal: false
    property bool showCloudModal: false
    property string currentShareCode: ""
    property bool shareCodeCopied: false
    property string importInputCode: ""
    property var importPreviewData: null
    property string importErrorMsg: ""
    property var integrityReport: null
    property bool isCheckingHealth: false
    property bool isRepairingHealth: false
    property string cloudBackupCode: ""
    property bool cloudBackupCopied: false
    property string cloudRestoreInput: ""
    property string cloudStatusMsg: ""
    property bool cloudIsBusy: false

    Shortcut {
        enabled: showConfirmUninstallAll || showShareModal || showImportModal || showCloudModal
        sequence: "Escape"
        onActivated: {
            showConfirmUninstallAll = false
            showShareModal = false
            showImportModal = false
            showCloudModal = false
        }
    }

    Component.onCompleted: {
        loadInstalled()
        if (typeof app !== "undefined" && app && typeof app.checkModsIntegrity === "function") {
            app.checkModsIntegrity()
        }
    }

    onVisibleChanged: {
        if (visible) {
            if (typeof app !== "undefined" && app) {
                app.validateInstalledMods()
                if (typeof app.checkModsIntegrity === "function") {
                    app.checkModsIntegrity()
                }
            }
            loadInstalled()
        }
    }

    Connections {
        target: app
        function onInstalledModsChanged() {
            loadInstalled()
            if (typeof app !== "undefined" && app && typeof app.checkModsIntegrity === "function") {
                app.checkModsIntegrity()
            }
        }
        function onIntegrityStatusChanged(report) {
            integrityReport = report
            isCheckingHealth = false
            isRepairingHealth = false
        }
        function onCloudBackupFinished(success, message, code) {
            cloudIsBusy = false
            cloudStatusMsg = message
            if (success && code) {
                cloudBackupCode = code
                cloudBackupCopied = false
            }
            if (success) {
                loadInstalled()
            }
        }
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

                // Health Check Button
                Rectangle {
                    height: 32
                    radius: SkinTheme.radiusMedium
                    implicitWidth: healthBtnText.implicitWidth + 20
                    color: {
                        if (isCheckingHealth || isRepairingHealth) return SkinTheme.bgCardHover
                        if (integrityReport && (!integrityReport.healthy || (integrityReport.corruptedCount && integrityReport.corruptedCount > 0))) {
                            return healthBtnM.containsMouse ? SkinTheme.accentCrimsonHover : SkinTheme.accentCrimsonGlow
                        }
                        return healthBtnM.containsMouse ? SkinTheme.accentEmeraldGlow : "transparent"
                    }
                    border.color: {
                        if (integrityReport && (!integrityReport.healthy || (integrityReport.corruptedCount && integrityReport.corruptedCount > 0))) {
                            return SkinTheme.accentCrimson
                        }
                        return SkinTheme.accentEmerald
                    }
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

                    RowLayout {
                        id: healthBtnText
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            text: (integrityReport && (!integrityReport.healthy || (integrityReport.corruptedCount && integrityReport.corruptedCount > 0))) ? "⚠️" : "🛡️"
                            font.pixelSize: 11
                        }
                        Text {
                            text: isCheckingHealth ? "SCANNING..." : (isRepairingHealth ? "REPAIRING..." : "INTEGRITY")
                            color: (integrityReport && (!integrityReport.healthy || (integrityReport.corruptedCount && integrityReport.corruptedCount > 0))) ? SkinTheme.accentCrimson : SkinTheme.accentEmerald
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: SkinTheme.fontSizeSmall
                            font.bold: true
                            font.letterSpacing: 0.5
                        }
                        Rectangle {
                            visible: integrityReport && integrityReport.corruptedCount > 0
                            width: 16
                            height: 16
                            radius: 8
                            color: SkinTheme.accentCrimson
                            Text {
                                anchors.centerIn: parent
                                text: integrityReport ? integrityReport.corruptedCount : "0"
                                color: "#FFFFFF"
                                font.family: SkinTheme.fontMono
                                font.pixelSize: 8
                                font.bold: true
                            }
                        }
                    }

                    MouseArea {
                        id: healthBtnM
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (typeof app !== "undefined" && app && typeof app.checkModsIntegrity === "function") {
                                isCheckingHealth = true
                                app.checkModsIntegrity()
                            }
                        }
                    }
                }

                // Cloud Sync Button
                Rectangle {
                    height: 32
                    radius: SkinTheme.radiusMedium
                    implicitWidth: cloudBtnText.implicitWidth + 20
                    color: cloudBtnM.containsMouse ? SkinTheme.accentCyanGlow : "transparent"
                    border.color: SkinTheme.accentCyan
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

                    RowLayout {
                        id: cloudBtnText
                        anchors.centerIn: parent
                        spacing: 6
                        Text { text: "☁️"; font.pixelSize: 11 }
                        Text {
                            text: "CLOUD SYNC"
                            color: SkinTheme.accentCyan
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: SkinTheme.fontSizeSmall
                            font.bold: true
                            font.letterSpacing: 0.5
                        }
                    }

                    MouseArea {
                        id: cloudBtnM
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            cloudStatusMsg = ""
                            cloudRestoreInput = ""
                            showCloudModal = true
                        }
                    }
                }

                // Share Loadout Code Button
                Rectangle {
                    visible: installedList.length > 0
                    height: 32
                    radius: SkinTheme.radiusMedium
                    implicitWidth: shareBtnText.implicitWidth + 18
                    color: shareBtnMouse.containsMouse ? SkinTheme.accentVioletGlow : "transparent"
                    border.color: SkinTheme.accentViolet
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

                    RowLayout {
                        id: shareBtnText
                        anchors.centerIn: parent
                        spacing: 5
                        Text { text: "📤"; font.pixelSize: 10 }
                        Text {
                            text: "SHARE"
                            color: SkinTheme.accentViolet
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: SkinTheme.fontSizeSmall
                            font.bold: true
                            font.letterSpacing: 0.5
                        }
                    }

                    MouseArea {
                        id: shareBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (typeof app !== "undefined" && app) {
                                var code = app.exportCurrentLoadoutCode()
                                if (code) {
                                    currentShareCode = code
                                    shareCodeCopied = true
                                    showShareModal = true
                                }
                            }
                        }
                    }
                }

                // Import Loadout Code Button
                Rectangle {
                    height: 32
                    radius: SkinTheme.radiusMedium
                    implicitWidth: importBtnText.implicitWidth + 18
                    color: importBtnMouse.containsMouse ? SkinTheme.accentCyanGlow : "transparent"
                    border.color: SkinTheme.accentCyan
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

                    RowLayout {
                        id: importBtnText
                        anchors.centerIn: parent
                        spacing: 5
                        Text { text: "📥"; font.pixelSize: 10 }
                        Text {
                            text: "IMPORT"
                            color: SkinTheme.accentCyan
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: SkinTheme.fontSizeSmall
                            font.bold: true
                            font.letterSpacing: 0.5
                        }
                    }

                    MouseArea {
                        id: importBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            importInputCode = ""
                            importPreviewData = null
                            importErrorMsg = ""
                            showImportModal = true
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
                                if (typeof app.syncAllMods === "function") {
                                    app.syncAllMods()
                                } else if (typeof app.syncAllInstalled === "function") {
                                    app.syncAllInstalled()
                                }
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
        // INTEGRITY ALERT BANNER (IF CORRUPTED MODS OR BROKEN GAMEINFO)
        // ═══════════════════════════════════════════
        Rectangle {
            id: integrityAlertBanner
            Layout.fillWidth: true
            visible: integrityReport !== null && (!integrityReport.healthy || (integrityReport.corruptedCount && integrityReport.corruptedCount > 0))
            Layout.preferredHeight: visible ? 56 : 0
            color: SkinTheme.accentCrimsonGlow
            border.color: SkinTheme.accentCrimson
            border.width: 1
            clip: true

            Behavior on Layout.preferredHeight { NumberAnimation { duration: SkinTheme.animFast } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: SkinTheme.spacingLG
                anchors.rightMargin: SkinTheme.spacingLG
                spacing: 12

                Text {
                    text: "⚠️"
                    font.pixelSize: 20
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    RowLayout {
                        spacing: 8
                        Text {
                            text: "MOD INTEGRITY ALERT"
                            color: SkinTheme.accentCrimson
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: SkinTheme.fontSizeBody
                            font.bold: true
                        }
                        Rectangle {
                            height: 16
                            radius: SkinTheme.radiusPill
                            implicitWidth: bannerBadgeText.implicitWidth + 10
                            color: SkinTheme.accentCrimson
                            Text {
                                id: bannerBadgeText
                                anchors.centerIn: parent
                                text: (integrityReport ? integrityReport.corruptedCount : 0) + " DAMAGED"
                                color: "#FFFFFF"
                                font.family: SkinTheme.fontMono
                                font.pixelSize: 7
                                font.bold: true
                            }
                        }
                    }

                    Text {
                        text: integrityReport ? (integrityReport.statusMessage || "Dota 2 update or missing VPK files detected.") : ""
                        color: SkinTheme.textSecondary
                        font.family: SkinTheme.fontFamily
                        font.pixelSize: SkinTheme.fontSizeSmall
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }

                // Repair All Button
                Rectangle {
                    height: 32
                    radius: SkinTheme.radiusSmall
                    implicitWidth: repairBtnRow.implicitWidth + 20
                    color: repairBannerM.containsMouse ? SkinTheme.accentEmeraldHover : SkinTheme.accentEmerald
                    border.color: SkinTheme.accentEmeraldDark
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

                    RowLayout {
                        id: repairBtnRow
                        anchors.centerIn: parent
                        spacing: 6
                        Text { text: "⚡"; font.pixelSize: 11; color: "#FFFFFF" }
                        Text {
                            text: isRepairingHealth ? "REPAIRING..." : "1-CLICK AUTO-REPAIR"
                            color: "#FFFFFF"
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: SkinTheme.fontSizeSmall
                            font.bold: true
                        }
                    }

                    MouseArea {
                        id: repairBannerM
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: !isRepairingHealth
                        onClicked: {
                            if (typeof app !== "undefined" && app && typeof app.repairModsIntegrity === "function") {
                                isRepairingHealth = true
                                app.repairModsIntegrity()
                            }
                        }
                    }
                }

                // Close / Dismiss Alert Button
                Rectangle {
                    width: 26
                    height: 26
                    radius: SkinTheme.radiusSmall
                    color: dismissBannerM.containsMouse ? SkinTheme.bgCardHover : "transparent"
                    border.color: SkinTheme.borderMuted
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        color: SkinTheme.textMuted
                        font.pixelSize: 9
                    }

                    MouseArea {
                        id: dismissBannerM
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: integrityReport = null
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
                        color: modelData.isCorrupted ? SkinTheme.accentCrimsonGlow : SkinTheme.accentEmeraldGlow
                        border.color: modelData.isCorrupted ? SkinTheme.accentCrimson : SkinTheme.accentEmerald
                        border.width: 1

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 4
                            Rectangle { width: 5; height: 5; radius: 2.5; color: modelData.isCorrupted ? SkinTheme.accentCrimson : SkinTheme.accentEmerald }
                            Text {
                                text: modelData.isCorrupted ? "MISSING" : "ACTIVE"
                                color: modelData.isCorrupted ? SkinTheme.accentCrimson : SkinTheme.accentEmerald
                                font.family: SkinTheme.fontMono
                                font.pixelSize: 7
                                font.bold: true
                            }
                        }
                    }

                    // Col 6: Uninstall / Repair Button (100px)
                    RowLayout {
                        Layout.preferredWidth: 100
                        spacing: 4

                        Rectangle {
                            visible: !!modelData.isCorrupted
                            Layout.preferredWidth: 46
                            Layout.preferredHeight: 28
                            radius: SkinTheme.radiusSmall
                            color: itemRepairMouse.containsMouse ? SkinTheme.accentEmeraldHover : SkinTheme.accentEmerald
                            border.color: SkinTheme.accentEmeraldDark
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "FIX"
                                color: "#FFFFFF"
                                font.family: SkinTheme.fontMono
                                font.pixelSize: 8
                                font.bold: true
                            }

                            MouseArea {
                                id: itemRepairMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (typeof app !== "undefined" && app) {
                                        app.repairModsIntegrity()
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: modelData.isCorrupted ? 50 : 96
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
                                    text: modelData.isCorrupted ? "DEL" : "UNINSTALL"
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

        MouseArea {
            anchors.fill: parent
            onClicked: showConfirmUninstallAll = false
        }

        Rectangle {
            anchors.centerIn: parent
            width: Math.min(460, parent.width - 40)
            height: 230
            radius: SkinTheme.radiusLarge
            color: SkinTheme.bgModal
            border.color: SkinTheme.accentCrimson
            border.width: 1

            MouseArea {
                anchors.fill: parent
                // absorb clicks inside
            }

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
                                    if (typeof app.uninstallAllMods === "function") {
                                        app.uninstallAllMods()
                                    } else if (typeof app.uninstallAll === "function") {
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

    // ═══════════════════════════════════════════
    // SHARE LOADOUT MODAL
    // ═══════════════════════════════════════════
    Rectangle {
        anchors.fill: parent
        color: SkinTheme.bgModalOverlay
        visible: showShareModal
        z: 1000

        MouseArea {
            anchors.fill: parent
            onClicked: showShareModal = false
        }

        Rectangle {
            anchors.centerIn: parent
            width: Math.min(520, parent.width - 40)
            height: 310
            radius: SkinTheme.radiusLarge
            color: SkinTheme.bgModal
            border.color: SkinTheme.accentViolet
            border.width: 1

            MouseArea {
                anchors.fill: parent
                // absorb clicks inside
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 14

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: "📤"
                        font.pixelSize: 20
                    }

                    ColumnLayout {
                        spacing: 2
                        Text {
                            text: "SHARE ACTIVE LOADOUT"
                            color: SkinTheme.textPrimary
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: SkinTheme.fontSizeTitle
                            font.bold: true
                            font.letterSpacing: 0.5
                        }
                        Text {
                            text: installedList.length + " mods equipped in this build"
                            color: SkinTheme.accentViolet
                            font.family: SkinTheme.fontMono
                            font.pixelSize: SkinTheme.fontSizeSmall
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: 28
                        height: 28
                        radius: 14
                        color: closeShareM.containsMouse ? SkinTheme.bgCardHover : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            color: SkinTheme.textMuted
                            font.pixelSize: 12
                        }
                        MouseArea {
                            id: closeShareM
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: showShareModal = false
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: "Copy this code to share your equipped cosmetic collection. Anyone can paste this code into ImmortalHub to replicate your loadout instantly."
                    color: SkinTheme.textSecondary
                    font.family: SkinTheme.fontFamily
                    font.pixelSize: SkinTheme.fontSizeBody
                    wrapMode: Text.WordWrap
                }

                // Share Code Display Box
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    radius: SkinTheme.radiusMedium
                    color: SkinTheme.bgInput
                    border.color: SkinTheme.borderLight
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 8

                        TextInput {
                            id: shareCodeTextDisplay
                            Layout.fillWidth: true
                            text: currentShareCode
                            readOnly: true
                            selectByMouse: true
                            color: SkinTheme.accentVioletHover
                            font.family: SkinTheme.fontMono
                            font.pixelSize: 11
                            clip: true
                        }

                        Rectangle {
                            width: copyShareCodeBtnText.implicitWidth + 16
                            height: 32
                            radius: SkinTheme.radiusSmall
                            color: shareCodeCopied ? SkinTheme.accentEmerald : (copyCodeM.containsMouse ? SkinTheme.accentVioletHover : SkinTheme.accentViolet)

                            RowLayout {
                                id: copyShareCodeBtnText
                                anchors.centerIn: parent
                                spacing: 4
                                Text {
                                    text: shareCodeCopied ? "✓" : "📋"
                                    color: "#FFFFFF"
                                    font.pixelSize: 11
                                }
                                Text {
                                    text: shareCodeCopied ? "COPIED" : "COPY"
                                    color: "#FFFFFF"
                                    font.family: SkinTheme.fontFamily
                                    font.pixelSize: SkinTheme.fontSizeSmall
                                    font.bold: true
                                }
                            }

                            MouseArea {
                                id: copyCodeM
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (typeof app !== "undefined" && app) {
                                        app.copyToClipboard(currentShareCode)
                                        shareCodeCopied = true
                                    }
                                }
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 38
                    radius: SkinTheme.radiusMedium
                    color: closeShareBtnM.containsMouse ? SkinTheme.bgCardHover : SkinTheme.bgCard
                    border.color: SkinTheme.borderMuted
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "DONE"
                        color: SkinTheme.textPrimary
                        font.family: SkinTheme.fontFamily
                        font.pixelSize: SkinTheme.fontSizeBody
                        font.bold: true
                    }

                    MouseArea {
                        id: closeShareBtnM
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: showShareModal = false
                    }
                }
            }
        }
    }

    // ═══════════════════════════════════════════
    // IMPORT LOADOUT MODAL
    // ═══════════════════════════════════════════
    Rectangle {
        anchors.fill: parent
        color: SkinTheme.bgModalOverlay
        visible: showImportModal
        z: 1000

        MouseArea {
            anchors.fill: parent
            onClicked: showImportModal = false
        }

        Rectangle {
            anchors.centerIn: parent
            width: Math.min(560, parent.width - 40)
            height: importPreviewData ? 420 : 280
            radius: SkinTheme.radiusLarge
            color: SkinTheme.bgModal
            border.color: SkinTheme.accentCyan
            border.width: 1

            Behavior on height { NumberAnimation { duration: SkinTheme.animNormal } }

            MouseArea {
                anchors.fill: parent
                // absorb clicks inside
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: "📥"
                        font.pixelSize: 20
                    }

                    ColumnLayout {
                        spacing: 2
                        Text {
                            text: "IMPORT LOADOUT CODE"
                            color: SkinTheme.textPrimary
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: SkinTheme.fontSizeTitle
                            font.bold: true
                            font.letterSpacing: 0.5
                        }
                        Text {
                            text: "Equip skins from community share codes"
                            color: SkinTheme.accentCyan
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: SkinTheme.fontSizeSmall
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: 28
                        height: 28
                        radius: 14
                        color: closeImportM.containsMouse ? SkinTheme.bgCardHover : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            color: SkinTheme.textMuted
                            font.pixelSize: 12
                        }
                        MouseArea {
                            id: closeImportM
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: showImportModal = false
                        }
                    }
                }

                // Input Box for Code
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    radius: SkinTheme.radiusMedium
                    color: SkinTheme.bgInput
                    border.color: importCodeInput.activeFocus ? SkinTheme.accentCyan : SkinTheme.borderMuted
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 6
                        spacing: 8

                        TextInput {
                            id: importCodeInput
                            Layout.fillWidth: true
                            color: SkinTheme.textPrimary
                            font.family: SkinTheme.fontMono
                            font.pixelSize: 12
                            clip: true
                            selectByMouse: true
                            text: importInputCode

                            onTextChanged: {
                                importInputCode = text
                                importErrorMsg = ""
                            }

                            Text {
                                text: "Paste IHUB-... code here"
                                color: SkinTheme.textMuted
                                font.family: SkinTheme.fontFamily
                                font.pixelSize: SkinTheme.fontSizeBody
                                visible: !importCodeInput.text && !importCodeInput.activeFocus
                            }
                        }

                        Rectangle {
                            height: 32
                            radius: SkinTheme.radiusSmall
                            implicitWidth: previewBtnText.implicitWidth + 14
                            color: previewBtnM.containsMouse ? SkinTheme.accentCyanHover : SkinTheme.accentCyan
                            visible: importInputCode.trim().length > 0

                            RowLayout {
                                id: previewBtnText
                                anchors.centerIn: parent
                                spacing: 4
                                Text { text: "🔍"; font.pixelSize: 10 }
                                Text {
                                    text: "INSPECT"
                                    color: "#FFFFFF"
                                    font.family: SkinTheme.fontFamily
                                    font.pixelSize: SkinTheme.fontSizeSmall
                                    font.bold: true
                                }
                            }

                            MouseArea {
                                id: previewBtnM
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (typeof app !== "undefined" && app) {
                                        var cleanCode = importInputCode.trim()
                                        var raw = app.previewShareCode(cleanCode)
                                        if (raw) {
                                            try {
                                                importPreviewData = JSON.parse(raw)
                                                importErrorMsg = ""
                                            } catch (e) {
                                                importErrorMsg = "Failed to parse share code data."
                                            }
                                        } else {
                                            importPreviewData = null
                                            importErrorMsg = "Invalid IHUB code. Please check format."
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Error Message if any
                Text {
                    visible: importErrorMsg !== ""
                    text: "⚠️ " + importErrorMsg
                    color: SkinTheme.accentCrimson
                    font.family: SkinTheme.fontFamily
                    font.pixelSize: SkinTheme.fontSizeSmall
                }

                // Preview Info Box if code is parsed
                Rectangle {
                    visible: importPreviewData !== null
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: SkinTheme.radiusMedium
                    color: SkinTheme.bgCard
                    border.color: SkinTheme.borderSubtle
                    border.width: 1
                    clip: true

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                text: importPreviewData ? (importPreviewData.name || "Custom Loadout") : ""
                                color: SkinTheme.textPrimary
                                font.family: SkinTheme.fontFamily
                                font.pixelSize: SkinTheme.fontSizeBody
                                font.bold: true
                            }

                            Rectangle {
                                height: 18
                                radius: SkinTheme.radiusPill
                                implicitWidth: previewCountBadge.implicitWidth + 10
                                color: SkinTheme.accentCyanGlow
                                border.color: SkinTheme.accentCyan
                                border.width: 1

                                Text {
                                    id: previewCountBadge
                                    anchors.centerIn: parent
                                    text: (importPreviewData && importPreviewData.items ? importPreviewData.items.length : 0) + " ITEMS"
                                    color: SkinTheme.accentCyan
                                    font.family: SkinTheme.fontMono
                                    font.pixelSize: 8
                                    font.bold: true
                                }
                            }
                        }

                        ListView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            model: importPreviewData && importPreviewData.items ? importPreviewData.items : []
                            spacing: 4

                            delegate: Rectangle {
                                width: ListView.view.width
                                height: 26
                                radius: SkinTheme.radiusSmall
                                color: SkinTheme.bgDark

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    spacing: 8

                                    Text {
                                        text: (modelData.hero ? modelData.hero.toUpperCase() + " : " : "") + (modelData.name || "Mod")
                                        color: SkinTheme.textSecondary
                                        font.family: SkinTheme.fontFamily
                                        font.pixelSize: SkinTheme.fontSizeSmall
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: modelData.categoryId ? modelData.categoryId.toUpperCase() : ""
                                        color: SkinTheme.textMuted
                                        font.family: SkinTheme.fontMono
                                        font.pixelSize: 8
                                    }
                                }
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true; visible: !importPreviewData }

                // Action Buttons
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 38
                        radius: SkinTheme.radiusMedium
                        color: cancelImportM.containsMouse ? SkinTheme.bgCardHover : SkinTheme.bgCard
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
                            id: cancelImportM
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: showImportModal = false
                        }
                    }

                    Rectangle {
                        visible: importPreviewData !== null
                        Layout.fillWidth: true
                        Layout.preferredHeight: 38
                        radius: SkinTheme.radiusMedium
                        color: applyImportM.containsMouse ? SkinTheme.accentCyanHover : SkinTheme.accentCyan

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            Text { text: "⚡"; font.pixelSize: 12; color: "#FFFFFF" }
                            Text {
                                text: "EQUIP & INSTALL ALL"
                                color: "#FFFFFF"
                                font.family: SkinTheme.fontFamily
                                font.pixelSize: SkinTheme.fontSizeBody
                                font.bold: true
                            }
                        }

                        MouseArea {
                            id: applyImportM
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (typeof app !== "undefined" && app) {
                                    var ok = app.applyShareCode(importInputCode.trim())
                                    if (ok) {
                                        showImportModal = false
                                        loadInstalled()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ═══════════════════════════════════════════
    // CLOUD SYNC & BACKUP MODAL
    // ═══════════════════════════════════════════
    Rectangle {
        anchors.fill: parent
        color: SkinTheme.bgModalOverlay
        visible: showCloudModal
        z: 1000

        MouseArea {
            anchors.fill: parent
            onClicked: showCloudModal = false
        }

        Rectangle {
            anchors.centerIn: parent
            width: Math.min(580, parent.width - 40)
            height: 480
            radius: SkinTheme.radiusLarge
            color: SkinTheme.bgModal
            border.color: SkinTheme.accentCyan
            border.width: 1

            MouseArea {
                anchors.fill: parent
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 14

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text { text: "☁️"; font.pixelSize: 22 }

                    ColumnLayout {
                        spacing: 2
                        Text {
                            text: "CLOUD BACKUP & PROFILE SYNC"
                            color: SkinTheme.textPrimary
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: SkinTheme.fontSizeTitle
                            font.bold: true
                            font.letterSpacing: 0.5
                        }
                        Text {
                            text: "Sync presets, equipped skins & favorites across multiple PCs or files"
                            color: SkinTheme.textSecondary
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: SkinTheme.fontSizeSmall
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: 28
                        height: 28
                        radius: SkinTheme.radiusSmall
                        color: closeCloudXMouse.containsMouse ? SkinTheme.accentCrimson : SkinTheme.bgCard
                        border.color: SkinTheme.borderMuted
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            color: closeCloudXMouse.containsMouse ? "#FFFFFF" : SkinTheme.textMuted
                            font.pixelSize: 10
                            font.bold: true
                        }

                        MouseArea {
                            id: closeCloudXMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: showCloudModal = false
                        }
                    }
                }

                // Section 1: Online Cloud Sync (Bytebin)
                Rectangle {
                    Layout.fillWidth: true
                    height: 160
                    radius: SkinTheme.radiusMedium
                    color: SkinTheme.bgCard
                    border.color: SkinTheme.borderMuted
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "🌐 INSTANT CLOUD SYNC"
                                color: SkinTheme.accentCyan
                                font.family: SkinTheme.fontMono
                                font.pixelSize: 9
                                font.bold: true
                                font.letterSpacing: 1.0
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: cloudIsBusy ? "CONNECTING..." : ""
                                color: SkinTheme.accentEmerald
                                font.family: SkinTheme.fontMono
                                font.pixelSize: 8
                            }
                        }

                        // Backup creation action
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Rectangle {
                                height: 32
                                radius: SkinTheme.radiusSmall
                                implicitWidth: genCloudBtnRow.implicitWidth + 18
                                color: genCloudBtnM.containsMouse ? SkinTheme.accentCyanHover : SkinTheme.accentCyan
                                enabled: !cloudIsBusy

                                RowLayout {
                                    id: genCloudBtnRow
                                    anchors.centerIn: parent
                                    spacing: 6
                                    Text { text: "☁️"; font.pixelSize: 10; color: "#FFFFFF" }
                                    Text {
                                        text: "GENERATE CLOUD CODE"
                                        color: "#FFFFFF"
                                        font.family: SkinTheme.fontFamily
                                        font.pixelSize: SkinTheme.fontSizeSmall
                                        font.bold: true
                                    }
                                }

                                MouseArea {
                                    id: genCloudBtnM
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (typeof app !== "undefined" && app) {
                                            cloudIsBusy = true
                                            cloudStatusMsg = "Uploading snapshot to cloud..."
                                            app.createCloudBackup()
                                        }
                                    }
                                }
                            }

                            // Resulting code display
                            Rectangle {
                                Layout.fillWidth: true
                                height: 32
                                radius: SkinTheme.radiusSmall
                                color: SkinTheme.bgInput
                                border.color: cloudBackupCode ? SkinTheme.accentCyan : SkinTheme.borderMuted
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 4
                                    spacing: 4

                                    Text {
                                        Layout.fillWidth: true
                                        text: cloudBackupCode ? cloudBackupCode : "No cloud code generated yet"
                                        color: cloudBackupCode ? SkinTheme.accentCyan : SkinTheme.textMuted
                                        font.family: SkinTheme.fontMono
                                        font.pixelSize: SkinTheme.fontSizeSmall
                                        font.bold: cloudBackupCode !== ""
                                        elide: Text.ElideRight
                                    }

                                    Rectangle {
                                        visible: cloudBackupCode !== ""
                                        height: 24
                                        radius: SkinTheme.radiusSmall
                                        implicitWidth: copyCloudText.implicitWidth + 12
                                        color: copyCloudM.containsMouse ? SkinTheme.accentCyanHover : SkinTheme.bgCardHover
                                        border.color: SkinTheme.borderMuted
                                        border.width: 1

                                        Text {
                                            id: copyCloudText
                                            anchors.centerIn: parent
                                            text: cloudBackupCopied ? "COPIED!" : "COPY"
                                            color: cloudBackupCopied ? SkinTheme.accentEmerald : SkinTheme.textPrimary
                                            font.family: SkinTheme.fontMono
                                            font.pixelSize: 8
                                            font.bold: true
                                        }

                                        MouseArea {
                                            id: copyCloudM
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (typeof app !== "undefined" && app && cloudBackupCode) {
                                                    app.copyToClipboard(cloudBackupCode)
                                                    cloudBackupCopied = true
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Restore from code action
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Rectangle {
                                Layout.fillWidth: true
                                height: 32
                                radius: SkinTheme.radiusSmall
                                color: SkinTheme.bgInput
                                border.color: restoreCloudInput.activeFocus ? SkinTheme.accentCyan : SkinTheme.borderMuted
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8

                                    TextInput {
                                        id: restoreCloudInput
                                        Layout.fillWidth: true
                                        color: SkinTheme.textPrimary
                                        font.family: SkinTheme.fontMono
                                        font.pixelSize: SkinTheme.fontSizeSmall
                                        clip: true
                                        selectByMouse: true
                                        text: cloudRestoreInput

                                        onTextChanged: cloudRestoreInput = text

                                        Text {
                                            text: "Enter IHUB-CLOUD-... code to restore"
                                            color: SkinTheme.textMuted
                                            font.family: SkinTheme.fontFamily
                                            font.pixelSize: SkinTheme.fontSizeSmall
                                            visible: !restoreCloudInput.text && !restoreCloudInput.activeFocus
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                height: 32
                                radius: SkinTheme.radiusSmall
                                implicitWidth: restoreCloudBtnRow.implicitWidth + 18
                                color: restoreCloudBtnM.containsMouse ? SkinTheme.accentCyanHover : SkinTheme.bgCard
                                border.color: SkinTheme.accentCyan
                                border.width: 1
                                enabled: !cloudIsBusy && cloudRestoreInput.trim() !== ""

                                RowLayout {
                                    id: restoreCloudBtnRow
                                    anchors.centerIn: parent
                                    spacing: 6
                                    Text { text: "📥"; font.pixelSize: 10 }
                                    Text {
                                        text: "RESTORE"
                                        color: SkinTheme.accentCyan
                                        font.family: SkinTheme.fontFamily
                                        font.pixelSize: SkinTheme.fontSizeSmall
                                        font.bold: true
                                    }
                                }

                                MouseArea {
                                    id: restoreCloudBtnM
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (typeof app !== "undefined" && app && cloudRestoreInput.trim() !== "") {
                                            cloudIsBusy = true
                                            cloudStatusMsg = "Restoring cloud snapshot..."
                                            app.restoreCloudBackup(cloudRestoreInput.trim())
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Section 2: Offline File Backup (.ihub_backup)
                Rectangle {
                    Layout.fillWidth: true
                    height: 105
                    radius: SkinTheme.radiusMedium
                    color: SkinTheme.bgCard
                    border.color: SkinTheme.borderMuted
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        Text {
                            text: "💾 OFFLINE LOCAL ARCHIVE (.IHUB_BACKUP)"
                            color: SkinTheme.accentViolet
                            font.family: SkinTheme.fontMono
                            font.pixelSize: 9
                            font.bold: true
                            font.letterSpacing: 1.0
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            Rectangle {
                                Layout.fillWidth: true
                                height: 34
                                radius: SkinTheme.radiusSmall
                                color: exportFileM.containsMouse ? SkinTheme.accentVioletGlow : SkinTheme.bgCardHover
                                border.color: SkinTheme.accentViolet
                                border.width: 1

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 6
                                    Text { text: "💾"; font.pixelSize: 11 }
                                    Text {
                                        text: "EXPORT TO FILE"
                                        color: SkinTheme.accentViolet
                                        font.family: SkinTheme.fontFamily
                                        font.pixelSize: SkinTheme.fontSizeSmall
                                        font.bold: true
                                    }
                                }

                                MouseArea {
                                    id: exportFileM
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (typeof app !== "undefined" && app) {
                                            app.exportBackupToFile("")
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 34
                                radius: SkinTheme.radiusSmall
                                color: importFileM.containsMouse ? SkinTheme.accentCyanGlow : SkinTheme.bgCardHover
                                border.color: SkinTheme.accentCyan
                                border.width: 1

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 6
                                    Text { text: "📂"; font.pixelSize: 11 }
                                    Text {
                                        text: "IMPORT FROM FILE"
                                        color: SkinTheme.accentCyan
                                        font.family: SkinTheme.fontFamily
                                        font.pixelSize: SkinTheme.fontSizeSmall
                                        font.bold: true
                                    }
                                }

                                MouseArea {
                                    id: importFileM
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (typeof app !== "undefined" && app) {
                                            var ok = app.importBackupFromFile("")
                                            if (ok) {
                                                loadInstalled()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Status message display
                Text {
                    visible: cloudStatusMsg !== ""
                    text: (cloudStatusMsg.indexOf("Error") !== -1 || cloudStatusMsg.indexOf("Failed") !== -1 || cloudStatusMsg.indexOf("Invalid") !== -1)
                          ? "⚠️ " + cloudStatusMsg
                          : "✅ " + cloudStatusMsg
                    color: (cloudStatusMsg.indexOf("Error") !== -1 || cloudStatusMsg.indexOf("Failed") !== -1 || cloudStatusMsg.indexOf("Invalid") !== -1)
                           ? SkinTheme.accentCrimson
                           : SkinTheme.accentEmerald
                    font.family: SkinTheme.fontFamily
                    font.pixelSize: SkinTheme.fontSizeSmall
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }

                Item { Layout.fillHeight: true }

                // Close Button
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 38
                    radius: SkinTheme.radiusMedium
                    color: closeCloudBtnM.containsMouse ? SkinTheme.bgCardHover : SkinTheme.bgCard
                    border.color: SkinTheme.borderMuted
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "CLOSE"
                        color: SkinTheme.textPrimary
                        font.family: SkinTheme.fontFamily
                        font.pixelSize: SkinTheme.fontSizeBody
                        font.bold: true
                    }

                    MouseArea {
                        id: closeCloudBtnM
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: showCloudModal = false
                    }
                }
            }
        }
    }

    // Floating Quick Scroll Controls
    FastScrollButtons {
        id: installedScrollButtons
        target: installedListView
    }
}
