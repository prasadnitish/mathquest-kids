#!/usr/bin/env swift

import AppKit
import Foundation

enum IconVariant: String, CaseIterable {
    case standard = "icon-1024.png"
    case dark = "icon-dark-1024.png"
    case tinted = "icon-tinted-1024.png"
}

let scriptURL = URL(fileURLWithPath: CommandLine.arguments[0]).standardizedFileURL
let rootURL = scriptURL.deletingLastPathComponent().deletingLastPathComponent()
let outputDirectory = rootURL
    .appendingPathComponent("MathQuestKids")
    .appendingPathComponent("Assets.xcassets")
    .appendingPathComponent("AppIcon.appiconset", isDirectory: true)

let canvasSize = CGSize(width: 1024, height: 1024)
let canvasRect = CGRect(origin: .zero, size: canvasSize)
let cornerRadius: CGFloat = 220

try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

for variant in IconVariant.allCases {
    let image = NSImage(size: canvasSize)
    image.lockFocus()
    drawIcon(in: canvasRect, variant: variant)
    image.unlockFocus()

    guard
        let tiff = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiff),
        let png = bitmap.representation(using: .png, properties: [:])
    else {
        fatalError("Failed to encode PNG for \(variant.rawValue)")
    }

    let url = outputDirectory.appendingPathComponent(variant.rawValue)
    try png.write(to: url)
    print("Wrote \(url.path)")
}

func drawIcon(in rect: CGRect, variant: IconVariant) {
    let rounded = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
    rounded.addClip()

    backgroundGradient(for: variant).draw(in: rect, angle: 310)
    drawBackdropGlow(in: rect, variant: variant)
    drawConstellationPattern(in: rect, variant: variant)
    drawOrbitRings(in: rect, variant: variant)
    drawCoin(in: rect, variant: variant)
    drawQuestBlocks(in: rect, variant: variant)
    drawQuestQ(in: rect, variant: variant)
    drawCornerSpark(in: rect, variant: variant)
}

func backgroundGradient(for variant: IconVariant) -> NSGradient {
    switch variant {
    case .standard:
        return NSGradient(colors: [
            NSColor(calibratedRed: 0.10, green: 0.57, blue: 0.78, alpha: 1),
            NSColor(calibratedRed: 0.48, green: 0.34, blue: 0.87, alpha: 1),
            NSColor(calibratedRed: 0.98, green: 0.53, blue: 0.47, alpha: 1)
        ])!
    case .dark:
        return NSGradient(colors: [
            NSColor(calibratedRed: 0.05, green: 0.10, blue: 0.22, alpha: 1),
            NSColor(calibratedRed: 0.13, green: 0.19, blue: 0.37, alpha: 1),
            NSColor(calibratedRed: 0.26, green: 0.17, blue: 0.44, alpha: 1)
        ])!
    case .tinted:
        return NSGradient(colors: [
            NSColor(calibratedWhite: 0.96, alpha: 1),
            NSColor(calibratedWhite: 0.90, alpha: 1)
        ])!
    }
}

func drawBackdropGlow(in rect: CGRect, variant: IconVariant) {
    let glowColors: [NSColor]
    switch variant {
    case .standard:
        glowColors = [
            NSColor(calibratedRed: 1.00, green: 0.86, blue: 0.38, alpha: 0.45),
            NSColor(calibratedRed: 0.98, green: 0.49, blue: 0.69, alpha: 0.22),
            NSColor.clear
        ]
    case .dark:
        glowColors = [
            NSColor(calibratedRed: 0.44, green: 0.80, blue: 0.96, alpha: 0.28),
            NSColor(calibratedRed: 0.91, green: 0.72, blue: 0.34, alpha: 0.14),
            NSColor.clear
        ]
    case .tinted:
        glowColors = [
            NSColor(calibratedRed: 0.31, green: 0.43, blue: 0.81, alpha: 0.12),
            NSColor.clear
        ]
    }

    let glow = NSGradient(colors: glowColors)!
    let ellipse = CGRect(x: 80, y: 80, width: 860, height: 860)
    glow.draw(in: NSBezierPath(ovalIn: ellipse), relativeCenterPosition: .zero)
}

func drawConstellationPattern(in rect: CGRect, variant: IconVariant) {
    let points: [(CGFloat, CGFloat, CGFloat)] = [
        (138, 842, 11), (246, 896, 7), (334, 780, 8), (822, 820, 12),
        (872, 726, 7), (734, 918, 9), (168, 262, 12), (282, 196, 8),
        (820, 224, 10), (910, 344, 8), (730, 134, 7), (516, 906, 10)
    ]

    let dotColor: NSColor
    switch variant {
    case .standard:
        dotColor = NSColor.white.withAlphaComponent(0.34)
    case .dark:
        dotColor = NSColor.white.withAlphaComponent(0.28)
    case .tinted:
        dotColor = NSColor(calibratedWhite: 0.45, alpha: 0.12)
    }
    dotColor.setFill()

    for (x, y, size) in points {
        NSBezierPath(ovalIn: CGRect(x: x, y: y, width: size, height: size)).fill()
    }

    let strokeColor = dotColor.withAlphaComponent(variant == .tinted ? 0.08 : 0.18)
    strokeColor.setStroke()
    for pair in [(0, 2), (2, 5), (6, 7), (8, 9)] {
        let first = points[pair.0]
        let second = points[pair.1]
        let path = NSBezierPath()
        path.move(to: CGPoint(x: first.0 + first.2 / 2, y: first.1 + first.2 / 2))
        path.line(to: CGPoint(x: second.0 + second.2 / 2, y: second.1 + second.2 / 2))
        path.lineWidth = 2
        path.stroke()
    }
}

func drawOrbitRings(in rect: CGRect, variant: IconVariant) {
    let ringColor: NSColor
    switch variant {
    case .standard:
        ringColor = NSColor.white.withAlphaComponent(0.14)
    case .dark:
        ringColor = NSColor.white.withAlphaComponent(0.10)
    case .tinted:
        ringColor = NSColor(calibratedWhite: 0.25, alpha: 0.08)
    }

    ringColor.setStroke()
    for inset in [80.0, 128.0] {
        let path = NSBezierPath(roundedRect: rect.insetBy(dx: inset, dy: inset + 10), xRadius: 180, yRadius: 180)
        path.lineWidth = 4
        path.stroke()
    }
}

func drawCoin(in rect: CGRect, variant: IconVariant) {
    let coinRect = CGRect(x: 202, y: 190, width: 620, height: 620)
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(variant == .tinted ? 0.08 : 0.18)
    shadow.shadowOffset = NSSize(width: 0, height: -20)
    shadow.shadowBlurRadius = 30
    shadow.set()

    let coinPath = NSBezierPath(ovalIn: coinRect)
    let coinGradient: NSGradient
    switch variant {
    case .standard:
        coinGradient = NSGradient(colors: [
            NSColor(calibratedRed: 0.99, green: 0.96, blue: 0.88, alpha: 1),
            NSColor(calibratedRed: 0.97, green: 0.88, blue: 0.62, alpha: 1)
        ])!
    case .dark:
        coinGradient = NSGradient(colors: [
            NSColor(calibratedRed: 0.95, green: 0.91, blue: 0.77, alpha: 1),
            NSColor(calibratedRed: 0.79, green: 0.66, blue: 0.33, alpha: 1)
        ])!
    case .tinted:
        coinGradient = NSGradient(colors: [
            NSColor(calibratedWhite: 0.99, alpha: 1),
            NSColor(calibratedWhite: 0.93, alpha: 1)
        ])!
    }
    coinGradient.draw(in: coinPath, angle: 270)

    let edgeColor: NSColor = variant == .tinted
        ? NSColor(calibratedRed: 0.30, green: 0.41, blue: 0.78, alpha: 0.18)
        : NSColor.white.withAlphaComponent(0.35)
    edgeColor.setStroke()
    coinPath.lineWidth = 8
    coinPath.stroke()
}

func drawQuestBlocks(in rect: CGRect, variant: IconVariant) {
    let colors: [NSColor]
    switch variant {
    case .standard:
        colors = [
            NSColor(calibratedRed: 0.13, green: 0.69, blue: 0.79, alpha: 1),
            NSColor(calibratedRed: 0.97, green: 0.53, blue: 0.45, alpha: 1),
            NSColor(calibratedRed: 0.55, green: 0.39, blue: 0.92, alpha: 1),
            NSColor(calibratedRed: 0.98, green: 0.73, blue: 0.29, alpha: 1)
        ]
    case .dark:
        colors = [
            NSColor(calibratedRed: 0.36, green: 0.83, blue: 0.92, alpha: 1),
            NSColor(calibratedRed: 0.98, green: 0.63, blue: 0.46, alpha: 1),
            NSColor(calibratedRed: 0.64, green: 0.54, blue: 0.95, alpha: 1),
            NSColor(calibratedRed: 0.98, green: 0.80, blue: 0.44, alpha: 1)
        ]
    case .tinted:
        colors = Array(repeating: NSColor(calibratedRed: 0.30, green: 0.41, blue: 0.78, alpha: 1), count: 4)
    }

    let tileRects = [
        CGRect(x: 330, y: 430, width: 110, height: 110),
        CGRect(x: 457, y: 430, width: 110, height: 110),
        CGRect(x: 584, y: 430, width: 110, height: 110),
        CGRect(x: 457, y: 557, width: 110, height: 110)
    ]

    for (index, tileRect) in tileRects.enumerated() {
        let path = NSBezierPath(roundedRect: tileRect, xRadius: 28, yRadius: 28)
        colors[index].setFill()
        path.fill()

        NSColor.white.withAlphaComponent(variant == .tinted ? 0.55 : 0.80).setStroke()
        path.lineWidth = 4
        path.stroke()
    }

    let numerals = ["1", "2", "3", "+"]
    for (index, tileRect) in tileRects.enumerated() {
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 54, weight: .heavy),
            .foregroundColor: variant == .tinted ? NSColor.white : NSColor.white.withAlphaComponent(0.96),
            .paragraphStyle: style
        ]
        let textRect = CGRect(x: tileRect.minX, y: tileRect.midY - 34, width: tileRect.width, height: 68)
        numerals[index].draw(in: textRect, withAttributes: attrs)
    }
}

func drawQuestQ(in rect: CGRect, variant: IconVariant) {
    let color: NSColor = variant == .tinted
        ? NSColor(calibratedRed: 0.30, green: 0.41, blue: 0.78, alpha: 0.94)
        : NSColor(calibratedRed: 0.11, green: 0.16, blue: 0.29, alpha: 0.92)

    let ring = NSBezierPath()
    ring.lineWidth = 34
    ring.lineCapStyle = .round
    ring.appendArc(withCenter: CGPoint(x: 512, y: 512), radius: 234, startAngle: 138, endAngle: -92, clockwise: true)
    color.setStroke()
    ring.stroke()

    let tail = NSBezierPath()
    tail.move(to: CGPoint(x: 626, y: 358))
    tail.line(to: CGPoint(x: 734, y: 252))
    tail.lineWidth = 34
    tail.lineCapStyle = .round
    tail.stroke()

    let flagPole = NSBezierPath()
    flagPole.move(to: CGPoint(x: 712, y: 706))
    flagPole.line(to: CGPoint(x: 712, y: 792))
    flagPole.lineWidth = 16
    flagPole.lineCapStyle = .round
    flagPole.stroke()

    let flag = NSBezierPath()
    flag.move(to: CGPoint(x: 724, y: 786))
    flag.line(to: CGPoint(x: 804, y: 754))
    flag.line(to: CGPoint(x: 724, y: 726))
    flag.close()
    (variant == .tinted ? color : NSColor(calibratedRed: 0.97, green: 0.43, blue: 0.55, alpha: 1)).setFill()
    flag.fill()
}

func drawCornerSpark(in rect: CGRect, variant: IconVariant) {
    let sparkColor: NSColor
    switch variant {
    case .standard:
        sparkColor = NSColor(calibratedRed: 1.00, green: 0.92, blue: 0.60, alpha: 0.92)
    case .dark:
        sparkColor = NSColor(calibratedRed: 0.80, green: 0.93, blue: 1.00, alpha: 0.92)
    case .tinted:
        sparkColor = NSColor(calibratedRed: 0.30, green: 0.41, blue: 0.78, alpha: 0.34)
    }

    let center = CGPoint(x: 782, y: 814)
    let path = NSBezierPath()
    path.move(to: CGPoint(x: center.x, y: center.y + 56))
    path.line(to: CGPoint(x: center.x + 18, y: center.y + 18))
    path.line(to: CGPoint(x: center.x + 56, y: center.y))
    path.line(to: CGPoint(x: center.x + 18, y: center.y - 18))
    path.line(to: CGPoint(x: center.x, y: center.y - 56))
    path.line(to: CGPoint(x: center.x - 18, y: center.y - 18))
    path.line(to: CGPoint(x: center.x - 56, y: center.y))
    path.line(to: CGPoint(x: center.x - 18, y: center.y + 18))
    path.close()
    sparkColor.setFill()
    path.fill()
}
