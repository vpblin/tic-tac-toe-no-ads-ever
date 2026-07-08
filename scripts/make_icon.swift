import AppKit

let S: CGFloat = 1024
let cs = CGColorSpaceCreateDeviceRGB()
// noneSkipLast => opaque output with no alpha channel (App Store requirement).
guard let ctx = CGContext(data: nil, width: Int(S), height: Int(S),
                          bitsPerComponent: 8, bytesPerRow: 0, space: cs,
                          bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
    fatalError("no ctx")
}

func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: cs, components: [r, g, b, a])!
}

let cyan = rgb(0.14, 0.92, 1.00)
let magenta = rgb(1.00, 0.23, 0.66)

// Background: vertical gradient, dark.
let bgTop = rgb(0.06, 0.06, 0.13)
let bgBot = rgb(0.01, 0.01, 0.04)
let grad = CGGradient(colorsSpace: cs, colors: [bgTop, bgBot] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: S), end: CGPoint(x: 0, y: 0), options: [])

// Center glow.
let glow = CGGradient(colorsSpace: cs,
                      colors: [rgb(0.14, 0.92, 1.0, 0.22), rgb(0, 0, 0, 0)] as CFArray,
                      locations: [0, 1])!
ctx.drawRadialGradient(glow, startCenter: CGPoint(x: S/2, y: S/2), startRadius: 0,
                       endCenter: CGPoint(x: S/2, y: S/2), endRadius: S*0.62, options: [])

// Grid geometry.
let margin: CGFloat = 210
let inner = S - margin * 2
let cell = inner / 3
func cx(_ col: Int) -> CGFloat { margin + (CGFloat(col) + 0.5) * cell }
func cy(_ row: Int) -> CGFloat { margin + (CGFloat(row) + 0.5) * cell }

// Grid lines (glowing cyan).
ctx.setLineCap(.round)
func withGlow(_ color: CGColor, blur: CGFloat, _ draw: () -> Void) {
    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: blur, color: color)
    draw()
    ctx.restoreGState()
}

ctx.setStrokeColor(cyan)
ctx.setLineWidth(20)
withGlow(cyan, blur: 34) {
    for i in 1...2 {
        let x = margin + CGFloat(i) * cell
        ctx.move(to: CGPoint(x: x, y: margin + 24))
        ctx.addLine(to: CGPoint(x: x, y: S - margin - 24))
        let y = margin + CGFloat(i) * cell
        ctx.move(to: CGPoint(x: margin + 24, y: y))
        ctx.addLine(to: CGPoint(x: S - margin - 24, y: y))
        ctx.strokePath()
    }
}

// Marks. Diagonal X / O / X reads clearly as tic-tac-toe.
let r = cell * 0.28

func drawX(col: Int, row: Int) {
    let x = cx(col), y = cy(row)
    ctx.setStrokeColor(cyan)
    ctx.setLineWidth(34)
    withGlow(cyan, blur: 40) {
        ctx.move(to: CGPoint(x: x - r, y: y - r))
        ctx.addLine(to: CGPoint(x: x + r, y: y + r))
        ctx.move(to: CGPoint(x: x + r, y: y - r))
        ctx.addLine(to: CGPoint(x: x - r, y: y + r))
        ctx.strokePath()
    }
}

func drawO(col: Int, row: Int) {
    let x = cx(col), y = cy(row)
    ctx.setStrokeColor(magenta)
    ctx.setLineWidth(34)
    withGlow(magenta, blur: 40) {
        ctx.addEllipse(in: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
        ctx.strokePath()
    }
}

drawX(col: 0, row: 0)
drawO(col: 1, row: 1)
drawX(col: 2, row: 2)

guard let image = ctx.makeImage() else { fatalError("no image") }
let rep = NSBitmapImageRep(cgImage: image)
guard let png = rep.representation(using: .png, properties: [:]) else { fatalError("no png") }

let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon-1024.png"
try! png.write(to: URL(fileURLWithPath: out))
print("wrote \(out)")
