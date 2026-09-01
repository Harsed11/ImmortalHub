import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"

// Premium toast notification system — slides in from top-right,
// supports multiple concurrent toasts with auto-dismiss.
Item {
    id: toastRoot
    anchors.fill: parent
    z: 9500

    // Public API
    function show(message, type, duration) {
        type = type || "info"
        duration = duration || 4000
        toastModel.append({ message: message, type: type, duration: duration })
    }

    ListModel {
        id: toastModel
    }

    Column {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 52
        anchors.rightMargin: 16
        spacing: 8
        z: 9501

        Repeater {
            model: toastModel

            delegate: Item {
                id: toastDelegate
                width: 340
                height: toastCard.height
                opacity: 0
                x: 60

                Component.onCompleted: {
                    enterAnim.start()
                    dismissTimer.interval = model.duration
                    dismissTimer.start()
                }

                Timer {
                    id: dismissTimer
                    repeat: false
                    onTriggered: exitAnim.start()
                }

                ParallelAnimation {
                    id: enterAnim
                    NumberAnimation { target: toastDelegate; property: "opacity"; to: 1.0; duration: SkinTheme.animNormal; easing.type: Easing.OutCubic }
                    NumberAnimation { target: toastDelegate; property: "x"; to: 0; duration: SkinTheme.animNormal; easing.type: Easing.OutCubic }
                }

                ParallelAnimation {
                    id: exitAnim
                    NumberAnimation { target: toastDelegate; property: "opacity"; to: 0; duration: 200; easing.type: Easing.InCubic }
                    NumberAnimation { target: toastDelegate; property: "x"; to: 60; duration: 200; easing.type: Easing.InCubic }
                    onFinished: toastModel.remove(index)
                }

                Rectangle {
                    id: toastCard
                    width: parent.width
                    height: toastContent.implicitHeight + 24
                    radius: SkinTheme.radiusMedium
                    color: SkinTheme.bgElevated
                    border.color: SkinTheme.borderLight
                    border.width: 1

                    // Subtle shadow
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -1
                        radius: parent.radius + 1
                        color: "transparent"
                        border.color: "#08000000"
                        border.width: 1
                        z: -1
                    }

                    // Left accent strip
                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.leftMargin: 0
                        anchors.topMargin: 6
                        anchors.bottomMargin: 6
                        width: 3
                        radius: 2
                        color: {
                            if (model.type === "success") return SkinTheme.accentEmerald
                            if (model.type === "error") return SkinTheme.accentCrimson
                            if (model.type === "warning") return SkinTheme.accentAmber
                            return SkinTheme.accentBlue
                        }
                    }

                    RowLayout {
                        id: toastContent
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 8
                        anchors.topMargin: 12
                        anchors.bottomMargin: 12
                        spacing: 10

                        // Icon
                        Text {
                            text: {
                                if (model.type === "success") return "✓"
                                if (model.type === "error") return "✕"
                                if (model.type === "warning") return "⚠"
                                return "ℹ"
                            }
                            color: {
                                if (model.type === "success") return SkinTheme.accentEmerald
                                if (model.type === "error") return SkinTheme.accentCrimson
                                if (model.type === "warning") return SkinTheme.accentAmber
                                return SkinTheme.accentBlue
                            }
                            font.pixelSize: 14
                            font.bold: true
                        }

                        // Message
                        Text {
                            text: model.message
                            color: SkinTheme.textPrimary
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: SkinTheme.fontSizeBody
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                            maximumLineCount: 3
                            elide: Text.ElideRight
                        }

                        // Close button
                        Rectangle {
                            width: 20
                            height: 20
                            radius: SkinTheme.radiusSmall
                            color: closeMouse.containsMouse ? SkinTheme.bgCardHover : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: "✕"
                                color: SkinTheme.textMuted
                                font.pixelSize: 9
                            }

                            MouseArea {
                                id: closeMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: exitAnim.start()
                            }
                        }
                    }

                    // Progress bar (auto-dismiss countdown)
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.leftMargin: 1
                        anchors.bottomMargin: 1
                        height: 2
                        radius: 1
                        width: parent.width - 2
                        color: {
                            if (model.type === "success") return SkinTheme.accentEmerald
                            if (model.type === "error") return SkinTheme.accentCrimson
                            if (model.type === "warning") return SkinTheme.accentAmber
                            return SkinTheme.accentBlue
                        }
                        opacity: 0.4

                        NumberAnimation on width {
                            from: toastCard.width - 2
                            to: 0
                            duration: model.duration
                            running: true
                        }
                    }
                }
            }
        }
    }
}
