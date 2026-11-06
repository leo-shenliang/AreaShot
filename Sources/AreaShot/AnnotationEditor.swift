import AppKit
import CoreImage

enum AnnotationTool: Int, CaseIterable {
    case select
    case arrow
    case line
    case rectangle
    case ellipse
    case pen
    case highlight
    case text
    case counter
    case spotlight
    case loupe
    case pixelate
    case blur
    case redact

    var title: String {
        switch self {
        case .select: return "选择"
        case .arrow: return "箭头"
        case .line: return "直线"
        case .rectangle: return "矩形"
        case .ellipse: return "椭圆"
        case .pen: return "画笔"
        case .highlight: return "高亮"
        case .text: return "文字"
        case .counter: return "序号"
        case .spotlight: return "聚光灯"
        case .loupe: return "放大镜"
        case .pixelate: return "马赛克"
        case .blur: return "模糊"
        case .redact: return "遮盖"
        }
    }

    var symbolName: String {
        switch self {
        case .select: return "cursorarrow"
        case .arrow: return "arrow.up.right"
        case .line: return "line.diagonal"
        case .rectangle: return "rectangle"
        case .ellipse: return "circle"
        case .pen: return "pencil.tip"
        case .highlight: return "highlighter"
        case .text: return "textformat"
        case .counter: return "number.circle"
        case .spotlight: return "flashlight.on.fill"
        case .loupe: return "magnifyingglass"
        case .pixelate: return "square.grid.3x3"
        case .blur: return "camera.filters"
        case .redact: return "rectangle.fill"
        }
    }
}

enum TextStyle: Int, CaseIterable {
    case standard
    case roundedBox
    case monospaced
    case outline

    var title: String {
        switch self {
        case .standard: return "标准"
        case .roundedBox: return "圆角框"
        case .monospaced: return "等宽"
        case .outline: return "描边"
        }
    }
}

enum ArrowStyle: Int, CaseIterable {
    case standard
    case double
    case fancy

    var title: String {
        switch self {
        case .standard: return "标准"
        case .double: return "双头"
        case .fancy: return "曲线"
        }
    }
}

enum SpotlightShape: Int, CaseIterable {
    case ellipse
    case rectangle

    var title: String {
        switch self {
        case .ellipse: return "椭圆"
        case .rectangle: return "矩形"
        }
    }

    var symbolName: String {
        switch self {
        case .ellipse: return "circle"
        case .rectangle: return "rectangle"
        }
    }
}

enum FontDesignOption: Int, CaseIterable {
    case system
    case rounded
    case serif
    case monospaced

    var title: String {
        switch self {
        case .system: return "系统"
        case .rounded: return "圆角"
        case .serif: return "衬线"
        case .monospaced: return "等宽"
        }
    }

    var systemDesign: NSFontDescriptor.SystemDesign? {
        switch self {
        case .system: return nil
        case .rounded: return .rounded
        case .serif: return .serif
        case .monospaced: return .monospaced
        }
    }
}

enum FontWeightOption: Int, CaseIterable {
    case regular
    case medium
    case semibold
    case bold

    var title: String {
        switch self {
        case .regular: return "常规"
        case .medium: return "中等"
        case .semibold: return "半粗"
        case .bold: return "粗体"
        }
    }

    var weight: NSFont.Weight {
        switch self {
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        }
    }
}

enum TextAlignmentOption: Int, CaseIterable {
    case left
    case center
    case right

    var title: String {
        switch self {
        case .left: return "左对齐"
        case .center: return "居中"
        case .right: return "右对齐"
        }
    }

    var alignment: NSTextAlignment {
        switch self {
        case .left: return .left
        case .center: return .center
        case .right: return .right
        }
    }
}

struct Annotation: Identifiable {
    enum Kind {
        case arrow
        case line
        case rectangle
        case ellipse
        case text
        case pixelate
        case blur
        case redact
        case pen
        case highlight
        case counter
        case spotlight
        case loupe
        case image
    }

    let id: UUID
    let kind: Kind
    var start: CGPoint
    var end: CGPoint
    var points: [CGPoint]
    var color: NSColor
    var lineWidth: CGFloat
    var text: String
    var fontSize: CGFloat
    var textStyle: TextStyle
    var textAlignment: TextAlignmentOption
    var fontWeight: FontWeightOption
    var fontDesign: FontDesignOption
    var arrowStyle: ArrowStyle
    var counterValue: Int
    var image: CGImage?
    var isLocked: Bool
    var isHidden: Bool
    var spotlightOpacity: CGFloat
    var intensity: CGFloat
    var spotlightShape: SpotlightShape

    init(
        id: UUID = UUID(),
        kind: Kind,
        start: CGPoint,
        end: CGPoint,
        points: [CGPoint] = [],
        color: NSColor,
        lineWidth: CGFloat,
        text: String = "",
        fontSize: CGFloat = 28,
        textStyle: TextStyle = .standard,
        textAlignment: TextAlignmentOption = .left,
        fontWeight: FontWeightOption = .semibold,
        fontDesign: FontDesignOption = .system,
        arrowStyle: ArrowStyle = .standard,
        counterValue: Int = 0,
        image: CGImage? = nil,
        isLocked: Bool = false,
        isHidden: Bool = false,
        spotlightOpacity: CGFloat = 0.55,
        intensity: CGFloat = 12,
        spotlightShape: SpotlightShape = .ellipse
    ) {
        self.id = id
        self.kind = kind
        self.start = start
        self.end = end
        self.points = points
        self.color = color
        self.lineWidth = lineWidth
        self.text = text
        self.fontSize = fontSize
        self.textStyle = textStyle
        self.textAlignment = textAlignment
        self.fontWeight = fontWeight
        self.fontDesign = fontDesign
        self.arrowStyle = arrowStyle
        self.counterValue = counterValue
        self.image = image
        self.isLocked = isLocked
        self.isHidden = isHidden
        self.spotlightOpacity = spotlightOpacity
        self.intensity = intensity
        self.spotlightShape = spotlightShape
    }

    var displayName: String {
        switch kind {
        case .arrow: return "箭头"
        case .line: return "直线"
        case .rectangle: return "矩形"
        case .ellipse: return "椭圆"
        case .text: return text.isEmpty ? "文字" : "文字：\(text.prefix(18))"
        case .pixelate: return "马赛克"
        case .blur: return "模糊"
        case .redact: return "遮盖"
        case .pen: return "画笔"
        case .highlight: return "高亮"
        case .counter: return "序号 \(counterValue)"
        case .spotlight: return "聚光灯"
        case .loupe: return "放大镜"
        case .image: return "图片"
        }
    }
}

final class AnnotationCanvasView: NSView {
    private enum ResizeHandle: CaseIterable {
        case topLeft
        case top
        case topRight
        case right
        case bottomRight
        case bottom
        case bottomLeft
        case left

        var affectsLeft: Bool { self == .topLeft || self == .left || self == .bottomLeft }
        var affectsRight: Bool { self == .topRight || self == .right || self == .bottomRight }
        var affectsTop: Bool { self == .topLeft || self == .top || self == .topRight }
        var affectsBottom: Bool { self == .bottomLeft || self == .bottom || self == .bottomRight }
    }

    let baseImage: CGImage
    private(set) var displayScale: CGFloat

    var onMagnify: ((CGFloat) -> Void)?

    var tool: AnnotationTool = .select {
        didSet {
            if tool != .select {
                selectedAnnotationIDs.removeAll()
            }
            window?.invalidateCursorRects(for: self)
            needsDisplay = true
        }
    }
    var currentColor: NSColor = .systemRed
    var currentLineWidth: CGFloat = 3
    var currentTextStyle: TextStyle = .standard
    var currentFontSize: CGFloat = 28
    var currentArrowStyle: ArrowStyle = .standard
    var currentFontDesign: FontDesignOption = .system
    var currentFontWeight: FontWeightOption = .semibold
    var currentTextAlignment: TextAlignmentOption = .left
    var currentSpotlightOpacity: CGFloat = 0.55
    var currentSpotlightShape: SpotlightShape = .ellipse
    var currentPixelateIntensity: CGFloat = 12
    var currentBlurIntensity: CGFloat = 14

    private(set) var annotations: [Annotation] = []
    private(set) var selectedAnnotationIDs: Set<UUID> = []
    private var nextCounterValue = 1

    private var draftStart: CGPoint?
    private var draftEnd: CGPoint?
    private var draftPoints: [CGPoint] = []
    private var dragStarted = false

    private var activeTextView: NSTextView?
    private var activeResizeHandle: TextResizeHandle?
    private var activeTextRect: CGRect = .zero
    private var editingAnnotationID: UUID?
    private var editingTextStyle: TextStyle?
    private var editingFontSize: CGFloat?
    private var editingTextColor: NSColor?
    private var editingFontDesign: FontDesignOption?
    private var editingFontWeight: FontWeightOption?
    private var editingTextAlignment: TextAlignmentOption?
    private var autoGrowText = false

    private var manipulationOriginals: [UUID: Annotation] = [:]
    private var manipulationStart: CGPoint = .zero
    private var activeHandle: ResizeHandle?
    private var movingSelection = false
    private var didManipulate = false

    private var copiedAnnotations: [Annotation] = []

    private let canvasUndoManager = UndoManager()
    private let ciContext = CIContext()

    private lazy var pixelateCache: [CGFloat: CGImage] = [:]
    private var pixelateCacheOrder: [CGFloat] = []
    private var blurCache: [CGFloat: CGImage] = [:]
    private var blurCacheOrder: [CGFloat] = []

    private func pixelatedImage(intensity: CGFloat) -> CGImage? {
        let key = max(2, intensity.rounded())
        if let cached = pixelateCache[key] {
            return cached
        }
        let input = CIImage(cgImage: baseImage)
        guard let filter = CIFilter(name: "CIPixellate") else { return nil }
        filter.setValue(input, forKey: kCIInputImageKey)
        filter.setValue(key, forKey: kCIInputScaleKey)
        guard let output = filter.outputImage?.cropped(to: input.extent),
              let image = ciContext.createCGImage(output, from: input.extent)
        else {
            return nil
        }
        pixelateCache[key] = image
        pixelateCacheOrder.append(key)
        if pixelateCacheOrder.count > 6 {
            pixelateCache.removeValue(forKey: pixelateCacheOrder.removeFirst())
        }
        return image
    }

    private func blurredImage(intensity: CGFloat) -> CGImage? {
        let key = max(2, intensity.rounded())
        if let cached = blurCache[key] {
            return cached
        }
        let extent = CIImage(cgImage: baseImage).extent
        let input = CIImage(cgImage: baseImage).clampedToExtent()
        guard let filter = CIFilter(name: "CIGaussianBlur") else { return nil }
        filter.setValue(input, forKey: kCIInputImageKey)
        filter.setValue(key, forKey: kCIInputRadiusKey)
        guard let output = filter.outputImage?.cropped(to: extent),
              let image = ciContext.createCGImage(output, from: extent)
        else {
            return nil
        }
        blurCache[key] = image
        blurCacheOrder.append(key)
        if blurCacheOrder.count > 6 {
            blurCache.removeValue(forKey: blurCacheOrder.removeFirst())
        }
        return image
    }

    init(image: CGImage, displayScale: CGFloat) {
        self.baseImage = image
        self.displayScale = displayScale
        super.init(frame: NSRect(
            x: 0,
            y: 0,
            width: CGFloat(image.width) * displayScale,
            height: CGFloat(image.height) * displayScale
        ))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var acceptsFirstResponder: Bool { true }
    override var undoManager: UndoManager? { canvasUndoManager }

    func setDisplayScale(_ scale: CGFloat) {
        displayScale = scale
        setFrameSize(NSSize(
            width: CGFloat(baseImage.width) * scale,
            height: CGFloat(baseImage.height) * scale
        ))
        needsDisplay = true
    }

    override func magnify(with event: NSEvent) {
        onMagnify?(event.magnification)
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        updateLayerContentsScale()
    }

    override func viewDidChangeBackingProperties() {
        super.viewDidChangeBackingProperties()
        updateLayerContentsScale()
    }

    private func updateLayerContentsScale() {
        let scale = window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 2
        layer?.contentsScale = scale
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: tool == .select ? .arrow : .crosshair)
    }

    override func keyDown(with event: NSEvent) {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if flags.contains(.command), let key = event.charactersIgnoringModifiers?.lowercased() {
            if key == "z" {
                if flags.contains(.shift) {
                    canvasUndoManager.redo()
                } else {
                    canvasUndoManager.undo()
                }
                needsDisplay = true
                return
            }
            if key == "c" {
                copySelection()
                return
            }
            if key == "v" {
                pasteSelection()
                return
            }
            if key == "d" {
                duplicateSelection()
                return
            }
            if key == "]" {
                moveSelection(by: 1)
                return
            }
            if key == "[" {
                moveSelection(by: -1)
                return
            }
            if key == "=" || key == "+" {
                changeTextSize(by: 2)
                return
            }
            if key == "-" {
                changeTextSize(by: -2)
                return
            }
        }
        if event.keyCode == 51 || event.keyCode == 117 {
            deleteSelection()
            return
        }
        super.keyDown(with: event)
    }

    override func mouseMoved(with event: NSEvent) {
        guard activeTextView == nil else { return }
        let point = imagePoint(convert(event.locationInWindow, from: nil))
        if tool == .select {
            if let primary = primarySelection(),
               hitTestHandle(at: point, annotation: primary.annotation) != nil {
                NSCursor.crosshair.set()
            } else if annotation(at: point) != nil {
                NSCursor.openHand.set()
            } else {
                NSCursor.arrow.set()
            }
        } else {
            NSCursor.crosshair.set()
        }
    }

    override func mouseDown(with event: NSEvent) {
        if activeTextView != nil {
            commitTextInput()
            return
        }
        window?.makeFirstResponder(self)
        let point = imagePoint(convert(event.locationInWindow, from: nil))

        switch tool {
        case .select:
            beginSelectionInteraction(at: point, event: event)
        case .text:
            if let existing = textAnnotation(at: point) {
                beginEditing(existing)
            } else {
                beginTextInput(at: point)
            }
        case .pen, .highlight:
            draftStart = point
            draftEnd = point
            draftPoints = [point]
            dragStarted = false
            needsDisplay = true
        case .counter:
            addCounter(at: point)
        case .arrow, .line, .rectangle, .ellipse, .spotlight, .loupe, .pixelate, .blur, .redact:
            draftStart = point
            draftEnd = point
            dragStarted = false
            needsDisplay = true
        }
    }

    override func mouseDragged(with event: NSEvent) {
        if !manipulationOriginals.isEmpty {
            let point = imagePoint(convert(event.locationInWindow, from: nil))
            if activeHandle != nil {
                updateResize(to: point)
            } else if movingSelection {
                updateMove(to: point)
            }
            return
        }
        guard let start = draftStart else { return }
        let point = imagePoint(convert(event.locationInWindow, from: nil))
        if hypot(point.x - start.x, point.y - start.y) > 3 {
            dragStarted = true
        }
        if tool == .pen || tool == .highlight {
            draftPoints.append(point)
        }
        draftEnd = point
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        if !manipulationOriginals.isEmpty {
            finishManipulation()
            return
        }
        guard let start = draftStart else { return }
        let end = imagePoint(convert(event.locationInWindow, from: nil))
        let points = draftPoints
        draftStart = nil
        draftEnd = nil
        draftPoints = []

        let distance = hypot(end.x - start.x, end.y - start.y)
        let rect = standardizedRect(from: start, to: end)

        switch tool {
        case .arrow:
            if distance > 4 {
                add(Annotation(
                    kind: .arrow,
                    start: start,
                    end: end,
                    color: currentColor,
                    lineWidth: currentLineWidth,
                    arrowStyle: currentArrowStyle
                ))
            }
        case .line:
            if distance > 4 {
                add(Annotation(
                    kind: .line,
                    start: start,
                    end: end,
                    color: currentColor,
                    lineWidth: currentLineWidth
                ))
            }
        case .rectangle:
            if rect.width > 3, rect.height > 3 {
                add(rectAnnotation(kind: .rectangle, rect: rect))
            }
        case .ellipse:
            if rect.width > 3, rect.height > 3 {
                add(rectAnnotation(kind: .ellipse, rect: rect))
            }
        case .spotlight:
            if rect.width > 3, rect.height > 3 {
                add(rectAnnotation(kind: .spotlight, rect: rect))
            }
        case .loupe:
            if rect.width > 3, rect.height > 3 {
                add(rectAnnotation(kind: .loupe, rect: rect))
            }
        case .pixelate:
            if rect.width > 3, rect.height > 3 {
                add(rectAnnotation(kind: .pixelate, rect: rect))
            }
        case .blur:
            if rect.width > 3, rect.height > 3 {
                add(rectAnnotation(kind: .blur, rect: rect))
            }
        case .redact:
            if rect.width > 3, rect.height > 3 {
                add(rectAnnotation(kind: .redact, rect: rect))
            }
        case .pen:
            if points.count > 1 {
                add(Annotation(
                    kind: .pen,
                    start: points[0],
                    end: points[points.count - 1],
                    points: points,
                    color: currentColor,
                    lineWidth: currentLineWidth
                ))
            }
        case .highlight:
            if points.count > 1 {
                add(Annotation(
                    kind: .highlight,
                    start: points[0],
                    end: points[points.count - 1],
                    points: points,
                    color: currentColor,
                    lineWidth: max(12, currentLineWidth * 5)
                ))
            }
        case .counter, .select, .text:
            break
        }

        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        context.interpolationQuality = .high
        context.draw(baseImage, in: bounds)

        for annotation in annotations where !annotation.isHidden {
            if let editingAnnotationID, annotation.id == editingAnnotationID { continue }
            draw(annotation, in: context, scale: displayScale)
        }

        drawSelection(in: context)

        if let start = draftStart, let end = draftEnd {
            drawDraft(from: start, to: end, points: draftPoints, in: context, scale: displayScale)
        }
    }

    func renderedImage() -> CGImage? {
        let width = baseImage.width
        let height = baseImage.height
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        context.interpolationQuality = .high
        context.draw(baseImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
        for annotation in annotations where !annotation.isHidden {
            draw(annotation, in: context, scale: 1)
        }
        NSGraphicsContext.restoreGraphicsState()

        return context.makeImage()
    }

    // MARK: - Insertions

    func insertImage(_ image: CGImage) {
        let maxWidth = CGFloat(baseImage.width) * 0.5
        let maxHeight = CGFloat(baseImage.height) * 0.5
        let scale = min(1, min(maxWidth / CGFloat(image.width), maxHeight / CGFloat(image.height)))
        let size = CGSize(width: CGFloat(image.width) * scale, height: CGFloat(image.height) * scale)
        let origin = CGPoint(
            x: (CGFloat(baseImage.width) - size.width) / 2,
            y: (CGFloat(baseImage.height) - size.height) / 2
        )
        let annotation = Annotation(
            kind: .image,
            start: origin,
            end: CGPoint(x: origin.x + size.width, y: origin.y + size.height),
            color: currentColor,
            lineWidth: currentLineWidth,
            image: image
        )
        add(annotation)
        selectedAnnotationIDs = [annotation.id]
        needsDisplay = true
    }

    func insertEmoji(_ emoji: String) {
        let fontSize: CGFloat = 64
        let font = textFont(
            size: fontSize,
            design: currentFontDesign,
            weight: currentFontWeight
        )
        let width = ceil((emoji as NSString).size(withAttributes: [.font: font]).width) + 8
        let origin = CGPoint(
            x: (CGFloat(baseImage.width) - width) / 2,
            y: CGFloat(baseImage.height) / 2
        )
        let annotation = Annotation(
            kind: .text,
            start: origin,
            end: CGPoint(x: origin.x + width, y: origin.y + fontSize + 8),
            color: currentColor,
            lineWidth: currentLineWidth,
            text: emoji,
            fontSize: fontSize,
            textStyle: currentTextStyle,
            textAlignment: currentTextAlignment,
            fontWeight: currentFontWeight,
            fontDesign: currentFontDesign
        )
        add(annotation)
        selectedAnnotationIDs = [annotation.id]
        needsDisplay = true
    }

    // MARK: - Selection

    private func selectedAnnotations() -> [(index: Int, annotation: Annotation)] {
        annotations.enumerated().compactMap { index, annotation in
            selectedAnnotationIDs.contains(annotation.id) ? (index, annotation) : nil
        }
    }

    private func primarySelection() -> (index: Int, annotation: Annotation)? {
        guard selectedAnnotationIDs.count == 1, let id = selectedAnnotationIDs.first,
              let index = annotations.firstIndex(where: { $0.id == id })
        else {
            return nil
        }
        return (index, annotations[index])
    }

    private func annotation(at point: CGPoint) -> (index: Int, annotation: Annotation)? {
        for (index, annotation) in annotations.enumerated().reversed() {
            guard !annotation.isHidden, !annotation.isLocked else { continue }
            let bounds = objectBounds(annotation)
            let padding: CGFloat = {
                switch annotation.kind {
                case .arrow, .line, .pen, .highlight:
                    return max(6, annotation.lineWidth)
                default:
                    return 4
                }
            }()
            if bounds.insetBy(dx: -padding, dy: -padding).contains(point) {
                return (index, annotation)
            }
        }
        return nil
    }

    private func beginSelectionInteraction(at point: CGPoint, event: NSEvent) {
        if let primary = primarySelection(),
           !primary.annotation.isLocked,
           let handle = hitTestHandle(at: point, annotation: primary.annotation) {
            activeHandle = handle
            manipulationOriginals = [primary.annotation.id: primary.annotation]
            manipulationStart = point
            movingSelection = false
            didManipulate = false
            return
        }

        guard let hit = annotation(at: point) else {
            selectedAnnotationIDs.removeAll()
            needsDisplay = true
            return
        }

        let additive = event.modifierFlags.contains(.shift) || event.modifierFlags.contains(.command)
        if additive {
            if selectedAnnotationIDs.contains(hit.annotation.id) {
                selectedAnnotationIDs.remove(hit.annotation.id)
            } else {
                selectedAnnotationIDs.insert(hit.annotation.id)
            }
            needsDisplay = true
            return
        }

        if !selectedAnnotationIDs.contains(hit.annotation.id) {
            selectedAnnotationIDs = [hit.annotation.id]
        }
        needsDisplay = true

        if event.clickCount == 2, hit.annotation.kind == .text {
            beginEditing(hit.annotation)
            return
        }

        manipulationOriginals = Dictionary(
            uniqueKeysWithValues: selectedAnnotations().map { ($0.annotation.id, $0.annotation) }
        )
        manipulationStart = point
        movingSelection = true
        didManipulate = false
        NSCursor.closedHand.set()
    }

    private func updateMove(to point: CGPoint) {
        var dx = point.x - manipulationStart.x
        var dy = point.y - manipulationStart.y

        let union = selectionUnionBounds()
        let imageBounds = CGRect(x: 0, y: 0, width: baseImage.width, height: baseImage.height)
        dx = max(imageBounds.minX - union.minX, min(dx, imageBounds.maxX - union.maxX))
        dy = max(imageBounds.minY - union.minY, min(dy, imageBounds.maxY - union.maxY))

        let snapped = snappedDelta(dx: dx, dy: dy, union: union)
        dx = snapped.x
        dy = snapped.y

        for (id, original) in manipulationOriginals {
            guard let index = annotations.firstIndex(where: { $0.id == id }) else { continue }
            annotations[index] = translated(original, dx: dx, dy: dy)
        }
        didManipulate = true
        needsDisplay = true
    }

    private func snappedDelta(dx: CGFloat, dy: CGFloat, union: CGRect) -> CGPoint {
        let moved = union.offsetBy(dx: dx, dy: dy)
        let threshold: CGFloat = 6
        let imageBounds = CGRect(x: 0, y: 0, width: baseImage.width, height: baseImage.height)

        var xCandidates: [CGFloat] = [imageBounds.minX, imageBounds.midX, imageBounds.maxX]
        var yCandidates: [CGFloat] = [imageBounds.minY, imageBounds.midY, imageBounds.maxY]
        for annotation in annotations where !selectedAnnotationIDs.contains(annotation.id) && !annotation.isHidden {
            let bounds = objectBounds(annotation)
            xCandidates.append(contentsOf: [bounds.minX, bounds.midX, bounds.maxX])
            yCandidates.append(contentsOf: [bounds.minY, bounds.midY, bounds.maxY])
        }

        func snap(_ value: CGFloat, _ candidates: [CGFloat]) -> CGFloat? {
            var best: CGFloat?
            var bestDistance = threshold
            for candidate in candidates {
                let distance = abs(candidate - value)
                if distance < bestDistance {
                    bestDistance = distance
                    best = candidate
                }
            }
            return best
        }

        var adjustedX = dx
        var adjustedY = dy
        for edge in [moved.minX, moved.midX, moved.maxX] {
            if let target = snap(edge, xCandidates) {
                adjustedX += target - edge
                break
            }
        }
        for edge in [moved.minY, moved.midY, moved.maxY] {
            if let target = snap(edge, yCandidates) {
                adjustedY += target - edge
                break
            }
        }
        return CGPoint(x: adjustedX, y: adjustedY)
    }

    private func selectionUnionBounds() -> CGRect {
        let bounds = selectedAnnotations().map { objectBounds($0.annotation) }
        guard var union = bounds.first else { return .zero }
        for rect in bounds.dropFirst() {
            union = union.union(rect)
        }
        return union
    }

    private func updateResize(to point: CGPoint) {
        guard let primary = primarySelection(),
              let handle = activeHandle,
              annotations.indices.contains(primary.index)
        else {
            return
        }

        let original = primary.annotation
        let originalRect = selectionBounds(original)
        var rect = originalRect
        let dx = point.x - manipulationStart.x
        let dy = point.y - manipulationStart.y

        if handle.affectsLeft {
            rect.origin.x += dx
            rect.size.width -= dx
        }
        if handle.affectsRight {
            rect.size.width += dx
        }
        if handle.affectsBottom {
            rect.origin.y += dy
            rect.size.height -= dy
        }
        if handle.affectsTop {
            rect.size.height += dy
        }

        let minSize: CGFloat = 16
        if rect.width < minSize {
            if handle.affectsLeft {
                rect.origin.x = originalRect.maxX - minSize
            }
            rect.size.width = minSize
        }
        if rect.height < minSize {
            if handle.affectsBottom {
                rect.origin.y = originalRect.maxY - minSize
            }
            rect.size.height = minSize
        }

        annotations[primary.index] = resizedAnnotation(original, from: originalRect, to: rect)
        didManipulate = true
        needsDisplay = true
    }

    private func finishManipulation() {
        if didManipulate, !manipulationOriginals.isEmpty {
            let originals = manipulationOriginals
            canvasUndoManager.registerUndo(withTarget: self) { target in
                target.restoreSnapshots(originals)
            }
            canvasUndoManager.setActionName(activeHandle != nil ? "调整标注大小" : "移动标注")
        }

        manipulationOriginals = [:]
        manipulationStart = .zero
        activeHandle = nil
        movingSelection = false
        didManipulate = false
        NSCursor.arrow.set()
        needsDisplay = true
    }

    private func restoreSnapshots(_ snapshots: [UUID: Annotation]) {
        var current: [UUID: Annotation] = [:]
        for (id, snapshot) in snapshots {
            guard let index = annotations.firstIndex(where: { $0.id == id }) else { continue }
            current[id] = annotations[index]
            annotations[index] = snapshot
        }
        canvasUndoManager.registerUndo(withTarget: self) { target in
            target.restoreSnapshots(current)
        }
        needsDisplay = true
    }

    private func copySelection() {
        let selected = selectedAnnotations().map { $0.annotation }
        if !selected.isEmpty {
            copiedAnnotations = selected
        }
    }

    private func pasteSelection() {
        guard !copiedAnnotations.isEmpty else { return }
        var pastedIDs: Set<UUID> = []
        for source in copiedAnnotations {
            let pasted = translated(source.withNewID(), dx: 20, dy: -20)
            add(pasted)
            pastedIDs.insert(pasted.id)
        }
        selectedAnnotationIDs = pastedIDs
        needsDisplay = true
    }

    private func duplicateSelection() {
        let selected = selectedAnnotations().map { $0.annotation }
        guard !selected.isEmpty else { return }
        var pastedIDs: Set<UUID> = []
        for source in selected {
            let duplicate = translated(source.withNewID(), dx: 20, dy: -20)
            add(duplicate)
            pastedIDs.insert(duplicate.id)
        }
        selectedAnnotationIDs = pastedIDs
        needsDisplay = true
    }

    private func deleteSelection() {
        let selected = selectedAnnotations().map { $0.annotation }
        guard !selected.isEmpty else { return }
        selectedAnnotationIDs.removeAll()
        for annotation in selected {
            remove(annotation)
        }
    }

    private func moveSelection(by offset: Int) {
        let selected = selectedAnnotations()
        guard !selected.isEmpty else { return }
        let originalOrder = annotations.map(\.id)

        if offset > 0 {
            for item in selected.reversed() {
                let target = item.index + 1
                guard target < annotations.count else { continue }
                let annotation = annotations.remove(at: item.index)
                annotations.insert(annotation, at: target)
            }
        } else {
            for item in selected {
                let target = item.index - 1
                guard target >= 0 else { continue }
                let annotation = annotations.remove(at: item.index)
                annotations.insert(annotation, at: target)
            }
        }
        canvasUndoManager.registerUndo(withTarget: self) { target in
            target.setAnnotationOrder(originalOrder)
        }
        canvasUndoManager.setActionName(offset > 0 ? "上移一层" : "下移一层")
        needsDisplay = true
    }

    private func setAnnotationOrder(_ order: [UUID]) {
        let currentOrder = annotations.map(\.id)
        let byID = Dictionary(uniqueKeysWithValues: annotations.map { ($0.id, $0) })
        let reordered = order.compactMap { byID[$0] }
        guard reordered.count == annotations.count else { return }
        annotations = reordered
        canvasUndoManager.registerUndo(withTarget: self) { target in
            target.setAnnotationOrder(currentOrder)
        }
        needsDisplay = true
    }

    private func translated(_ annotation: Annotation, dx: CGFloat, dy: CGFloat) -> Annotation {
        var copy = annotation
        copy.start = CGPoint(x: annotation.start.x + dx, y: annotation.start.y + dy)
        copy.end = CGPoint(x: annotation.end.x + dx, y: annotation.end.y + dy)
        copy.points = annotation.points.map { CGPoint(x: $0.x + dx, y: $0.y + dy) }
        return copy
    }

    private func resizedAnnotation(_ annotation: Annotation, from oldRect: CGRect, to newRect: CGRect) -> Annotation {
        var copy = annotation
        switch annotation.kind {
        case .rectangle, .ellipse, .text, .pixelate, .blur, .redact, .spotlight, .loupe, .counter, .image:
            copy.start = newRect.origin
            copy.end = CGPoint(x: newRect.maxX, y: newRect.maxY)
        case .arrow, .line:
            copy.start = mapPoint(annotation.start, from: oldRect, to: newRect)
            copy.end = mapPoint(annotation.end, from: oldRect, to: newRect)
        case .pen, .highlight:
            copy.points = annotation.points.map { mapPoint($0, from: oldRect, to: newRect) }
            copy.start = copy.points.first ?? annotation.start
            copy.end = copy.points.last ?? annotation.end
        }
        return copy
    }

    private func mapPoint(_ point: CGPoint, from oldRect: CGRect, to newRect: CGRect) -> CGPoint {
        let x = oldRect.width > 0
            ? newRect.minX + (point.x - oldRect.minX) / oldRect.width * newRect.width
            : newRect.midX
        let y = oldRect.height > 0
            ? newRect.minY + (point.y - oldRect.minY) / oldRect.height * newRect.height
            : newRect.midY
        return CGPoint(x: x, y: y)
    }

    private func objectBounds(_ annotation: Annotation) -> CGRect {
        standardizedRect(from: annotation.start, to: annotation.end)
    }

    private func selectionBounds(_ annotation: Annotation) -> CGRect {
        let bounds = objectBounds(annotation)
        let minDimension: CGFloat = 24
        if bounds.width >= minDimension, bounds.height >= minDimension {
            return bounds
        }
        let width = max(bounds.width, minDimension)
        let height = max(bounds.height, minDimension)
        return CGRect(x: bounds.midX - width / 2, y: bounds.midY - height / 2, width: width, height: height)
    }

    private func hitTestHandle(at point: CGPoint, annotation: Annotation) -> ResizeHandle? {
        let rect = scaledRect(selectionBounds(annotation), by: displayScale)
        let viewPoint = scaled(point, by: displayScale)
        for handle in ResizeHandle.allCases {
            let center = handleCenter(handle, in: rect)
            if abs(viewPoint.x - center.x) <= 6, abs(viewPoint.y - center.y) <= 6 {
                return handle
            }
        }
        return nil
    }

    private func handleCenter(_ handle: ResizeHandle, in rect: CGRect) -> CGPoint {
        switch handle {
        case .topLeft: return CGPoint(x: rect.minX, y: rect.maxY)
        case .top: return CGPoint(x: rect.midX, y: rect.maxY)
        case .topRight: return CGPoint(x: rect.maxX, y: rect.maxY)
        case .right: return CGPoint(x: rect.maxX, y: rect.midY)
        case .bottomRight: return CGPoint(x: rect.maxX, y: rect.minY)
        case .bottom: return CGPoint(x: rect.midX, y: rect.minY)
        case .bottomLeft: return CGPoint(x: rect.minX, y: rect.minY)
        case .left: return CGPoint(x: rect.minX, y: rect.midY)
        }
    }

    private func drawSelection(in context: CGContext) {
        guard activeTextView == nil, !selectedAnnotationIDs.isEmpty else { return }
        let selected = selectedAnnotations()
        guard !selected.isEmpty else { return }

        if selected.count == 1, let primary = primarySelection() {
            let rect = scaledRect(selectionBounds(primary.annotation), by: displayScale)
            context.setStrokeColor(NSColor.controlAccentColor.cgColor)
            context.setLineWidth(1)
            context.stroke(rect)

            let radius: CGFloat = 4
            for handle in ResizeHandle.allCases {
                let center = handleCenter(handle, in: rect)
                let handleRect = CGRect(
                    x: center.x - radius,
                    y: center.y - radius,
                    width: radius * 2,
                    height: radius * 2
                )
                context.setFillColor(NSColor.controlAccentColor.cgColor)
                context.fillEllipse(in: handleRect)
                context.setStrokeColor(NSColor.white.cgColor)
                context.setLineWidth(1.5)
                context.strokeEllipse(in: handleRect)
            }
        } else {
            let bounds = selected.map { selectionBounds($0.annotation) }
            guard var union = bounds.first else { return }
            for rect in bounds.dropFirst() {
                union = union.union(rect)
            }
            let rect = scaledRect(union, by: displayScale)
            context.setStrokeColor(NSColor.controlAccentColor.cgColor)
            context.setLineWidth(1)
            context.setLineDash(phase: 0, lengths: [4, 3])
            context.stroke(rect)
            context.setLineDash(phase: 0, lengths: [])
        }
    }

    // MARK: - Layer operations

    func layerEntries() -> [(id: UUID, name: String, isHidden: Bool, isLocked: Bool)] {
        annotations.reversed().map {
            ($0.id, $0.displayName, $0.isHidden, $0.isLocked)
        }
    }

    func selectAnnotation(id: UUID) {
        selectedAnnotationIDs = [id]
        needsDisplay = true
    }

    func toggleHidden(id: UUID) {
        guard let index = annotations.firstIndex(where: { $0.id == id }) else { return }
        var copy = annotations[index]
        copy.isHidden.toggle()
        setAnnotation(copy, at: index)
    }

    func toggleLocked(id: UUID) {
        guard let index = annotations.firstIndex(where: { $0.id == id }) else { return }
        var copy = annotations[index]
        copy.isLocked.toggle()
        setAnnotation(copy, at: index)
    }

    // MARK: - Text options

    func applyTextStyle(_ style: TextStyle) {
        currentTextStyle = style
        if activeTextView != nil {
            editingTextStyle = style
            applyEditorStyle(style)
            return
        }
        updateSelectedText { $0.textStyle = style }
        needsDisplay = true
    }

    func applyTextAlignment(_ alignment: TextAlignmentOption) {
        currentTextAlignment = alignment
        if activeTextView != nil {
            editingTextAlignment = alignment
            activeTextView?.alignment = alignment.alignment
            return
        }
        updateSelectedText { $0.textAlignment = alignment }
        needsDisplay = true
    }

    func applyFontWeight(_ weight: FontWeightOption) {
        currentFontWeight = weight
        if activeTextView != nil {
            editingFontWeight = weight
            applyEditorStyle(editingTextStyle ?? currentTextStyle)
            return
        }
        updateSelectedText { $0.fontWeight = weight }
        needsDisplay = true
    }

    func applyFontDesign(_ design: FontDesignOption) {
        currentFontDesign = design
        if activeTextView != nil {
            editingFontDesign = design
            applyEditorStyle(editingTextStyle ?? currentTextStyle)
            return
        }
        updateSelectedText { $0.fontDesign = design }
        needsDisplay = true
    }

    func applyArrowStyle(_ style: ArrowStyle) {
        currentArrowStyle = style
        let selected = selectedAnnotations().filter { $0.annotation.kind == .arrow }
        for item in selected {
            var copy = item.annotation
            copy.arrowStyle = style
            setAnnotation(copy, at: item.index)
        }
        needsDisplay = true
    }

    func setFontSize(_ size: CGFloat) {
        currentFontSize = min(96, max(12, size))
        if activeTextView != nil {
            editingFontSize = currentFontSize
            applyEditorStyle(editingTextStyle ?? currentTextStyle)
            return
        }
        updateSelectedText { $0.fontSize = self.currentFontSize }
        needsDisplay = true
    }

    func applyColor(_ color: NSColor) {
        currentColor = color
        if activeTextView != nil {
            editingTextColor = color
            applyEditorStyle(editingTextStyle ?? currentTextStyle)
            return
        }
        for item in selectedAnnotations() {
            var copy = item.annotation
            copy.color = color
            setAnnotation(copy, at: item.index)
        }
        needsDisplay = true
    }

    func applyLineWidth(_ width: CGFloat) {
        currentLineWidth = min(24, max(1, width))
        for item in selectedAnnotations() {
            var copy = item.annotation
            copy.lineWidth = currentLineWidth
            setAnnotation(copy, at: item.index)
        }
        needsDisplay = true
    }

    func applySpotlightOpacity(_ value: CGFloat) {
        currentSpotlightOpacity = min(1, max(0.05, value))
        for item in selectedAnnotations() where item.annotation.kind == .spotlight {
            var copy = item.annotation
            copy.spotlightOpacity = currentSpotlightOpacity
            setAnnotation(copy, at: item.index)
        }
        needsDisplay = true
    }

    func applySpotlightShape(_ shape: SpotlightShape) {
        currentSpotlightShape = shape
        for item in selectedAnnotations() where item.annotation.kind == .spotlight {
            var copy = item.annotation
            copy.spotlightShape = shape
            setAnnotation(copy, at: item.index)
        }
        needsDisplay = true
    }

    func applyIntensity(_ value: CGFloat) {
        let clamped = min(40, max(2, value))
        let kind: Annotation.Kind
        if tool == .blur {
            currentBlurIntensity = clamped
            kind = .blur
        } else {
            currentPixelateIntensity = clamped
            kind = .pixelate
        }
        for item in selectedAnnotations() where item.annotation.kind == kind {
            var copy = item.annotation
            copy.intensity = clamped
            setAnnotation(copy, at: item.index)
        }
        needsDisplay = true
    }

    func resetCounter() {
        nextCounterValue = 1
    }

    private func updateSelectedText(_ update: (inout Annotation) -> Void) {
        for item in selectedAnnotations() where item.annotation.kind == .text {
            var copy = item.annotation
            update(&copy)
            setAnnotation(copy, at: item.index)
        }
    }

    private func changeTextSize(by delta: CGFloat) {
        setFontSize(currentFontSize + delta)
    }

    // MARK: - Text editing

    func finishTextEditing() {
        if activeTextView != nil {
            commitTextInput()
        }
    }

    private func textAnnotation(at point: CGPoint) -> Annotation? {
        annotations.reversed().first { annotation in
            annotation.kind == .text && !annotation.isHidden && annotationRect(annotation).contains(point)
        }
    }

    private func beginTextInput(at point: CGPoint) {
        editingAnnotationID = nil
        let font = textFont(
            size: currentFontSize,
            design: currentFontDesign,
            weight: currentFontWeight
        )
        let lineHeight = ceil(font.ascender - font.descender + font.leading)
        let height = lineHeight + 8
        let rect = CGRect(x: point.x, y: point.y - height, width: 80, height: height)
        presentTextEditor(
            rect: rect,
            text: "",
            color: currentColor,
            style: currentTextStyle,
            fontSize: currentFontSize,
            design: currentFontDesign,
            weight: currentFontWeight,
            alignment: currentTextAlignment,
            autoGrow: true
        )
    }

    private func beginEditing(_ annotation: Annotation) {
        editingAnnotationID = annotation.id
        presentTextEditor(
            rect: annotationRect(annotation),
            text: annotation.text,
            color: annotation.color,
            style: annotation.textStyle,
            fontSize: annotation.fontSize,
            design: annotation.fontDesign,
            weight: annotation.fontWeight,
            alignment: annotation.textAlignment,
            autoGrow: false
        )
    }

    private func presentTextEditor(
        rect: CGRect,
        text: String,
        color: NSColor,
        style: TextStyle,
        fontSize: CGFloat,
        design: FontDesignOption,
        weight: FontWeightOption,
        alignment: TextAlignmentOption,
        autoGrow: Bool
    ) {
        activeTextRect = rect
        editingTextStyle = style
        editingFontSize = fontSize
        editingTextColor = color
        editingFontDesign = design
        editingFontWeight = weight
        editingTextAlignment = alignment
        autoGrowText = autoGrow

        let viewRect = scaledRect(rect, by: displayScale)
        let font = textFont(size: fontSize * displayScale, design: design, weight: weight)

        let textView = NSTextView(frame: viewRect)
        textView.isRichText = false
        textView.drawsBackground = false
        textView.textColor = style == .roundedBox ? .white : color
        textView.font = font
        textView.alignment = alignment.alignment
        textView.isEditable = true
        textView.isSelectable = true
        textView.textContainerInset = style == .roundedBox
            ? NSSize(width: 8 * displayScale, height: 6 * displayScale)
            : .zero
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: viewRect.width, height: CGFloat.greatestFiniteMagnitude)
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = false
        textView.delegate = self
        textView.wantsLayer = true
        textView.layer?.borderWidth = 1
        textView.layer?.borderColor = NSColor.controlAccentColor.withAlphaComponent(0.8).cgColor
        textView.layer?.cornerRadius = style == .roundedBox ? 6 : 0
        textView.layer?.masksToBounds = style == .roundedBox
        textView.layer?.backgroundColor = style == .roundedBox
            ? cgColor(color)
            : NSColor.white.withAlphaComponent(0.06).cgColor
        textView.string = text

        let handle = TextResizeHandle(frame: NSRect(
            x: viewRect.maxX - 6,
            y: viewRect.maxY - 6,
            width: 12,
            height: 12
        ))
        handle.wantsLayer = true
        handle.layer?.backgroundColor = NSColor.controlAccentColor.cgColor
        handle.layer?.cornerRadius = 6
        handle.onDrag = { [weak self] dx, dy in
            self?.resizeActiveText(dx: dx, dy: dy)
        }

        activeTextView = textView
        activeResizeHandle = handle
        addSubview(textView)
        addSubview(handle)
        window?.makeFirstResponder(textView)
        if !text.isEmpty {
            textView.setSelectedRange(NSRange(location: 0, length: (text as NSString).length))
        }
        needsDisplay = true
    }

    private func resizeActiveText(dx: CGFloat, dy: CGFloat) {
        guard let textView = activeTextView, let handle = activeResizeHandle else { return }
        autoGrowText = false
        var rect = activeTextRect
        rect.size.width = max(60 / displayScale, rect.width + dx / displayScale)
        rect.size.height = max(24 / displayScale, rect.height + dy / displayScale)
        activeTextRect = rect

        let viewRect = scaledRect(rect, by: displayScale)
        textView.frame = viewRect
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: viewRect.width, height: CGFloat.greatestFiniteMagnitude)
        if let container = textView.textContainer {
            textView.layoutManager?.ensureLayout(for: container)
        }
        handle.frame.origin = NSPoint(x: viewRect.maxX - 6, y: viewRect.maxY - 6)
        needsDisplay = true
    }

    private func commitTextInput() {
        guard let textView = activeTextView else { return }
        let text = textView.string
        let rect = activeTextRect
        let color = editingTextColor ?? currentColor
        let style = editingTextStyle ?? currentTextStyle
        let fontSize = editingFontSize ?? currentFontSize
        let design = editingFontDesign ?? currentFontDesign
        let weight = editingFontWeight ?? currentFontWeight
        let alignment = editingTextAlignment ?? currentTextAlignment
        let editingID = editingAnnotationID
        let handle = activeResizeHandle

        activeTextView = nil
        activeResizeHandle = nil
        editingAnnotationID = nil
        editingTextStyle = nil
        editingFontSize = nil
        editingTextColor = nil
        editingFontDesign = nil
        editingFontWeight = nil
        editingTextAlignment = nil
        autoGrowText = false
        textView.delegate = nil
        textView.removeFromSuperview()
        handle?.removeFromSuperview()
        window?.makeFirstResponder(self)

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            if let editingID, let existing = annotations.first(where: { $0.id == editingID }) {
                remove(existing)
            }
        } else if let editingID, let index = annotations.firstIndex(where: { $0.id == editingID }) {
            var annotation = annotations[index]
            annotation.start = rect.origin
            annotation.end = CGPoint(x: rect.maxX, y: rect.maxY)
            annotation.color = color
            annotation.fontSize = fontSize
            annotation.textStyle = style
            annotation.fontDesign = design
            annotation.fontWeight = weight
            annotation.textAlignment = alignment
            annotation.text = text
            setAnnotation(annotation, at: index)
        } else {
            let annotation = Annotation(
                kind: .text,
                start: rect.origin,
                end: CGPoint(x: rect.maxX, y: rect.maxY),
                color: color,
                lineWidth: currentLineWidth,
                text: text,
                fontSize: fontSize,
                textStyle: style,
                textAlignment: alignment,
                fontWeight: weight,
                fontDesign: design
            )
            add(annotation)
            selectedAnnotationIDs = [annotation.id]
        }
        needsDisplay = true
    }

    private func cancelTextInput() {
        guard let textView = activeTextView else { return }
        let handle = activeResizeHandle
        activeTextView = nil
        activeResizeHandle = nil
        editingAnnotationID = nil
        editingTextStyle = nil
        editingFontSize = nil
        editingTextColor = nil
        editingFontDesign = nil
        editingFontWeight = nil
        editingTextAlignment = nil
        autoGrowText = false
        textView.delegate = nil
        textView.removeFromSuperview()
        handle?.removeFromSuperview()
        window?.makeFirstResponder(self)
        needsDisplay = true
    }

    func applyTextStyleFromMenu(_ style: TextStyle) {
        applyTextStyle(style)
    }

    private func applyEditorStyle(_ style: TextStyle) {
        guard let textView = activeTextView else { return }
        let fontSize = (editingFontSize ?? currentFontSize) * displayScale
        let design = editingFontDesign ?? currentFontDesign
        let weight = editingFontWeight ?? currentFontWeight
        textView.font = textFont(size: fontSize, design: design, weight: weight)
        textView.alignment = (editingTextAlignment ?? currentTextAlignment).alignment
        textView.textColor = style == .roundedBox ? .white : (editingTextColor ?? currentColor)
        textView.textContainerInset = style == .roundedBox
            ? NSSize(width: 8 * displayScale, height: 6 * displayScale)
            : .zero
        textView.layer?.cornerRadius = style == .roundedBox ? 6 : 0
        textView.layer?.masksToBounds = style == .roundedBox
        textView.layer?.backgroundColor = style == .roundedBox
            ? cgColor(editingTextColor ?? currentColor)
            : NSColor.white.withAlphaComponent(0.06).cgColor

        if autoGrowText {
            resizeEditorToFitText()
        } else {
            textView.textContainer?.widthTracksTextView = true
            textView.textContainer?.containerSize = NSSize(width: textView.frame.width, height: CGFloat.greatestFiniteMagnitude)
            if let container = textView.textContainer {
                textView.layoutManager?.ensureLayout(for: container)
            }
        }
        needsDisplay = true
    }

    private func resizeEditorToFitText() {
        guard let textView = activeTextView, let handle = activeResizeHandle else { return }

        let inset = textView.textContainerInset
        let availableWidth = max(60, bounds.width - textView.frame.minX)
        let maxContentWidth = max(20, availableWidth - inset.width * 2 - 6)
        let font = textView.font ?? NSFont.systemFont(ofSize: 14)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = (editingTextAlignment ?? currentTextAlignment).alignment

        let bounding = (textView.string as NSString).boundingRect(
            with: NSSize(width: maxContentWidth, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font, .paragraphStyle: paragraph]
        )

        let lineHeight = ceil(font.ascender - font.descender + font.leading)
        let newWidth = min(availableWidth, max(60, ceil(bounding.width) + inset.width * 2 + 6))
        let newHeight = max(lineHeight + inset.height * 2 + 6, ceil(bounding.height) + inset.height * 2 + 6)

        let top = textView.frame.maxY
        let frame = NSRect(x: textView.frame.minX, y: top - newHeight, width: newWidth, height: newHeight)
        textView.frame = frame
        textView.textContainer?.widthTracksTextView = true
        if let container = textView.textContainer {
            textView.layoutManager?.ensureLayout(for: container)
        }
        handle.frame.origin = NSPoint(x: frame.maxX - 6, y: frame.maxY - 6)
        activeTextRect = CGRect(
            x: frame.minX / displayScale,
            y: frame.minY / displayScale,
            width: frame.width / displayScale,
            height: frame.height / displayScale
        )
        needsDisplay = true
    }

    private func textFont(size: CGFloat, design: FontDesignOption, weight: FontWeightOption) -> NSFont {
        let base = NSFont.systemFont(ofSize: size, weight: weight.weight)
        if let systemDesign = design.systemDesign,
           let descriptor = base.fontDescriptor.withDesign(systemDesign),
           let font = NSFont(descriptor: descriptor, size: size) {
            return font
        }
        return base
    }

    private func textAttributes(for annotation: Annotation, scale: CGFloat) -> [NSAttributedString.Key: Any] {
        let font = textFont(
            size: annotation.fontSize * scale,
            design: annotation.fontDesign,
            weight: annotation.fontWeight
        )
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
        paragraph.alignment = annotation.textAlignment.alignment

        switch annotation.textStyle {
        case .roundedBox:
            return [
                .font: font,
                .foregroundColor: NSColor.white,
                .paragraphStyle: paragraph
            ]
        case .outline:
            return [
                .font: font,
                .foregroundColor: annotation.color,
                .strokeColor: NSColor.white,
                .strokeWidth: -3.0,
                .paragraphStyle: paragraph
            ]
        case .standard, .monospaced:
            return [
                .font: font,
                .foregroundColor: annotation.color,
                .paragraphStyle: paragraph
            ]
        }
    }

    // MARK: - Undo

    private func add(_ annotation: Annotation) {
        annotations.append(annotation)
        canvasUndoManager.registerUndo(withTarget: self) { target in
            target.remove(annotation)
        }
        canvasUndoManager.setActionName("添加标注")
        needsDisplay = true
    }

    private func remove(_ annotation: Annotation) {
        guard let index = annotations.firstIndex(where: { $0.id == annotation.id }) else { return }
        annotations.remove(at: index)
        selectedAnnotationIDs.remove(annotation.id)
        canvasUndoManager.registerUndo(withTarget: self) { target in
            target.insert(annotation, at: index)
        }
        canvasUndoManager.setActionName("删除标注")
        needsDisplay = true
    }

    private func insert(_ annotation: Annotation, at index: Int) {
        annotations.insert(annotation, at: min(index, annotations.count))
        canvasUndoManager.registerUndo(withTarget: self) { target in
            target.remove(annotation)
        }
        canvasUndoManager.setActionName("添加标注")
        needsDisplay = true
    }

    private func setAnnotation(_ annotation: Annotation, at index: Int) {
        guard annotations.indices.contains(index) else { return }
        let previous = annotations[index]
        annotations[index] = annotation
        canvasUndoManager.registerUndo(withTarget: self) { target in
            target.setAnnotation(previous, at: index)
        }
        canvasUndoManager.setActionName("编辑标注")
        needsDisplay = true
    }

    // MARK: - Drawing

    private func rectAnnotation(kind: Annotation.Kind, rect: CGRect) -> Annotation {
        var annotation = Annotation(
            kind: kind,
            start: rect.origin,
            end: CGPoint(x: rect.maxX, y: rect.maxY),
            color: currentColor,
            lineWidth: currentLineWidth
        )
        switch kind {
        case .spotlight:
            annotation.spotlightOpacity = currentSpotlightOpacity
            annotation.spotlightShape = currentSpotlightShape
        case .pixelate:
            annotation.intensity = currentPixelateIntensity
        case .blur:
            annotation.intensity = currentBlurIntensity
        default:
            break
        }
        return annotation
    }

    private func addCounter(at point: CGPoint) {
        let size: CGFloat = max(28, currentLineWidth * 8)
        let rect = CGRect(x: point.x - size / 2, y: point.y - size / 2, width: size, height: size)
        let annotation = Annotation(
            kind: .counter,
            start: rect.origin,
            end: CGPoint(x: rect.maxX, y: rect.maxY),
            color: currentColor,
            lineWidth: currentLineWidth,
            counterValue: nextCounterValue
        )
        nextCounterValue += 1
        add(annotation)
        selectedAnnotationIDs = [annotation.id]
        needsDisplay = true
    }

    private func draw(_ annotation: Annotation, in context: CGContext, scale: CGFloat) {
        switch annotation.kind {
        case .arrow:
            drawArrow(
                annotation: annotation,
                in: context,
                scale: scale
            )
        case .line:
            context.setStrokeColor(cgColor(annotation.color))
            context.setLineWidth(annotation.lineWidth * scale)
            context.setLineCap(.round)
            context.move(to: scaled(annotation.start, by: scale))
            context.addLine(to: scaled(annotation.end, by: scale))
            context.strokePath()
        case .rectangle:
            let rect = scaledRect(annotationRect(annotation), by: scale)
            context.setStrokeColor(cgColor(annotation.color))
            context.setLineWidth(annotation.lineWidth * scale)
            context.stroke(rect)
        case .ellipse:
            let rect = scaledRect(annotationRect(annotation), by: scale)
            context.setStrokeColor(cgColor(annotation.color))
            context.setLineWidth(annotation.lineWidth * scale)
            context.strokeEllipse(in: rect)
        case .pen:
            drawPoints(annotation.points, color: annotation.color, lineWidth: annotation.lineWidth * scale, scale: scale, in: context)
        case .highlight:
            drawPoints(
                annotation.points,
                color: annotation.color.withAlphaComponent(0.35),
                lineWidth: annotation.lineWidth * scale,
                scale: scale,
                in: context
            )
        case .text:
            let rect = scaledRect(annotationRect(annotation), by: scale)
            let attributes = textAttributes(for: annotation, scale: scale)
            if annotation.textStyle == .roundedBox {
                let radius = 6 * scale
                let path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
                context.setFillColor(cgColor(annotation.color))
                context.addPath(path)
                context.fillPath()
                let inset = rect.insetBy(dx: 8 * scale, dy: 6 * scale)
                (annotation.text as NSString).draw(
                    with: inset,
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: attributes,
                    context: nil
                )
            } else {
                (annotation.text as NSString).draw(
                    with: rect,
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: attributes,
                    context: nil
                )
            }
        case .counter:
            let rect = scaledRect(annotationRect(annotation), by: scale)
            let radius = min(rect.width, rect.height) / 2
            let center = CGPoint(x: rect.midX, y: rect.midY)
            context.setFillColor(cgColor(annotation.color))
            context.fillEllipse(in: CGRect(
                x: center.x - radius,
                y: center.y - radius,
                width: radius * 2,
                height: radius * 2
            ))
            let fontSize = max(10, radius * 1.1)
            let font = NSFont.systemFont(ofSize: fontSize, weight: .bold)
            let text = "\(annotation.counterValue)"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: NSColor.white
            ]
            let size = (text as NSString).size(withAttributes: attributes)
            (text as NSString).draw(
                at: CGPoint(x: center.x - size.width / 2, y: center.y - size.height / 2),
                withAttributes: attributes
            )
        case .spotlight:
            let rect = scaledRect(annotationRect(annotation), by: scale)
            let canvasRect = CGRect(
                x: 0,
                y: 0,
                width: CGFloat(baseImage.width) * scale,
                height: CGFloat(baseImage.height) * scale
            )
            let path = CGMutablePath()
            path.addRect(canvasRect)
            if annotation.spotlightShape == .rectangle {
                path.addRect(rect)
            } else {
                path.addEllipse(in: rect)
            }
            context.addPath(path)
            context.setFillColor(NSColor.black.withAlphaComponent(annotation.spotlightOpacity).cgColor)
            context.drawPath(using: .eoFill)
        case .loupe:
            drawLoupe(annotation, in: context, scale: scale)
        case .pixelate:
            guard let image = pixelatedImage(intensity: annotation.intensity) else { return }
            drawProcessedRegion(annotation, image: image, in: context, scale: scale)
        case .blur:
            guard let image = blurredImage(intensity: annotation.intensity) else { return }
            drawProcessedRegion(annotation, image: image, in: context, scale: scale)
        case .redact:
            let rect = scaledRect(annotationRect(annotation), by: scale)
            context.setFillColor(cgColor(annotation.color))
            context.fill(rect)
        case .image:
            if let image = annotation.image {
                let rect = scaledRect(annotationRect(annotation), by: scale)
                context.draw(image, in: rect)
            }
        }
    }

    private func drawPoints(_ points: [CGPoint], color: NSColor, lineWidth: CGFloat, scale: CGFloat, in context: CGContext) {
        guard points.count > 1 else { return }
        context.setStrokeColor(cgColor(color))
        context.setLineWidth(lineWidth)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.move(to: scaled(points[0], by: scale))
        for point in points.dropFirst() {
            context.addLine(to: scaled(point, by: scale))
        }
        context.strokePath()
    }

    private func drawArrow(annotation: Annotation, in context: CGContext, scale: CGFloat) {
        let from = scaled(annotation.start, by: scale)
        let to = scaled(annotation.end, by: scale)
        let color = cgColor(annotation.color)
        let lineWidth = annotation.lineWidth * scale

        context.setStrokeColor(color)
        context.setFillColor(color)
        context.setLineWidth(lineWidth)
        context.setLineCap(.round)

        switch annotation.arrowStyle {
        case .standard:
            context.move(to: from)
            context.addLine(to: to)
            context.strokePath()
            drawArrowHead(at: to, from: from, color: color, lineWidth: lineWidth, in: context)
        case .double:
            context.move(to: from)
            context.addLine(to: to)
            context.strokePath()
            drawArrowHead(at: to, from: from, color: color, lineWidth: lineWidth, in: context)
            drawArrowHead(at: from, from: to, color: color, lineWidth: lineWidth, in: context)
        case .fancy:
            let midpoint = CGPoint(x: (from.x + to.x) / 2, y: (from.y + to.y) / 2)
            let dx = to.x - from.x
            let dy = to.y - from.y
            let length = max(1, hypot(dx, dy))
            let offset = min(40, length * 0.18)
            let control = CGPoint(
                x: midpoint.x - dy / length * offset,
                y: midpoint.y + dx / length * offset
            )
            context.move(to: from)
            context.addQuadCurve(to: to, control: control)
            context.strokePath()
            drawArrowHead(at: to, from: control, color: color, lineWidth: lineWidth, in: context)
        }
    }

    private func drawArrowHead(at tip: CGPoint, from origin: CGPoint, color: CGColor, lineWidth: CGFloat, in context: CGContext) {
        let angle = atan2(tip.y - origin.y, tip.x - origin.x)
        let headLength = max(10, lineWidth * 4)
        let spread = CGFloat.pi / 7
        let left = CGPoint(
            x: tip.x - headLength * cos(angle - spread),
            y: tip.y - headLength * sin(angle - spread)
        )
        let right = CGPoint(
            x: tip.x - headLength * cos(angle + spread),
            y: tip.y - headLength * sin(angle + spread)
        )
        context.setFillColor(color)
        context.move(to: tip)
        context.addLine(to: left)
        context.addLine(to: right)
        context.closePath()
        context.fillPath()
    }

    private func drawProcessedRegion(_ annotation: Annotation, image: CGImage?, in context: CGContext, scale: CGFloat) {
        let destination = scaledRect(annotationRect(annotation), by: scale)
        guard let image else {
            context.setFillColor(NSColor.black.cgColor)
            context.fill(destination)
            return
        }
        let sourceRect = annotationRect(annotation)
        let cropRect = CGRect(
            x: sourceRect.minX,
            y: CGFloat(baseImage.height) - sourceRect.maxY,
            width: sourceRect.width,
            height: sourceRect.height
        ).integral
        if let cropped = image.cropping(to: cropRect) {
            context.draw(cropped, in: destination)
        }
    }

    private func drawLoupe(_ annotation: Annotation, in context: CGContext, scale: CGFloat) {
        let rect = scaledRect(annotationRect(annotation), by: scale)
        let magnification: CGFloat = 2

        context.saveGState()
        let clipPath = CGMutablePath()
        clipPath.addEllipse(in: rect)
        context.addPath(clipPath)
        context.clip()
        let imageRect = CGRect(
            x: 0,
            y: 0,
            width: CGFloat(baseImage.width) * scale,
            height: CGFloat(baseImage.height) * scale
        )
        let magnifiedRect = CGRect(
            x: rect.midX - imageRect.midX * magnification,
            y: rect.midY - imageRect.midY * magnification,
            width: imageRect.width * magnification,
            height: imageRect.height * magnification
        )
        context.interpolationQuality = .high
        context.draw(baseImage, in: magnifiedRect)
        context.restoreGState()

        context.setStrokeColor(NSColor.white.cgColor)
        context.setLineWidth(max(2, annotation.lineWidth * scale))
        context.strokeEllipse(in: rect)
        context.setStrokeColor(NSColor.black.withAlphaComponent(0.4).cgColor)
        context.setLineWidth(1)
        context.strokeEllipse(in: rect.insetBy(dx: -1, dy: -1))
    }

    private func drawDraft(from start: CGPoint, to end: CGPoint, points: [CGPoint], in context: CGContext, scale: CGFloat) {
        switch tool {
        case .arrow:
            let draft = Annotation(
                kind: .arrow,
                start: start,
                end: end,
                color: currentColor,
                lineWidth: currentLineWidth,
                arrowStyle: currentArrowStyle
            )
            drawArrow(annotation: draft, in: context, scale: scale)
        case .line:
            context.setStrokeColor(cgColor(currentColor))
            context.setLineWidth(currentLineWidth * scale)
            context.move(to: scaled(start, by: scale))
            context.addLine(to: scaled(end, by: scale))
            context.strokePath()
        case .rectangle:
            let rect = scaledRect(standardizedRect(from: start, to: end), by: scale)
            context.setStrokeColor(cgColor(currentColor))
            context.setLineWidth(currentLineWidth * scale)
            context.stroke(rect)
        case .ellipse:
            let rect = scaledRect(standardizedRect(from: start, to: end), by: scale)
            context.setStrokeColor(cgColor(currentColor))
            context.setLineWidth(currentLineWidth * scale)
            context.strokeEllipse(in: rect)
        case .pen, .highlight:
            guard points.count > 1 else { return }
            context.setStrokeColor(cgColor(tool == .highlight ? currentColor.withAlphaComponent(0.35) : currentColor))
            context.setLineWidth((tool == .highlight ? max(12, currentLineWidth * 5) : currentLineWidth) * scale)
            context.setLineCap(.round)
            context.setLineJoin(.round)
            context.move(to: scaled(points[0], by: scale))
            for point in points.dropFirst() {
                context.addLine(to: scaled(point, by: scale))
            }
            context.strokePath()
        case .pixelate, .blur, .redact:
            let rect = scaledRect(standardizedRect(from: start, to: end), by: scale)
            context.setFillColor(NSColor.black.withAlphaComponent(0.25).cgColor)
            context.fill(rect)
            context.setStrokeColor(cgColor(currentColor))
            context.setLineWidth(currentLineWidth * scale)
            context.stroke(rect)
        case .spotlight, .loupe:
            let rect = scaledRect(standardizedRect(from: start, to: end), by: scale)
            context.setStrokeColor(cgColor(currentColor))
            context.setLineWidth(currentLineWidth * scale)
            context.strokeEllipse(in: rect)
        case .select, .text, .counter:
            break
        }
    }

    private func scaled(_ point: CGPoint, by scale: CGFloat) -> CGPoint {
        CGPoint(x: point.x * scale, y: point.y * scale)
    }

    private func scaledRect(_ rect: CGRect, by scale: CGFloat) -> CGRect {
        CGRect(x: rect.minX * scale, y: rect.minY * scale, width: rect.width * scale, height: rect.height * scale)
    }

    private func imagePoint(_ point: NSPoint) -> CGPoint {
        CGPoint(x: point.x / displayScale, y: point.y / displayScale)
    }

    private func standardizedRect(from start: CGPoint, to end: CGPoint) -> CGRect {
        CGRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )
    }

    private func cgColor(_ color: NSColor) -> CGColor {
        color.usingColorSpace(.sRGB)?.cgColor ?? NSColor.systemRed.cgColor
    }

    private func annotationRect(_ annotation: Annotation) -> CGRect {
        objectBounds(annotation)
    }
}

extension AnnotationCanvasView: NSTextViewDelegate {
    func textDidChange(_ notification: Notification) {
        if autoGrowText {
            resizeEditorToFitText()
        }
    }

    func textDidEndEditing(_ notification: Notification) {
        if activeTextView != nil {
            commitTextInput()
        }
    }

    func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
            cancelTextInput()
            return true
        }
        if commandSelector == #selector(NSResponder.insertNewline(_:)),
           let event = NSApp.currentEvent,
           event.modifierFlags.contains(.command) {
            commitTextInput()
            return true
        }
        return false
    }
}

final class TextResizeHandle: NSView {
    var onDrag: ((CGFloat, CGFloat) -> Void)?
    private var lastLocation: NSPoint?

    override func mouseDown(with event: NSEvent) {
        lastLocation = event.locationInWindow
    }

    override func mouseDragged(with event: NSEvent) {
        guard let last = lastLocation else { return }
        let current = event.locationInWindow
        onDrag?(current.x - last.x, current.y - last.y)
        lastLocation = current
    }

    override func mouseUp(with event: NSEvent) {
        lastLocation = nil
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .crosshair)
    }
}

extension Annotation {
    func withNewID() -> Annotation {
        Annotation(
            kind: kind,
            start: start,
            end: end,
            points: points,
            color: color,
            lineWidth: lineWidth,
            text: text,
            fontSize: fontSize,
            textStyle: textStyle,
            textAlignment: textAlignment,
            fontWeight: fontWeight,
            fontDesign: fontDesign,
            arrowStyle: arrowStyle,
            counterValue: counterValue,
            image: image,
            isLocked: false,
            isHidden: false
        )
    }
}
