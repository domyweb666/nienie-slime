import UIKit

/// Draws the slime and reads raw touches. A CADisplayLink (up to 120Hz) steps the rig
/// with fixed small substeps, then redraws a handful of CAShapeLayers.
final class SlimeView: UIView {
    let rig: SlimeRig
    var colors: SlimeColors { didSet { applyColors() } }
    /// Fires once per frame, after the rig stepped, so sound/haptics read the same state as the picture.
    var onFrame: ((_ dt: Double) -> Void)?
    var usePredictedTouches = true

    private var link: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    private var laidOutSize: CGSize = .zero

    private let skyLayer = CAGradientLayer()
    private let shadowLayer = CAShapeLayer()
    private let shadeLayer = CAShapeLayer()      // whole body in the shade colour
    private let litGroup = CALayer()             // masked to the body
    private let litMask = CAShapeLayer()
    private let baseLayer = CAShapeLayer()       // same body shifted up-left, in the base colour
    private let highlightLayer = CAShapeLayer()
    private let outlineLayer = CAShapeLayer()

    /// Touches starting this close to the top/bottom edge are left to the system gestures.
    private let edgeBand: CGFloat = 32

    init(rig: SlimeRig, colors: SlimeColors) {
        self.rig = rig
        self.colors = colors
        super.init(frame: .zero)
        isMultipleTouchEnabled = true
        isOpaque = true
        backgroundColor = UIColor(hex: 0xCDEBFA)

        skyLayer.colors = [UIColor(hex: 0xCDEBFA).cgColor, UIColor(hex: 0xE6F5FD).cgColor]
        skyLayer.startPoint = CGPoint(x: 0.5, y: 0)
        skyLayer.endPoint = CGPoint(x: 0.5, y: 1)
        layer.addSublayer(skyLayer)
        shadowLayer.fillColor = UIColor(red: 60 / 255, green: 90 / 255, blue: 40 / 255, alpha: 0.18).cgColor
        layer.addSublayer(shadowLayer)
        layer.addSublayer(shadeLayer)
        litGroup.mask = litMask
        layer.addSublayer(litGroup)
        litGroup.addSublayer(baseLayer)
        litGroup.addSublayer(highlightLayer)
        outlineLayer.fillColor = nil
        outlineLayer.lineJoin = .round
        layer.addSublayer(outlineLayer)
        applyColors()

        isAccessibilityElement = true
        accessibilityLabel = "史萊姆，可以捏、拉、甩它的觸手"
        accessibilityTraits = .allowsDirectInteraction
        accessibilityCustomActions = [
            UIAccessibilityCustomAction(name: "捏一下") { [weak self] _ in
                self?.rig.bump(2); self?.rig.onEvent?(.press(gain: 0.7)); return true
            },
            UIAccessibilityCustomAction(name: "拉長") { [weak self] _ in
                self?.rig.stretchUp(); return true
            },
            UIAccessibilityCustomAction(name: "揉回原形") { [weak self] _ in
                self?.rig.resetShape(); self?.rig.onEvent?(.press(gain: 0.7)); return true
            },
        ]
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func applyColors() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        shadeLayer.fillColor = colors.shade.cgColor
        baseLayer.fillColor = colors.base.cgColor
        highlightLayer.fillColor = colors.light.cgColor
        outlineLayer.strokeColor = colors.line.cgColor
        CATransaction.commit()
    }

    // MARK: - Lifecycle

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            guard link == nil else { return }
            let l = CADisplayLink(target: self, selector: #selector(tick(_:)))
            l.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 120, preferred: 120)
            l.add(to: .main, forMode: .common)
            link = l
            lastTimestamp = 0
        } else {
            link?.invalidate()
            link = nil
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let size = bounds.size
        guard size.width > 0, size.height > 0 else { return }
        // ignore small height changes (keyboard, panels), rebuild on real size changes
        if abs(size.width - laidOutSize.width) > 2 || abs(size.height - laidOutSize.height) > 160 || laidOutSize == .zero {
            laidOutSize = size
            rig.setup(width: Double(size.width), height: Double(size.height))
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            skyLayer.frame = bounds
            for l in [shadowLayer, shadeLayer, litGroup, litMask, baseLayer, highlightLayer, outlineLayer] as [CALayer] {
                l.frame = bounds
            }
            redraw()
            CATransaction.commit()
        }
    }

    // MARK: - Touches

    private func touchAllowed(_ p: CGPoint) -> Bool {
        p.y > safeAreaInsets.top + edgeBand && p.y < bounds.height - safeAreaInsets.bottom - edgeBand
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            let p = t.location(in: self)
            rig.touchBegan(ObjectIdentifier(t), x: Double(p.x), y: Double(p.y), time: t.timestamp, allowed: touchAllowed(p))
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            // coalesced samples: true travelled distance at the digitizer rate
            let samples = event?.coalescedTouches(for: t) ?? [t]
            var prev = t.previousLocation(in: self)
            var distance = 0.0
            for s in samples {
                let p = s.location(in: self)
                distance += Double(hypot(p.x - prev.x, p.y - prev.y))
                prev = p
            }
            // predicted touch: chase slightly ahead of the finger to hide latency
            var target = t.location(in: self)
            if usePredictedTouches, let predicted = event?.predictedTouches(for: t)?.last {
                target = predicted.location(in: self)
            }
            rig.touchMoved(ObjectIdentifier(t), x: Double(target.x), y: Double(target.y), distance: distance)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { rig.touchEnded(ObjectIdentifier(t), time: t.timestamp) }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { rig.touchEnded(ObjectIdentifier(t), time: t.timestamp) }
    }

    // MARK: - Frame loop

    @objc private func tick(_ link: CADisplayLink) {
        let now = link.timestamp
        let dt = lastTimestamp == 0 ? 1.0 / 120 : min(1.0 / 30, now - lastTimestamp)
        lastTimestamp = now
        guard dt > 0, laidOutSize != .zero else { return }
        rig.update(dt)
        onFrame?(dt)
        redraw()
    }

    // MARK: - Drawing (flat cartoon)

    private func bodyPath(_ P: [(x: Double, y: Double)], dx: Double = 0, dy: Double = 0) -> CGPath {
        // closed Catmull-Rom spline through the boundary points
        let n = P.count
        let path = CGMutablePath()
        guard n > 2 else { return path }
        func pt(_ i: Int) -> (x: Double, y: Double) { P[(i + n) % n] }
        path.move(to: CGPoint(x: P[0].x + dx, y: P[0].y + dy))
        for i in 0..<n {
            let p0 = pt(i - 1), p1 = pt(i), p2 = pt(i + 1), p3 = pt(i + 2)
            path.addCurve(to: CGPoint(x: p2.x + dx, y: p2.y + dy),
                          control1: CGPoint(x: p1.x + (p2.x - p0.x) / 6 + dx, y: p1.y + (p2.y - p0.y) / 6 + dy),
                          control2: CGPoint(x: p2.x - (p3.x - p1.x) / 6 + dx, y: p2.y - (p3.y - p1.y) / 6 + dy))
        }
        path.closeSubpath()
        return path
    }

    private func redraw() {
        let R = rig.R
        let P = rig.boundaryPoints()
        guard !P.isEmpty else { return }
        let lw = max(4, R * 0.034)

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        var minX = 1e9, maxX = -1e9, maxY = -1e9
        for p in P { minX = min(minX, p.x); maxX = max(maxX, p.x); maxY = max(maxY, p.y) }
        let c = rig.centroid

        // floating: a soft shadow under the lowest point, fainter the higher it hangs
        let sw = (maxX - minX) * 0.5
        let sy = max(maxY, rig.cy + R * 1.2) + R * 0.35
        let lift = max(0, min(1, (sy - maxY) / (R * 1.2)))
        shadowLayer.opacity = Float((0.10 + 0.08 * (1 - lift)) / 0.18)
        let rx = sw * (0.7 + 0.3 * (1 - lift)), ry = R * 0.11 * 0.8
        shadowLayer.path = CGPath(ellipseIn: CGRect(x: c.x - rx, y: sy - ry, width: rx * 2, height: ry * 2), transform: nil)

        let body = bodyPath(P)
        shadeLayer.path = body
        litMask.path = body
        baseLayer.path = bodyPath(P, dx: -R * 0.07, dy: -R * 0.085)

        // highlight rides on an upper-left particle and turns with the body
        let hp = rig.highlight, ang = rig.bodyAngle
        let hl = CGMutablePath()
        let t = CGAffineTransform(translationX: hp.x, y: hp.y).rotated(by: ang - 0.5)
        hl.addEllipse(in: CGRect(x: -R * 0.17, y: -R * 0.085, width: R * 0.34, height: R * 0.17), transform: t)
        let dot = CGAffineTransform(translationX: hp.x + cos(ang - 0.2) * R * 0.26, y: hp.y + sin(ang - 0.2) * R * 0.26)
        hl.addEllipse(in: CGRect(x: -R * 0.035, y: -R * 0.035, width: R * 0.07, height: R * 0.07), transform: dot)
        highlightLayer.path = hl

        outlineLayer.lineWidth = lw
        outlineLayer.path = body

        CATransaction.commit()
    }
}
