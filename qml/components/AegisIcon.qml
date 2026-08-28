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
    property real rotAngle: 0

    SequentialAnimation on pulseOpacity {
        running: aegis.animated
        loops: Animation.Infinite
        NumberAnimation { to: 1.0; duration: 1400; easing.type: Easing.InOutSine }
        NumberAnimation { to: 0.4; duration: 1400; easing.type: Easing.InOutSine }
    }

    NumberAnimation on rotAngle {
        running: aegis.animated
        from: 0; to: 360
        duration: 20000
        loops: Animation.Infinite
    }

    onPulseOpacityChanged: {
        if (canvas.available) canvas.requestPaint()
    }
    onRotAngleChanged: {
        if (canvas.available) canvas.requestPaint()
    }

    // Outer glow layer
    Rectangle {
        anchors.centerIn: parent
        width: parent.width + 8
        height: parent.height + 8
        radius: width / 2
        color: "transparent"
        border.color: SkinTheme.accentCyan
        border.width: 1
        opacity: aegis.pulseOpacity * 0.15
    }

    Canvas {
        id: canvas
        anchors.fill: parent
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

            // Outer Shield Gradient — deep cyber blue
            var gradOuter = ctx.createLinearGradient(0, 0, w, h)
            gradOuter.addColorStop(0, "#0A0D1A")
            gradOuter.addColorStop(0.5, "#080C18")
            gradOuter.addColorStop(1, "#100820")
            ctx.fillStyle = gradOuter
            ctx.fill()

            // Cyan Outer Border
            ctx.lineWidth = Math.max(1.5, w * 0.06)
            ctx.strokeStyle = primaryColor
            ctx.globalAlpha = 0.8 + aegis.pulseOpacity * 0.2
            ctx.stroke()
            ctx.globalAlpha = 1.0

            // Inner Aegis Rune Contour
            ctx.beginPath()
            ctx.moveTo(cx, h * 0.18)
            ctx.lineTo(w * 0.80, h * 0.35)
            ctx.lineTo(w * 0.72, h * 0.70)
            ctx.lineTo(cx, h * 0.84)
            ctx.lineTo(w * 0.28, h * 0.70)
            ctx.lineTo(w * 0.20, h * 0.35)
            ctx.closePath()

            var gradInner = ctx.createRadialGradient(cx, cy, 1, cx, cy, w * 0.45)
            gradInner.addColorStop(0, "#1A0830")
            gradInner.addColorStop(0.8, "#0A0518")
            gradInner.addColorStop(1, "#060310")
            ctx.fillStyle = gradInner
            ctx.fill()

            ctx.lineWidth = Math.max(1.0, w * 0.035)
            ctx.strokeStyle = "#5500AACC"
            ctx.stroke()

            // Central Glowing Gem
            ctx.beginPath()
            ctx.moveTo(cx, h * 0.30)
            ctx.lineTo(w * 0.65, cy)
            ctx.lineTo(cx, h * 0.70)
            ctx.lineTo(w * 0.35, cy)
            ctx.closePath()

            var gemGrad = ctx.createRadialGradient(cx, cy, 0, cx, cy, w * 0.25)
            gemGrad.addColorStop(0, glowColor)
            gemGrad.addColorStop(0.3, primaryColor)
            gemGrad.addColorStop(0.7, secondaryColor)
            gemGrad.addColorStop(1, "#40001A")
            ctx.fillStyle = gemGrad
            ctx.globalAlpha = aegis.pulseOpacity
            ctx.fill()
            ctx.globalAlpha = 1.0

            ctx.lineWidth = 1
            ctx.strokeStyle = "#AAEEFF"
            ctx.stroke()

            // Core dot — bright cyan
            ctx.beginPath()
            ctx.arc(cx, cy, Math.max(1.5, w * 0.06), 0, Math.PI * 2)
            ctx.fillStyle = "#ffffff"
            ctx.globalAlpha = aegis.pulseOpacity
            ctx.fill()
            ctx.globalAlpha = 1.0
        }
    }
}
