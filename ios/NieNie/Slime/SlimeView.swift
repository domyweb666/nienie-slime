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
    // v2.28 窗台: the room baked into one picture behind it (sky, window, wall, the dish, the plant, the bowl), and the bowl's front half over it while it sits inside
    private let sceneLayer = CALayer(), bowlFrontLayer = CALayer()
    private var sceneKey = ""
    private let speckLayers = [CAShapeLayer(), CAShapeLayer()]   // v2.17: far-away specks, two strengths
    private let shadowLayer = CAShapeLayer()
    private let shadeLayer = CAShapeLayer()      // whole body in the shade colour
    private let litGroup = CALayer()             // masked to the body
    private let litMask = CAShapeLayer()
    private let baseLayer = CAShapeLayer()       // same body shifted up-left, in the base colour
    private let dentShadeLayer = CAShapeLayer()  // v2.15 dents (press2 0): an ellipse in the shade colour...
    private let dentLitLayer = CAShapeLayer()    // ...covered by the base colour shifted down-right, leaving a crescent upper-left
    private var dentLayers: [CALayer] = []       // v2.16 dents: a soft pit image each, stretched with the skin
    private var trailLayers: [CAShapeLayer] = []  // v2.26 F7 the trail: five ages, each a wide faint and a narrow darker band, in the shade colour up-left and the light colour down-right
    private var dentImage: CGImage?
    private let dentUnit: CGFloat = 40           // the pit image is drawn for this radius (points)
    private let highlightLayer = CAShapeLayer()
    private let outlineLayer = CAShapeLayer()
    private var tintKey = -1   // v2.22 E3: the impression tint last applied (rounded), −1 = plain colours
    private let eyeFillLayer = CAShapeLayer()    // v2.23 eyes, inside the body: open eyes...
    private let eyeLightLayer = CAShapeLayer()   // ...their white glints...
    private let eyeLineLayer = CAShapeLayer()    // ...and the ∩ ∪ > < and shut ones as strokes

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
        sceneLayer.contentsGravity = .resize; sceneLayer.isHidden = true
        layer.addSublayer(sceneLayer)
        for (n, l) in speckLayers.enumerated() {
            l.fillColor = UIColor.white.cgColor
            l.opacity = n == 0 ? 0.4 : 0.7
            layer.addSublayer(l)
        }
        shadowLayer.fillColor = UIColor(red: 60 / 255, green: 90 / 255, blue: 40 / 255, alpha: 0.18).cgColor
        layer.addSublayer(shadowLayer)
        layer.addSublayer(shadeLayer)
        litGroup.mask = litMask
        layer.addSublayer(litGroup)
        litGroup.addSublayer(baseLayer)
        litGroup.addSublayer(dentShadeLayer)
        litGroup.addSublayer(dentLitLayer)
        for _ in 0..<20 {
            let l = CAShapeLayer()
            l.fillColor = nil; l.lineCap = .butt; l.lineJoin = .round; l.isHidden = true
            litGroup.addSublayer(l)
            trailLayers.append(l)
        }
        for _ in 0..<6 {   // four dents and up to two stroking fingers
            let l = CALayer()
            l.bounds = CGRect(x: 0, y: 0, width: dentUnit * 2.6, height: dentUnit * 2.6)
            l.isHidden = true
            litGroup.addSublayer(l)
            dentLayers.append(l)
        }
        litGroup.addSublayer(highlightLayer)
        eyeLightLayer.fillColor = UIColor.white.cgColor
        eyeLineLayer.fillColor = nil; eyeLineLayer.lineCap = .round; eyeLineLayer.lineJoin = .round
        litGroup.addSublayer(eyeFillLayer); litGroup.addSublayer(eyeLightLayer); litGroup.addSublayer(eyeLineLayer)
        outlineLayer.fillColor = nil
        outlineLayer.lineJoin = .round
        layer.addSublayer(outlineLayer)
        bowlFrontLayer.contentsGravity = .resize; bowlFrontLayer.isHidden = true
        layer.addSublayer(bowlFrontLayer)   // v2.28 窗台: in front of the body and the eyes
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
        dentShadeLayer.fillColor = colors.shade.cgColor
        dentLitLayer.fillColor = colors.base.cgColor
        dentImage = makeDentImage()
        for l in dentLayers { l.contents = dentImage }
        for b in 0..<5 {
            let kk = (CGFloat(b) + 0.5) / 5
            trailLayers[b * 4].strokeColor = colors.shade.withAlphaComponent(0.22 * kk).cgColor
            trailLayers[b * 4 + 1].strokeColor = colors.shade.withAlphaComponent(0.28 * kk).cgColor
            trailLayers[b * 4 + 2].strokeColor = colors.light.withAlphaComponent(0.16 * kk).cgColor
            trailLayers[b * 4 + 3].strokeColor = colors.light.withAlphaComponent(0.2 * kk).cgColor
        }
        highlightLayer.fillColor = colors.light.cgColor
        outlineLayer.strokeColor = bandMode ? nil : colors.line.cgColor
        outlineLayer.fillColor = bandMode ? colors.line.cgColor : nil
        eyeFillLayer.fillColor = colors.eye.cgColor; eyeLineLayer.strokeColor = colors.eye.cgColor
        tintKey = -1
        CATransaction.commit()
    }

    /// v2.22 E3: trusting leans warm, wary leans pale, inside the same two flat colours (the style stays).
    private func tinted(_ c: UIColor, _ tr: Double, _ w: Double, shade: Bool = false) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        c.getRed(&r, green: &g, blue: &b, alpha: &a)
        var rr = min(255, Double(r) * 255 + 22 * tr), gg = min(255, Double(g) * 255 + 4 * tr), bb = max(0, Double(b) * 255 - 18 * tr)
        rr += (255 - rr) * 0.22 * w; gg += (255 - gg) * 0.22 * w; bb += (255 - bb) * 0.22 * w
        // v2.27 mood colour: towards the mood's colour, by the same share for every slime
        let mC: Double = rig.mcC, mS: Double = rig.mcS, mW: Double = rig.mcW, mZ: Double = rig.mcZ, sum: Double = mC + mS + mW + mZ, A: Double = rig.params.moodColor
        if A > 0 && sum > 0.002 {
            let k: Double = A * sum / max(1, sum), sh: Double = shade ? 0.82 : 1
            let mr: Double = (mC * 255 + mS * 240 + mW * 141 + mZ * 108) / sum * sh
            let mg: Double = (mC * 154 + mS * 68 + mW * 166 + mZ * 120) / sum * sh
            let mb: Double = (mC * 139 + mS * 79 + mW * 217 + mZ * 184) / sum * sh
            rr += (mr - rr) * k; gg += (mg - gg) * k; bb += (mb - bb) * k
        }
        return UIColor(red: CGFloat(rr / 255), green: CGFloat(gg / 255), blue: CGFloat(bb / 255), alpha: a)
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
            let first = laidOutSize == .zero
            laidOutSize = size
            rig.setup(width: Double(size.width), height: Double(size.height))
            if first { rig.startIntro() }   // v2.17: the hop-in plays on a cold start only, not on a rotation or coming back from the background
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            skyLayer.frame = bounds
            sceneLayer.frame = bounds; sceneKey = ""
            for l in ([shadowLayer, shadeLayer, litGroup, litMask, baseLayer, dentShadeLayer, dentLitLayer, highlightLayer, outlineLayer, flashLayer,
                       eyeFillLayer, eyeLightLayer, eyeLineLayer] as [CALayer]) + (speckLayers as [CALayer]) + (trailLayers as [CALayer]) {
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

    /// v2.16 P2 (多米: the press looked like a toy; two crescents read as brows and eyes): the light comes from the upper left,
    /// so inside the pit the upper-left wall is dark. A two-circle gradient from the lower right (light) to the upper-left rim
    /// (dark), soft at the edge; outside it on the lower right a faint lit lip, the skin pushed up around the press.
    /// Same stops as the prototype's drawDents.
    private func makeDentImage() -> CGImage? {
        let u = dentUnit, size = CGSize(width: u * 2.6, height: u * 2.6)
        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = 3
        let img = UIGraphicsImageRenderer(size: size, format: fmt).image { ctx in
            let g = ctx.cgContext, c = CGPoint(x: size.width / 2, y: size.height / 2), sp = CGColorSpaceCreateDeviceRGB()
            let sh = colors.shade, hi = colors.light
            if let grad = CGGradient(colorsSpace: sp, colors: [sh.withAlphaComponent(0).cgColor, sh.withAlphaComponent(0.3).cgColor,
                                                                sh.withAlphaComponent(0.9).cgColor, sh.withAlphaComponent(0).cgColor] as CFArray,
                                     locations: [0, 0.5, 0.86, 1]) {
                g.drawRadialGradient(grad, startCenter: CGPoint(x: c.x + u * 0.42, y: c.y + u * 0.5), startRadius: u * 0.3,
                                     endCenter: c, endRadius: u, options: [])
            }
            g.addEllipse(in: CGRect(x: c.x + u * 0.55 - u * 1.05, y: c.y + u * 0.65 - u * 1.05, width: u * 2.1, height: u * 2.1))
            g.clip()
            if let grad = CGGradient(colorsSpace: sp, colors: [hi.withAlphaComponent(0).cgColor, hi.withAlphaComponent(0.45).cgColor,
                                                                hi.withAlphaComponent(0).cgColor] as CFArray, locations: [0, 0.35, 1]) {
                g.drawRadialGradient(grad, startCenter: c, startRadius: u * 0.92, endCenter: c, endRadius: u * 1.28, options: [])
            }
        }
        return img.cgImage
    }

    /// v2.28 窗台: the baked room behind it and the bowl's front half over it; the blue sky and the specks only while floating.
    private func updateScene() {
        let kind = rig.sceneKind
        guard kind > 0, let g = rig.sillG, bounds.width > 0, bounds.height > 0 else {
            sceneLayer.isHidden = true; bowlFrontLayer.isHidden = true; skyLayer.isHidden = false
            for l in speckLayers { l.isHidden = false }
            return
        }
        let key = "\(kind)|\(Int(bounds.width))|\(Int(bounds.height))"
        if key != sceneKey {
            if let imgs = SceneArt.make(kind: kind, size: bounds.size, g: g) {
                sceneKey = key
                sceneLayer.contents = imgs.base.cgImage
                bowlFrontLayer.contents = imgs.bowlFront.cgImage
                bowlFrontLayer.frame = CGRect(x: g.bx - g.bw / 2, y: g.by, width: g.bw, height: g.bh)
            } else {   // pictures missing: the plain sky, nothing else (the physics still has the sill)
                sceneLayer.isHidden = true; bowlFrontLayer.isHidden = true; skyLayer.isHidden = false
                return
            }
        }
        skyLayer.isHidden = true; sceneLayer.isHidden = false
        for l in speckLayers { l.isHidden = true }
        bowlFrontLayer.isHidden = !rig.sillInBowl
    }

    /// v2.17: a layer of faint fixed specks far behind (parallax 0.55, they move slower than the slime). Without them a following
    /// camera looks like the slime walking back by itself. One speck or none per 120-point cell, hashed from the cell.
    private func drawSpecks() {
        guard rig.params.specks >= 0.5 else { for l in speckLayers { l.path = nil }; return }
        let v = rig.viewV, par = 0.55, zf = 1 + (rig.camZ - 1) * par, cell = 120.0, bx = rig.camX * par, by = rig.camY * par
        let W = Double(bounds.width), H = Double(bounds.height)
        func hs(_ a: Int, _ b: Int, _ c: Int) -> Double {
            var n = UInt32(truncatingIfNeeded: a &* 374761393 &+ b &* 668265263 &+ c &* 2147483647)
            n = (n ^ (n >> 13)) &* 1274126177
            return Double(n ^ (n >> 16)) / 4294967296
        }
        let x0 = Int(floor((bx - v.x / zf) / cell)) - 1, x1 = Int(ceil((bx + (W - v.x) / zf) / cell)) + 1
        let y0 = Int(floor((by - v.y / zf) / cell)) - 1, y1 = Int(ceil((by + (H - v.y) / zf) / cell)) + 1
        let paths = [CGMutablePath(), CGMutablePath()]
        if x1 >= x0 && y1 >= y0 && (x1 - x0) * (y1 - y0) < 4000 {
            for i in x0...x1 {
                for j in y0...y1 where hs(i, j, 1) <= 0.45 {
                    let sx = (Double(i) * cell + hs(i, j, 2) * cell - bx) * zf + v.x, sy = (Double(j) * cell + hs(i, j, 3) * cell - by) * zf + v.y
                    let r = (1.4 + 2 * hs(i, j, 4)) * zf
                    paths[hs(i, j, 5) < 0.5 ? 0 : 1].addEllipse(in: CGRect(x: sx - r, y: sy - r, width: r * 2, height: r * 2))
                }
            }
        }
        speckLayers[0].path = paths[0]; speckLayers[1].path = paths[1]
    }

    /// v2.26 F7: one age band of the trail, in one continuous path where it can be (short pieces drawn apart go jagged around a small circle)
    private func trailPath(_ tr: [(x: Double, y: Double, k: Double, n: Double)], _ k0: Double, _ k1: Double, _ last: Bool, _ ox: Double, _ oy: Double) -> CGPath {
        let p = CGMutablePath()
        var open = false
        for j in 1..<tr.count {
            let q = tr[j], a = tr[j - 1]
            if q.n != a.n || q.k < k0 || (q.k >= k1 && !last) { open = false; continue }
            if !open {
                let s = rig.toScreen(a.x, a.y)
                p.move(to: CGPoint(x: s.x + ox, y: s.y + oy))
                open = true
            }
            let s = rig.toScreen(q.x, q.y)
            p.addLine(to: CGPoint(x: s.x + ox, y: s.y + oy))
        }
        return p
    }

    private func redraw() {
        // v2.12 camera: everything is drawn in screen points through rig.toScreen; sizes scale with the zoom, the outline
        // keeps its on-screen width
        let z = rig.drawZ, R = rig.R * z
        let P = rig.boundaryPoints().map { p -> (x: Double, y: Double) in rig.toScreen(p.x, p.y) }
        guard !P.isEmpty else { return }
        let lw = max(4, rig.R * 0.034)

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        drawSpecks()
        updateScene()   // v2.28 窗台

        var minX = 1e9, maxX = -1e9, maxY = -1e9
        for p in P { minX = min(minX, p.x); maxX = max(maxX, p.x); maxY = max(maxY, p.y) }
        let shadowX = (minX + maxX) / 2   // the shadow centres on the whole width (a long pull shifts the centroid aside)

        // floating: a soft shadow under the lowest point, fainter the higher it hangs. v2.19 A8: none (it floats and walks every way;
        // a shadow said up was flying one moment and the floor moved along the next)
        let noShadow = rig.params.life2 >= 0.5 && rig.params.shadow < 0.5
        shadowLayer.isHidden = noShadow
        if !noShadow {
            let sw = (maxX - minX) * 0.5
            let sy = max(maxY, rig.toScreen(0, rig.cy).y + R * 1.2) + R * 0.35
            let lift = max(0, min(1, (sy - maxY) / (R * 1.2)))
            let pz = rig.params.press2 >= 0.5 ? max(0, rig.pressSum) : 0   // v2.16 P6: pressed, the body sinks a little: a wider, darker shadow
            shadowLayer.opacity = Float((0.10 + 0.08 * (1 - lift) + 0.04 * pz) / 0.18)
            let rx = sw * (0.7 + 0.3 * (1 - lift)) * (1 + 0.08 * pz), ry = R * 0.11 * 0.8
            shadowLayer.path = CGPath(ellipseIn: CGRect(x: shadowX - rx, y: sy - ry, width: rx * 2, height: ry * 2), transform: nil)
        }

        let body = bodyPath(P)
        shadeLayer.path = body
        litMask.path = body
        baseLayer.path = bodyPath(P, dx: -R * 0.07, dy: -R * 0.085)

        // dents (v2.15): the light comes from the upper left, so inside a dent the upper-left wall is in shade
        let ds = CGMutablePath(), dl = CGMutablePath()
        let dents = rig.dents, press2 = rig.params.press2 >= 0.5
        var used = 0
        if press2 {
            // v2.16 P2: the pit image stretched with the skin around it; held longer it gets wider and shallower
            for dn in dents where dn.d >= 0.02 && used < dentLayers.count {
                let l = dentLayers[used]; used += 1
                let r = R * rig.params.dentSize * (0.65 + 0.35 * dn.w), k = r / Double(dentUnit)
                l.isHidden = false
                let c = rig.toScreen(dn.x, dn.y)
                l.position = CGPoint(x: c.x, y: c.y)
                l.setAffineTransform(CGAffineTransform(a: dn.a * k, b: dn.b * k, c: dn.c * k, d: dn.dd * k, tx: 0, ty: 0))
                l.opacity = Float(dn.d * (1 - 0.35 * dn.w))
            }
        }
        // v2.26 F7: the ring beside a stroking finger, and the trail it leaves
        if press2 {
            for h in rig.strokeHeads where used < dentLayers.count {
                let l = dentLayers[used]; used += 1
                let r: Double = R * rig.params.dentSize * 0.75, k: Double = r / Double(dentUnit)
                l.isHidden = false
                let c = rig.toScreen(h.x, h.y)
                l.position = CGPoint(x: c.x, y: c.y)
                l.setAffineTransform(CGAffineTransform(scaleX: k, y: k))
                l.opacity = 0.6
            }
        }
        let trailNow = press2 ? rig.trailView : []
        if trailNow.count > 1 {
            let ox: Double = -0.64 * R * 0.14, oy: Double = -0.77 * R * 0.14
            for b in 0..<5 {
                let k0: Double = Double(b) / 5, k1: Double = Double(b + 1) / 5, wd: Double = R
                let dark = trailPath(trailNow, k0, k1, b == 4, ox, oy), lit = trailPath(trailNow, k0, k1, b == 4, -ox, -oy)
                trailLayers[b * 4].path = dark; trailLayers[b * 4].lineWidth = CGFloat(wd * 0.2)
                trailLayers[b * 4 + 1].path = dark; trailLayers[b * 4 + 1].lineWidth = CGFloat(wd * 0.1)
                trailLayers[b * 4 + 2].path = lit; trailLayers[b * 4 + 2].lineWidth = CGFloat(wd * 0.16)
                trailLayers[b * 4 + 3].path = lit; trailLayers[b * 4 + 3].lineWidth = CGFloat(wd * 0.08)
            }
            for l in trailLayers { l.isHidden = false }
        } else if !trailLayers[0].isHidden {
            for l in trailLayers { l.isHidden = true; l.path = nil }
        }
        for l in dentLayers[used...] { l.isHidden = true }
        for dn in dents where !press2 {
            let r = R * rig.params.dentSize * dn.d
            if r < 0.5 { continue }
            let c = rig.toScreen(dn.x, dn.y)
            ds.addEllipse(in: CGRect(x: c.x - r, y: c.y - r * 0.8, width: r * 2, height: r * 1.6))
            dl.addEllipse(in: CGRect(x: c.x + r * 0.22 - r * 0.82, y: c.y + r * 0.26 - r * 0.64, width: r * 1.64, height: r * 1.28))
        }
        dentShadeLayer.path = ds
        dentLitLayer.path = dl

        // highlight rides on an upper-left particle and turns with the body
        var hp = rig.toScreen(rig.highlight.x, rig.highlight.y)
        let ang = rig.bodyAngle
        // v2.16 P5: a finger pressing within 0.45R of the highlight squeezes it aside and flattens it along that direction
        var sq = 0.0, ux = 1.0, uy = 0.0
        if press2 {
            var ox = 0.0, oy = 0.0
            for dn in dents where dn.p > 0 {
                let c = rig.toScreen(dn.x, dn.y), dx = hp.x - c.x, dy = hp.y - c.y, d = hypot(dx, dy), rad = R * 0.45
                if d >= rad { continue }
                let a = (1 - d / rad) * min(1, dn.p), vx = d > 1e-6 ? dx / d : 1, vy = d > 1e-6 ? dy / d : 0
                ox += vx * a * R * 0.16; oy += vy * a * R * 0.16
                if a > sq { sq = a; ux = vx; uy = vy }
            }
            hp.x += ox; hp.y += oy
        }
        var S = CGAffineTransform.identity
        if sq > 0 {   // squash to s along u, widen to s2 across
            let k = -0.4 * sq, k2 = 0.25 * sq
            S = CGAffineTransform(a: 1 + k * ux * ux + k2 * uy * uy, b: (k - k2) * ux * uy, c: (k - k2) * ux * uy, d: 1 + k * uy * uy + k2 * ux * ux, tx: 0, ty: 0)
        }
        let hf = rig.highlightFrame   // v2.26 F7: bends with the skin around it
        let HF = CGAffineTransform(a: CGFloat(hf.0), b: CGFloat(hf.1), c: CGFloat(hf.2), d: CGFloat(hf.3), tx: 0, ty: 0)
        let at = HF.concatenating(CGAffineTransform(translationX: hp.x, y: hp.y))
        let hl = CGMutablePath()
        let t = CGAffineTransform(rotationAngle: ang - 0.5).concatenating(S).concatenating(at)
        hl.addEllipse(in: CGRect(x: -R * 0.17, y: -R * 0.085, width: R * 0.34, height: R * 0.17), transform: t)
        let dot = CGAffineTransform(translationX: cos(ang - 0.2) * R * 0.26, y: sin(ang - 0.2) * R * 0.26).concatenating(S).concatenating(at)
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

        // v2.22 E3: the body colour leans with the impression (only re-set when it moved by a visible step)
        let moodOn: Bool = rig.params.moodColor > 0 && rig.mcC + rig.mcS + rig.mcW + rig.mcZ > 0.002
        func q40(_ v: Double) -> Int { Int((v * 40).rounded()) }
        let tkImp: Int = rig.showsImpression ? q40(rig.impShownTrust) * 100 + q40(rig.impShownWary) : -1
        let tkMood: Int = moodOn ? (q40(rig.mcC) + q40(rig.mcS) * 41 + q40(rig.mcW) * 1681 + q40(rig.mcZ) * 68921 + 1) * 10000 : 0
        let tk: Int = tkImp + tkMood
        if tk != tintKey {
            tintKey = tk
            let tr = rig.showsImpression ? rig.impShownTrust : 0, w = rig.showsImpression ? rig.impShownWary : 0
            let sh = tinted(colors.shade, tr, w, shade: true).cgColor, ba = tinted(colors.base, tr, w).cgColor
            shadeLayer.fillColor = sh; baseLayer.fillColor = ba
        }
        // v2.23 eyes (多米 11-02: try a face, eyes only): bean eyes looking where it looks; ∩ happy, ∪ asleep, > < squeezed, a line when shut
        let ef = CGMutablePath(), el = CGMutablePath(), eli = CGMutablePath()
        if let e = rig.eyeView {
            let S = e.size * z, ew = S * 0.082 * sqrt(e.spread), eh = S * 0.118, ox = e.lookX * S, oy = e.lookY * S
            eyeLineLayer.lineWidth = max(2.5, S * 0.034)
            // addArc draws a line from the current point, so each arc needs its own move, or the two eyes get joined by a line (web: beginPath per eye)
            let eyeArc: (Double, Double, Double, Double, Double) -> Void = { ax, ay, ar, a0, a1 in
                el.move(to: CGPoint(x: ax + ar * cos(a0), y: ay + ar * sin(a0)))
                el.addArc(center: CGPoint(x: ax, y: ay), radius: ar, startAngle: a0, endAngle: a1, clockwise: false)
            }
            for (wx, wy, sd) in [(e.lx, e.ly, -1.0), (e.rx, e.ry, 1.0)] {
                let c = rig.toScreen(wx, wy), x = c.x + ox, y = c.y + oy
                switch e.mode {
                case .happy:
                    eyeArc(x, y + eh * 0.45, ew * 1.15, .pi * 1.15, .pi * 1.85)
                case .sleep:
                    eyeArc(x, y - eh * 0.35, ew * 1.15, .pi * 0.15, .pi * 0.85)
                case .squeeze:
                    let a = -sd
                    el.move(to: CGPoint(x: x + a * ew * 0.9, y: y - eh * 0.55))
                    el.addLine(to: CGPoint(x: x - a * ew * 0.8, y: y))
                    el.addLine(to: CGPoint(x: x + a * ew * 0.9, y: y + eh * 0.55))
                case .open:
                    let h = eh * e.open * e.wide * e.blink, w = ew * e.wide
                    if h < w * 0.35 {
                        el.move(to: CGPoint(x: x - w, y: y)); el.addLine(to: CGPoint(x: x + w, y: y))
                    } else {
                        ef.addEllipse(in: CGRect(x: x - w, y: y - h, width: 2 * w, height: 2 * h))
                        if h > w * 0.7 { let lr = w * 0.34; eli.addEllipse(in: CGRect(x: x - w * 0.32 - lr, y: y - h * 0.4 - lr, width: 2 * lr, height: 2 * lr)) }
                    }
                }
            }
        }
        eyeFillLayer.path = ef; eyeLineLayer.path = el; eyeLightLayer.path = eli

        CATransaction.commit()
    }
}
