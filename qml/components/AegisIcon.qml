import QtQuick 2.15
import "../theme"

Item {
    id: aegis
    width: 28
    height: 28

    property color primaryColor: SkinTheme.accentCyan
    property color secondaryColor: SkinTheme.accentViolet
    property color glowColor: "#80FFFF"
    property bool animated: true
    property real pulseOpacity: 0.6

    SequentialAnimation on pulseOpacity {
        running: aegis.animated
        loops: Animation.Infinite
        NumberAnimation { to: 1.0; duration: 1600; easing.type: Easing.InOutSine }
        NumberAnimation { to: 0.4; duration: 1600; easing.type: Easing.InOutSine }
    }

    // Outer subtle ambient glow
    Rectangle {
        anchors.centerIn: parent
        width: parent.width + 6
        height: parent.height + 6
        radius: width / 2
        color: aegis.primaryColor
        opacity: aegis.pulseOpacity * 0.2
    }

    // Official ImmortalHub Logo
    Image {
        id: logoImg
        anchors.fill: parent
        anchors.margins: 1
        source: "../../assets/logo_transparent.png"
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
        visible: status === Image.Ready
    }

    // Fallback Canvas (if image is loading or missing)
    Canvas {
        id: canvas
        anchors.fill: parent
        visible: logoImg.status !== Image.Ready
        renderTarget: Canvas.Image
        antialiasing: true

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            var w = width
            var h = height
            var cx = w / 2
            var cy = h / 2

            // Draw Aegis Shield Outer Shape
            ctx.beginPath()
            ctx.moveTo(cx, h * 0.05)
            ctx.lineTo(w * 0.92, h * 0.28)
            ctx.lineTo(w * 0.82, h * 0.76)
            ctx.lineTo(cx, h * 0.96)
            ctx.lineTo(w * 0.18, h * 0.76)
            ctx.lineTo(w * 0.08, h * 0.28)
            ctx.closePath()

            var gradOuter = ctx.createLinearGradient(0, 0, w, h)
            gradOuter.addColorStop(0, "#0A0D1A")
            gradOuter.addColorStop(0.5, "#080C18")
            gradOuter.addColorStop(1, "#100820")
            ctx.fillStyle = gradOuter
            ctx.fill()

            ctx.lineWidth = Math.max(1.5, w * 0.06)
            ctx.strokeStyle = primaryColor
            ctx.stroke()
        }
    }
}
