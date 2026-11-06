import AppKit
import CoreGraphics

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItemController: StatusItemController?
    private var editorWindows: [AnnotationEditorWindowController] = []
    private let countdown = CountdownController()
    private var showCursorInCaptures = false
    private var includeWindowShadow = true
    private var lastArea: (displayID: CGDirectDisplayID, rect: CGRect)?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItemController = StatusItemController(
            showCursor: showCursorInCaptures,
            includeShadow: includeWindowShadow,
            onCaptureArea: { [weak self] in self?.beginAreaCapture(allInOne: false) },
            onCaptureScreen: { [weak self] in self?.captureScreen() },
            onSelfTimer: { [weak self] in self?.startSelfTimer() },
            onRepeatLast: { [weak self] in self?.repeatLastArea() },
            onClipboard: { [weak self] in self?.captureFromClipboard() },
            onAllInOne: { [weak self] in self?.beginAreaCapture(allInOne: true) },
            onToggleCursor: { [weak self] value in self?.showCursorInCaptures = value },
            onToggleShadow: { [weak self] value in self?.includeWindowShadow = value },
            onQuit: { NSApp.terminate(nil) }
        )
    }

    private func screenUnderMouse() -> NSScreen {
        let mouse = NSEvent.mouseLocation
        return NSScreen.screens.first(where: { NSMouseInRect(mouse, $0.frame, false) })
            ?? NSScreen.main
            ?? NSScreen.screens[0]
    }

    private func beginAreaCapture(allInOne: Bool) {
        guard ensureScreenRecordingPermission() else { return }
        SelectionOverlayController.shared.begin(allInOne: allInOne) { [weak self] result in
            self?.handleSelection(result)
        }
    }

    private func handleSelection(_ result: SelectionResult) {
        guard case .cancelled = result else {
            // Let the overlay windows disappear from the compositor before capturing.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [weak self] in
                guard let self else { return }
                switch result {
                case .cancelled:
                    break
                case let .area(screen, rect):
                    self.captureArea(screen: screen, rect: rect)
                case let .window(snapWindow, screen):
                    self.captureWindow(snapWindow, on: screen)
                }
            }
            return
        }
    }

    private func captureArea(screen: NSScreen, rect: CGRect) {
        let displayID = displayID(for: screen)
        ScreenCaptureService.captureArea(
            rect: rect,
            on: screen,
            includeCursor: showCursorInCaptures
        ) { [weak self] result in
            guard let self else { return }
            if case .success = result {
                self.lastArea = (displayID, rect)
            }
            self.finishCapture(result, on: screen)
        }
    }

    private func captureWindow(_ snapWindow: SnapWindow, on screen: NSScreen) {
        ScreenCaptureService.captureWindow(
            snapWindow,
            on: screen,
            includeCursor: showCursorInCaptures,
            includeShadow: includeWindowShadow
        ) { [weak self] result in
            self?.finishCapture(result, on: screen)
        }
    }

    private func captureScreen() {
        guard ensureScreenRecordingPermission() else { return }
        let screen = screenUnderMouse()
        captureArea(screen: screen, rect: CGRect(origin: .zero, size: screen.frame.size))
    }

    private func startSelfTimer() {
        guard ensureScreenRecordingPermission() else { return }
        let screen = screenUnderMouse()
        countdown.start(seconds: 5, on: screen) { [weak self] in
            self?.beginAreaCapture(allInOne: false)
        }
    }

    private func repeatLastArea() {
        guard ensureScreenRecordingPermission() else { return }
        guard let lastArea, let screen = screen(forDisplayID: lastArea.displayID) else {
            beginAreaCapture(allInOne: false)
            return
        }
        captureArea(screen: screen, rect: lastArea.rect)
    }

    private func captureFromClipboard() {
        guard let image = NSPasteboard.general
                .readObjects(forClasses: [NSImage.self], options: nil)?
                .first as? NSImage,
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
        else {
            presentError(NSError(
                domain: "AreaShot",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "剪贴板中没有图片。"]
            ))
            return
        }
        showEditor(for: cgImage, on: screenUnderMouse())
    }

    private func displayID(for screen: NSScreen) -> CGDirectDisplayID {
        let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
        return CGDirectDisplayID(number?.uint32Value ?? 0)
    }

    private func screen(forDisplayID displayID: CGDirectDisplayID) -> NSScreen? {
        NSScreen.screens.first { self.displayID(for: $0) == displayID }
    }

    private func finishCapture(_ result: Result<CGImage, Error>, on screen: NSScreen) {
        switch result {
        case .success(let image):
            showEditor(for: image, on: screen)
        case .failure(let error):
            presentError(error)
        }
    }

    private func showEditor(for image: CGImage, on screen: NSScreen) {
        let editor = AnnotationEditorWindowController(image: image, screen: screen)
        editor.onClose = { [weak self, weak editor] in
            guard let self else { return }
            self.editorWindows.removeAll { $0 === editor }
        }
        editorWindows.append(editor)
        editor.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func presentError(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = "截图失败"
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .warning
        alert.runModal()
    }

    private func ensureScreenRecordingPermission() -> Bool {
        if CGPreflightScreenCaptureAccess() {
            return true
        }

        let granted = CGRequestScreenCaptureAccess()
        let alert = NSAlert()
        alert.messageText = "需要屏幕录制权限"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "好")

        if granted {
            alert.informativeText = "已获得权限。如果截图仍然失败，请退出并重新启动 AreaShot。"
            alert.runModal()
            return true
        }

        alert.informativeText = "请在「系统设置 > 隐私与安全性 > 屏幕录制」中勾选 AreaShot，然后重新启动应用。"
        alert.addButton(withTitle: "打开系统设置")
        if alert.runModal() == .alertSecondButtonReturn,
           let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
        return false
    }
}
