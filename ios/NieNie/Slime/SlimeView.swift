import UIKit

/// Draws the slime and reads raw touches. A CADisplayLink (up to 120Hz) steps the rig
/// with fixed small substeps, then redraws a handful of CAShapeLayers.
final class SlimeView: UIView {
    let rig: SlimeRig
    var colors: SlimeColors { didSet { applyColors(animated: !rig.reduceMotion) } }
    var kind: SlimeKind = .honey { didSet { tintKey = .min } }   // v2.57: its signature (purple, fog), its own skin, the new six's look switch
    /// v2.59 窗景: the scene outside the window, "" = the original one
    var winId = "" {
        didSet {
            guard winId != oldValue else { return }
            winFailSaid = ""
            windows?.forgetFailures()
        }
    }
    /// The picked window could not be loaded; the original one stays
    var onWindowFail: (() -> Void)?
    private var windows: WindowRenderer?      // made the first time a window is picked
    private var windowsTried = false
    private var winShown: WindowStage?        // what is drawn now (the last one, while the next one loads)
    private var winFailSaid = ""
    /// Fires once per frame, after the rig stepped, so sound/haptics read the same state as the picture.
    var onFrame: ((_ dt: Double) -> Void)?
    var usePredictedTouches = true

    /// Readout for the hidden panel, refreshed twice a second (Domi has no Mac, so no Instruments).
    struct FrameStats {
        var hz = 0.0            // frames actually drawn per second
        var maxFrameMs = 0.0    // longest frame in the last second
        var dropped = 0         // frames longer than 1.5× the display's frame interval, last second
        var workMs = 0.0        // physics + sound/haptics + drawing on the main thread, average, last second
        var physMs = 0.0        // v2.52 A5: the physics alone (rig.update), average, last second
        var physMaxMs = 0.0     // ...and its longest frame
        var decoMs = 0.0        // v2.52 C3: drawing the moving things into the room behind the body, average, last second
        var touchRadius = 0.0   // UITouch.majorRadius of the finger down, points
    }
    var onStats: ((FrameStats) -> Void)?
    /// Latency test (3-4 做法三): the whole screen flashes white for exactly one frame when a finger lands, so
    /// 240fps slow motion can count "finger touches → flash" (input to display) and "→ spread" (with physics).
    var latencyTest = false
    private let flashLayer = CALayer()
    private var flashFrames = 0
    private var frameLog: [(time: CFTimeInterval, dt: Double, work: Double, phys: Double, deco: Double, dropped: Bool)] = []
    // v2.52 量測 (《虛擬手感》3-2 灰盒與純圓, 3-5 C4): set from the feel desk's 量測 group, never saved
    /// 灰盒: one flat grey, no eyes, no shadow, the things from its walks put away. The rig's numbers are grey-boxed by the controller (FeelParams.greyBox).
    var labGrey = false { didSet { if labGrey != oldValue { applyColors() } } }
    /// 純圓: a 2 cm disc whose centre is the finger, nothing handed to the body. Dragged along a ruler it shows the system's own lag (跟手基準的 C).
    var labCircle = false { didSet { if !labCircle { circleLayer.isHidden = true } } }
    /// 圖層: the skin's layers switched off one at a time, to read each one's cost off the frame readout
    var labLayersOff: Set<String> = [] { didSet { tintKey = .min } }
    private let circleLayer = CAShapeLayer()
    private let gooFlatLayer = CAShapeLayer()   // the strand and the small blob for the flat skin (the jelly skin takes them into its mask)
    private var thinK = 0.0                     // C1 細絲: the rounding's shrink, eased
    private var frameDt = 1.0 / 60              // this frame's length, for that easing
    private var bellImage: CGImage?, teruImage: CGImage?   // C3: the two hanging things, to draw into what is seen through the body
    private var backSprites: [SlimeRig.WalkSprite] = []    // ...and what it brought back, as placed this frame
    private var decoCost = 0.0                             // seconds spent this frame drawing them into the room behind the body
    private static let greyColors = SlimeColors(base: UIColor(hex: 0x8D949B), shade: UIColor(hex: 0x8D949B), line: UIColor(hex: 0x8D949B), light: UIColor(hex: 0x8D949B), eye: UIColor(hex: 0x8D949B))
    private var lastStatsTime: CFTimeInterval = 0

    private var link: CADisplayLink?
    // 提案第 35 條: 120Hz only while a finger is down (and for a second after); 60Hz idle so a three-minute toy does not heat up
    private var touchesDown = 0
    private var lastTouchEnd: CFTimeInterval = -10
    private var frameRate: Float = 0
    private var rateLocked = false   // v2.61 B7 碰著時固定 120: what the link was last asked for
    private var bandMode = false   // 候選 34: outline drawn as a filled band of varying width
    private var lastTimestamp: CFTimeInterval = 0
    private var laidOutSize: CGSize = .zero

    private let skyLayer = CAGradientLayer()
    // v2.28 窗台: the room baked into pictures (sky; the wall with the window; the dish, the plant and the bowl) placed behind or in front of the body by plane,
    // the bowl's front half over it while it sits inside; 走路: the small things on the sill and the one stuck to it
    private let skyImgLayer = CALayer(), wallLayer = CALayer(), propsLayer = CALayer(), bowlFrontLayer = CALayer()
    private let bellLayer = CALayer(), teruLayer = CALayer()   // v2.37 擺飾: hanging from the frame, turned about their top
    // v2.64 擺飾變真: the candle and the right-end thing drawn where they are (each its shadow on the sill), the lit candle's glow
    private let propImgLayers = [CALayer(), CALayer()], propShadowLayers = [CALayer(), CALayer()], propGlowLayer = CALayer()
    private var propImgs: [CGImage?] = [nil, nil]   // what each prop layer shows now, for the see-through skin
    private let itemsGroup = CALayer(), stuckGroup = CALayer()
    // v2.31 搖晃沉澱: inside the body (in litGroup, under the eyes) the haze, the glitter by colour, the glow; the halo outside
    private let fogLayer = CAGradientLayer(), glowLayer = CAGradientLayer(), haloLayer = CAGradientLayer()
    // v2.28 果凍皮: the body as a lit jelly on Metal, under litGroup (the glitter and the eyes stay Core Animation); the blush with it
    private let jelly = JellySkin()
    // v2.61 A1 網格聯集的皮: where the triangles come from (nil until SlimeRig hands them out), this frame's points, and the path the eyes and the filling are cut to
    private let skinSrc: SkinMeshSource?
    private let skinMesh = SkinMesh()
    private var litPath: CGPath?
    private let blushLayers = [CAGradientLayer(), CAGradientLayer()]
    // v2.57 新六隻的招牌 (web drawFx): on the jelly skin, under the blush and the eyes, clipped to the body by litGroup
    private let fxGroup = CALayer()
    private let fxStainLayers = (0..<6).map { _ in CAGradientLayer() }, fxCoreLayers = (0..<22).map { _ in CAGradientLayer() }
    private let fxCoreSoftGroup = CALayer(), fxCoreSoftLayers = (0..<14).map { _ in CAGradientLayer() }   // v2.61b coreSoft: solid round spots with soft edges, the group at 0.3 (web: a blurred union at 0.3)
    private let fxPearlLayer = CAShapeLayer(), fxPearlLitLayer = CAShapeLayer(), fxCapGrad = CAGradientLayer(), fxCapMask = CAShapeLayer()
    private let bubbleRing = CAShapeLayer(), bubbleDot = CAShapeLayer(), causticShade = CAGradientLayer(), causticLight = CAGradientLayer()   // v2.49 water: bubbles inside it, gathered light under it
    private let glitLayers = [CAShapeLayer(), CAShapeLayer(), CAShapeLayer(), CAShapeLayer()]
    private let glitColors: [UIColor] = [UIColor(red: 1, green: 224 / 255, blue: 138 / 255, alpha: 1), .white, UIColor(red: 1, green: 195 / 255, blue: 214 / 255, alpha: 1), UIColor(red: 190 / 255, green: 240 / 255, blue: 230 / 255, alpha: 1)]
    private var itemLayers: [CALayer] = [], stuckLayers: [CALayer] = []
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
    // v2.64 B9 果凍皮上的揉的痕跡（rubTrail；網頁 drawRubTrail）：每幀把痕跡那一塊畫成一張圖，放在 litGroup 裡（跟招牌、腮紅、眼睛同一組，用皮的遮罩剪）
    private let rubTrailLayer = CALayer()
    private var rubTrailShown = false
    private var dentImage: CGImage?
    private let dentUnit: CGFloat = 40           // the pit image is drawn for this radius (points)
    private let highlightLayer = CAShapeLayer()
    private let outlineLayer = CAShapeLayer()
    private var tintKey = -1   // v2.22 E3: the impression tint last applied (rounded), −1 = plain colours
    private let eyeFillLayer = CAShapeLayer()    // v2.23 eyes, inside the body: open eyes...
    private let eyeLightLayer = CAShapeLayer()   // ...their white glints...
    private let eyeLineLayer = CAShapeLayer()    // ...and the ∩ ∪ > < and shut ones as strokes
    // v2.62 the second slime (web twinFace): its flat body's lit part and its blush, clipped to its outline; the lump while it is swallowed; its eyes (not clipped, as on the web);
    // the ripple inside the first one (in litGroup, clipped to it)
    private let twinGroup = CALayer(), twinMask = CAShapeLayer(), twinBaseLayer = CAShapeLayer(), twinBulge = CAShapeLayer()
    private let twinBlush = [CAGradientLayer(), CAGradientLayer()], twinRings = [CAShapeLayer(), CAShapeLayer()]
    private let twinEyeFill = CAShapeLayer(), twinEyeLight = CAShapeLayer(), twinEyeLine = CAShapeLayer()
    private var twinNow: SlimeRig.TwinView?

    /// Touches starting this close to the top/bottom edge are left to the system gestures.
    private let edgeBand: CGFloat = 32

    init(rig: SlimeRig, colors: SlimeColors) {
        self.rig = rig
        self.colors = colors
        skinSrc = (rig as AnyObject) as? SkinMeshSource   // v2.61 A1
        super.init(frame: .zero)
        isMultipleTouchEnabled = true
        isOpaque = true
        backgroundColor = UIColor(hex: 0xCDEBFA)

        skyLayer.colors = [UIColor(hex: 0xCDEBFA).cgColor, UIColor(hex: 0xE6F5FD).cgColor]
        skyLayer.startPoint = CGPoint(x: 0.5, y: 0)
        skyLayer.endPoint = CGPoint(x: 0.5, y: 1)
        layer.addSublayer(skyLayer)
        skyLayer.zPosition = -5
        for l in [skyImgLayer, wallLayer, propsLayer, itemsGroup] { l.contentsGravity = .resize; l.isHidden = true; layer.addSublayer(l) }
        for (n, l) in speckLayers.enumerated() {
            l.fillColor = UIColor.white.cgColor
            l.opacity = n == 0 ? 0.4 : 0.7
            layer.addSublayer(l)
        }
        shadowLayer.fillColor = UIColor(red: 60 / 255, green: 90 / 255, blue: 40 / 255, alpha: 0.18).cgColor
        layer.addSublayer(shadowLayer)
        layer.addSublayer(shadeLayer)
        gooFlatLayer.isHidden = true
        layer.addSublayer(gooFlatLayer)
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
        for l in [fogLayer, glowLayer, haloLayer] { l.type = .radial; l.startPoint = CGPoint(x: 0.5, y: 0.5); l.endPoint = CGPoint(x: 1, y: 1); l.isHidden = true }
        if let j = jelly { j.layer.zPosition = -0.5; j.layer.isHidden = true; layer.addSublayer(j.layer) }
        for l in [causticShade, causticLight] { l.type = .radial; l.startPoint = CGPoint(x: 0.5, y: 0.5); l.endPoint = CGPoint(x: 1, y: 1); l.zPosition = -0.6; l.isHidden = true; layer.addSublayer(l) }
        causticShade.colors = [UIColor(red: 70 / 255, green: 60 / 255, blue: 50 / 255, alpha: 0.16).cgColor, UIColor(red: 70 / 255, green: 60 / 255, blue: 50 / 255, alpha: 0).cgColor]
        causticLight.colors = [UIColor(red: 1, green: 252 / 255, blue: 240 / 255, alpha: 0.75).cgColor, UIColor(red: 1, green: 250 / 255, blue: 235 / 255, alpha: 0.35).cgColor, UIColor(red: 1, green: 250 / 255, blue: 235 / 255, alpha: 0).cgColor]
        causticLight.locations = [0, 0.5, 1]
        bubbleRing.fillColor = UIColor(white: 1, alpha: 0.10).cgColor; bubbleRing.strokeColor = UIColor(white: 1, alpha: 0.62).cgColor
        bubbleDot.fillColor = UIColor(white: 1, alpha: 0.9).cgColor; bubbleDot.strokeColor = nil
        for l in [bubbleRing, bubbleDot] { l.zPosition = -0.4; l.isHidden = true; layer.addSublayer(l) }
        litGroup.addSublayer(fxGroup); fxGroup.isHidden = true   // v2.57, under the blush
        rubTrailLayer.isHidden = true; rubTrailLayer.contentsGravity = .resize; litGroup.addSublayer(rubTrailLayer)   // v2.64 B9：在招牌上面、腮紅和眼睛下面（網頁 inBody：drawFx 之後、drawBlush 之前）
        for l in fxStainLayers + fxCoreLayers { l.type = .radial; l.startPoint = CGPoint(x: 0.5, y: 0.5); l.endPoint = CGPoint(x: 1, y: 1); l.isHidden = true; fxGroup.addSublayer(l) }
        fxCoreSoftGroup.opacity = 0.3; fxCoreSoftGroup.allowsGroupOpacity = true; fxCoreSoftGroup.isHidden = true; fxGroup.addSublayer(fxCoreSoftGroup)
        for l in fxCoreSoftLayers { l.type = .radial; l.startPoint = CGPoint(x: 0.5, y: 0.5); l.endPoint = CGPoint(x: 1, y: 1); l.isHidden = true; fxCoreSoftGroup.addSublayer(l) }
        fxCapGrad.mask = fxCapMask; fxCapGrad.startPoint = CGPoint(x: 0.5, y: 0); fxCapGrad.endPoint = CGPoint(x: 0.5, y: 1); fxCapGrad.isHidden = true; fxGroup.addSublayer(fxCapGrad)
        fxPearlLayer.fillColor = UIColor(red: 43 / 255, green: 27 / 255, blue: 20 / 255, alpha: 0.92).cgColor; fxPearlLitLayer.fillColor = UIColor(red: 98 / 255, green: 64 / 255, blue: 46 / 255, alpha: 0.5).cgColor   // no white glint (多米 11-22): a lighter brown makes it round
        fxGroup.addSublayer(fxPearlLayer); fxGroup.addSublayer(fxPearlLitLayer)
        for l in blushLayers { l.type = .radial; l.startPoint = CGPoint(x: 0.5, y: 0.5); l.endPoint = CGPoint(x: 1, y: 1); l.isHidden = true; litGroup.addSublayer(l) }
        litGroup.addSublayer(fogLayer)
        for (k, l) in glitLayers.enumerated() { l.fillColor = glitColors[k].cgColor; litGroup.addSublayer(l) }
        litGroup.addSublayer(glowLayer)
        haloLayer.zPosition = 0.5
        layer.addSublayer(haloLayer)
        eyeLightLayer.fillColor = UIColor.white.cgColor
        eyeLineLayer.fillColor = nil; eyeLineLayer.lineCap = .round; eyeLineLayer.lineJoin = .round
        litGroup.addSublayer(eyeFillLayer); litGroup.addSublayer(eyeLightLayer); litGroup.addSublayer(eyeLineLayer)
        outlineLayer.fillColor = nil
        outlineLayer.lineJoin = .round
        layer.addSublayer(outlineLayer)
        for l in twinRings { l.fillColor = nil; l.isHidden = true; litGroup.addSublayer(l) }   // v2.62, over the first one's eyes
        twinGroup.mask = twinMask; twinGroup.isHidden = true
        twinBaseLayer.isHidden = true; twinGroup.addSublayer(twinBaseLayer)
        for l in twinBlush { l.type = .radial; l.startPoint = CGPoint(x: 0.5, y: 0.5); l.endPoint = CGPoint(x: 1, y: 1); l.isHidden = true; twinGroup.addSublayer(l) }
        layer.addSublayer(twinGroup)
        twinBulge.fillColor = nil; twinBulge.isHidden = true
        layer.addSublayer(twinBulge)
        twinEyeLight.fillColor = UIColor.white.cgColor
        twinEyeLine.fillColor = nil; twinEyeLine.lineCap = .round; twinEyeLine.lineJoin = .round
        layer.addSublayer(twinEyeFill); layer.addSublayer(twinEyeLight); layer.addSublayer(twinEyeLine)
        stuckGroup.isHidden = true; stuckGroup.zPosition = 1
        layer.addSublayer(stuckGroup)   // 走路: the thing stuck to it, over the body
        bowlFrontLayer.contentsGravity = .resize; bowlFrontLayer.isHidden = true; bowlFrontLayer.zPosition = 4
        for l in [bellLayer, teruLayer] { l.contentsGravity = .resize; l.anchorPoint = CGPoint(x: 0.5, y: 0); l.isHidden = true; layer.addSublayer(l) }
        for l in propShadowLayers + propImgLayers + [propGlowLayer] { l.contentsGravity = .resize; l.isHidden = true; layer.addSublayer(l) }   // v2.64
        propGlowLayer.compositingFilter = "screenBlendMode"   // the web adds the glow ('lighter'); where Core Animation has no such filter it is a plain blend
        layer.addSublayer(bowlFrontLayer)   // v2.28 窗台: in front of the body and the eyes
        flashLayer.backgroundColor = UIColor.white.cgColor
        flashLayer.isHidden = true
        layer.addSublayer(flashLayer)
        circleLayer.fillColor = UIColor(red: 20 / 255, green: 24 / 255, blue: 28 / 255, alpha: 0.85).cgColor
        circleLayer.path = CGPath(ellipseIn: CGRect(x: -62, y: -62, width: 124, height: 124), transform: nil)   // 2 cm across at 163 points an inch
        circleLayer.zPosition = 5; circleLayer.isHidden = true
        layer.addSublayer(circleLayer)
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
        rig.winMover = { [weak self] gx, gy, gw, gh, minV in self?.winMover(gx, gy, gw, gh, minV) }   // v2.64 C5 張望有對象
    }

    /// v2.64 C5 張望有對象（網頁 ltWin）：窗景裡這一刻正在動、在窗洞裡、每秒移動 minV 以上的那幾層，挑「速度 × 透明度」最大那層，回它的中心。
    /// 中心 = 那層的框（還沒套動畫前）的中心，套上設計單位 → 窗洞的縮放和那層這一刻的動畫；速度取前後兩段 0.2 秒裡慢的那段（飄完從頭再來那一跳不算）。
    /// 只看現在選的那扇（還在載入、先畫上一扇時不算）；虛線（瀑布）、不會動的、透明度不到 0.3 的不算。減少動態由牠那邊擋
    private func winMover(_ gx: Double, _ gy: Double, _ gw: Double, _ gh: Double, _ minV: Double) -> (i: Int, x: Double, y: Double)? {
        guard let st = winShown, st.def.id == winId, let r = windows, let lib = WindowLibrary.shared, lib.w > 0, lib.h > 0, gw > 0, gh > 0 else { return nil }
        let T: Double = r.clock
        let base = WindowAff(a: gw / lib.w, b: 0, c: 0, d: gh / lib.h, e: gx, f: gy)
        func at(_ it: WindowItem, _ T: Double) -> (x: Double, y: Double) {
            var m = base
            for o in it.ops { m = m.times(o.at(T)) }
            return m.apply(it.box[0] + it.box[2] / 2, it.box[1] + it.box[3] / 2)
        }
        var best: (i: Int, x: Double, y: Double, v: Double)? = nil
        for (i, it) in st.items.enumerated() {
            guard it.dash == nil, it.box.count >= 4 else { continue }
            let moving: Bool = it.ops.contains { op in
                if case .fixed = op { return false }
                return true
            }
            guard moving else { continue }
            var al: Double = 1
            for a in it.alphas { al *= a.at(T) }
            if !(al >= 0.3) { continue }
            let p = at(it, T)
            if !(p.x >= gx && p.x <= gx + gw && p.y >= gy && p.y <= gy + gh) { continue }
            let p1 = at(it, T - 0.2), p2 = at(it, T - 0.4)
            let sp: Double = min(hypot(p.x - p1.x, p.y - p1.y), hypot(p1.x - p2.x, p1.y - p2.y)) / 0.2
            if !(sp >= minV) { continue }
            let v: Double = sp * al
            if let b = best, !(v > b.v) { continue }
            best = (i: i, x: p.x, y: p.y, v: v)
        }
        guard let b = best else { return nil }
        return (i: b.i, x: b.x, y: b.y)
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
        let colors = labGrey ? Self.greyColors : self.colors   // v2.52 灰盒
        gooFlatLayer.fillColor = colors.shade.cgColor
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
        twinBaseLayer.fillColor = colors.base.cgColor; twinEyeFill.fillColor = colors.eye.cgColor; twinEyeLine.strokeColor = colors.eye.cgColor   // v2.62
        tintKey = -1
        CATransaction.commit()
    }

    /// v2.22 E3: trusting leans warm, wary leans pale, inside the same two flat colours (the style stays).
    private func tinted(_ c: UIColor, _ tr: Double, _ w: Double, shade: Bool = false) -> UIColor {
        if labLayersOff.contains("mood") { return c }   // v2.52 C4
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        c.getRed(&r, green: &g, blue: &b, alpha: &a)
        var rr = min(255, Double(r) * 255 + 22 * tr), gg = min(255, Double(g) * 255 + 4 * tr), bb = max(0, Double(b) * 255 - 18 * tr)
        let fx = kind.fx
        if let pp = fx.purple {   // v2.57 蝶豆: trusting leans purple, not warm
            let k = 0.62 * tr, q: Double = shade ? 0.8 : 1
            rr = Double(r) * 255; gg = Double(g) * 255; bb = Double(b) * 255
            rr += (pp.0 * q - rr) * k; gg += (pp.1 * q - gg) * k; bb += (pp.2 * q - bb) * k
        }
        rr += (255 - rr) * 0.22 * w; gg += (255 - gg) * 0.22 * w; bb += (255 - bb) * 0.22 * w
        // v2.27 mood colour: towards the mood's colour, by the same share for every slime
        let mC: Double = rig.mcC, mS: Double = rig.mcS, mW: Double = rig.mcW, mZ: Double = rig.mcZ, sum: Double = mC + mS + mW + mZ, A: Double = rig.params.moodColor
        if A > 0 && sum > 0.002 {
            let k: Double = A * sum / max(1, sum), sh: Double = shade ? 0.82 : 1
            let cc: (Double, Double, Double) = fx.purple ?? (255, 154, 139)   // v2.57 蝶豆: happy is purple too
            let mr: Double = (mC * cc.0 + mS * 240 + mW * 141 + mZ * 108) / sum * sh
            let mg: Double = (mC * cc.1 + mS * 68 + mW * 166 + mZ * 120) / sum * sh
            let mb: Double = (mC * cc.2 + mS * 79 + mW * 217 + mZ * 184) / sum * sh
            rr += (mr - rr) * k; gg += (mg - gg) * k; bb += (mb - bb) * k
        }
        if let fg = fx.fog, rig.fogCloud > 0.001 {   // v2.57 汽水: shaken, the whole body leans misty white by the haze, clearing as it settles
            let k = min(1, rig.fogCloud) * 0.88, q: Double = shade ? 0.9 : 1
            rr += (fg.0 * q - rr) * k; gg += (fg.1 * q - gg) * k; bb += (fg.2 * q - bb) * k
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
            rateLocked = false
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
            for l in [skyImgLayer, wallLayer, propsLayer, itemsGroup, stuckGroup] { l.frame = bounds }
            if let j = jelly { j.layer.frame = bounds; j.resize(width: Int(size.width.rounded()), height: Int(size.height.rounded()), scale: window?.screen.scale ?? UIScreen.main.scale) }
            sceneKey = ""
            for l in ([shadowLayer, shadeLayer, litGroup, litMask, baseLayer, dentShadeLayer, dentLitLayer, highlightLayer, outlineLayer, flashLayer,
                       eyeFillLayer, eyeLightLayer, eyeLineLayer, twinGroup, twinMask, twinBaseLayer, twinBulge, twinEyeFill, twinEyeLight, twinEyeLine] as [CALayer])
                      + (speckLayers as [CALayer]) + (trailLayers as [CALayer]) + (twinRings as [CALayer]) {
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

    /// v2.52 純圓: the disc goes to the newest sample at once, in the touch handler itself (no physics, no smoothing, no prediction)
    private func circleFollow(_ touches: Set<UITouch>, with event: UIEvent?, down: Bool) {
        guard let t = touches.first else { return }
        let p = (event?.coalescedTouches(for: t)?.last ?? t).location(in: self)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        circleLayer.position = p
        circleLayer.isHidden = !down
        CATransaction.commit()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if LabProbe.shared.on, let t = touches.first { LabProbe.shared.begin(touch: t.timestamp) }   // v2.61 B7
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
        if labCircle { circleFollow(touches, with: event, down: true); return }
        for t in touches {
            let p = t.location(in: self)
            let fmax = Double(t.maximumPossibleForce)   // v2.63 B2: 3D Touch; 0 where there is none (then the rig reads majorRadius)
            let force: Double = fmax > 0 && t.force > 0 ? min(1, Double(t.force) / fmax) : -1
            rig.touchBegan(ObjectIdentifier(t), x: Double(p.x), y: Double(p.y), time: t.timestamp,
                           allowed: touchAllowed(p), radius: Double(t.majorRadius), force: force)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if labCircle { circleFollow(touches, with: event, down: true); return }
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
        if labCircle { circleFollow(touches, with: event, down: false) }
        for t in touches { rig.touchEnded(ObjectIdentifier(t), time: t.timestamp) }
        touchesDown = max(0, touchesDown - touches.count)
        lastTouchEnd = CACurrentMediaTime()
    }

    /// The system took the touch (edge gesture, call, app switch): let go without the release pop.
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if labCircle { circleFollow(touches, with: event, down: false) }
        for t in touches { rig.touchCancelled(ObjectIdentifier(t)) }
        touchesDown = max(0, touchesDown - touches.count)
        lastTouchEnd = CACurrentMediaTime()
    }

    /// 提案第 35 條. The latency test keeps 120Hz so the slow-motion count measures the 120Hz pipeline; from idle the
    /// first frame after a touch can be one 60Hz frame (up to 8 ms) later, which the panel's Hz readout also shows.
    private func setFrameRate(_ hz: Float) {
        // v2.61 B7, off unless the desk's 固定 120 is on: the three the same while a finger is down (Apple: for measuring; low power mode takes 120 away anyway)
        let lock: Bool = hz >= 120 && touchesDown > 0 && LabProbe.shared.lock120 && (window?.screen.maximumFramesPerSecond ?? 60) >= 120
        guard hz != frameRate || lock != rateLocked, let l = link else { return }
        frameRate = hz
        rateLocked = lock
        let low: Float = lock ? 120 : 60
        l.preferredFrameRateRange = hz >= 120
            ? CAFrameRateRange(minimum: low, maximum: 120, preferred: 120)
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
        frameDt = dt
        let t0 = CACurrentMediaTime()
        rig.update(dt)
        let phys = CACurrentMediaTime() - t0
        onFrame?(dt)
        redraw()
        let work = CACurrentMediaTime() - t0
        if LabProbe.shared.on {   // v2.61 B7, A7
            LabProbe.shared.frame(start: t0, end: t0 + work, target: link.targetTimestamp)
            LabProbe.shared.skinTick()
        }
        // frame readout over a one-second window
        frameLog.append((time: now, dt: dt, work: work, phys: phys, deco: decoCost, dropped: dt > nominal * 1.5))
        while let first = frameLog.first, now - first.time > 1 { frameLog.removeFirst() }
        if now - lastStatsTime > 0.5, let onStats, let first = frameLog.first {
            lastStatsTime = now
            var s = FrameStats()
            s.hz = Double(frameLog.count) / max(0.1, now - first.time + dt)
            s.maxFrameMs = (frameLog.map { $0.dt }.max() ?? 0) * 1000
            s.dropped = frameLog.filter { $0.dropped }.count
            s.workMs = frameLog.map { $0.work }.reduce(0, +) / Double(frameLog.count) * 1000
            s.physMs = frameLog.map { $0.phys }.reduce(0, +) / Double(frameLog.count) * 1000
            s.physMaxMs = (frameLog.map { $0.phys }.max() ?? 0) * 1000
            s.decoMs = frameLog.map { $0.deco }.reduce(0, +) / Double(frameLog.count) * 1000
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

    /// v2.28 窗台: the baked room behind it (or, behind the bowl and outside, in front of it), the bowl's front half over it while it sits inside;
    /// 走路: the small things. The blue sky and the specks only while floating.
    private func updateScene() {
        let kind = rig.sceneKind
        let all: [CALayer] = [skyImgLayer, wallLayer, propsLayer, itemsGroup, stuckGroup, bowlFrontLayer, bellLayer, teruLayer]
        let dyn: [CALayer] = propShadowLayers + propImgLayers + [propGlowLayer]   // v2.64: shown only while there are things to draw
        guard kind > 0, let g = rig.sillG, bounds.width > 0, bounds.height > 0 else {
            for l in all + dyn { l.isHidden = true }
            windowHide()
            skyLayer.isHidden = false
            for l in speckLayers { l.isHidden = false }
            jelly?.setBackground(key: "none", images: [])   // v2.49: no room behind it, so no water skin (the v2.48 one)
            return
        }
        let p = rig.params, decoLv = Int(p.deco.rounded())
        // v2.59 窗景: what is outside the window, and the colour it gives the wall by day
        let stage: WindowStage? = windowStage(night: kind == 2)
        var tint: UIColor?
        if let st = stage, kind == 1, !st.night { tint = st.def.dayColor }
        let winTag: String = stage == nil ? "" : "|win" + (tint == nil ? "" : (stage?.def.id ?? ""))
        let real = rig.dreal   // v2.64 擺飾變真: the candle and the right end are not in the picture
        let key = "\(kind)|\(Int(bounds.width))|\(Int(bounds.height))|\(rig.noBowl)|\(p.props >= 0.5)|\(decoLv)|\(real)" + winTag
        if key != sceneKey {
            guard let imgs = SceneArt.make(kind: kind, size: bounds.size, g: g, bowl: !rig.noBowl, props: p.props >= 0.5, deco: decoLv, real: real) else {   // pictures missing: the plain sky, nothing else (the physics still has the sill)
                for l in all + dyn { l.isHidden = true }
                windowHide()
                skyLayer.isHidden = false
                return
            }
            sceneKey = key
            var wall: UIImage = imgs.wall
            if let t = tint { wall = SceneArt.tintedWall(imgs.wall, tint: t, key: key) }
            skyImgLayer.contents = imgs.sky.cgImage; wallLayer.contents = wall.cgImage; propsLayer.contents = imgs.props.cgImage
            var behind: [CGImage?] = [wall.cgImage, imgs.props.cgImage]
            if stage == nil { behind.insert(imgs.sky.cgImage, at: 0) }
            jelly?.setBackground(key: key, images: behind.compactMap { $0 }, clear: stage != nil)   // v2.49: the room behind it, for the water skin to bend
            bowlFrontLayer.contents = imgs.bowlFront.cgImage
            bowlFrontLayer.frame = CGRect(x: g.bx - g.bw / 2, y: g.by, width: g.bw, height: g.bh)
            bellImage = imgs.bell?.cgImage; teruImage = imgs.teru?.cgImage
            for (l, im, x, w0) in [(bellLayer, imgs.bell, g.jr - 46 * g.U, 50.0), (teruLayer, imgs.teru, g.gx + 46 * g.U, 54.0)] {
                l.contents = im?.cgImage
                guard let im else { continue }
                let w = w0 * g.U, h = w * Double(im.size.height / im.size.width)
                l.setAffineTransform(.identity)
                l.bounds = CGRect(x: 0, y: 0, width: w, height: h)
                l.position = CGPoint(x: x, y: g.gy)
            }
        }
        skyLayer.isHidden = true
        for l in speckLayers { l.isHidden = true }
        for l in all { l.isHidden = false }
        if let st = stage, let r = windows {
            r.place(CGRect(x: g.gx, y: g.gy, width: g.gw, height: g.gh), scale: window?.screen.scale ?? UIScreen.main.scale)
            r.layer.isHidden = false
            r.draw(st, still: rig.reduceMotion)
            skyImgLayer.isHidden = r.settled   // until the layer has its first pictures the original sky stays behind it
            jelly?.windowOn = true
        } else { windowHide() }
        // who is in front: on the sill the room is behind it; behind the bowl the bowl and the things are in front; outside the wall is too (it shows through the window only)
        let plane = rig.sillPlane
        skyImgLayer.zPosition = -4
        wallLayer.zPosition = plane == .out ? 2 : -3
        propsLayer.zPosition = plane == .room ? -2 : 3
        itemsGroup.zPosition = plane == .room ? -1 : 3.5
        bowlFrontLayer.isHidden = !(rig.sillInBowl && plane == .room) || rig.noBowl
        // v2.37: the hanging two sit with the props (behind it on the sill, in front of it on the frame or outside); the bell swings after a shake
        bellLayer.isHidden = bellLayer.contents == nil; teruLayer.isHidden = teruLayer.contents == nil
        bellLayer.zPosition = propsLayer.zPosition; teruLayer.zPosition = propsLayer.zPosition
        bellLayer.setAffineTransform(CGAffineTransform(rotationAngle: rig.hangAngle("bell", amp: 0.22)))   // v2.64: the pendulum while decoReal is on
        teruLayer.setAffineTransform(CGAffineTransform(rotationAngle: rig.hangAngle("teru", amp: 0.06)))
        let night = kind == 2
        // v2.64 擺飾變真 (web drawProps): each thing turned about its centre of mass, its shadow on the sill, the lit candle's glow; with the props (behind it on the sill)
        let pv = rig.propViews, zp = propsLayer.zPosition
        var glow = false
        for k in 0..<2 {
            let il = propImgLayers[k], sl = propShadowLayers[k]
            guard k < pv.count else { il.isHidden = true; sl.isHidden = true; propImgs[k] = nil; continue }
            let v = pv[k]
            let im = (v.lit ? SceneArt.decoImage("candleLit", night: true) : nil) ?? SceneArt.decoImage(v.im, night: night)
            let cg = im?.cgImage
            il.contents = cg
            propImgs[k] = cg
            il.isHidden = cg == nil; il.zPosition = zp + 0.5
            il.setAffineTransform(.identity)
            il.bounds = CGRect(x: 0, y: 0, width: v.w, height: v.h)
            il.anchorPoint = CGPoint(x: v.w > 0 ? v.ox / v.w : 0.5, y: v.h > 0 ? v.oy / v.h : 0.5)
            il.position = CGPoint(x: v.x, y: v.y)
            il.setAffineTransform(CGAffineTransform(rotationAngle: v.a))
            il.opacity = Float(v.alpha)
            if v.shadow > 0 {
                let rx = v.w * 0.52 * (1 + 0.3 * abs(sin(v.a))), ry = 11 * g.U
                if sl.contents == nil { sl.contents = SceneArt.propShadowImage().cgImage }
                sl.isHidden = false; sl.zPosition = zp + 0.2
                sl.frame = CGRect(x: v.x - rx, y: g.fl - 2 - ry, width: 2 * rx, height: 2 * ry)
                sl.opacity = Float(v.shadow)
            } else { sl.isHidden = true }
            if v.lit {
                glow = true
                let c = cos(v.a), sn = sin(v.a), fy = -v.oy + v.h * 0.22, r = 150 * g.U * v.alpha
                if propGlowLayer.contents == nil { propGlowLayer.contents = SceneArt.glowImage().cgImage }
                propGlowLayer.zPosition = zp + 0.6
                propGlowLayer.frame = CGRect(x: v.x - sn * fy - r, y: v.y + c * fy - r, width: 2 * r, height: 2 * r)
            }
        }
        propGlowLayer.isHidden = !glow
        backSprites = rig.walkBackSprites
        place(backSprites, in: &itemLayers, group: itemsGroup, world: false, night: night)
        place(rig.walkWorldSprites, in: &stuckLayers, group: stuckGroup, world: true, night: night)
        if labGrey { itemsGroup.isHidden = true; stuckGroup.isHidden = true }   // v2.52 灰盒: only the room stays
    }
    /// v2.59 窗景: the stage to draw; nil = the original window (none picked, the first one still loading, or it could not be loaded)
    private func windowStage(night: Bool) -> WindowStage? {
        guard let d = WindowLibrary.def(winId) else {
            if winShown != nil { winShown = nil }
            windows?.clear()
            return nil
        }
        if !windowsTried {
            windowsTried = true
            if let j = jelly, let r = WindowRenderer(device: j.device, queue: j.queue) {
                r.layer.zPosition = -4   // the sky picture's place, over it
                layer.insertSublayer(r.layer, above: skyImgLayer)
                windows = r
                j.windows = r
            }
        }
        guard let r = windows else { windowFail("no Metal"); return nil }
        switch r.request(d, night: night) {
        case .ready(let s): winShown = s
        case .waiting: break   // the last one stays meanwhile
        case .failed(let why):
            winShown = nil
            windowFail(why)
        }
        return winShown
    }
    private func windowFail(_ why: String) {
        guard winFailSaid != winId else { return }
        winFailSaid = winId
        NSLog("[windows] reason: %@", why as NSString)
        DispatchQueue.main.async { [weak self] in self?.onWindowFail?() }
    }
    private func windowHide() {
        jelly?.windowOn = false
        if let r = windows, !r.layer.isHidden { r.layer.isHidden = true }
    }
    private func place(_ sprites: [SlimeRig.WalkSprite], in pool: inout [CALayer], group: CALayer, world: Bool, night: Bool) {
        while pool.count < sprites.count && pool.count < 16 {
            let l = CALayer(); l.contentsGravity = .resize; l.contentsScale = 2
            group.addSublayer(l); pool.append(l)
        }
        let z: Double = world ? rig.drawZ : 1
        for (k, l) in pool.enumerated() {
            guard k < sprites.count else { l.isHidden = true; continue }
            let sp = sprites[k], sz: Double = (sp.big ? 30 : 22) * 1.05 * z
            let c: (x: Double, y: Double) = world ? rig.toScreen(sp.x, sp.y) : (sp.x, sp.y)
            l.isHidden = false
            l.contents = SceneArt.sprite(sp.kind, night: night).cgImage
            l.bounds = CGRect(x: 0, y: 0, width: sz, height: sz)
            l.position = CGPoint(x: c.x, y: c.y)
            l.setAffineTransform(CGAffineTransform(rotationAngle: sp.a))
            l.opacity = Float(sp.alpha)
        }
    }

    private var jellyOn: Bool { jelly != nil && rig.params.skin >= 0.5 }
    /// v2.49 看得出是水: the bubbles inside it and the gathered light under it (web: drawBubbles, drawCaustic). Core Animation layers, no implicit animation (the caller's transaction turns it off).
    private func drawWater(body: CGPath, z: Double) {
        let p = rig.params, on = p.water > 0 && p.wet >= 0.5
        let bubs = on && !labLayersOff.contains("bubbles") ? rig.bubbleView : []
        if bubs.isEmpty { bubbleRing.isHidden = true; bubbleDot.isHidden = true } else {
            let ring = CGMutablePath(), dot = CGMutablePath()
            var lw = 0.6
            for b in bubs {
                let c = rig.toScreen(b.x, b.y), r = b.r * z
                ring.addEllipse(in: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
                let dr = r * 0.2
                dot.addEllipse(in: CGRect(x: c.x - r * 0.38 - dr, y: c.y - r * 0.38 - dr, width: dr * 2, height: dr * 2))
                lw = max(lw, r * 0.22)
            }
            bubbleRing.path = ring; bubbleRing.lineWidth = lw; bubbleDot.path = dot
            bubbleRing.isHidden = false; bubbleDot.isHidden = false
        }
        let box = body.boundingBoxOfPath
        if on && p.caustic > 0 && !labLayersOff.contains("caustic") && rig.restsOnSill && !box.isNull && box.width > 1 {
            let w = Double(box.width) * 0.5, cx = Double(box.midX), by = Double(box.maxY), R = rig.R * z, k = Float(min(1.5, p.caustic))
            causticShade.bounds = CGRect(x: 0, y: 0, width: w * 2.1, height: R * 0.17); causticShade.position = CGPoint(x: cx, y: by - R * 0.015); causticShade.opacity = min(1, k)
            causticLight.bounds = CGRect(x: 0, y: 0, width: w * 1.24, height: R * 0.10); causticLight.position = CGPoint(x: cx + w * 0.22, y: by - R * 0.01); causticLight.opacity = min(1, k)
            causticShade.isHidden = false; causticLight.isHidden = false
        } else { causticShade.isHidden = true; causticLight.isHidden = true }
    }
    /// v2.28 果凍皮: the Metal skin instead of the flat fill, outline, highlight, dents and trail (those stay for the flat control); the blush under the eyes.
    private func drawJelly(body: CGPath, outline: [(x: Double, y: Double)], z: Double) {
        let on = jellyOn
        decoCost = 0
        litPath = nil
        shadeLayer.isHidden = on; baseLayer.isHidden = on; highlightLayer.isHidden = on; outlineLayer.isHidden = on
        dentShadeLayer.isHidden = on || dentShadeLayer.isHidden; dentLitLayer.isHidden = on || dentLitLayer.isHidden
        if on { for l in dentLayers { l.isHidden = true }; for l in trailLayers { l.isHidden = true } }
        // v2.51: the strand and the small blob go into the same mask, so the skin lights them as one body; v2.62: the second slime's outline instead of the blob, and the merge's goo
        var extra: [CGPath] = []
        let gv = rig.gooView
        twinNow = gv.twin
        for s in gv.segs {
            let a = rig.toScreen(s.x0, s.y0), b = rig.toScreen(s.x1, s.y1), ln = CGMutablePath()
            ln.move(to: CGPoint(x: Double(a.x), y: Double(a.y))); ln.addLine(to: CGPoint(x: Double(b.x), y: Double(b.y)))
            extra.append(ln.copy(strokingWithWidth: CGFloat(s.w * z), lineCap: .round, lineJoin: .round, miterLimit: 1))
        }
        if let tw = gv.twin, tw.outline.count > 2 {
            extra.append(bodyPath(tw.outline.map { rig.toScreen($0.x, $0.y) }))
        }
        // v2.52: the flat skin (phones without Metal, and the grey box) draws them too, in the shade colour; before, a strand there could not be seen
        if on || extra.isEmpty { gooFlatLayer.isHidden = true } else {
            let all = CGMutablePath()
            for e in extra { all.addPath(e) }
            gooFlatLayer.path = all; gooFlatLayer.isHidden = false
        }
        guard on, let j = jelly else {
            jelly?.layer.isHidden = true
            fxGroup.isHidden = true
            hideRubTrail()   // v2.64 B9：平塗皮照舊畫自己那條一暗一亮的溝（trailLayers）
            for l in blushLayers { l.isHidden = true }
            for l in [bubbleRing, bubbleDot, causticShade, causticLight] as [CALayer] { l.isHidden = true }
            return
        }
        j.layer.isHidden = false
        let off = labLayersOff, moodOff = off.contains("mood")
        let tr = rig.showsImpression && !moodOff ? rig.impShownTrust : 0, w = rig.showsImpression && !moodOff ? rig.impShownWary : 0
        let R = rig.R * z
        var marks = JellySkin.Marks()   // v2.65 #9 markStyle（網頁 jelRender）：0 照 v2.63；1、2 的凹痕半徑固定 0.53R（設計稿 58px）、深度是看得到的深度
        marks.mode = Float(rig.markMS)
        var dents: [JellySkin.Dent] = []
        if rig.markMS < 1 {
            dents = off.contains("dent") ? [] : rig.dents.compactMap { d -> JellySkin.Dent? in
                let r = rig.R * rig.params.dentSize * d.d
                guard r >= 0.5 else { return nil }
                let p = rig.toScreen(d.x, d.y)
                return JellySkin.Dent(x: Float(p.x), y: Float(p.y), r: Float(r * z * 1.2), d: Float(min(1, d.d)))
            }
        } else if !off.contains("dent") {
            for d in rig.markDents {
                let p = rig.toScreen(d.x, d.y)
                dents.append(JellySkin.Dent(x: Float(p.x), y: Float(p.y), r: Float(0.53 * rig.R * z), d: Float(d.mv)))
                marks.rel.append(Float(d.mr)); marks.d0.append(Float(d.m0))
            }
        }
        if let q = rig.markPullView {
            let b = rig.toScreen(q.bx, q.by), e = rig.toScreen(q.tx, q.ty)
            marks.bx = Float(b.x); marks.by = Float(b.y); marks.tx = Float(e.x); marks.ty = Float(e.y); marks.s = Float(q.s); marks.fade = Float(q.fade)
        }
        let hz = rig.haze
        let p = rig.params
        // C1 細絲 (多米 11-22 決定 6): the rounding hides a strand of body thinner than about 0.1R; with `thin` on it shrinks as the pull nears its limit
        thinK += (rig.thinLevel - thinK) * (1 - pow(0.8, frameDt * 60))   // the web eases by a fifth each 60 Hz frame
        let round: Double = off.contains("round") ? 0 : p.round * (1 - 0.7 * thinK)
        // C2 水的呼吸 (決定 7): still, the refraction was static (glass, not water; Kawabe 2015); with `wbreath` on it follows its breath, ±12% (half with Reduce Motion)
        let refr: Double = p.refr * (p.wbreath >= 0.5 ? 1 + (rig.reduceMotion ? 0.06 : 0.12) * rig.breathWave : 1)
        var skin = JellySkin.skin(cloud: hz.cloud, glow: hz.glow, wet: p.wet >= 0.5)
        if let o = kind.skin {   // v2.57 its own skin numbers (仙草's edge does not go white)
            if let v = o.kEdge { skin.kEdge = Float(v) }
            if let v = o.kCore { skin.kCore = Float(v) }
            if let v = o.glow { skin.glow = Float(v) }
        }
        if off.contains("shade") { skin.amb = 1; skin.dif = 0 }
        // C3 (決定 8): what moves behind it shows through it too
        let t0 = CACurrentMediaTime()
        if p.decoThru >= 0.5 && p.water > 0 && !off.contains("refr") && rig.sillPlane == .room && !labGrey {
            var sprites: [JellySkin.Sprite] = []
            if let im = bellImage, !bellLayer.isHidden {
                sprites.append(JellySkin.Sprite(image: im, x: Double(bellLayer.position.x), y: Double(bellLayer.position.y), w: Double(bellLayer.bounds.width), h: Double(bellLayer.bounds.height), anchorY: 0, angle: rig.hangAngle("bell", amp: 0.22), alpha: 1))
            }
            if let im = teruImage, !teruLayer.isHidden {
                sprites.append(JellySkin.Sprite(image: im, x: Double(teruLayer.position.x), y: Double(teruLayer.position.y), w: Double(teruLayer.bounds.width), h: Double(teruLayer.bounds.height), anchorY: 0, angle: rig.hangAngle("teru", amp: 0.06), alpha: 1))
            }
            for (k, v) in rig.propViews.prefix(2).enumerated() {   // v2.64 擺飾變真: the things are no longer in the baked room, so they go in here
                guard let im = propImgs[k], !propImgLayers[k].isHidden else { continue }
                sprites.append(JellySkin.Sprite(image: im, x: v.x, y: v.y, w: v.w, h: v.h, anchorY: v.h > 0 ? v.oy / v.h : 0.5, angle: v.a, alpha: v.alpha))
            }
            let night = rig.sceneKind == 2
            for sp in backSprites {
                guard let im = SceneArt.sprite(sp.kind, night: night).cgImage else { continue }
                let sz: Double = (sp.big ? 30 : 22) * 1.05
                sprites.append(JellySkin.Sprite(image: im, x: sp.x, y: sp.y, w: sz, h: sz, anchorY: 0.5, angle: sp.a, alpha: sp.alpha))
            }
            j.setDynamic(sprites, around: body.boundingBoxOfPath.insetBy(dx: -R * 0.7, dy: -R * 0.7))
        } else { j.setDynamic([], around: .null) }
        decoCost = CACurrentMediaTime() - t0
        let mesh = meshSkin(outline: outline, z: z)   // v2.61 A1
        if let m = mesh { litPath = m.clip(body) }
        j.render(path: body, rpx: R, dents: Array(dents.prefix(6)), body: tinted(colors.base, tr, w), shade: tinted(colors.shade, tr, w, shade: true), line: colors.line,
                 skin: skin, round: round,
                 water: off.contains("refr") ? 0 : p.water, refr: refr, absorb: p.absorb,
                 shine: p.lookShine, opaque: p.lookOpaque, edgeClean: p.lookEdgeClean,   // v2.61b edgeClean (多米 11-26). v2.60 (多米 11-24): opaque, no highlights, all ten; the panel's 外觀 chip (clear) makes them glossy and see-through
                 extra: extra, hiOff: off.contains("hi"), rimOff: off.contains("wet"), mesh: mesh, marks: marks)
        if LabProbe.shared.skinOn {   // v2.61 A7
            let fill: [CGPath] = mesh == nil ? [body] + extra : []
            LabProbe.shared.skinFrame(mesh: mesh, paths: fill, outline: outline, size: bounds.size, R: R, round: round)
        }
        drawWater(body: body, z: z)
        drawFx(body: body, z: z)
        if p.rubTrail >= 0.5 { drawRubTrail(z: z) } else { hideRubTrail() }   // v2.64 B9（網頁 inBody：if(mat.rubTrail>=.5)drawRubTrail）
        // the blush: two soft pink spots below and beside the eyes (web: drawBlush)
        if let e = rig.eyeView {
            let S = e.size * z, l = rig.toScreen(e.lx, e.ly), r = rig.toScreen(e.rx, e.ry), a = atan2(r.y - l.y, r.x - l.x)
            let pink0 = UIColor(red: 1, green: 132 / 255, blue: 150 / 255, alpha: 0.72).cgColor, pink1 = UIColor(red: 1, green: 132 / 255, blue: 150 / 255, alpha: 0.42).cgColor, pink2 = UIColor(red: 1, green: 132 / 255, blue: 150 / 255, alpha: 0).cgColor
            for (k, (x0, y0, sd)) in [(l.x, l.y, -1.0), (r.x, r.y, 1.0)].enumerated() {
                let bl = blushLayers[k]
                bl.isHidden = false
                bl.bounds = CGRect(x: 0, y: 0, width: S * 0.26, height: S * 0.16)
                bl.position = CGPoint(x: x0 + cos(a) * sd * S * 0.23, y: y0 + sin(a) * sd * S * 0.23 + S * 0.11)
                bl.colors = [pink0, pink1, pink2]; bl.locations = [0, 0.55, 1]
            }
        } else { for l in blushLayers { l.isHidden = true } }
    }

    /// v2.61 A1 網格聯集的皮 (web skinU): this frame's triangles and keep-alive lines in screen points. nil = the outline path, as up to v2.60
    /// (skinU 0, a phone that cannot draw it, or no triangles to draw).
    private func meshSkin(outline: [(x: Double, y: Double)], z: Double) -> SkinMesh? {
        guard rig.params.skinU >= 0.5, let src = skinSrc, let j = jelly, j.meshReady else { return nil }
        let o = rig.toScreen(0, 0), pts = rig.labParticles()   // the camera and the intro only scale and shift: where (0, 0) lands is the shift
        guard skinMesh.update(src, x: pts.x, y: pts.y, ring: rig.bnd, outline: outline, zoom: z, ox: o.x, oy: o.y, R: rig.R * z) else { return nil }
        let gv = rig.gooView
        for s in gv.segs {
            let a = rig.toScreen(s.x0, s.y0), b = rig.toScreen(s.x1, s.y1)
            skinMesh.line(a.x, a.y, b.x, b.y, s.w * z)
        }
        if let tw = gv.twin, tw.outline.count > 2 {   // v2.62
            skinMesh.polygon(tw.outline.map { rig.toScreen($0.x, $0.y) })
        }
        return skinMesh
    }

    /// v2.57 新六隻的招牌 (web drawFx): 蝶豆's purple spots, 湯圓's sesame core, 珍奶's pearls, 布丁's caramel cap. The same soft spots as the blush.
    private func drawFx(body: CGPath, z: Double) {
        guard let v = rig.fxView, !labLayersOff.contains("fx") else { fxGroup.isHidden = true; return }
        fxGroup.isHidden = false
        let Rz = rig.R * z, fx = kind.fx
        func soft(_ l: CAGradientLayer, _ x: Double, _ y: Double, _ r: Double, _ c: (Double, Double, Double), _ a: Double) {
            l.isHidden = false
            l.bounds = CGRect(x: 0, y: 0, width: 2 * r, height: 2 * r)
            l.position = CGPoint(x: x, y: y)
            func col(_ al: Double) -> CGColor { UIColor(red: CGFloat(c.0 / 255), green: CGFloat(c.1 / 255), blue: CGFloat(c.2 / 255), alpha: CGFloat(al)).cgColor }
            l.colors = [col(a), col(a * 0.5), col(0)]; l.locations = [0, 0.55, 1]
        }
        for (k, l) in fxStainLayers.enumerated() {
            if let pp = fx.purple, k < v.stains.count { let s = v.stains[k], p = rig.toScreen(s.x, s.y); soft(l, p.x, p.y, s.r * z, pp, 0.78 * s.k) } else { l.isHidden = true }
        }
        for (k, l) in fxCoreLayers.enumerated() {
            if let c = fx.core, v.coreSoft.isEmpty, k < v.core.count { let p = rig.toScreen(v.core[k].x, v.core[k].y); soft(l, p.x, p.y, Rz * 0.34, c, 0.1) } else { l.isHidden = true }
        }
        // v2.61b coreSoft (多米 11-26: the core looked like a grey smudge on the white body): fewer, smaller, lighter. Each spot is solid to 0.2R and fades out by 0.48R,
        // they add up to one lump at full strength and the group draws it at 0.3 (web coreSoft: solid circles, blurred 0.14R, at 0.3)
        fxCoreSoftGroup.isHidden = v.coreSoft.isEmpty
        let cs = UIColor(red: 96 / 255, green: 84 / 255, blue: 92 / 255, alpha: 1), csR = Rz * 0.48
        for (k, l) in fxCoreSoftLayers.enumerated() {
            guard k < v.coreSoft.count else { l.isHidden = true; continue }
            let p = rig.toScreen(v.coreSoft[k].x, v.coreSoft[k].y)
            l.isHidden = false; l.bounds = CGRect(x: 0, y: 0, width: 2 * csR, height: 2 * csR); l.position = CGPoint(x: p.x, y: p.y)
            l.colors = [cs.cgColor, cs.cgColor, cs.withAlphaComponent(0.35).cgColor, cs.withAlphaComponent(0).cgColor]; l.locations = [0, 0.42, 0.7, 1]
        }
        if v.pearls.isEmpty { fxPearlLayer.path = nil; fxPearlLitLayer.path = nil } else {
            let dark = CGMutablePath(), lit = CGMutablePath(), rr = Rz * 0.1
            for q in v.pearls {
                let p = rig.toScreen(q.x, q.y)
                dark.addEllipse(in: CGRect(x: p.x - rr, y: p.y - rr, width: 2 * rr, height: 2 * rr))
                let lx = p.x - rr * 0.22, ly = p.y - rr * 0.22, lr = rr * 0.52
                lit.addEllipse(in: CGRect(x: lx - lr, y: ly - lr, width: 2 * lr, height: 2 * lr))
            }
            fxPearlLayer.path = dark; fxPearlLitLayer.path = lit
        }
        if let c = fx.cap {   // always on whichever side is up: measured down from the outline's top, however the body has turned; the lower edge drips in a few arcs
            let bb = body.boundingBoxOfPath, x0 = Double(bb.minX), x1 = Double(bb.maxX), y0 = Double(bb.minY), hh = Double(bb.height), cxm = (x0 + x1) / 2, fl = v.capFlow
            let base = y0 + hh * (0.25 + 0.04 * fl), amp = Rz * (0.045 + 0.05 * fl)
            func yb(_ x: Double) -> Double { let u = (x - cxm) / max(1, Rz); return base + amp * (0.62 * sin(u * 5.3 + 1.2) + 0.38 * sin(u * 9.4 + 0.5) + 0.5) }
            let fr = CGRect(x: x0 - 4, y: y0 - 4, width: x1 - x0 + 8, height: max(1, base + amp * 1.5 - (y0 - 4)))
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: 0)); path.addLine(to: CGPoint(x: fr.width, y: 0))
            var x = x1 + 4
            while x >= x0 - 4 { path.addLine(to: CGPoint(x: x - Double(fr.minX), y: yb(x) - Double(fr.minY))); x -= 3 }
            path.closeSubpath()
            fxCapGrad.isHidden = false; fxCapGrad.frame = fr; fxCapMask.frame = CGRect(origin: .zero, size: fr.size); fxCapMask.path = path
            fxCapGrad.colors = [UIColor(red: CGFloat(min(255, c.0 + 22) / 255), green: CGFloat(min(255, c.1 + 18) / 255), blue: CGFloat(min(255, c.2 + 10) / 255), alpha: 0.93).cgColor,
                                UIColor(red: CGFloat(c.0 / 255), green: CGFloat(c.1 / 255), blue: CGFloat(c.2 / 255), alpha: 0.93).cgColor]
        } else { fxCapGrad.isHidden = true }
    }

    /// v2.31 搖晃沉澱: the haze (thickest low in the middle), the glitter, the glow at the clear moment; all clipped to the body by litGroup
    private func drawGlitter() {
        guard let gv = rig.glitterView else {
            fogLayer.isHidden = true; glowLayer.isHidden = true; haloLayer.isHidden = true
            for l in glitLayers { l.path = nil }
            return
        }
        let z = rig.drawZ, R = rig.R * z, c = rig.toScreen(gv.cx, gv.cy), pr = 1 / max(0.2, z)
        func radial(_ l: CAGradientLayer, cx: Double, cy: Double, r: Double, colors: [CGColor], locations: [NSNumber]) {
            l.isHidden = false
            l.bounds = CGRect(x: 0, y: 0, width: 2 * r, height: 2 * r)
            l.position = CGPoint(x: cx, y: cy)
            l.colors = colors; l.locations = locations
        }
        if gv.cloud > 0.01 {
            radial(fogLayer, cx: c.x, cy: c.y + R * 0.1, r: R * 1.05,
                   colors: [UIColor(white: 1, alpha: 0.42 * gv.cloud).cgColor, UIColor(white: 1, alpha: 0.12 * gv.cloud).cgColor], locations: [0.095, 1])
        } else { fogLayer.isHidden = true }
        var paths = [CGMutablePath(), CGMutablePath(), CGMutablePath(), CGMutablePath()]
        var alpha = [0.0, 0.0, 0.0, 0.0], count = [0, 0, 0, 0]
        for d in gv.dots {
            let p = rig.toScreen(d.x, d.y), rr = d.r * pr * z, k = min(3, max(0, d.c))
            paths[k].addEllipse(in: CGRect(x: p.x - rr, y: p.y - rr, width: 2 * rr, height: 2 * rr))
            alpha[k] += d.a; count[k] += 1
        }
        for k in 0..<4 { glitLayers[k].path = count[k] > 0 ? paths[k] : nil; glitLayers[k].opacity = Float(count[k] > 0 ? alpha[k] / Double(count[k]) : 0) }
        if gv.glow > 0.01 {
            let g1 = UIColor(red: 1, green: 250 / 255, blue: 210 / 255, alpha: 0.55 * gv.glow).cgColor, g0 = UIColor(red: 1, green: 250 / 255, blue: 210 / 255, alpha: 0).cgColor
            radial(glowLayer, cx: c.x, cy: c.y, r: R * 1.1, colors: [g1, g0], locations: [0, 1])
            let h1 = UIColor(red: 1, green: 240 / 255, blue: 170 / 255, alpha: 0.28 * gv.glow).cgColor, h0 = UIColor(red: 1, green: 240 / 255, blue: 170 / 255, alpha: 0).cgColor
            radial(haloLayer, cx: c.x, cy: c.y, r: R * 1.7, colors: [h1, h1, h0], locations: [0, 0.353, 1])
        } else { glowLayer.isHidden = true; haloLayer.isHidden = true }
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

    /* v2.64 B9 揉的時候看得到手指走過的痕跡（rubTrail；未做 13，BATCH3 第 6 項、第 8 項之 6；網頁 RTK、drawRubTrail，6ef0791）。
       痕跡 v2.26 就有在算（SlimeRig trail：揉、摸時手指每走 0.05R 記一點，dentTrail 秒後丟掉），也一直有畫，但只畫在平塗那條路（trailLayers）；
       果凍皮那條路（drawJelly）一開頭就把 trailLayers 藏起來，所以算了沒畫，跟網頁同一個原因。這裡在果凍皮那條路補畫，照角色的畫風：
       角色的陰影色一條實心的帶子，寬 w R、往左上偏 off R，不加亮邊、不加漸層。越舊越淡，分五段（同一段一條路徑，疊的地方不變深；
       新的那段先挖掉底下舊的再畫，接頭和繞回來的地方不疊深，網頁 destination-out 那一步，這裡是 CGBlendMode.destinationOut）。
       Core Animation 的圖層沒有「挖掉」，所以每幀把痕跡那一塊用 CGContext 畫成一張圖（只畫框住痕跡那一塊），放在 litGroup 裡，用皮的遮罩剪。
       沒動 Metal 著色器。只畫、不碰物理和亂數；rubTrail 0 不畫，跟改之前一樣 */
    private enum RTK { static let w = 0.13, a = 0.3, off = 0.05 }   // w 帶子寬（R）、a 最新那段的不透明度（乘段中間的新鮮度，最新那段 0.27）、off 往左上偏多少（R）
    private func hideRubTrail() {
        guard rubTrailShown else { return }
        rubTrailLayer.isHidden = true; rubTrailLayer.contents = nil; rubTrailShown = false
    }
    private func drawRubTrail(z: Double) {
        let tr = rig.trailView   // 網頁 if(!(mat.dentTrail>0)||TRAIL.length<2)return：trailView 在 dentTrail 0 或不到兩點時是空的
        guard tr.count > 1, z > 0, z.isFinite else { hideRubTrail(); return }
        let Rz: Double = rig.R * z, hw: Double = Rz * RTK.w, ox: Double = -0.64 * Rz * RTK.off, oy: Double = -0.77 * Rz * RTK.off
        let pts: [CGPoint] = tr.map { q in
            let s = rig.toScreen(q.x, q.y)
            return CGPoint(x: Double(s.x) + ox, y: Double(s.y) + oy)
        }
        var x0 = Double.infinity, y0 = Double.infinity, x1 = -Double.infinity, y1 = -Double.infinity
        for c in pts {
            let x = Double(c.x), y = Double(c.y)
            guard x.isFinite, y.isFinite else { continue }
            x0 = min(x0, x); x1 = max(x1, x); y0 = min(y0, y); y1 = max(y1, y)
        }
        let pad: Double = hw + 4, bw = Double(bounds.width), bh = Double(bounds.height)
        x0 = max(0, floor(x0 - pad)); y0 = max(0, floor(y0 - pad)); x1 = min(bw, ceil(x1 + pad)); y1 = min(bh, ceil(y1 + pad))
        guard x0.isFinite, y0.isFinite, x1.isFinite, y1.isFinite, x1 > x0, y1 > y0 else { hideRubTrail(); return }
        let box = CGRect(x: x0, y: y0, width: x1 - x0, height: y1 - y0)
        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = window?.screen.scale ?? UIScreen.main.scale
        fmt.opaque = false
        fmt.preferredRange = .standard
        let shade = (labGrey ? Self.greyColors : colors).shade
        var drew = false
        let img = UIGraphicsImageRenderer(size: box.size, format: fmt).image { rc in
            let c = rc.cgContext
            c.translateBy(x: -box.minX, y: -box.minY)
            c.setLineCap(.round); c.setLineJoin(.round); c.setLineWidth(CGFloat(hw))
            for b in 0..<5 {
                let k0: Double = Double(b) / 5, k1: Double = Double(b + 1) / 5, kk: Double = (Double(b) + 0.5) / 5
                let path = CGMutablePath()
                var open = false, any = false
                for j in 1..<tr.count {
                    let q = tr[j], p = tr[j - 1]
                    let ok: Bool = pts[j].x.isFinite && pts[j].y.isFinite && pts[j - 1].x.isFinite && pts[j - 1].y.isFinite
                    if !ok || q.n != p.n || q.k < k0 || (q.k >= k1 && b < 4) { open = false; continue }
                    any = true
                    if !open { path.move(to: pts[j - 1]); open = true }
                    path.addLine(to: pts[j])
                }
                guard any else { continue }
                c.setBlendMode(.destinationOut); c.setStrokeColor(UIColor.black.cgColor); c.addPath(path); c.strokePath()   // 新的那段先挖掉底下舊的
                c.setBlendMode(.normal); c.setStrokeColor(shade.withAlphaComponent(CGFloat(RTK.a * kk)).cgColor); c.addPath(path); c.strokePath()
                drew = true
            }
        }
        guard drew, let cg = img.cgImage else { hideRubTrail(); return }
        rubTrailLayer.frame = box
        rubTrailLayer.contentsScale = fmt.scale
        rubTrailLayer.contents = cg
        rubTrailLayer.isHidden = false
        rubTrailShown = true
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
        drawGlitter()   // v2.31 搖晃沉澱
        drawJelly(body: bodyPath(P), outline: P, z: z)   // v2.28 果凍皮

        var minX = 1e9, maxX = -1e9, maxY = -1e9
        for p in P { minX = min(minX, p.x); maxX = max(maxX, p.x); maxY = max(maxY, p.y) }
        let shadowX = (minX + maxX) / 2   // the shadow centres on the whole width (a long pull shifts the centroid aside)

        // floating: a soft shadow under the lowest point, fainter the higher it hangs. v2.19 A8: none (it floats and walks every way;
        // a shadow said up was flying one moment and the floor moved along the next)
        let noShadow = (rig.params.life2 >= 0.5 && rig.params.shadow < 0.5) || labGrey   // v2.52 灰盒: no shadow
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
        litMask.path = litPath ?? body   // v2.61 A1: cut to the mesh skin's own shape
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
        let tk: Int = tkImp + tkMood + (kind.fx.fog != nil ? q40(rig.fogCloud) * 1_000_000_000_000 : 0)   // v2.57 汽水's fog
        if tk != tintKey && !labGrey {
            tintKey = tk
            let tr = rig.showsImpression ? rig.impShownTrust : 0, w = rig.showsImpression ? rig.impShownWary : 0
            let sh = tinted(colors.shade, tr, w, shade: true).cgColor, ba = tinted(colors.base, tr, w).cgColor
            shadeLayer.fillColor = sh; baseLayer.fillColor = ba; twinBaseLayer.fillColor = ba
        }
        // v2.23 eyes (多米 11-02: try a face, eyes only): bean eyes looking where it looks; ∩ happy, ∪ asleep, > < squeezed, a line when shut
        let ef = CGMutablePath(), el = CGMutablePath(), eli = CGMutablePath()
        if let e = rig.eyeView {
            let js: Double = jellyOn ? 0.68 : 1   // the jelly skin draws the eyes smaller, as on the web
            let S = e.size * z, ew = S * 0.082 * js * sqrt(e.spread), eh = S * 0.118 * js, ox = e.lookX * S, oy = e.lookY * S
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
        drawTwin(z: z)   // v2.62

        CATransaction.commit()
    }

    /// v2.62 (web twinFace): the second slime's face (eyes, blush), its flat body's lit part, the lump while it is swallowed, the ripple inside the first one
    private func drawTwin(z: Double) {
        func off() {
            twinGroup.isHidden = true; twinBulge.isHidden = true
            twinEyeFill.path = nil; twinEyeLight.path = nil; twinEyeLine.path = nil
        }
        guard let tw = twinNow else { off(); for l in twinRings { l.isHidden = true }; return }
        let R: Double = rig.R * z
        for (k, l) in twinRings.enumerated() {
            guard k < tw.rings.count else { l.isHidden = true; continue }
            let q = tw.rings[k], c = rig.toScreen(q.x, q.y), r: Double = q.r * z
            l.isHidden = false
            l.path = CGPath(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2), transform: nil)
            l.lineWidth = CGFloat(q.w * z)
            l.strokeColor = colors.light.withAlphaComponent(CGFloat(max(0, min(1, q.alpha)))).cgColor
        }
        let P: [(x: Double, y: Double)] = tw.outline.map { rig.toScreen($0.x, $0.y) }
        guard P.count > 2 else { off(); return }
        let path = bodyPath(P), flat = !jellyOn
        twinMask.path = path
        twinBaseLayer.isHidden = !flat
        if flat { twinBaseLayer.path = bodyPath(P, dx: -R * 0.05, dy: -R * 0.06) }   // the flat skin: the shade is the extra shape (gooFlatLayer), the body colour up-left of it
        if tw.bulge > 0 {
            twinBulge.isHidden = false; twinBulge.path = path; twinBulge.lineWidth = CGFloat(R * 0.04)
            twinBulge.strokeColor = colors.shade.withAlphaComponent(CGFloat(min(1, 0.7 * tw.bulge))).cgColor
        } else { twinBulge.isHidden = true }
        let ef = CGMutablePath(), el = CGMutablePath(), eli = CGMutablePath()
        var blushOn = false
        if let e = tw.eyes {
            let S: Double = e.size * z, l = rig.toScreen(e.lx, e.ly), r = rig.toScreen(e.rx, e.ry), a: Double = atan2(r.y - l.y, r.x - l.x)
            let sides: [((x: Double, y: Double), Double)] = [(l, -1.0), (r, 1.0)]
            if jellyOn {   // the blush as the first one's (the flat skin has none)
                blushOn = true
                let pink0 = UIColor(red: 1, green: 132 / 255, blue: 150 / 255, alpha: 0.72).cgColor, pink1 = UIColor(red: 1, green: 132 / 255, blue: 150 / 255, alpha: 0.42).cgColor, pink2 = UIColor(red: 1, green: 132 / 255, blue: 150 / 255, alpha: 0).cgColor
                for (k, sd) in sides.enumerated() {
                    let bl = twinBlush[k], c0 = sd.0, s: Double = sd.1
                    bl.isHidden = false
                    bl.bounds = CGRect(x: 0, y: 0, width: S * 0.26, height: S * 0.16)
                    bl.position = CGPoint(x: c0.x + cos(a) * s * S * 0.23, y: c0.y + sin(a) * s * S * 0.23 + S * 0.11)
                    bl.colors = [pink0, pink1, pink2]; bl.locations = [0, 0.55, 1]
                }
            }
            let js: Double = jellyOn ? 0.68 : 1, ew: Double = S * 0.082 * js, eh: Double = S * 0.118 * js, ox: Double = e.ox * z, oy: Double = e.oy * z
            twinEyeLine.lineWidth = CGFloat(max(2, S * 0.034))
            if let md = e.mode {   // v2.65 #1（網頁 twinEyesDraw）：照主體眼睛那套畫（∩、∪、> <、睜開帶亮點、閉起來一條線）；看哪已經在姿勢裡
                let ew2: Double = ew * e.spread.squareRoot()
                for sd in sides {
                    let x: Double = sd.0.x, y: Double = sd.0.y
                    switch md {
                    case .happy:
                        let ar: Double = ew2 * 1.15, cy0: Double = y + eh * 0.45
                        el.move(to: CGPoint(x: x + ar * cos(Double.pi * 1.15), y: cy0 + ar * sin(Double.pi * 1.15)))
                        el.addArc(center: CGPoint(x: x, y: cy0), radius: CGFloat(ar), startAngle: CGFloat(Double.pi * 1.15), endAngle: CGFloat(Double.pi * 1.85), clockwise: false)
                    case .sleep:
                        let ar: Double = ew2 * 1.15, cy0: Double = y - eh * 0.35
                        el.move(to: CGPoint(x: x + ar * cos(Double.pi * 0.15), y: cy0 + ar * sin(Double.pi * 0.15)))
                        el.addArc(center: CGPoint(x: x, y: cy0), radius: CGFloat(ar), startAngle: CGFloat(Double.pi * 0.15), endAngle: CGFloat(Double.pi * 0.85), clockwise: false)
                    case .squeeze:
                        let q: Double = -sd.1
                        el.move(to: CGPoint(x: x + q * ew2 * 0.9, y: y - eh * 0.55))
                        el.addLine(to: CGPoint(x: x - q * ew2 * 0.8, y: y))
                        el.addLine(to: CGPoint(x: x + q * ew2 * 0.9, y: y + eh * 0.55))
                    case .open:
                        let h: Double = eh * e.open * e.wide, w: Double = ew2 * e.wide
                        if h < w * 0.35 {
                            el.move(to: CGPoint(x: x - w, y: y)); el.addLine(to: CGPoint(x: x + w, y: y))
                        } else {
                            ef.addEllipse(in: CGRect(x: x - w, y: y - h, width: 2 * w, height: 2 * h))
                            if h > w * 0.7 { let lr: Double = w * 0.34; eli.addEllipse(in: CGRect(x: x - w * 0.32 - lr, y: y - h * 0.4 - lr, width: 2 * lr, height: 2 * lr)) }
                        }
                    }
                }
            }
            for sd in sides where e.mode == nil {
                let x: Double = sd.0.x + ox, y: Double = sd.0.y + oy
                if e.squeeze {   // pulled open: > <
                    let q: Double = -sd.1
                    el.move(to: CGPoint(x: x + q * ew * 0.9, y: y - eh * 0.55))
                    el.addLine(to: CGPoint(x: x - q * ew * 0.8, y: y))
                    el.addLine(to: CGPoint(x: x + q * ew * 0.9, y: y + eh * 0.55))
                    continue
                }
                let hh: Double = eh * e.open
                if hh < ew * 0.35 {   // shut: the sleeping arc
                    let ar: Double = ew * 1.15, cy0: Double = y - eh * 0.35
                    el.move(to: CGPoint(x: x + ar * cos(Double.pi * 0.15), y: cy0 + ar * sin(Double.pi * 0.15)))
                    el.addArc(center: CGPoint(x: x, y: cy0), radius: CGFloat(ar), startAngle: CGFloat(Double.pi * 0.15), endAngle: CGFloat(Double.pi * 0.85), clockwise: false)
                    continue
                }
                ef.addEllipse(in: CGRect(x: x - ew, y: y - hh, width: 2 * ew, height: 2 * hh))
                if hh > ew * 0.7 { let lr: Double = ew * 0.34; eli.addEllipse(in: CGRect(x: x - ew * 0.32 - lr, y: y - hh * 0.4 - lr, width: 2 * lr, height: 2 * lr)) }
            }
        }
        if !blushOn { for l in twinBlush { l.isHidden = true } }
        twinEyeFill.path = ef; twinEyeLine.path = el; twinEyeLight.path = eli
        twinGroup.isHidden = !(flat || blushOn)
    }
}
