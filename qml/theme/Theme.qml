pragma Singleton

import QtQuick

QtObject {
    // ============================================================
    //  VOID — Design System
    //  All colors, fonts, sizes, and durations in one place.
    //  Never write a raw hex or hardcoded number in components again.
    // ============================================================

    // ---------- BACKGROUNDS ----------
    readonly property color bgVoid:     "#05060D"   // deepest — window base
    readonly property color bgDeep:     "#0A0A14"   // sidebar / chrome
    readonly property color bgPanel:    "#12121F"   // cards, panels
    readonly property color bgElevated: "#1A1A28"   // hovered card, menu
    readonly property color bgPressed:  "#22222E"   // pressed state

    // ---------- SURFACES (opaque, safe from platform tinting) ----------
    readonly property color surfaceHover:   "#1A1A24"
    readonly property color surfaceActive:  "#22222E"
    readonly property color surfacePressed: "#2A2A36"

    // ---------- TEXT ----------
    readonly property color textPrimary:   "#F2F2F7"
    readonly property color textSecondary: "#8A8AA0"
    readonly property color textMuted:     "#55556A"
    readonly property color textDisabled:  "#3A3A4A"

    // ---------- ACCENTS ----------
    readonly property color accentCyan:    "#22D3EE"
    readonly property color accentBlue:    "#3B82F6"
    readonly property color accentPurple:  "#A78BFA"
    readonly property color accentViolet:  "#8B5CF6"
    readonly property color accentMagenta: "#E879F9"
    readonly property color accentPink:    "#F472B6"

    // ---------- ACCENT ALPHA VARIANTS ----------
    // NOTE: In Qt QML, 8-digit hex is #AARRGGBB (alpha FIRST).
    // Use these instead of #ffffffXX — they don't get tinted by KDE.
    readonly property color cyan10:  "#1A22D3EE"
    readonly property color cyan15:  "#2622D3EE"
    readonly property color cyan20:  "#3322D3EE"
    readonly property color cyan25:  "#4022D3EE"
    readonly property color cyan35:  "#5922D3EE"

    readonly property color purple10:  "#1AA78BFA"
    readonly property color purple15:  "#26A78BFA"
    readonly property color purple20:  "#33A78BFA"
    readonly property color purple25:  "#40A78BFA"
    readonly property color purple35:  "#59A78BFA"

    readonly property color magenta20: "#33E879F9"
    readonly property color pink20:    "#33F472B6"

    // ---------- BORDERS ----------
    readonly property color borderSubtle: "#FFFFFF0D"   // 5% white
    readonly property color borderNormal: "#FFFFFF14"   // 8% white
    readonly property color borderStrong: "#FFFFFF26"   // 15% white

    // ---------- FONTS ----------
    readonly property string fontFamily:     "Inter"
    readonly property string fontMonoFamily: "JetBrains Mono"

    readonly property int fontTiny:     10
    readonly property int fontSmall:    11
    readonly property int fontBody:     13
    readonly property int fontBodyLg:   14
    readonly property int fontSubtitle: 16
    readonly property int fontTitle:    22
    readonly property int fontHeading:  28
    readonly property int fontDisplay:  40
    readonly property int fontMega:     64

    // ---------- RADII ----------
    readonly property int radiusXs:   4
    readonly property int radiusSm:   6
    readonly property int radiusMd:   10
    readonly property int radiusLg:   14
    readonly property int radiusXl:   20
    readonly property int radiusPill: 999

    // ---------- SPACING ----------
    readonly property int spaceXs:  4
    readonly property int spaceSm:  8
    readonly property int spaceMd:  12
    readonly property int spaceLg:  16
    readonly property int spaceXl:  24
    readonly property int space2xl: 32
    readonly property int space3xl: 48

    // ---------- LAYOUT ----------
    readonly property int sidebarWidth:  220
    readonly property int topBarHeight:  60
    readonly property int playerHeight:  96

    // ---------- ANIMATION DURATIONS (ms) ----------
    readonly property int animFast:   120
    readonly property int animNormal: 200
    readonly property int animSlow:   320
    readonly property int animGlacial: 600

    // ---------- GLOW INTENSITY (MultiEffect shadowBlur) ----------
    readonly property real glowSoft:    0.5
    readonly property real glowMedium:  0.8
    readonly property real glowStrong:  1.0

    // ---------- OPACITY ----------
    readonly property real opacityDisabled: 0.4
    readonly property real opacitySubtle:   0.6
}