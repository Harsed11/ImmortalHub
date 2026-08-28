import QtQuick 2.15
import "../theme"

// Living aurora background: soft neon blobs drifting slowly across the void,
// with subtle parallax following the cursor. Pure QML (fake-glow discs),
// no GPU-blur module dependencies — works on any Qt build.
Item {
    id: auroraRoot

    // Normalized pointer position (0..1) for parallax
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

    // Fake-glow blob: three concentric translucent discs create a soft edge
    component GlowBlob: Item {
        id: blobRoot
        property color tint: "#00F0FF"
        property real strength: 1.0
        width: 220
        height: 220

        Rectangle {
            anchors.centerIn: parent
            width: blobRoot.width * 3.0
            height: width
            radius: width / 2
            color: blobRoot.tint
            opacity: 0.026 * blobRoot.strength
        }
        Rectangle {
            anchors.centerIn: parent
            width: blobRoot.width * 1.9
            height: width
            radius: width / 2
            color: blobRoot.tint
            opacity: 0.05 * blobRoot.strength
        }
        Rectangle {
            anchors.centerIn: parent
            width: blobRoot.width
            height: width
            radius: width / 2
            color: blobRoot.tint
            opacity: 0.09 * blobRoot.strength
        }
    }

    // Container handles parallax (Behavior-smoothed), blob handles drift
    Item {
        id: blob1Container
        x: parent.width * 0.08 + (auroraRoot.pointerX - 0.5) * -34
        y: parent.height * 0.12 + (auroraRoot.pointerY - 0.5) * -22
        Behavior on x { NumberAnimation { duration: 900; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 900; easing.type: Easing.OutCubic } }

        GlowBlob {
            tint: SkinTheme.accentCyan
            strength: 1.0
            SequentialAnimation on x {
                loops: Animation.Infinite
                NumberAnimation { to: 55; duration: 11000; easing.type: Easing.InOutSine }
                NumberAnimation { to: -55; duration: 14500; easing.type: Easing.InOutSine }
            }
            SequentialAnimation on y {
                loops: Animation.Infinite
                NumberAnimation { to: -38; duration: 9500; easing.type: Easing.InOutSine }
                NumberAnimation { to: 38; duration: 13000; easing.type: Easing.InOutSine }
            }
        }
    }

    Item {
        id: blob2Container
        x: parent.width * 0.86 + (auroraRoot.pointerX - 0.5) * 40
        y: parent.height * 0.74 + (auroraRoot.pointerY - 0.5) * 26
        Behavior on x { NumberAnimation { duration: 1100; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 1100; easing.type: Easing.OutCubic } }

        GlowBlob {
            width: 260
            tint: SkinTheme.accentViolet
            strength: 1.0
            SequentialAnimation on x {
                loops: Animation.Infinite
                NumberAnimation { to: -48; duration: 12500; easing.type: Easing.InOutSine }
                NumberAnimation { to: 42; duration: 9800; easing.type: Easing.InOutSine }
            }
            SequentialAnimation on y {
                loops: Animation.Infinite
                NumberAnimation { to: 30; duration: 10800; easing.type: Easing.InOutSine }
                NumberAnimation { to: -34; duration: 13900; easing.type: Easing.InOutSine }
            }
        }
    }

    Item {
        id: blob3Container
        x: parent.width * 0.55 + (auroraRoot.pointerX - 0.5) * 22
        y: parent.height * 0.40 + (auroraRoot.pointerY - 0.5) * -30
        Behavior on x { NumberAnimation { duration: 1000; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 1000; easing.type: Easing.OutCubic } }

        GlowBlob {
            width: 190
            tint: SkinTheme.accentEmerald
            strength: 0.8
            SequentialAnimation on x {
                loops: Animation.Infinite
                NumberAnimation { to: 36; duration: 8600; easing.type: Easing.InOutSine }
                NumberAnimation { to: -30; duration: 12200; easing.type: Easing.InOutSine }
            }
            SequentialAnimation on y {
                loops: Animation.Infinite
                NumberAnimation { to: -44; duration: 11700; easing.type: Easing.InOutSine }
                NumberAnimation { to: 36; duration: 9200; easing.type: Easing.InOutSine }
            }
        }
    }

    Item {
        id: blob4Container
        x: parent.width * 0.30 + (auroraRoot.pointerX - 0.5) * -26
        y: parent.height * 0.85 + (auroraRoot.pointerY - 0.5) * 18
        Behavior on x { NumberAnimation { duration: 1200; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 1200; easing.type: Easing.OutCubic } }

        GlowBlob {
            width: 170
            tint: SkinTheme.accentCyan
            strength: 0.7
            SequentialAnimation on x {
                loops: Animation.Infinite
                NumberAnimation { to: -40; duration: 10100; easing.type: Easing.InOutSine }
                NumberAnimation { to: 34; duration: 13300; easing.type: Easing.InOutSine }
            }
            SequentialAnimation on y {
                loops: Animation.Infinite
                NumberAnimation { to: 26; duration: 8900; easing.type: Easing.InOutSine }
                NumberAnimation { to: -30; duration: 12600; easing.type: Easing.InOutSine }
            }
        }
    }
}

