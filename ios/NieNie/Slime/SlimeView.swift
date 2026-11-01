import UIKit

/// Draws the slime and reads raw touches. A CADisplayLink (up to 120Hz) steps the rig
/// with fixed small substeps, then redraws a handful of CAShapeLayers.
final class SlimeView: UIView {
    let rig: SlimeRig
    var colors: SlimeColors { didSet { applyColors(animated: !rig.reduceMotion) } }
    /// Fires once per frame, after the rig stepped, so sound/haptics read the same state as the picture.
    var onFrame: ((_ dt: Double) -> Void)?
    var usePredictedTouches = true

    /// Readout for the hidden panel, refreshed twice a second (Domi has no Mac, so no Instruments).
    struct FrameStats {
        var hz = 0.0            // frames actually drawn per second
        var maxFrameMs = 0.0    // longest frame in the last second
        var dropped = 0         // frames longer than 1.5× the display's frame interval, last second
        var workMs = 0.0        // physics + sound/haptics + drawing on the main thread, average, last second
        var touchRadius = 0.0   // UITouch.majorRadius of the finger down, points
    }
    var onStats: ((FrameStats) -> Void)?
    /// Latency test (3-4 做法三): the whole screen flashes white for exactly one frame when a finger lands, so
    /// 240fps slow motion can count "finger touches → flash" (input to display) and "→ spread" (with physics).
    var latencyTest = false
    private let flashLayer = CALayer()
    private var flashFrames = 0
    private var frameLog: [(time: CFTimeInterval, dt: Double, work: Double, dropped: Bool)] = []
    private var lastStatsTime: CFTimeInterval = 0

    private var link: CADisplayLink?
    // 提案第 35 條: 120Hz only while a finger is down (and for a second after); 60Hz idle so a three-minute toy does not heat up
    private var touchesDown = 0
    private var lastTouchEnd: CFTimeInterval = -10
    private var frameRate: Float = 0
    private var bandMode = false   // 候選 34: outline drawn as a filled band of varying width
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
        flashLayer.backgroundColor = UIColor.white.cgColor
        flashLayer.isHidden = true
        layer.addSublayer(flashLayer)
        applyColors()

        isAccessibilityElement = true
        accessibilityLabel = "史萊姆，可以捏、拉、揉，拉出來的形狀會留一陣子"
        accessibilityTraits = .allowsDirectInteraction
        accessibilityCustomActions = [
            UIAccessibilityCustomAction(name: "捏一下") { [weak self] _ in
                self?.rig.bump(2); self?.rig.onEvent?(.press(gain: 0.7)); return true
            },
            UIAccessibilityCustomAction(name: "拉長") { [weak self] _ in
                self?.rig.stretchUp(); return true
            },
            UIAccessibilityCustomAction(name: "揉回原形") { [weak self] _ in
                self?.rig.relax(); self?.rig.onEvent?(.press(gain: 0.7)); return true
            },
        ]
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// 提案第 30 條: a material switch fades its colours over 0.25 s (hard cut at setup and with Reduce Motion).
    private func applyColors(animated: Bool = false) {
        CATransaction.begin()
        if animated {
            CATransaction.setAnimationDuration(0.25)
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeInEaseOut))
        } else {
            CATransaction.setDisableActions(true)
        }
        shadeLayer.fillColor = colors.shade.cgColor
        baseLayer.fillColor = colors.base.cgColor
        highlightLayer.fillColor = colors.light.cgColor
        outlineLayer.strokeColor = bandMode ? nil : colors.line.cgColor
        outlineLayer.fillColor = bandMode ? colors.line.cgColor : nil
        CATransaction.commit()
    }

    // MARK: - Lifecycle

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            guard link == nil else { return }
            let l = CADisplayLink(target: self, selector: #selector(tick(_:)))
            l.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 120, preferred: 120)
            frameRate = 120
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
            for l in [shadowLayer, shadeLayer, litGroup, litMask, baseLayer, highlightLayer, outlineLayer, flashLayer] as [CALayer] {
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
        touchesDown += touches.count
        setFrameRate(120)
        if latencyTest {
            // shown from the touch handler itself, before any physics, so it measures the input-to-display pipeline
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            flashLayer.isHidden = false
            flashFrames = 0
            CATransaction.commit()
        }
        for t in touches {
            let p = t.location(in: self)
            rig.touchBegan(ObjectIdentifier(t), x: Double(p.x), y: Double(p.y), time: t.timestamp,
                           allowed: touchAllowed(p), radius: Double(t.majorRadius))
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
            // predicted touch: handed over separately; the rig uses it only until the next event arrives
            var px: Double?, py: Double?
            if usePredictedTouches, let predicted = event?.predictedTouches(for: t)?.last {
                let q = predicted.location(in: self)
                px = Double(q.x); py = Double(q.y)
            }
            let p = t.location(in: self)
            rig.touchMoved(ObjectIdentifier(t), x: Double(p.x), y: Double(p.y), predictedX: px, predictedY: py,
                           distance: distance, radius: Double(t.majorRadius))
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { rig.touchEnded(ObjectIdentifier(t), time: t.timestamp) }
        touchesDown = max(0, touchesDown - touches.count)
        lastTouchEnd = CACurrentMediaTime()
    }

    /// The system took the touch (edge gesture, call, app switch): let go without the release pop.
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { rig.touchCancelled(ObjectIdentifier(t)) }
        touchesDown = max(0, touchesDown - touches.count)
        lastTouchEnd = CACurrentMediaTime()
    }

    /// 提案第 35 條. The latency test keeps 120Hz so the slow-motion count measures the 120Hz pipeline; from idle the
    /// first frame after a touch can be one 60Hz frame (up to 8 ms) later, which the panel's Hz readout also shows.
    private func setFrameRate(_ hz: Float) {
        guard hz != frameRate, let l = link else { return }
        frameRate = hz
        l.preferredFrameRateRange = hz >= 120
            ? CAFrameRateRange(minimum: 60, maximum: 120, preferred: 120)
            : CAFrameRateRange(minimum: 60, maximum: 60, preferred: 60)
    }

    // MARK: - Frame loop

    @objc private func tick(_ link: CADisplayLink) {
        let now = link.timestamp
        let dt = lastTimestamp == 0 ? 1.0 / 120 : min(1.0 / 30, now - lastTimestamp)
        setFrameRate(touchesDown > 0 || latencyTest || now - lastTouchEnd < 1 ? 120 : 60)
        let nominal = max(1.0 / 120, link.targetTimestamp - link.timestamp)
        lastTimestamp = now
        guard dt > 0, laidOutSize != .zero else { return }
        // latency flash: visible for exactly one drawn frame
        if !flashLayer.isHidden {
            if flashFrames >= 1 {
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                flashLayer.isHidden = true
                CATransaction.commit()
            } else {
                flashFrames += 1
            }
        }
        let t0 = CACurrentMediaTime()
        rig.update(dt)
        onFrame?(dt)
        redraw()
        let work = CACurrentMediaTime() - t0
        // frame readout over a one-second window
        frameLog.append((time: now, dt: dt, work: work, dropped: dt > nominal * 1.5))
        while let first = frameLog.first, now - first.time > 1 { frameLog.removeFirst() }
        if now - lastStatsTime > 0.5, let onStats, let first = frameLog.first {
            lastStatsTime = now
            var s = FrameStats()
            s.hz = Double(frameLog.count) / max(0.1, now - first.time + dt)
            s.maxFrameMs = (frameLog.map { $0.dt }.max() ?? 0) * 1000
            s.dropped = frameLog.filter { $0.dropped }.count
            s.workMs = frameLog.map { $0.work }.reduce(0, +) / Double(frameLog.count) * 1000
            s.touchRadius = rig.maxTouchRadius
            onStats(s)
        }
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

    /// 候選 34: the outline as a filled band whose width follows each segment's compression (1.3× squashed, 0.8× stretched).
    /// A CAShapeLayer stroke has one width, so the spline is sampled and offset to both sides into a ring polygon.
    private func inkBand(_ P: [(x: Double, y: Double)], lw: Double, inkVar: Double) -> CGPath {
        let n = P.count, c = rig.boundaryCompression()
        let path = CGMutablePath()
        guard n > 2, c.count == n else { return path }
        var w = [Double](repeating: lw, count: n)
        for i in 0..<n {
            let f = c[i] < 1 ? 1 + 0.3 * min(1, (1 - c[i]) / 0.4) : 1 - 0.2 * min(1, (c[i] - 1) / 1.4)
            w[i] = lw * (1 + inkVar * (f - 1))
        }
        func pt(_ i: Int) -> (x: Double, y: Double) { P[(i + n) % n] }
        var outer: [CGPoint] = [], inner: [CGPoint] = []
        outer.reserveCapacity(n * 3); inner.reserveCapacity(n * 3)
        for i in 0..<n {
            let p0 = pt(i - 1), p1 = pt(i), p2 = pt(i + 1), p3 = pt(i + 2)
            let c1x = p1.x + (p2.x - p0.x) / 6, c1y = p1.y + (p2.y - p0.y) / 6
            let c2x = p2.x - (p3.x - p1.x) / 6, c2y = p2.y - (p3.y - p1.y) / 6
            let wa = (w[(i + n - 1) % n] + w[i]) * 0.5, wb = (w[i] + w[(i + 1) % n]) * 0.5
            for s in 0..<3 {
                let u = Double(s) / 3, mu = 1 - u
                let b0 = mu * mu * mu, b1 = 3 * mu * mu * u, b2 = 3 * mu * u * u, b3 = u * u * u
                let bx = b0 * p1.x + b1 * c1x + b2 * c2x + b3 * p2.x
                let by = b0 * p1.y + b1 * c1y + b2 * c2y + b3 * p2.y
                let d0 = 3 * mu * mu, d1 = 6 * mu * u, d2 = 3 * u * u
                var tx = d0 * (c1x - p1.x) + d1 * (c2x - c1x) + d2 * (p2.x - c2x)
                var ty = d0 * (c1y - p1.y) + d1 * (c2y - c1y) + d2 * (p2.y - c2y)
                let tl = max(1e-6, hypot(tx, ty)); tx /= tl; ty /= tl
                let hw = (wa + (wb - wa) * u) * 0.5
                outer.append(CGPoint(x: bx - ty * hw, y: by + tx * hw))
                inner.append(CGPoint(x: bx + ty * hw, y: by - tx * hw))
            }
        }
        path.addLines(between: outer); path.closeSubpath()
        path.addLines(between: Array(inner.reversed())); path.closeSubpath()
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

        // 候選 34: outline width follows compression (a band path), else a plain stroke
        let inkVar = rig.params.inkVar
        if (inkVar > 0) != bandMode {
            bandMode = inkVar > 0
            outlineLayer.strokeColor = bandMode ? nil : colors.line.cgColor
            outlineLayer.fillColor = bandMode ? colors.line.cgColor : nil
        }
        if bandMode {
            outlineLayer.path = inkBand(P, lw: lw, inkVar: inkVar)
        } else {
            outlineLayer.lineWidth = lw
            outlineLayer.path = body
        }

        CATransaction.commit()
    }
}
