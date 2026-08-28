import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"
import "../components"

Item {
    id: liveMatchViewRoot
    anchors.fill: parent

    property var matchData: null
    property var radiantPlayers: []
    property var direPlayers: []
    property bool hasActiveMatch: matchData !== null && matchData.radiant && matchData.radiant.length > 0

    Component.onCompleted: loadMatchData()

    Connections {
        target: app
        function onLiveMatchChanged() { loadMatchData() }
    }

    function loadMatchData() {
        var raw = app.getLiveMatchJson()
        try {
            var parsed = JSON.parse(raw)
            if (parsed && (parsed.radiant || parsed.dire)) {
                matchData = parsed
                radiantPlayers = parsed.radiant || []
                direPlayers = parsed.dire || []
            } else {
                matchData = null
                radiantPlayers = []
                direPlayers = []
            }
        } catch(e) {
            matchData = null
            radiantPlayers = []
            direPlayers = []
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Top Control Bar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 70
            color: SkinTheme.bgHeader

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: SkinTheme.borderMuted
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                spacing: 14

                // Title & Status
                ColumnLayout {
                    spacing: 3
                    RowLayout {
                        spacing: 8
                        Text {
                            text: "🎯 OVERPLUS LIVE DRAFT TRACKER"
                            color: SkinTheme.textPrimary
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: SkinTheme.fontSizeTitle
                            font.bold: true
                            font.letterSpacing: 0.5
                        }

                        Rectangle {
                            height: 20
                            radius: 10
                            implicitWidth: statusText.implicitWidth + 16
                            color: hasActiveMatch ? "#0d2e1d" : "#26161b"
                            border.color: hasActiveMatch ? SkinTheme.accentEmerald : SkinTheme.accentCrimson
                            border.width: 1

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 5
                                Rectangle {
                                    width: 6
                                    height: 6
                                    radius: 3
                                    color: hasActiveMatch ? SkinTheme.accentEmerald : SkinTheme.accentCrimson
                                }
                                Text {
                                    id: statusText
                                    text: hasActiveMatch ? "LIVE MATCH TRACKING" : "WAITING FOR DOTA 2"
                                    color: hasActiveMatch ? SkinTheme.accentEmerald : SkinTheme.textMuted
                                    font.family: SkinTheme.fontFamily
                                    font.pixelSize: 9
                                    font.bold: true
                                }
                            }
                        }
                    }

                    Text {
                        text: hasActiveMatch
                              ? ("Match ID: " + (matchData.matchId || "Live") + " • Mode: " + (matchData.gameMode || "All Pick") + " • Real Dota 2 Player Intelligence")
                              : "Automatically parses connected players from Dota 2 game logs & GSI. Detects smurfs, winrates, and hero spammers."
                        color: SkinTheme.textMuted
                        font.family: SkinTheme.fontFamily
                        font.pixelSize: 11
                    }
                }

                Item { Layout.fillWidth: true }

                // Quick SteamID / Match Search Box
                Rectangle {
                    height: 36
                    Layout.preferredWidth: 260
                    radius: SkinTheme.radiusMedium
                    color: SkinTheme.bgCard
                    border.color: searchInput.activeFocus ? SkinTheme.accentCyan : SkinTheme.borderMuted
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 6
                        spacing: 6

                        Text { text: "⌕"; font.pixelSize: 11 }

                        TextInput {
                            id: searchInput
                            Layout.fillWidth: true
                            color: SkinTheme.textPrimary
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: 11
                            clip: true
                            selectByMouse: true
                            onAccepted: {
                                if (text.trim().length > 0) {
                                    app.loadMatchByAccountIds(text.trim())
                                }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "SteamID / Match ID / Link..."
                                color: SkinTheme.textMuted
                                font.family: SkinTheme.fontFamily
                                font.pixelSize: 11
                                visible: !searchInput.text && !searchInput.activeFocus
                            }
                        }

                        Rectangle {
                            width: 24
                            height: 24
                            radius: 4
                            color: searchBtnMouse.containsMouse ? SkinTheme.accentCyanHover : SkinTheme.bgDark
                            border.color: SkinTheme.borderMuted
                            border.width: 1
                            visible: searchInput.text.length > 0

                            Text {
                                anchors.centerIn: parent
                                text: "в†µ"
                                color: searchBtnMouse.containsMouse ? "#000000" : SkinTheme.textPrimary
                                font.pixelSize: 12
                                font.bold: true
                            }

                            MouseArea {
                                id: searchBtnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: app.loadMatchByAccountIds(searchInput.text.trim())
                            }
                        }
                    }
                }

                // Action Controls
                RowLayout {
                    spacing: 8

                    // Scan Dota Logs Button
                    Rectangle {
                        height: 36
                        radius: SkinTheme.radiusMedium
                        implicitWidth: scanBtnText.implicitWidth + 22
                        color: scanBtnMouse.containsMouse ? SkinTheme.bgCardHover : SkinTheme.bgCard
                        border.color: SkinTheme.accentCyan
                        border.width: 1

                        RowLayout {
                            id: scanBtnText
                            anchors.centerIn: parent
                            spacing: 6
                            Text { text: "⚡"; font.pixelSize: 11 }
                            Text {
                                text: "Scan Game Logs"
                                color: SkinTheme.accentCyan
                                font.family: SkinTheme.fontFamily
                                font.pixelSize: 11
                                font.bold: true
                            }
                        }

                        MouseArea {
                            id: scanBtnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: app.scanDotaLogsNow()
                        }
                    }

                    // Overlay HUD Toggle
                    Rectangle {
                        height: 36
                        radius: SkinTheme.radiusMedium
                        implicitWidth: ovlBtnText.implicitWidth + 22
                        color: app.overlayVisible ? "#122a3e" : (ovlBtnMouse.containsMouse ? SkinTheme.bgCardHover : SkinTheme.bgCard)
                        border.color: app.overlayVisible ? SkinTheme.accentCyan : SkinTheme.borderMuted
                        border.width: 1

                        RowLayout {
                            id: ovlBtnText
                            anchors.centerIn: parent
                            spacing: 6
                            Text { text: "◫"; font.pixelSize: 11 }
                            Text {
                                text: app.overlayVisible ? "Hide HUD (F2)" : "Show HUD (F2)"
                                color: app.overlayVisible ? SkinTheme.accentCyan : SkinTheme.textPrimary
                                font.family: SkinTheme.fontFamily
                                font.pixelSize: 11
                                font.bold: true
                            }
                        }

                        MouseArea {
                            id: ovlBtnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: app.toggleOverlay()
                        }
                    }

                    // Demo Match Button
                    Rectangle {
                        height: 36
                        radius: SkinTheme.radiusMedium
                        implicitWidth: demoBtnText.implicitWidth + 22
                        color: demoBtnMouse.containsMouse ? SkinTheme.accentCyanHover : SkinTheme.accentCyan

                        RowLayout {
                            id: demoBtnText
                            anchors.centerIn: parent
                            spacing: 6
                            Text { text: "в–¶"; font.pixelSize: 10 }
                            Text {
                                text: "Preview Demo"
                                color: "#000000"
                                font.family: SkinTheme.fontFamily
                                font.pixelSize: 11
                                font.bold: true
                            }
                        }

                        MouseArea {
                            id: demoBtnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: app.triggerDemoMatch()
                        }
                    }
                }
            }
        }

        // Teams Grid Area
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            visible: hasActiveMatch

            ScrollBar.vertical: ScrollBar {
                width: 8
                policy: ScrollBar.AsNeeded
                contentItem: Rectangle {
                    radius: 4
                    color: SkinTheme.accentCyan
                    opacity: 0.4
                }
            }

            ColumnLayout {
                width: parent.width
                spacing: 16
                Layout.margins: 16

                // Radiant Team Box
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: radCol.implicitHeight + 24
                    radius: SkinTheme.radiusLarge
                    color: "#0a131b"
                    border.color: "#16382b"
                    border.width: 1

                    ColumnLayout {
                        id: radCol
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        // Team Banner
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Rectangle {
                                width: 4
                                height: 18
                                radius: 2
                                color: SkinTheme.accentEmerald
                            }

                            Text {
                                text: "◆ THE RADIANT"
                                color: SkinTheme.accentEmerald
                                font.family: SkinTheme.fontFamily
                                font.pixelSize: 13
                                font.bold: true
                                font.letterSpacing: 1.0
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: radiantPlayers.length + " PLAYERS"
                                color: SkinTheme.textMuted
                                font.family: SkinTheme.fontFamily
                                font.pixelSize: 10
                                font.bold: true
                            }
                        }

                        // Radiant Player Rows
                        Repeater {
                            model: radiantPlayers
                            delegate: Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 76
                                radius: SkinTheme.radiusMedium
                                color: radRowMouse.containsMouse ? "#11222b" : "#0d1820"
                                border.color: modelData.banRecommendation ? SkinTheme.accentCyan : "#192c38"
                                border.width: 1

                                MouseArea {
                                    id: radRowMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 12

                                    // Avatar with rank border
                                    Rectangle {
                                        width: 52
                                        height: 52
                                        radius: 26
                                        color: "#162330"
                                        border.color: modelData.isOnFire ? SkinTheme.accentCyan : (modelData.isTilting ? SkinTheme.accentCyan : "#203444")
                                        border.width: modelData.isOnFire || modelData.isTilting ? 2 : 1
                                        clip: true

                                        Image {
                                            anchors.fill: parent
                                            source: modelData.avatar || ""
                                            fillMode: Image.PreserveAspectCrop
                                            asynchronous: true
                                            visible: Boolean(modelData.avatar)
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.isPrivate ? "🔒" : "👤"
                                            font.pixelSize: 20
                                            visible: !modelData.avatar
                                        }
                                    }

                                    // Player Info & Winrates
                                    ColumnLayout {
                                        Layout.preferredWidth: 160
                                        spacing: 2

                                        RowLayout {
                                            spacing: 6
                                            Text {
                                                text: modelData.name || "Player"
                                                color: SkinTheme.textPrimary
                                                font.family: SkinTheme.fontFamily
                                                font.pixelSize: 13
                                                font.bold: true
                                                elide: Text.ElideRight
                                                Layout.maximumWidth: 110
                                            }

                                            Text {
                                                text: modelData.streak !== "-" ? (modelData.isOnFire ? ("🔥" + modelData.streak) : ("❄" + modelData.streak)) : ""
                                                font.pixelSize: 10
                                                font.bold: true
                                                visible: modelData.streak !== "-"
                                            }
                                        }

                                        RowLayout {
                                            spacing: 4
                                            Rectangle {
                                                height: 16
                                                radius: 3
                                                implicitWidth: rankBadgeText.implicitWidth + 8
                                                color: "#17283c"
                                                Text {
                                                    id: rankBadgeText
                                                    anchors.centerIn: parent
                                                    text: modelData.rank ? modelData.rank.full : "Unranked"
                                                    color: SkinTheme.accentCyan
                                                    font.pixelSize: 8
                                                    font.bold: true
                                                }
                                            }

                                            Text {
                                                text: "ID: " + modelData.accountId
                                                color: SkinTheme.textMuted
                                                font.pixelSize: 9
                                            }
                                        }

                                        Text {
                                            text: modelData.isPrivate ? "Private Profile" : (modelData.winrate + "% WR • " + modelData.totalGames + " games")
                                            color: modelData.winrate >= 55.0 ? SkinTheme.accentEmerald : SkinTheme.textSecondary
                                            font.pixelSize: 10
                                            font.bold: modelData.winrate >= 55.0
                                        }
                                    }

                                    // Signature Heroes (3 chips)
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        Repeater {
                                            model: modelData.signatureHeroes ? modelData.signatureHeroes.slice(0, 4) : []

                                            delegate: Rectangle {
                                                width: 86
                                                height: 56
                                                radius: SkinTheme.radiusSmall
                                                color: "#081017"
                                                border.color: modelData.isSpammer ? SkinTheme.accentCyan : "#182a38"
                                                border.width: 1

                                                ColumnLayout {
                                                    anchors.fill: parent
                                                    anchors.margins: 3
                                                    spacing: 1

                                                    Image {
                                                        Layout.alignment: Qt.AlignHCenter
                                                        Layout.preferredWidth: 36
                                                        Layout.preferredHeight: 20
                                                        source: modelData.avatar || ""
                                                        fillMode: Image.PreserveAspectCrop
                                                    }

                                                    Text {
                                                        Layout.alignment: Qt.AlignHCenter
                                                        text: modelData.heroName
                                                        color: SkinTheme.textPrimary
                                                        font.pixelSize: 8
                                                        elide: Text.ElideRight
                                                        Layout.fillWidth: true
                                                        horizontalAlignment: Text.AlignHCenter
                                                    }

                                                    Text {
                                                        Layout.alignment: Qt.AlignHCenter
                                                        text: modelData.winrate + "% (" + modelData.games + ")"
                                                        color: modelData.winrate >= 60.0 ? SkinTheme.accentEmerald : (modelData.winrate >= 52.0 ? SkinTheme.accentCyan : SkinTheme.textMuted)
                                                        font.pixelSize: 7
                                                        font.bold: true
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // Ban Recommendation Alert
                                    Rectangle {
                                        Layout.preferredWidth: 90
                                        Layout.preferredHeight: 34
                                        radius: 4
                                        color: "#341315"
                                        border.color: SkinTheme.accentCrimson
                                        border.width: 1
                                        visible: Boolean(modelData.banRecommendation)

                                        ColumnLayout {
                                            anchors.centerIn: parent
                                            spacing: 0
                                            Text {
                                                Layout.alignment: Qt.AlignHCenter
                                                text: "⚠ BAN THIS"
                                                color: SkinTheme.accentCrimsonHover
                                                font.pixelSize: 8
                                                font.bold: true
                                            }
                                            Text {
                                                Layout.alignment: Qt.AlignHCenter
                                                text: modelData.banRecommendation ? modelData.banRecommendation.heroName : ""
                                                color: "#ffffff"
                                                font.pixelSize: 8
                                                font.bold: true
                                                elide: Text.ElideRight
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Dire Team Box
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: dirCol.implicitHeight + 24
                    radius: SkinTheme.radiusLarge
                    color: "#180a0e"
                    border.color: "#3a151b"
                    border.width: 1

                    ColumnLayout {
                        id: dirCol
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        // Team Banner
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Rectangle {
                                width: 4
                                height: 18
                                radius: 2
                                color: SkinTheme.accentCrimson
                            }

                            Text {
                                text: "◆ THE DIRE"
                                color: SkinTheme.accentCrimson
                                font.family: SkinTheme.fontFamily
                                font.pixelSize: 13
                                font.bold: true
                                font.letterSpacing: 1.0
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: direPlayers.length + " PLAYERS"
                                color: SkinTheme.textMuted
                                font.family: SkinTheme.fontFamily
                                font.pixelSize: 10
                                font.bold: true
                            }
                        }

                        // Dire Player Rows
                        Repeater {
                            model: direPlayers
                            delegate: Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 76
                                radius: SkinTheme.radiusMedium
                                color: dirRowMouse.containsMouse ? "#261217" : "#1a0d11"
                                border.color: modelData.banRecommendation ? SkinTheme.accentCyan : "#32151c"
                                border.width: 1

                                MouseArea {
                                    id: dirRowMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 12

                                    // Avatar with rank border
                                    Rectangle {
                                        width: 52
                                        height: 52
                                        radius: 26
                                        color: "#281218"
                                        border.color: modelData.isOnFire ? SkinTheme.accentCyan : (modelData.isTilting ? SkinTheme.accentCyan : "#3c1822")
                                        border.width: modelData.isOnFire || modelData.isTilting ? 2 : 1
                                        clip: true

                                        Image {
                                            anchors.fill: parent
                                            source: modelData.avatar || ""
                                            fillMode: Image.PreserveAspectCrop
                                            asynchronous: true
                                            visible: Boolean(modelData.avatar)
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.isPrivate ? "🔒" : "👤"
                                            font.pixelSize: 20
                                            visible: !modelData.avatar
                                        }
                                    }

                                    // Player Info & Winrates
                                    ColumnLayout {
                                        Layout.preferredWidth: 160
                                        spacing: 2

                                        RowLayout {
                                            spacing: 6
                                            Text {
                                                text: modelData.name || "Player"
                                                color: SkinTheme.textPrimary
                                                font.family: SkinTheme.fontFamily
                                                font.pixelSize: 13
                                                font.bold: true
                                                elide: Text.ElideRight
                                                Layout.maximumWidth: 110
                                            }

                                            Text {
                                                text: modelData.streak !== "-" ? (modelData.isOnFire ? ("🔥" + modelData.streak) : ("❄" + modelData.streak)) : ""
                                                font.pixelSize: 10
                                                font.bold: true
                                                visible: modelData.streak !== "-"
                                            }
                                        }

                                        RowLayout {
                                            spacing: 4
                                            Rectangle {
                                                height: 16
                                                radius: 3
                                                implicitWidth: dRankBadgeText.implicitWidth + 8
                                                color: "#321620"
                                                Text {
                                                    id: dRankBadgeText
                                                    anchors.centerIn: parent
                                                    text: modelData.rank ? modelData.rank.full : "Unranked"
                                                    color: SkinTheme.accentCyan
                                                    font.pixelSize: 8
                                                    font.bold: true
                                                }
                                            }

                                            Text {
                                                text: "ID: " + modelData.accountId
                                                color: SkinTheme.textMuted
                                                font.pixelSize: 9
                                            }
                                        }

                                        Text {
                                            text: modelData.isPrivate ? "Private Profile" : (modelData.winrate + "% WR • " + modelData.totalGames + " games")
                                            color: modelData.winrate >= 55.0 ? SkinTheme.accentEmerald : SkinTheme.textSecondary
                                            font.pixelSize: 10
                                            font.bold: modelData.winrate >= 55.0
                                        }
                                    }

                                    // Signature Heroes (3 chips)
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        Repeater {
                                            model: modelData.signatureHeroes ? modelData.signatureHeroes.slice(0, 4) : []

                                            delegate: Rectangle {
                                                width: 86
                                                height: 56
                                                radius: SkinTheme.radiusSmall
                                                color: "#120609"
                                                border.color: modelData.isSpammer ? SkinTheme.accentCyan : "#2a1016"
                                                border.width: 1

                                                ColumnLayout {
                                                    anchors.fill: parent
                                                    anchors.margins: 3
                                                    spacing: 1

                                                    Image {
                                                        Layout.alignment: Qt.AlignHCenter
                                                        Layout.preferredWidth: 36
                                                        Layout.preferredHeight: 20
                                                        source: modelData.avatar || ""
                                                        fillMode: Image.PreserveAspectCrop
                                                    }

                                                    Text {
                                                        Layout.alignment: Qt.AlignHCenter
                                                        text: modelData.heroName
                                                        color: SkinTheme.textPrimary
                                                        font.pixelSize: 8
                                                        elide: Text.ElideRight
                                                        Layout.fillWidth: true
                                                        horizontalAlignment: Text.AlignHCenter
                                                    }

                                                    Text {
                                                        Layout.alignment: Qt.AlignHCenter
                                                        text: modelData.winrate + "% (" + modelData.games + ")"
                                                        color: modelData.winrate >= 60.0 ? SkinTheme.accentEmerald : (modelData.winrate >= 52.0 ? SkinTheme.accentCyan : SkinTheme.textMuted)
                                                        font.pixelSize: 7
                                                        font.bold: true
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // Ban Recommendation Alert
                                    Rectangle {
                                        Layout.preferredWidth: 90
                                        Layout.preferredHeight: 34
                                        radius: 4
                                        color: "#341315"
                                        border.color: SkinTheme.accentCrimson
                                        border.width: 1
                                        visible: Boolean(modelData.banRecommendation)

                                        ColumnLayout {
                                            anchors.centerIn: parent
                                            spacing: 0
                                            Text {
                                                Layout.alignment: Qt.AlignHCenter
                                                text: "⚠ BAN THIS"
                                                color: SkinTheme.accentCrimsonHover
                                                font.pixelSize: 8
                                                font.bold: true
                                            }
                                            Text {
                                                Layout.alignment: Qt.AlignHCenter
                                                text: modelData.banRecommendation ? modelData.banRecommendation.heroName : ""
                                                color: "#ffffff"
                                                font.pixelSize: 8
                                                font.bold: true
                                                elide: Text.ElideRight
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

        // Waiting / Empty State
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !hasActiveMatch

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 16

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 72
                    height: 72
                    radius: 36
                    color: "#121b28"
                    border.color: SkinTheme.accentCyan
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "🎯"
                        font.pixelSize: 32
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Ready for Live Dota 2 Match"
                    color: SkinTheme.textPrimary
                    font.family: SkinTheme.fontFamily
                    font.pixelSize: 18
                    font.bold: true
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Launch Dota 2 with '-condebug' in Steam launch options for instant real-time lobby detection, " +
                          "or click 'Scan Game Logs' when you enter hero pick phase."
                    color: SkinTheme.textMuted
                    font.family: SkinTheme.fontFamily
                    font.pixelSize: 13
                    horizontalAlignment: Text.AlignHCenter
                    Layout.preferredWidth: 480
                    wrapMode: Text.Wrap
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 12

                    Rectangle {
                        height: 38
                        radius: SkinTheme.radiusMedium
                        implicitWidth: scanLgText.implicitWidth + 24
                        color: scanLgMouse.containsMouse ? SkinTheme.accentCyanHover : SkinTheme.accentCyan

                        RowLayout {
                            id: scanLgText
                            anchors.centerIn: parent
                            spacing: 6
                            Text { text: "⚡"; font.pixelSize: 12 }
                            Text {
                                text: "Scan Game Logs Now"
                                color: "#000000"
                                font.family: SkinTheme.fontFamily
                                font.pixelSize: 11
                                font.bold: true
                            }
                        }

                        MouseArea {
                            id: scanLgMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: app.scanDotaLogsNow()
                        }
                    }

                    Rectangle {
                        height: 38
                        radius: SkinTheme.radiusMedium
                        implicitWidth: prevDemoText.implicitWidth + 24
                        color: prevDemoMouse.containsMouse ? SkinTheme.bgCardHover : SkinTheme.bgCard
                        border.color: SkinTheme.borderMuted
                        border.width: 1

                        RowLayout {
                            id: prevDemoText
                            anchors.centerIn: parent
                            spacing: 6
                            Text { text: "в–¶"; font.pixelSize: 10 }
                            Text {
                                text: "Load Sample Demo"
                                color: SkinTheme.textPrimary
                                font.family: SkinTheme.fontFamily
                                font.pixelSize: 11
                                font.bold: true
                            }
                        }

                        MouseArea {
                            id: prevDemoMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: app.triggerDemoMatch()
                        }
                    }
                }
            }
        }
    }
}

