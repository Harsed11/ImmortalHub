import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"

Rectangle {
    id: titleBar
    height: 44
    color: SkinTheme.bgDark
    z: 100

    property var rootWindow: null
    property int queueCount: 0
    signal queueClicked()
    signal presetsClicked()
    signal playDotaClicked()
    signal searchClicked()

    // Bottom border
    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: SkinTheme.borderSubtle
    }

    // Subtle top accent line
    Rectangle {
        anchors.top: parent.top
        width: parent.width
        height: 1
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.2; color: SkinTheme.accentCyan }
            GradientStop { position: 0.8; color: SkinTheme.accentCyan }
            GradientStop { position: 1.0; color: "transparent" }
        }
        opacity: 0.3
    }

    // Soft glow under accent line
    Rectangle {
        anchors.top: parent.top
        width: parent.width
        height: 8
        gradient: Gradient {
            GradientStop { position: 0.0; color: SkinTheme.accentCyanGlow }
            GradientStop { position: 1.0; color: "transparent" }
        }
        opacity: 0.5
    }

    // Drag area
    MouseArea {
        id: dragArea
        anchors.fill: parent
        property point clickPos: "0,0"
        onPressed: function(mouse) { clickPos = Qt.point(mouse.x, mouse.y) }
        onPositionChanged: function(mouse) {
            if (pressed && rootWindow) {
                var delta = Qt.point(mouse.x - clickPos.x, mouse.y - clickPos.y)
                rootWindow.x += delta.x
                rootWindow.y += delta.y
            }
        }
        onDoubleClicked: {
            if (rootWindow) {
                if (rootWindow.visibility === Window.Maximized) rootWindow.showNormal()
                else rootWindow.showMaximized()
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 0
        spacing: 0

        // ── Brand Logo ──
        RowLayout {
            spacing: 10

            AegisIcon {
                width: 22
                height: 22
            }

            Text {
                text: "IMMORTAL"
                color: SkinTheme.textPrimary
                font.family: SkinTheme.fontDisplay
                font.pixelSize: 14
                font.bold: true
                font.letterSpacing: 2.0
            }
            Text {
                text: "HUB"
                color: SkinTheme.accentCyan
                font.family: SkinTheme.fontDisplay
                font.pixelSize: 14
                font.bold: true
                font.letterSpacing: 2.0
            }

            // Version badge
            Rectangle {
                height: 18
                radius: SkinTheme.radiusSmall
                implicitWidth: verText.implicitWidth + 10
                color: SkinTheme.bgSurface
                border.color: SkinTheme.borderMuted
                border.width: 1

                Text {
                    id: verText
                    anchors.centerIn: parent
                    text: app ? app.appVersion : "v0.0"
                    color: SkinTheme.textMuted
                    font.family: SkinTheme.fontMono
                    font.pixelSize: 8
                    font.bold: true
                }
            }
        }

        Item { Layout.fillWidth: true }

        // ── Search Button (Ctrl+K) ──
        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            Layout.rightMargin: 8
            height: 30
            width: 200
            radius: SkinTheme.radiusMedium
            color: searchBtnMouse.containsMouse ? SkinTheme.bgCardHover : SkinTheme.bgInput
            border.color: searchBtnMouse.containsMouse ? SkinTheme.borderActive : SkinTheme.borderMuted
            border.width: 1

            Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }
            Behavior on border.color { ColorAnimation { duration: SkinTheme.animFast } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8

                Text {
                    text: "\uE721"
                    font.family: "Segoe MDL2 Assets"
                    font.pixelSize: 12
                    color: SkinTheme.textMuted
                }

                Text {
                    text: "Search..."
                    color: SkinTheme.textMuted
                    font.family: SkinTheme.fontFamily
                    font.pixelSize: SkinTheme.fontSizeSmall
                    Layout.fillWidth: true
                }

                Rectangle {
                    width: shortcutText.implicitWidth + 8
                    height: 18
                    radius: 4
                    color: SkinTheme.bgCard
                    border.color: SkinTheme.borderMuted
                    border.width: 1

                    Text {
                        id: shortcutText
                        anchors.centerIn: parent
                        text: "Ctrl K"
                        color: SkinTheme.textMuted
                        font.family: SkinTheme.fontMono
                        font.pixelSize: 8
                        font.bold: true
                    }
                }
            }

            MouseArea {
                id: searchBtnMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: titleBar.searchClicked()
            }
        }

        // ── Presets Button ──
        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            Layout.rightMargin: 8
            height: 30
            radius: SkinTheme.radiusMedium
            implicitWidth: presetsBtnRow.implicitWidth + 20
            color: presetsBtnMouse.containsMouse ? SkinTheme.bgCardHover : "transparent"
            border.color: presetsBtnMouse.containsMouse ? SkinTheme.borderActive : SkinTheme.borderMuted
            border.width: 1

            Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }
            Behavior on border.color { ColorAnimation { duration: SkinTheme.animFast } }

            RowLayout {
                id: presetsBtnRow
                anchors.centerIn: parent
                spacing: 6

                Text {
                    text: "\uE8F1"
                    font.family: "Segoe MDL2 Assets"
                    font.pixelSize: 11
                    color: presetsBtnMouse.containsMouse ? SkinTheme.textPrimary : SkinTheme.textSecondary
                    Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }
                }

                Text {
                    text: app.uiLanguage.length && app.t("tb.presets")
                    color: presetsBtnMouse.containsMouse ? SkinTheme.textPrimary : SkinTheme.textSecondary
                    font.family: SkinTheme.fontFamily
                    font.pixelSize: SkinTheme.fontSizeSmall
                    font.weight: Font.Medium
                    Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }
                }
            }

            MouseArea {
                id: presetsBtnMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: titleBar.presetsClicked()
            }
        }

        // ── Queue Button ──
        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            Layout.rightMargin: 8
            height: 30
            radius: SkinTheme.radiusMedium
            implicitWidth: queueBtnRow.implicitWidth + 20
            color: queueCount > 0
                   ? (queueBtnMouse.containsMouse ? SkinTheme.accentCyanHover : SkinTheme.accentCyan)
                   : (queueBtnMouse.containsMouse ? SkinTheme.bgCardHover : "transparent")
            border.color: queueCount > 0 ? "transparent" : (queueBtnMouse.containsMouse ? SkinTheme.borderActive : SkinTheme.borderMuted)
            border.width: 1

            Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

            RowLayout {
                id: queueBtnRow
                anchors.centerIn: parent
                spacing: 6

                Text {
                    text: "\uE896"
                    font.family: "Segoe MDL2 Assets"
                    font.pixelSize: 11
                    color: queueCount > 0 ? "#FFFFFF" : (queueBtnMouse.containsMouse ? SkinTheme.textPrimary : SkinTheme.textSecondary)
                }

                Text {
                    text: queueCount > 0 ? "QUEUE  " + queueCount : "QUEUE"
                    color: queueCount > 0 ? "#FFFFFF" : (queueBtnMouse.containsMouse ? SkinTheme.textPrimary : SkinTheme.textSecondary)
                    font.family: SkinTheme.fontFamily
                    font.pixelSize: SkinTheme.fontSizeSmall
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.5
                }
            }

            MouseArea {
                id: queueBtnMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: titleBar.queueClicked()
            }
        }

        // ── Play Dota 2 Button ──
        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            Layout.rightMargin: 12
            height: 30
            radius: SkinTheme.radiusMedium
            implicitWidth: playRow.implicitWidth + 20
            color: playDotaMouse.containsMouse ? SkinTheme.accentEmeraldHover : SkinTheme.accentEmerald

            Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

            RowLayout {
                id: playRow
                anchors.centerIn: parent
                spacing: 6

                Text {
                    text: "▶"
                    color: "#FFFFFF"
                    font.pixelSize: 10
                }

                Text {
                    text: "PLAY"
                    color: "#FFFFFF"
                    font.family: SkinTheme.fontFamily
                    font.pixelSize: SkinTheme.fontSizeSmall
                    font.weight: Font.Bold
                    font.letterSpacing: 1.0
                }
            }

            MouseArea {
                id: playDotaMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: titleBar.playDotaClicked()
            }
        }

        // ── Window Controls ──
        RowLayout {
            spacing: 0

            Repeater {
                model: [
                    { sym: "\uE921", action: "min" },
                    { sym: "\uE922", action: "max" },
                    { sym: "\uE8BB", action: "close" }
                ]

                delegate: Rectangle {
                    width: 44
                    height: 44
                    color: {
                        if (!wcMouse.containsMouse) return "transparent"
                        if (modelData.action === "close") return "#E23B3B"
                        return SkinTheme.bgCardHover
                    }

                    Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

                    Text {
                        anchors.centerIn: parent
                        text: modelData.action === "max" && rootWindow && rootWindow.visibility === Window.Maximized ? "\uE923" : modelData.sym
                        color: wcMouse.containsMouse ? "#FFFFFF" : SkinTheme.textMuted
                        font.family: "Segoe MDL2 Assets"
                        font.pixelSize: 10

                        Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }
                    }

                    MouseArea {
                        id: wcMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (modelData.action === "min") rootWindow.showMinimized()
                            else if (modelData.action === "max") {
                                if (rootWindow.visibility === Window.Maximized) rootWindow.showNormal()
                                else rootWindow.showMaximized()
                            }
                            else if (modelData.action === "close") rootWindow.close()
                        }
                    }
                }
            }
        }
    }
}
