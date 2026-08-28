import QtQuick 2.15
import QtQuick.Controls 2.15
import "../theme"

// Thin neon scrollbar: invisible track, glowing thumb that brightens on
// hover/press and fades out when the area is not being scrolled.
ScrollBar {
    id: control

    implicitWidth: 10
    implicitHeight: 10

    contentItem: Rectangle {
        implicitWidth: control.pressed ? 6 : 4
        implicitHeight: 4
        radius: 3
        color: control.pressed ? SkinTheme.accentCyan
             : (control.hovered ? SkinTheme.accentCyanGlow : SkinTheme.borderMuted)
        opacity: (control.policy === ScrollBar.AlwaysOn || control.active) ? 1.0 : 0.15

        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on opacity { NumberAnimation { duration: 200 } }
        Behavior on implicitWidth { NumberAnimation { duration: 120 } }

        // One-sided neon edge glow while interacting
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            x: -2
            width: 2
            height: parent.height * 0.9
            radius: 1
            color: SkinTheme.accentCyan
            opacity: (control.hovered || control.pressed) ? 0.35 : 0

            Behavior on opacity { NumberAnimation { duration: 150 } }
        }
    }

    background: Rectangle {
        implicitWidth: 10
        color: "transparent"
    }
}
