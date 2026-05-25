import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15

ApplicationWindow {
    id: root
    visible:     true
    visibility:  "FullScreen"
    width:       480
    height:      272
    title:       "world-clock"

    // ── Palette ───────────────────────────────────────────────────
    Material.theme:  Material.Dark
    Material.accent: "#4dd0e1"

    readonly property color bgBody:     "#0a1628"
    readonly property color bgCard:     "#132040"
    readonly property color bgActive:   "#1e3a6e"
    readonly property color accentLeft: "#4dd0e1"   // cyan-teal
    readonly property color accentRight:"#80cbc4"   // slightly warmer teal

    // ── Background ────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "#0a1628" }
            GradientStop { position: 0.5; color: "#0d1e3a" }
            GradientStop { position: 1.0; color: "#0a1628" }
        }

        // Subtle vertical vignette overlay
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#28000000" }
                GradientStop { position: 0.5; color: "transparent" }
                GradientStop { position: 1.0; color: "#44000000" }
            }
        }

        // ── Divider between the two clocks ────────────────────────
        Rectangle {
            id: divider
            width:  1
            height: parent.height * 0.72
            anchors.centerIn: parent
            color: "#22ffffff"
        }

        // ── LEFT clock ────────────────────────────────────────────
        ClockFace {
            id: leftClockFace
            anchors {
                top:    parent.top
                bottom: parent.bottom
                left:   parent.left
                right:  divider.left
            }
            clockSource:  leftClock
            location:     locationLeft
            accentColor:  root.accentLeft
            cardColor:    root.bgCard
            bgActive:     root.bgActive
        }

        // ── RIGHT clock ───────────────────────────────────────────
        ClockFace {
            id: rightClockFace
            anchors {
                top:    parent.top
                bottom: parent.bottom
                left:   divider.right
                right:  parent.right
            }
            clockSource:  rightClock
            location:     locationRight
            accentColor:  root.accentRight
            cardColor:    root.bgCard
            bgActive:     root.bgActive
        }
    }
}
