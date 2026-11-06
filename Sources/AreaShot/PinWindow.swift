import AppKit

final class PinWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

final class PinWindowController: NSWindowController, NSWindowDelegate {
    private static var active: [PinWindowController] = []

    private let image: CGImage
    private let captureScale: CGFloat
    private let imageView: PinContentView
    private let closeButton: NSButton
    private let copyButton: NSButton
    private let resizeHandle = PinResizeHandle(frame: .zero)

    init(image: CGImage, captureScale: CGFloat = 2) {
        self.image = image
        self.captureScale = max(1, captureScale)

        let maxSize = NSSize(width: 520, height: 380)
        let fit = min(
            1,
            min(maxSize.width / CGFloat(image.width), maxSize.height / CGFloat(image.height))
        )
        let size = NSSize(
            width: max(160, CGFloat(image.width) * fit),
            height: max(120, CGFloat(image.height) * fit)
        )

        let window = PinWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.level = .floating
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false

        imageView = PinContentView(image: NSImage(cgImage: image, size: size))
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.wantsLayer = true
        imageView.layer?.cornerRadius = 6
        imageView.layer?.masksToBounds = true
        imageView.layer?.borderWidth = 1
        imageView.layer?.borderColor = NSColor.white.withAlphaComponent(0.15).cgColor

        let closeSymbol = NSImage(systemSymbolName: "xmark", accessibilityDescription: "关闭")?
            .withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: 11, weight: .bold))
        closeButton = NSButton(image: closeSymbol ?? NSImage(), target: nil, action: nil)

        let copySymbol = NSImage(systemSymbolName: "doc.on.doc", accessibilityDescription: "复制图片")?
            .withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: 10, weight: .semibold))
        copyButton = NSButton(image: copySymbol ?? NSImage(), target: nil, action: nil)

        super.init(window: window)
        window.delegate = self

        imageView.translatesAutoresizingMaskIntoConstraints = true
        window.contentView = imageView

        closeButton.isBordered = false
        closeButton.contentTintColor = .white
        closeButton.wantsLayer = true
        closeButton.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.6).cgColor
        closeButton.layer?.cornerRadius = 11
        closeButton.layer?.borderWidth = 1
        closeButton.layer?.borderColor = NSColor.white.withAlphaComponent(0.3).cgColor
        closeButton.target = self
        closeButton.action = #selector(closeTapped)
        closeButton.toolTip = "关闭"
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        imageView.addSubview(closeButton)

        copyButton.isBordered = false
        copyButton.contentTintColor = .white
        copyButton.wantsLayer = true
        copyButton.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.6).cgColor
        copyButton.layer?.cornerRadius = 11
        copyButton.layer?.borderWidth = 1
        copyButton.layer?.borderColor = NSColor.white.withAlphaComponent(0.3).cgColor
        copyButton.target = self
        copyButton.action = #selector(copyTapped)
        copyButton.toolTip = "复制图片"
        copyButton.translatesAutoresizingMaskIntoConstraints = false
        imageView.addSubview(copyButton)

        imageView.onCopy = { [weak self] in
            self?.copyTapped()
        }
        let menu = NSMenu()
        let copyItem = NSMenuItem(title: "复制图片", action: #selector(copyTapped), keyEquivalent: "c")
        copyItem.target = self
        menu.addItem(copyItem)
        menu.addItem(.separator())
        let closeItem = NSMenuItem(title: "关闭", action: #selector(closeTapped), keyEquivalent: "w")
        closeItem.target = self
        menu.addItem(closeItem)
        imageView.menu = menu

        resizeHandle.wantsLayer = true
        resizeHandle.layer?.backgroundColor = NSColor.controlAccentColor.cgColor
        resizeHandle.layer?.cornerRadius = 5
        resizeHandle.translatesAutoresizingMaskIntoConstraints = false
        resizeHandle.onDrag = { [weak self] dx, dy in
            self?.resize(dx: dx, dy: dy)
        }
        imageView.addSubview(resizeHandle)

        NSLayoutConstraint.activate([
            closeButton.trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: -8),
            closeButton.topAnchor.constraint(equalTo: imageView.topAnchor, constant: 8),
            closeButton.widthAnchor.constraint(equalToConstant: 22),
            closeButton.heightAnchor.constraint(equalToConstant: 22),

            copyButton.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -6),
            copyButton.topAnchor.constraint(equalTo: imageView.topAnchor, constant: 8),
            copyButton.widthAnchor.constraint(equalToConstant: 22),
            copyButton.heightAnchor.constraint(equalToConstant: 22),

            resizeHandle.trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: -6),
            resizeHandle.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -6),
            resizeHandle.widthAnchor.constraint(equalToConstant: 10),
            resizeHandle.heightAnchor.constraint(equalToConstant: 10)
        ])

        Self.active.append(self)
        positionNearMouse(size: size)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func positionNearMouse(size: NSSize) {
        guard let window else { return }
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first(where: { NSMouseInRect(mouse, $0.frame, false) }) ?? NSScreen.main
        var origin = NSPoint(x: mouse.x - 24, y: mouse.y - size.height + 24)
        if let visible = screen?.visibleFrame {
            origin.x = min(max(visible.minX, origin.x), visible.maxX - size.width)
            origin.y = min(max(visible.minY, origin.y), visible.maxY - size.height)
        }
        window.setFrameOrigin(origin)
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        window?.orderFrontRegardless()
        window?.makeFirstResponder(imageView)
    }

    func windowWillClose(_ notification: Notification) {
        Self.active.removeAll { $0 === self }
    }

    private func resize(dx: CGFloat, dy: CGFloat) {
        guard let window else { return }
        let aspect = CGFloat(image.width) / CGFloat(image.height)
        let current = window.frame.size
        var width = max(80, current.width + dx)
        var height = width / aspect
        if dy != 0 {
            let proposedHeight = max(60, current.height + dy)
            let proposedWidth = proposedHeight * aspect
            if abs(dy) > abs(dx) {
                height = proposedHeight
                width = proposedWidth
            }
        }
        window.setContentSize(NSSize(width: width, height: height))
    }

    @objc private func copyTapped() {
        let logicalSize = NSSize(
            width: CGFloat(image.width) / captureScale,
            height: CGFloat(image.height) / captureScale
        )
        let representation = NSBitmapImageRep(cgImage: image)
        representation.size = logicalSize
        let nsImage = NSImage(size: logicalSize)
        nsImage.addRepresentation(representation)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([nsImage])
    }

    @objc private func closeTapped() {
        window?.close()
    }
}

final class PinContentView: NSImageView {
    var onCopy: (() -> Void)?

    override var mouseDownCanMoveWindow: Bool { true }
    override var acceptsFirstResponder: Bool { true }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        window?.performDrag(with: event)
    }

    override func keyDown(with event: NSEvent) {
        if event.modifierFlags.contains(.command),
           event.charactersIgnoringModifiers?.lowercased() == "c" {
            onCopy?()
            return
        }
        super.keyDown(with: event)
    }
}

final class PinResizeHandle: NSView {
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
