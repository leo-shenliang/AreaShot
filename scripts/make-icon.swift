import AppKit
import CoreGraphics

let base: CGFloat = 1024
let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!

func srgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: colorSpace, components: [r, g, b, a])!
}

func render(size: Int) -> CGImage {
    let scale = CGFloat(size) / base
    let context = CGContext(
        data: nil,
        width: size,
        height: size,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    context.setAllowsAntialiasing(true)
    context.interpolationQuality = .high
    context.scaleBy(x: scale, y: scale)

    let square = CGRect(x: 100, y: 100, width: 824, height: 824)
    let squarePath = CGPath(
        roundedRect: square,
        cornerWidth: 185,
        cornerHeight: 185,
        transform: nil
    )

    context.saveGState()
    context.setShadow(
        offset: CGSize(width: 0, height: -14),
        blur: 36,
        color: srgb(0, 0, 0, 0.30)
    )
    context.addPath(squarePath)
    context.setFillColor(srgb(0.24, 0.38, 0.95))
    context.fillPath()
    context.restoreGState()

    context.saveGState()
    context.addPath(squarePath)
    context.clip()

    let background = CGGradient(
        colorsSpace: colorSpace,
        colors: [srgb(0.30, 0.53, 1.0), srgb(0.55, 0.27, 0.96)] as CFArray,
        locations: [0, 1]
    )!
    context.drawLinearGradient(
        background,
        start: CGPoint(x: 150, y: 920),
        end: CGPoint(x: 890, y: 120),
        options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
    )

    let halo = CGGradient(
        colorsSpace: colorSpace,
        colors: [srgb(1, 1, 1, 0.30), srgb(1, 1, 1, 0)] as CFArray,
        locations: [0, 1]
    )!
    context.drawRadialGradient(
        halo,
        startCenter: CGPoint(x: 340, y: 820),
        startRadius: 0,
        endCenter: CGPoint(x: 340, y: 820),
        endRadius: 540,
        options: []
    )
    context.restoreGState()

    let innerBorder = CGPath(
        roundedRect: square.insetBy(dx: 2, dy: 2),
        cornerWidth: 183,
        cornerHeight: 183,
        transform: nil
    )
    context.addPath(innerBorder)
    context.setStrokeColor(srgb(1, 1, 1, 0.20))
    context.setLineWidth(4)
    context.strokePath()

    let region = CGRect(x: 282, y: 318, width: 460, height: 388)
    let regionPath = CGPath(
        roundedRect: region,
        cornerWidth: 58,
        cornerHeight: 58,
        transform: nil
    )
    context.addPath(regionPath)
    context.setFillColor(srgb(1, 1, 1, 0.10))
    context.fillPath()

    let arm: CGFloat = size <= 32 ? 118 : 124
    let bracketWidth: CGFloat = size <= 32 ? 84 : 58
    let brackets = CGMutablePath()
    let minX = region.minX
    let maxX = region.maxX
    let minY = region.minY
    let maxY = region.maxY

    brackets.move(to: CGPoint(x: minX, y: maxY - arm))
    brackets.addLine(to: CGPoint(x: minX, y: maxY))
    brackets.addLine(to: CGPoint(x: minX + arm, y: maxY))

    brackets.move(to: CGPoint(x: maxX - arm, y: maxY))
    brackets.addLine(to: CGPoint(x: maxX, y: maxY))
    brackets.addLine(to: CGPoint(x: maxX, y: maxY - arm))

    brackets.move(to: CGPoint(x: maxX, y: minY + arm))
    brackets.addLine(to: CGPoint(x: maxX, y: minY))
    brackets.addLine(to: CGPoint(x: maxX - arm, y: minY))

    brackets.move(to: CGPoint(x: minX + arm, y: minY))
    brackets.addLine(to: CGPoint(x: minX, y: minY))
    brackets.addLine(to: CGPoint(x: minX, y: minY + arm))

    context.saveGState()
    context.setShadow(
        offset: CGSize(width: 0, height: -8),
        blur: 20,
        color: srgb(0.07, 0.10, 0.35, 0.35)
    )
    context.addPath(brackets)
    context.setStrokeColor(srgb(1, 1, 1))
    context.setLineWidth(bracketWidth)
    context.setLineCap(.round)
    context.setLineJoin(.round)
    context.strokePath()
    context.restoreGState()

    return context.makeImage()!
}

let arguments = CommandLine.arguments
guard arguments.count == 3 else {
    FileHandle.standardError.write(Data("usage: make-icon.swift <iconset-dir> <preview.png>\n".utf8))
    exit(1)
}

let iconset = URL(fileURLWithPath: arguments[1])
let preview = URL(fileURLWithPath: arguments[2])
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

let variants: [(Int, String)] = [
    (16, "icon_16x16.png"),
    (32, "icon_16x16@2x.png"),
    (32, "icon_32x32.png"),
    (64, "icon_32x32@2x.png"),
    (128, "icon_128x128.png"),
    (256, "icon_128x128@2x.png"),
    (256, "icon_256x256.png"),
    (512, "icon_256x256@2x.png"),
    (512, "icon_512x512.png"),
    (1024, "icon_512x512@2x.png")
]

for (size, name) in variants {
    let image = render(size: size)
    let representation = NSBitmapImageRep(cgImage: image)
    guard let data = representation.representation(using: .png, properties: [:]) else {
        exit(1)
    }
    try data.write(to: iconset.appendingPathComponent(name))
}

let previewImage = render(size: 1024)
let previewRepresentation = NSBitmapImageRep(cgImage: previewImage)
guard let previewData = previewRepresentation.representation(using: .png, properties: [:]) else {
    exit(1)
}
try previewData.write(to: preview)
print(iconset.path)
print(preview.path)
