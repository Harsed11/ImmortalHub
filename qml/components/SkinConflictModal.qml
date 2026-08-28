import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"

Rectangle {
    id: conflictModal
    anchors.fill: parent
    color: SkinTheme.bgModalOverlay
    visible: isOpen
    opacity: isOpen ? 1 : 0
    z: 700

    Behavior on opacity { NumberAnimation { duration: SkinTheme.animFast } }

    property bool isOpen: false
    property var newMod: null
    property var conflictingMod: null

    signal replaceRequested(var oldMod, var newMod)
    signal keepBothRequested(var newMod)
    signal closeRequested()

    MouseArea {
        anchors.fill: parent
        onClicked: conflictModal.closeRequested()
    }

    Rectangle {
        anchors.centerIn: parent
        width: Math.min(520, parent.width - 40)
        height: Math.min(320, parent.height - 40)
        radius: SkinTheme.radiusLarge
        color: SkinTheme.bgModal
        border.color: SkinTheme.accentAmber
        border.width: 1
        clip: true

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        // Top Amber Line
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 3
            color: SkinTheme.accentAmber
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 16

            RowLayout {
                spacing: 12

                Text {
                    text: "⚠"
                    font.pixelSize: 24
                    color: SkinTheme.accentAmber
                }

                ColumnLayout {
                    spacing: 2
                    Text {
                        text: "SMART CONFLICT DETECTED"
                        color: SkinTheme.textPrimary
                        font.family: SkinTheme.fontDisplay
                        font.pixelSize: 16
                        font.bold: true
                        font.letterSpacing: 1.2
                    }

                    Text {
                        text: "Another skin is already installed for this hero slot."
                        color: SkinTheme.textSecondary
                        font.family: SkinTheme.fontFamily
                        font.pixelSize: 12
                    }
                }
            }

            // Conflict Card
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: SkinTheme.radiusMedium
                color: SkinTheme.bgCard
                border.color: SkinTheme.borderMuted
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 8

                    Text {
                        text: "Current Installed: <font color='" + SkinTheme.accentCrimson + "'>" + (conflictingMod ? conflictingMod.name : "") + "</font>"
                        textFormat: Text.RichText
                        color: SkinTheme.textPrimary
                        font.family: SkinTheme.fontFamily
                        font.pixelSize: 13
                    }

                    Text {
                        text: "New Selected: <font color='" + SkinTheme.accentCyan + "'>" + (newMod ? newMod.name : "") + "</font>"
                        textFormat: Text.RichText
                        color: SkinTheme.textPrimary
                        font.family: SkinTheme.fontFamily
                        font.pixelSize: 13
                    }

                    Text {
                        text: "Would you like to replace the old skin to avoid in-game visual model clipping?"
                        color: SkinTheme.textMuted
                        font.family: SkinTheme.fontFamily
                        font.pixelSize: 11
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }
            }

            // Action Buttons
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    radius: SkinTheme.radiusSmall
                    color: cancelMouse.containsMouse ? SkinTheme.bgCardHover : "transparent"
                    border.color: SkinTheme.borderMuted
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "CANCEL"
                        color: SkinTheme.textSecondary
                        font.family: SkinTheme.fontMono
                        font.pixelSize: 10
                        font.bold: true
                    }

                    MouseArea {
                        id: cancelMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: conflictModal.closeRequested()
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    radius: SkinTheme.radiusSmall
                    color: keepBothMouse.containsMouse ? SkinTheme.accentVioletHover : SkinTheme.accentViolet
                    border.color: "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "KEEP BOTH"
                        color: "#ffffff"
                        font.family: SkinTheme.fontMono
                        font.pixelSize: 10
                        font.bold: true
                    }

                    MouseArea {
                        id: keepBothMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            conflictModal.keepBothRequested(conflictModal.newMod)
                            conflictModal.closeRequested()
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    radius: SkinTheme.radiusSmall
                    color: replaceMouse.containsMouse ? SkinTheme.accentCyanHover : SkinTheme.accentCyan
                    border.color: "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "REPLACE OLD SKIN"
                        color: "#060810"
                        font.family: SkinTheme.fontMono
                        font.pixelSize: 10
                        font.bold: true
                    }

                    MouseArea {
                        id: replaceMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            conflictModal.replaceRequested(conflictModal.conflictingMod, conflictModal.newMod)
                            conflictModal.closeRequested()
                        }
                    }
                }
            }
        }
    }
}
