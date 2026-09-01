pragma Singleton
import QtQuick 2.15

QtObject {
    id: theme

    // ═══════════════════════════════════════════
    // PREMIUM DARK BACKGROUNDS
    // Deep, layered surfaces with subtle blue undertones
    // ═══════════════════════════════════════════
    property color bgVoid: "#08080E"
    property color bgDark: "#0C0C14"
    property color bgSidebar: "#0A0A12"
    property color bgHeader: "#0E0E18"
    property color bgCard: "#12121C"
    property color bgCardHover: "#181824"
    property color bgCardActive: "#1E1E2C"
    property color bgInput: "#0E0E18"
    property color bgModal: "#0C0C16"
    property color bgModalOverlay: "#E0050510"
    property color bgGlass: "#50101020"
    property color bgSurface: "#14141E"
    property color bgElevated: "#1A1A28"

    // ═══════════════════════════════════════════
    // BORDERS & STROKES — Subtle, refined
    // ═══════════════════════════════════════════
    property color borderSubtle: "#14142A"
    property color borderMuted: "#1A1A32"
    property color borderLight: "#22223C"
    property color borderActive: "#2E2E4A"
    property color borderGold: "#D4A853"
    property color borderCrimson: "#E23B3B"
    property color borderCyan: "#0891b2"
    property color borderEmerald: "#22C55E"
    property color borderViolet: "#9333EA"

    // ═══════════════════════════════════════════
    // PRIMARY ACCENT — Bound to user-selected hue
    // Default: "immortal" crimson red (Dota 2 signature)
    // All UI elements reference accentCyan* properties
    // ═══════════════════════════════════════════
    property color accentCyan: "#E23B3B"
    property color accentCyanHover: "#EF5350"
    property color accentCyanDark: "#B71C1C"
    property color accentCyanGlow: "#18E23B3B"
    property color accentCyanMuted: "#22C62828"
    property color accentCyanSoft: "#30E23B3B"

    // ═══════════════════════════════════════════
    // SECONDARY ACCENT
    // ═══════════════════════════════════════════
    property color accentViolet: "#9333EA"
    property color accentVioletHover: "#A855F7"
    property color accentVioletDark: "#6B21A8"
    property color accentVioletGlow: "#189333EA"
    property color accentVioletMuted: "#229333EA"

    // ═══════════════════════════════════════════
    // STATUS COLORS
    // ═══════════════════════════════════════════
    property color accentEmerald: "#22C55E"
    property color accentEmeraldHover: "#4ADE80"
    property color accentEmeraldDark: "#15803D"
    property color accentEmeraldGlow: "#1822C55E"

    property color accentCrimson: "#EF4444"
    property color accentCrimsonHover: "#F87171"
    property color accentCrimsonDark: "#B91C1C"
    property color accentCrimsonGlow: "#18EF4444"

    property color accentAmber: "#F59E0B"
    property color accentAmberHover: "#FBBF24"
    property color accentAmberDark: "#B45309"
    property color accentAmberGlow: "#18F59E0B"

    property color accentBlue: "#3B82F6"
    property color accentBlueHover: "#60A5FA"
    property color accentBlueDark: "#1D4ED8"
    property color accentBlueGlow: "#183B82F6"

    // ═══════════════════════════════════════════
    // GLOW COLORS (for soft outer glows / shadows)
    // ═══════════════════════════════════════════
    property color glowCyan: "#30E23B3B"
    property color glowViolet: "#309333EA"
    property color glowWhite: "#14FFFFFF"

    // ═══════════════════════════════════════════
    // ACCENT HUE — USER PICKER
    // ═══════════════════════════════════════════
    property string currentThemeId: "cyberpunk"
    property string accentHue: "immortal"   // immortal | cyan | violet | emerald | amber | crimson

    // ═══════════════════════════════════════════
    // THEME SWITCHING LOGIC
    // ═══════════════════════════════════════════
    function setTheme(themeId) {
        currentThemeId = themeId
        if (themeId === "dire") {
            bgVoid = "#0A0606"
            bgDark = "#100A0A"
            bgSidebar = "#0C0808"
            bgHeader = "#120C0C"
            bgCard = "#181010"
            bgCardHover = "#201616"
            bgCardActive = "#281C1C"
            bgInput = "#120C0C"
            bgModal = "#100A0A"
            bgModalOverlay = "#E0080404"
            bgSurface = "#1A1212"
            bgElevated = "#221818"

            borderSubtle = "#241414"
            borderMuted = "#2E1A1A"
            borderLight = "#382222"
            borderActive = "#442A2A"

            accentViolet = "#FF6B35"
            accentVioletHover = "#FF8A5C"
            accentVioletDark = "#CC4400"
            accentVioletGlow = "#18FF6B35"

            glowCyan = "#30FF3333"
            glowViolet = "#30FF6B35"

        } else if (themeId === "radiant") {
            bgVoid = "#060A06"
            bgDark = "#0A100A"
            bgSidebar = "#080C08"
            bgHeader = "#0C120C"
            bgCard = "#101810"
            bgCardHover = "#162016"
            bgCardActive = "#1C281C"
            bgInput = "#0C120C"
            bgModal = "#0A100A"
            bgModalOverlay = "#E0040804"
            bgSurface = "#121A12"
            bgElevated = "#182218"

            borderSubtle = "#142414"
            borderMuted = "#1A2E1A"
            borderLight = "#223822"
            borderActive = "#2A442A"

            accentViolet = "#EAB308"
            accentVioletHover = "#FACC15"
            accentVioletDark = "#A16207"
            accentVioletGlow = "#18EAB308"

            glowCyan = "#3022C55E"
            glowViolet = "#30EAB308"

        } else if (themeId === "true_black") {
            bgVoid = "#000000"
            bgDark = "#000000"
            bgSidebar = "#000000"
            bgHeader = "#040404"
            bgCard = "#0A0A0A"
            bgCardHover = "#111111"
            bgCardActive = "#181818"
            bgInput = "#060606"
            bgModal = "#040404"
            bgModalOverlay = "#F0000000"
            bgSurface = "#0C0C0C"
            bgElevated = "#141414"

            borderSubtle = "#1A1A1A"
            borderMuted = "#222222"
            borderLight = "#2C2C2C"
            borderActive = "#383838"

            accentViolet = "#666666"
            accentVioletHover = "#888888"
            accentVioletDark = "#444444"
            accentVioletGlow = "#18666666"

            glowCyan = "#20FFFFFF"
            glowViolet = "#20888888"

        } else {
            // Cyberpunk (Default)
            bgVoid = "#08080E"
            bgDark = "#0C0C14"
            bgSidebar = "#0A0A12"
            bgHeader = "#0E0E18"
            bgCard = "#12121C"
            bgCardHover = "#181824"
            bgCardActive = "#1E1E2C"
            bgInput = "#0E0E18"
            bgModal = "#0C0C16"
            bgModalOverlay = "#E0050510"
            bgSurface = "#14141E"
            bgElevated = "#1A1A28"

            borderSubtle = "#14142A"
            borderMuted = "#1A1A32"
            borderLight = "#22223C"
            borderActive = "#2E2E4A"

            accentViolet = "#9333EA"
            accentVioletHover = "#A855F7"
            accentVioletDark = "#6B21A8"
            accentVioletGlow = "#189333EA"

            glowCyan = "#30E23B3B"
            glowViolet = "#309333EA"
        }

        applyAccentHue(accentHue)
    }

    function _themeBaseAccent(themeId) {
        if (themeId === "dire")
            return { c: "#FF3333", h: "#FF5555", d: "#CC0000", g: "#18FF3333", m: "#22DD1111" }
        if (themeId === "radiant")
            return { c: "#22C55E", h: "#4ADE80", d: "#15803D", g: "#1822C55E", m: "#2218A048" }
        if (themeId === "true_black")
            return { c: "#FFFFFF", h: "#E0E0E0", d: "#999999", g: "#18FFFFFF", m: "#22DDDDDD" }
        // cyberpunk default => immortal red
        return { c: "#E23B3B", h: "#EF5350", d: "#B71C1C", g: "#18E23B3B", m: "#22C62828" }
    }

    function applyAccentHue(hueId) {
        accentHue = hueId
        if (hueId === "cyan") {
            accentCyan = "#06B6D4"; accentCyanHover = "#22D3EE"; accentCyanDark = "#0E7490"
            accentCyanGlow = "#1806B6D4"; accentCyanMuted = "#220891B2"; accentCyanSoft = "#3006B6D4"
            glowCyan = "#3006B6D4"
        } else if (hueId === "violet") {
            accentCyan = "#9333EA"; accentCyanHover = "#A855F7"; accentCyanDark = "#6B21A8"
            accentCyanGlow = "#189333EA"; accentCyanMuted = "#227C3AED"; accentCyanSoft = "#309333EA"
            glowCyan = "#309333EA"
        } else if (hueId === "emerald") {
            accentCyan = "#22C55E"; accentCyanHover = "#4ADE80"; accentCyanDark = "#15803D"
            accentCyanGlow = "#1822C55E"; accentCyanMuted = "#2218A048"; accentCyanSoft = "#3022C55E"
            glowCyan = "#3022C55E"
        } else if (hueId === "amber") {
            accentCyan = "#F59E0B"; accentCyanHover = "#FBBF24"; accentCyanDark = "#B45309"
            accentCyanGlow = "#18F59E0B"; accentCyanMuted = "#22D97706"; accentCyanSoft = "#30F59E0B"
            glowCyan = "#30F59E0B"
        } else if (hueId === "crimson") {
            accentCyan = "#EF4444"; accentCyanHover = "#F87171"; accentCyanDark = "#B91C1C"
            accentCyanGlow = "#18EF4444"; accentCyanMuted = "#22DC2626"; accentCyanSoft = "#30EF4444"
            glowCyan = "#30EF4444"
        } else {
            // "immortal" — premium Dota 2 signature red (default)
            var base = _themeBaseAccent(currentThemeId)
            accentCyan = base.c; accentCyanHover = base.h; accentCyanDark = base.d
            accentCyanGlow = base.g; accentCyanMuted = base.m
            accentCyanSoft = base.g.replace("#18", "#30")
            glowCyan = base.g.replace("#18", "#30")
        }
    }

    // ═══════════════════════════════════════════
    // TYPOGRAPHY — Premium, readable, hierarchical
    // ═══════════════════════════════════════════
    readonly property color textPrimary: "#EAEAF0"
    readonly property color textSecondary: "#8888A0"
    readonly property color textMuted: "#555570"
    readonly property color textDisabled: "#333348"
    readonly property color textAccent: accentCyan
    readonly property color textOnAccent: "#FFFFFF"

    readonly property string fontFamily: "'Montserrat', 'Exo 2', 'Segoe UI', sans-serif"
    readonly property string fontDisplay: "'Rajdhani', 'Orbitron', 'Russo One', sans-serif"
    readonly property string fontMono: "'JetBrains Mono', Consolas, monospace"

    // Font Sizes — Larger, more breathable
    readonly property int fontSizeHero: 28
    readonly property int fontSizeHeader: 22
    readonly property int fontSizeTitle: 17
    readonly property int fontSizeSubtitle: 15
    readonly property int fontSizeBody: 13
    readonly property int fontSizeSmall: 11
    readonly property int fontSizeTiny: 9
    readonly property int fontSizeLabel: 10

    // ═══════════════════════════════════════════
    // SPACING — Consistent scale
    // ═══════════════════════════════════════════
    readonly property int spacingXS: 4
    readonly property int spacingSM: 8
    readonly property int spacingMD: 16
    readonly property int spacingLG: 24
    readonly property int spacingXL: 32
    readonly property int spacingXXL: 48

    // ═══════════════════════════════════════════
    // RADII — Larger, more modern
    // ═══════════════════════════════════════════
    readonly property int radiusXLarge: 16
    readonly property int radiusLarge: 12
    readonly property int radiusMedium: 8
    readonly property int radiusSmall: 6
    readonly property int radiusPill: 24

    // ═══════════════════════════════════════════
    // SIDEBAR DIMENSIONS
    // ═══════════════════════════════════════════
    readonly property int sidebarCollapsed: 60
    readonly property int sidebarExpanded: 220

    // ═══════════════════════════════════════════
    // ANIMATION DURATIONS — Fast & premium
    // ═══════════════════════════════════════════
    readonly property int animFast: 150
    readonly property int animNormal: 250
    readonly property int animSlow: 400
    readonly property int animEntrance: 350
    readonly property int animGlow: 2000

    // ═══════════════════════════════════════════
    // CARD DIMENSIONS
    // ═══════════════════════════════════════════
    readonly property int cardHeroHeight: 200
    readonly property int cardSkinHeight: 220
    readonly property real cardAspectRatio: 0.6  // height/width for hero cards (3:5 portrait)

    // ═══════════════════════════════════════════
    // DOTA 2 ATTRIBUTE COLORS
    // ═══════════════════════════════════════════
    readonly property color attrStr: "#EF4444"
    readonly property color attrAgi: "#22C55E"
    readonly property color attrInt: "#3B82F6"
    readonly property color attrUni: "#A855F7"

    // ═══════════════════════════════════════════
    // RARITY COLORS — Dota 2 signature tiers
    // ═══════════════════════════════════════════
    readonly property color rarityCommon: "#9CA3AF"
    readonly property color rarityUncommon: "#60A5FA"
    readonly property color rarityRare: "#3B82F6"
    readonly property color rarityMythical: "#A855F7"
    readonly property color rarityLegendary: "#EC4899"
    readonly property color rarityImmortal: "#F59E0B"
    readonly property color rarityArcana: "#EF4444"
    readonly property color rarityPersona: "#06B6D4"
}
