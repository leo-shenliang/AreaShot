import AppKit
import ImageIO
import UniformTypeIdentifiers

final class EditorWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

final class ToolbarButton: NSButton {
    var isSelectedState = false {
        didSet { needsDisplay = true }
    }

    private var isHovered = false
    private var hoverTrackingArea: NSTrackingArea?

    init(image: NSImage, target: AnyObject?, action: Selector?) {
        super.init(frame: .zero)
        self.image = image
        self.target = target
        self.action = action
        isBordered = false
        bezelStyle = .regularSquare
        focusRingType = .none
        imagePosition = .imageOnly
        contentTintColor = .labelColor
        translatesAutoresizingMaskIntoConstraints = false
        widthAnchor.constraint(equalToConstant: 26).isActive = true
        heightAnchor.constraint(equalToConstant: 26).isActive = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let hoverTrackingArea {
            removeTrackingArea(hoverTrackingArea)
        }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        hoverTrackingArea = area
    }

    override func mouseEntered(with event: NSEvent) {
        isHovered = true
        needsDisplay = true
    }

    override func mouseExited(with event: NSEvent) {
        isHovered = false
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        if isSelectedState || isHovered || isHighlighted {
            let fill: NSColor
            if isSelectedState {
                fill = NSColor.controlAccentColor.withAlphaComponent(0.2)
            } else if isHighlighted {
                fill = NSColor.labelColor.withAlphaComponent(0.16)
            } else {
                fill = NSColor.labelColor.withAlphaComponent(0.08)
            }
            fill.setFill()
            NSBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), xRadius: 6, yRadius: 6).fill()
        }
        super.draw(dirtyRect)
    }
}

final class AnnotationEditorWindowController: NSWindowController, NSWindowDelegate {
    var onClose: (() -> Void)?

    private let canvas: AnnotationCanvasView
    private let captureScale: CGFloat
    private let editorScreen: NSScreen
    private let logicalScale: CGFloat
    private let maxZoomScale: CGFloat
    private let minZoomScale: CGFloat = 0.05
    private var currentScale: CGFloat
    private let editorOuterMargin: CGFloat = 16
    private let editorGap: CGFloat = 12
    private let editorToolBarHeight: CGFloat = 38
    private let editorBottomBarHeight: CGFloat = 34
    private let editorBarGap: CGFloat = 8
    private var canvasWidthConstraint: NSLayoutConstraint?
    private var canvasHeightConstraint: NSLayoutConstraint?

    private var toolControl: NSSegmentedControl?
    private var optionsStack: NSStackView?
    private var selectedTool: AnnotationTool = .select
    private var colorButton: ToolbarButton?
    private var thicknessButton: ToolbarButton?
    private var arrowStyleButton: ToolbarButton?
    private var textOptionsButton: ToolbarButton?
    private var spotlightButton: ToolbarButton?
    private var spotlightShapeButton: ToolbarButton?
    private var intensityButton: ToolbarButton?
    private var counterButton: ToolbarButton?
    private var layersButton: ToolbarButton?
    private var emojiButton: ToolbarButton?
    private var zoomLabelButton: NSButton?

    private var colorPopover: NSPopover?
    private var widthPopover: NSPopover?
    private var layersPopover: NSPopover?
    private var spotlightPopover: NSPopover?
    private var intensityPopover: NSPopover?
    private var layersStack: NSStackView?
    private var layersScroll: NSScrollView?

    private let presetColors: [NSColor] = [
        .systemRed, .systemOrange, .systemYellow, .systemGreen,
        .systemBlue, .systemPurple, .white, .black
    ]

    init(image: CGImage, screen: NSScreen) {
        editorScreen = screen
        captureScale = max(1, screen.backingScaleFactor)
        logicalScale = 1 / captureScale

        let imageWidth = CGFloat(image.width)
        let imageHeight = CGFloat(image.height)
        let availableWidth = max(320, screen.visibleFrame.width - 80)
        let availableHeight = max(240, screen.visibleFrame.height - 220)
        maxZoomScale = max(
            logicalScale,
            min(2, min(availableWidth / imageWidth, availableHeight / imageHeight))
        )
        currentScale = min(logicalScale, maxZoomScale)
        canvas = AnnotationCanvasView(image: image, displayScale: currentScale)
        if let saved = AnnotationTool(rawValue: UserDefaults.standard.integer(forKey: "markupLastToolIndex")) {
            selectedTool = saved
            canvas.tool = saved
        }

        let outerMargin = editorOuterMargin
        let desiredWidth = max(canvas.frame.width + outerMargin * 2, 900)
        let contentWidth = min(desiredWidth, max(600, screen.visibleFrame.width - 40))
        let contentHeight = outerMargin
            + canvas.frame.height
            + editorGap
            + editorToolBarHeight
            + editorBarGap
            + editorBottomBarHeight
            + outerMargin

        let window = EditorWindow(
            contentRect: NSRect(origin: .zero, size: NSSize(width: contentWidth, height: contentHeight)),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.title = "标注"
        window.level = .floating
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.isReleasedWhenClosed = false
        window.appearance = NSAppearance(named: .aqua)

        let contentView = NSView()
        window.contentView = contentView

        super.init(window: window)
        window.delegate = self

        setupUI(in: contentView, outerMargin: outerMargin)

        canvas.onMagnify = { [weak self] magnification in
            guard let self else { return }
            self.applyZoom(self.currentScale * (1 + magnification))
        }

        let originX = screen.frame.midX - contentWidth / 2
        let originY = screen.frame.midY - contentHeight / 2
        window.setFrameOrigin(NSPoint(x: originX, y: originY))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI(in contentView: NSView, outerMargin: CGFloat) {
        let card = NSView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.wantsLayer = true
        card.layer?.shadowColor = NSColor.black.cgColor
        card.layer?.shadowOpacity = 0.3
        card.layer?.shadowRadius = 12
        card.layer?.shadowOffset = CGSize(width: 0, height: -2)

        canvas.translatesAutoresizingMaskIntoConstraints = false
        canvas.wantsLayer = true
        canvas.layer?.cornerRadius = 8
        canvas.layer?.masksToBounds = true
        canvas.layer?.borderWidth = 1
        canvas.layer?.borderColor = NSColor.black.withAlphaComponent(0.12).cgColor
        card.addSubview(canvas)

        let (toolBarShadow, toolBarPill) = makePill()
        let toolBar = makeToolBar()
        toolBarPill.addSubview(toolBar)

        let (bottomBarShadow, bottomBarPill) = makePill()
        let bottomBar = makeBottomBar()
        bottomBarPill.addSubview(bottomBar)

        contentView.addSubview(card)
        contentView.addSubview(toolBarShadow)
        contentView.addSubview(bottomBarShadow)

        let canvasWidthConstraint = canvas.widthAnchor.constraint(equalToConstant: canvas.frame.width)
        let canvasHeightConstraint = canvas.heightAnchor.constraint(equalToConstant: canvas.frame.height)
        self.canvasWidthConstraint = canvasWidthConstraint
        self.canvasHeightConstraint = canvasHeightConstraint

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: outerMargin),
            card.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            canvas.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            canvas.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            canvas.topAnchor.constraint(equalTo: card.topAnchor),
            canvas.bottomAnchor.constraint(equalTo: card.bottomAnchor),
            canvasWidthConstraint,
            canvasHeightConstraint,

            toolBarShadow.topAnchor.constraint(equalTo: card.bottomAnchor, constant: editorGap),
            toolBarShadow.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            toolBarShadow.heightAnchor.constraint(equalToConstant: editorToolBarHeight),

            toolBarPill.leadingAnchor.constraint(equalTo: toolBarShadow.leadingAnchor),
            toolBarPill.trailingAnchor.constraint(equalTo: toolBarShadow.trailingAnchor),
            toolBarPill.topAnchor.constraint(equalTo: toolBarShadow.topAnchor),
            toolBarPill.bottomAnchor.constraint(equalTo: toolBarShadow.bottomAnchor),

            toolBar.leadingAnchor.constraint(equalTo: toolBarPill.leadingAnchor, constant: 8),
            toolBar.trailingAnchor.constraint(equalTo: toolBarPill.trailingAnchor, constant: -8),
            toolBar.centerYAnchor.constraint(equalTo: toolBarPill.centerYAnchor),

            bottomBarShadow.topAnchor.constraint(equalTo: toolBarShadow.bottomAnchor, constant: editorBarGap),
            bottomBarShadow.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            bottomBarShadow.heightAnchor.constraint(equalToConstant: editorBottomBarHeight),
            bottomBarShadow.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -outerMargin),

            bottomBarPill.leadingAnchor.constraint(equalTo: bottomBarShadow.leadingAnchor),
            bottomBarPill.trailingAnchor.constraint(equalTo: bottomBarShadow.trailingAnchor),
            bottomBarPill.topAnchor.constraint(equalTo: bottomBarShadow.topAnchor),
            bottomBarPill.bottomAnchor.constraint(equalTo: bottomBarShadow.bottomAnchor),

            bottomBar.leadingAnchor.constraint(equalTo: bottomBarPill.leadingAnchor, constant: 8),
            bottomBar.trailingAnchor.constraint(equalTo: bottomBarPill.trailingAnchor, constant: -8),
            bottomBar.centerYAnchor.constraint(equalTo: bottomBarPill.centerYAnchor)
        ])

        rebuildOptions(for: selectedTool)
        updateZoomLabel()
        window?.makeFirstResponder(canvas)
    }

    private func makePill() -> (NSView, NSVisualEffectView) {
        let shadow = NSView()
        shadow.translatesAutoresizingMaskIntoConstraints = false
        shadow.wantsLayer = true
        shadow.layer?.shadowColor = NSColor.black.cgColor
        shadow.layer?.shadowOpacity = 0.22
        shadow.layer?.shadowRadius = 10
        shadow.layer?.shadowOffset = CGSize(width: 0, height: -1)

        let pill = NSVisualEffectView()
        pill.translatesAutoresizingMaskIntoConstraints = false
        pill.material = .popover
        pill.blendingMode = .behindWindow
        pill.state = .active
        pill.wantsLayer = true
        pill.layer?.cornerRadius = 12
        pill.layer?.masksToBounds = true
        pill.layer?.borderWidth = 1
        pill.layer?.borderColor = NSColor.white.withAlphaComponent(0.55).cgColor
        shadow.addSubview(pill)
        return (shadow, pill)
    }

    private func makeToolBar() -> NSStackView {
        let images: [NSImage] = AnnotationTool.allCases.map { tool in
            let configuration = NSImage.SymbolConfiguration(pointSize: 12, weight: .regular)
            return NSImage(systemSymbolName: tool.symbolName, accessibilityDescription: tool.title)?
                .withSymbolConfiguration(configuration)
                ?? NSImage(size: NSSize(width: 12, height: 12))
        }
        let control = NSSegmentedControl(
            images: images,
            trackingMode: .selectOne,
            target: self,
            action: #selector(toolSegmentChanged(_:))
        )
        control.segmentStyle = .capsule
        control.selectedSegment = selectedTool.rawValue
        control.translatesAutoresizingMaskIntoConstraints = false
        control.heightAnchor.constraint(equalToConstant: 28).isActive = true
        for (index, tool) in AnnotationTool.allCases.enumerated() {
            control.setWidth(30, forSegment: index)
            control.setToolTip(tool.title, forSegment: index)
        }
        toolControl = control

        thicknessButton = makeIconButton(
            symbolName: "lineweight",
            tooltip: "线宽",
            action: #selector(showWidthPopover)
        )
        colorButton = makeIconButton(
            symbolName: "paintpalette",
            tooltip: "颜色",
            action: #selector(showColorPopover)
        )
        colorButton?.image = swatchImage(color: canvas.currentColor)
        arrowStyleButton = makeIconButton(
            symbolName: "arrow.up.right",
            tooltip: "箭头样式",
            action: #selector(showArrowStyleMenu)
        )
        textOptionsButton = makeIconButton(
            symbolName: "textformat.size",
            tooltip: "文字样式",
            action: #selector(showStyleMenu)
        )
        spotlightButton = makeIconButton(
            symbolName: "flashlight.on.fill",
            tooltip: "聚光灯暗度",
            action: #selector(showSpotlightPopover)
        )
        spotlightShapeButton = makeIconButton(
            symbolName: canvas.currentSpotlightShape.symbolName,
            tooltip: "聚光灯形状",
            action: #selector(showSpotlightShapeMenu)
        )
        intensityButton = makeIconButton(
            symbolName: "slider.horizontal.3",
            tooltip: "强度",
            action: #selector(showIntensityPopover)
        )
        counterButton = makeIconButton(
            symbolName: "number.circle",
            tooltip: "序号设置",
            action: #selector(showCounterMenu)
        )

        let options = NSStackView()
        options.orientation = .horizontal
        options.spacing = 3
        options.alignment = .centerY
        options.translatesAutoresizingMaskIntoConstraints = false
        optionsStack = options

        let toolbar = NSStackView(views: [control, makeDivider(), options])
        toolbar.orientation = .horizontal
        toolbar.spacing = 6
        toolbar.alignment = .centerY
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        return toolbar
    }

    private func makeBottomBar() -> NSStackView {
        let zoom = NSButton(title: "100%", target: self, action: #selector(showZoomMenu))
        zoom.isBordered = false
        zoom.focusRingType = .none
        zoom.translatesAutoresizingMaskIntoConstraints = false
        zoom.widthAnchor.constraint(equalToConstant: 44).isActive = true
        zoom.heightAnchor.constraint(equalToConstant: 26).isActive = true
        zoom.toolTip = "缩放"
        zoomLabelButton = zoom

        layersButton = makeIconButton(
            symbolName: "square.3.layers.3d",
            tooltip: "图层",
            action: #selector(showLayersPopover)
        )
        emojiButton = makeIconButton(
            symbolName: "face.smiling",
            tooltip: "插入 Emoji",
            action: #selector(showEmojiMenu)
        )

        let views: [NSView] = [
            zoom,
            makeDivider(),
            layersButton!,
            makeDivider(),
            makeIconButton(symbolName: "arrow.uturn.backward", tooltip: "撤销", action: #selector(undoTapped)),
            makeIconButton(symbolName: "arrow.uturn.forward", tooltip: "重做", action: #selector(redoTapped)),
            makeDivider(),
            makeIconButton(symbolName: "photo", tooltip: "插入图片", action: #selector(insertImageTapped)),
            emojiButton!,
            makeIconButton(symbolName: "pin", tooltip: "钉在屏幕上", action: #selector(pinTapped)),
            makeIconButton(symbolName: "doc.on.doc", tooltip: "复制", action: #selector(copyTapped)),
            makeIconButton(symbolName: "square.and.arrow.down", tooltip: "保存", action: #selector(saveTapped)),
            makeIconButton(symbolName: "xmark", tooltip: "关闭", action: #selector(closeTapped))
        ]

        let bar = NSStackView(views: views)
        bar.orientation = .horizontal
        bar.spacing = 3
        bar.alignment = .centerY
        bar.translatesAutoresizingMaskIntoConstraints = false
        return bar
    }

    private func makeIconButton(symbolName: String, tooltip: String, action: Selector) -> ToolbarButton {
        let configuration = NSImage.SymbolConfiguration(pointSize: 13, weight: .regular)
        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: tooltip)?
            .withSymbolConfiguration(configuration) ?? NSImage(size: NSSize(width: 13, height: 13))
        let button = ToolbarButton(image: image, target: self, action: action)
        button.toolTip = tooltip
        return button
    }

    private func makeDivider() -> NSView {
        let divider = NSView()
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.wantsLayer = true
        divider.layer?.backgroundColor = NSColor.separatorColor.withAlphaComponent(0.5).cgColor
        divider.widthAnchor.constraint(equalToConstant: 1).isActive = true
        divider.heightAnchor.constraint(equalToConstant: 16).isActive = true
        return divider
    }

    private func swatchImage(color: NSColor) -> NSImage {
        let size = NSSize(width: 16, height: 16)
        let image = NSImage(size: size)
        image.lockFocus()
        let rect = NSRect(x: 1.5, y: 1.5, width: 13, height: 13)
        let path = NSBezierPath(ovalIn: rect)
        color.setFill()
        path.fill()
        NSColor.separatorColor.setStroke()
        path.lineWidth = 1
        path.stroke()
        image.unlockFocus()
        image.isTemplate = false
        return image
    }

    private func rebuildOptions(for tool: AnnotationTool) {
        guard let optionsStack else { return }
        for view in optionsStack.arrangedSubviews {
            optionsStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        func add(_ view: ToolbarButton?) {
            guard let view else { return }
            optionsStack.addArrangedSubview(view)
        }

        switch tool {
        case .select:
            add(thicknessButton)
            add(colorButton)
        case .arrow:
            add(thicknessButton)
            add(arrowStyleButton)
            add(colorButton)
        case .line, .rectangle, .ellipse, .pen, .highlight, .loupe:
            add(thicknessButton)
            add(colorButton)
        case .text:
            add(textOptionsButton)
            add(colorButton)
        case .counter:
            add(thicknessButton)
            add(counterButton)
            add(colorButton)
        case .spotlight:
            add(spotlightButton)
            add(spotlightShapeButton)
            add(colorButton)
        case .pixelate, .blur:
            add(intensityButton)
        case .redact:
            add(colorButton)
        }
    }

    private func updateZoomLabel() {
        guard let zoomLabelButton else { return }
        let percent = Int((currentScale / logicalScale * 100).rounded())
        zoomLabelButton.attributedTitle = NSAttributedString(
            string: "\(percent)%",
            attributes: [
                .font: NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium),
                .foregroundColor: NSColor.secondaryLabelColor
            ]
        )
    }

    override func showWindow(_ sender: Any?) {
        guard let window else { return }
        window.alphaValue = 0
        super.showWindow(sender)
        window.makeKeyAndOrderFront(sender)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            window.animator().alphaValue = 1
        }
        window.makeFirstResponder(canvas)
    }

    func windowWillClose(_ notification: Notification) {
        onClose?()
    }

    // MARK: - Tool bar

    @objc private func toolSegmentChanged(_ sender: NSSegmentedControl) {
        guard sender.selectedSegment >= 0,
              AnnotationTool.allCases.indices.contains(sender.selectedSegment)
        else {
            return
        }
        canvas.finishTextEditing()
        let tool = AnnotationTool.allCases[sender.selectedSegment]
        selectedTool = tool
        canvas.tool = tool
        UserDefaults.standard.set(tool.rawValue, forKey: "markupLastToolIndex")
        rebuildOptions(for: tool)
        window?.makeFirstResponder(canvas)
    }

    @objc private func showArrowStyleMenu() {
        guard let arrowStyleButton else { return }
        let menu = NSMenu()
        for style in ArrowStyle.allCases {
            let item = NSMenuItem(title: style.title, action: #selector(arrowStyleMenuSelected(_:)), keyEquivalent: "")
            item.target = self
            item.tag = style.rawValue
            item.state = style == canvas.currentArrowStyle ? .on : .off
            menu.addItem(item)
        }
        menu.popUp(
            positioning: nil,
            at: NSPoint(x: 0, y: arrowStyleButton.bounds.maxY + 4),
            in: arrowStyleButton
        )
    }

    @objc private func showSpotlightPopover() {
        guard let spotlightButton else { return }
        spotlightPopover?.close()

        let content = NSView(frame: NSRect(x: 0, y: 0, width: 216, height: 64))
        let slider = NSSlider(
            value: Double(canvas.currentSpotlightOpacity),
            minValue: 0.05,
            maxValue: 0.9,
            target: self,
            action: #selector(spotlightSliderChanged(_:))
        )
        slider.frame = NSRect(x: 12, y: 30, width: 192, height: 24)
        content.addSubview(slider)

        let label = NSTextField(labelWithString: "暗度：\(Int(canvas.currentSpotlightOpacity * 100))%")
        label.frame = NSRect(x: 12, y: 8, width: 192, height: 16)
        label.font = .systemFont(ofSize: 11)
        label.textColor = .secondaryLabelColor
        label.tag = 100
        content.addSubview(label)

        let viewController = NSViewController()
        viewController.view = content
        let popover = NSPopover()
        popover.behavior = .transient
        popover.contentViewController = viewController
        popover.show(relativeTo: spotlightButton.bounds, of: spotlightButton, preferredEdge: .maxY)
        spotlightPopover = popover
    }

    @objc private func spotlightSliderChanged(_ sender: NSSlider) {
        let value = CGFloat(sender.doubleValue)
        canvas.applySpotlightOpacity(value)
        (sender.superview?.viewWithTag(100) as? NSTextField)?.stringValue =
            "暗度：\(Int(value * 100))%"
    }

    @objc private func showSpotlightShapeMenu() {
        guard let spotlightShapeButton else { return }
        let menu = NSMenu()
        for shape in SpotlightShape.allCases {
            let item = NSMenuItem(title: shape.title, action: #selector(spotlightShapeSelected(_:)), keyEquivalent: "")
            item.target = self
            item.tag = shape.rawValue
            item.state = shape == canvas.currentSpotlightShape ? .on : .off
            menu.addItem(item)
        }
        menu.popUp(
            positioning: nil,
            at: NSPoint(x: 0, y: spotlightShapeButton.bounds.maxY + 4),
            in: spotlightShapeButton
        )
    }

    @objc private func spotlightShapeSelected(_ sender: NSMenuItem) {
        guard let shape = SpotlightShape(rawValue: sender.tag) else { return }
        canvas.applySpotlightShape(shape)
        spotlightShapeButton?.image = NSImage(
            systemSymbolName: shape.symbolName,
            accessibilityDescription: shape.title
        )?.withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: 13, weight: .regular))
        window?.makeFirstResponder(canvas)
    }

    @objc private func showIntensityPopover() {
        guard let intensityButton else { return }
        intensityPopover?.close()

        let isBlur = selectedTool == .blur
        let value = isBlur ? canvas.currentBlurIntensity : canvas.currentPixelateIntensity

        let content = NSView(frame: NSRect(x: 0, y: 0, width: 216, height: 64))
        let slider = NSSlider(
            value: Double(value),
            minValue: 2,
            maxValue: 40,
            target: self,
            action: #selector(intensitySliderChanged(_:))
        )
        slider.frame = NSRect(x: 12, y: 30, width: 192, height: 24)
        content.addSubview(slider)

        let label = NSTextField(labelWithString: "强度：\(Int(value))")
        label.frame = NSRect(x: 12, y: 8, width: 192, height: 16)
        label.font = .systemFont(ofSize: 11)
        label.textColor = .secondaryLabelColor
        label.tag = 100
        content.addSubview(label)

        let viewController = NSViewController()
        viewController.view = content
        let popover = NSPopover()
        popover.behavior = .transient
        popover.contentViewController = viewController
        popover.show(relativeTo: intensityButton.bounds, of: intensityButton, preferredEdge: .maxY)
        intensityPopover = popover
    }

    @objc private func intensitySliderChanged(_ sender: NSSlider) {
        let value = CGFloat(sender.doubleValue)
        canvas.applyIntensity(value)
        (sender.superview?.viewWithTag(100) as? NSTextField)?.stringValue =
            "强度：\(Int(value.rounded()))"
    }

    @objc private func showCounterMenu() {
        guard let counterButton else { return }
        let menu = NSMenu()
        let reset = NSMenuItem(title: "将序号重置为 1", action: #selector(resetCounterTapped), keyEquivalent: "")
        reset.target = self
        menu.addItem(reset)
        menu.popUp(
            positioning: nil,
            at: NSPoint(x: 0, y: counterButton.bounds.maxY + 4),
            in: counterButton
        )
    }

    @objc private func resetCounterTapped() {
        canvas.resetCounter()
        window?.makeFirstResponder(canvas)
    }

    // MARK: - Zoom

    @objc private func showZoomMenu() {
        guard let zoomLabelButton else { return }
        let menu = NSMenu()

        let fitItem = NSMenuItem(title: "适应窗口", action: #selector(zoomMenuSelected(_:)), keyEquivalent: "")
        fitItem.target = self
        fitItem.tag = -1
        fitItem.state = abs(currentScale - fitScale()) < 0.001 ? .on : .off
        menu.addItem(fitItem)
        menu.addItem(.separator())

        for percent in [50, 75, 100, 125, 150, 200] {
            let item = NSMenuItem(title: "\(percent)%", action: #selector(zoomMenuSelected(_:)), keyEquivalent: "")
            item.target = self
            item.tag = percent
            let target = logicalScale * CGFloat(percent) / 100
            item.state = abs(currentScale - target) < 0.001 ? .on : .off
            menu.addItem(item)
        }

        menu.popUp(
            positioning: nil,
            at: NSPoint(x: 0, y: zoomLabelButton.bounds.maxY + 4),
            in: zoomLabelButton
        )
    }

    @objc private func zoomMenuSelected(_ sender: NSMenuItem) {
        if sender.tag == -1 {
            applyZoom(fitScale())
        } else {
            applyZoom(logicalScale * CGFloat(sender.tag) / 100)
        }
    }

    private func fitScale() -> CGFloat {
        let imageWidth = CGFloat(canvas.baseImage.width)
        let imageHeight = CGFloat(canvas.baseImage.height)
        let availableWidth = max(320, editorScreen.visibleFrame.width - 80)
        let availableHeight = max(240, editorScreen.visibleFrame.height - 220)
        return min(maxZoomScale, min(availableWidth / imageWidth, availableHeight / imageHeight))
    }

    private func applyZoom(_ requested: CGFloat) {
        let clamped = min(maxZoomScale, max(minZoomScale, requested))
        guard abs(clamped - currentScale) > 0.0001 else { return }

        canvas.finishTextEditing()
        currentScale = clamped
        canvas.setDisplayScale(clamped)
        canvasWidthConstraint?.constant = canvas.frame.width
        canvasHeightConstraint?.constant = canvas.frame.height
        updateZoomLabel()

        let contentWidth = min(
            max(canvas.frame.width + editorOuterMargin * 2, 900),
            max(600, editorScreen.visibleFrame.width - 40)
        )
        let contentHeight = editorOuterMargin
            + canvas.frame.height
            + editorGap
            + editorToolBarHeight
            + editorBarGap
            + editorBottomBarHeight
            + editorOuterMargin

        guard let window else { return }
        window.setContentSize(NSSize(width: contentWidth, height: contentHeight))
        let originX = editorScreen.frame.midX - contentWidth / 2
        let originY = editorScreen.frame.midY - contentHeight / 2
        window.setFrameOrigin(NSPoint(x: originX, y: originY))
        window.layoutIfNeeded()
        canvas.needsDisplay = true
    }

    // MARK: - Style & color

    @objc private func showStyleMenu() {
        guard let textOptionsButton else { return }
        let menu = NSMenu()

        for style in TextStyle.allCases {
            let item = NSMenuItem(title: style.title, action: #selector(styleMenuSelected(_:)), keyEquivalent: "")
            item.target = self
            item.tag = style.rawValue
            item.state = style == canvas.currentTextStyle ? .on : .off
            menu.addItem(item)
        }

        menu.addItem(.separator())
        menu.addItem(makeSubmenu(title: "对齐", items: TextAlignmentOption.allCases.map {
            ($0.title, $0.rawValue, #selector(alignmentMenuSelected(_:)), $0 == canvas.currentTextAlignment)
        }))
        menu.addItem(makeSubmenu(title: "字重", items: FontWeightOption.allCases.map {
            ($0.title, $0.rawValue, #selector(weightMenuSelected(_:)), $0 == canvas.currentFontWeight)
        }))
        menu.addItem(makeSubmenu(title: "字体", items: FontDesignOption.allCases.map {
            ($0.title, $0.rawValue, #selector(fontMenuSelected(_:)), $0 == canvas.currentFontDesign)
        }))
        menu.addItem(makeSubmenu(title: "字号", items: [16, 20, 24, 28, 36, 48, 64].map {
            ("\($0) px", $0, #selector(fontSizeMenuSelected(_:)), CGFloat($0) == canvas.currentFontSize)
        }))

        menu.popUp(
            positioning: nil,
            at: NSPoint(x: 0, y: textOptionsButton.bounds.maxY + 4),
            in: textOptionsButton
        )
    }

    private func makeSubmenu(
        title: String,
        items: [(String, Int, Selector, Bool)]
    ) -> NSMenuItem {
        let parent = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        let submenu = NSMenu()
        for (itemTitle, tag, action, isSelected) in items {
            let item = NSMenuItem(title: itemTitle, action: action, keyEquivalent: "")
            item.target = self
            item.tag = tag
            item.state = isSelected ? .on : .off
            submenu.addItem(item)
        }
        parent.submenu = submenu
        return parent
    }

    @objc private func showColorPopover() {
        guard let colorButton else { return }
        colorPopover?.close()

        let content = NSView(frame: NSRect(x: 0, y: 0, width: 224, height: 92))
        let well = NSColorWell(frame: NSRect(x: 12, y: 48, width: 44, height: 28))
        well.color = canvas.currentColor
        well.target = self
        well.action = #selector(popoverColorChanged(_:))
        content.addSubview(well)

        for (index, color) in presetColors.enumerated() {
            let button = NSButton(frame: NSRect(x: 12 + index * 25, y: 12, width: 20, height: 20))
            button.isBordered = false
            button.wantsLayer = true
            button.layer?.backgroundColor = cgColor(color)
            button.layer?.cornerRadius = 10
            button.layer?.borderWidth = 1
            button.layer?.borderColor = NSColor.separatorColor.cgColor
            button.target = self
            button.action = #selector(presetColorClicked(_:))
            button.tag = index
            content.addSubview(button)
        }

        let viewController = NSViewController()
        viewController.view = content
        let popover = NSPopover()
        popover.behavior = .transient
        popover.contentViewController = viewController
        popover.show(relativeTo: colorButton.bounds, of: colorButton, preferredEdge: .maxY)
        colorPopover = popover
    }

    @objc private func showWidthPopover() {
        guard let thicknessButton else { return }
        widthPopover?.close()

        let content = NSView(frame: NSRect(x: 0, y: 0, width: 216, height: 64))
        let slider = NSSlider(
            value: Double(canvas.currentLineWidth),
            minValue: 1,
            maxValue: 12,
            target: self,
            action: #selector(widthSliderChanged(_:))
        )
        slider.frame = NSRect(x: 12, y: 30, width: 192, height: 24)
        content.addSubview(slider)

        let label = NSTextField(labelWithString: "线宽：\(Int(canvas.currentLineWidth))")
        label.frame = NSRect(x: 12, y: 8, width: 192, height: 16)
        label.font = .systemFont(ofSize: 11)
        label.textColor = .secondaryLabelColor
        label.tag = 100
        content.addSubview(label)

        let viewController = NSViewController()
        viewController.view = content
        let popover = NSPopover()
        popover.behavior = .transient
        popover.contentViewController = viewController
        popover.show(relativeTo: thicknessButton.bounds, of: thicknessButton, preferredEdge: .maxY)
        widthPopover = popover
    }

    // MARK: - Layers

    @objc private func showLayersPopover() {
        guard let layersButton else { return }
        layersPopover?.close()

        let container = NSView(frame: NSRect(x: 0, y: 0, width: 260, height: 240))
        let scroll = NSScrollView(frame: NSRect(x: 0, y: 0, width: 260, height: 240))
        scroll.hasVerticalScroller = true
        scroll.drawsBackground = false
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 2
        stack.alignment = .leading
        stack.translatesAutoresizingMaskIntoConstraints = true
        scroll.documentView = stack
        container.addSubview(scroll)
        layersStack = stack
        layersScroll = scroll
        rebuildLayerRows()

        let viewController = NSViewController()
        viewController.view = container
        let popover = NSPopover()
        popover.behavior = .transient
        popover.contentViewController = viewController
        popover.show(relativeTo: layersButton.bounds, of: layersButton, preferredEdge: .maxY)
        layersPopover = popover
    }

    private func rebuildLayerRows() {
        guard let stack = layersStack else { return }
        for view in stack.arrangedSubviews {
            stack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        let entries = canvas.layerEntries()
        for entry in entries {
            let row = NSStackView()
            row.orientation = .horizontal
            row.spacing = 4
            row.alignment = .centerY
            row.translatesAutoresizingMaskIntoConstraints = false

            let eye = NSButton(image: NSImage(
                systemSymbolName: entry.isHidden ? "eye.slash" : "eye",
                accessibilityDescription: "可见性"
            ) ?? NSImage(), target: self, action: #selector(layerVisibilityTapped(_:)))
            eye.isBordered = false
            eye.identifier = NSUserInterfaceItemIdentifier(entry.id.uuidString)
            eye.contentTintColor = .secondaryLabelColor
            eye.toolTip = entry.isHidden ? "显示" : "隐藏"

            let lock = NSButton(image: NSImage(
                systemSymbolName: entry.isLocked ? "lock.fill" : "lock.open",
                accessibilityDescription: "锁定"
            ) ?? NSImage(), target: self, action: #selector(layerLockTapped(_:)))
            lock.isBordered = false
            lock.identifier = NSUserInterfaceItemIdentifier(entry.id.uuidString)
            lock.contentTintColor = .secondaryLabelColor
            lock.toolTip = entry.isLocked ? "解锁" : "锁定"

            let title = NSButton(title: entry.name, target: self, action: #selector(layerTitleTapped(_:)))
            title.isBordered = false
            title.alignment = .left
            title.identifier = NSUserInterfaceItemIdentifier(entry.id.uuidString)
            title.contentTintColor = .labelColor
            title.font = .systemFont(ofSize: 12)
            title.lineBreakMode = .byTruncatingTail

            row.addArrangedSubview(eye)
            row.addArrangedSubview(lock)
            row.addArrangedSubview(title)
            row.widthAnchor.constraint(equalToConstant: 236).isActive = true
            stack.addArrangedSubview(row)
        }

        let height = max(30, CGFloat(entries.count) * 30)
        stack.frame = NSRect(x: 0, y: 0, width: 236, height: height)
    }

    @objc private func layerVisibilityTapped(_ sender: NSButton) {
        guard let id = layerID(from: sender) else { return }
        canvas.toggleHidden(id: id)
        rebuildLayerRows()
    }

    @objc private func layerLockTapped(_ sender: NSButton) {
        guard let id = layerID(from: sender) else { return }
        canvas.toggleLocked(id: id)
        rebuildLayerRows()
    }

    @objc private func layerTitleTapped(_ sender: NSButton) {
        guard let id = layerID(from: sender) else { return }
        canvas.selectAnnotation(id: id)
    }

    private func layerID(from sender: NSButton) -> UUID? {
        guard let raw = sender.identifier?.rawValue else { return nil }
        return UUID(uuidString: raw)
    }

    // MARK: - Options actions

    @objc private func styleMenuSelected(_ sender: NSMenuItem) {
        guard let style = TextStyle(rawValue: sender.tag) else { return }
        canvas.applyTextStyle(style)
        window?.makeFirstResponder(canvas)
    }

    @objc private func alignmentMenuSelected(_ sender: NSMenuItem) {
        guard let alignment = TextAlignmentOption(rawValue: sender.tag) else { return }
        canvas.applyTextAlignment(alignment)
        window?.makeFirstResponder(canvas)
    }

    @objc private func weightMenuSelected(_ sender: NSMenuItem) {
        guard let weight = FontWeightOption(rawValue: sender.tag) else { return }
        canvas.applyFontWeight(weight)
        window?.makeFirstResponder(canvas)
    }

    @objc private func fontMenuSelected(_ sender: NSMenuItem) {
        guard let design = FontDesignOption(rawValue: sender.tag) else { return }
        canvas.applyFontDesign(design)
        window?.makeFirstResponder(canvas)
    }

    @objc private func fontSizeMenuSelected(_ sender: NSMenuItem) {
        canvas.setFontSize(CGFloat(sender.tag))
        window?.makeFirstResponder(canvas)
    }

    @objc private func arrowStyleMenuSelected(_ sender: NSMenuItem) {
        guard let style = ArrowStyle(rawValue: sender.tag) else { return }
        canvas.applyArrowStyle(style)
        window?.makeFirstResponder(canvas)
    }

    @objc private func presetColorClicked(_ sender: NSButton) {
        guard presetColors.indices.contains(sender.tag) else { return }
        applyColor(presetColors[sender.tag])
        colorPopover?.close()
    }

    @objc private func popoverColorChanged(_ sender: NSColorWell) {
        applyColor(sender.color)
    }

    private func applyColor(_ color: NSColor) {
        canvas.applyColor(color)
        colorButton?.image = swatchImage(color: color)
    }

    @objc private func widthSliderChanged(_ sender: NSSlider) {
        canvas.applyLineWidth(CGFloat(sender.doubleValue))
        (sender.superview?.viewWithTag(100) as? NSTextField)?.stringValue =
            "线宽：\(Int(sender.doubleValue.rounded()))"
    }

    // MARK: - Bottom bar actions

    @objc private func insertImageTapped() {
        canvas.finishTextEditing()
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        panel.begin { [weak self] response in
            guard let self, response == .OK, let url = panel.url,
                  let nsImage = NSImage(contentsOf: url),
                  let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil)
            else {
                return
            }
            self.canvas.insertImage(cgImage)
            self.window?.makeFirstResponder(self.canvas)
        }
    }

    @objc private func showEmojiMenu() {
        guard let emojiButton else { return }
        let emojis = ["😀", "😎", "😍", "🔥", "👍", "🎉", "✅", "❌", "⭐️", "💡", "📌", "🚀"]
        let menu = NSMenu()
        for emoji in emojis {
            let item = NSMenuItem(title: emoji, action: #selector(emojiMenuSelected(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = emoji
            menu.addItem(item)
        }
        menu.popUp(
            positioning: nil,
            at: NSPoint(x: 0, y: emojiButton.bounds.maxY + 4),
            in: emojiButton
        )
    }

    @objc private func emojiMenuSelected(_ sender: NSMenuItem) {
        guard let emoji = sender.representedObject as? String else { return }
        canvas.insertEmoji(emoji)
        window?.makeFirstResponder(canvas)
    }

    @objc private func pinTapped() {
        canvas.finishTextEditing()
        guard let image = canvas.renderedImage() else { return }
        let pin = PinWindowController(image: image, captureScale: captureScale)
        pin.showWindow(nil)
    }

    private func cgColor(_ color: NSColor) -> CGColor {
        color.usingColorSpace(.sRGB)?.cgColor ?? color.cgColor
    }

    @objc private func undoTapped() {
        canvas.finishTextEditing()
        canvas.undoManager?.undo()
        canvas.needsDisplay = true
    }

    @objc private func redoTapped() {
        canvas.finishTextEditing()
        canvas.undoManager?.redo()
        canvas.needsDisplay = true
    }

    @objc private func copyTapped() {
        canvas.finishTextEditing()
        guard let image = canvas.renderedImage() else { return }
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

    @objc private func saveTapped() {
        canvas.finishTextEditing()
        guard let window, let image = canvas.renderedImage() else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = "AreaShot.png"
        panel.beginSheetModal(for: window) { response in
            guard response == .OK, let url = panel.url else { return }
            guard let destination = CGImageDestinationCreateWithURL(
                url as CFURL,
                UTType.png.identifier as CFString,
                1,
                nil
            ) else {
                return
            }
            CGImageDestinationAddImage(destination, image, nil)
            CGImageDestinationFinalize(destination)
        }
    }

    @objc private func closeTapped() {
        canvas.finishTextEditing()
        window?.close()
    }
}
