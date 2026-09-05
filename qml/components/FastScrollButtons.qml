import QtQuick 2.15
import QtQuick.Controls 2.15
import "../theme"

Item {
    id: fastScrollRoot

    property var target: null
    property int scrollDuration: 280

    // Visibility: only show if the content actually exceeds the viewport
    readonly property real minY: (target && target.originY !== undefined) ? target.originY : 0
    readonly property real maxY: (target && target.contentHeight !== undefined) ? (minY + Math.max(0, target.contentHeight - target.height)) : 0
    readonly property bool hasOverflow: Boolean(target && (target.contentHeight > target.height + 40))
    readonly property bool isNearTop: Boolean(target && (target.contentY <= (minY + 120)))
    readonly property bool isNearBottom: Boolean(target && (target.contentY >= (maxY - 120)))

    width: 40
    height: 82
    anchors.right: parent ? parent.right : undefined
    anchors.bottom: parent ? parent.bottom : undefined
    anchors.rightMargin: 20
    anchors.bottomMargin: 24
    z: 99

    visible: opacity > 0.01
    opacity: hasOverflow ? (hoverMouseArea.containsMouse ? 1.0 : 0.75) : 0.0
    scale: hasOverflow ? 1.0 : 0.85

    Behavior on opacity { NumberAnimation { duration: SkinTheme.animFast } }
    Behavior on scale { NumberAnimation { duration: SkinTheme.animFast; easing.type: Easing.OutCubic } }

    NumberAnimation {
        id: scrollAnim
        target: fastScrollRoot.target
        property: "contentY"
        duration: fastScrollRoot.scrollDuration
        easing.type: Easing.OutCubic
    }

    Connections {
        target: fastScrollRoot.target
        ignoreUnknownSignals: true
        function onMovementStarted() {
            scrollAnim.stop()
        }
    }

    function scrollToTop() {
        if (!target) return
        scrollAnim.stop()
        scrollAnim.from = target.contentY
        scrollAnim.to = minY
        scrollAnim.start()
    }

    function scrollToBottom() {
        if (!target) return
        scrollAnim.stop()
        scrollAnim.from = target.contentY
        scrollAnim.to = maxY
        scrollAnim.start()
    }

    Rectangle {
        id: pillBody
        anchors.fill: parent
        radius: 19
        color: "#E80B0B14"
        border.color: hoverMouseArea.containsMouse ? SkinTheme.accentCyanSoft : SkinTheme.borderMuted
        border.width: 1

        Behavior on border.color { ColorAnimation { duration: SkinTheme.animFast } }

        // Glow halo on hover
        Rectangle {
            anchors.centerIn: parent
            width: parent.width + 4
            height: parent.height + 4
            radius: parent.radius + 2
            color: "transparent"
            border.color: SkinTheme.accentCyan
            border.width: 1
            opacity: hoverMouseArea.containsMouse ? 0.35 : 0.0
            z: -1

            Behavior on opacity { NumberAnimation { duration: SkinTheme.animFast } }
        }

        MouseArea {
            id: hoverMouseArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
        }

        Column {
            anchors.centerIn: parent
            spacing: 2

            // ── Scroll to Top Button (▲) ──
            Rectangle {
                id: topBtn
                width: 32
                height: 34
                radius: 16
                color: topMouse.pressed ? SkinTheme.bgCardActive : (topMouse.containsMouse ? SkinTheme.bgCardHover : "transparent")
                scale: topMouse.pressed ? 0.92 : 1.0

                Behavior on scale { NumberAnimation { duration: SkinTheme.animFast } }
                Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

                Text {
                    anchors.centerIn: parent
                    text: "▲"
                    font.pixelSize: 10
                    color: fastScrollRoot.isNearTop
                           ? SkinTheme.textMuted
                           : (topMouse.containsMouse ? SkinTheme.accentCyan : SkinTheme.textPrimary)
                    font.bold: true

                    Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }
                }

                ToolTip.visible: topMouse.containsMouse
                ToolTip.text: "Scroll to Top (Наверх)"
                ToolTip.delay: 300

                MouseArea {
                    id: topMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: fastScrollRoot.scrollToTop()
                }
            }

            // Divider line
            Rectangle {
                width: 18
                height: 1
                color: SkinTheme.borderSubtle
                anchors.horizontalCenter: parent.horizontalCenter
            }

            // ── Scroll to Bottom Button (▼) ──
            Rectangle {
                id: bottomBtn
                width: 32
                height: 34
                radius: 16
                color: bottomMouse.pressed ? SkinTheme.bgCardActive : (bottomMouse.containsMouse ? SkinTheme.bgCardHover : "transparent")
                scale: bottomMouse.pressed ? 0.92 : 1.0

                Behavior on scale { NumberAnimation { duration: SkinTheme.animFast } }
                Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }

                Text {
                    anchors.centerIn: parent
                    text: "▼"
                    font.pixelSize: 10
                    color: fastScrollRoot.isNearBottom
                           ? SkinTheme.textMuted
                           : (bottomMouse.containsMouse ? SkinTheme.accentCyan : SkinTheme.textPrimary)
                    font.bold: true

                    Behavior on color { ColorAnimation { duration: SkinTheme.animFast } }
                }

                ToolTip.visible: bottomMouse.containsMouse
                ToolTip.text: "Scroll to Bottom (Вниз)"
                ToolTip.delay: 300

                MouseArea {
                    id: bottomMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: fastScrollRoot.scrollToBottom()
                }
            }
        }
    }
}
