import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"

Rectangle {
    id: toastRoot
    width: toastContent.implicitWidth + 40
    height: 44
    radius: SkinTheme.radiusMedium
    color: SkinTheme.bgGlass
    border.width: 1
    border.color: {
        if (toastType === "success") return SkinTheme.accentEmerald
        if (toastType === "error") return SkinTheme.accentCrimson
        return SkinTheme.accentCyan
    }
    anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
    anchors.bottom: parent ? parent.bottom : undefined
    anchors.bottomMargin: 24
    z: 9999
    opacity: 0
    visible: opacity > 0
    scale: 0.9

    Behavior on opacity { NumberAnimation { duration: SkinTheme.animFast } }
    Behavior on scale { NumberAnimation { duration: SkinTheme.animNormal; easing.type: Easing.OutBack } }

    property string toastType: "info"
    property alias text: toastLabel.text

    // Neon glow background
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: {
            if (toastType === "success") return SkinTheme.accentEmeraldGlow
            if (toastType === "error") return SkinTheme.accentCrimsonGlow
            return SkinTheme.accentCyanGlow
        }
        opacity: 0.3
        z: -1
    }

    // Glitch flash on appear
    Rectangle {
        id: glitchFlash
        anchors.fill: parent
        radius: parent.radius
        color: "#ffffff"
        opacity: 0
    }

    RowLayout {
        id: toastContent
        anchors.centerIn: parent
        spacing: 10

        // Status indicator
        Rectangle {
            width: 4
            height: 20
            radius: 2
            color: {
                if (toastType === "success") return SkinTheme.accentEmerald
                if (toastType === "error") return SkinTheme.accentCrimson
                return SkinTheme.accentCyan
            }
        }

        Text {
            id: toastLabel
            color: SkinTheme.textPrimary
            font.family: SkinTheme.fontFamily
            font.pixelSize: 12
            font.weight: Font.DemiBold
        }
    }

    Timer {
        id: hideTimer
        interval: 3000
        onTriggered: {
            toastRoot.opacity = 0
            toastRoot.scale = 0.9
        }
    }

    // Glitch animation on show
    SequentialAnimation {
        id: glitchAnim
        NumberAnimation { target: glitchFlash; property: "opacity"; to: 0.15; duration: 40 }
        NumberAnimation { target: glitchFlash; property: "opacity"; to: 0; duration: 40 }
        PauseAnimation { duration: 60 }
        NumberAnimation { target: glitchFlash; property: "opacity"; to: 0.08; duration: 30 }
        NumberAnimation { target: glitchFlash; property: "opacity"; to: 0; duration: 30 }
    }

    function show(message, type) {
        text = message
        toastType = type || "info"
        toastRoot.opacity = 1
        toastRoot.scale = 1.0
        glitchAnim.start()
        hideTimer.restart()
    }
}
