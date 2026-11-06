import AppKit
import ScreenCaptureKit

enum SelectionResult {
    case area(NSScreen, CGRect)
    case window(SnapWindow, NSScreen)
    case cancelled
}

final class SelectionOverlayController {
    static let shared = SelectionOverlayController()

    private var windows: [SelectionWindow] = []
    private var views: [SelectionOverlayView] = []
    private var completion: ((SelectionResult) -> Void)?
    private var finished = false

    private init() {}

    func begin(allInOne: Bool = false, completion: @escaping (SelectionResult) -> Void) {
        self.completion = completion
        finished = false
        NSApp.activate(ignoringOtherApps: true)

        for screen in NSScreen.screens {
            let window = SelectionWindow(
                contentRect: screen.frame,
                styleMask: .borderless,
                backing: .buffered,
                defer: false
            )
            window.setFrame(screen.frame, display: true)
            window.level = .screenSaver
            window.backgroundColor = .clear
            window.isOpaque = false
            window.hasShadow = false
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            window.ignoresMouseEvents = false
            window.acceptsMouseMovedEvents = true
            window.isReleasedWhenClosed = false

            let view = SelectionOverlayView(frame: NSRect(origin: .zero, size: screen.frame.size))
            view.screenRef = screen
            view.onFinish = { [weak self] result in
                self?.finish(result)
            }
            window.contentView = view
            windows.append(window)
            views.append(view)
            window.makeKeyAndOrderFront(nil)
            window.makeFirstResponder(view)
        }

        if allInOne {
            let mouse = NSEvent.mouseLocation
            let target = NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) }
            views.first { $0.screenRef === target }?.addModeControl()
        }

        NSCursor.crosshair.set()
    }

    private func finish(_ result: SelectionResult) {
        guard !finished else { return }
        finished = true

        let completion = self.completion
        self.completion = nil

        for window in windows {
            window.orderOut(nil)
        }
        windows.removeAll()
        views.removeAll()
        NSCursor.arrow.set()
        completion?(result)
    }
}

final class SelectionWindow: NSWindow {
    override var canBecomeKey: Bool { true }
}

final class SelectionOverlayView: NSView {
    enum SelectionMode {
        case area
        case window
        case screen
    }

    var screenRef: NSScreen?
    var onFinish: ((SelectionResult) -> Void)?
    var mode: SelectionMode = .area {
        didSet { needsDisplay = true }
    }
    var snapWindows: [SnapWindow] = [] {
        didSet { needsDisplay = true }
    }

    private var startPoint: NSPoint?
    private var currentPoint: NSPoint?
    private var dragStarted = false
    private var hoveredWindow: SnapWindow?
    private var trackingArea: NSTrackingArea?
    private var windowModeClick = false

    func addModeControl() {
        let control = NSSegmentedControl(
            labels: ["区域", "窗口", "屏幕"],
            trackingMode: .selectOne,
            target: self,
            action: #selector(modeChanged(_:))
        )
        control.selectedSegment = 0
        control.segmentStyle = .texturedRounded
        let width: CGFloat = 210
        control.frame = NSRect(
            x: (bounds.width - width) / 2,
            y: bounds.height - 48,
            width: width,
            height: 30
        )
        control.autoresizingMask = [.minXMargin, .maxXMargin, .minYMargin]
        addSubview(control)
    }

    @objc private func modeChanged(_ sender: NSSegmentedControl) {
        switch sender.selectedSegment {
        case 1:
            mode = .window
        case 2:
            mode = .screen
            if let screen = screenRef {
                onFinish?(.area(screen, CGRect(origin: .zero, size: screen.frame.size)))
            }
        default:
            mode = .area
        }
    }

    override var acceptsFirstResponder: Bool { true }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingArea {
            removeTrackingArea(trackingArea)
        }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseMoved, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingArea = area
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .crosshair)
    }

    override func mouseMoved(with event: NSEvent) {
        guard startPoint == nil else { return }
        hoveredWindow = windowUnderMouse(event)
        needsDisplay = true
    }

    override func mouseDown(with event: NSEvent) {
        if mode == .window {
            windowModeClick = true
            return
        }
        startPoint = convert(event.locationInWindow, from: nil)
        currentPoint = startPoint
        dragStarted = false
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        if mode == .window {
            return
        }
        guard let start = startPoint else { return }
        currentPoint = convert(event.locationInWindow, from: nil)
        if let current = currentPoint,
           hypot(current.x - start.x, current.y - start.y) > 3 {
            dragStarted = true
            hoveredWindow = nil
        }
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        if windowModeClick {
            windowModeClick = false
            if let hovered = hoveredWindow, let screen = screenRef {
                onFinish?(.window(hovered, screen))
            } else {
                onFinish?(.cancelled)
            }
            return
        }
        guard let start = startPoint else { return }
        let end = convert(event.locationInWindow, from: nil)
        currentPoint = end
        let rect = standardizedRect(from: start, to: end)
        let wasDragging = dragStarted
        let hovered = hoveredWindow
        startPoint = nil
        currentPoint = nil
        dragStarted = false
        hoveredWindow = nil
        needsDisplay = true

        if wasDragging, rect.width >= 2, rect.height >= 2, let screen = screenRef {
            onFinish?(.area(screen, rect))
        } else if let hovered, let screen = screenRef {
            onFinish?(.window(hovered, screen))
        } else {
            onFinish?(.cancelled)
        }
    }

    override func rightMouseDown(with event: NSEvent) {
        onFinish?(.cancelled)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape
            onFinish?(.cancelled)
        } else {
            super.keyDown(with: event)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        context.setFillColor(NSColor.black.withAlphaComponent(0.45).cgColor)
        context.fill(bounds)

        if let rect = activeRect() {
            context.setBlendMode(.clear)
            context.fill(rect)
            context.setBlendMode(.normal)

            context.setStrokeColor(NSColor.controlAccentColor.cgColor)
            context.setLineWidth(hoveredWindow != nil && !dragStarted ? 2 : 1)
            context.stroke(rect.insetBy(dx: 0.5, dy: 0.5))

            drawDimensionLabel(for: rect)
        }
    }

    private func activeRect() -> NSRect? {
        if let hoveredWindow, !dragStarted {
            return viewRect(for: hoveredWindow.bounds)
        }
        guard let start = startPoint, let current = currentPoint else { return nil }
        return standardizedRect(from: start, to: current)
    }

    private func windowUnderMouse(_ event: NSEvent) -> SnapWindow? {
        guard let viewWindow = window else { return nil }
        let viewPoint = convert(event.locationInWindow, from: nil)
        let screenPoint = viewWindow.convertPoint(toScreen: viewPoint)
        let primaryHeight = NSScreen.screens.first?.frame.height ?? 0
        let cgPoint = NSPoint(x: screenPoint.x, y: primaryHeight - screenPoint.y)
        return snapWindows.first { $0.bounds.contains(cgPoint) }
    }

    private func viewRect(for cgRect: CGRect) -> NSRect {
        guard let screen = screenRef else { return .zero }
        let primaryHeight = NSScreen.screens.first?.frame.height ?? 0
        let appKitY = primaryHeight - cgRect.maxY
        return NSRect(
            x: cgRect.minX - screen.frame.minX,
            y: appKitY - screen.frame.minY,
            width: cgRect.width,
            height: cgRect.height
        )
    }

    private func standardizedRect(from start: NSPoint, to end: NSPoint) -> NSRect {
        NSRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )
    }

    private func drawDimensionLabel(for rect: NSRect) {
        let scale = screenRef?.backingScaleFactor ?? 1
        let sizeText = "\(Int(rect.width * scale)) \u{00D7} \(Int(rect.height * scale))"
        let text: String
        if let hoveredWindow, !dragStarted {
            let appName = hoveredWindow.window.owningApplication?.applicationName ?? ""
            let title = hoveredWindow.window.title ?? ""
            let name = [appName, title].filter { !$0.isEmpty }.joined(separator: " \u{2014} ")
            text = name.isEmpty ? sizeText : "\(name)  \(sizeText)"
        } else {
            text = sizeText
        }

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium),
            .foregroundColor: NSColor.white
        ]
        let textSize = (text as NSString).size(withAttributes: attributes)

        var labelRect = NSRect(
            x: rect.minX,
            y: rect.maxY + 6,
            width: min(textSize.width + 12, bounds.width - rect.minX),
            height: textSize.height + 6
        )
        if labelRect.maxY > bounds.maxY {
            labelRect.origin.y = rect.maxY - labelRect.height - 6
        }
        if labelRect.maxX > bounds.maxX {
            labelRect.origin.x = bounds.maxX - labelRect.width
        }

        NSColor.black.withAlphaComponent(0.72).setFill()
        NSBezierPath(roundedRect: labelRect, xRadius: 4, yRadius: 4).fill()

        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byTruncatingTail
        var textAttributes = attributes
        textAttributes[.paragraphStyle] = paragraph
        (text as NSString).draw(
            in: NSRect(
                x: labelRect.minX + 6,
                y: labelRect.minY + 3,
                width: labelRect.width - 12,
                height: textSize.height
            ),
            withAttributes: textAttributes
        )
    }
}
