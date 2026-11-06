import AppKit

let width: CGFloat = 1280
let height: CGFloat = 640
let root = URL(fileURLWithPath: CommandLine.arguments[1])
let iconURL = root.appendingPathComponent("Support/AppIcon-1024.png")
let outputURL = root.appendingPathComponent("Support/social-preview.png")

let imageRep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(width),
    pixelsHigh: Int(height),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
)!
let graphics = NSGraphicsContext(bitmapImageRep: imageRep)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = graphics
let context = graphics.cgContext
context.setAllowsAntialiasing(true)
context.setShouldAntialias(true)
context.interpolationQuality = .high

let background = NSGradient(colors: [
    NSColor(srgbRed: 0.035, green: 0.055, blue: 0.12, alpha: 1),
    NSColor(srgbRed: 0.10, green: 0.07, blue: 0.22, alpha: 1)
])!
background.draw(in: NSRect(x: 0, y: 0, width: width, height: height), angle: -55)

let glow = NSGradient(colors: [
    NSColor(srgbRed: 0.30, green: 0.46, blue: 1.0, alpha: 0.20),
    NSColor(srgbRed: 0.30, green: 0.46, blue: 1.0, alpha: 0)
])!
glow.draw(
    in: NSBezierPath(ovalIn: NSRect(x: -380, y: -160, width: 1160, height: 1160)),
    relativeCenterPosition: .zero
)

let glowRight = NSGradient(colors: [
    NSColor(srgbRed: 0.55, green: 0.30, blue: 1.0, alpha: 0.14),
    NSColor(srgbRed: 0.55, green: 0.30, blue: 1.0, alpha: 0)
])!
glowRight.draw(
    in: NSBezierPath(ovalIn: NSRect(x: 820, y: -320, width: 1000, height: 1000)),
    relativeCenterPosition: .zero
)

if let icon = NSImage(contentsOf: iconURL) {
    icon.draw(
        in: NSRect(x: 86, y: 168, width: 300, height: 300),
        from: .zero,
        operation: .sourceOver,
        fraction: 1
    )
}

func drawText(
    _ text: String,
    rect: NSRect,
    font: NSFont,
    color: NSColor,
    lineSpacing: CGFloat = 0
) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.lineSpacing = lineSpacing
    paragraph.lineBreakMode = .byWordWrapping
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color,
        .paragraphStyle: paragraph
    ]
    (text as NSString).draw(in: rect, withAttributes: attributes)
}

drawText(
    "AreaShot",
    rect: NSRect(x: 452, y: 390, width: 760, height: 110),
    font: .systemFont(ofSize: 86, weight: .bold),
    color: .white
)

drawText(
    "Open-source macOS screenshot and annotation tool",
    rect: NSRect(x: 456, y: 316, width: 740, height: 70),
    font: .systemFont(ofSize: 30, weight: .regular),
    color: NSColor(white: 0.88, alpha: 1)
)

let accent = NSColor(srgbRed: 0.52, green: 0.68, blue: 1.0, alpha: 1)
drawText(
    "Area capture   ·   Annotate   ·   Pin   ·   Copy",
    rect: NSRect(x: 456, y: 264, width: 740, height: 36),
    font: .systemFont(ofSize: 23, weight: .medium),
    color: accent
)

let divider = NSBezierPath()
divider.move(to: NSPoint(x: 456, y: 232))
divider.line(to: NSPoint(x: 1168, y: 232))
divider.lineWidth = 1
NSColor(white: 1, alpha: 0.12).setStroke()
divider.stroke()

drawText(
    "github.com/leo-shenliang/AreaShot",
    rect: NSRect(x: 456, y: 184, width: 740, height: 30),
    font: .monospacedSystemFont(ofSize: 19, weight: .regular),
    color: NSColor(white: 0.62, alpha: 1)
)

let pill = NSBezierPath(roundedRect: NSRect(x: 1052, y: 418, width: 116, height: 36), xRadius: 18, yRadius: 18)
NSColor(white: 1, alpha: 0.10).setFill()
pill.fill()

let paragraph = NSMutableParagraphStyle()
paragraph.alignment = .center
(("v0.1.0" as NSString)).draw(
    in: NSRect(x: 1052, y: 426, width: 116, height: 24),
    withAttributes: [
        .font: NSFont.monospacedDigitSystemFont(ofSize: 17, weight: .semibold),
        .foregroundColor: accent,
        .paragraphStyle: paragraph
    ]
)

NSGraphicsContext.restoreGraphicsState()

guard let data = imageRep.representation(using: .png, properties: [:]) else {
    exit(1)
}
try data.write(to: outputURL)
print(outputURL.path)
