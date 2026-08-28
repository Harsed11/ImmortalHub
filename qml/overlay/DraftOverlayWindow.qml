import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"
import "../components"

Window {
    id: overlayWindow
    visible: app.overlayVisible
    width: Math.min(1380, Screen.width - 60)
    height: 420
    x: (Screen.width - width) / 2
    y: 20
    title: "ImmortalHub Overplus In-Game HUD"
    color: "transparent"
    flags: Qt.Window | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint

    property var matchData: null
    property var radiantPlayers: []
    property var direPlayers: []
    property real overlayOpacity: 0.96

    Component.onCompleted: loadMatchData()

    Connections {
        target: app
        function onLiveMatchChanged() { loadMatchData() }
        function onOverlayToggled(vis) {
            overlayWindow.visible = vis
            if (vis) loadMatchData()
        }
    }

    function loadMatchData() {
        var raw = app.getLiveMatchJson()
        try {
            var parsed = JSON.parse(raw)
            if (parsed && (parsed.radiant || parsed.dire)) {
                matchData = parsed
                radiantPlayers = parsed.radiant || []
                direPlayers = parsed.dire || []
            }
        } catch(e) {}
    }

    // Glassmorphism HUD Card
    Rectangle {
        id: hudCard
        anchors.fill: parent
        radius: 12
        color: "#080c14f2"
        border.color: "#302212"
        border.width: 1
        opacity: overlayWindow.overlayOpacity
        clip: true

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // Floating Header Bar (Draggable)
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 38
                color: "#0f1624"

                MouseArea {
                    anchors.fill: parent
                    property point clickPos: "0,0"
                    onPressed: function(mouse) { clickPos = Qt.point(mouse.x, mouse.y) }
                    onPositionChanged: function(mouse) {
                        if (pressed) {
                            overlayWindow.x += mouse.x - clickPos.x
                            overlayWindow.y += mouse.y - clickPos.y
                        }
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 10
                    spacing: 8

                    Text { text: "⚡"; font.pixelSize: 13 }
                    Text {
                        text: "OVERPLUS DRAFT INTEL"
                        color: SkinTheme.accentCyan
                        font.family: SkinTheme.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 1.0
                    }

                    Rectangle {
                        height: 18
                        radius: 4
                        implicitWidth: ovlModeBadge.implicitWidth + 8
                        color: "#16283b"
                        Text {
                            id: ovlModeBadge
                            anchors.centerIn: parent
                            text: matchData ? (matchData.gameMode || "All Pick") : "Drafting"
                            color: SkinTheme.accentCyan
                            font.pixelSize: 9
                            font.bold: true
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Rescan button
                    Rectangle {
                        height: 24
                        radius: 4
                        implicitWidth: rescanText.implicitWidth + 12
                        color: rescanMouse.containsMouse ? "#2a3c50" : "#1a2838"
                        border.color: SkinTheme.borderMuted
                        border.width: 1

                        Text {
                            id: rescanText
                            anchors.centerIn: parent
                            text: "⚡ Rescan"
                            color: SkinTheme.accentCyan
                            font.pixelSize: 9
                            font.bold: true
                        }

                        MouseArea {
                            id: rescanMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: app.scanDotaLogsNow()
                        }
                    }

                    // Opacity Slider
                    Text {
                        text: Math.round(overlayOpacity * 100) + "%"
                        color: SkinTheme.textMuted
                        font.pixelSize: 9
                    }

                    Slider {
                        implicitWidth: 70
                        from: 0.4
                        to: 1.0
                        value: overlayOpacity
                        onValueChanged: overlayOpacity = value
                    }

                    // Close Button
                    Rectangle {
                        width: 24
                        height: 24
                        radius: 12
                        color: closeMouse.containsMouse ? SkinTheme.accentCrimson : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "вњ•"
                            color: closeMouse.containsMouse ? "#ffffff" : SkinTheme.textSecondary
                            font.pixelSize: 11
                            font.bold: true
                        }

                        MouseArea {
                            id: closeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: app.setOverlayVisible(false)
                        }
                    }
                }
            }

            // Teams Matrix
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 8
                spacing: 8

                // Radiant Table
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 8
                    color: "#081017"
                    border.color: "#143024"
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 3

                        Text {
                            text: "◆ THE RADIANT"
                            color: SkinTheme.accentEmerald
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: 10
                            font.bold: true
                        }

                        Repeater {
                            model: radiantPlayers
                            delegate: Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 60
                                radius: 4
                                color: "#0c171e"
                                border.color: modelData.banRecommendation ? SkinTheme.accentCyan : "#14252e"
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 6
                                    anchors.rightMargin: 6
                                    spacing: 8

                                    // Avatar
                                    Rectangle {
                                        width: 42
                                        height: 42
                                        radius: 21
                                        color: "#121d26"
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
                                            font.pixelSize: 16
                                            visible: !modelData.avatar
                                        }
                                    }

                                    // Player details
                                    ColumnLayout {
                                        Layout.preferredWidth: 120
                                        spacing: 1

                                        Text {
                                            text: modelData.name || "Player"
                                            color: SkinTheme.textPrimary
                                            font.family: SkinTheme.fontFamily
                                            font.pixelSize: 11
                                            font.bold: true
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: (modelData.rank ? modelData.rank.badge : "Unranked") + (modelData.streak !== "-" ? (" • " + modelData.streak) : "")
                                            color: modelData.isOnFire ? SkinTheme.accentCyan : SkinTheme.accentCyan
                                            font.pixelSize: 8
                                            font.bold: true
                                        }

                                        Text {
                                            text: modelData.isPrivate ? "Private" : (modelData.winrate + "% WR (" + modelData.totalGames + ")")
                                            color: modelData.winrate >= 55.0 ? SkinTheme.accentEmerald : SkinTheme.textMuted
                                            font.pixelSize: 8
                                        }
                                    }

                                    // Signature Heroes (3 items)
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 3

                                        Repeater {
                                            model: modelData.signatureHeroes ? modelData.signatureHeroes.slice(0, 3) : []
                                            delegate: Rectangle {
                                                width: 60
                                                height: 48
                                                radius: 3
                                                color: "#060d13"
                                                border.color: modelData.isSpammer ? SkinTheme.accentCyan : "#162530"
                                                border.width: 1

                                                ColumnLayout {
                                                    anchors.fill: parent
                                                    anchors.margins: 2
                                                    spacing: 1

                                                    Image {
                                                        Layout.alignment: Qt.AlignHCenter
                                                        Layout.preferredWidth: 28
                                                        Layout.preferredHeight: 16
                                                        source: modelData.avatar || ""
                                                        fillMode: Image.PreserveAspectCrop
                                                    }

                                                    Text {
                                                        Layout.alignment: Qt.AlignHCenter
                                                        text: modelData.heroName
                                                        color: SkinTheme.textPrimary
                                                        font.pixelSize: 7
                                                        elide: Text.ElideRight
                                                        Layout.fillWidth: true
                                                        horizontalAlignment: Text.AlignHCenter
                                                    }

                                                    Text {
                                                        Layout.alignment: Qt.AlignHCenter
                                                        text: modelData.winrate + "%"
                                                        color: modelData.winrate >= 60.0 ? SkinTheme.accentEmerald : SkinTheme.accentCyan
                                                        font.pixelSize: 6
                                                        font.bold: true
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // Ban Warning
                                    Rectangle {
                                        Layout.preferredWidth: 50
                                        Layout.preferredHeight: 28
                                        radius: 3
                                        color: "#341214"
                                        border.color: SkinTheme.accentCrimson
                                        border.width: 1
                                        visible: Boolean(modelData.banRecommendation)

                                        Text {
                                            anchors.centerIn: parent
                                            text: "⚠ BAN"
                                            color: SkinTheme.accentCrimsonHover
                                            font.pixelSize: 7
                                            font.bold: true
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Dire Table
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 8
                    color: "#12070a"
                    border.color: "#36141a"
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 3

                        Text {
                            text: "◆ THE DIRE"
                            color: SkinTheme.accentCrimson
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: 10
                            font.bold: true
                        }

                        Repeater {
                            model: direPlayers
                            delegate: Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 60
                                radius: 4
                                color: "#1c0b0f"
                                border.color: modelData.banRecommendation ? SkinTheme.accentCyan : "#2d1217"
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 6
                                    anchors.rightMargin: 6
                                    spacing: 8

                                    // Avatar
                                    Rectangle {
                                        width: 42
                                        height: 42
                                        radius: 21
                                        color: "#220e13"
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
                                            font.pixelSize: 16
                                            visible: !modelData.avatar
                                        }
                                    }

                                    // Player details
                                    ColumnLayout {
                                        Layout.preferredWidth: 120
                                        spacing: 1

                                        Text {
                                            text: modelData.name || "Player"
                                            color: SkinTheme.textPrimary
                                            font.family: SkinTheme.fontFamily
                                            font.pixelSize: 11
                                            font.bold: true
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: (modelData.rank ? modelData.rank.badge : "Unranked") + (modelData.streak !== "-" ? (" • " + modelData.streak) : "")
                                            color: modelData.isOnFire ? SkinTheme.accentCyan : SkinTheme.accentCyan
                                            font.pixelSize: 8
                                            font.bold: true
                                        }

                                        Text {
                                            text: modelData.isPrivate ? "Private" : (modelData.winrate + "% WR (" + modelData.totalGames + ")")
                                            color: modelData.winrate >= 55.0 ? SkinTheme.accentEmerald : SkinTheme.textMuted
                                            font.pixelSize: 8
                                        }
                                    }

                                    // Signature Heroes (3 items)
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 3

                                        Repeater {
                                            model: modelData.signatureHeroes ? modelData.signatureHeroes.slice(0, 3) : []
                                            delegate: Rectangle {
                                                width: 60
                                                height: 48
                                                radius: 3
                                                color: "#0e0407"
                                                border.color: modelData.isSpammer ? SkinTheme.accentCyan : "#220c11"
                                                border.width: 1

                                                ColumnLayout {
                                                    anchors.fill: parent
                                                    anchors.margins: 2
                                                    spacing: 1

                                                    Image {
                                                        Layout.alignment: Qt.AlignHCenter
                                                        Layout.preferredWidth: 28
                                                        Layout.preferredHeight: 16
                                                        source: modelData.avatar || ""
                                                        fillMode: Image.PreserveAspectCrop
                                                    }

                                                    Text {
                                                        Layout.alignment: Qt.AlignHCenter
                                                        text: modelData.heroName
                                                        color: SkinTheme.textPrimary
                                                        font.pixelSize: 7
                                                        elide: Text.ElideRight
                                                        Layout.fillWidth: true
                                                        horizontalAlignment: Text.AlignHCenter
                                                    }

                                                    Text {
                                                        Layout.alignment: Qt.AlignHCenter
                                                        text: modelData.winrate + "%"
                                                        color: modelData.winrate >= 60.0 ? SkinTheme.accentEmerald : SkinTheme.accentCyan
                                                        font.pixelSize: 6
                                                        font.bold: true
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // Ban Warning
                                    Rectangle {
                                        Layout.preferredWidth: 50
                                        Layout.preferredHeight: 28
                                        radius: 3
                                        color: "#341214"
                                        border.color: SkinTheme.accentCrimson
                                        border.width: 1
                                        visible: Boolean(modelData.banRecommendation)

                                        Text {
                                            anchors.centerIn: parent
                                            text: "⚠ BAN"
                                            color: SkinTheme.accentCrimsonHover
                                            font.pixelSize: 7
                                            font.bold: true
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
}

