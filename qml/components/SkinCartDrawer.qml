import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"

Rectangle {
    id: drawer
    anchors.fill: parent
    color: SkinTheme.bgModalOverlay
    visible: opacity > 0
    opacity: isOpen ? 1 : 0
    z: 400

    property bool isOpen: false
    property var cartList: []
    property bool isInstalling: false
    property int installPercent: 0
    property string installStatus: ""
    property string currentInstallingItem: ""

    signal closeRequested()
    signal installAllRequested()
    signal clearRequested()
    signal removeItemRequested(int index)

    Behavior on opacity { NumberAnimation { duration: SkinTheme.animFast } }

    // Dismiss on backdrop click
    MouseArea {
        anchors.fill: parent
        onClicked: drawer.closeRequested()
    }

    // Slide-in Drawer from Right
    Rectangle {
        id: panel
        width: Math.min(420, parent.width * 0.85)
        height: parent.height
        anchors.right: parent.right
        color: SkinTheme.bgSidebar
        border.color: SkinTheme.borderSubtle
        border.width: 1

        x: isOpen ? parent.width - width : parent.width
        Behavior on x { NumberAnimation { duration: SkinTheme.animNormal; easing.type: Easing.OutCubic } }

        MouseArea {
            anchors.fill: parent
            onClicked: {} // Prevent backdrop click
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // ── Drawer Header ──
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
                    anchors.leftMargin: 18
                    anchors.rightMargin: 14
                    spacing: 10

                    Text {
                        text: "INSTALL QUEUE"
                        color: SkinTheme.textPrimary
                        font.family: SkinTheme.fontFamily
                        font.pixelSize: SkinTheme.fontSizeTitle
                        font.bold: true
                        font.letterSpacing: 0.5
                    }

                    Rectangle {
                        height: 20
                        radius: SkinTheme.radiusPill
                        implicitWidth: cartCountPill.implicitWidth + 12
                        color: cartList.length > 0 ? SkinTheme.accentCyanGlow : SkinTheme.bgCard
                        border.color: cartList.length > 0 ? SkinTheme.accentCyan : SkinTheme.borderMuted
                        border.width: 1

                        Text {
                            id: cartCountPill
                            anchors.centerIn: parent
                            text: cartList.length + ""
                            color: cartList.length > 0 ? SkinTheme.accentCyan : SkinTheme.textMuted
                            font.family: SkinTheme.fontMono
                            font.pixelSize: 9
                            font.bold: true
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Close Button
                    Rectangle {
                        width: 30
                        height: 30
                        radius: SkinTheme.radiusSmall
                        color: closeBtnMouse.containsMouse ? SkinTheme.bgCardHover : "transparent"
                        border.color: SkinTheme.borderMuted
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            color: closeBtnMouse.containsMouse ? SkinTheme.textPrimary : SkinTheme.textMuted
                            font.pixelSize: 11
                        }

                        MouseArea {
                            id: closeBtnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: drawer.closeRequested()
                        }
                    }
                }
            }

            // ── Install Progress Banner ──
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 68
                color: SkinTheme.bgCard
                visible: isInstalling
                border.color: SkinTheme.accentCyan
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: installStatus || "INSTALLING..."
                            color: SkinTheme.accentCyan
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: SkinTheme.fontSizeSmall
                            font.bold: true
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        Text {
                            text: installPercent + "%"
                            color: SkinTheme.textPrimary
                            font.family: SkinTheme.fontMono
                            font.pixelSize: SkinTheme.fontSizeBody
                            font.bold: true
                        }
                    }

                    // Progress Bar
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 6
                        radius: 3
                        color: SkinTheme.bgDark

                        Rectangle {
                            height: parent.height
                            radius: 3
                            width: Math.max(6, parent.width * (installPercent / 100))
                            color: SkinTheme.accentCyan
                            Behavior on width { NumberAnimation { duration: 150 } }
                        }
                    }
                }
            }

            // ── Queued Items List ──
            ListView {
                id: cartListView
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: cartList
                clip: true
                spacing: 6
                displayMarginBeginning: 10
                displayMarginEnd: 10

                ScrollBar.vertical: NeonScrollBar {}

                delegate: Rectangle {
                    width: cartListView.width - 24
                    height: 56
                    anchors.horizontalCenter: parent.horizontalCenter
                    radius: SkinTheme.radiusMedium
                    color: itemRowMouse.containsMouse ? SkinTheme.bgCardHover : SkinTheme.bgCard
                    border.color: itemRowMouse.containsMouse ? SkinTheme.borderLight : SkinTheme.borderMuted
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }
                    Behavior on border.color { ColorAnimation { duration: SkinTheme.animFast } }

                    MouseArea {
                        id: itemRowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 12

                        // Thumbnail
                        Rectangle {
                            width: 44
                            height: 38
                            radius: SkinTheme.radiusSmall
                            color: SkinTheme.bgDark
                            clip: true

                            Image {
                                anchors.fill: parent
                                source: modelData.previewUrl || ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }
                        }

                        // Info
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: modelData.name
                                color: SkinTheme.textPrimary
                                font.family: SkinTheme.fontFamily
                                font.pixelSize: SkinTheme.fontSizeBody
                                font.bold: true
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: app.translate(modelData.categoryId) + (modelData.hero ? " • " + modelData.hero : "")
                                color: SkinTheme.textSecondary
                                font.family: SkinTheme.fontFamily
                                font.pixelSize: SkinTheme.fontSizeSmall
                                elide: Text.ElideRight
                            }
                        }

                        // Remove Button
                        Rectangle {
                            width: 26
                            height: 26
                            radius: SkinTheme.radiusSmall
                            color: delMouse.containsMouse ? SkinTheme.accentCrimsonHover : "transparent"
                            border.color: delMouse.containsMouse ? "transparent" : SkinTheme.borderMuted
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "✕"
                                color: delMouse.containsMouse ? "#FFFFFF" : SkinTheme.textMuted
                                font.pixelSize: 10
                            }

                            MouseArea {
                                id: delMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: drawer.removeItemRequested(index)
                            }
                        }
                    }
                }

                // Empty State
                Item {
                    anchors.centerIn: parent
                    visible: cartList.length === 0

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 10

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "⚡"
                            font.pixelSize: 28
                            color: SkinTheme.textMuted
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "QUEUE IS EMPTY"
                            color: SkinTheme.textPrimary
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: SkinTheme.fontSizeBody
                            font.bold: true
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Click '+' on any skin card to add to queue"
                            color: SkinTheme.textSecondary
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: SkinTheme.fontSizeSmall
                        }
                    }
                }
            }

            // ── Footer Action Buttons ──
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 106
                color: SkinTheme.bgDark

                Rectangle {
                    anchors.top: parent.top
                    width: parent.width
                    height: 1
                    color: SkinTheme.borderSubtle
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 8

                    // Install All Button
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        radius: SkinTheme.radiusMedium
                        enabled: cartList.length > 0 && !isInstalling
                        color: (cartList.length > 0 && !isInstalling)
                               ? (instAllMouse.containsMouse ? SkinTheme.accentCyanHover : SkinTheme.accentCyan)
                               : SkinTheme.bgCard

                        Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: "⚡"
                                color: (cartList.length > 0 && !isInstalling) ? "#FFFFFF" : SkinTheme.textMuted
                                font.pixelSize: 11
                            }

                            Text {
                                text: isInstalling ? "INSTALLING..." : "INSTALL ALL (" + cartList.length + ")"
                                color: (cartList.length > 0 && !isInstalling) ? "#FFFFFF" : SkinTheme.textMuted
                                font.family: SkinTheme.fontFamily
                                font.pixelSize: SkinTheme.fontSizeBody
                                font.bold: true
                                font.letterSpacing: 0.5
                            }
                        }

                        MouseArea {
                            id: instAllMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: drawer.installAllRequested()
                        }
                    }

                    // Clear Queue
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 32
                        radius: SkinTheme.radiusMedium
                        color: clearMouse.containsMouse ? SkinTheme.bgCardHover : "transparent"
                        border.color: SkinTheme.borderMuted
                        border.width: 1
                        enabled: cartList.length > 0 && !isInstalling

                        Text {
                            anchors.centerIn: parent
                            text: "CLEAR QUEUE"
                            color: SkinTheme.textMuted
                            font.family: SkinTheme.fontFamily
                            font.pixelSize: SkinTheme.fontSizeSmall
                            font.bold: true
                        }

                        MouseArea {
                            id: clearMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: drawer.clearRequested()
                        }
                    }
                }
            }
        }
    }
}
