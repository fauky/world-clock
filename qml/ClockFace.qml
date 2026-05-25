import QtQuick 2.15
import QtQuick.Controls 2.15
import QtGraphicalEffects 1.15

Item {
    id: root

    // ── Public API ────────────────────────────────────────────────
    property var    clockSource   : null     // a ClockProvider instance
    property string location      : "City"
    property color  accentColor   : "#4dd0e1"
    property color  digitalColor  : '#ffea00'
    property color  cardColor     : "#132040"
    property color  bgActive      : "#1e3a6e"

    // ── Internals ─────────────────────────────────────────────────
    readonly property int   _h  : clockSource ? clockSource.hours   : 0
    readonly property int   _m  : clockSource ? clockSource.minutes : 0
    readonly property int   _s  : clockSource ? clockSource.seconds : 0
    readonly property string _d : clockSource ? clockSource.digital : "00:00:00"
    readonly property string _ampm : clockSource ? clockSource.ampm : "AM"

    // Smooth angle helpers (no jump at 0)
    readonly property real hourAngle  : (_h * 30) + (_m * 0.5)   // 360/12 = 30 deg per hr
    readonly property real minuteAngle: _m * 6                    // 360/60 = 6 deg per min
    readonly property real secondAngle: _s * 6                    // 360/60 = 6 deg per sec

    // ── Root column: location label + clock card + digital ────────
    Column {
        anchors.fill: parent
        anchors.topMargin: 2
        spacing: 0

        // ── Location label ────────────────────────────────────────
        Item {
            width:  parent.width
            height: parent.height * 0.15

            Text {
                anchors.centerIn: parent
                text:      root.location
                color:     root.digitalColor
                font {
                    pixelSize:   parent.height * 0.65
                    family:      "Amiri"
                }
            }
        }

        // ── Analog clock ──────────────────────────────────────────
        Item {
            width:  parent.width
            height: parent.height * 0.68

            // Card / bezel
            Rectangle {
                id: clockCard
                anchors.centerIn: parent
                width:  Math.min(parent.width, parent.height) * 0.92
                height: width
                radius: width / 2
                color:  root.cardColor

                // Outer ring gradient simulation
                border.color: Qt.rgba(root.accentColor.r,
                                      root.accentColor.g,
                                      root.accentColor.b, 0.55)
                border.width: 2

                // ── Canvas: dial face ─────────────────────────────
                Canvas {
                    id: dialCanvas
                    anchors.fill: parent
                    anchors.margins: 4

                    property real acR: root.accentColor.r
                    property real acG: root.accentColor.g
                    property real acB: root.accentColor.b

                    // Repaint only when time changes (seconds tick)
                    Connections {
                        target: root.clockSource
                        function onTimeChanged() { dialCanvas.requestPaint() }
                    }

                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.reset()

                        var cx = width  / 2
                        var cy = height / 2
                        var r  = Math.min(width, height) / 2

                        // ── Background fill ───────────────────────
                        var bgGrad = ctx.createRadialGradient(cx, cy, r * 0.1,
                                                              cx, cy, r)
                        bgGrad.addColorStop(0,   "#1a2f55")
                        bgGrad.addColorStop(1,   "#0a1628")
                        ctx.fillStyle = bgGrad
                        ctx.beginPath()
                        ctx.arc(cx, cy, r, 0, Math.PI * 2)
                        ctx.fill()

                        // ── Outer accent ring ─────────────────────
                        ctx.strokeStyle = "rgba(" +
                            Math.round(acR*255) + "," +
                            Math.round(acG*255) + "," +
                            Math.round(acB*255) + ",0.7)"
                        ctx.lineWidth = 2.5
                        ctx.beginPath()
                        ctx.arc(cx, cy, r - 2, 0, Math.PI * 2)
                        ctx.stroke()

                        // ── Hour ticks + numerals ─────────────────
                        for (var i = 0; i < 12; i++) {
                            var a    = (i * Math.PI / 6) - Math.PI / 2
                            var isMaj = true   // all 12 are major on small dial

                            // Tick line
                            var x1 = cx + Math.cos(a) * (r - 5)
                            var y1 = cy + Math.sin(a) * (r - 5)
                            var x2 = cx + Math.cos(a) * (r - 10)
                            var y2 = cy + Math.sin(a) * (r - 10)

                            ctx.strokeStyle = "rgba(" +
                                Math.round(acR*255) + "," +
                                Math.round(acG*255) + "," +
                                Math.round(acB*255) + ",0.9)"
                            ctx.lineWidth = 2.5
                            ctx.beginPath()
                            ctx.moveTo(x1, y1)
                            ctx.lineTo(x2, y2)
                            ctx.stroke()

                            // Hour numerals – small font to fit dial
                            var num = (i === 0) ? 12 : i
                            var nx  = cx + Math.cos(a) * (r - 22)
                            var ny  = cy + Math.sin(a) * (r - 22) + 4
                            ctx.fillStyle = "rgba(212,175,55,0.85)"
                            ctx.font = "bold " + Math.round(r * 0.22) + "px sans-serif"
                            ctx.textAlign    = "center"
                            ctx.textBaseline = "middle"
                            ctx.fillText(num.toString(), nx, ny)
                        }

                        // ── Minute ticks ──────────────────────────
                        for (var j = 0; j < 60; j++) {
                            if (j % 5 === 0) continue   // skip where hour ticks are
                            var ma  = (j * Math.PI / 30) - Math.PI / 2
                            var mx1 = cx + Math.cos(ma) * (r - 5)
                            var my1 = cy + Math.sin(ma) * (r - 5)
                            var mx2 = cx + Math.cos(ma) * (r - 10)
                            var my2 = cy + Math.sin(ma) * (r - 10)
                            ctx.strokeStyle = "rgba(" +
                                Math.round(acR*255) + "," +
                                Math.round(acG*255) + "," +
                                Math.round(acB*255) + ",0.7)"
                            ctx.lineWidth = 1
                            ctx.beginPath()
                            ctx.moveTo(mx1, my1)
                            ctx.lineTo(mx2, my2)
                            ctx.stroke()
                        }

                        // ── Hour hand ─────────────────────────────
                        var hrA = (root.hourAngle - 90) * Math.PI / 180
                        drawHand(ctx, cx, cy, hrA, r * 0.45, 5,
                                 "rgba(220,235,255,0.95)", true)

                        // ── Minute hand ───────────────────────────
                        var mnA = (root.minuteAngle - 90) * Math.PI / 180
                        drawHand(ctx, cx, cy, mnA, r * 0.65, 4,
                                 "rgba(180,215,255,0.9)", true)

                        // ── Second hand ───────────────────────────
                        var scA = (root.secondAngle - 90) * Math.PI / 180
                        // tail
                        ctx.strokeStyle = "rgba(255,0,0,0.9)" // bright red, slightly transparent for tail
                        ctx.lineWidth = 1.6
                        ctx.beginPath()
                        ctx.moveTo(cx, cy)
                        ctx.lineTo(cx + Math.cos(scA + Math.PI) * r * 0.18,
                                   cy + Math.sin(scA + Math.PI) * r * 0.18)
                        ctx.stroke()
                        // main
                        ctx.strokeStyle = "rgba(255,0,0,1.0)" // bright red, fully opaque for main
                        ctx.lineWidth = 1.6
                        ctx.beginPath()
                        ctx.moveTo(cx, cy)
                        ctx.lineTo(cx + Math.cos(scA) * r * 0.78,
                                   cy + Math.sin(scA) * r * 0.78)
                        ctx.stroke()

                        // ── Centre dot ────────────────────────────
                        var dotGrad = ctx.createRadialGradient(cx, cy, 0, cx, cy, 5)
                        dotGrad.addColorStop(0, "rgba(255,255,255,1)")
                        dotGrad.addColorStop(1, "rgba(" +
                            Math.round(acR*255) + "," +
                            Math.round(acG*255) + "," +
                            Math.round(acB*255) + ",0.8)")
                        ctx.fillStyle = dotGrad
                        ctx.beginPath()
                        ctx.arc(cx, cy, 4, 0, Math.PI * 2)
                        ctx.fill()
                    }

                    // Helper: draw a tapered clock hand with a subtle glow cap
                    function drawHand(ctx, cx, cy, angle, length, width, color, rounded) {
                        ctx.save()
                        ctx.translate(cx, cy)
                        ctx.rotate(angle)
                        ctx.strokeStyle = color
                        ctx.lineWidth   = width
                        ctx.lineCap     = rounded ? "round" : "butt"
                        ctx.shadowColor  = color
                        ctx.shadowBlur   = 6
                        ctx.beginPath()
                        ctx.moveTo(0, 0)
                        ctx.lineTo(length, 0)
                        ctx.stroke()
                        ctx.restore()
                    }
                }   // Canvas
            }   // clockCard Rectangle

            // Outer glow ring using a semi-transparent border rect
            Rectangle {
                anchors.centerIn: parent
                width:  clockCard.width  + 12
                height: clockCard.height + 12
                radius: width / 2
                color:  "transparent"
                border.color: Qt.rgba(root.accentColor.r,
                                      root.accentColor.g,
                                      root.accentColor.b, 0.18)
                border.width: 6
            }
        }   // analog clock Item

        // ── Digital readout ───────────────────────────────────────
        Item {
            width:  parent.width
            height: parent.height * 0.17

            Rectangle {

                anchors.centerIn: parent
                width:  parent.width
                height: parent.height
                radius: 5
                color: "transparent"

                Text {
                    id: timeText
                    anchors.centerIn: parent
                    text: root._d
                    color: root.digitalColor
                    font {
                        pixelSize:   parent.height * 0.85
                        family:      "Share Tech Mono"
                        bold:        true
                        letterSpacing: 1.5
                    }
                }

                Text {
                    id: ampmText
                    anchors.left: timeText.right
                    anchors.leftMargin: 8
                    anchors.baseline: timeText.baseline
                    text: root._ampm
                    color: root.digitalColor
                    font {
                        pixelSize:   parent.height * 0.45
                        family:      "Share Tech Mono"
                        bold:        true
                        letterSpacing: 1.5
                    }
                }
            }
        }
    }   // Column
}
