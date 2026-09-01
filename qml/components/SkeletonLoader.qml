import QtQuick 2.15
import "../theme"

// Reusable skeleton loading placeholder with shimmer animation.
// Usage:  SkeletonLoader { width: 200; height: 100; radius: SkinTheme.radiusMedium }
Rectangle {
    id: skeleton
    color: SkinTheme.bgCard
    radius: SkinTheme.radiusMedium
    clip: true

    property bool animate: true

    // Shimmer sweep
    Rectangle {
        id: shimmer
        width: parent.width * 0.6
        height: parent.height
        x: -width
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.4; color: "#08FFFFFF" }
            GradientStop { position: 0.5; color: "#12FFFFFF" }
            GradientStop { position: 0.6; color: "#08FFFFFF" }
            GradientStop { position: 1.0; color: "transparent" }
        }

        SequentialAnimation on x {
            running: skeleton.visible && skeleton.animate
            loops: Animation.Infinite
            NumberAnimation {
                from: -shimmer.width
                to: skeleton.width + shimmer.width
                duration: 1400
                easing.type: Easing.InOutQuad
            }
            PauseAnimation { duration: 400 }
        }
    }
}
