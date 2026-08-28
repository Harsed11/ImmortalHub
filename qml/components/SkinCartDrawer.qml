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

    // Backdrop click -> close
    MouseArea {
        anchors.fill: parent
        onClicked: drawer.closeRequested()
    }

    // Slide-in Panel from Right
    Rectangle {
        id: panel
        width: Math.min(420, parent.width * 0.85)
        height: parent.height
        anchors.right: parent.right
        color: SkinTheme.bgSidebar
        border.color: SkinTheme.borderMuted
        border.width: 1

        x: isOpen ? parent.width - width : parent.width
        Behavior on x { NumberAnimation { duration: SkinTheme.animNormal; easing.type: Easing.OutCubic } }

        // Left neon edge
        Rectangle {
            anchors.left: parent.left
            width: 1
            height: parent.height
            color: SkinTheme.accentCyan
            opacity: 0.3
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {} // Prevent backdrop click
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // Header Bar
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                color: SkinTheme.bgDark

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: SkinTheme.borderMuted
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 18
                    anchors.rightMargin: 14
                    spacing: 10

                    Text {
                        text: "BATCH QUEUE"
                        color: SkinTheme.textPrimary
                        font.family: SkinTheme.fontMono
                        font.pixelSize: 12
                        font.bold: true
                        font.letterSpacing: 1.5
                    }

                    Rectangle {
                        height: 20
                        radius: 4
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
                            font.pixelSize: 10
                            font.bold: true
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: 30
                        height: 30
                        radius: SkinTheme.radiusSmall
                        color: closeBtnMouse.containsMouse ? SkinTheme.bgCardHover : "transparent"
                        border.color: closeBtnMouse.containsMouse ? SkinTheme.accentCrimson : SkinTheme.borderMuted
                        border.width: 1

                        Behavior on border.color { ColorAnimation { duration: SkinTheme.animFast } }

                        Text {
                            anchors.centerIn: parent
                            text: "\uE8BB"
                            color: closeBtnMouse.containsMouse ? SkinTheme.accentCrimson : SkinTheme.textMuted
                            font.family: "Segoe MDL2 Assets"
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

            // Install Progress
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 72
                color: SkinTheme.bgCard
                visible: isInstalling
                border.color: SkinTheme.accentCyan
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: installStatus || "INSTALLING..."
                            color: SkinTheme.accentCyan
                            font.family: SkinTheme.fontMono
                            font.pixelSize: 10
                            font.bold: true
                            font.letterSpacing: 0.5
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        Text {
                            text: installPercent + "%"
                            color: SkinTheme.textPrimary
                            font.family: SkinTheme.fontMono
                            font.pixelSize: 12
                            font.bold: true
                        }
                    }

                    // Progress Bar — neon gradient
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 6
                        radius: 3
                        color: SkinTheme.bgDark

                        Rectangle {
                            height: parent.height
                            radius: 3
                            width: Math.max(6, parent.width * (installPercent / 100))
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: SkinTheme.accentCyan }
                                GradientStop { position: 1.0; color: SkinTheme.accentViolet }
                            }
                            Behavior on width { NumberAnimation { duration: 150 } }

                            // Glow effect
                            Rectangle {
                                anchors.fill: parent
                                radius: parent.radius
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.0; color: SkinTheme.accentCyan }
                                    GradientStop { position: 1.0; color: SkinTheme.accentViolet }
                                }
                                opacity: 0.4
                                anchors.margins: -2
                            }
                        }
                    }
                }
            }

            // Queued Items List
            ListView {
                id: cartListView
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: cartList
                clip: true
                spacing: 6
                displayMarginBeginning: 10
                displayMarginEnd: 10

                ScrollBar.vertical: ScrollBar {
                    width: 4
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle {
                        radius: 2
                        color: SkinTheme.accentCyan
                        opacity: 0.3
                    }
                }

                delegate: Rectangle {
                    width: cartListView.width - 24
                    height: 56
                    anchors.horizontalCenter: parent.horizontalCenter
                    radius: SkinTheme.radiusSmall
                    color: SkinTheme.bgCard
                    border.color: itemRowMouse.containsMouse ? SkinTheme.accentCyan : SkinTheme.borderMuted
                    border.width: 1

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
                            border.color: SkinTheme.borderMuted
                            border.width: 1

                            Image {
                                anchors.fill: parent
                                source: modelData.previewUrl || ""
                                fillMode: Image.PreserveAspectCrop
                                sourceSize.width: 100
                                sourceSize.height: 70
                                asynchronous: true
                                cache: true
                            }
                        }

                        // Info
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3

                            Text {
                                text: modelData.name
                                color: SkinTheme.textPrimary
                                font.family: SkinTheme.fontFamily
                                font.pixelSize: 12
                                font.bold: true
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: app.translate(modelData.categoryId) + (modelData.hero ? " • " + modelData.hero : "")
                                color: SkinTheme.textMuted
                                font.family: SkinTheme.fontMono
                                font.pixelSize: 9
                                font.letterSpacing: 0.5
                                elide: Text.ElideRight
                            }
                        }

                        // Remove Button
                        Rectangle {
                            width: 26
                            height: 26
                            radius: SkinTheme.radiusSmall
                            color: delMouse.containsMouse ? SkinTheme.accentCrimson : "transparent"
                            border.color: delMouse.containsMouse ? "transparent" : SkinTheme.borderMuted
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

                            Text {
                                anchors.centerIn: parent
                                text: "\uE8BB"
                                color: delMouse.containsMouse ? "#ffffff" : SkinTheme.textMuted
                                font.family: "Segoe MDL2 Assets"
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
                        spacing: 12

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "⊘"
                            font.pixelSize: 32
                            color: SkinTheme.textMuted
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "QUEUE EMPTY"
                            color: SkinTheme.textPrimary
                            font.family: SkinTheme.fontMono
                            font.pixelSize: 13
                            font.bold: true
                            font.letterSpacing: 1.5
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Click '+' on any mod card to add items"
                            color: SkinTheme.textMuted
                            font.pixelSize: 11
                        }
                    }
                }
            }

            // Footer Actions
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 110
                color: SkinTheme.bgDark

                Rectangle {
                    anchors.top: parent.top
                    width: parent.width
                    height: 1
                    color: SkinTheme.borderMuted
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 8

                    // Install All Button — neon gradient
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 42
                        radius: SkinTheme.radiusMedium
                        enabled: cartList.length > 0 && !isInstalling

                        gradient: (cartList.length > 0 && !isInstalling) ? instGrad : null
                        color: (cartList.length > 0 && !isInstalling) ? "transparent" : SkinTheme.borderMuted

                        Gradient {
                            id: instGrad
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: instAllMouse.containsMouse ? SkinTheme.accentCyanHover : SkinTheme.accentCyan }
                            GradientStop { position: 1.0; color: instAllMouse.containsMouse ? SkinTheme.accentVioletHover : SkinTheme.accentViolet }
                        }

                        // Glow behind button
                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width + 6
                            height: parent.height + 6
                            radius: parent.radius + 3
                            color: "transparent"
                            border.color: SkinTheme.accentCyan
                            border.width: 1
                            opacity: (cartList.length > 0 && instAllMouse.containsMouse) ? 0.3 : 0
                            Behavior on opacity { NumberAnimation { duration: SkinTheme.animFast } }
                        }

                        Row {
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "\uE945"
                                color: (cartList.length > 0 && !isInstalling) ? "#060810" : SkinTheme.textMuted
                                font.family: "Segoe MDL2 Assets"
                                font.pixelSize: 12
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: isInstalling ? "INSTALLING..." : "INSTALL ALL (" + cartList.length + ")"
                                color: (cartList.length > 0 && !isInstalling) ? "#060810" : SkinTheme.textMuted
                                font.family: SkinTheme.fontMono
                                font.pixelSize: 12
                                font.bold: true
                                font.letterSpacing: 1.0
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
                            font.family: SkinTheme.fontMono
                            font.pixelSize: 10
                            font.bold: true
                            font.letterSpacing: 1.0
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
