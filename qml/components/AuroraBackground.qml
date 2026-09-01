import QtQuick 2.15
import "../theme"

// Subtle ambient background: very soft accent-colored glow blobs
// drifting slowly. Toned down for premium feel — barely visible,
// adds depth without distraction.
Item {
    id: auroraRoot

    property real pointerX: 0.5
    property real pointerY: 0.5

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        hoverEnabled: true
        onPositionChanged: function(mouse) {
            auroraRoot.pointerX = mouse.x / Math.max(1, auroraRoot.width)
            auroraRoot.pointerY = mouse.y / Math.max(1, auroraRoot.height)
        }
    }

    // Soft glow blob: concentric translucent discs
    component GlowBlob: Item {
        id: blobRoot
        property color tint: SkinTheme.accentCyan
        property real strength: 1.0
        width: 280
        height: 280

        Rectangle {
            anchors.centerIn: parent
            width: blobRoot.width * 3.0
            height: width
            radius: width / 2
            color: blobRoot.tint
            opacity: 0.012 * blobRoot.strength
        }
        Rectangle {
            anchors.centerIn: parent
            width: blobRoot.width * 1.8
            height: width
            radius: width / 2
            color: blobRoot.tint
            opacity: 0.022 * blobRoot.strength
        }
        Rectangle {
            anchors.centerIn: parent
            width: blobRoot.width
            height: width
            radius: width / 2
            color: blobRoot.tint
            opacity: 0.035 * blobRoot.strength
        }
    }

    // Blob 1 — top-left, accent color
    Item {
        x: parent.width * 0.08 + (auroraRoot.pointerX - 0.5) * -20
        y: parent.height * 0.12 + (auroraRoot.pointerY - 0.5) * -14
        Behavior on x { NumberAnimation { duration: 1200; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 1200; easing.type: Easing.OutCubic } }

        GlowBlob {
            tint: SkinTheme.accentCyan
            strength: 0.6
            SequentialAnimation on x {
                loops: Animation.Infinite
                NumberAnimation { to: 40; duration: 18000; easing.type: Easing.InOutSine }
                NumberAnimation { to: -40; duration: 22000; easing.type: Easing.InOutSine }
            }
            SequentialAnimation on y {
                loops: Animation.Infinite
                NumberAnimation { to: -28; duration: 16000; easing.type: Easing.InOutSine }
                NumberAnimation { to: 28; duration: 20000; easing.type: Easing.InOutSine }
            }
        }
    }

    // Blob 2 — bottom-right, violet
    Item {
        x: parent.width * 0.82 + (auroraRoot.pointerX - 0.5) * 24
        y: parent.height * 0.72 + (auroraRoot.pointerY - 0.5) * 16
        Behavior on x { NumberAnimation { duration: 1400; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 1400; easing.type: Easing.OutCubic } }

        GlowBlob {
            width: 320
            tint: SkinTheme.accentViolet
            strength: 0.5
            SequentialAnimation on x {
                loops: Animation.Infinite
                NumberAnimation { to: -36; duration: 20000; easing.type: Easing.InOutSine }
                NumberAnimation { to: 30; duration: 24000; easing.type: Easing.InOutSine }
            }
            SequentialAnimation on y {
                loops: Animation.Infinite
                NumberAnimation { to: 22; duration: 17000; easing.type: Easing.InOutSine }
                NumberAnimation { to: -26; duration: 21000; easing.type: Easing.InOutSine }
            }
        }
    }
}
