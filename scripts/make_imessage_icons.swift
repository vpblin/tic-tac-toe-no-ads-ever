import AppKit

// Generates every icon the iMessage app needs. Same neon language as the app
// icon (scripts/make_icon.swift), but on the landscape canvases Messages wants.
//
// Usage:
//   swift scripts/make_imessage_icons.swift \
//     "TicTacToeMessages/Assets.xcassets/iMessage App Icon.stickersiconset"

let cs = CGColorSpaceCreateDeviceRGB()

func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: cs, components: [r, g, b, a])!
}

let cyan = rgb(0.14, 0.92, 1.00)
let magenta = rgb(1.00, 0.23, 0.66)
let bgTop = rgb(0.06, 0.06, 0.13)
let bgBot = rgb(0.01, 0.01, 0.04)

/// Below this height a 3×3 grid collapses into mush, so those sizes get a
/// simplified two-mark lockup instead. Apple asks for the small icons to be
/// drawn for their size rather than shrunk.
let gridThreshold: CGFloat = 100

func withGlow(_ ctx: CGContext, _ color: CGColor, blur: CGFloat, _ draw: () -> Void) {
    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: blur, color: color)
    draw()
    ctx.restoreGState()
}

func strokeX(_ ctx: CGContext, cx: CGFloat, cy: CGFloat, r: CGFloat, lineWidth: CGFloat) {
    ctx.setStrokeColor(cyan)
    ctx.setLineWidth(lineWidth)
    withGlow(ctx, cyan, blur: r * 0.8) {
        ctx.move(to: CGPoint(x: cx - r, y: cy - r))
        ctx.addLine(to: CGPoint(x: cx + r, y: cy + r))
        ctx.move(to: CGPoint(x: cx + r, y: cy - r))
        ctx.addLine(to: CGPoint(x: cx - r, y: cy + r))
        ctx.strokePath()
    }
}

func strokeO(_ ctx: CGContext, cx: CGFloat, cy: CGFloat, r: CGFloat, lineWidth: CGFloat) {
    ctx.setStrokeColor(magenta)
    ctx.setLineWidth(lineWidth)
    withGlow(ctx, magenta, blur: r * 0.8) {
        ctx.addEllipse(in: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
        ctx.strokePath()
    }
}

/// Full board — grid rails plus a diagonal X / O / X.
func drawGrid(_ ctx: CGContext, _ W: CGFloat, _ H: CGFloat) {
    let side = H * 0.76
    let originX = (W - side) / 2
    let originY = (H - side) / 2
    let cell = side / 3
    let markRadius = cell * 0.28
    let gridWidth = side * 0.033
    let markWidth = side * 0.056
    let bleed = side * 0.04

    func cx(_ col: Int) -> CGFloat { originX + (CGFloat(col) + 0.5) * cell }
    func cy(_ row: Int) -> CGFloat { originY + (CGFloat(row) + 0.5) * cell }

    ctx.setLineCap(.round)
    ctx.setStrokeColor(cyan)
    ctx.setLineWidth(gridWidth)
    withGlow(ctx, cyan, blur: side * 0.055) {
        for i in 1...2 {
            let x = originX + CGFloat(i) * cell
            ctx.move(to: CGPoint(x: x, y: originY + bleed))
            ctx.addLine(to: CGPoint(x: x, y: originY + side - bleed))
            let y = originY + CGFloat(i) * cell
            ctx.move(to: CGPoint(x: originX + bleed, y: y))
            ctx.addLine(to: CGPoint(x: originX + side - bleed, y: y))
            ctx.strokePath()
        }
    }

    strokeX(ctx, cx: cx(0), cy: cy(0), r: markRadius, lineWidth: markWidth)
    strokeO(ctx, cx: cx(1), cy: cy(1), r: markRadius, lineWidth: markWidth)
    strokeX(ctx, cx: cx(2), cy: cy(2), r: markRadius, lineWidth: markWidth)
}

/// Small sizes — one X, one O, no grid. Reads at 54×40.
func drawLockup(_ ctx: CGContext, _ W: CGFloat, _ H: CGFloat) {
    let r = H * 0.20
    let offset = H * 0.24
    let lineWidth = max(2, r * 0.42)

    ctx.setLineCap(.round)
    strokeX(ctx, cx: W / 2 - offset, cy: H / 2, r: r, lineWidth: lineWidth)
    strokeO(ctx, cx: W / 2 + offset, cy: H / 2, r: r, lineWidth: lineWidth)
}

func makeIcon(width: Int, height: Int) -> Data {
    let W = CGFloat(width), H = CGFloat(height)
    // noneSkipLast => opaque, no alpha channel (App Store requirement).
    guard let ctx = CGContext(data: nil, width: width, height: height,
                              bitsPerComponent: 8, bytesPerRow: 0, space: cs,
                              bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
        fatalError("no context for \(width)×\(height)")
    }

    let grad = CGGradient(colorsSpace: cs, colors: [bgTop, bgBot] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: H), end: CGPoint(x: 0, y: 0), options: [])

    let glow = CGGradient(colorsSpace: cs,
                          colors: [rgb(0.14, 0.92, 1.0, 0.22), rgb(0, 0, 0, 0)] as CFArray,
                          locations: [0, 1])!
    ctx.drawRadialGradient(glow, startCenter: CGPoint(x: W / 2, y: H / 2), startRadius: 0,
                           endCenter: CGPoint(x: W / 2, y: H / 2), endRadius: max(W, H) * 0.62,
                           options: [])

    if H >= gridThreshold {
        drawGrid(ctx, W, H)
    } else {
        drawLockup(ctx, W, H)
    }

    guard let image = ctx.makeImage(),
          let png = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])
    else { fatalError("no png for \(width)×\(height)") }
    return png
}

// Every slot in iMessage App Icon.stickersiconset, as (filename, pixel size).
let icons: [(String, Int, Int)] = [
    ("icon-29@2x.png", 58, 58),
    ("icon-29@3x.png", 87, 87),
    ("icon-ipad-29@2x.png", 58, 58),
    ("icon-27x20@2x.png", 54, 40),
    ("icon-27x20@3x.png", 81, 60),
    ("icon-32x24@2x.png", 64, 48),
    ("icon-32x24@3x.png", 96, 72),
    ("icon-60x45@2x.png", 120, 90),
    ("icon-60x45@3x.png", 180, 135),
    ("icon-67x50@2x.png", 134, 100),
    ("icon-74x55@2x.png", 148, 110),
    ("icon-1024x768.png", 1024, 768),
]

let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."
for (name, w, h) in icons {
    let url = URL(fileURLWithPath: outDir).appendingPathComponent(name)
    try! makeIcon(width: w, height: h).write(to: url)
    print("wrote \(name) (\(w)×\(h))")
}
