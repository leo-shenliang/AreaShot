import AppKit
import CoreGraphics
import ScreenCaptureKit

enum ScreenCaptureError: LocalizedError {
    case displayNotFound
    case cropFailed

    var errorDescription: String? {
        switch self {
        case .displayNotFound:
            return "找不到选区所在的显示器。"
        case .cropFailed:
            return "无法裁剪截取到的图像。"
        }
    }
}

struct SnapWindow {
    let window: SCWindow
    let bounds: CGRect // CoreGraphics global coordinates, top-left origin
}

enum ScreenCaptureService {
    static func loadSnapWindows(completion: @escaping ([SnapWindow]) -> Void) {
        Task {
            do {
                let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                let windowsByID = Dictionary(
                    content.windows.map { ($0.windowID, $0) },
                    uniquingKeysWith: { first, _ in first }
                )

                let infoList = CGWindowListCopyWindowInfo(
                    [.optionOnScreenOnly, .excludeDesktopElements],
                    kCGNullWindowID
                ) as? [[String: Any]] ?? []

                let ownPID = ProcessInfo.processInfo.processIdentifier
                var result: [SnapWindow] = []

                // CGWindowList is ordered front-to-back, which is what hit-testing needs.
                for info in infoList {
                    guard let number = info[kCGWindowNumber as String] as? NSNumber,
                          let layer = info[kCGWindowLayer as String] as? NSNumber, layer.intValue == 0,
                          let ownerPID = info[kCGWindowOwnerPID as String] as? NSNumber,
                          ownerPID.int32Value != ownPID,
                          let boundsDict = info[kCGWindowBounds as String] as? [String: Any],
                          let bounds = CGRect(dictionaryRepresentation: boundsDict as CFDictionary),
                          bounds.width >= 20, bounds.height >= 20,
                          let window = windowsByID[CGWindowID(number.uint32Value)]
                    else {
                        continue
                    }
                    result.append(SnapWindow(window: window, bounds: bounds))
                }

                DispatchQueue.main.async { completion(result) }
            } catch {
                DispatchQueue.main.async { completion([]) }
            }
        }
    }

    static func captureArea(
        rect: CGRect,
        on screen: NSScreen,
        includeCursor: Bool,
        completion: @escaping (Result<CGImage, Error>) -> Void
    ) {
        guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
            completion(.failure(ScreenCaptureError.displayNotFound))
            return
        }
        let displayID = CGDirectDisplayID(number.uint32Value)

        Task {
            do {
                let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                guard let display = content.displays.first(where: { $0.displayID == displayID }) else {
                    throw ScreenCaptureError.displayNotFound
                }

                let filter = SCContentFilter(display: display, excludingWindows: [])
                let pixelScale = CGFloat(filter.pointPixelScale)
                let configuration = SCStreamConfiguration()
                configuration.width = max(1, Int(filter.contentRect.width * pixelScale))
                configuration.height = max(1, Int(filter.contentRect.height * pixelScale))
                configuration.captureResolution = .best
                configuration.showsCursor = includeCursor

                let image = try await SCScreenshotManager.captureImage(
                    contentFilter: filter,
                    configuration: configuration
                )
                NSLog("AreaShot capture: \(image.width)x\(image.height) pixelScale=\(pixelScale) screenScale=\(screen.backingScaleFactor)")

                let scaleX = CGFloat(image.width) / screen.frame.width
                let scaleY = CGFloat(image.height) / screen.frame.height
                let cropRect = CGRect(
                    x: rect.minX * scaleX,
                    y: (screen.frame.height - rect.maxY) * scaleY,
                    width: rect.width * scaleX,
                    height: rect.height * scaleY
                ).integral

                guard let cropped = image.cropping(to: cropRect) else {
                    throw ScreenCaptureError.cropFailed
                }
                DispatchQueue.main.async { completion(.success(cropped)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
    }

    static func captureWindow(
        _ snapWindow: SnapWindow,
        on screen: NSScreen,
        includeCursor: Bool,
        includeShadow: Bool,
        completion: @escaping (Result<CGImage, Error>) -> Void
    ) {
        Task {
            do {
                let filter = SCContentFilter(desktopIndependentWindow: snapWindow.window)
                let pixelScale = CGFloat(filter.pointPixelScale)
                let configuration = SCStreamConfiguration()
                configuration.width = max(1, Int(snapWindow.window.frame.width * pixelScale))
                configuration.height = max(1, Int(snapWindow.window.frame.height * pixelScale))
                configuration.captureResolution = .best
                configuration.showsCursor = includeCursor
                configuration.ignoreShadowsSingleWindow = !includeShadow

                let image = try await SCScreenshotManager.captureImage(
                    contentFilter: filter,
                    configuration: configuration
                )
                DispatchQueue.main.async { completion(.success(image)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
    }
}
