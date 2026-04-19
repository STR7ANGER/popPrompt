import AppKit
import Foundation

struct BrandAssetsGenerator {
    let root: URL

    func run() throws {
        let macAssets = root.appendingPathComponent("macos/PopPrompt/Assets.xcassets")
        let macIconset = macAssets.appendingPathComponent("AppIcon.appiconset")
        let statusImageSet = macAssets.appendingPathComponent("StatusIcon.imageset")
        let macBranding = root.appendingPathComponent("macos/Branding")
        let windowsAssets = root.appendingPathComponent("windows/PopPrompt.Windows/Assets")
        let windowsSetupAssets = root.appendingPathComponent("windows/PopPrompt.Windows.Setup/Assets")

        try ensureDirectory(macIconset)
        try ensureDirectory(statusImageSet)
        try ensureDirectory(macBranding)
        try ensureDirectory(windowsAssets)
        try ensureDirectory(windowsSetupAssets)

        let appIconSizes = [16, 32, 64, 128, 256, 512, 1024]
        for size in appIconSizes {
            let image = drawAppIcon(size: CGFloat(size))
            try writePNG(image: image, to: macIconset.appendingPathComponent("icon_\(size)x\(size).png"))
        }

        let status1x = drawStatusIcon(size: 18)
        let status2x = drawStatusIcon(size: 36)
        try writePNG(image: status1x, to: statusImageSet.appendingPathComponent("status-icon.png"))
        try writePNG(image: status2x, to: statusImageSet.appendingPathComponent("status-icon@2x.png"))

        let dmgBackground = drawDmgBackground(size: NSSize(width: 680, height: 420))
        try writePNG(image: dmgBackground, to: macBranding.appendingPathComponent("DmgBackground.png"))

        let windowsPngSizes = [16, 24, 32, 48, 64, 128, 256]
        var windowsPngs: [(Int, Data)] = []
        for size in windowsPngSizes {
            let image = drawAppIcon(size: CGFloat(size))
            let data = try pngData(from: image)
            windowsPngs.append((size, data))
        }
        try writeICO(images: windowsPngs, to: windowsAssets.appendingPathComponent("AppIcon.ico"))

        let banner = drawInstallerBanner(size: NSSize(width: 493, height: 58))
        try writeBMP(image: banner, to: windowsSetupAssets.appendingPathComponent("InstallerBanner.bmp"))

        let dialog = drawInstallerDialog(size: NSSize(width: 493, height: 312))
        try writeBMP(image: dialog, to: windowsSetupAssets.appendingPathComponent("InstallerDialog.bmp"))

        print("Generated brand assets")
    }

    private func ensureDirectory(_ url: URL) throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    private func drawAppIcon(size: CGFloat) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()

        let rect = NSRect(x: 0, y: 0, width: size, height: size)
        NSColor.clear.setFill()
        rect.fill()

        let outerInset = size * 0.09
        let outerRect = rect.insetBy(dx: outerInset, dy: outerInset)
        let outerPath = NSBezierPath(roundedRect: outerRect, xRadius: size * 0.22, yRadius: size * 0.22)
        NSColor(calibratedWhite: 0.04, alpha: 1).setFill()
        outerPath.fill()

        let bubbleRect = NSRect(
            x: size * 0.30,
            y: size * 0.34,
            width: size * 0.40,
            height: size * 0.30
        )
        let bubblePath = NSBezierPath(roundedRect: bubbleRect, xRadius: size * 0.07, yRadius: size * 0.07)
        bubblePath.move(to: NSPoint(x: size * 0.42, y: size * 0.34))
        bubblePath.line(to: NSPoint(x: size * 0.36, y: size * 0.24))
        bubblePath.line(to: NSPoint(x: size * 0.50, y: size * 0.34))
        bubblePath.close()
        NSColor.white.setFill()
        bubblePath.fill()

        let line1 = NSBezierPath(roundedRect: NSRect(x: size * 0.395, y: size * 0.53, width: size * 0.21, height: size * 0.045), xRadius: size * 0.022, yRadius: size * 0.022)
        let line2 = NSBezierPath(roundedRect: NSRect(x: size * 0.395, y: size * 0.445, width: size * 0.145, height: size * 0.045), xRadius: size * 0.022, yRadius: size * 0.022)
        NSColor(calibratedWhite: 0.04, alpha: 1).setFill()
        line1.fill()
        line2.fill()

        image.unlockFocus()
        return image
    }

    private func drawStatusIcon(size: CGFloat) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size))
        image.isTemplate = true
        image.lockFocus()

        NSColor.clear.setFill()
        NSRect(x: 0, y: 0, width: size, height: size).fill()

        let bubbleRect = NSRect(x: size * 0.18, y: size * 0.28, width: size * 0.64, height: size * 0.44)
        let bubble = NSBezierPath(roundedRect: bubbleRect, xRadius: size * 0.14, yRadius: size * 0.14)
        bubble.move(to: NSPoint(x: size * 0.35, y: size * 0.28))
        bubble.line(to: NSPoint(x: size * 0.30, y: size * 0.16))
        bubble.line(to: NSPoint(x: size * 0.46, y: size * 0.28))
        bubble.close()

        NSColor.black.setFill()
        bubble.fill()

        image.unlockFocus()
        return image
    }

    private func drawDmgBackground(size: NSSize) -> NSImage {
        let image = NSImage(size: size)
        image.lockFocus()

        let bounds = NSRect(origin: .zero, size: size)
        NSColor(calibratedWhite: 0.03, alpha: 1).setFill()
        bounds.fill()

        let leftPanel = NSBezierPath(roundedRect: NSRect(x: 42, y: 54, width: 244, height: 312), xRadius: 28, yRadius: 28)
        NSColor(calibratedWhite: 0.08, alpha: 1).setFill()
        leftPanel.fill()

        let icon = drawAppIcon(size: 108)
        icon.draw(in: NSRect(x: 74, y: 226, width: 108, height: 108))

        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 30, weight: .bold),
            .foregroundColor: NSColor.white
        ]
        let subtitleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 15, weight: .regular),
            .foregroundColor: NSColor(calibratedWhite: 0.72, alpha: 1)
        ]
        NSString(string: "PopPrompt").draw(at: NSPoint(x: 74, y: 176), withAttributes: titleAttrs)
        NSString(string: "Drag the app into Applications").draw(at: NSPoint(x: 74, y: 148), withAttributes: subtitleAttrs)

        let arrowPath = NSBezierPath()
        arrowPath.lineWidth = 7
        arrowPath.lineCapStyle = .round
        arrowPath.move(to: NSPoint(x: 312, y: 210))
        arrowPath.line(to: NSPoint(x: 468, y: 210))
        arrowPath.line(to: NSPoint(x: 442, y: 234))
        arrowPath.move(to: NSPoint(x: 468, y: 210))
        arrowPath.line(to: NSPoint(x: 442, y: 186))
        NSColor(calibratedWhite: 0.9, alpha: 1).setStroke()
        arrowPath.stroke()

        image.unlockFocus()
        return image
    }

    private func drawInstallerBanner(size: NSSize) -> NSImage {
        let image = NSImage(size: size)
        image.lockFocus()
        let bounds = NSRect(origin: .zero, size: size)
        NSColor.black.setFill()
        bounds.fill()

        let icon = drawAppIcon(size: 34)
        icon.draw(in: NSRect(x: 18, y: 12, width: 34, height: 34))
        NSString(string: "PopPrompt").draw(
            at: NSPoint(x: 64, y: 18),
            withAttributes: [
                .font: NSFont.systemFont(ofSize: 20, weight: .bold),
                .foregroundColor: NSColor.white
            ]
        )

        image.unlockFocus()
        return image
    }

    private func drawInstallerDialog(size: NSSize) -> NSImage {
        let image = NSImage(size: size)
        image.lockFocus()
        let bounds = NSRect(origin: .zero, size: size)
        NSColor.black.setFill()
        bounds.fill()

        let panel = NSBezierPath(roundedRect: NSRect(x: 26, y: 34, width: 214, height: 244), xRadius: 26, yRadius: 26)
        NSColor(calibratedWhite: 0.08, alpha: 1).setFill()
        panel.fill()

        let icon = drawAppIcon(size: 72)
        icon.draw(in: NSRect(x: 52, y: 182, width: 72, height: 72))

        NSString(string: "PopPrompt").draw(
            at: NSPoint(x: 52, y: 148),
            withAttributes: [
                .font: NSFont.systemFont(ofSize: 24, weight: .bold),
                .foregroundColor: NSColor.white
            ]
        )

        NSString(string: "Minimal prompt access from\nyour tray or menu bar.").draw(
            in: NSRect(x: 52, y: 90, width: 150, height: 44),
            withAttributes: [
                .font: NSFont.systemFont(ofSize: 13, weight: .regular),
                .foregroundColor: NSColor(calibratedWhite: 0.74, alpha: 1)
            ]
        )

        image.unlockFocus()
        return image
    }

    private func pngData(from image: NSImage) throws -> Data {
        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let data = bitmap.representation(using: .png, properties: [:]) else {
            throw NSError(domain: "BrandAssetsGenerator", code: 1)
        }
        return data
    }

    private func writePNG(image: NSImage, to url: URL) throws {
        let data = try pngData(from: image)
        try data.write(to: url)
    }

    private func writeBMP(image: NSImage, to url: URL) throws {
        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let data = bitmap.representation(using: .bmp, properties: [:]) else {
            throw NSError(domain: "BrandAssetsGenerator", code: 2)
        }
        try data.write(to: url)
    }

    private func writeICO(images: [(Int, Data)], to url: URL) throws {
        var data = Data()
        let count = UInt16(images.count)

        data.append(contentsOf: [0, 0, 1, 0])
        data.append(contentsOf: withUnsafeBytes(of: count.littleEndian, Array.init))

        let directorySize = 6 + (16 * images.count)
        var offset = UInt32(directorySize)
        var payload = Data()

        for (size, pngData) in images {
            let dimension = UInt8(size == 256 ? 0 : min(size, 255))
            data.append(dimension)
            data.append(dimension)
            data.append(0)
            data.append(0)
            data.append(contentsOf: [1, 0, 32, 0])

            let dataSize = UInt32(pngData.count)
            data.append(contentsOf: withUnsafeBytes(of: dataSize.littleEndian, Array.init))
            data.append(contentsOf: withUnsafeBytes(of: offset.littleEndian, Array.init))

            payload.append(pngData)
            offset += dataSize
        }

        data.append(payload)
        try data.write(to: url)
    }
}

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
try BrandAssetsGenerator(root: root).run()
