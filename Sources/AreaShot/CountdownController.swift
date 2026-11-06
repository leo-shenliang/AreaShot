import AppKit

final class CountdownController {
    private var window: NSWindow?
    private var timer: Timer?
    private var remaining = 0
    private var completion: (() -> Void)?
    private let label = NSTextField(labelWithString: "5")

    func start(seconds: Int, on screen: NSScreen, completion: @escaping () -> Void) {
        cancel()
        self.completion = completion
        remaining = seconds

        let panel = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 120, height: 120),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        panel.level = .screenSaver
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isReleasedWhenClosed = false

        let effect = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: 120, height: 120))
        effect.material = .hudWindow
        effect.blendingMode = .behindWindow
        effect.state = .active
        effect.wantsLayer = true
        effect.layer?.cornerRadius = 18
        effect.layer?.masksToBounds = true
        panel.contentView = effect

        label.stringValue = "\(remaining)"
        label.font = .monospacedDigitSystemFont(ofSize: 56, weight: .semibold)
        label.textColor = .white
        label.alignment = .center
        label.frame = NSRect(x: 0, y: 34, width: 120, height: 64)
        effect.addSubview(label)

        let subtitle = NSTextField(labelWithString: "区域截图")
        subtitle.font = .systemFont(ofSize: 11, weight: .medium)
        subtitle.textColor = .secondaryLabelColor
        subtitle.alignment = .center
        subtitle.frame = NSRect(x: 0, y: 14, width: 120, height: 16)
        effect.addSubview(subtitle)

        let originX = screen.frame.midX - 60
        let originY = screen.frame.midY - 60
        panel.setFrameOrigin(NSPoint(x: originX, y: originY))
        panel.orderFrontRegardless()
        window = panel

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.remaining -= 1
            if self.remaining <= 0 {
                self.finish()
            } else {
                self.label.stringValue = "\(self.remaining)"
            }
        }
    }

    func cancel() {
        timer?.invalidate()
        timer = nil
        completion = nil
        window?.orderOut(nil)
        window = nil
    }

    private func finish() {
        timer?.invalidate()
        timer = nil
        let completion = self.completion
        self.completion = nil
        window?.orderOut(nil)
        window = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            completion?()
        }
    }
}
