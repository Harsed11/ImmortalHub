import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"

Rectangle {
    id: titleBar
    height: 38
    color: SkinTheme.bgDark
    z: 100

    property var rootWindow: null
    property int queueCount: 0
    signal queueClicked()
    signal presetsClicked()
    signal playDotaClicked()

    // Bottom subtle border
    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: SkinTheme.borderMuted
    }

    // Top neon accent line — animated gradient sweep
    Rectangle {
        id: topNeonLine
        anchors.top: parent.top
        width: parent.width
        height: 1

        // Animated gradient sweep position
        property real sweepPos: 0.0

        NumberAnimation on sweepPos {
            from: 0.0; to: 1.0
            duration: 3000
            loops: Animation.Infinite
            easing.type: Easing.Linear
        }

        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: Math.max(0.01, topNeonLine.sweepPos - 0.15); color: "transparent" }
            GradientStop { position: topNeonLine.sweepPos; color: SkinTheme.accentCyan }
            GradientStop { position: Math.min(0.99, topNeonLine.sweepPos + 0.15); color: SkinTheme.accentViolet }
            GradientStop { position: Math.min(1.0, topNeonLine.sweepPos + 0.3); color: "transparent" }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    // Subtle glow under the neon line
    Rectangle {
        anchors.top: parent.top
        width: parent.width
        height: 6
        gradient: Gradient {
            GradientStop { position: 0.0; color: SkinTheme.accentCyanGlow }
            GradientStop { position: 1.0; color: "transparent" }
        }
        opacity: 0.3
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
        anchors.leftMargin: 14
        anchors.rightMargin: 0
        spacing: 10

        // Brand Logo & Title — Clean Minimal with Neon Glow
        RowLayout {
            spacing: 8

            AegisIcon {
                width: 20
                height: 20
            }

            Item {
                implicitWidth: titleText.implicitWidth
                implicitHeight: titleText.implicitHeight

                // Subtle Cyan Ambient Glow under Title Text
                Text {
                    anchors.centerIn: parent
                    text: titleText.text
                    textFormat: Text.RichText
                    font: titleText.font
                    color: SkinTheme.accentCyan
                    opacity: 0.4
                }

                Text {
                    id: titleText
                    anchors.centerIn: parent
                    text: "IMMORTAL<font color='" + SkinTheme.accentCyan + "'>HUB</font>"
                    textFormat: Text.RichText
                    color: SkinTheme.textPrimary
                    font.family: SkinTheme.fontDisplay
                    font.pixelSize: 12
                    font.bold: true
                    font.letterSpacing: 2.0
                }
            }

            Rectangle {
                height: 16
                radius: 3
                implicitWidth: alphaBadgeText.implicitWidth + 8
                color: SkinTheme.accentCyanGlow
                border.color: SkinTheme.accentCyan
                border.width: 1

                // Outer neon glow
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width + 4
                    height: parent.height + 4
                    radius: parent.radius + 1
                    color: "transparent"
                    border.color: SkinTheme.accentCyan
                    border.width: 1
                    opacity: 0.3
                }

                Text {
                    id: alphaBadgeText
                    anchors.centerIn: parent
                    text: "ALPHA"
                    color: SkinTheme.accentCyan
                    font.family: SkinTheme.fontMono
                    font.pixelSize: 8
                    font.bold: true
                    font.letterSpacing: 0.8
                }
            }
        }

        // Spacer
        Item { Layout.fillWidth: true }

        // Launch Dota 2 Button
        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            Layout.rightMargin: 6
            height: 24
            radius: SkinTheme.radiusSmall
            implicitWidth: playDotaLabel.implicitWidth + 20
            color: playDotaMouse.containsMouse ? SkinTheme.accentEmeraldHover : SkinTheme.accentEmerald
            border.color: "transparent"

            Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

            RowLayout {
                anchors.centerIn: parent
                spacing: 5

                Text {
                    id: playDotaLabel
                    text: "▶ PLAY DOTA 2"
                    color: "#060810"
                    font.family: SkinTheme.fontMono
                    font.pixelSize: 10
                    font.bold: true
                    font.letterSpacing: 0.8
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

        // Presets Button
        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            Layout.rightMargin: 6
            height: 24
            radius: SkinTheme.radiusSmall
            implicitWidth: presetsBtnLabel.implicitWidth + 20
            color: presetsBtnMouse.containsMouse ? SkinTheme.bgCardHover : "transparent"
            border.color: presetsBtnMouse.containsMouse ? SkinTheme.accentViolet : SkinTheme.borderMuted
            border.width: 1

            Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }
            Behavior on border.color { ColorAnimation { duration: SkinTheme.animFast } }

            RowLayout {
                anchors.centerIn: parent
                spacing: 5

                Text {
                    id: presetsBtnLabel
                    text: "🎭 PRESETS"
                    color: presetsBtnMouse.containsMouse ? SkinTheme.accentViolet : SkinTheme.textSecondary
                    font.family: SkinTheme.fontMono
                    font.pixelSize: 10
                    font.bold: true
                    font.letterSpacing: 0.8
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

        // Integrated TitleBar Queue Button
        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            Layout.rightMargin: 10
            height: 24
            radius: SkinTheme.radiusSmall
            implicitWidth: titleQueueLabel.implicitWidth + 20
            color: queueCount > 0
                   ? (queueBtnMouse.containsMouse ? SkinTheme.accentCyanHover : SkinTheme.accentCyan)
                   : (queueBtnMouse.containsMouse ? SkinTheme.bgCardHover : "transparent")
            border.color: queueCount > 0 ? "transparent" : (queueBtnMouse.containsMouse ? SkinTheme.accentCyan : SkinTheme.borderMuted)
            border.width: 1

            Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }
            Behavior on border.color { ColorAnimation { duration: SkinTheme.animFast } }

            // Glow when queue has items
            Rectangle {
                anchors.centerIn: parent
                width: parent.width + 4
                height: parent.height + 4
                radius: parent.radius + 2
                color: "transparent"
                border.color: SkinTheme.accentCyan
                border.width: 1
                opacity: queueCount > 0 ? 0.3 : 0
                Behavior on opacity { NumberAnimation { duration: SkinTheme.animFast } }
            }

            RowLayout {
                anchors.centerIn: parent
                spacing: 5

                Text {
                    id: titleQueueLabel
                    text: queueCount > 0 ? "⚡ QUEUE  " + queueCount : "⚡ QUEUE"
                    color: queueCount > 0 ? "#060810" : (queueBtnMouse.containsMouse ? SkinTheme.accentCyan : SkinTheme.textSecondary)
                    font.family: SkinTheme.fontMono
                    font.pixelSize: 10
                    font.bold: true
                    font.letterSpacing: 1.0
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

        // Window Control Buttons — Neon Hover
        RowLayout {
            spacing: 0

            Repeater {
                model: [
                    { sym: "\u2013", action: "min", label: "Minimize" },
                    { sym: "\u25A1", action: "max", label: "Maximize" },
                    { sym: "\u00D7", action: "close", label: "Close" }
                ]

                delegate: Rectangle {
                    width: 42
                    height: 38
                    color: {
                        if (!wcMouse.containsMouse) return "transparent"
                        if (modelData.action === "close") return SkinTheme.accentCrimson
                        return SkinTheme.bgCardHover
                    }

                    Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

                    // Neon glow on hover
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 2
                        color: {
                            if (modelData.action === "close") return SkinTheme.accentCrimson
                            return SkinTheme.accentCyan
                        }
                        opacity: wcMouse.containsMouse ? 0.6 : 0
                        Behavior on opacity { NumberAnimation { duration: SkinTheme.animFast } }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: modelData.action === "max" && rootWindow && rootWindow.visibility === Window.Maximized ? "\u25A0" : modelData.sym
                        color: {
                            if (wcMouse.containsMouse) return "#ffffff"
                            return SkinTheme.textMuted
                        }
                        font.family: SkinTheme.fontFamily
                        font.pixelSize: modelData.action === "close" ? 15 : 12
                        font.bold: modelData.action === "close"
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
