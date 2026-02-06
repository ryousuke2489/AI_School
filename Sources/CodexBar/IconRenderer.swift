#if os(macOS)
import AppKit
import CodexBarCore

/// Renders menu bar icons showing usage progress bars.
///
/// The icon uses a dual-bar metaphor:
/// - Top bar: session usage
/// - Bottom hairline: weekly/periodic progress
enum IconRenderer {

    /// Icon canvas size.
    private static let iconSize = NSSize(width: 18, height: 18)
    private static let scaleFactor: CGFloat = 2.0

    /// Create a menu bar icon for the given parameters.
    static func makeIcon(
        style: IconStyle,
        sessionPercentage: Double,
        weeklyPercentage: Double,
        isStale: Bool = false,
        statusIndicator: StatusIndicator = .none
    ) -> NSImage {
        let pixelSize = NSSize(
            width: iconSize.width * scaleFactor,
            height: iconSize.height * scaleFactor
        )

        let image = NSImage(size: iconSize, flipped: false) { drawRect in
            NSGraphicsContext.current?.cgContext.scaleBy(x: 1, y: 1)

            let alpha: CGFloat = isStale ? 0.5 : 1.0

            // Draw character/provider outline
            drawProviderShape(style: style, in: drawRect, alpha: alpha)

            // Draw session bar (top)
            drawProgressBar(
                percentage: sessionPercentage,
                rect: CGRect(x: 3, y: 10, width: 12, height: 3),
                alpha: alpha
            )

            // Draw weekly bar (bottom hairline)
            drawProgressBar(
                percentage: weeklyPercentage,
                rect: CGRect(x: 3, y: 5, width: 12, height: 1.5),
                alpha: alpha
            )

            // Draw status indicator if needed
            drawStatusIndicator(statusIndicator, in: drawRect, alpha: alpha)

            return true
        }

        image.isTemplate = true
        return image
    }

    // MARK: - Drawing Helpers

    private static func drawProgressBar(
        percentage: Double,
        rect: CGRect,
        alpha: CGFloat
    ) {
        let clamped = min(max(percentage, 0), 1)

        // Background track
        let trackColor = NSColor.labelColor.withAlphaComponent(0.15 * alpha)
        trackColor.setFill()
        let trackPath = NSBezierPath(roundedRect: rect, xRadius: 1, yRadius: 1)
        trackPath.fill()

        // Fill bar
        if clamped > 0 {
            let fillWidth = rect.width * CGFloat(clamped)
            let fillRect = CGRect(x: rect.origin.x, y: rect.origin.y, width: fillWidth, height: rect.height)

            let fillColor: NSColor
            if clamped >= 0.9 {
                fillColor = NSColor.systemRed.withAlphaComponent(alpha)
            } else if clamped >= 0.7 {
                fillColor = NSColor.systemOrange.withAlphaComponent(alpha)
            } else {
                fillColor = NSColor.labelColor.withAlphaComponent(0.8 * alpha)
            }

            fillColor.setFill()
            let fillPath = NSBezierPath(roundedRect: fillRect, xRadius: 1, yRadius: 1)
            fillPath.fill()
        }
    }

    private static func drawProviderShape(style: IconStyle, in rect: CGRect, alpha: CGFloat) {
        let outlineColor = NSColor.labelColor.withAlphaComponent(0.3 * alpha)
        outlineColor.setStroke()

        switch style {
        case .claude:
            // Claude: blockier shape with notches
            let path = NSBezierPath()
            path.move(to: CGPoint(x: 2, y: 4))
            path.line(to: CGPoint(x: 2, y: 15))
            path.line(to: CGPoint(x: 7, y: 17))
            path.line(to: CGPoint(x: 11, y: 17))
            path.line(to: CGPoint(x: 16, y: 15))
            path.line(to: CGPoint(x: 16, y: 4))
            path.line(to: CGPoint(x: 14, y: 2))
            path.line(to: CGPoint(x: 4, y: 2))
            path.close()
            path.lineWidth = 0.5
            path.stroke()

            // Eyes
            let eyeColor = NSColor.labelColor.withAlphaComponent(0.4 * alpha)
            eyeColor.setFill()
            NSBezierPath(ovalIn: CGRect(x: 6, y: 13, width: 2, height: 3)).fill()
            NSBezierPath(ovalIn: CGRect(x: 10, y: 13, width: 2, height: 3)).fill()

        case .codex:
            // Codex: capsule shape with eyes
            let capsule = NSBezierPath(roundedRect: rect.insetBy(dx: 2, dy: 1), xRadius: 6, yRadius: 8)
            capsule.lineWidth = 0.5
            capsule.stroke()

            let eyeColor = NSColor.labelColor.withAlphaComponent(0.4 * alpha)
            eyeColor.setFill()
            NSBezierPath(ovalIn: CGRect(x: 6, y: 13, width: 2.5, height: 2.5)).fill()
            NSBezierPath(ovalIn: CGRect(x: 10, y: 13, width: 2.5, height: 2.5)).fill()

        case .gemini:
            // Gemini: 4-pointed star eyes
            let capsule = NSBezierPath(roundedRect: rect.insetBy(dx: 2, dy: 1), xRadius: 4, yRadius: 6)
            capsule.lineWidth = 0.5
            capsule.stroke()

            let starColor = NSColor.labelColor.withAlphaComponent(0.4 * alpha)
            starColor.setFill()
            drawDiamond(center: CGPoint(x: 7, y: 14), size: 2, alpha: alpha)
            drawDiamond(center: CGPoint(x: 11, y: 14), size: 2, alpha: alpha)

        case .cursor:
            // Cursor: simple rounded rect
            let shape = NSBezierPath(roundedRect: rect.insetBy(dx: 2, dy: 1), xRadius: 3, yRadius: 3)
            shape.lineWidth = 0.5
            shape.stroke()

            // Cursor icon (simple arrow)
            let arrowColor = NSColor.labelColor.withAlphaComponent(0.4 * alpha)
            arrowColor.setFill()
            let arrow = NSBezierPath()
            arrow.move(to: CGPoint(x: 7, y: 16))
            arrow.line(to: CGPoint(x: 7, y: 12))
            arrow.line(to: CGPoint(x: 11, y: 14))
            arrow.close()
            arrow.fill()

        case .copilot:
            // Copilot: rounded shape with visor
            let shape = NSBezierPath(roundedRect: rect.insetBy(dx: 2, dy: 1), xRadius: 5, yRadius: 5)
            shape.lineWidth = 0.5
            shape.stroke()

            // Visor line
            let visorColor = NSColor.labelColor.withAlphaComponent(0.3 * alpha)
            visorColor.setStroke()
            let visor = NSBezierPath()
            visor.move(to: CGPoint(x: 4, y: 14))
            visor.line(to: CGPoint(x: 14, y: 14))
            visor.lineWidth = 1.0
            visor.stroke()

        case .combined:
            // Combined: simple rounded rectangle
            let shape = NSBezierPath(roundedRect: rect.insetBy(dx: 1.5, dy: 1), xRadius: 3, yRadius: 3)
            shape.lineWidth = 0.5
            shape.stroke()
        }
    }

    private static func drawDiamond(center: CGPoint, size: CGFloat, alpha: CGFloat) {
        let path = NSBezierPath()
        path.move(to: CGPoint(x: center.x, y: center.y + size))
        path.line(to: CGPoint(x: center.x + size, y: center.y))
        path.line(to: CGPoint(x: center.x, y: center.y - size))
        path.line(to: CGPoint(x: center.x - size, y: center.y))
        path.close()
        path.fill()
    }

    private static func drawStatusIndicator(
        _ indicator: StatusIndicator,
        in rect: CGRect,
        alpha: CGFloat
    ) {
        switch indicator {
        case .none:
            break
        case .minor:
            // Small dot in corner
            let dotColor = NSColor.systemYellow.withAlphaComponent(alpha)
            dotColor.setFill()
            NSBezierPath(ovalIn: CGRect(x: rect.maxX - 5, y: rect.maxY - 5, width: 4, height: 4)).fill()
        case .critical:
            // Exclamation mark
            let critColor = NSColor.systemRed.withAlphaComponent(alpha)
            critColor.setFill()
            NSBezierPath(ovalIn: CGRect(x: rect.maxX - 6, y: rect.maxY - 6, width: 5, height: 5)).fill()
        }
    }
}

/// Status indicator overlay for the menu bar icon.
enum StatusIndicator {
    case none
    case minor
    case critical
}
#endif
