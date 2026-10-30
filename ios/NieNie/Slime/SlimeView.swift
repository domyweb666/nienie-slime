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

    private let backgroundLayer = CALayer()
    private let groundShadowLayer = CAShapeLayer()
    private let clipLayer = CALayer()            // cuts the body flat at the ground
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

        layer.addSublayer(backgroundLayer)
        groundShadowLayer.fillColor = UIColor(red: 60 / 255, green: 110 / 255, blue: 50 / 255, alpha: 0.22).cgColor
        layer.addSublayer(groundShadowLayer)
        clipLayer.masksToBounds = true
        layer.addSublayer(clipLayer)
        clipLayer.addSublayer(shadeLayer)
        litGroup.mask = litMask
        clipLayer.addSublayer(litGroup)
        litGroup.addSublayer(baseLayer)
        litGroup.addSublayer(highlightLayer)
        outlineLayer.fillColor = nil
        outlineLayer.lineJoin = .round
        clipLayer.addSublayer(outlineLayer)
        applyColors()

        isAccessibilityElement = true
        accessibilityLabel = "史萊姆，可以揉、拉長、推回去"
        accessibilityTraits = .allowsDirectInteraction
        accessibilityCustomActions = [
            UIAccessibilityCustomAction(name: "捏一下") { [weak self] _ in
                self?.rig.bump(3.5); self?.rig.onEvent?(.squish(0.7)); return true
            },
            UIAccessibilityCustomAction(name: "拉長") { [weak self] _ in
                self?.rig.stretchUp(); return true
            },
            UIAccessibilityCustomAction(name: "揉圓") { [weak self] _ in
                self?.rig.resetShape(); self?.rig.onEvent?(.squish(0.7)); return true
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
        // like the prototype: ignore small height changes, rebuild on real size changes
        if abs(size.width - laidOutSize.width) > 2 || abs(size.height - laidOutSize.height) > 160 || laidOutSize == .zero {
            laidOutSize = size
            rig.setup(width: Double(size.width), height: Double(size.height))
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            for l in [backgroundLayer, groundShadowLayer] { l.frame = bounds }
            backgroundLayer.contents = drawBackground(size: size).cgImage
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
        let n = max(1, Int(ceil(dt / 0.004)))
        for _ in 0..<n { rig.update(dt / Double(n)) }
        onFrame?(dt)
        redraw()
    }

    // MARK: - Drawing (flat cartoon)

    private func bodyPath(_ P: [(x: Double, y: Double)], dx: Double = 0, dy: Double = 0) -> CGPath {
        // closed Catmull-Rom spline through the control points
        let n = P.count
        let path = CGMutablePath()
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
        let K = SlimeRig.K, R = rig.R, ground = rig.ground, sq = rig.sq
        let P = rig.points()
        let lw = max(3, R * 0.055)

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        // soft shadow under the part touching the ground
        var x0 = 1e9, x1 = -1e9
        for p in P where p.y > ground - R * 0.3 { x0 = min(x0, p.x); x1 = max(x1, p.x) }
        if x1 > x0 {
            let rx = (x1 - x0) / 2 + R * 0.12, ry = R * 0.1
            groundShadowLayer.path = CGPath(ellipseIn: CGRect(x: (x0 + x1) / 2 - rx, y: ground + R * 0.05 - ry,
                                                              width: rx * 2, height: ry * 2), transform: nil)
        } else {
            groundShadowLayer.path = nil
        }

        let clip = CGRect(x: 0, y: 0, width: bounds.width, height: CGFloat(ground + lw * 0.5))
        if clipLayer.frame != clip {
            clipLayer.frame = clip
            for l in [shadeLayer, litGroup, litMask, baseLayer, highlightLayer, outlineLayer] as [CALayer] {
                l.frame = CGRect(origin: .zero, size: bounds.size)
            }
        }

        let body = bodyPath(P)
        shadeLayer.path = body
        litMask.path = body
        baseLayer.path = bodyPath(P, dx: -R * 0.07, dy: -R * 0.1)

        // highlight rides on the upper-left part of the body
        let a = P[Int((Double(K) * 0.82).rounded()) % K], b = P[Int((Double(K) * 0.9).rounded()) % K], c = P[0]
        let hx = (a.x + b.x + c.x) / 3 + R * 0.25, hy = (a.y + b.y + c.y) / 3 + R * 0.22
        let t = CGAffineTransform(translationX: hx, y: hy).rotated(by: -0.5).scaledBy(x: 1 + sq * 0.4, y: 1 - sq * 0.5)
        let hl = CGMutablePath()
        hl.addEllipse(in: CGRect(x: -R * 0.2, y: -R * 0.085, width: R * 0.4, height: R * 0.17), transform: t)
        hl.addEllipse(in: CGRect(x: R * 0.27 - R * 0.04, y: R * 0.09 - R * 0.04, width: R * 0.08, height: R * 0.08), transform: t)
        highlightLayer.path = hl

        outlineLayer.lineWidth = lw
        outlineLayer.path = body

        CATransaction.commit()
    }

    /// Flat sunny field, drawn once per size (sky, clouds, grass).
    private func drawBackground(size: CGSize) -> UIImage {
        let W = Double(size.width), H = Double(size.height), R = rig.R
        let hz = rig.ground - R * 0.55
        let format = UIGraphicsImageRendererFormat.preferred()
        format.opaque = true
        return UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            let g = ctx.cgContext
            g.setFillColor(UIColor(hex: 0xCDEBFA).cgColor)
            g.fill(CGRect(x: 0, y: 0, width: W, height: hz))
            g.setFillColor(UIColor(hex: 0xE6F6FF).cgColor)
            for (u, v, s) in [(0.18, 0.18, 1.0), (0.72, 0.12, 0.8), (0.9, 0.3, 0.6)] {
                let x = u * W, y = v * H, r = R * 0.45 * s
                for (cx, cy, cr) in [(x, y, r), (x + r * 0.9, y + r * 0.15, r * 0.75), (x - r * 0.9, y + r * 0.2, r * 0.65)] {
                    g.fillEllipse(in: CGRect(x: cx - cr, y: cy - cr, width: cr * 2, height: cr * 2))
                }
            }
            g.setFillColor(UIColor(hex: 0xBFE6A8).cgColor)
            g.fill(CGRect(x: 0, y: hz, width: W, height: H - hz))
            g.setFillColor(UIColor(hex: 0xA9D98F).cgColor)
            g.fill(CGRect(x: 0, y: hz, width: W, height: 4))
            g.setStrokeColor(UIColor(hex: 0x97CB7C).cgColor)
            g.setLineWidth(3)
            g.setLineCap(.round)
            for (u, v) in [(0.1, 0.84), (0.2, 0.95), (0.82, 0.86), (0.9, 0.97), (0.35, 1.02), (0.66, 1.05)] {
                let x = u * W, y = hz + (H - hz) * (v - 0.75) * 1.6
                g.move(to: CGPoint(x: x - 6, y: y)); g.addLine(to: CGPoint(x: x - 9, y: y - 9))
                g.move(to: CGPoint(x: x, y: y)); g.addLine(to: CGPoint(x: x, y: y - 12))
                g.move(to: CGPoint(x: x + 6, y: y)); g.addLine(to: CGPoint(x: x + 9, y: y - 9))
            }
            g.strokePath()
        }
    }
}
