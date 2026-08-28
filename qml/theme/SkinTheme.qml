pragma Singleton
import QtQuick 2.15

QtObject {
    id: theme

    // ═══════════════════════════════════════════
    // CYBERPUNK DARK BACKGROUNDS
    // ═══════════════════════════════════════════
    property color bgVoid: "#04060B"
    property color bgDark: "#080C14"
    property color bgSidebar: "#06080D"
    property color bgHeader: "#080C14"
    property color bgCard: "#0C1018"
    property color bgCardHover: "#111620"
    property color bgCardActive: "#161C2A"
    property color bgInput: "#0A0E16"
    property color bgModal: "#0A0D14"
    property color bgModalOverlay: "#E0030508"
    property color bgGlass: "#60080C14"

    // ═══════════════════════════════════════════
    // NEON BORDERS & STROKES
    // ═══════════════════════════════════════════
    property color borderMuted: "#12182A"
    property color borderLight: "#182236"
    property color borderActive: "#253450"
    property color borderGold: "#0099AA"
    property color borderCrimson: "#FF0055"
    property color borderCyan: "#0891b2"
    property color borderEmerald: "#00AA55"
    property color borderViolet: "#8000AA"
    property color borderNeon: "#1800F0FF"
    property color borderNeonViolet: "#18BF00FF"

    // ═══════════════════════════════════════════
    // PRIMARY ACCENT — NEON CYAN
    // ═══════════════════════════════════════════
    property color accentCyan: "#00F0FF"
    property color accentCyanHover: "#40FFFF"
    property color accentCyanDark: "#0099AA"
    property color accentCyanGlow: "#1500F0FF"
    property color accentCyanMuted: "#2000C8DD"

    // ═══════════════════════════════════════════
    // SECONDARY ACCENT — NEON VIOLET
    // ═══════════════════════════════════════════
    // SECONDARY ACCENT — NEON VIOLET
    // ═══════════════════════════════════════════
    property color accentViolet: "#BF00FF"
    property color accentVioletHover: "#D94DFF"
    property color accentVioletDark: "#8000AA"
    property color accentVioletGlow: "#15BF00FF"
    property color accentVioletMuted: "#20A000DD"

    // ═══════════════════════════════════════════
    // STATUS COLORS
    // ═══════════════════════════════════════════
    property color accentEmerald: "#00FF88"
    property color accentEmeraldHover: "#40FFB0"
    property color accentEmeraldDark: "#00AA55"
    property color accentEmeraldGlow: "#1500FF88"

    property color accentCrimson: "#FF0055"
    property color accentCrimsonHover: "#FF4080"
    property color accentCrimsonDark: "#AA0033"
    property color accentCrimsonGlow: "#15FF0055"

    property color accentAmber: "#FFAA00"
    property color accentAmberHover: "#FFCC44"
    property color accentAmberDark: "#CC8800"
    property color accentAmberGlow: "#15FFAA00"

    // ═══════════════════════════════════════════
    // NEON GLOW COLORS (for overlays/shadows)
    // ═══════════════════════════════════════════
    property color glowCyan: "#4000F0FF"
    property color glowViolet: "#40BF00FF"
    property color glowWhite: "#20FFFFFF"

    // ═══════════════════════════════════════════
    // THEME SWITCHING LOGIC
    // ═══════════════════════════════════════════
    function setTheme(themeId) {
        if (themeId === "dire") {
            // Dire: Crimson and Black
            bgVoid = "#0A0303"
            bgDark = "#120606"
            bgSidebar = "#0E0404"
            bgHeader = "#120606"
            bgCard = "#1A0909"
            bgCardHover = "#240D0D"
            bgCardActive = "#2E1111"
            bgInput = "#140707"
            bgModal = "#160808"
            bgModalOverlay = "#E0080202"
            
            borderMuted = "#2A1010"
            borderLight = "#3A1616"
            borderActive = "#4A1A1A"
            
            accentCyan = "#FF0033" // Main Accent is Crimson
            accentCyanHover = "#FF3355"
            accentCyanDark = "#AA0022"
            accentCyanGlow = "#15FF0033"
            
            accentViolet = "#FF5500" // Secondary is Orange/Amber
            accentVioletHover = "#FF7733"
            accentVioletDark = "#AA3300"
            accentVioletGlow = "#15FF5500"
            
            glowCyan = "#40FF0033"
            glowViolet = "#40FF5500"
            
        } else if (themeId === "radiant") {
            // Radiant: Emerald and Gold
            bgVoid = "#040A06"
            bgDark = "#06120A"
            bgSidebar = "#050E08"
            bgHeader = "#06120A"
            bgCard = "#091A0E"
            bgCardHover = "#0D2414"
            bgCardActive = "#112E1A"
            bgInput = "#07160C"
            bgModal = "#08180D"
            bgModalOverlay = "#E0030805"
            
            borderMuted = "#122A1A"
            borderLight = "#183A24"
            borderActive = "#204A2E"
            
            accentCyan = "#00FFAA" // Main Accent is Emerald
            accentCyanHover = "#33FFBB"
            accentCyanDark = "#00AA77"
            accentCyanGlow = "#1500FFAA"
            
            accentViolet = "#FFDD00" // Secondary is Gold
            accentVioletHover = "#FFEE33"
            accentVioletDark = "#AA9900"
            accentVioletGlow = "#15FFDD00"
            
            glowCyan = "#4000FFAA"
            glowViolet = "#40FFDD00"
            
        } else if (themeId === "true_black") {
            // True Black: Pure OLED Black with minimal contrast, keeps Cyan accent
            bgVoid = "#000000"
            bgDark = "#000000"
            bgSidebar = "#000000"
            bgHeader = "#000000"
            bgCard = "#060606"
            bgCardHover = "#0A0A0A"
            bgCardActive = "#0F0F0F"
            bgInput = "#040404"
            bgModal = "#050505"
            bgModalOverlay = "#F0000000"
            
            borderMuted = "#1A1A1A"
            borderLight = "#222222"
            borderActive = "#333333"
            
            accentCyan = "#FFFFFF" // Main Accent is White
            accentCyanHover = "#CCCCCC"
            accentCyanDark = "#888888"
            accentCyanGlow = "#15FFFFFF"
            
            accentViolet = "#444444" 
            accentVioletHover = "#666666"
            accentVioletDark = "#222222"
            accentVioletGlow = "#15444444"
            
            glowCyan = "#20FFFFFF"
            glowViolet = "#20FFFFFF"
            
        } else {
            // Cyberpunk (Default)
            bgVoid = "#04060B"
            bgDark = "#080C14"
            bgSidebar = "#06080D"
            bgHeader = "#080C14"
            bgCard = "#0C1018"
            bgCardHover = "#111620"
            bgCardActive = "#161C2A"
            bgInput = "#0A0E16"
            bgModal = "#0A0D14"
            bgModalOverlay = "#E0030508"
            
            borderMuted = "#12182A"
            borderLight = "#182236"
            borderActive = "#253450"
            
            accentCyan = "#00F0FF"
            accentCyanHover = "#40FFFF"
            accentCyanDark = "#0099AA"
            accentCyanGlow = "#1500F0FF"
            
            accentViolet = "#BF00FF"
            accentVioletHover = "#D94DFF"
            accentVioletDark = "#8000AA"
            accentVioletGlow = "#15BF00FF"
            
            glowCyan = "#4000F0FF"
            glowViolet = "#40BF00FF"
        }
    }

    // ═══════════════════════════════════════════
    // TYPOGRAPHY
    // ═══════════════════════════════════════════
    readonly property color textPrimary: "#E8ECF4"
    readonly property color textSecondary: "#7B8CA6"
    readonly property color textMuted: "#4A5670"
    readonly property color textDisabled: "#2A3346"
    readonly property color textNeon: "#00F0FF"
    readonly property color textNeonViolet: "#BF00FF"

    readonly property string fontFamily: "'Exo 2', 'Montserrat', 'Segoe UI', sans-serif"
    readonly property string fontDisplay: "'Exo 2', 'Montserrat', 'Russo One', sans-serif"
    readonly property string fontMono: "'JetBrains Mono', 'Chakra Petch', Consolas, monospace"

    // Font Sizes
    readonly property int fontSizeHeader: 22
    readonly property int fontSizeTitle: 16
    readonly property int fontSizeSub: 14
    readonly property int fontSizeBody: 13
    readonly property int fontSizeSmall: 11
    readonly property int fontSizeTiny: 10

    // ═══════════════════════════════════════════
    // RADII
    // ═══════════════════════════════════════════
    readonly property int radiusXLarge: 14
    readonly property int radiusLarge: 10
    readonly property int radiusMedium: 6
    readonly property int radiusSmall: 4
    readonly property int radiusPill: 20

    // ═══════════════════════════════════════════
    // SIDEBAR DIMENSIONS
    // ═══════════════════════════════════════════
    readonly property int sidebarCollapsed: 56
    readonly property int sidebarExpanded: 200

    // ═══════════════════════════════════════════
    // ANIMATION DURATIONS
    // ═══════════════════════════════════════════
    readonly property int animFast: 180
    readonly property int animNormal: 280
    readonly property int animSlow: 450
    readonly property int animGlitch: 80
    readonly property int animGlow: 2400
    readonly property int animScanline: 5000
}
