import AppKit
import Carbon.HIToolbox

final class StatusItemController: NSObject {
    private let statusItem: NSStatusItem
    private let areaHotKey = HotKeyManager()
    private let screenHotKey = HotKeyManager()
    private var showCursor: Bool
    private var includeShadow: Bool
    private var cursorItem: NSMenuItem?
    private var shadowItem: NSMenuItem?

    private let onCaptureArea: () -> Void
    private let onCaptureScreen: () -> Void
    private let onSelfTimer: () -> Void
    private let onRepeatLast: () -> Void
    private let onClipboard: () -> Void
    private let onAllInOne: () -> Void
    private let onToggleCursor: (Bool) -> Void
    private let onToggleShadow: (Bool) -> Void
    private let onQuit: () -> Void

    init(
        showCursor: Bool,
        includeShadow: Bool,
        onCaptureArea: @escaping () -> Void,
        onCaptureScreen: @escaping () -> Void,
        onSelfTimer: @escaping () -> Void,
        onRepeatLast: @escaping () -> Void,
        onClipboard: @escaping () -> Void,
        onAllInOne: @escaping () -> Void,
        onToggleCursor: @escaping (Bool) -> Void,
        onToggleShadow: @escaping (Bool) -> Void,
        onQuit: @escaping () -> Void
    ) {
        self.showCursor = showCursor
        self.includeShadow = includeShadow
        self.onCaptureArea = onCaptureArea
        self.onCaptureScreen = onCaptureScreen
        self.onSelfTimer = onSelfTimer
        self.onRepeatLast = onRepeatLast
        self.onClipboard = onClipboard
        self.onAllInOne = onAllInOne
        self.onToggleCursor = onToggleCursor
        self.onToggleShadow = onToggleShadow
        self.onQuit = onQuit
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()

        if let button = statusItem.button {
            let symbol = NSImage(systemSymbolName: "camera.viewfinder", accessibilityDescription: "截取区域")
            button.image = symbol
            button.image?.isTemplate = true
            if symbol == nil {
                button.title = "AS"
            }
        }

        let menu = NSMenu()
        // 分享版暂时只暴露区域截图入口，其余模式与窗口截图保留实现待恢复。
        let areaItem = makeItem("截取区域", action: #selector(captureAreaClicked), key: "a")
        areaItem.keyEquivalentModifierMask = [.option, .shift]
        menu.addItem(areaItem)
        menu.addItem(.separator())

        let cursorItem = makeItem("截图中显示光标", action: #selector(toggleCursorClicked), key: "")
        cursorItem.state = showCursor ? .on : .off
        menu.addItem(cursorItem)
        self.cursorItem = cursorItem

        menu.addItem(.separator())
        menu.addItem(makeItem("退出 AreaShot", action: #selector(quitClicked), key: "q"))
        statusItem.menu = menu

        areaHotKey.register(
            keyCode: UInt32(kVK_ANSI_A),
            modifiers: UInt32(optionKey | shiftKey)
        ) { [weak self] in
            self?.onCaptureArea()
        }
    }

    private func makeItem(_ title: String, action: Selector, key: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        return item
    }

    @objc private func captureAreaClicked() { onCaptureArea() }
    @objc private func captureScreenClicked() { onCaptureScreen() }
    @objc private func allInOneClicked() { onAllInOne() }
    @objc private func selfTimerClicked() { onSelfTimer() }
    @objc private func repeatLastClicked() { onRepeatLast() }
    @objc private func clipboardClicked() { onClipboard() }

    @objc private func toggleCursorClicked() {
        showCursor.toggle()
        cursorItem?.state = showCursor ? .on : .off
        onToggleCursor(showCursor)
    }

    @objc private func toggleShadowClicked() {
        includeShadow.toggle()
        shadowItem?.state = includeShadow ? .on : .off
        onToggleShadow(includeShadow)
    }

    @objc private func quitClicked() { onQuit() }
}
