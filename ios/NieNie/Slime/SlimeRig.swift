import Foundation

/// Things the rig asks the outside world to play. Picture, sound and haptics
/// all react to the same event in the same frame.
enum SlimeEvent {
    case press(gain: Double)                 // a finger landed on the body
    case pull(gain: Double, rate: Double)    // stretched past another step
    case release(gain: Double, rate: Double, special: Bool) // let go; gain follows release strength; special = 偶發特別回彈
    case tick(gain: Double)                  // texture tick while kneading (提案第 13 條)
    case grain(gain: Double)                 // v2.25 F5: a fading grain after pressing down, or the contact patch changing
    case squish(gain: Double)                // two grabbing fingers pinched closer (提案第 24 條)
    case tap                                 // VoiceOver / buttons
    case nudge                               // v2.20 C1: it reached your resting finger (one soft tap); v2.22 E2: it pushed back at your finger
    case voice(kind: String, gain: Double, rate: Double)   // v2.22 E1: one of its small sounds; rate from the impression
    case beat                                // v2.23 C6: one beat of it answering your rhythm (a soft tap)
    case fx(kind: String, gain: Double, delay: Double)   // v2.50 場景聲 (AI samples, manifest fx.<kind>)
    case land(gain: Double)                  // v2.28 窗台: it landed on the sill or in the bowl after a fall or a hop
    case ding(gain: Double)                  // v2.31 搖晃沉澱: the glitter has settled, it is clear again
    case flinch(gain: Double, hap: Double)   // v2.63 D4 (flinchFx): it flinched from your touch: a small sound (gain 0 = tap only) and a light tap
    case knock(kind: String, gain: Double)   // v2.64 擺飾變真: a thing knocked (manifest prop.<kind>: glass, candle, book, bell; the web's sfxPlay('knock.'+kind))
    case wall(gain: Double, rate: Double)    // v2.64 B9 撞側牆出聲（sndWall）：落地那個音檔 fx.land，rate 是音高；網頁沒有震動，所以不走 .fx（.fx 的 land 會輕震）
}

/// v2.63 B1 pull, B3 (FeelParams.pullFx; web PFX, the same numbers, Agent's picks for 多米 to hear and feel): d0 the farthest the real finger got from where it
/// took hold must pass this (radii) before it counts as opening; tv the new-ground speed's smoothing (s); g, v the strand loop's floor (pullMax × g × min(1, speed ÷ v));
/// v0 the new-ground speed (radii a second) that lifts the haptic floor, hap its size, ta / tr its rise / fall time constants. Used by SlimeController and SlimeAudio too
enum PullFxSet { static let d0 = 0.05, tv = 0.06, g = 0.3, v = 0.5, v0 = 0.15, hap = 0.08, ta = 0.04, tr = 0.2 }
/// v2.64 B8 起步跟手（startFollow；網頁 SFK，1505203）：起步的時間常數（秒）、手指走多遠（R）變回慢一拍、停多久（秒）歸零、每格動多少（R）以下算停
enum SfSet { static let t0 = 0.02, lead = 0.6, stop = 0.08, eps = 0.002 }

/// Shape-matching soft body (Müller 2005), a port of `prototype/web/index.html` v2.5
/// (v2.2 plus the first batch of 手感精修提案, 2026-11-01: press spread, dwell-gated plasticity,
/// release strength by stretch, prediction fallback, animated reset; v2.4 second-batch candidates
/// behind FeelParams defaults; v2.5 提案第 41 條: tentacle rungs and medial-axis constraint, so a
/// tentacle pushed from its root toward its tip no longer folds over itself):
/// a floating irregular blob with drooping tentacles, built from particles that are pulled
/// back every substep to the best rigid fit of overlapping clusters. Plasticity keeps a
/// molded shape (clay), tentacles spring back; idle breathing, wriggle, tentacle drift,
/// twitches and wandering; boundary ring constraints and in-group non-penetration so it
/// never tangles. Rules learned the hard way are in `.uiux/lessons.md` and CLAUDE.md.
final class SlimeRig {
    var params: FeelParams
    /// The params as the physics uses them. v2.29: the anti-knot guards are not applied to fixed tentacles (limbs > 0, the 8-legged control):
    /// those have their own rungs and slip, and 多米 11-06 no longer wants the legs.
    private var effParams: FeelParams { Self.effective(params) }
    /// v2.52 A2: the same numbers for the panels, so a slider can say「實際是 X」beside a value a scene or a mode has overridden
    /// (3-3: what the panel shows, the default and what the physics uses must be one number, or the difference is written out).
    var effectiveParams: FeelParams { effParams }
    static func effective(_ p: FeelParams) -> FeelParams {
        var m = p
        if m.limbs > 0 { m.noFlip = 0; m.gripUp = 0.2; m.homeCap = 0; m.fingerSolid = 0 }
        if m.scene >= 0.5 {   // v2.28 窗台: on the sill it does not lift itself by pulsing; a little more upright; no hop-in (it drops into the bowl)
            m.bodySize = 0.27; m.intro = 0; m.introSwim = 0; m.jellyLift = 0
            // v2.52 A1 (多米 11-22 決定 3: 拿掉窗台對拉伸的覆寫). The sill used to cap every stretch at 3.2R and the memory at 2.6R, so clay's own
            // 7 and 5 were never used there and the panel showed a number the hand never felt. What is left is v2.51's strand: while it is on the
            // body itself stretches only to strandAt (the rest of the way is the strand; 多米 11-22: 不能破皮). With the strand off the
            // material's own numbers hold. sillCap > 0 is the control for v2.50 (the old cap), kept for blind tests and the selftest's old items.
            if m.strand >= 0.5 { m.maxPull = min(m.maxPull, m.strandAt); m.memMax = min(m.memMax, 2.6) }   // v2.53: back to v2.51 (2.4 and 2.6); 1.6 and 1.8 left too little of the pull and of the shape it keeps (多米 11-22)
            else if m.sillCap > 0 { m.maxPull = min(m.maxPull, m.sillCap); m.memMax = min(m.memMax, 2.6) }
            m.upright = max(m.upright, 0.03)
        }
        // v2.54 無限拉: the soft limits and the finger giving way are off (web effPull, effMem, effSlip); the edge limits widen in capGrowStep
        if m.endless >= 0.5 { m.maxPull = Self.endlessLim; m.memMax = Self.endlessLim }
        return m
    }
    /// v2.52 A5: every random draw of the rig comes from here. Unseeded it is the system's generator, as before; the fuzz test seeds it
    /// (`seedRandom`), so the same seed gives the same run on every build (3-3 第 8 欄: 固定種子的亂捏，每一版跑同一套).
    struct RigRandom: RandomNumberGenerator {
        var seeded = false
        var state: UInt64 = 0
        mutating func next() -> UInt64 {
            guard seeded else { var g = SystemRandomNumberGenerator(); return g.next() }
            state &+= 0x9E37_79B9_7F4A_7C15   // SplitMix64
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
            z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
            return z ^ (z >> 31)
        }
    }
    private var rng = RigRandom()
    func seedRandom(_ seed: UInt64?) { if let s = seed { rng = RigRandom(seeded: true, state: s) } else { rng = RigRandom() } }
    /// v2.52 A5: no reads or writes of what the user has stored (the fuzz test runs on a rig of its own, like the web's WALK.noSave)
    var labNoSave = false
    /// Reduce Motion: idle motion and twitches halved. Feedback stays on.
    var reduceMotion = false
    var onEvent: ((SlimeEvent) -> Void)?
    /// v2.31 走路: a tap on the gift stone on the sill (the app asks whether it may know how far you walked)
    var onGiftTap: (() -> Void)?

    private(set) var W = 0.0, H = 0.0, R = 100.0, cx = 0.0, cy = 0.0, h = 10.0
    private(set) var homeX = 0.0, homeY = 0.0
    private(set) var N = 0

    // particle state (positions in view points)
    private var X: [Double] = [], Y: [Double] = [], PX: [Double] = [], PY: [Double] = []
    private var Q0X: [Double] = [], Q0Y: [Double] = []   // original rest shape (zero mean)
    private var QX: [Double] = [], QY: [Double] = []     // remembered (plastic) rest shape
    /// v2.54 補點: what the remembered shape returns to. The same as Q0 until the body is re-sampled; then Q0 becomes the remembered
    /// shape of that moment (mesh, clusters and rest lengths are measured from it) and H0, carried over by interpolation, is the original lump.
    private var H0X: [Double] = [], H0Y: [Double] = []
    // v2.58 (web homeRing): the body as built: its outline (points, running length), all its points, its outline's indices; each outline point's
    // place along that outline now (HB), and how far H0 has been shifted by re-centring
    private var HRX: [Double] = [], HRY: [Double] = [], HRC: [Double] = [0], HB: [Double] = [], HQX: [Double] = [], HQY: [Double] = [], HBND: [Int] = []
    private var HOX = 0.0, HOY = 0.0, remCrossQ = false
    private var remN = 0, remN0 = 0, remLast = -9.0, remChk = 0.0, remCalm = -9.0
    private var remKnot = 0.0, remKnotChk = 0.0   // v2.58 (11-24) memUntie: how long the remembered outline has been crossed with nothing held, and the 0.1 s check
    // v2.57 the six new slimes' signatures (web fxStep, drawFx): set by the controller with the chosen slime
    var fx = SlimeFx() { didSet { fxReset() } }
    private var fxStains: [(i: Int, k: Double, r: Double, hot: Bool)] = []   // 蝶豆: rubbed spots turning purple (particle, how purple, how wide ×R, rubbed this frame)
    private var fxCoreN = 0, fxCore: [Int] = [], fxCoreSoftN = 0, fxCoreSoft: [Int] = []   // 湯圓: the sesame core hangs on these inner particles (v2.61b coreSoft: a smaller set)
    private var fxPearlN = 0, fxPearls: [(i: Int, x: Double, y: Double)] = [], fxPearlSink = 0.0   // 珍奶: each pearl trails one inner particle; sink after a shake
    private(set) var fxCapFlow = 0.0                                          // 布丁: 0...1, the caramel runs down while it is held
    private(set) var remeshCount = 0, remeshMs = 0.0
    // v2.25 F4: QD is the reference shape with inertia (the body chases QD, QD chases Q on a spring); QV its velocity; QW how much a drag's acceleration pushes each particle
    private var QDX: [Double] = [], QDY: [Double] = [], QVX: [Double] = [], QVY: [Double] = [], QW: [Double] = []
    // v2.26 F6: the offset a stroke carries the whole body by; comfort adding up over strokes; F7: the trail in the body's frame; the highlight's neighbours
    private var stkOX = 0.0, stkOY = 0.0, stkVX = 0.0, stkVY = 0.0, stkG = 0.0, stkLast = -9.0, stkSaid = false, stkPet = false
    private struct TrailPoint { let x, y, t0, n: Double }
    private var trail: [TrailPoint] = []
    private var hiDent: Dent?
    private var cvX = 0.0, cvY = 0.0, caX = 0.0, caY = 0.0, cpX: Double?, cpY: Double?, tickLastT = -9.0   // centroid velocity, acceleration, last position; v2.25 F5: the last grain
    private var EX: [Double] = [], EY: [Double] = []     // rest shape with idle breathing / wriggle / drift
    private var GX: [Double] = [], GY: [Double] = [], GW: [Double] = []
    private var RX: [Double] = [], RY: [Double] = []
    private var TU: [Double] = [], TUB: [Double] = [], KF: [Double] = []
    private var TID: [Int] = [], BIDX: [Int] = []
    private var GRAB: [Bool] = []

    private(set) var bnd: [Int] = []     // boundary particle indices, in ring order
    private var bndL: [Double] = []      // rest distance between ring neighbours
    private var bndL2: [Double] = []     // rest distance between ring particles two apart (no folding back)
    /// v2.48: each edge's rest length; what the hard limits pushed the held particles back by this substep (the finger gives way by it); who a wall or the sill stopped; the remembered shape's longest edge (times rest)
    private var EDL: [Double] = [], SLX: [Double] = [], SLY: [Double] = [], HIT: [Bool] = [], QSTR = 1.0
    /// v2.54 無限拉 (多米 11-22: pulled 5 cm it grew 3 cm and would not go further; it should stretch without end, under the finger).
    /// Measured, three things held it back: ① the finger gave way (capSlip 4): every mesh edge stops at 3× rest (stretchCap), the held patch
    /// was pushed back and the finger's effective position moved back four times that, finger 4R, patch 2.5R; ② slide 1.5: stretched 1.5R
    /// the whole body was dragged along; ③ the remembered shape stopped at 2.4× an edge (memCap) and shrank back to 2.5R on release.
    /// With `endless` on the finger does not give way and the soft limits are off (`effective`); every edge's limit is multiplied by CAPG,
    /// which grows by growK a second while edges are full and the held patch lags the finger, so the whole length grows together instead of
    /// a few edges by the finger turning into a spike. Let go, CAPG only falls back to what the remembered shape still needs. Web `capGrowStep`.
    static let endlessLim = 100.0
    private(set) var CAPG = 1.0, CAPGAP = 0.0
    private var EDG: [Int] = [], EDEG: [Double] = [], EDSX: [Double] = [], EDSY: [Double] = []   // v2.47: the mesh's edges (two indices an edge, each once), how many meet at each particle, scratch for memSmoothStep
    private var TRI: [Int] = [], TRA: [Double] = []   // v2.29 防打結: the rest shape's triangle mesh (3 indices a triangle) and each rest area
    // v2.28 窗台 (多米 11-06): gravity, a sill to stand on, a bowl in the middle to sit in; v2.31 the bowl centred, the props pictures only.
    // Port of the web's SILL for the room plane only: the window frame, the outside and the climbing routes come with the next batch.
    struct SillGeo {
        let s, U, off, ox, fl, bw, bh, bx, by, gx, gy, gw, gh, jr, bt, oy: Double
        let rim, lip, back, cav, outer, bf, l, r, sl, sr: Double   // rim = the bowl's rim line, lip = the front edge's lowest point, back = the back edge, cav = the inside's half width, fl = the sill's top, l/r = how far it may go on the sill
    }
    private(set) var sillOn = false
    private(set) var sillG: SillGeo?
    private(set) var sillInBowl = false
    private var sillAir = false, sillC = 0, sillWant = false, sillGrab = false, sillHeld = false
    private var sillPX = 0.0, sillPY = 0.0, sillVX = 0.0, sillVY = 0.0, sillFall = 0.0, sillLastHome = -99.0, sillRelX = 0.0, sillRelY = 0.0
    private struct SillHop { var air = false; var t = 0.0; var tx = 0.0; var toBowl = false }
    private var sillHop: SillHop?
    private let sillGrav = 14.0   // gravity, radii per second per second
    // v2.30 routes (多米 11-06; v2.31 only in and out of the bowl): a list of steps walked in order. sniff = reach a pseudopod, move = gravity off,
    // it lifts itself until its bottom is at y (climbing strokes), plane = in or out of the bowl, drop = gravity back on, walk = along the sill
    // to x, surf = stick to a surface, wait. gt = the gravity it wants (0 while lifting), gv = the gravity it has (eased over 0.12 s);
    // tanV = walking vertically, lift = lifting itself, y1 = the body's bottom this frame.
    private enum RouteStep { case sniff(a: Double, L: Double, T: Double), move(y: Double), plane(SillPlane, inBowl: Bool?), drop(g: Double), walk(surf: String, to: Double), surf(String), wait(T: Double), zoomHome, walkHops, turn(String), fn(() -> Void) }   // v2.64 fn: the web's RT.fn (推東西)
    private struct Route { var steps: [RouteStep]; var i = -1; var st0 = 0.0; var y0: Double? = nil; var i0 = -1; var id = 0 }   // v2.64 id: the web compares the route object itself (DR.push.route)
    private var routeSeq = 0
    private var sillRoute: Route?
    private var sillLift = false, sillTanV = false, sillSurf: String?
    private var sillGTX = 0.0, sillGTY = 1.0, sillGVX = 0.0, sillGVY = 1.0, sillY1 = 0.0
    private var gaitClimb = false
    // v2.30 planes: room = on the sill in front of everything; frame = behind the bowl on the window frame's bottom; out = outside on the ledge,
    // the view zoomed out to 0.8 about the ledge's height. v2.31: it only goes there on the walk's way home (走路), not by itself.
    enum SillPlane { case room, frame, out }
    private(set) var sillPlane = SillPlane.room
    private var sillZoom = 1.0, sillZTG = 1.0, sillZPX = 0.0, sillZPY = 0.0, sillOutT = 0.0, sillCB = 0   // cb = floor contacts this substep (walls do not count as landing)
    // 走路 (多米 11-06: 現實裡做的事跟牠掛勾): walked enough, it comes back from outside with a small thing stuck to it; a pinch knocks it off onto the sill.
    // Nothing of the physics changes, the thing is only drawn bound to the body. Steps come from CMPedometer through the controller; the panel fakes them.
    private struct WalkItem: Codable { var k: String; var big: Bool; var s: Int; var a: Double; var gift: Bool }
    private struct WalkSave: Codable { var items: [WalkItem]; var bank: Int; var day: String; var dayN: Int; var opens: Int; var perm: String }
    private struct WalkStuck { var k: String; var big: Bool; var i: Int; var a: Double; var idle: Double }
    private struct WalkFall { var k: String; var big: Bool; var s: Int; var x, y, vx, vy, a, va, ty, G: Double; var b: Int; var na: Double }
    private struct WalkLeave { var k: String; var big: Bool; var x, y, a, al: Double }
    private var walkItems: [WalkItem] = [], walkStuck: WalkStuck?, walkFall: [WalkFall] = [], walkLeave: [WalkLeave] = []
    private var walkBank = 0, walkDay = "", walkDayN = 0, walkOpens = 0, walkLoaded = false, walkPending = false
    private(set) var walkPerm = ""   // "" not asked, "ok", "no"
    private let walkKinds = ["stone", "leaf", "petal", "acorn", "cap", "feather"], walkSmall = 500, walkBig = 3000, walkDayMax = 3, walkIdle = 20.0
    /// One small thing as drawn: on the sill (screen points, the room does not move) or stuck to it / falling (world points)
    struct WalkSprite { let kind: String; let big: Bool; let x, y, a, alpha: Double }
    // v2.31 搖晃沉澱 (多米 11-07: like a snow globe). Shake: it bounces in the bowl (capped), the glitter in its belly rises into a haze; shakeN shakes and it is full.
    // Still: nothing touching it, the glitter sinks over settleT s, it breathes 6 times a minute with its eyes shut. Clear: the moment it is all down it glows, opens
    // its eyes, dings; a little pile at the bottom, now and then a star or a heart, picked again each time it is shaken up. The glitter is only drawn inside the body,
    // the physics does not change; only the bounce gives the particles a speed. Port of the web's SNW, settle mode only (散出來吃回來 stays on the web for now).
    private struct Glit { var tx = 0.0, ty = 0.0, sx = 0.0, sy = 0.0, h = 0.0, s = 1.0, r = 1.0, c = 0, ph = 0.0, sw = 1.0 }
    private var snwGlit: [Glit] = [], snwCloud = 0.0, snwK = 0.0, snwShape = "mound", snwCleared = true, snwWasCloudy = false
    private var snwLast = -9.0, snwLastVoice = -9.0, snwGlow = 0.0, snwClearT = -9.0, snwKick: (vx: Double, vy: Double, until: Double)?
    private var glitSeed: UInt32 = 7
    struct GlitterView { let cloud, glow, cx, cy: Double; let dots: [(x: Double, y: Double, r: Double, c: Int, a: Double)] }
    private var builtScene = -1.0
    /// 0 blue (floating), 1 day, 2 night: what the view draws behind it
    /// v2.59 窗景: a window that only has a night is open; the chosen background stays as it was
    var winNight = false
    var sceneKind: Int {
        let k = Int(params.scene.rounded())
        return k > 0 && winNight ? 2 : k
    }
    /// v2.35 拿掉碗 (多米 11-08): it lives in the middle of the sill; the bowl is not drawn, not in the way, nothing to fall into
    var noBowl: Bool { sillOn && params.bowl < 0.5 }
    /// v2.37 擺飾: the wind bell swings after a shake (amp in radians), decaying over a few seconds
    private var decoKick = -99.0, decoDir = 1.0
    // v2.64 擺飾變真 (未做 24; web PROPS, PROPDEF, HANG, DB, SOFTB, DR, v2.44 to v2.61): the state; the code is MARK v2.64 擺飾變真 at the end of this file
    struct PropDef { let kind: String; let asp, wd, com, m, tap: Double; let poly: [(Double, Double)] }
    struct Prop {
        let im: String, kind: String
        var tap: Double, upT = -99.0
        var w, h, ox, oy: Double
        var px: [Double], py: [Double], nx: [Double], ny: [Double]   // the outline (local, about the centre of mass) and each edge's outward normal
        var r, hw, base, m, I: Double
        var x: Double, y: Double, hx: Double, hy: Double
        var a = 0.0, vx = 0.0, vy = 0.0, va = 0.0
        var alpha = 1.0, fade = 0.0, gone = false, fell = false, tip = false, tc = 0
        var lastHit: Double, backAt = 0.0, knockT = -9.0
        var held: ObjectIdentifier? = nil
        var hlx = 0.0, hly = 0.0                         // where the finger holds it, in its own frame
        var fingT: Double? = nil, selfT: Double? = nil, softT: Double? = nil, softX = 0.0, softK: Double? = nil
        var catT: Double? = nil, lookAt: Double? = nil, crashAt: Double? = nil
        init(im: String, kind: String, tap: Double, w: Double, h: Double, ox: Double, oy: Double, px: [Double], py: [Double], nx: [Double], ny: [Double],
             r: Double, hw: Double, base: Double, m: Double, I: Double, x: Double, y: Double, t: Double) {
            self.im = im; self.kind = kind; self.tap = tap; self.w = w; self.h = h; self.ox = ox; self.oy = oy
            self.px = px; self.py = py; self.nx = nx; self.ny = ny; self.r = r; self.hw = hw; self.base = base; self.m = m; self.I = I
            self.x = x; self.y = y; self.hx = x; self.hy = y; self.lastHit = t
        }
    }
    struct Hang { let name: String; let w2, damp, kick, tap: Double; let ring: Bool
        var a = 0.0, va = 0.0, held: ObjectIdentifier? = nil, ringT = -9.0, on = false, x = 0.0, y = 0.0, w = 0.0, h = 0.0
        var selfT: Double? = nil, fingT: Double? = nil, lookAt: Double? = nil, touch = false
    }
    private(set) var props: [Prop] = []
    private var hangs: [Hang] = [Hang(name: "bell", w2: 77, damp: 0.9, kick: 1.9, tap: 2.6, ring: true), Hang(name: "teru", w2: 115, damp: 1.4, kick: 1.3, tap: 3.2, ring: false)]
    private var decoKeyNow = -1
    private var dbX: [Double] = [], dbY: [Double] = [], dbOK = false
    // v2.46 第 3 片 (web DR): habituation per thing, when its eyes go to what moved, 推東西
    private var drHab: [String: Int] = [:], drWideT: Double? = nil, drLookT = -9.0, drLX = 0.0, drLY = 0.0
    private var drCats = 0, drCatT = -99.0, drCatLast = ""
    private var drPush: (k: Int, side: Double, route: Int)? = nil
    func decoSwing(_ amp: Double) -> Double {
        let u = t - decoKick
        guard u >= 0, u < 6 else { return 0 }
        return amp * decoDir * exp(-u / 1.1) * sin(u * 2 * .pi * 1.4)
    }

    private struct Cluster {
        var idx: [Int]
        var w: Double
        var cs = 1.0, sn = 0.0, xc = 0.0, yc = 0.0, qcx = 0.0, qcy = 0.0
    }
    private var clusters: [Cluster] = []
    private var gi = 0   // index of the whole-body cluster

    private struct Tentacle {
        var a, ux, uy, L, w, curl, droop: Double
        var uExit = 0.0
        var root: [Int] = [], edge: [Int] = [], all: [Int] = []   // v2.27: particles at the root, the outline away from the root, all of them
        var s = 1.0, bumpT = -9.0   // v2.27: remembered stretch; last time it was bumped
    }
    private var tent: [Tentacle] = []
    private var ph: [Double] = [0, 0, 0, 0]

    /// 觸手橫檔 (提案第 41 條): a pair of boundary particles across a tentacle, with its rest width and the
    /// rest length of the medial-axis link leading to it.
    private struct Rung {
        var a: Int, b: Int
        var w0: Double
        var hs: Double
    }
    private var rungs: [[Rung]] = []          // per tentacle, root to tip
    private var rungSign: [Double] = []       // rest handedness: sign of cross(local axis, b − a)
    private var rungRef: [(Int, Int)] = []    // the two body particles flanking each tentacle's boundary run

    private(set) var hiIdx = 0
    private var t = 0.0, lastTouch = -10.0, nextTwitch = 3.0, A0 = 1.0
    private var wanderX = 0.0, wanderY = 0.0, wanderNext = 3.0, wanderMoving = false
    private var wanderSX = 0.0, wanderSY = 0.0, wanderP = 0.0, wanderT = 1.0   // 提案第 20 條: start, progress and duration of the current walk
    private var wanderVX = 0.0, wanderVY = 0.0                                 // home velocity this frame (points per second), drives the tentacle tail
    private var pinchA: ObjectIdentifier?, pinchB: ObjectIdentifier?, pinchD0 = 1.0, pinchNext = 0.6   // 提案第 24 條 two-finger squish
    private var brPhase = 0.0, brPrev = 0.0, brAmp = 1.0, brWave = 0.0, brDeepAt = -99.0, brGrabStart = -1.0   // 提案第 23 條 breathing
    private var AW: [Double] = []                                              // 候選 27 area-pressure weights
    private var builtHome = -1.0                                               // 候選 33 home height fraction the body was built for
    private var cellHead: [Int32] = [], cellNext: [Int32] = []                 // 第 36 條 collide grid, no per-substep allocation
    private var builtSeed = -1.0, builtFloppy = -1.0, builtSpace = -1.0, builtRad = -1.0
    private var relaxUntil = -1.0            // 揉回原形: until when the remembered shape eases back to the original
    private(set) var lastReleaseStrength = 0.0
    private var tLife = 0.0                                                // idle-life clock, runs only while untouched (提案第 19 條)
    private var releaseCount = 0, nextSpecial = 0, specialUntil = -1.0     // 偶發特別回彈 (提案第 2 條)
    // 2026-11-01 多米真機回報 (build 46): idle morph coefficients for outline modes 2...5 and two roaming bumps, set once a frame
    private var morphA = [Double](repeating: 0, count: 6), morphB = [Double](repeating: 0, count: 6)
    private var bumpAng = [0.0, 0.0], bumpAmp = [0.0, 0.0]
    private var rest0: [[(w: Double, s: Double)]] = []   // the original shape's own rung widths and axis advances (restFix thresholds)
    // v2.9 pseudopods (多米 2026-11-01: limbs retract and grow again elsewhere, the top too; no fixed shape): direction, length,
    // width, bend, lifetime; grow 40%, hold 20%, retract 40%. Their clock runs only while untouched (touched, they hold still)
    private struct Pod { var a, L, sig, bend, D: Double; var p = 0.0 }
    private var pods: [Pod] = [], podClock = 0.0, podNext = 0.5, podShift = 0.0
    private var podE: [(ca: Double, sa: Double, amp: Double, sig: Double, bend: Double)] = []
    private var brJw = 0.0, brLift = 0.0          // jellyfish contraction 0...1, and the lift it gave (points)
    private var GWT: [Double] = []                // grab weight of each particle this substep (grabHold)
    private var flatOn = false, flatFloor = 0.0, flatQB = 0.0
    // v2.12 camera (多米: pulled a little bigger and it stopped; the physics followed, the screen edge did not): a big shape
    // zooms the view out and pans it to fit, down to zoomMin; the walls sit at the edge of the farthest view. screen = (world − cam) × z + V
    private(set) var camZ = 1.0, camX = 0.0, camY = 0.0
    var viewV: (x: Double, y: Double) { (W / 2, (90 + H - 120) / 2) }
    func toWorld(_ sx: Double, _ sy: Double) -> (x: Double, y: Double) {
        let v = viewV
        return ((sx - v.x) / camZ + camX, (sy - v.y) / camZ + camY)
    }
    func toScreen(_ x: Double, _ y: Double) -> (x: Double, y: Double) {
        let v = viewV
        // v2.17 intro: far away is drawn smaller and up-right, pivoting on the floor point under home
        let wx = ivS == 1 && ivOX == 0 && ivOY == 0 ? x : introPX + ivOX + ivS * (x - introPX)
        let wy = ivS == 1 && ivOX == 0 && ivOY == 0 ? y : introPY + ivOY + ivS * (y - introPY)
        return ((wx - camX) * camZ + v.x, (wy - camY) * camZ + v.y)
    }
    /// On-screen scale of the body: the camera zoom times the intro's distance scale.
    var drawZ: Double { camZ * ivS }

    // v2.17 intro (多米: when it opens it comes bouncing over from far away, hop by hop): wait → crouch → air → land, n hops; gravity and
    // the floor only during the intro; distance is a drawing scale (pivot: the floor point under home); iv* is that scale and shift
    // (eased back to 1 in 0.25 s at the end or on a touch)
    private enum IntroPhase { case wait, crouch, air, land }
    private(set) var introOn = false
    private var introPh = IntroPhase.wait, introK = 0, introN = 4, introPT = 0.0, introSq = 0.0, introFloor = 0.0, introTair = 0.4
    private var introU = 0.0, introS0 = 0.15, introOX0 = 0.0, introOY0 = 0.0, introPX = 0.0, introPY = 0.0
    private let introG = 26.0, introHops = [0.55, 0.6, 0.65, 0.85]
    private var ivS = 1.0, ivOX = 0.0, ivOY = 0.0
    // v2.17 camera follow (多米: don't pin it to the middle; it moves, sometimes off screen, and the camera follows slowly)
    private var folX = 0.0, folY = 0.0, folVX = 0.0, folVY = 0.0, folChase = false
    // v2.18 mood (多米: pulled it wants to run, stroked it purrs; no face): comfort −1...1 and arousal 0...1, easing back to the middle
    // with a 6 s time constant when untouched. Only what the hand is doing now, never how long you have been away.
    // strain: how hard it is being pulled (past 1.5R, held) 0...1; scare: from pokes; cowerUntil: curled up until; happyT / wagT:
    // the happy stand-tall and the pseudopod wag; tug: while pulled, home shifts away so the body pulls back
    private var moodC = 0.0, moodA = 0.0, moodStrain = 0.0, moodStrainMax = 0.0, moodScare = 0.0, cowerUntil = -9.0
    private var happyT = -9.0, wagT = -9.0, taps: [Double] = [], pullDX = 1.0, pullDY = 0.0, tugX = 0.0, tugY = 0.0
    // v2.63 C6 (rubVary; web RUBV): the shuffled bag of what it does when you let go after a rub, the last one, the last hop, when the melting began;
    // rubvS is the bag's own generator, so rubVary never draws from rng
    private var rubvBag: [String] = [], rubvLast = "", rubvHopT = -99.0, rubvSpT = -9.0, rubvS = UInt32.random(in: 0...UInt32.max)
    private static let rubvHop = 40.0, rubvSpread = 2.0
    // fleeing: home rushes out on an ease-out (fast, the camera lags and it leaves the screen a bit), then it curls up a moment
    private var escOn = false, escT0 = 0.0, escT = 1.0, escSX = 0.0, escSY = 0.0, escDX = 0.0, escDY = 0.0
    private var introMini = false
    /// Purr strength 0...1 (the controller turns it into soft taps).
    private(set) var purr = 0.0
    // v2.61 D1 (rough): how hard it tugs back. The same sum as moodStrain but whatever the speed (web MOOD.tugS): a slow pull is no rough play any more,
    // yet the body still leans back, so a long pull keeps its shape. 0 while rough is off
    private var moodTugS = 0.0
    // v2.61 C3 (petSlow): how much it has been stroked slowly (g), when last, being stroked now, hummed already (web PET)
    private var petG = 0.0, petLast = -9.0, petOn = false, petSaid = false
    // v2.19 活物感 (多米 build 73: no sense of life, it does not read as a creature; .uiux/04-手感/活物感提案-暫定.md).
    // rest / look / go / arrive (A1, A2). sniffs: pseudopods reaching out to sniff (a = screen angle, L length, T1 out, T2 hold, T3 back;
    // cut: touched or flinching, drawn in within 0.15 s); att: a point queued to sniff at (A7); lifeWrg: wriggle share; goFade: the
    // jellyfish pulse fades while walking (the contraction is the walking); lifeUntil −1 = choose on the next frame
    private enum LifeState { case rest, look, go, arrive, sleep, route }   // v2.23 sleep (B2); v2.30 route: walking a route on the sill (the route decides, not the life)
    private struct Sniff { var a, L, t0, T1, T2, T3, ph: Double; var cut = 0.0, eCut = 0.0, id = 0 }
    private var sniffSeq = 0
    // v2.64 C5 張望有對象（lookTarget；網頁 LT、LTK，第三批第 3 項）。程式在 MARK v2.64 C5（pickDir 旁邊）。
    // ltCur：這次探的對象（ltPick 挑的，排進 ltReactQ 就清掉）；ltReactQ：看完的小反應（sid 是那條偽足的 id，網頁拿偽足物件本身比）；
    // ltHabT：每個對象上次被看的時間（90 秒內份量慢慢回來）；ltS：自己那串亂數（網頁 ltRnd），rng 一個都不多抽。lookTarget 0 時都不會動
    private struct LookTgt { let k: String; let key: String; let x: Double; let y: Double; let ta: Double }
    private struct LookReact { let tg: LookTgt; let sid: Int; let a: Double; var at: Double }
    private var ltCur: LookTgt? = nil, ltReactQ: LookReact? = nil, ltHabT: [String: Double] = [:], ltS: UInt32 = 1
    private var lifeSt = LifeState.rest, lifeUntil = -1.0, lifeLooks = 0, lifeNoGo = false, sniffs: [Sniff] = []
    private var attOn = false, attAt = 0.0, attX = 0.0, attY = 0.0
    private var lifeWrg = 1.0, goFade = 0.0, lastDir = 0.0
    private var arrT = -9.0, arrH = 0.0, arrA = 0.0, arrK = 0.0, arrK0 = 1.0, arrOff = 0.0
    // gait (A3): ph < 0 gathering before setting off; each stroke P s, the first c s contract and surge, then relax and glide;
    // k = stretch along the heading; off = the gathering draw-back
    private var gaitOn = false, gaitTX = 0.0, gaitTY = 0.0, gaitDash = false, gaitPh = -1.0, gaitPrep = 0.0
    private var gaitV = 0.0, gaitVP = 0.0, gaitH = 0.0, gaitK = 1.0, gaitStr = 1.0, gaitLast = false, gaitOff = 0.0
    // flinch (A5): at = when, t0 = started, amp, H = habituation (×0.55 a flinch, back with a 7 s time constant), s = current scale,
    // pre = what it was doing before the touch (resting flinches more)
    private var flAt = -9.0, flT0 = -9.0, flAmp = 0.0, flH = 1.0, flS = 1.0, flPre = LifeState.rest
    private struct FlSay { var at: Double; var kind: String; var gain: Double; var rate: Double }   // v2.63 B5: a startle waiting for its flinch (web FLN.say)
    private var flSay: FlSay? = nil
    /// v2.63 B2: the press sound's own loudness for the `.press` event being sent (from pressForce), −1 = use the event's gain as before
    private(set) var pressSnd = -1.0
    // v2.61 D2 (tapSoft; web FLN.tc, tcq, tpAt): the most a flinch from your touch may be (1 = no limit), a light tap whose flinch has not come yet, when the flinch your touch set off is due
    private var flTc = 1.0, flTapQ = false, flTapAt = -9.0
    /// v2.63 D4 (flinchFx; web FLX, the same numbers, Agent's picks for 多米 to feel and hear): gain the sound (the release pop's air layer), hap the tap
    /// (sharpness sh), lo below flinchAmp × lo neither, win a release this soon after the flinch's sound skips its pop sound (and the other way round)
    private enum FlxSet { static let gain = 0.3, hap = 0.25, sh = 0.2, lo = 0.7, win = 0.3 }
    private var flxSndT = -9.0, flxRelT = -9.0   // when the flinch last sounded, when a release last popped
    /// v2.63 D4: true while the `.release` being sent should not play its pop sound (a flinch just sounded); the haptic pop stays
    private(set) var relQuiet = false
    private var shkAt = -9.0, shkT0 = -9.0, shkAmp = 0.0, shkTh = 0.0      // shaking off after a hard pull; th = how far it is turned now
    // breath (A6): exert = panting 0...1 (4 s time constant, 8...10 s to normal); a sigh every 30...90 s, then a 1 s pause
    private var exert = 0.0, sighNext = -1.0, sighCyc = -1, pauseUntil = -9.0, brAmpX = 1.0, brCyc = 0
    private var strK = 1.0, strH = 0.0                                     // stretched along the heading while walking or fleeing (area kept)
    private var psm = (a: 1.0, b: 0.0, c: 0.0, d: 1.0)                     // this substep's performed scaling of the rest shape; memory takes it off
    private var lifeLB = 1.0                                               // breathing amplitude (it goes on while held)
    private var SX2: [Double] = [], SY2: [Double] = []                     // where the performed scaling alone would put each particle in rest space
    /// v2.19 A4: one count per breath (each contraction), for the soft tap while held still.
    private(set) var breathBeat = 0
    private func lv(_ v: Double) -> Bool { params.life2 >= 0.5 && v >= 0.5 }
    // v2.20 D1 drag (多米 build 75: dragging only deformed it, nothing moved; measured: pulled 2R right the centroid moved 0.058R and
    // was back within a second, the held home spring being 4× the idle one). o = home's offset while held, following `drag` of the
    // fingers' travel (0.25 s lag, as if it had weight); on release it joins home, so it stays where it was dragged; g = a fling glides
    // on; b = keeps the offset continuous when a finger joins or leaves; slipT = how long a very wary one has been dragged (C3)
    private var dragOX = 0.0, dragOY = 0.0, dragVX = 0.0, dragVY = 0.0, dragBX = 0.0, dragBY = 0.0, dragGX = 0.0, dragGY = 0.0, dragSlipT = 0.0
    // v2.20 impression (多米 build 75: no feeling it reacts to you; wants second-order effects of how you treat it;
    // .uiux/04-手感/互動與拖拉提案-暫定.md): trust and wariness 0...1, only for this run of the app (zeroed after 10 min in the
    // background), never "sad you were away". impL: where you last touched it; ask: begging after a purr (C4)
    private(set) var impTrust = 0.0, impWary = 0.0
    private var impLX = 0.0, impLY = 0.0, impHas = false, impAskUntil = -9.0
    // v2.63 D6 (bond; web BONDK, BOND, SOOK, SOO, the same numbers, Agent's picks for 多米 to feel): trust splits in two. impTrust stays today's
    // closeness (full after 7 s of stroking); impBond is the bond, 0...1, and it never goes down: while trust is full (≥ full) and it is still
    // treated gently (the frames impStep adds trust on), rate a minute (about 100 minutes to 1); a yank, quick taps or a fling take nothing off.
    // The controller keeps each slime's in UserDefaults with the trust ("bd" in nienie.imp). Nothing on screen shows it.
    // It does one thing: a high bond (lo...hi, eased), not wary (< 0.4), the first touch more than gap s after the last hold, the flinch × (1 − k),
    // at k 1 none, it leans to your finger instead (the E2 lean). bondLastT = the last time it was held; flBk, flBX, flBY = that touch's k and where.
    // Soothing (SooSet): wary past w (only a yank or three quick taps get it there), a gentle hand has to add up T s first: no comfort, no purr, no
    // nuzzle meanwhile; at T it sighs (the sigh after a rub), then as usual. sooOn soothing, sooG seconds so far, sooOK soothed (until the wariness rises again)
    private enum BondSet { static let rate = 0.01, full = 0.95, lo = 0.3, hi = 0.7, gap = 2.0 }
    private enum SooSet { static let w = 0.5, T = 3.0 }
    private(set) var impBond = 0.0
    private var bondLastT = -9.0, flBk = 0.0, flBX = 0.0, flBY = 0.0
    private var sooOn = false, sooG = 0.0, sooOK = false
    private var bondOn: Bool { params.bond >= 0.5 && params.imp >= 0.5 }
    /// v2.63 D6: the controller brings a slime's bond back (launch, switching slimes); 0 with bond off
    func setBond(_ v: Double) { impBond = v.isFinite ? max(0, min(1, v)) : 0 }
    private var askOn = false, askAt = 0.0, askX = 0.0, askY = 0.0
    // a finger resting beside it (C1, C2): sn = the pseudopod pointing at it (sniff id); stillT = how long the finger has been still;
    // touched = reached it this time; rub = the nestling sway
    private var lureOn = false, lureID: ObjectIdentifier?, lureT0 = 0.0, lureStillT = 0.0, lurePounced = false, lureTouched = false
    private var lureTouchT = -9.0, lureStartle = -9.0, lureSn = -1, lureRub = 0.0, lureBacked = false
    private func iv2(_ v: Double) -> Bool { params.imp >= 0.5 && params.life2 >= 0.5 && v >= 0.5 }
    // v2.22 (多米 build 77: still no feeling it reacts to you; go on with the drops; .uiux/04-手感/拉力互動聲音黏液提案-暫定.md sections 2, 4):
    // E1 voice, E2 every action answered, E3 the impression shows, E4 comes to say hello (the drops were taken out 2026-11-07, 多米 11-06: 黏液取消)
    private func iv3(_ v: Double) -> Bool { params.life2 >= 0.5 && v >= 0.5 }
    // E2: lean* = leans toward the finger (S −1: wary, away); nuz* = nuzzling; tkTimes = when the tickling finger turned back
    private var leanO = 0.0, leanT = -9.0, leanA = 0.0, leanS = 1.0, nuzT0 = -1.0, nuzO = 0.0, nuzSaid = false, tkTimes: [Double] = [], tkT = 0.0, gigNext = 0.0
    // v2.64 D8 點牠牠頂回來（tapBack；網頁 TB）：tbAt 排好要頂的時間（−9 沒排）、tbRel 點的那一刻、tbX／tbY 你點的地方、tbFire 頂的那一刻、tbUntil 看著你到幾秒。程式在 MARK v2.64 D8
    private var tbAt = -9.0, tbRel = -9.0, tbX = 0.0, tbY = 0.0, tbFire = -9.0, tbUntil = -9.0
    // v2.64 D8 呼嚕時慢眨眼（slowBlink；網頁 SBL）：sblS 自己那串亂數（網頁 sblRnd）、sblAcc 呼嚕累計秒數、sblGap 這次要累計幾秒、sblT0 這次慢眨開始的時間（−9 沒在眨）
    private var sblS: UInt32 = 1, sblAcc = 0.0, sblGap = 8.0, sblT0 = -9.0
    // v2.64 C8 十隻招牌動作、喜歡的位置（signature；網頁 SG）：sgId 是哪一隻（SlimeController 換隻時設，網頁 SLIMES[SLIME].id；"" 沒有招牌）、sgS 自己那串亂數（網頁 sgRnd）、
    // sgAcc 醒著沒人碰累計的秒數、sgGap 這次要累計幾秒（−1 還沒抽）、sgOn 正在做的那一段、sgQ 排好的步驟、sgEye 眼睛半閉或慢慢閉上、sgWk 上次看到的醒來時間。程式在 MARK v2.64 C8
    var sgId = ""
    private var sgS: UInt32 = 1, sgAcc = 0.0, sgGap = -1.0, sgOn: SgRun? = nil, sgQ: [SgStep] = [], sgEye: SgEye? = nil, sgWk = -9.0
    // E4: wait = idle seconds before it comes this time; count = visits this run; wave = arrived and waving
    private var e4Wait = -1.0, e4Count = 0, e4On = false, e4Wave = false, e4T0 = 0.0, e4LastT = -99.0
    private var voiceLast = -9.0
    private(set) var mcC = 0.0, mcS = 0.0, mcW = 0.0, mcZ = 0.0   // v2.27 mood colour shown: comfort, strain, wary, asleep
    private(set) var impShownTrust = 0.0, impShownWary = 0.0
    // v2.23 (多米 build 86: the drops look wrong, come off too easily, too many; still no feeling it reacts to you; try a face, eyes only;
    // sleep, rhythm, swim-in and the collection all at once). lastSdt: the substep
    private var lastSdt = 1.0 / 240
    /// Eyes: open (blinks, squints while held, shut a moment on a flinch, wide when wary), happy ∩ (purr, happy, hello, your rhythm back),
    /// squeeze > < (pulled to flee, tickled, the start of a run, a yank), sleep ∪.
    enum EyeMode { case open, happy, squeeze, sleep }
    private var eyeL: [Int] = [], eyeR: [Int] = [], eyeD0 = 1.0, eyeGX = 0.0, eyeGY = 0.0, eyeSacT = 0.0, eyeSX = 0.0, eyeSY = 0.0
    private var eyeUser = -9.0, eyeOpenD = 1.0, eyeWideD = 1.0, eyeBlinkT = -9.0, eyeNextBlink = 2.0, eyePulse = -9.0, eyeSqU = -9.0, eyeBlink = 1.0
    private var eyeDX = 0.0, eyeDY = 0.0, eyeDK = 0.0   // v2.24: the face sliding out from under a finger (× eye size), and how close the finger is 0...1
    // v2.29 眼睛不跑出身體 (多米 11-06; measured 59 pt outside the outline in rough play): the face as placed this frame, with the eye distance capped at 1.3× rest,
    // the face tilted at most 50°, both eyes one eye's width inside the outline (else the face slides to the nearest thick spot, then the eyes close up);
    // eyeCX/CY/CK = the correction eased over 0.05 s, so it does not jump
    private var eyeCX = 0.0, eyeCY = 0.0, eyeCK = 1.0
    private var eyePose: (lx: Double, ly: Double, rx: Double, ry: Double)?
    private(set) var eyeMode = EyeMode.open
    struct EyeView { let lx, ly, rx, ry, gx, gy, lookX, lookY, open, wide, blink, size, spread: Double; let mode: EyeMode }
    /// The eyes as drawn (world points): each on the mean of its 4 particles; gaze −1...1; size = R × eyeSize; spread = how far apart vs rest.
    var eyeView: EyeView? {
        guard params.eyes >= 0.5, !eyeL.isEmpty, !eyeR.isEmpty else { return nil }
        if let pz = eyePose, effParams.noFlip > 0 {   // v2.29: the gaze and the dodge are already inside the pose
            return EyeView(lx: pz.lx, ly: pz.ly, rx: pz.rx, ry: pz.ry, gx: eyeGX, gy: eyeGY, lookX: 0, lookY: 0, open: eyeOpenD, wide: eyeWideD, blink: eyeBlink,
                           size: R * params.eyeSize * splitK, spread: max(0.8, min(1.3, hypot(pz.rx - pz.lx, pz.ry - pz.ly) / eyeD0)), mode: t < splitHappy ? .happy : eyeMode)
        }
        let l = eyeAt(eyeL), r = eyeAt(eyeR)
        let ga: Double = params.gazeAmp * (1 - 0.8 * eyeDK)   // v2.24: the whole face slides on the body; the closer the finger, the less it slides toward it
        return EyeView(lx: l.x, ly: l.y, rx: r.x, ry: r.y, gx: eyeGX, gy: eyeGY, lookX: eyeGX * ga + eyeDX, lookY: eyeGY * ga * 0.75 + eyeDY, open: eyeOpenD, wide: eyeWideD, blink: eyeBlink,
                       size: R * params.eyeSize * splitK, spread: max(0.8, min(1.3, hypot(r.x - l.x, r.y - l.y) / eyeD0)), mode: t < splitHappy ? .happy : eyeMode)   // v2.62: A smaller after a tear; happy eyes after a swallow
    }
    // B2 sleep: k eases 0...1 (1.6 s falling asleep, 0.25 s waking); lastAny = the last touch anywhere (a tap on empty space counts)
    private var slpSnoreAt = 0.0   // v2.50 next sleeping breath sound
    private var slpOn = false, slpK = 0.0, slpLastAny = -99.0, slpWakeT = -9.0, slpAskAt = -9.0, slpNearT = 0.0, flBoost = 1.0
    // v2.61 C1 (wakeSoft; web SLP): openT = when it was opened (or another one swam in); slow = this waking is the slow one; tap = the finger that touched it asleep (still to be told light or hard,
    // then, done, held on), since tapT0; tapN = light touches this nap; roll = the turn over (since when, which side, how far it has moved for it)
    private var slpOpenT = -99.0, slpSlow = false, slpTapN = 0, slpTapT0 = -9.0, slpTapDone = false, slpRollT = -9.0, slpRollD = 1.0, slpRollO = 0.0
    private var slpTapX = 0.0, slpTapY = 0.0, slpTapOut = false   // where it met the body, and whether it came in from outside
    // v2.63 C9 (nap; web NAP): cum = seconds purred this opening; on = waiting to fall asleep; x, y = where it was last touched (world; nothing reads it but a readout);
    // n = naps at your hand this opening. The web's armN is the selftest's count only, not here
    private var napCum = 0.0, napOn = false, napX = 0.0, napY = 0.0, napN = 0
    private var slpTap: Finger?
    // C6 echo: st 0 idle, 1 listening, 2 answering; beats = offsets from t0; prev = the rhythm it answered last (you repeating it = happy)
    private var echoTaps: [Double] = [], echoSt = 0, echoX = 0.0, echoY = 0.0, echoBeats: [Double] = [], echoI = 0, echoT0 = 0.0
    private var echoPrev: [Double]?, echoPrevT = -99.0, echoSame = false, echoJoyUntil = -9.0
    private(set) var echoBeatT = -9.0
    private var swimOn = false, swimT0 = 0.0   // swimming in (cold start, a slime switch)
    // v2.63 C4 (greetLook; web GREET, GREETK): wait = armed; open = armed by an opening (cold start, a slime switch: waits for it to land) or else by coming back
    // (from the background, the lock screen, Control Center: waits back s); at = when it turns to you (opening: −9 until it lands); t0 = when armed;
    // until = it looks at you till then; air = it was in the air (on the sill) since armed
    private var greetWait = false, greetOpen = false, greetAt = -9.0, greetT0 = -9.0, greetUntil = -9.0, greetAir = false
    // v2.63 大腦第一片 (brain; web BRAIN, BRon): the five needs and what it chose (SlimeBrain.swift); the body side is under MARK v2.63 大腦 below
    private var brain = SlimeBrain()
    private var brOn: Bool { params.life2 >= 0.5 && params.brain >= 0.5 }
    // v2.63 大腦第二片「心情」(mood; web MDon, BRM, BRMS): off (or the brain off) and every reader sees 0, as in slice 1
    private var mdOn: Bool { brOn && params.mood >= 0.5 }
    private var brainM: Double { mdOn ? brain.m : 0 }
    private var brainMS: Double { mdOn ? brain.mS : 0 }
    // v2.64 大腦第三片「記地方」(brMem; web BMEM, MMon): the five cells and your side (SlimeBrain.Mem); the body side is under MARK v2.64 記地方 below.
    // Off (brMem 0, the brain off, no sill) and nothing reads or writes it: as v2.63
    private var mem = SlimeBrain.Mem()
    private var mmOn: Bool { brOn && params.brMem >= 0.5 && sillOn && sillG != nil }
    /// v2.64: set by the controller; the rig calls it when the places changed and it is time to write them (the web's memSave: memPut, then localStorage).
    /// The controller reads memSaved(ts:) for the slime on screen. nil (the Linux harness): nothing is written
    var memWrite: (() -> Void)?
    /// v2.64 C5 張望有對象（網頁 ltWin）：畫面那邊設的，問「窗景裡現在有沒有正在動的東西」。傳進去窗洞（gx、gy、gw、gh）和最慢要多快（點／秒），
    /// 回來最快那層的編號和中心（跟牠同一套座標）。窗景存在畫面那邊（Metal），物理檔只准 Foundation，所以用這個問。nil（沒有畫面、Linux 測試）：不看窗景
    var winMover: ((_ gx: Double, _ gy: Double, _ gw: Double, _ gh: Double, _ minV: Double) -> (i: Int, x: Double, y: Double)?)?
    /// What the brain is doing and why it chose the last thing (the web's 「牠在想什麼」 lines; no readout on the phone yet)
    var brainSay: (act: String, why: String) { (act: brain.act, why: brain.why) }
    /// v2.23 收集: switching slimes brings that one's impression back (this run only).
    func setImpression(trust: Double, wary: Double) { impTrust = trust; impWary = wary; impShownTrust = trust; impShownWary = wary; impHas = false; impAskUntil = -9; sooOn = false; sooG = 0; sooOK = false }   // v2.63 D6: soothing starts over (web chooseSlime: impReset)
    /// v2.22 E3: the body colour leans with the impression.
    var showsImpression: Bool { iv3(params.e3) }

    /// Four hops in place at home: squash to gather before take-off (rest shape wider and lower), stretch in the air, the landing left
    /// to gravity and the floor (it really hits it, so no two wobbles are alike). Distance is drawn: it starts up-right at 0.15×, each
    /// hop comes closer and bigger, the last lands at home. Reduce Motion: no travel, one small hop at home.
    func startIntro() {
        slpOpenT = t   // v2.61 C1: opened, or another one swims in
        defer { greetWait = false; brainJit(); greetArm(open: true) }   // v2.63 C4 (web chooseSlime: startIntro(); … GREET.st=''; brainJit(); greetArm(true)), after the intro has started, whether or not there is one
        guard effParams.intro >= 0.5, N > 0 else { return }
        if effParams.introSwim >= 0.5 && params.life2 >= 0.5 && lv(params.lifeGait) { swimIntro(1); return }   // v2.23 開場游過來
        var y1 = -1e9
        for i in bnd { y1 = max(y1, Y[i]) }
        let far = !reduceMotion
        introMini = false
        introOn = true; introPh = .wait; introK = 0; introN = far ? 4 : 1; introPT = 0; introSq = 0; introFloor = y1
        introU = far ? 0 : 1; introS0 = far ? 0.15 : 1; introOX0 = far ? W * 0.2 : 0; introOY0 = far ? -H * 0.24 : 0
        introPX = homeX; introPY = y1
        ivS = introS0; ivOX = introOX0; ivOY = introOY0
        wanderMoving = false; wanderNext = t + 4
    }
    /// v2.18: what kind of grab this was, at release. A pull held past 0.5 s → run the other way; a gentle stroke over 1 s while
    /// comfortable → happy (stand tall, wag, hop); a quick one (under 0.25 s, not pulled) → a poke: flinch, the third within 1 s darts aside.
    private func moodRelease(_ f: Finger) {
        guard params.emo >= 0.5 else { return }
        // v2.61 D1 (rough): only a yank ever raises moodStrainMax (moodStep), so a slow pull takes neither of the next two branches; a yank still held long stops at A5, any other yank runs
        if params.pullSoft >= 0.5 && moodStrainMax > 0.15 && memLen() > PullSet.noFlee * HRC[HRX.count] {   // v2.61 A5 (fl): still pulled long, it does not run yet (only the scare)
            moodStrainMax = 0; moodScare = min(1, moodScare + 0.5)
            return
        }
        if moodStrainMax > 0.15 {
            flee(-pullDX, -pullDY, W * (0.45 + 0.35 * moodStrainMax) * params.flee); moodStrainMax = 0; return
        }
        if t - f.tDown < 0.25 && f.stretch < 0.3 {
            taps = taps.filter { t - $0 < 1 }; taps.append(t)
            moodA = min(1, moodA + 0.3)
            if params.tapSoft >= 0.5 && taps.count < 3 {   // v2.61 D2 (tapSoft): fewer than three within a second is just a touch: no scare, no comfort lost, no cowering; the flinch gets smaller
                if flAt > 0 && flAt == flTapAt { flTapQ = true } else if flT0 > f.tDown { tapCap(flAmp) }
            } else {
                flTc = 1; flTapQ = false
                moodScare = min(1, moodScare + 0.45); moodC = max(-1, moodC - 0.1); cowerUntil = max(cowerUntil, t + 0.5)
            }
            if taps.count >= 3 {
                var ux = clusters[gi].xc - f.ax, uy = clusters[gi].yc - f.ay
                let ul = hypot(ux, uy)
                if ul < R * 0.1 { let a = Double.random(in: 0..<(2 * .pi), using: &rng); ux = cos(a); uy = sin(a) } else { ux /= ul; uy /= ul }
                flee(ux, uy, W * 0.28 * params.flee); taps = []; moodC = max(-1, moodC - 0.3); moodA = 1
            }
            return
        }
        if f.gentleT > 1 && moodC > 0.35 && fingers.isEmpty && !slpOn { rubHappy(f.fx, f.fy) }   // v2.61 C1: !slpOn, let go still asleep (it only turned over); v2.63 C6 rubVary 0 as before (tall, a wag, the hop, happy)
    }
    private func flee(_ dx: Double, _ dy: Double, _ dist: Double) {
        guard dist > 0 else { return }
        let l = max(1e-9, hypot(dx, dy)), ux = dx / l, uy = dy / l
        escOn = true; escT0 = t; escT = max(0.6, dist / (R * 2.4)); escSX = homeX; escSY = homeY
        escDX = homeX + ux * dist; escDY = homeY + uy * dist * 0.8
        wanderMoving = false; moodScare = min(1, moodScare + 0.5)
    }
    /// v2.63 C6 (web rubHappy, rubVary): done rubbing or stroking, it is happy. 0: tall 2 s, a wag, the hop, the happy sound (as before, every time).
    /// 1: the hop, melting 2 s more, leaning to your finger, a sigh, from a shuffled bag (all four before a new shuffle; a new bag never starts with the last one);
    /// the hop at most once in 40 s (its turn sooner is skipped). The three without the hop put happyT 2 s back: the mood and the memory still see it, no tall pose, no ∩.
    /// The sounds are the old slime ones (mmm, poke, the sigh). MARK v2.63 C6
    private func rubHappy(_ fx: Double, _ fy: Double) {
        guard params.rubVary >= 0.5 else { happyT = t; wagT = t + 0.1; hop(); voice("happy"); return }
        var k = ""
        var i = 0
        while i < 9 && k.isEmpty {
            i += 1
            if rubvBag.isEmpty {
                rubvBag = rubvShuffle(["hop", "spread", "lean", "sigh"])
                if rubvBag.first == rubvLast { rubvBag.append(rubvBag.removeFirst()) }
            }
            let c = rubvBag.removeFirst()
            if c == "hop" && t - rubvHopT < Self.rubvHop { continue }
            k = c
        }
        rubvLast = k
        if k == "hop" { rubvHopT = t; happyT = t; wagT = t + 0.1; hop(); voice("happy"); return }
        happyT = t - 2
        if k == "spread" {   // melting 2 s more: the comfortable pose once more (5% wider, 6% lower), in over 0.3 s, out over 0.5 s after 2 s
            rubvSpT = t; voice("mmm", 0.5)
        } else if k == "lean" {   // leaning to your finger: the lean after a tap (E2), toward where the finger left
            if !clusters.isEmpty { leanT = t + 0.15; leanA = atan2(fy - clusters[gi].yc, fx - clusters[gi].xc); leanS = 1 }
            voice("poke", 0.5)
        } else {   // a sigh: the next breath 1.8× deeper and 1.6× slower, then a 1 s pause (its own sigh)
            if lv(effParams.lifeBreath) && sighCyc < 0 { sighCyc = Int(floor(brPhase)) + 1 }
            if !slpOn { onEvent?(.fx(kind: "sigh", gain: 0.45, delay: 0)) }
        }
    }
    private func rubvRnd() -> Double { rubvS = rubvS &* 1664525 &+ 1013904223; return Double(rubvS) / 4294967296 }
    private func rubvShuffle(_ a: [String]) -> [String] {
        var a = a
        var i = a.count - 1
        while i > 0 { let j = min(i, Int(rubvRnd() * Double(i + 1))); a.swapAt(i, j); i -= 1 }
        return a
    }
    /// The happy hop: the intro's hop, once, without travelling (mini: a touch grabs as usual).
    private func hop() {
        if sillOn && (sillAir || sillRoute != nil || sillTanV) { return }   // v2.28 窗台: not while falling; v2.30 not on a route
        guard !introOn, N > 0 else { return }
        var y1 = -1e9
        for i in bnd { y1 = max(y1, Y[i]) }
        introMini = true; introOn = true; introPh = .crouch; introK = 0; introN = 1; introPT = 0; introSq = 0; introFloor = y1
        introU = 1; introS0 = 1; introOX0 = 0; introOY0 = 0; introPX = homeX; introPY = y1
    }
    /// Every frame: the mood follows the hand (the most stretched grabbing finger), the purr, home while fleeing.
    private var tickOn: Bool { Double(tkTimes.count) >= params.tickRev }   // v2.24
    private static let grainTimes: [Double] = [0.06, 0.13, 0.21, 0.30], grainGains: [Double] = [0.8, 0.6, 0.42, 0.28]   // v2.25 F5
    // MARK: v2.61 D1 D2 C3 (.uiux/04-手感/極致優化規劃-暫定.md; web ROUGH, TAPK, PETK)
    /// D1 (rough), a yank: the hand at v (R a second on the screen, 30 ms smoothed) or more, heading outward, the patch pulled open past st (R).
    /// inR, inC are tugIn's: it counts from this far from the body's middle (R), and from this angle (cosine) towards the middle.
    private enum RoughSet { static let v: Double = 6, st: Double = 0.8, inR: Double = 0.35, inC: Double = 0.5 }
    private var roughOn: Bool { params.rough >= 0.5 }
    /// D2 (tapSoft): each light tap caps the next flinch at k of this one, eased off over T s, never below lo × flinchAmp.
    private enum TapSet { static let k: Double = 0.93, T: Double = 90, lo: Double = 0.3 }
    private func tapCap(_ a: Double) { flTc = max(TapSet.lo * params.flinchAmp, min(flTc, a * TapSet.k)) }
    /// C3 (petSlow), one for one with the web's PETK but for the centimetre: screen points ÷ ptPerCm, as rubSpeed has it (the web counts an R as 1.8 cm).
    private enum PetSet {
        static let ptPerCm: Double = 60
        static let lo0: Double = 0.5, lo: Double = 1, hi: Double = 10, hi0: Double = 14   // cm a second: lo to hi counts in full, fading out to lo0 and hi0
        static let rate: Double = 2.5, cap: Double = 0.8, top: Double = 3                 // added a second; at most on one pass (so one pass never purrs); at most in all
        static let rin: Double = 1.1, rout: Double = 1.25, c0: Double = 0.35              // R from the centre as it was: counts within rin; held past rout it is a pull and all of it is taken back; setting out within c0 does not count
        static let gap: Double = 0.6, fade: Double = 0.6                                  // still stroking this long after the last bit; lost a second after that
    }
    private func petReset() { petG = 0; petLast = -9; petOn = false; petSaid = false }
    /// Every frame, at the start of moodStep (web `petStep`). Grab or stroke is judged as before; this only counts how much it has been stroked, slow ones too, and feeds the purr and the trust.
    /// A pass setting out from the middle, or heading outward (within 60 degrees), does not count: strokeJudge's rule; turning back starts another pass.
    private func petStep(_ dt: Double) {
        petOn = false
        guard params.petSlow >= 0.5 else {
            petReset()
            for q in fingers.values { q.pt = nil }
            return
        }
        var f: Finger?
        for q in fingers.values where q.mode == .grab || (q.mode == .stroke && q.on) { f = q }
        let n: Int = fingers.count   // a second finger anywhere on the screen: no counting, no purr
        var pull = false
        if let f, n == 1, clusters.indices.contains(gi) {
            let x: Double = f.rawX, y: Double = f.rawY
            var p: Finger.PetPath = f.pt ?? Finger.PetPath(cx: clusters[gi].xc, cy: clusters[gi].yc, sx: x, sy: y, px: x, py: y)
            let dl: Double = hypot(x - p.sx, y - p.sy)
            if dl >= p.ml {
                p.ml = dl; p.px = x; p.py = y
            } else {
                let back: Double = hypot(x - p.px, y - p.py), turn: Double = (x - p.px) * (p.px - p.sx) + (y - p.py) * (p.py - p.sy)
                if back > R * 0.15 && turn < 0 {
                    p.sx = p.px; p.sy = p.py; p.ml = hypot(x - p.sx, y - p.sy); p.px = x; p.py = y; p.run = 0
                }
            }
            let d: Double = hypot(x - p.cx, y - p.cy) / R
            let rx: Double = p.sx - p.cx, ry: Double = p.sy - p.cy, rl: Double = hypot(rx, ry)
            let mx: Double = x - p.sx, my: Double = y - p.sy, ml: Double = hypot(mx, my)
            let along: Double = ml > 1e-6 ? (rx * mx + ry * my) / (rl * ml) : 0
            let away: Bool = rl < R * PetSet.c0 || along > 0.5
            let v: Double = hypot(f.vxS, f.vyS) * camZ / PetSet.ptPerCm
            if f.mode == .grab && d > PetSet.rout && !p.out { p.out = true; petG = max(0, petG - p.sum); p.sum = 0 }
            pull = p.out || (away && ml > R * 0.3) || f.yank
            let counts: Bool = !pull && !away && d < PetSet.rin && v > PetSet.lo0
            if v > PetSet.hi0 {
                petG = max(0, petG - 3 * dt)
            } else if counts && !tickOn && moodStrain < 0.05 && !escOn {
                let up: Double = (v - PetSet.lo0) / (PetSet.lo - PetSet.lo0), down: Double = (PetSet.hi0 - v) / (PetSet.hi0 - PetSet.hi)
                let add: Double = PetSet.rate * dt * min(1, min(up, down))
                let a: Double = max(0, min(PetSet.cap - p.run, min(PetSet.top - petG, add)))
                petG += a; p.run += a; p.sum += a; petLast = t
            }
            f.pt = p
        }
        if t - petLast > PetSet.gap || petLast > t { petG = max(0, petG - PetSet.fade * dt) }
        let lately: Bool = t >= petLast && t - petLast < PetSet.gap
        petOn = petG > 1 && !pull && n < 2 && lately && !tickOn
        if petG < 0.5 { petSaid = false }
    }
    private func moodStep(_ dt: Double) {
        guard params.emo >= 0.5 else { moodStrain = 0; moodTugS = 0; tugX = 0; tugY = 0; purr = 0; escOn = false; petReset(); return }
        petStep(dt)   // v2.61 C3
        var g: Finger?
        var soo = false   // v2.63 D6: soothing, no comfort or purr this frame
        for f in fingers.values where f.mode == .grab { if g == nil || bodyStretch(f) > bodyStretch(g!) { g = f } }
        if let g {
            let st = bodyStretch(g), sp = hypot(g.vxS, g.vyS) / R   // v2.20: how far the body itself is pulled open (dragging it along is not a hard pull)
            // v2.24 rubSpeed: the limit in real speed (60 pt a second is about 1 cm), a tickle does not count; really rubbing, comfort comes twice as fast as held still
            let v24: Bool = params.rubSpeed > 0, spPt: Double = sp * R, rubbing: Bool = v24 && spPt > R * 0.3
            let rubOK: Bool = v24 ? (spPt < params.rubSpeed * 60 && !tickOn) : sp < 2
            let gt0: Double = g.gentleT
            g.gentleT = st < 0.6 && rubOK ? g.gentleT + dt * (rubbing ? 2 : 1) : max(0, g.gentleT - 2 * dt)
            soo = sooStep(dt, gentle: g.gentleT > gt0 || (petOn && t - petLast < 0.05))   // v2.63 D6 (bond; web: the same line): very wary, soothe first
            if g.gentleT > 1 && !soo { moodC = min(1, moodC + (rubbing ? 0.6 : 0.35) * dt); moodA += (0.15 - moodA) * (1 - exp(-dt / 1.5)) }
            let rough: Bool = !roughOn || g.yank   // v2.61 D1 (rough): only once this grab has been yanked
            g.strainT = st > 1.5 && rough ? g.strainT + dt : max(0, g.strainT - dt)
            let sv = max(0, min(1, (g.strainT - 0.5) / 1))
            moodStrain += (sv - moodStrain) * (1 - exp(-dt / 0.15)); moodStrainMax = max(moodStrainMax, moodStrain)
            if roughOn {   // v2.61 D1: the tug back goes by how far and how long, fast or slow
                g.tugT = st > 1.5 ? g.tugT + dt : max(0, g.tugT - dt)
                let tv: Double = max(0, min(1, g.tugT - 0.5))
                moodTugS += (tv - moodTugS) * (1 - exp(-dt / 0.15))
            } else {
                g.tugT = 0; moodTugS = 0
            }
            if moodStrain > 0 { moodC = max(-1, moodC - 0.6 * dt * moodStrain); moodA = min(1, moodA + 0.8 * dt * moodStrain) }
            if !clusters.isEmpty {
                let px = g.fx - clusters[gi].xc, py = g.fy - clusters[gi].yc, pl = hypot(px, py)
                if pl > R * 0.2 { pullDX = px / pl; pullDY = py / pl }
            }
        } else {
            moodStrain *= exp(-dt / 0.2)
            moodTugS = roughOn ? moodTugS * exp(-dt / 0.2) : 0   // v2.61 D1
            let k = 1 - exp(-dt / 6)
            soo = sooStep(dt, gentle: (stkG > 1 && t - stkLast < 0.05) || (petOn && t - petLast < 0.05))   // v2.63 D6 (bond)
            if stkG > 1 && t - stkLast < 0.05 && !soo {   // v2.26 F6: a stroke counts as comfort; the finger is on it half the time, so it rises twice as fast as a rub
                moodC = min(1, moodC + 1.2 * dt); moodA += (0.15 - moodA) * (1 - exp(-dt / 1.5))
            } else {
                moodC -= moodC * k; moodA -= moodA * k
            }
        }
        moodScare *= exp(-dt / 0.8)
        let tugBy: Double = roughOn ? moodTugS : moodStrain   // v2.61 D1
        let tg = tugBy * R * 0.35; tugX = -pullDX * tg; tugY = -pullDY * tg   // tug of war: you can still pull it
        let gentleNow: Bool = g != nil ? g!.gentleT > 1 : (stkG > 1 && t - stkLast < 0.6)
        let pt: Double = gentleNow && moodC > 0.2 ? min(1, (moodC - 0.2) / 0.5) : 0
        let pt2: Double = soo ? 0 : (petOn ? max(pt, min(1, (petG - 1) / 0.5)) : pt)   // v2.61 C3: slow strokes purr too; v2.63 D6: soothing, none
        purr += (pt2 - purr) * (1 - exp(-dt * (1 + 0.4 * exLevel()) / 0.3))   // v2.32: excited, the purr comes sooner
        if escOn {
            let p = min(1, (t - escT0) / escT), e = 1 - pow(1 - p, 3)
            let nx = escSX + (escDX - escSX) * e, ny = escSY + (escDY - escSY) * e
            wanderVX = (nx - homeX) / dt; wanderVY = (ny - homeY) / dt; homeX = nx; homeY = ny
            if lv(params.lifeGait) { strK = 1 + 0.15 * pow(1 - p, 2) * (reduceMotion ? 0.5 : 1); strH = atan2(escDY - escSY, escDX - escSX) }   // v2.19: stretched along the dash
            if p >= 1 {
                escOn = false; cowerUntil = t + 1.2 + Double.random(in: 0..<0.8, using: &rng); wanderNext = max(wanderNext, t + 2 + Double.random(in: 0..<1.5, using: &rng))
                if params.life2 >= 0.5 {   // v2.19 A6: out of breath after running away
                    if lv(params.lifeBreath) { exert = max(exert, 0.8) }
                    lifeSt = .rest; lifeUntil = cowerUntil + 1 + Double.random(in: 0..<1, using: &rng)
                }
            }
        }
    }
    private func endIntro() {
        guard introOn else { return }
        introOn = false; introSq = 0; lastTouch = t - 0.8   // life fades in from the start; iv eases back to 1
    }
    private func introStep(_ dt: Double, _ h: Double) {
        introPT += dt
        var y1 = -1e9
        for i in bnd { y1 = max(y1, Y[i]) }
        let hh = R * (introN > 1 ? introHops[min(introK, 3)] : 0.3), v0 = sqrt(2 * R * introG * hh), tair = 2 * v0 / (R * introG)
        switch introPh {
        case .wait:   // a little wobble far away, as if it just saw you
            introSq = 0.05 * sin(min(1, introPT / 0.25) * .pi)
            if introPT >= 0.25 { introPh = .crouch; introPT = 0 }
        case .crouch:
            introSq = 0.14 * sin(min(1, introPT / 0.07) * .pi / 2)
            if introPT >= 0.07 {   // take-off: an upward velocity for the whole body (Verlet velocity = this substep minus the last)
                for i in 0..<N { PY[i] = Y[i] + v0 * h }
                introPh = .air; introPT = 0; introTair = tair
            }
        case .air:
            let q = min(1, introPT / introTair)
            introSq = -0.07 * sin(.pi * q)
            if introN > 1 { introU = min(1, (Double(introK) + q) / Double(introN)) }
            if introPT > introTair * 0.5 && y1 >= introFloor - 0.5 {
                introPh = .land; introPT = 0; introSq = 0
                if introN > 1 { introU = min(1, Double(introK + 1) / Double(introN)) }
                onEvent?(.fx(kind: "land", gain: 0.25 + 0.5 * ivS, delay: 0))
            }
        case .land:
            if introPT >= (introK + 1 >= introN ? 0.3 : 0.08) {
                introK += 1; introPT = 0
                if introK >= introN { endIntro() } else { introPh = .crouch }
            }
        }
    }
    // zoomMin 0 (v2.13, 多米: zoom out without limit): no floor on the zoom, the walls are at infinity (no walls)
    private var camMin: Double { params.zoomMin > 0 ? min(1, params.zoomMin) : 1e-4 }
    private var worldWalls: (l: Double, r: Double, t: Double, b: Double) {
        if sillOn, let g = sillG { return sillPlane == .room ? (g.l, g.r, 4, g.fl) : (-1e5, 1e5, -1e5, 1e5) }   // v2.28 窗台: the room is the world; v2.30 behind the bowl and outside the frame and the ledge do the holding
        if !(params.zoomMin > 0) { return (-.infinity, .infinity, -.infinity, .infinity) }
        let v = viewV, zm = camMin, ax = (W - 16) / 2 / zm, ay = (H - 210) / 2 / zm
        return (v.x - ax, v.x + ax, v.y - ay, v.y + ay)
    }

    // MARK: v2.64 B9 撞側牆出一聲（sndWall；網頁 WALLK、WALL、wallSides、wallStep，6ef0791；BATCH3 第 6 項、第 8 項之 6）
    // 原本身體撞到牆沒有聲音。側牆照現有的牆：窗台層是 worldWalls 的左右（窗台兩端，軟牆），在窗框上是左右窗框（sillHit 的 g.gx、g.jr），窗外沒有側牆；
    // 沒有窗台時是 worldWalls 的左右（鏡頭最遠的邊，zoomMin 0 時沒有牆）。
    // 每幀（物理小步跑完）看外框點：離某一面牆不到 near R 就算碰著，從沒碰著變碰著那一格出一聲；同一面要先離開超過 off R 才算下一次（貼著牆蠕動、呼吸不會一直響）。
    // 撞多快看整團（整團那一群的中心 clusters[gi]，網頁 globalC）往那面牆的速度，這一格和上一格取大（碰到那一格已經被牆擋掉一部分），單位每秒幾個 R。
    // v0 以下不響；v0 到 v1 之間音量 g0 到 g1、音高 r0 到 r1（越大力越低）。冷卻 cool 秒內不管哪面牆都不再響。
    // 音檔用現有的落地聲 fx.land（四個版本輪流抽，SlimeAudio.fx 同一種 0.25 秒只響一次，跟落地共用）。網頁沒有震動，所以走自己的事件 .wall，不走 .fx（.fx 的 land 會輕震）。
    // 冷卻用倒數，不存絕對時間；重建、補點、扯斷或合回、換層、重心一格跳超過 jump R、中間有幀沒跑（剛打開開關、時鐘倒回）都只重記，之後 settle 秒不響。
    // 只讀位置、不改物理、不抽亂數；0 不呼叫，跟改之前一樣。網頁的計數（WALL.n、sup、edge、log，給 T90 用）沒搬
    private enum WALLK { static let near = 0.05, off = 0.15, v0 = 2.0, v1 = 10.0, g0 = 0.15, g1 = 0.6, r0 = 1.04, r1 = 0.94, cool = 0.6, jump = 0.8, settle = 0.3 }
    // wallCX 上一格重心 x；wallN0 上一格的點數；wallB2 上一格有沒有扯斷的第二團；wallQT 還有幾秒不響；wallTL 上一格的時間；wallPL 上一格在哪一層；wallIn 左右碰著沒；wallV 上一格往左、往右多快（R/秒）；wallCD 冷卻倒數
    private var wallCX = 0.0, wallN0 = -1, wallB2 = false, wallQT = 0.0, wallTL = -9.0, wallPL = -2, wallIn = [true, true], wallV = [0.0, 0.0], wallCD = 0.0
    /// 網頁 wallSides：左右兩面側牆的 x（世界座標），nil = 沒有側牆
    private func wallSides() -> (l: Double, r: Double)? {
        if sillOn, let g = sillG {
            switch sillPlane {
            case .frame: return (g.gx, g.jr)
            case .out: return nil
            case .room: break
            }
        }
        let w = worldWalls
        return w.l.isFinite && w.r.isFinite && w.l > -1e4 ? (w.l, w.r) : nil
    }
    /// 網頁 wallStep：一幀一次，在物理小步、擺飾、推東西之後
    private func wallStep(_ dt: Double) {
        guard dt > 0, R > 0, !clusters.isEmpty, gi < clusters.count else { return }
        var pl = -1   // 網頁 SILL.on ? SILL.plane : '-'
        if sillOn {
            switch sillPlane {
            case .room: pl = 0
            case .frame: pl = 1
            case .out: pl = 2
            }
        }
        let sd = wallSides(), cx: Double = clusters[gi].xc, vc: Double = (cx - wallCX) / dt / R
        wallCD = max(0, wallCD - dt); wallQT = max(0, wallQT - dt)
        let fresh: Bool = wallN0 != N || abs(t - dt - wallTL) > 1e-6 || wallPL != pl || wallB2 != b2On || abs(cx - wallCX) > R * WALLK.jump
        wallTL = t; wallPL = pl; wallN0 = N; wallB2 = b2On; wallCX = cx
        if fresh { wallQT = WALLK.settle }
        guard let s = sd else { wallIn = [true, true]; wallV = [0, 0]; return }
        var dl = 1e9, dr = 1e9
        for i in bnd where i >= 0 && i < X.count {
            let x = X[i]
            if x - s.l < dl { dl = x - s.l }
            if s.r - x < dr { dr = s.r - x }
        }
        let quiet: Bool = wallQT > 0 || introOn || swimOn || clingOn
        let d: [Double] = [dl, dr], v: [Double] = fresh ? [0, 0] : [max(0, -vc), max(0, vc)]
        for k in 0..<2 {
            if wallIn[k] {
                if d[k] > R * WALLK.off { wallIn[k] = false }
            } else if d[k] < R * WALLK.near {
                wallIn[k] = true
                let sp: Double = max(v[k], wallV[k])
                if !quiet && wallCD <= 0 && sp >= WALLK.v0 {
                    let q: Double = min(1, (sp - WALLK.v0) / (WALLK.v1 - WALLK.v0))
                    let g: Double = WALLK.g0 + (WALLK.g1 - WALLK.g0) * q, r: Double = WALLK.r0 + (WALLK.r1 - WALLK.r0) * q
                    onEvent?(.wall(gain: g, rate: r))
                    wallCD = WALLK.cool
                }
            }
        }
        wallV = v
    }

    private var camRSt = 0.0, camRUntil = -9.0   // v2.24 camGrip: how far this grab pulled; until when a release may move the shape back in
    private func updateCam(_ dt: Double) {
        if sillOn {   // v2.28 窗台: the room does not move; v2.30 outside the view zooms out to 0.8 about the ledge's height, so the floor stays put on screen
            let q = viewV
            if sillZoom != sillZTG {
                sillZoom += (sillZTG - sillZoom) * (1 - exp(-dt / (sillGrab ? 0.1 : 0.4)))
                if abs(sillZoom - sillZTG) < 0.002 { sillZoom = sillZTG }
                camZ = sillZoom; camX = sillZPX - (sillZPX - q.x) / sillZoom; camY = sillZPY - (sillZPY - q.y) / sillZoom
                for f in fingers.values where f.mode == .grab {   // the patch under a finger stays under it while the view zooms
                    let p = toWorld(f.sx, f.sy), dx = p.x - f.x, dy = p.y - f.y
                    f.x = p.x; f.y = p.y; f.ax += dx; f.ay += dy; f.fx += dx; f.fy += dy
                    f.rawX += dx; f.rawY += dy; f.lastRawX += dx; f.lastRawY += dy
                    if slpTap === f { slpTapX += dx; slpTapY += dy }
                }
            } else {
                camZ = sillZoom; camX = sillZPX - (sillZPX - q.x) / sillZoom; camY = sillZPY - (sillZPY - q.y) / sillZoom
            }
            folX = camX; folY = camY; folVX = 0; folVY = 0; folChase = false
            return
        }
        let v = viewV, pad = R * (params.camPad > 0 ? params.camPad : 0.35)
        var x0 = 1e9, x1 = -1e9, y0 = 1e9, y1 = -1e9
        for i in bnd { x0 = min(x0, X[i]); x1 = max(x1, X[i]); y0 = min(y0, Y[i]); y1 = max(y1, Y[i]) }
        let ax = (W - 16) / 2, ay = (H - 210) / 2, zm = camMin
        // camFill (v2.13, 多米: as far as it is pulled): while grabbed the shape fills at most this much of the view, leaving room for
        // the finger; tight (v2.12) the finger at the screen edge was only pad beyond the shape and the pull stopped near 6R. Only while
        // grabbed: idle pods and breathing change the size all the time and the view would breathe with them
        // the margin comes in with the stretch (v2.14): from 0.5R pulled, full at 1.5R. Full margin from the first touch zoomed the
        // view the moment a finger landed on a shape near 70% of the view, moving the picture under the fingers (measured: in a
        // two-finger pinch the fingers' world distance stopped shrinking and a squish went missing)
        let grabs = fingers.values.filter { $0.mode == .grab }
        let grabbingNow = !grabs.isEmpty, stMax = grabs.map(\.stretch).max() ?? 0
        // v2.24 camGrip: untouched, the view looks at the remembered shape only, not the performance. A pseudopod reaching after a release made the
        // shape bigger, and with the bigger body the view zoomed out and in with it (measured: pull 70 pt and let go, z under 0.95, the edge jumping 40 pt)
        if params.camGrip >= 0.5 && !grabbingNow && !clusters.isEmpty {
            let g = clusters[gi], gx: Double = g.xc != 0 ? g.xc : cx, gy: Double = g.yc != 0 ? g.yc : cy
            x0 = 1e9; x1 = -1e9; y0 = 1e9; y1 = -1e9
            for i in bnd {
                let rx: Double = g.cs * QX[i] - g.sn * QY[i], ry: Double = g.sn * QX[i] + g.cs * QY[i]
                x0 = min(x0, rx); x1 = max(x1, rx); y0 = min(y0, ry); y1 = max(y1, ry)
            }
            x0 += gx; x1 += gx; y0 += gy; y1 += gy
        }
        // pulled, then let go: for 1.2 s a shape too close to the screen edge is moved back in (0.45R left for the next grab; if it fits nothing moves)
        if !grabbingNow { if camRSt > 0.25 { camRUntil = t + 1.2 }; camRSt = 0 }
        let rc: Bool = params.camGrip >= 0.5 && !grabbingNow && t < camRUntil
        // once the shape is big enough to zoom (v2.15), keep a margin even untouched (camFill + 0.1) and centre on the shape: otherwise
        // after a release the pulled end sits on the screen edge and grabbing it again leaves nowhere to pull (measured the device
        // way, pull to the edge, let go, grab again: 5 pulls reached 5.2R). Before, the resting finger dragged out by the view did it,
        // which was the twitch
        let cf = min(1, max(0.2, params.camFill)), big = camZ < 0.95 && cf < 1, idleFill = big ? min(1, cf + 0.1) : 1
        let fillK = max(0, min(1, stMax - 0.5)), fill = min(idleFill, 1 - (1 - cf) * fillK)
        let zt = max(zm, min(1, fill * ax / ((x1 - x0) / 2 + pad), fill * ay / ((y1 - y0) / 2 + pad)))
        let hx = ax / zt, hy = ay / zt
        func clampC(_ c: Double, _ lo: Double, _ hi: Double) -> Double { lo > hi ? (lo + hi) / 2 : max(lo, min(hi, c)) }
        // camCenter: centre on the shape when it is big or pulled, so the margin is ahead of the finger too (centred on home it sits behind)
        // v2.17 follow: untouched and not big, the view is no longer pinned at home nor forced to frame the whole body. Once the centre
        // is followZone (1 = half the view) off, chase it until close, on a critically damped spring (followSpeed 1.4: about 2 s, eased
        // start and stop). Still while grabbed: the picture must not slide under a finger
        let follow = params.camFollow >= 0.5 && !big && !grabbingNow && !introOn && !swimOn && !rc   // v2.23: swimming in, the view holds still
        // the target puts the slime back where it normally sits on screen (home cx, cy against the view centre), not dead centre;
        // the centre is the boundary mean (the centroid is still 0 on the first frame and the view thought it had run far)
        if follow, !bnd.isEmpty {
            var mx = 0.0, my = 0.0
            for i in bnd { mx += X[i]; my += Y[i] }
            mx /= Double(bnd.count); my /= Double(bnd.count)
            let zx = ax / camZ, zy = ay / camZ, dx = mx - (cx - v.x) - folX, dy = my - (cy - v.y) - folY, om = max(0.1, params.followSpeed)
            if !folChase && (abs(dx) > zx * params.followZone || abs(dy) > zy * params.followZone) { folChase = true }
            if folChase && hypot(dx / zx, dy / zy) < params.followStop { folChase = false }   // v2.18: stop near, not dead centre (pulled back to centre it looked like it never walked)
            let ex = folChase ? dx : 0, ey = folChase ? dy : 0
            folVX += (om * om * ex - 2 * om * folVX) * dt; folVY += (om * om * ey - 2 * om * folVY) * dt
            folX += folVX * dt; folY += folVY * dt
        } else {
            folX = camX; folY = camY; folVX = 0; folVY = 0; folChase = false
        }
        let fo = params.camFollow >= 0.5
        let cc = (big || grabbingNow && fillK > 0) && params.camCenter >= 0.5
        let ox = cc ? (x0 + x1) / 2 : fo ? folX : v.x, oy = cc ? (y0 + y1) / 2 : fo ? folY : v.y
        let fit = !fo || big || fillK > 0   // following, frame the whole body only when big or pulled (else grabbing a half-out body slides the view)
        var cxT = fit ? clampC(ox, x1 + pad - hx, x0 - pad + hx) : ox, cyT = fit ? clampC(oy, y1 + pad - hy, y0 - pad + hy) : oy
        if rc && !big { let m: Double = R * 0.45; cxT = clampC(camX, x1 + m - hx, x0 - m + hx); cyT = clampC(camY, y1 + m - hy, y0 - m + hy) }
        let k = follow ? 1 : 1 - exp(-dt / 0.35), kz = 1 - exp(-dt / 0.35)
        // v2.24 camGrip (measured on v2.23: pull 70 pt and hold, the view centred on the shape and the held patch ended 79 pt from the finger; pull 300 pt down, 145 pt):
        // while grabbed the view does not pan, it only zooms out about the finger when the shape no longer fits, so the point under the finger stays under it
        if params.camGrip >= 0.5 && grabbingNow {
            let z0 = camZ; camZ += (zt - camZ) * kz
            var sx = 0.0, sy = 0.0
            for f in grabs { sx += f.rawX; sy += f.rawY }
            sx /= Double(grabs.count); sy /= Double(grabs.count)
            let r: Double = z0 / camZ
            camX = sx - (sx - camX) * r; camY = sy - (sy - camY) * r
            camRSt = max(camRSt, stMax)
            return
        }
        camZ += (zt - camZ) * kz; camX += (cxT - camX) * k; camY += (cyT - camY) * k
    }   // press flat: pressing now, table height, remembered bottom below the centroid
    private var builtLimbs = -1.0, builtSize = -1.0, builtDens = -1.0

    final class Finger {
        var splitT = 0.0          // v2.62: how long it has been pulled far and fast enough to tear
        var tug: Bool? = nil      // v2.51: grabbed near the outline: it pulls a strand out, the body is not carried (nil = not judged yet)
        var r0x: Double? = nil, r0y = 0.0   // v2.61 A4: where it took hold, from the body's centre (r0x, r0y on the web; not the contact radius r0)
        var clD0: Double? = nil   // v2.36 黏牆: the finger's distance from the wall when it took hold; the pull is measured from there
        enum Mode { case grab, push, none, stroke }   // v2.26 F6 stroke: sliding over it, nothing pinned
        var propK = -1, hangN: String? = nil      // v2.64 擺飾變真: this finger holds props[propK] or the hanging one named hangN (mode .none, the web's 'prop')
        var ax, ay, x, y, fx, fy: Double            // anchor, chase target, lagged effective position
        var slx = 0.0, sly = 0.0, slLX = Double.nan, slLY = Double.nan   // v2.48 手指讓: how far the effective position has given way to the limits, and last frame's x, y (moving back takes it up again)
        var tgx = 0.0, tgy = 0.0, lagK = 1.0         // v2.38: this frame's target for (fx, fy) and the chase rate; chased after pairStep
        var sfD = 0.0, sfS = 0.0, sfTau = 0.0       // v2.64 B8 起步跟手（網頁 f.sfD、f.sfS、f.sfTau）：這次起步後真手指走了多遠（世界座標）、停了多久（秒）、這一格用的時間常數
        var rawX, rawY, lastRawX, lastRawY: Double   // real finger position (never a prediction)
        var predX = 0.0, predY = 0.0, hasPrediction = false, movedThisFrame = false
        var vx = 0.0, vy = 0.0                       // raw per-frame velocity of the real finger
        var vxS = 0.0, vyS = 0.0                     // ~30 ms smoothed
        var peak = 0.0                               // ~80 ms decaying peak speed, for the release pop
        var travel = 0.0, travelFrame = 0.0          // true distance travelled (coalesced touches): total, and since the last update
        var speedC = 0.0                             // smoothed travel rate, drives the rub sound
        var radius = 0.0                             // UITouch.majorRadius, points (0 = unknown)
        var r0 = 0.0, prS = 0.0                      // radius baseline at landing, smoothed radius pressure 0...1 (提案第 9 條)
        var gentleT = 0.0, strainT = 0.0             // v2.18: how long it has been a gentle stroke / a hard pull
        var tugT = 0.0, vMax = 0.0, yank = false     // v2.61 D1 (rough): pulled open this long, fast or slow (the tug back); the fastest this grab has been (R a second on screen, never decays); has it been yanked
        /// v2.61 C3 (petSlow), one stroke there and back. c = the body's centre when it was first counted (it stays put), s = where this pass set out, p = its farthest point, ml = how far that is;
        /// run = added on this pass, sum = added by this finger, out = pulled too far, nothing more counts
        struct PetPath { var cx, cy, sx, sy, px, py: Double; var ml = 0.0, run = 0.0, sum = 0.0, out = false }
        var pt: PetPath? = nil
        var hitT = -9.0, stillT = 0.0                // v2.19: last time a push touched the body (A4); how long it has been held still (breath tap)
        var ex = 0.0, ey = 0.0, sb = -1.0            // v2.20: the limited stretch vector; how far the body itself is pulled open (minus what followed), −1 = not yet
        var lure = false, edge = 0.0                 // v2.20 C1 C2: landed on empty space (left to lureStep); distance to the body's edge
        var tkA: Double?, pushed2 = false            // v2.22 E2: last heading (tickle turns), pushed back once
        var judge = false, slowT = 0.0, on = false, trD = 0.0, tGrab = -9.0, rBase = 0.0   // v2.26 F6: still to be judged (stroke or grab); how long slow; on the body; travel since the last trail point; when a stroke became a grab; contact size to compare with
        var grainI = 0, grR = 0.0, grT = -9.0        // v2.25 F5: press grains played, contact size at the last grain, its time
        var tkP = 0.0, far = false, reachN: Int?     // v2.24: travel since the last turn (tickle or rub); moved off its spot (0.15R, it is no longer just a press); mem count before the reach strip
        var saidProt = false, saidPurr = false       // v2.22 E1: protested / hummed once this grab
        var scared = false                           // v2.63 D3 (holdScared; web f.scared): held open while very wary, it protested this grab; it walks off when let go
        var dragMax = 0.0                            // v2.22: how far this grab dragged it (E3)
        var tickAt = 0.0, tickNext = 0.0             // texture ticks: travel at the last tick, spacing to the next (提案第 13 條)
        var step = 0
        var stretch = 0.0                            // tanh-limited stretch at the last update, in radii
        var om = 0.0, ov = 0.0                       // v2.63 B1 B3 (pullFx; web f.om, f.ov): the farthest the real finger got from where it took hold (radii), the speed it opens new ground (radii a second, 60 ms smoothed)
        let tDown: Double                            // rig time when the finger landed (dwell for plasticity)
        var press = 0.0, hold = 0.0, pressOn = false // press spread (points), hold level 0...1
        var pushed = false                           // push mode: has it displaced anything yet
        var over = 0.0                               // seconds past the slip threshold (候選 25)
        var sticking = false, releaseAt = 0.0         // lifted slowly: still holding until releaseAt (候選 26)
        var flatOn = false, h0 = 1.0, bot = 0.0, flat = 1.0   // press flat: began on the upper half; height and bottom then; current squash
        var sx = 0.0, sy = 0.0, psx = 0.0, psy = 0.0  // screen position (and prediction): the camera moves, so world is recomputed each frame
        var mode: Mode
        var reach = false                            // grabbed from inside out of reach of the boundary: add a strip once it moves (grabReach)
        var mem: [(i: Int, ox: Double, oy: Double, w: Double, dx: Double, dy: Double)] = []
        init(x: Double, y: Double, mode: Mode, time: Double) {
            ax = x; ay = y; self.x = x; self.y = y; fx = x; fy = y
            rawX = x; rawY = y; lastRawX = x; lastRawY = y
            tDown = time
            self.mode = mode
        }
    }
    private(set) var fingers: [ObjectIdentifier: Finger] = [:]

    init(params: FeelParams) {
        self.params = params
    }

    // MARK: - Shape definition (irregular blob + drooping tentacles)

    private struct LCG {
        var x: Int
        init(seed: Int) { x = seed * 9301 + 49297 }
        mutating func next() -> Double {
            x = (x * 9301 + 49297) % 233280
            return Double(x) / 233280
        }
    }

    /// v2.51 不規則外形 (web shape.js, same numbers and the same order of random draws): radius as a function of the angle, so the mesh builds as before.
    private struct Lump {
        var bumps: [(a: Double, k: Double, w: Double)] = []
        var p1 = 0.0, p2 = 0.0, k = 1.0, scale = 1.0
        func raw(_ a: Double) -> Double {
            var v: Double = 0.10 * sin(a) + 0.06 * cos(2 * a) + 0.04 * sin(3 * a + p1) + 0.025 * sin(5 * a + p2)
            for b in bumps {
                var d = a - b.a
                d = atan2(sin(d), cos(d))
                v += b.k * exp(-pow(d / b.w, 2))
            }
            return 1 + k * v
        }
        func r(_ a: Double) -> Double { raw(a) * scale }
    }
    private var lumpShape: Lump?
    private func makeLump(seed: Int, k: Double) -> Lump {
        var g = LCG(seed: seed * 13 + 5)
        let D = Double.pi / 180
        let side: Double = g.next() < 0.5 ? -1 : 1
        var s = Lump()
        s.k = k
        s.p1 = g.next() * 6.28; s.p2 = g.next() * 6.28
        let a1 = (-90 + side * (25 + g.next() * 35)) * D, k1 = 0.20 + g.next() * 0.12, w1 = 0.42 + g.next() * 0.14   // the bump on top, leaning to one side
        let a2 = (90 + side * (50 + g.next() * 30)) * D, k2 = 0.10 + g.next() * 0.08, w2 = 0.36 + g.next() * 0.12    // a smaller one low on the other side
        let a3 = (-90 - side * (40 + g.next() * 70)) * D, k3 = -(0.05 + g.next() * 0.05), w3 = 0.30 + g.next() * 0.10   // a shallow dip high on the other side
        s.bumps = [(a1, k1, w1), (a2, k2, w2), (a3, k3, w3)]
        var sum = 0.0
        let n = 360
        for i in 0..<n { let q = s.raw(Double(i) / Double(n) * .pi * 2); sum += q * q }
        s.scale = 0.98 / (sum / Double(n)).squareRoot()   // same area as the old blob
        return s
    }

    private func defineShape() {
        goo.removeAll(); twinDrop()   // v2.51: a rebuilt body starts whole; v2.62 one slime again
        lumpShape = Int(params.limbs.rounded()) <= 0 && params.lump > 0 ? makeLump(seed: Int(params.seed.rounded()), k: params.lump) : nil
        var r = LCG(seed: Int(params.seed.rounded()) * 7 + 3)
        ph = [r.next() * 6.28, r.next() * 6.28, r.next() * 6.28, (-72 + (r.next() - 0.5) * 30) * .pi / 180]
        // screen coords, y down: 90° is straight down. Most hang below or sideways.
        // v2.9: limbs 0 by default, no fixed tentacles (多米: not a starfish); what reaches out are the pseudopods
        // v2.27 (多米 11-05: many tentacles): more than 5 ring the body evenly; the old 5 stay for the starfish control
        let nLimb: Int = max(0, Int(params.limbs.rounded())), ring: Bool = nLimb > 5
        var base: [(Double, Double, Double)] = Array([(100, 2.1, 0.17), (55, 1.8, 0.15), (140, 1.65, 0.14), (8, 1.5, 0.14), (198, 1.35, 0.13)].prefix(min(5, nLimb)))
        if ring { base = (0..<nLimb).map { i -> (Double, Double, Double) in (360.0 * Double(i) / Double(nLimb) - 90.0, 1.32, 0.11) } }
        tent = base.map { item -> Tentacle in
            let (deg, L, w) = item
            let a = (deg + (r.next() - 0.5) * 22) * .pi / 180
            let curl = (r.next() - 0.5) * 0.6
            let droop: Double = ring ? 0.08 : 0.15 + 0.3 * max(0, -sin(a))
            let lScale: Double = ring ? 0.88 + r.next() * 0.22 : 0.85 + r.next() * 0.3
            return Tentacle(a: a, ux: cos(a), uy: sin(a), L: L * lScale, w: w * (0.85 + r.next() * 0.3),
                            curl: curl, droop: droop)
        }
        for k in tent.indices {
            let b = blobR(tent[k].a)
            tent[k].uExit = min(0.8, max(0, (b * 0.95 - b * 0.35) / (tent[k].L - b * 0.35)))
        }
    }

    /// Blob radius in units of R, with the head bump on top.
    private func blobR(_ a: Double) -> Double {
        // no tentacles: one lump, no head bump, a little bigger to keep the tentacles' mass
        if tent.isEmpty, let s = lumpShape { return s.r(a) }   // v2.51
        if tent.isEmpty { return 0.98 + 0.07 * sin(2 * a + ph[0]) + 0.05 * sin(3 * a + ph[1]) + 0.03 * sin(5 * a + ph[2]) }
        if tent.count > 5 { return 0.72 + 0.05 * sin(2 * a + ph[0]) + 0.03 * sin(3 * a + ph[1]) + 0.02 * sin(5 * a + ph[2]) }   // v2.27 ringed tentacles: no head bump
        var d = a - ph[3]
        d = atan2(sin(d), cos(d))
        return 0.78 + 0.10 * sin(2 * a + ph[0]) + 0.07 * sin(3 * a + ph[1]) + 0.04 * sin(5 * a + ph[2]) + 0.24 * exp(-pow(d / 0.38, 2))
    }

    /// Which tentacle a rest-space point is in, how far along it (0 root, 1 tip), and how close to the axis.
    private func tentHit(_ x: Double, _ y: Double) -> (k: Int, u: Double, q: Double)? {
        var best: (k: Int, u: Double, q: Double)?
        for k in tent.indices {
            let tt = tent[k], r0 = blobR(tt.a) * R * 0.35
            let sx = tt.ux * r0, sy = tt.uy * r0, ex = tt.ux * tt.L * R, ey = tt.uy * tt.L * R
            let dx = ex - sx, dy = ey - sy, len2 = dx * dx + dy * dy
            var u = ((x - sx) * dx + (y - sy) * dy) / len2
            u = max(0, min(1, u))
            let px = sx + dx * u, py = sy + dy * u, d = hypot(x - px, y - py), w = tt.w * R * (tent.count > 5 ? 1.7 - 0.85 * u : 1 - 0.12 * u)
            if d < w && (best == nil || d / w < best!.q) { best = (k, u, d / w) }
        }
        return best
    }

    private func inside(_ x: Double, _ y: Double) -> Bool {
        let a = atan2(y, x)
        if hypot(x, y) < blobR(a) * R { return true }
        return tentHit(x, y) != nil
    }

    /// Ray-march the union's outer radius along angle a.
    private func restR(_ a: Double) -> Double {
        let c = cos(a), s = sin(a), step = R / 150
        var last = 0.0, tt = 0.0
        while tt <= R * 2.6 {
            if inside(c * tt, s * tt) { last = tt }
            tt += step
        }
        return last
    }

    // MARK: - Setup

    func setup(width: Double, height: Double) {
        W = width; H = height
        sillOn = effParams.scene >= 0.5   // v2.28 窗台
        R = max(60, min(W * effParams.bodySize, H * 0.18, 160))   // bodySize: 0.26 before v2.9, 0.22 v2.10 to v2.23, 0.30 v2.24 (about 4 cm wide; a finger is 1.6 to 2 cm)
        cx = W / 2
        defineShape()

        // boundary: scan a fine polar polygon, then resample evenly by arc length
        // (angle-even sampling misses the thin tentacles)
        let fine = 1440
        var poly: [(Double, Double)] = []
        poly.reserveCapacity(fine)
        for i in 0..<fine {
            let a = -.pi / 2 + Double(i) / Double(fine) * .pi * 2, r = restR(a)
            poly.append((cos(a) * r, sin(a) * r))
        }
        cy = H * params.homeFrac; builtHome = params.homeFrac   // 候選 33: 0.40H, or 0.46H for the one-hand test
        homeX = cx; homeY = cy
        h = R / max(4, params.dens)   // dens (v2.13): particles per radius; a long pull spreads the boundary out
        var cum = [0.0]
        cum.reserveCapacity(fine + 1)
        for i in 1...fine {
            let a = poly[i - 1], b = poly[i % fine]
            cum.append(cum[i - 1] + hypot(b.0 - a.0, b.1 - a.1))
        }
        let per = cum[fine]
        let M = max(60, Int((per / (h * 1.05)).rounded()))
        var pts: [(Double, Double)] = []
        bnd = []
        var j = 0
        for m in 0..<M {
            let target = Double(m) / Double(M) * per
            while cum[j + 1] < target { j += 1 }
            let span = cum[j + 1] - cum[j]
            let f = span > 0 ? (target - cum[j]) / span : 0
            let a = poly[j], b = poly[(j + 1) % fine]
            bnd.append(pts.count)
            pts.append((a.0 + (b.0 - a.0) * f, a.1 + (b.1 - a.1) * f))
        }
        // interior: hex grid, kept away from the boundary
        var row = 0
        var gy = -2.7 * R
        while gy <= 2.7 * R {
            var gx = -2.7 * R + (row % 2 == 1 ? h / 2 : 0)
            while gx <= 2.7 * R {
                if inside(gx, gy) {
                    var dmin = 1e9
                    for b in 0..<M {
                        let d = hypot(pts[b].0 - gx, pts[b].1 - gy)
                        if d < dmin { dmin = d }
                    }
                    if dmin > h * 0.7 { pts.append((gx, gy)) }
                }
                gx += h
            }
            gy += h * 0.87
            row += 1
        }
        N = pts.count

        X = [Double](repeating: 0, count: N); Y = X; PX = X; PY = X
        Q0X = X; Q0Y = X; QX = X; QY = X; EX = X; EY = X
        GX = X; GY = X; GW = X; RX = X; RY = X; GWT = X
        TU = X; TUB = X; KF = X
        TID = [Int](repeating: -1, count: N); BIDX = [Int](repeating: -1, count: N)
        GRAB = [Bool](repeating: false, count: N)

        for i in 0..<N {
            Q0X[i] = pts[i].0; Q0Y[i] = pts[i].1
            let ht = tentHit(pts[i].0, pts[i].1)
            let inBlob = hypot(pts[i].0, pts[i].1) < blobR(atan2(pts[i].1, pts[i].0)) * R * 0.9
            if let ht, !inBlob {
                TID[i] = ht.k; TU[i] = ht.u
                let ue = tent[ht.k].uExit
                TUB[i] = max(0, (ht.u - ue) / (1 - ue))
                KF[i] = 1 - params.floppy * ht.u
            } else {
                TID[i] = -1; TU[i] = 0; TUB[i] = 0; KF[i] = 1
            }
        }
        // rest pose: tentacles curl and droop. A smooth deformation of the rest shape starting at
        // the junction (zero there), so boundary order stays valid.
        for i in 0..<N {
            let k = TID[i]
            if k < 0 { continue }
            let tt = tent[k], u = TUB[i], u2 = u * u
            Q0X[i] += -tt.uy * tt.curl * u2 * R * 0.45
            Q0Y[i] += tt.ux * tt.curl * u2 * R * 0.45 + tt.droop * u2 * R
        }
        // zero-mean rest shape: the same basis plasticity recenters to every frame
        var mx = 0.0, my = 0.0
        for i in 0..<N { mx += Q0X[i]; my += Q0Y[i] }
        mx /= Double(N); my /= Double(N)
        for i in 0..<N {
            Q0X[i] -= mx; Q0Y[i] -= my
            QX[i] = Q0X[i]; QY[i] = Q0Y[i]
            X[i] = cx + Q0X[i]; Y[i] = cy + Q0Y[i]; PX[i] = X[i]; PY[i] = Y[i]
        }
        H0X = Q0X; H0Y = Q0Y; remN = 0; remN0 = N; remLast = -9; remCalm = -9; homeRing()   // v2.54 補點
        for k in tent.indices {   // v2.27 tentSlip, tentBump, tentRest
            tent[k].all = (0..<N).filter { TID[$0] == k }
            tent[k].root = tent[k].all.filter { TUB[$0] < 0.08 }
            tent[k].edge = bnd.filter { TID[$0] == k && TUB[$0] > 0.15 }
            tent[k].s = 1; tent[k].bumpT = -9
        }
        buildClusters()
        bndL = []
        for k in 0..<bnd.count {
            let i = bnd[k], jj = bnd[(k + 1) % bnd.count]
            bndL.append(hypot(Q0X[jj] - Q0X[i], Q0Y[jj] - Q0Y[i]))
        }
        bndL2 = (0..<bnd.count).map { k in
            let i = bnd[k], j = bnd[(k + 2) % bnd.count]
            return hypot(Q0X[j] - Q0X[i], Q0Y[j] - Q0Y[i])
        }
        for k in 0..<bnd.count { BIDX[bnd[k]] = k }
        buildRungs()
        buildMesh()   // v2.29 防打結
        // highlight rides on the upper-left of the blob
        var bd = 1e9
        for i in 0..<N where TID[i] < 0 {
            let d = hypot(Q0X[i] + R * 0.28, Q0Y[i] + R * 0.32)
            if d < bd { bd = d; hiIdx = i }
        }
        do {   // v2.26 F7: the highlight bends with the skin around it, fitted like a dent
            let h = Dent(i: hiIdx, finger: nil), rr: Double = R * 0.3
            for i in 0..<N where i != hiIdx {
                let ox: Double = Q0X[i] - Q0X[hiIdx], oy: Double = Q0Y[i] - Q0Y[hiIdx]
                if ox * ox + oy * oy < rr * rr { h.nb.append((i, ox, oy)) }
            }
            hiDent = h
        }
        fingers.removeAll()
        A0 = polygonArea()
        builtSeed = params.seed; builtFloppy = params.floppy; builtLimbs = params.limbs; builtSize = params.bodySize; builtDens = params.dens; builtScene = params.scene
        pods = []; podClock = 0; podNext = 0.5; podShift = 0; podE = []; brJw = 0; brLift = 0; flatOn = false
        camZ = 1; camX = viewV.x; camY = viewV.y
        folX = viewV.x; folY = viewV.y; folVX = 0; folVY = 0; folChase = false
        introOn = false; introSq = 0; ivS = 1; ivOX = 0; ivOY = 0
        moodC = 0; moodA = 0; moodStrain = 0; moodStrainMax = 0; moodScare = 0; cowerUntil = -9; happyT = -9; wagT = -9; taps = []
        tugX = 0; tugY = 0; escOn = false; purr = 0
        moodTugS = 0; petReset(); flTc = 1; flTapQ = false; flTapAt = -9   // v2.61 D1 D2 C3 (the fingers' own go with the fingers)
        bondLastT = -9; flBk = 0; sooOn = false; sooG = 0; sooOK = false   // v2.63 D6 (web setup: the same): the clock set back, the last hold must not sit in the future
        dentList.removeAll()
        t = 0; lastTouch = -10; nextTwitch = 3; relaxUntil = -1
        tLife = 0; releaseCount = 0; nextSpecial = 0; specialUntil = -1
        wanderMoving = false; wanderNext = 3; wanderVX = 0; wanderVY = 0
        brPhase = 0; brPrev = 0; brAmp = 1; brWave = 0; brDeepAt = -99; brGrabStart = -1; pinchA = nil; pinchB = nil
        // v2.19
        lifeSt = .rest; lifeUntil = -1; lifeLooks = 0; lifeNoGo = false; sniffs = []; attOn = false; lifeWrg = 1; goFade = 0; arrT = -9; arrOff = 0
        gaitOn = false; gaitK = 1; gaitOff = 0; gaitV = 0; flAt = -9; flSay = nil; flxSndT = -9; flxRelT = -9; flT0 = -9; flAmp = 0; flH = 1; flS = 1; shkAt = -9; shkT0 = -9; shkAmp = 0; shkTh = 0
        exert = 0; sighNext = -1; sighCyc = -1; pauseUntil = -9; brAmpX = 1; brCyc = 0; strK = 1; psm = (1, 0, 0, 1); lifeLB = 1
        // v2.20: a rebuild drops the fingers without a release, so the offset must go too or home stays off (measured on the web:
        // later tests leaned with it, a 3 s press moved 61 pt instead of 30)
        dragOX = 0; dragOY = 0; dragVX = 0; dragVY = 0; dragBX = 0; dragBY = 0; dragGX = 0; dragGY = 0; dragSlipT = 0; lureOn = false; lureSn = -1; askOn = false
        e4On = false; e4Wait = -1   // v2.22
        leanT = -9; leanO = 0; nuzT0 = -1; nuzO = 0; nuzSaid = false; tkTimes = []; tkT = 0; gigNext = 0; camRSt = 0; camRUntil = -9
        rubvBag = []; rubvLast = ""; rubvHopT = -99; rubvSpT = -9   // v2.63 C6: the clock set back, the last hop and the melting must not sit in the future
        tbAt = -9; tbRel = -9; tbFire = -9; tbUntil = -9; sblAcc = 0; sblT0 = -9; sblS = brain.seed ^ 0x27d4_eb2f; sblGap = SBLK.lo + (SBLK.hi - SBLK.lo) * sblRnd()   // v2.64 D8（網頁 setup：Object.assign(TB,…)、Object.assign(SBL,…)）：排好的頂回來、慢眨跟著重建清掉；慢眨自己那串亂數從大腦的種子接，rng 不多抽
        ltCur = nil; ltReactQ = nil; ltHabT = [:]; ltS = brain.seed ^ 0x5bd1_e995   // v2.64 C5（網頁 setup：Object.assign(LT,…)）：排好的反應、看過的對象跟著重建清掉；自己那串亂數從大腦的種子接（brainReset 不動種子，所以放在 brain.reset 前後都一樣）
        QDX = QX; QDY = QY; QVX = [Double](repeating: 0, count: N); QVY = QVX; QW = QVX; cvX = 0; cvY = 0; caX = 0; caY = 0; cpX = nil; cpY = nil; tickLastT = -9   // v2.25
        stkOX = 0; stkOY = 0; stkVX = 0; stkVY = 0; stkG = 0; stkLast = -9; stkSaid = false; stkPet = false; trail = []   // v2.26
        eyeSetup(); slpOn = false; slpK = 0; slpLastAny = -99; slpAskAt = -9; slpNearT = 0; flBoost = 1   // v2.23 (setup restarts the clock)
        slpWakeT = -9; voiceLast = -9; e4LastT = -99; impAskUntil = -9   // v2.61: the same clock; left in the old one the next slime kept its eyes wide, said nothing and did not come for as long as the last one had been out
        slpOpenT = t; slpSlow = false; slpTap = nil; slpTapN = 0; slpTapT0 = -9; slpTapDone = false; slpRollT = -9; slpRollD = 1; slpRollO = 0   // v2.61 C1 (the clock restarts here, so openT does too: 40 s from now)
        sgAcc = 0; sgGap = -1; sgOn = nil; sgQ = []; sgEye = nil; sgS = brain.seed ^ 0x1b87_3593; sgWk = slpWakeT; wallN0 = -1; wallCD = 0   // v2.64 B9（網頁 setup：WALL.n0=-1;WALL.cd=0）：重建後撞牆先重記、冷卻清掉。v2.64 C8（網頁 setup：Object.assign(SG,…)）：排好的招牌跟著重建清掉；間隔第一次用到時才抽（自己那串亂數，從大腦的種子接）；放在 slpWakeT 歸零後面
        napCum = 0; napOn = false; napN = 0   // v2.63 C9 (web setup, with SLP: Object.assign(NAP,{cum:0,on:false,n:0})): a slime switch, a rebuild, a rotation start this opening's count again
        greetWait = false; greetAt = -9; greetT0 = -9; greetUntil = -9   // v2.63 C4: the same clock (the web's setup keeps its clock, so it needs none of this); startIntro arms it again
        echoSt = 0; echoTaps = []; echoJoyUntil = -9; echoPrevT = -99; echoBeatT = -9; swimOn = false
        drReset()   // v2.64 擺飾變真 (web brainReset: drReset())
        brain.reset(t, ev: brainEv())   // v2.63 大腦 (web setup: brainReset()); startIntro draws the opening's needs (brainJit). After echoJoyUntil: the clock restarts here, an old one would hide the next 回你的節奏 from the mood
        SX2 = Array(repeating: 0, count: N); SY2 = Array(repeating: 0, count: N)
        CAPG = 1; CAPGAP = 0   // v2.54
        pullStillT = 0   // v2.61
        sillInit()   // v2.28 窗台: last, it moves the body over the bowl and lets it drop
        shkReset()   // v2.31 搖晃沉澱: clear, the glitter in a pile
    }

    /// v2.29 防打結: Delaunay (Bowyer-Watson) over the rest shape, keeping the triangles whose centre is inside the boundary ring,
    /// wound counter-clockwise, with their rest areas. Port of the web's `buildMesh`.
    private func buildMesh(fast: Bool = false) {
        let n = N
        guard n >= 3, bnd.count >= 3 else { TRI = []; TRA = []; return }
        var xs = Q0X + [0, 0, 0], ys = Q0Y + [0, 0, 0]
        var x0 = 1e9, x1 = -1e9, y0 = 1e9, y1 = -1e9
        for i in 0..<n { x0 = min(x0, xs[i]); x1 = max(x1, xs[i]); y0 = min(y0, ys[i]); y1 = max(y1, ys[i]) }
        let d = max(x1 - x0, y1 - y0) * 20
        xs[n] = x0 - d; ys[n] = y0 - d; xs[n + 1] = x1 + d; ys[n + 1] = y0 - d; xs[n + 2] = (x0 + x1) / 2; ys[n + 2] = y1 + d
        struct Tri { let a, b, c: Int; let ux, uy, r, right: Double }
        func circ(_ a: Int, _ b: Int, _ c: Int) -> Tri {
            let ax = xs[a], ay = ys[a], bx = xs[b], by = ys[b], cx = xs[c], cy = ys[c]
            let D: Double = 2 * (ax * (by - cy) + bx * (cy - ay) + cx * (ay - by))
            let A: Double = ax * ax + ay * ay, B: Double = bx * bx + by * by, C: Double = cx * cx + cy * cy
            let ux: Double = (A * (by - cy) + B * (cy - ay) + C * (ay - by)) / D
            let uy: Double = (A * (cx - bx) + B * (ax - cx) + C * (bx - ax)) / D
            let r: Double = (ax - ux) * (ax - ux) + (ay - uy) * (ay - uy)
            return Tri(a: a, b: b, c: c, ux: ux, uy: uy, r: r, right: ux + r.squareRoot())
        }
        // v2.54 (補點 rebuilds the mesh while held, so it has to be quick): points go in left to right; a triangle whose circle ends left of
        // the current point can never be broken again and is set aside. The same triangulation, about ten times faster.
        // fast only for the re-sample; building the body keeps the old insertion order (the triangle order sets the order the constraints
        // run in each substep; measured on the web with the new order, T62's downward pull jittered 1.2 → 3.9)
        let order: [Int] = fast ? (0..<n).sorted { xs[$0] < xs[$1] || (xs[$0] == xs[$1] && $0 < $1) } : Array(0..<n)
        var T = [circ(n, n + 1, n + 2)], done: [Tri] = []
        var keep: [Tri] = [], E: [(a: Int, b: Int, dup: Bool)] = []
        for i in order {
            keep.removeAll(keepingCapacity: true); E.removeAll(keepingCapacity: true)   // edges of the triangles this point falls into; an edge seen twice is inside the hole
            let px = xs[i], py = ys[i]
            for q in T {
                if fast && q.right < px { done.append(q); continue }
                let ex = px - q.ux, ey = py - q.uy
                if ex * ex + ey * ey < q.r {
                    for (a, b) in [(q.a, q.b), (q.b, q.c), (q.c, q.a)] {
                        if let k = E.firstIndex(where: { ($0.a == a && $0.b == b) || ($0.a == b && $0.b == a) }) { E[k].dup = true } else { E.append((a, b, false)) }
                    }
                } else { keep.append(q) }
            }
            swap(&T, &keep)
            for e in E where !e.dup { T.append(circ(e.a, e.b, i)) }
        }
        T += done
        let nb = bnd.count
        func inRing(_ x: Double, _ y: Double) -> Bool {
            var c = false
            var j = nb - 1
            for i in 0..<nb {
                let ax = Q0X[bnd[i]], ay = Q0Y[bnd[i]], bx = Q0X[bnd[j]], by = Q0Y[bnd[j]]
                if (ay > y) != (by > y) && x < (bx - ax) * (y - ay) / (by - ay) + ax { c.toggle() }
                j = i
            }
            return c
        }
        var tri: [Int] = [], area: [Double] = []
        for q in T {
            if q.a >= n || q.b >= n || q.c >= n { continue }
            let mx = (xs[q.a] + xs[q.b] + xs[q.c]) / 3, my = (ys[q.a] + ys[q.b] + ys[q.c]) / 3
            if !inRing(mx, my) { continue }
            let s: Double = 0.5 * ((xs[q.b] - xs[q.a]) * (ys[q.c] - ys[q.a]) - (ys[q.b] - ys[q.a]) * (xs[q.c] - xs[q.a]))
            if abs(s) < 1e-6 { continue }
            if s > 0 { tri.append(q.a); tri.append(q.b); tri.append(q.c) } else { tri.append(q.a); tri.append(q.c); tri.append(q.b) }
            area.append(abs(s))
        }
        TRI = tri; TRA = area
        // v2.47: the edges, each once, for memSmoothStep
        var seen = Set<Int>(), ed: [Int] = [], deg = [Double](repeating: 0, count: n)
        var k = 0
        while k + 2 < tri.count {
            for (a, b) in [(tri[k], tri[k + 1]), (tri[k + 1], tri[k + 2]), (tri[k + 2], tri[k])] {
                let key = a < b ? a * 100000 + b : b * 100000 + a
                if seen.insert(key).inserted { ed.append(a); ed.append(b); deg[a] += 1; deg[b] += 1 }
            }
            k += 3
        }
        EDG = ed; EDEG = deg; EDSX = [Double](repeating: 0, count: n); EDSY = [Double](repeating: 0, count: n)
        var el: [Double] = []
        el.reserveCapacity(ed.count / 2)
        var e = 0
        while e + 1 < ed.count { el.append(hypot(Q0X[ed[e]] - Q0X[ed[e + 1]], Q0Y[ed[e]] - Q0Y[ed[e + 1]])); e += 2 }
        EDL = el; SLX = [Double](repeating: 0, count: n); SLY = [Double](repeating: 0, count: n); HIT = [Bool](repeating: false, count: n); QSTR = 1
    }

    /// v2.48 every bit of the body has hard limits (多米 11-16: pulled about it often "breaks", past some range it twitches, knots, turns into irregular spikes;
    /// fix it at the source). Each mesh edge may be at most `hi` and at least `lo` times its rest length. The pull used to pile onto the few particles by the
    /// finger (measured: edges at 12 to 35 times rest, their neighbours at 1): those few are the spike, the whisker, the flipped triangles. With a limit, once
    /// the ones by the finger are full the next ones stretch, the whole strand lengthens evenly, and past that the whole body is dragged along.
    /// `live`: the live body (X, Y): held particles move less on a stretch (capGrabW) and fully on a squeeze (capPushW), a particle a wall stopped last substep
    /// hardly moves on a squeeze, corrections carry no velocity (capVel), squeeze corrections on held particles are summed for the finger to give way by,
    /// and a wall sucker pulled past the limit lets go. Port of the web's `strainStep`. Returns whether anything was over.
    private func strainStep(_ AX: inout [Double], _ AY: inout [Double], _ lo: Double, _ hi: Double, _ live: Bool, _ mat: FeelParams) -> Bool {
        let m = EDG.count
        guard m > 0, EDL.count * 2 == m, SLX.count == N, HIT.count == N else { return false }
        let gw: Double = mat.capGrabW, gp: Double = mat.capPushW, kv: Double = 1 - mat.capVel
        let pins: Bool = live && clingOn && clingAX.count == N
        var any = false
        var e = 0, k = 0
        while e + 1 < m {
            let i = EDG[e], j = EDG[e + 1]
            let dx: Double = AX[j] - AX[i], dy: Double = AY[j] - AY[i]
            let d: Double = (dx * dx + dy * dy).squareRoot(), r: Double = EDL[k]
            e += 2; k += 1
            let tg: Double = d > r * hi ? r * hi : (d < r * lo ? r * lo : 0)
            if tg == 0 || d < 1e-9 { continue }
            any = true
            if live { if d < tg { grdLo = true } else { grdHi = true } }   // v2.52 A5
            var pi = false, pj = false
            if pins {
                pi = !clingAX[i].isNaN; pj = !clingAX[j].isNaN
                // the suckers give way too: both ends pinned and still over, or a pinned end pulled to 1.3 times the limit, and that sucker lets go
                if (pi && pj) || ((pi || pj) && d > r * hi * 1.3) { clingFree(pi ? i : j) }
            }
            let sq: Bool = d < tg
            let gi: Bool = live && GRAB[i], gj: Bool = live && GRAB[j]
            var wi: Double = gi ? (sq ? gp : gw) : (pi ? gw : 1)
            var wj: Double = gj ? (sq ? gp : gw) : (pj ? gw : 1)
            if sq && live { if HIT[i] { wi *= 0.05 }; if HIT[j] { wj *= 0.05 } }
            let ws: Double = wi + wj
            if ws < 1e-9 { continue }
            let q: Double = (d - tg) / d / ws
            let ix: Double = dx * q * wi, iy: Double = dy * q * wi, jx: Double = -dx * q * wj, jy: Double = -dy * q * wj
            AX[i] += ix; AY[i] += iy; AX[j] += jx; AY[j] += jy
            if live {
                if kv > 0 { PX[i] += ix * kv; PY[i] += iy * kv; PX[j] += jx * kv; PY[j] += jy * kv }   // the last position moves along: the correction leaves no velocity
                if sq {
                    if gi { SLX[i] += ix; SLY[i] += iy }
                    if gj { SLX[j] += jx; SLY[j] += jy }
                }
            }
        }
        return any
    }

    /// v2.47 the remembered shape smooths its own spikes (like surface tension). Memory is per particle: the few under the finger are pulled much farther than
    /// their neighbours and a spike or a thin whisker stays after the release (多米's phone video, 11-16). Every frame the offset from the rest shape is smoothed
    /// twice over the mesh, once toward the neighbours' mean and once back by as much: only detail that differs a lot between neighbours goes, a whole pulled
    /// strand or a flat spread barely moves. `rate` (memSmooth) is how much of that detail goes a second. Port of the web's `memSmoothStep`.
    private func memSmoothStep(_ dt: Double, _ rate: Double) {
        let m = EDG.count
        guard m > 0, EDEG.count == N, EDSX.count == N, EDSY.count == N else { return }
        let lam: Double = min(0.45, (rate * dt).squareRoot())
        for pass in 0..<2 {
            for i in 0..<N { EDSX[i] = 0; EDSY[i] = 0 }
            var e = 0
            while e + 1 < m {
                let i = EDG[e], j = EDG[e + 1]
                let dx: Double = (QX[j] - H0X[j]) - (QX[i] - H0X[i]), dy: Double = (QY[j] - H0Y[j]) - (QY[i] - H0Y[i])   // v2.54: against the original lump (H0), not the rest shape, which holds the corners after a re-sample
                EDSX[i] += dx; EDSY[i] += dy; EDSX[j] -= dx; EDSY[j] -= dy
                e += 2
            }
            let k: Double = pass == 0 ? lam : -lam
            for i in 0..<N where EDEG[i] > 0 { QX[i] += k * EDSX[i] / EDEG[i]; QY[i] += k * EDSY[i] / EDEG[i] }
        }
    }

    /// v2.29 防打結: every triangle whose area fell below `kp` of its rest area is pushed back open along the area's gradient.
    /// `grab` (the GRAB flags) lets the held particles move a quarter as much. One particle moves at most 0.4 spacing a call,
    /// so a triangle that flipped all the way does not fling the body. Port of the web's `meshGuard`.
    /// v2.38: corners of flipped triangles (no memory there) and how many are flipped (is the remembered shape flipped). Web `flipMarks`, `flipCount`.
    /// v2.54 無限拉: a triangle pressed flat on the sill, or a long thin one that tipped over by a hair after a long pull, does not count as
    /// flipped (neither shows; counted, nothing of the pull was remembered and it shrank back on release). Web `flipTol`.
    private func flipTol(_ k: Int) -> Double { effParams.endless >= 0.5 && k / 3 < TRA.count ? -0.1 * TRA[k / 3] : 0 }
    // MARK: - v2.54 快扯變硬、慢拉變軟 (web `rateStep`)

    /// How fast the grabbing finger moves (radii a second; up in 0.05 s, down in 0.25 s) sets the body's stiffness while held: below
    /// rateLo it is softest (shape matching ×(1−0.35·rateK)), above rateHi stiffest (×(1+2·rateK)), it remembers less (×(1−0.95·rateK)) and
    /// the edge limits widen slower (×(1−0.5·rateK)): a yank barely stretches and springs back, a slow pull keeps growing and stays.
    private var rateV = 0.0, rateG = 0.0
    private(set) var rateS = 0.0
    private var rateKA = 1.0, rateKC = 1.0, rateKG = 1.0
    private func rateStep(_ dt: Double) {
        let mat = effParams
        var v = 0.0, held = false
        for f in fingers.values where f.mode == .grab { held = true; v = max(v, hypot(f.vx, f.vy) / R) }
        rateV += (v - rateV) * (1 - exp(-dt / (v > rateV ? 0.05 : 0.25)))
        rateG += ((held ? 1 : 0) - rateG) * (1 - exp(-dt / 0.1))
        let K: Double = mat.rateK > 0 ? mat.rateK : 0, lo: Double = mat.rateLo > 0 ? mat.rateLo : 4, hi: Double = max(lo + 0.1, mat.rateHi > 0 ? mat.rateHi : 14)
        let x: Double = max(0, min(1, (rateV - lo) / (hi - lo)))
        rateS = x * x * (3 - 2 * x)
        let g = rateG * K
        rateKA = 1 + g * (-0.35 + 2.35 * rateS); rateKC = 1 - 0.95 * g * rateS; rateKG = 1 - 0.5 * g * rateS
    }

    /// v2.54 拉力 (多米 11-22: the vibration follows how hard you pull): 0...1, from how long the pull is (a long pull keeps rising, about
    /// 0.5 at 3R, 0.8 at 8R) plus how far the held patch trails the finger (a yank against the stiff body is felt at once).
    var pullTension: Double {
        guard isGrabbing else { return 0 }
        let st = max(0, pullStretch - 0.3)
        let len: Double = 1 - exp(-st / 4.5), lag: Double = min(1, CAPGAP / 0.8)
        return min(1, 0.8 * len + 0.45 * lag * (0.4 + 0.6 * rateS))
    }

    // MARK: - v2.54 拉長時自動補點 (web `remeshCheck`, `remesh`)

    /// The particle count was fixed when the body was built; pulled long, the points thin out: the outline turns into straight runs, long
    /// thin triangles flip at a twitch, nothing is remembered. When an outline edge of the remembered shape (Q) is longer than remeshHi
    /// point spacings, or an edge inside is past remeshStr × rest, the body is sampled again from the remembered shape (outline evenly,
    /// a hex grid inside, the same spacing). Each new point finds its triangle in the old mesh and takes position, velocity, the return
    /// target (H0) and the finger weights from its three corners, so nothing visibly jumps; mesh, clusters and rest lengths come from the
    /// new shape (Q0 becomes the remembered shape) and CAPG returns to 1. Going back, points too close (outline under remeshLo spacings or
    /// an edge under 0.45 × rest) with more points than at build time: sampled again, fewer. At most remeshMaxN × the build count.
    /// Not while crossed, stuck to an edge, with fixed tentacles or a second lump.
    private func remeshCheck(_ dt: Double) {
        let mat = effParams
        guard mat.remesh >= 0.5, mat.endless >= 0.5, tent.isEmpty, !b2On, !clingOn, !EDG.isEmpty, H0X.count == N, EDL.count * 2 == EDG.count else { return }
        remChk += dt
        guard remChk >= 0.1, t - remLast >= 0.2 else { return }
        remChk = 0
        let home = mat.remeshHome >= 0.5
        if home && !fingers.values.contains(where: { $0.mode != .none }) {   // v2.58: let go, back to the mesh it was built with
            let shortEnough: Bool = !(mat.pullSoft >= 0.5) || memLen() < PullSet.homeLen * HRC[HRX.count]   // v2.61 A2 (bl): not until what it remembers is back under 1.35× the built outline
            if remN > 0, HB.count == bnd.count, shortEnough, remesh(back: true) { remN = 0; remCalm = t + max(0, mat.remeshCalm); remLast = t }
            return
        }
        let nb = bnd.count
        var bmax = 0.0, bmin = 1e9
        for k in 0..<nb { let i = bnd[k], j = bnd[(k + 1) % nb], d: Double = hypot(QX[j] - QX[i], QY[j] - QY[i]); bmax = max(bmax, d); bmin = min(bmin, d) }
        var smax = 0.0, smin = 1e9, e = 0, k = 0
        while e + 1 < EDG.count { let i = EDG[e], j = EDG[e + 1], l: Double = hypot(QX[i] - QX[j], QY[i] - QY[j]) / EDL[k]; smax = max(smax, l); smin = min(smin, l); e += 2; k += 1 }
        let grow = bmax > (mat.remeshHi > 0 ? mat.remeshHi : 2.6) * h || smax > (mat.remeshStr > 0 ? mat.remeshStr : 2.8)
        let shrink = !home && remN > 0 && Double(N) > Double(remN0) * 1.05 && (bmin < (mat.remeshLo > 0 ? mat.remeshLo : 0.55) * h || smin < 0.45)
        guard grow || shrink else { return }
        // only at a clean moment: no flipped triangle, no crossing in the live body; going back, only while untouched (re-sampled during
        // rough play too, the fuzz jumped twice as much and left twice as many corners)
        if shrink && !grow && fingers.values.contains(where: { $0.mode != .none }) { return }
        guard !ringCrossedQ(), !ringCrossed(), flipCount(X, Y) == 0, !home || flipCount(QX, QY) == 0 else { return }
        let t0 = Date()
        if remesh() { remN += 1; remeshCount += 1; remCalm = t + max(0, mat.remeshCalm) }
        remLast = t; remeshMs = Date().timeIntervalSince(t0) * 1000
    }

    /// v2.56 補點後站穩 (web `remeshCalmStep`). A re-sample swaps in a new set of particles and rebuilds the mesh and the clusters; the new mesh's
    /// balance is a little off the old one's, and for a dozen frames the body bounced (held at 3R: 8 to 10 points a frame for 12 frames, 1-something
    /// otherwise). Measured on the web: points kept and only rebuilt 2; rest shape swapped to the remembered one 2.5 to 5.7; new points 8. So it is the
    /// new set finding its balance, not one wrong constraint. For remeshCalm s after a re-sample, each particle keeps remeshCalmK (per 1/60 s) of its
    /// velocity relative to the whole; the whole body's movement is untouched.
    private func remeshCalmStep(_ dt: Double) {
        let kk = effParams.remeshCalmK
        guard t < remCalm, kk < 1, N > 0 else { return }
        let k = pow(max(0, kk), dt * 60)
        var mx = 0.0, my = 0.0
        for i in 0..<N { mx += X[i] - PX[i]; my += Y[i] - PY[i] }
        mx /= Double(N); my /= Double(N)
        for i in 0..<N {
            let vx = X[i] - PX[i] - mx, vy = Y[i] - PY[i] - my
            PX[i] = X[i] - mx - vx * k; PY[i] = Y[i] - my - vy * k
        }
    }

    private func ringCrossedQ() -> Bool {
        let n = bnd.count
        for i in 0..<n {
            let a = bnd[i], b = bnd[(i + 1) % n]
            var j = i + 2
            while j < n {
                if i == 0 && j == n - 1 { j += 1; continue }
                let p = bnd[j], q = bnd[(j + 1) % n]
                let d: Double = (QX[b] - QX[a]) * (QY[q] - QY[p]) - (QY[b] - QY[a]) * (QX[q] - QX[p])
                if abs(d) > 1e-12 {
                    let u: Double = ((QX[p] - QX[a]) * (QY[q] - QY[p]) - (QY[p] - QY[a]) * (QX[q] - QX[p])) / d
                    let v: Double = ((QX[p] - QX[a]) * (QY[b] - QY[a]) - (QY[p] - QY[a]) * (QX[b] - QX[a])) / d
                    if u > 0 && u < 1 && v > 0 && v < 1 { return true }
                }
                j += 1
            }
        }
        return false
    }

    var remT = [0.0, 0, 0, 0, 0, 0]; private var remT0 = Date()
    /// v2.58 補點後回原形的目標不能摺 (QC-0007 #46: pull, let go, and it twitched on and on; web `homeRing`...). Each new point's return place (H0)
    /// was interpolated over the old mesh; after a few long pulls the new triangles spanned several badly skewed old ones and H0 itself had 20 to 40
    /// flipped triangles and edges pressed to 2%. Let go, the remembered shape kept heading for a folded target it could not reach. Now the outline
    /// keeps its place along the built outline, crowded places pushed apart, and the inside is eased by neighbour averages until nothing is flipped.
    private func homeRing() {
        let n = bnd.count
        HRX = bnd.map { Q0X[$0] }; HRY = bnd.map { Q0Y[$0] }
        HRC = [0]
        for k in 0..<n { let j = (k + 1) % n; HRC.append(HRC[k] + hypot(HRX[j] - HRX[k], HRY[j] - HRY[k])) }
        HB = Array(HRC[0..<n]); HOX = 0; HOY = 0; HQX = Q0X; HQY = Q0Y; HBND = bnd; remCrossQ = false; remKnot = 0; remKnotChk = 0
    }
    private func homeAt(_ s0: Double) -> (Double, Double) {
        let n = HRX.count, per = HRC[n]
        var s = s0.truncatingRemainder(dividingBy: per)
        if s < 0 { s += per }
        var lo = 0, hi = n
        while hi - lo > 1 { let m = (lo + hi) / 2; if HRC[m] <= s { lo = m } else { hi = m } }
        let span = HRC[lo + 1] - HRC[lo], f: Double = span > 0 ? (s - HRC[lo]) / span : 0, j = (lo + 1) % n
        return (HRX[lo] + (HRX[j] - HRX[lo]) * f, HRY[lo] + (HRY[j] - HRY[lo]) * f)
    }
    private func homeSpread(_ S: inout [Double]) {
        let M = S.count, per = HRC[HRX.count], least = 0.35 * per / Double(M)
        for q in 0..<600 {
            var bad = false
            for m in 0..<M { let nx: Double = m + 1 < M ? S[m + 1] : S[0] + per; if nx - S[m] < least { bad = true; break } }
            if !bad && q >= 8 { break }
            let o = S
            for m in 0..<M {
                let a: Double = m > 0 ? o[m - 1] : o[M - 1] - per, b: Double = m + 1 < M ? o[m + 1] : o[0] + per
                S[m] = o[m] + 0.5 * ((a + b) / 2 - o[m])
            }
        }
    }
    private func homeUnfold() {
        guard EDEG.count == N, TRA.count * 3 == TRI.count else { return }
        var onB = [Bool](repeating: false, count: N)
        for i in bnd { onB[i] = true }
        let need = 0.12 * TRA.reduce(0, +) / Double(max(1, TRA.count))
        for _ in 0..<400 {
            var bad = false, k = 0
            while k < TRI.count {
                let a = TRI[k], b = TRI[k + 1], c = TRI[k + 2]
                let ar: Double = 0.5 * ((H0X[b] - H0X[a]) * (H0Y[c] - H0Y[a]) - (H0Y[b] - H0Y[a]) * (H0X[c] - H0X[a]))
                if ar < need && !(onB[a] && onB[b] && onB[c]) { bad = true; break }
                k += 3
            }
            if !bad { return }
            var sx = [Double](repeating: 0, count: N), sy = sx, e = 0
            while e + 1 < EDG.count {
                let i = EDG[e], j = EDG[e + 1]
                sx[i] += H0X[j]; sy[i] += H0Y[j]; sx[j] += H0X[i]; sy[j] += H0Y[i]
                e += 2
            }
            for i in 0..<N where !onB[i] && EDEG[i] > 0 { H0X[i] += 0.7 * (sx[i] / EDEG[i] - H0X[i]); H0Y[i] += 0.7 * (sy[i] / EDEG[i] - H0Y[i]) }
        }
    }
    private func homeCenter() {
        var hx = 0.0, hy = 0.0
        for i in 0..<N { hx += H0X[i]; hy += H0Y[i] }
        hx /= Double(N); hy /= Double(N)
        for i in 0..<N { H0X[i] -= hx; H0Y[i] -= hy }
        HOX += hx; HOY += hy
    }

    /// back (v2.58): instead of sampling anew, the points the body was built with, found in the return target (H0)
    private func remesh(back: Bool = false) -> Bool {
        remT0 = Date()
        let nb = bnd.count
        let LX = back ? H0X : QX, LY = back ? H0Y : QY, HP = HRC[HRX.count]
        let P: [(Double, Double)] = bnd.map { (LX[$0], LY[$0]) }
        var cum = [0.0]
        for k in 1...nb { let a = P[k - 1], b = P[k % nb]; cum.append(cum[k - 1] + hypot(b.0 - a.0, b.1 - a.1)) }
        let per = cum[nb], M = max(24, Int((per / (h * 1.05)).rounded()))
        var pts: [(Double, Double)] = [], nbnd: [Int] = [], NS: [Double] = []
        var j = 0
        if back {
            for i in HQX.indices { pts.append((HQX[i] - HOX, HQY[i] - HOY)) }
            nbnd = HBND
        }
        for m in 0..<(back ? 0 : M) {
            let tg = Double(m) / Double(M) * per
            while j + 1 < cum.count - 1 && cum[j + 1] < tg { j += 1 }
            let span = cum[j + 1] - cum[j], f: Double = span > 0 ? (tg - cum[j]) / span : 0, a = P[j], b = P[(j + 1) % nb]
            nbnd.append(pts.count); pts.append((a.0 + (b.0 - a.0) * f, a.1 + (b.1 - a.1) * f))
            if HB.count == nb {
                var d: Double = (HB[(j + 1) % nb] - HB[j]).truncatingRemainder(dividingBy: HP)
                if d < 0 { d += HP }
                NS.append(HB[j] + f * d)
            }
        }
        func inP(_ x: Double, _ y: Double) -> Bool {
            var c = false, jj = nb - 1
            for i in 0..<nb {
                let ax = P[i].0, ay = P[i].1, bx = P[jj].0, by = P[jj].1
                if (ay > y) != (by > y) && x < (bx - ax) * (y - ay) / (by - ay) + ax { c.toggle() }
                jj = i
            }
            return c
        }
        var x0 = 1e9, x1 = -1e9, y0 = 1e9, y1 = -1e9
        for q in P { x0 = min(x0, q.0); x1 = max(x1, q.0); y0 = min(y0, q.1); y1 = max(y1, q.1) }
        // buckets (one point spacing) for "how far to the outline" and for finding each new point's old triangle
        let cw = h, ncx = max(1, Int((x1 - x0) / cw) + 3), ncy = max(1, Int((y1 - y0) / cw) + 3)
        func cell(_ x: Double, _ y: Double) -> (Int, Int) { (min(ncx - 1, max(0, Int((x - x0) / cw) + 1)), min(ncy - 1, max(0, Int((y - y0) / cw) + 1))) }
        var bb = [[Int]](repeating: [], count: ncx * ncy)
        for b in 0..<(back ? 0 : M) { let c = cell(pts[b].0, pts[b].1); bb[c.1 * ncx + c.0].append(b) }
        var gy = y0, row = 0
        while !back && gy <= y1 {
            var gx = x0 + (row % 2 == 1 ? h / 2 : 0)
            while gx <= x1 {
                if inP(gx, gy) {
                    var dm = 1e9
                    let c = cell(gx, gy)
                    for yy in max(0, c.1 - 1)...min(ncy - 1, c.1 + 1) { for xx in max(0, c.0 - 1)...min(ncx - 1, c.0 + 1) { for b in bb[yy * ncx + xx] { dm = min(dm, hypot(pts[b].0 - gx, pts[b].1 - gy)) } } }
                    if dm > h * 0.7 { pts.append((gx, gy)) }
                }
                gx += h
            }
            gy += h * 0.87; row += 1
        }
        let n2 = pts.count
        remT[0] += Date().timeIntervalSince(remT0) * 1000; remT0 = Date()
        guard Double(n2) <= Double(remN0) * (effParams.remeshMaxN > 0 ? effParams.remeshMaxN : 3), n2 >= 12 else { return false }
        // each new point's triangle in the old mesh (in the remembered shape) and its barycentric weights; not found (a hair outside
        // a concave bit of outline): the nearest triangle, weights clamped
        let T = TRI, nt = T.count / 3
        var tb = [[Int]](repeating: [], count: ncx * ncy)
        for k in 0..<nt {
            let a = T[3 * k], b = T[3 * k + 1], c = T[3 * k + 2]
            let lo = cell(min(LX[a], LX[b], LX[c]), min(LY[a], LY[b], LY[c])), hi = cell(max(LX[a], LX[b], LX[c]), max(LY[a], LY[b], LY[c]))
            for yy in lo.1...hi.1 { for xx in lo.0...hi.0 { tb[yy * ncx + xx].append(k) } }
        }
        var SA = [Int](repeating: 0, count: n2 * 3), SW = [Double](repeating: 0, count: n2 * 3)
        for p in 0..<n2 {
            let x = pts[p].0, y = pts[p].1
            var best = -1, bs = -1e9, bw = (0.0, 0.0, 0.0)
            let pc = cell(x, y), cand = tb[pc.1 * ncx + pc.0]
            for pass in 0..<2 where best < 0 || (pass == 1 && bs < -0.05) {
            for k in (pass == 0 ? cand : Array(0..<nt)) {
                let a = T[3 * k], b = T[3 * k + 1], c = T[3 * k + 2], ax = LX[a], ay = LY[a]
                let v0x = LX[b] - ax, v0y = LY[b] - ay, v1x = LX[c] - ax, v1y = LY[c] - ay, v2x = x - ax, v2y = y - ay
                let den: Double = v0x * v1y - v1x * v0y
                if abs(den) < 1e-9 { continue }
                let v: Double = (v2x * v1y - v1x * v2y) / den, w: Double = (v0x * v2y - v2x * v0y) / den, u = 1 - v - w, mn = min(u, v, w)
                if mn > bs { bs = mn; best = k; bw = (u, v, w); if mn >= 0 { break } }
            }
            }
            guard best >= 0 else { return false }
            let u = max(0, bw.0), v = max(0, bw.1), w = max(0, bw.2), sm = u + v + w > 0 ? u + v + w : 1
            SA[3 * p] = T[3 * best]; SA[3 * p + 1] = T[3 * best + 1]; SA[3 * p + 2] = T[3 * best + 2]
            SW[3 * p] = u / sm; SW[3 * p + 1] = v / sm; SW[3 * p + 2] = w / sm
        }
        if back {
            let rk = (0..<nb).sorted { HB[$0] < HB[$1] }
            for (k, p) in HBND.enumerated() {
                let v = HRC[k]
                var lo = -1
                for q in 0..<nb where HB[rk[q]] <= v { lo = q }
                let a = rk[lo < 0 ? nb - 1 : lo], b = rk[lo < 0 ? 0 : (lo + 1) % nb]
                var g: Double = HB[b] - HB[a], d: Double = v - HB[a]
                if g <= 0 { g += HP }
                if d < 0 { d += HP }
                let fr: Double = max(0, min(1, d / g))
                SA[3 * p] = bnd[a]; SA[3 * p + 1] = bnd[b]; SA[3 * p + 2] = bnd[b]
                SW[3 * p] = 1 - fr; SW[3 * p + 1] = fr; SW[3 * p + 2] = 0
            }
        }
        remT[1] += Date().timeIntervalSince(remT0) * 1000; remT0 = Date()
        func ip(_ A: [Double]) -> [Double] {
            var o = [Double](repeating: 0, count: n2)
            for p in 0..<n2 { o[p] = A[SA[3 * p]] * SW[3 * p] + A[SA[3 * p + 1]] * SW[3 * p + 1] + A[SA[3 * p + 2]] * SW[3 * p + 2] }
            return o
        }
        // fingers holding on: weight and offsets interpolated (a corner not held weighs 0, its offset is where it is from the finger now)
        var fm: [(Finger, [Double], [Double], [Double], [Double], [Double])] = []
        for f in fingers.values where !f.mem.isEmpty {
            var w = [Double](repeating: 0, count: N), ox = [Double](repeating: 0, count: N), oy = ox, ux = ox, uy = ox
            for i in 0..<N { ox[i] = X[i] - f.fx; oy[i] = Y[i] - f.fy }
            for m in f.mem { w[m.i] = m.w; ox[m.i] = m.ox; oy[m.i] = m.oy; ux[m.i] = m.dx; uy[m.i] = m.dy }
            fm.append((f, ip(w), ip(ox), ip(oy), ip(ux), ip(uy)))
        }
        func qAt(_ a: [Int]) -> (Double, Double)? {
            guard !a.isEmpty else { return nil }
            var x = 0.0, y = 0.0
            for i in a { x += QX[i]; y += QY[i] }
            return (x / Double(a.count), y / Double(a.count))
        }
        let nQX: [Double] = back ? ip(QX) : [], nQY: [Double] = back ? ip(QY) : []
        let eL = qAt(eyeL), eR = qAt(eyeR), hq = (hiIdx < N ? QX[hiIdx] : 0, hiIdx < N ? QY[hiIdx] : 0)
        let nX = ip(X), nY = ip(Y), nPX = ip(PX), nPY = ip(PY), nH0X = ip(H0X), nH0Y = ip(H0Y), nEX = ip(EX), nEY = ip(EY)
        let nQDX: [Double]? = QDX.count == N ? ip(QDX) : nil, nQDY: [Double]? = QDY.count == N ? ip(QDY) : nil
        let nQVX: [Double]? = QVX.count == N ? ip(QVX) : nil, nQVY: [Double]? = QVY.count == N ? ip(QVY) : nil
        let cg = clusters.indices.contains(gi) ? (clusters[gi].cs, clusters[gi].sn) : (1.0, 0.0)
        N = n2; bnd = nbnd
        X = nX; Y = nY; PX = nPX; PY = nPY; H0X = nH0X; H0Y = nH0Y; EX = nEX; EY = nEY
        var mx = 0.0, my = 0.0
        if back {
            for i in 0..<N { mx += nQX[i]; my += nQY[i] }
            mx /= Double(N); my /= Double(N)
            Q0X = HQX; Q0Y = HQY; QX = nQX.map { $0 - mx }; QY = nQY.map { $0 - my }
        } else {
            for p in pts { mx += p.0; my += p.1 }
            mx /= Double(N); my /= Double(N)
            Q0X = pts.map { $0.0 - mx }; Q0Y = pts.map { $0.1 - my }; QX = Q0X; QY = Q0Y
        }
        let hOn = !back && effParams.remeshHome >= 0.5 && NS.count == M
        if hOn {
            for m in 1..<M { while NS[m] < NS[m - 1] { NS[m] += HP } }
            homeSpread(&NS)
            for m in 0..<M { let q = homeAt(NS[m]); H0X[m] = q.0 - HOX; H0Y[m] = q.1 - HOY }
            HB = NS.map { (v: Double) -> Double in let r = v.truncatingRemainder(dividingBy: HP); return r < 0 ? r + HP : r }
        } else if back {
            H0X = HQX; H0Y = HQY; HB = Array(HRC[0..<HRX.count]); HOX = 0; HOY = 0
        } else {
            HB = []
            homeCenter()
        }
        if let a = nQDX, let b = nQDY { QDX = a.map { $0 - mx }; QDY = b.map { $0 - my } } else { QDX = QX; QDY = QY }
        let zero = [Double](repeating: 0, count: N)
        QVX = nQVX ?? zero; QVY = nQVY ?? zero; QW = zero
        GX = zero; GY = zero; GW = zero; RX = zero; RY = zero; GWT = zero; AW = zero
        SX2 = zero; SY2 = zero
        TU = zero; TUB = zero; KF = [Double](repeating: 1, count: N)
        TID = [Int](repeating: -1, count: N); GRAB = [Bool](repeating: false, count: N)
        clingAX = []; clingAY = []
        for (f, w, ox, oy, ux, uy) in fm {
            var mem: [(i: Int, ox: Double, oy: Double, w: Double, dx: Double, dy: Double)] = []
            for i in 0..<N where w[i] > 0.02 { mem.append((i, ox[i], oy[i], w[i], ux[i], uy[i])); GRAB[i] = true }
            f.mem = mem; f.reachN = nil   // v2.58: reachN counted the old list
        }
        remT[2] += Date().timeIntervalSince(remT0) * 1000; remT0 = Date()
        buildClusters()
        for c in clusters.indices { clusters[c].cs = cg.0; clusters[c].sn = cg.1 }
        remT[3] += Date().timeIntervalSince(remT0) * 1000; remT0 = Date()
        bndL = (0..<bnd.count).map { k in let i = bnd[k], jj = bnd[(k + 1) % bnd.count]; return hypot(Q0X[jj] - Q0X[i], Q0Y[jj] - Q0Y[i]) }
        bndL2 = (0..<bnd.count).map { k in let i = bnd[k], jj = bnd[(k + 2) % bnd.count]; return hypot(Q0X[jj] - Q0X[i], Q0Y[jj] - Q0Y[i]) }
        BIDX = [Int](repeating: -1, count: N)
        for k in 0..<bnd.count { BIDX[bnd[k]] = k }
        buildRungs()
        buildMesh(fast: !back)
        if hOn { homeUnfold(); homeCenter() }
        remT[4] += Date().timeIntervalSince(remT0) * 1000; remT0 = Date()
        func near(_ x: Double, _ y: Double, _ k: Int) -> [Int] {
            var o: [(Double, Int)] = []
            for i in 0..<N { o.append((hypot(QX[i] + mx - x, QY[i] + my - y), i)) }
            o.sort { $0.0 < $1.0 }
            return o.prefix(k).map { $0.1 }
        }
        hiIdx = near(hq.0, hq.1, 1).first ?? 0
        do {
            let hd = Dent(i: hiIdx, finger: nil), rr: Double = R * 0.3
            for i in 0..<N where i != hiIdx {
                let ox: Double = Q0X[i] - Q0X[hiIdx], oy: Double = Q0Y[i] - Q0Y[hiIdx]
                if ox * ox + oy * oy < rr * rr { hd.nb.append((i, ox, oy)) }
            }
            hiDent = hd
        }
        if let e = eL { eyeL = near(e.0, e.1, 4) }
        if let e = eR { eyeR = near(e.0, e.1, 4) }
        dentList.removeAll()
        CAPG = 1
        if back {   // the shape is still long on the built mesh: the limits widen to just what it needs, so letting go does not shrink it at once
            let mat = effParams
            var m = 1.0, e = 0, k = 0
            while e + 1 < EDG.count && k < EDL.count { let i = EDG[e], jj = EDG[e + 1], l: Double = hypot(QX[i] - QX[jj], QY[i] - QY[jj]) / EDL[k]; m = max(m, l); e += 2; k += 1 }
            QSTR = m
            let top: Double = mat.growMax > 0 ? mat.growMax : 12, base: Double = max(mat.memCap, 0.9 * mat.stretchCap)
            if mat.memCap > 0 { CAPG = max(1, min(top, m / base)) }
        }
        remT[5] += Date().timeIntervalSince(remT0) * 1000
        return true
    }

    /// v2.54: pulled outward (0.6R on, fully at 1.8R) the shape is remembered faster (pullCreep) and as a whole (pullNearR), so the memory keeps
    /// up with the finger and a long pull does not shrink back on release; rubbing, scrubbing and pinching keep creep (measured: creep 30 all the
    /// time, the frames with a flipped triangle in the fuzz went from a tenth to four in ten). Web `pullK`.
    private func pullK(_ mat: FeelParams) -> Double {
        guard mat.endless >= 0.5 else { return 0 }
        var m = 0.0
        for f in fingers.values where f.mode == .grab && f.far { let x = max(0, min(1, (f.stretch - 0.6) / 1.2)); m = max(m, x * x * (3 - 2 * x)) }
        return m
    }
    /// v2.58 (11-24) pullGive: how much of an outward pull this finger is (0.6R from where it took hold, fully at 1.8R; at least 1R from the body's
    /// centre and heading away from it); how far it may give way shrinks by this from 2R to pullGive × R. Web `giveK`.
    private func giveK(_ f: Finger, _ mat: FeelParams) -> Double {
        guard mat.endless >= 0.5, mat.pullGive > 0, f.mode == .grab, !clusters.isEmpty else { return 0 }
        let mx: Double = f.rawX - f.ax, my: Double = f.rawY - f.ay
        let d: Double = hypot(mx, my) / R
        if d < 0.6 { return 0 }
        let ox: Double = f.rawX - clusters[gi].xc, oy: Double = f.rawY - clusters[gi].yc
        let ol: Double = hypot(ox, oy), out: Double = mx * ox + my * oy
        if ol < R || out <= 0 { return 0 }
        let u: Double = min(1, (d - 0.6) / 1.2)
        return u * u * (3 - 2 * u)
    }
    // MARK: - v2.61 拉的三顆開關 (多米 11-25; .uiux/04-手感/極致優化規劃-暫定.md A2...A5; web PULLHOLD, PULLWHOLE, PULLSOFT)

    /// The numbers of pullHold (A3), pullWhole (A4) and pullSoft (A5 + A2), one for one with the web's.
    private enum PullSet {
        static let still: Double = 0.3, wait: Double = 0.25            // a finger slower than this (radii a second) is still; that long (s) and the pull has stopped
        static let holdFade: Double = 0.25, holdMin: Double = 0.02     // A3 (cr): stopped, remembering falls to holdMin over holdFade s
        static let wholeK: Double = 1.6, wholeR0: Double = 0.15, wholeRamp: Double = 0.35   // A4 (iw): at most wholeK × (how far from the centre it took hold) moves the whole body; taken hold within wholeR0 R of the centre none, wholeRamp R further out all of it
        static let noFlee: Double = 1.35, homeLen: Double = 1.35       // A5 (fl): the remembered outline over this × the built one, let go, it does not flee yet. A2 (bl): under this it goes back to the built mesh
        static let upright: Double = 3                                 // A5 (up): turning upright, the farthest tip moves at most this (R a second)
        static let relV: Double = 6, relT: Double = 0.8                // A5 (vc): for relT s after letting go no particle is faster than relV (R a second)
        static let drift: Double = 0.3                                 // A2 (gv): stopped, the finger's effective position drifts at most this far (R)
    }
    /// How long every grabbing finger has been still (web `PULLT`); 0 with nothing held, after a rebuild, and while both switches that read it are off.
    private var pullStillT = 0.0
    private func pullMoving() -> Bool {
        fingers.values.contains { $0.mode == .grab && hypot($0.vxS, $0.vyS) > R * PullSet.still }
    }
    /// Once a frame, right before the memory (web `pullStillStep`).
    private func pullStillStep(_ dt: Double) {
        guard params.pullHold >= 0.5 || params.pullSoft >= 0.5, fingers.values.contains(where: { $0.mode == .grab }) else { pullStillT = 0; return }
        pullStillT = pullMoving() ? 0 : pullStillT + dt
    }
    /// A3: how much of the remembering is left (pulled open 0.6R on, fully at 1.8R: pullK). Web `pullHoldK`.
    private func pullHoldK(_ mat: FeelParams) -> Double {
        let g0: Double = pullStillT < PullSet.wait ? 1 : max(PullSet.holdMin, 1 - (pullStillT - PullSet.wait) / PullSet.holdFade)
        return 1 - pullK(mat) * (1 - g0)
    }
    /// How long the remembered shape's outline is (web `memLen`).
    private func memLen() -> Double {
        var s = 0.0
        let n = bnd.count
        for k in 0..<n { let i = bnd[k], j = bnd[(k + 1) % n]; s += hypot(QX[j] - QX[i], QY[j] - QY[i]) }
        return s
    }
    private func capG(_ mat: FeelParams) -> Double { mat.endless >= 0.5 ? CAPG : 1 }
    /// Widened, the remembered shape's limit is nine tenths of the live body's (2.4 of 3 before), or it shrinks back to the memory limit on release.
    private func memCapNow(_ mat: FeelParams) -> Double { mat.endless >= 0.5 && CAPG > 1 ? max(mat.memCap, 0.9 * mat.stretchCap) * CAPG : mat.memCap }
    /// Once a frame after the physics: widen the edge limits while edges are full and the held patch lags its finger by more than 0.12R;
    /// with no finger, fall back over about 0.6 s to what the remembered shape still needs.
    private func capGrowStep(_ dt: Double) {
        let mat = effParams
        guard mat.endless >= 0.5, EDL.count * 2 == EDG.count, !EDL.isEmpty else { CAPG = 1; CAPGAP = 0; return }
        var gap = 0.0, held = false
        for f in fingers.values where f.mode == .grab && !f.mem.isEmpty {
            held = true
            var sx = 0.0, sy = 0.0, sw = 0.0
            for m in f.mem { sx += (X[m.i] - m.ox) * m.w; sy += (Y[m.i] - m.oy) * m.w; sw += m.w }
            if sw > 0 { gap = max(gap, hypot(sx / sw - f.fx, sy / sw - f.fy) / R) }
        }
        CAPGAP = gap
        if held {
            let grows: Bool = !(mat.pullSoft >= 0.5) || pullMoving()   // v2.61 A2 (cg): the limit widens only while a finger moves
            if gap > 0.12 && mat.stretchCap > 0 && grows {
                var mx = 0.0, e = 0, k = 0
                while e + 1 < EDG.count {
                    let i = EDG[e], j = EDG[e + 1], l: Double = hypot(X[i] - X[j], Y[i] - Y[j]) / EDL[k]
                    if l > mx { mx = l }
                    e += 2; k += 1
                }
                if mx >= 0.93 * mat.stretchCap * CAPG { CAPG = min(mat.growMax > 0 ? mat.growMax : 12, CAPG * exp((mat.growK > 0 ? mat.growK : 1.5) * rateKG * dt * min(1, gap / 0.4))) }
            }
        } else {
            let need: Double = mat.memCap > 0 ? max(1, QSTR / max(mat.memCap, 0.9 * mat.stretchCap)) : 1
            if CAPG > need { CAPG += (need - CAPG) * (1 - exp(-dt / 0.6)) }
            if CAPG < 1 { CAPG = 1 }
        }
    }
    private func flipMarks(_ AX: [Double], _ AY: [Double]) -> [Bool] {
        var b = [Bool](repeating: false, count: N)
        var k = 0
        while k + 2 < TRI.count {
            let a = TRI[k], p = TRI[k + 1], c = TRI[k + 2]
            if (AX[p] - AX[a]) * (AY[c] - AY[a]) - (AY[p] - AY[a]) * (AX[c] - AX[a]) <= 2 * flipTol(k) { b[a] = true; b[p] = true; b[c] = true }
            k += 3
        }
        return b
    }
    private func flipCount(_ AX: [Double], _ AY: [Double]) -> Int {
        var n = 0, k = 0
        while k + 2 < TRI.count {
            let a = TRI[k], p = TRI[k + 1], c = TRI[k + 2]
            if (AX[p] - AX[a]) * (AY[c] - AY[a]) - (AY[p] - AY[a]) * (AX[c] - AX[a]) <= 2 * flipTol(k) { n += 1 }
            k += 3
        }
        return n
    }
    @discardableResult
    private func meshGuard(_ AX: inout [Double], _ AY: inout [Double], _ kp: Double, _ grab: [Bool]?, _ limits: FeelParams? = nil) -> Bool {
        let cap = h * 0.4
        let m = TRI.count
        // v2.48 (`limits`, the live body with stretchCap on): held particles give way fully (capPushW), a particle a wall stopped hardly moves,
        // the correction leaves no velocity, and what the held ones were pushed by is summed for the finger to give way by
        let cp: Bool = limits != nil && SLX.count == N && HIT.count == N
        let gq: Double = cp ? (limits?.capPushW ?? 1) : 0.25, kv: Double = cp ? 1 - (limits?.capVel ?? 0) : 0
        var any = false
        var t = 0
        while t + 2 < m {
            let a = TRI[t], b = TRI[t + 1], c = TRI[t + 2]
            let ax = AX[a], ay = AY[a], bx = AX[b], by = AY[b], cx = AX[c], cy = AY[c]
            let A: Double = 0.5 * ((bx - ax) * (cy - ay) - (by - ay) * (cx - ax))
            let Am: Double = TRA[t / 3] * kp
            if A < Am {
                let gax = 0.5 * (by - cy), gay = 0.5 * (cx - bx)
                let gbx = 0.5 * (cy - ay), gby = 0.5 * (ax - cx)
                let gcx = 0.5 * (ay - by), gcy = 0.5 * (bx - ax)
                any = true
                let ha: Bool = grab?[a] ?? false, hb: Bool = grab?[b] ?? false, hc: Bool = grab?[c] ?? false
                var wa: Double = ha ? gq : 1, wb: Double = hb ? gq : 1, wc: Double = hc ? gq : 1
                if cp { if HIT[a] { wa *= 0.05 }; if HIT[b] { wb *= 0.05 }; if HIT[c] { wc *= 0.05 } }
                let ga = gax * gax + gay * gay, gb = gbx * gbx + gby * gby, gc = gcx * gcx + gcy * gcy
                let den: Double = wa * ga + wb * gb + wc * gc
                if den >= 1e-9 {
                    var lam: Double = (Am - A) / den
                    let mv: Double = lam * sqrt(max(wa * wa * ga, max(wb * wb * gb, wc * wc * gc)))
                    if mv > cap { lam *= cap / mv }
                    AX[a] += lam * wa * gax; AY[a] += lam * wa * gay
                    AX[b] += lam * wb * gbx; AY[b] += lam * wb * gby
                    AX[c] += lam * wc * gcx; AY[c] += lam * wc * gcy
                    if cp {
                        let ax1: Double = lam * wa * gax, ay1: Double = lam * wa * gay, bx1: Double = lam * wb * gbx, by1: Double = lam * wb * gby, cx1: Double = lam * wc * gcx, cy1: Double = lam * wc * gcy
                        if kv > 0 { PX[a] += ax1 * kv; PY[a] += ay1 * kv; PX[b] += bx1 * kv; PY[b] += by1 * kv; PX[c] += cx1 * kv; PY[c] += cy1 * kv }
                        if ha { SLX[a] += ax1; SLY[a] += ay1 }
                        if hb { SLX[b] += bx1; SLY[b] += by1 }
                        if hc { SLX[c] += cx1; SLY[c] += cy1 }
                    }
                }
            }
            t += 3
        }
        return any
    }

    private func buildClusters() {
        clusters = []
        let cs = R * params.cSpace, cr = R * params.cRad
        // v2.54 補點: a re-sampled long body reaches past ±2.6R; the same grid, extended to cover it (a normal body: the same clusters as before)
        var qx0 = 0.0, qx1 = 0.0, qy0 = 0.0, qy1 = 0.0
        for i in 0..<N { qx0 = min(qx0, Q0X[i]); qx1 = max(qx1, Q0X[i]); qy0 = min(qy0, Q0Y[i]); qy1 = max(qy1, Q0Y[i]) }
        let gx0: Double = -2.6 * R - cs * ceil(max(0, -2.6 * R - (qx0 - cr)) / cs), gy0: Double = -2.6 * R - cs * ceil(max(0, -2.6 * R - (qy0 - cr)) / cs)
        let gx1: Double = max(2.6 * R, qx1 + cr), gy1: Double = max(2.6 * R, qy1 + cr)
        var cy = gy0
        while cy <= gy1 {
            var cx = gx0
            while cx <= gx1 {
                var idx: [Int] = []
                for i in 0..<N where abs(Q0X[i] - cx) < cr && abs(Q0Y[i] - cy) < cr && hypot(Q0X[i] - cx, Q0Y[i] - cy) < cr { idx.append(i) }
                if idx.count >= 5 { clusters.append(Cluster(idx: idx, w: 1)) }
                cx += cs
            }
            cy += cs
        }
        clusters.append(Cluster(idx: Array(0..<N), w: params.wGlobal))
        gi = clusters.count - 1
        builtSpace = params.cSpace; builtRad = params.cRad
    }

    /// 觸手橫檔 (提案第 41 條). A tentacle's boundary is one contiguous run of the ring: up one edge to the tip and
    /// back down the other. Pair the two edges by position along the tentacle, remember the rest width, the rest
    /// handedness and the rest spacing of the medial axis (rung midpoints), so the tentacle cannot fold over itself.
    private func buildRungs() {
        rungs = []; rungSign = []; rungRef = []; rest0 = []
        let nb = bnd.count
        for k in tent.indices {
            var pos: [Int] = []
            for r in 0..<nb where TID[bnd[r]] == k { pos.append(r) }
            if pos.count < 4 { rungs.append([]); rungSign.append(1); rungRef.append((bnd[0], bnd[0])); continue }
            let inRun = Set(pos)
            var start = pos[0]
            for r in pos where !inRun.contains((r + nb - 1) % nb) { start = r; break }
            var run: [Int] = []
            for m in 0..<pos.count { run.append(bnd[(start + m) % nb]) }
            var tipAt = 0
            for m in 1..<run.count where TU[run[m]] > TU[run[tipAt]] { tipAt = m }
            let edgeA = Array(run[0...tipAt]), edgeB = Array(run[tipAt...])
            var list: [Rung] = []
            for a in edgeA {
                var best = -1, bd = 1e9
                for b in edgeB where b != a {
                    let d = abs(TU[b] - TU[a])
                    if d < bd { bd = d; best = b }
                }
                if best < 0 { continue }
                let w0 = hypot(Q0X[best] - Q0X[a], Q0Y[best] - Q0Y[a])
                if w0 < h * 0.9 { continue }   // the very tip is too narrow to tell the sides apart
                list.append(Rung(a: a, b: best, w0: w0, hs: 0))
            }
            list.sort { TU[$0.a] < TU[$1.a] }
            var s = 0.0
            for r in list.indices {
                let p = list[max(0, r - 1)], q = list[min(list.count - 1, r + 1)], g = list[r]
                let tx = Q0X[q.a] + Q0X[q.b] - Q0X[p.a] - Q0X[p.b], ty = Q0Y[q.a] + Q0Y[q.b] - Q0Y[p.a] - Q0Y[p.b]
                let c = tx * (Q0Y[g.b] - Q0Y[g.a]) - ty * (Q0X[g.b] - Q0X[g.a])
                s += c > 0 ? 1 : (c < 0 ? -1 : 0)
            }
            let ref = (bnd[(start + nb - 1) % nb], bnd[(start + pos.count) % nb])
            for r in list.indices {
                let g = list[r]
                let mx: Double, my: Double
                if r == 0 {
                    mx = (Q0X[g.a] + Q0X[g.b] - Q0X[ref.0] - Q0X[ref.1]) * 0.5
                    my = (Q0Y[g.a] + Q0Y[g.b] - Q0Y[ref.0] - Q0Y[ref.1]) * 0.5
                } else {
                    let p = list[r - 1]
                    mx = (Q0X[g.a] + Q0X[g.b] - Q0X[p.a] - Q0X[p.b]) * 0.5
                    my = (Q0Y[g.a] + Q0Y[g.b] - Q0Y[p.a] - Q0Y[p.b]) * 0.5
                }
                list[r].hs = max(h * 0.3, hypot(mx, my))
            }
            rungs.append(list); rungSign.append(s >= 0 ? 1 : -1); rungRef.append(ref)
        }
    }

    private func polygonArea() -> Double {
        var A = 0.0
        let n = bnd.count
        for i in 0..<n {
            let a = bnd[i], b = bnd[(i + 1) % n]
            A += X[a] * Y[b] - X[b] * Y[a]
        }
        return abs(A) / 2
    }

    // MARK: - Readouts for drawing

    /// Boundary points, lightly smoothed (0.25 / 0.5 / 0.25) for the outline.
    func boundaryPoints() -> [(x: Double, y: Double)] {
        let n = bnd.count
        var P: [(x: Double, y: Double)] = []
        P.reserveCapacity(n)
        for i in 0..<n {
            let a = bnd[(i + n - 1) % n], b = bnd[i], c = bnd[(i + 1) % n]
            P.append((X[a] * 0.25 + X[b] * 0.5 + X[c] * 0.25, Y[a] * 0.25 + Y[b] * 0.5 + Y[c] * 0.25))
        }
        return P
    }

    /// 候選 34: per boundary segment, current spacing over rest spacing (below 1 = compressed).
    func boundaryCompression() -> [Double] {
        let n = bnd.count
        var c = [Double](repeating: 1, count: n)
        for i in 0..<n {
            let a = bnd[i], b = bnd[(i + 1) % n]
            c[i] = hypot(X[b] - X[a], Y[b] - Y[a]) / max(1e-6, hypot(Q0X[b] - Q0X[a], Q0Y[b] - Q0Y[a]))
        }
        return c
    }

    var centroid: (x: Double, y: Double) { (clusters.isEmpty ? cx : clusters[gi].xc, clusters.isEmpty ? cy : clusters[gi].yc) }
    var bodyAngle: Double { clusters.isEmpty ? 0 : atan2(clusters[gi].sn, clusters[gi].cs) }
    var highlight: (x: Double, y: Double) { N > 0 ? (X[hiIdx], Y[hiIdx]) : (cx, cy) }
    /// v2.26 F7: how the highlight bends with the skin (a b c d of a CGAffineTransform, rotation removed, pulled back toward identity when extreme)
    var highlightFrame: (Double, Double, Double, Double) {
        guard params.hiStretch >= 0.5, let h = hiDent, h.i < N, h.i == hiIdx else { return (1, 0, 0, 1) }
        let m = dentFrame(h)
        let h0: Double = (m.0 + m.3) / 2, h1: Double = hypot((m.0 - m.3) / 2, (m.1 + m.2) / 2), lb: Double = h0 + h1, ls: Double = h0 - h1
        var q = 1.0
        if lb > 1.8 { q = min(q, 0.8 / (lb - 1)) }
        if ls < 0.55 { q = min(q, 0.45 / (1 - ls)) }
        return (1 + q * (m.0 - 1), q * m.1, q * m.2, 1 + q * (m.3 - 1))
    }
    /// v2.26 F7: the trail in world points, oldest first; k how fresh (1...0); n which touch
    var trailView: [(x: Double, y: Double, k: Double, n: Double)] {
        guard params.dentTrail > 0, !clusters.isEmpty, trail.count > 1 else { return [] }
        let g = clusters[gi], keep: Double = params.dentTrail
        return trail.map { q -> (x: Double, y: Double, k: Double, n: Double) in
            (g.xc + g.cs * q.x - g.sn * q.y, g.yc + g.sn * q.x + g.cs * q.y, 1 - (t - q.t0) / keep, q.n)
        }
    }
    /// v2.26 F7: stroking fingers on the body (the ring beside the finger)
    var strokeHeads: [(x: Double, y: Double)] { fingers.values.filter { $0.mode == .stroke && $0.on }.map { (x: $0.rawX, y: $0.rawY) } }
    /// Dents (v2.15, 多米 build 61: just tapping should do something, maybe a dent). Only the boundary is drawn, so a press in the
    /// middle was invisible. Each dent rides a particle; held it sinks in 0.08 s, a finger dragged 0.4R or more is a pull and the
    /// dent goes; released it fades at the relax rate (clay: half in about 15 s). World position and depth 0...1
    var dents: [DentView] {
        dentList.compactMap { dn -> DentView? in
            guard dn.i < N else { return nil }
            let m = dentFrame(dn)
            return DentView(x: X[dn.i], y: Y[dn.i], d: dn.d, p: dn.p, w: dn.w, a: m.0, b: m.1, c: m.2, dd: m.3)
        }
    }
    /// A dent for drawing: world position, visible depth d, physical press p (can dip below 0 on a jelly rebound), how long
    /// it was held (w 0...1: wider and shallower), and how the skin around it is stretched (a b c dd, CGAffineTransform order,
    /// rotation removed so the light stays upper-left).
    struct DentView { let x, y, d, p, w, a, b, c, dd: Double }
    /// v2.16: p is the physical press (the body spreads, area, highlight, shadow), d the visible depth. nb: neighbours and their
    /// offsets at the press, to fit how the skin is stretched
    private final class Dent { let i: Int; var d = 0.0; var finger: ObjectIdentifier?; var pull = false
        var p = 0.0, v = 0.0, p0 = 0.0, tau = 0.0, w = 0.0, held = 0.0
        var nb: [(i: Int, ox: Double, oy: Double)] = []
        init(i: Int, finger: ObjectIdentifier?) { self.i = i; self.finger = finger } }
    private var dentList: [Dent] = []
    /// v2.16: all dents' physical press added up (area, shadow), clamped to -0.6...1.5
    private(set) var pressSum = 0.0

    /// Least-squares fit of the neighbours' offsets now against at the press, then the stretch part only (polar decomposition
    /// A = R·S): the body turning must not turn the dent's dark side away from the upper-left light.
    private func dentFrame(_ dn: Dent) -> (Double, Double, Double, Double) {
        let x0 = X[dn.i], y0 = Y[dn.i]
        var m00 = 0.0, m01 = 0.0, m10 = 0.0, m11 = 0.0, s00 = 0.0, s01 = 0.0, s11 = 0.0
        for q in dn.nb where q.i < N {
            let cx = X[q.i] - x0, cy = Y[q.i] - y0
            m00 += cx * q.ox; m01 += cx * q.oy; m10 += cy * q.ox; m11 += cy * q.oy
            s00 += q.ox * q.ox; s01 += q.ox * q.oy; s11 += q.oy * q.oy
        }
        let det = s00 * s11 - s01 * s01
        if dn.nb.count < 3 || abs(det) < 1e-9 { return (1, 0, 0, 1) }
        let i00 = s11 / det, i01 = -s01 / det, i11 = s00 / det
        let a = m00 * i00 + m01 * i01, c = m00 * i01 + m01 * i11, b = m10 * i00 + m11 * i01, d = m10 * i01 + m11 * i11
        let da = a * d - b * c
        if !(da > 0.15 && da < 6) { return (1, 0, 0, 1) }
        let th = atan2(b - c, a + d), co = cos(th), si = sin(th)
        return (co * a + si * b, -si * a + co * b, co * c + si * d, -si * c + co * d)
    }

    /// v2.16 P1: around each dent the goals are pushed outward, most (pressSpread·R·p) at σ = 0.3R from the finger and soon gone
    /// further out (σ 0.6R reached the whole ring from a press in the middle: +20% area, the body's growth is sp's job).
    private func pressField() -> [(x: Double, y: Double, a: Double, k: Double, s: Double)] {
        guard params.press2 >= 0.5 && params.pressSpread > 0 else { return [] }
        let sg = R * 0.3
        var pf: [(x: Double, y: Double, a: Double, k: Double, s: Double)] = []
        for dn in dentList where abs(dn.p) >= 0.005 && dn.i < N {
            pf.append((x: X[dn.i], y: Y[dn.i], a: params.pressSpread * R * dn.p, k: 1 / (2 * sg * sg), s: sg))
        }
        return pf
    }
    private func pressPush(_ pf: [(x: Double, y: Double, a: Double, k: Double, s: Double)], _ x: Double, _ y: Double) -> (Double, Double) {
        var ox = 0.0, oy = 0.0
        for q in pf {
            let dx = x - q.x, dy = y - q.y, d2 = dx * dx + dy * dy
            if d2 < 1e-6 { continue }
            let m = q.a * exp(0.5 - d2 * q.k) / q.s
            ox += dx * m; oy += dy * m
        }
        return (ox, oy)
    }

    // MARK: - Fingers

    /// A finger grabbed from inside has moved 0.12R or more: from the held patch's centre, find the boundary particle nearest the
    /// ray in the direction of motion and also grab the strip (grabR wide) from the centre to it, keeping its current offset from
    /// the finger. The strip carries the boundary out while the far side stays: a stretch. Grabbing everything out to the
    /// boundary (a bigger radius) only moved the whole body
    private func reachGrab(_ f: Finger) {
        let mx = f.rawX - f.ax, my = f.rawY - f.ay, ml = hypot(mx, my)
        guard !f.mem.isEmpty else { return }
        // v2.24 reachV: rubbing the finger keeps circling; at 0.12R a strip with boundary points got pinned to it and the outline folded (measured 43°, 14° at rest).
        // Now only a straight pull outward adds the strip (moving within 25° of the way it has moved, 0.5R out), past 0.8R always; back within 0.25R of the start it lets go
        if params.reachV >= 0.5 {
            let vl: Double = hypot(f.vxS, f.vyS), c: Double = vl > R * 0.2 && ml > 1e-6 ? (mx * f.vxS + my * f.vyS) / (ml * vl) : 0
            guard ml > R * 0.8 || (ml > R * 0.5 && c > 0.9) else { return }
            f.reachN = f.mem.count
        } else {
            guard ml >= R * 0.12 else { return }
        }
        f.reach = false
        let ux = mx / ml, uy = my / ml
        var cx = 0.0, cy = 0.0
        for m in f.mem { cx += X[m.i]; cy += Y[m.i] }
        cx /= Double(f.mem.count); cy /= Double(f.mem.count)
        // pushing toward the body centre (a two-finger pinch, a squeeze inward) adds nothing: only an outward pull carries the boundary.
        // Measured: in a pinch each finger grabbed a strip toward the other, they fought over it and one squish went missing
        let rx = cx - clusters[gi].xc, ry = cy - clusters[gi].yc, rl = hypot(rx, ry)
        if rl > R * 0.3 && (rx * ux + ry * uy) / rl < 0 { return }
        var bi = -1, bs = 1e9
        let noTent: Bool = tent.count > 5
        for i in bnd {
            if noTent && TID[i] >= 0 && TU[i] >= 0.35 { continue }
            let dx = X[i] - cx, dy = Y[i] - cy
            if dx * ux + dy * uy <= 0 { continue }
            let pr = abs(dx * uy - dy * ux)
            if pr < bs { bs = pr; bi = i }
        }
        guard bi >= 0 else { return }
        let ex = X[bi] - cx, ey = Y[bi] - cy, l2 = max(1e-9, ex * ex + ey * ey), gr = params.grabR * R
        for i in 0..<N where !GRAB[i] && !(noTent && TID[i] >= 0 && TU[i] >= 0.35) {
            let dx = X[i] - cx, dy = Y[i] - cy, tt = max(0, min(1, (dx * ex + dy * ey) / l2))
            let d = hypot(dx - ex * tt, dy - ey * tt)
            if d < gr {
                let u = d / gr
                f.mem.append((i, X[i] - f.fx, Y[i] - f.fy, exp(-u * u * 2.5) * (1 - u * u), 0, 0))
                GRAB[i] = true
            }
        }
    }

    func insideBody(_ x: Double, _ y: Double) -> Bool {
        var c = false
        let n = bnd.count
        guard n > 2 else { return false }
        var j = n - 1
        for i in 0..<n {
            let ax = X[bnd[i]], ay = Y[bnd[i]], bx = X[bnd[j]], by = Y[bnd[j]]
            if (ay > y) != (by > y) && x < (bx - ax) * (y - ay) / (by - ay) + ax { c.toggle() }
            j = i
        }
        return c
    }

    private func nearBody(_ x: Double, _ y: Double, _ rad: Double) -> Bool {
        for i in bnd where hypot(X[i] - x, Y[i] - y) < rad { return true }
        return false
    }

    /// v2.26: the grab itself, on landing or when a stroke stops on the body
    private func fingerGrab(_ f: Finger, id: ObjectIdentifier, x: Double, y: Double) {
        // mem: particle, offset from the finger, follow weight, and the spread direction for the press
        // (unit vector away from the finger × (1 − u²)², so the patch squashes flat under the finger)
        let gr = params.grabR * R
        for i in 0..<N where !GRAB[i] {
            let ox = X[i] - x, oy = Y[i] - y, d = hypot(ox, oy)
            if d < gr {
                let u = d / gr, wp = (1 - u * u) * (1 - u * u), inv = d > 1e-6 ? wp / d : 0
                f.mem.append((i, ox, oy, exp(-u * u * 2.5) * (1 - u * u), ox * inv, oy * inv))
                GRAB[i] = true
            }
        }
        // v2.27: not landing on a tentacle, hold none of its particles: a grab on the body holds only the body (a few caught along twist the root as clay remembers, 30 pt a frame of shaking)
        if tent.count > 5 && gripTent(f) < 0 {
            let keep = f.mem.filter { !(TID[$0.i] >= 0 && TU[$0.i] >= 0.35) }
            if !keep.isEmpty && keep.count < f.mem.count {
                for m in f.mem where TID[m.i] >= 0 && TU[m.i] >= 0.35 { GRAB[m.i] = false }
                f.mem = keep
            }
        }
        // grabReach (v2.14, 多米 build 59: pulling from the middle did nothing; measured: the right edge went back 0.08R): only the
        // inner patch was held, and dragged out of the body it is invisible (only the boundary is drawn). Mark it; reachGrab adds
        // a strip to the boundary in the pull direction once the finger moves
        if params.grabReach > 0 && insideBody(x, y) {
            var db = 1e9
            for i in bnd { db = min(db, hypot(X[i] - x, Y[i] - y)) }
            if db > gr * 0.8 { f.reach = true }
        }
        if f.mem.isEmpty {
            let order = (0..<N).sorted { hypot(X[$0] - x, Y[$0] - y) < hypot(X[$1] - x, Y[$1] - y) }
            for i in order.prefix(6) {
                let ox = X[i] - x, oy = Y[i] - y, d = hypot(ox, oy), inv = d > 1e-6 ? 1 / d : 0
                f.mem.append((i, ox, oy, 1, ox * inv, oy * inv))
                GRAB[i] = true
            }
        }
        if params.dent > 0 {
            var bi = 0, bd = 1e9
            for i in 0..<N { let d = hypot(X[i] - x, Y[i] - y); if d < bd { bd = d; bi = i } }
            // v2.16: pressing near an old dent reuses it (pressing one spot keeps deepening it, not two dents side by side that
            // read as eyes); remember the neighbours' offsets so the drawing bends with the body
            if params.press2 >= 0.5, let old = dentList.first(where: { $0.finger == nil && hypot(X[$0.i] - x, Y[$0.i] - y) < R * params.dentSize * 0.9 }) {
                old.finger = id; old.pull = false; old.tau = 0; old.p0 = max(0, old.p)
            } else {
                let dn = Dent(i: bi, finger: id), rr = R * params.dentSize * 1.3
                for i in 0..<N where i != bi {
                    let ox = X[i] - X[bi], oy = Y[i] - Y[bi]
                    if ox * ox + oy * oy < rr * rr { dn.nb.append((i, ox, oy)) }
                }
                dentList.append(dn)
                if dentList.count > (params.press2 >= 0.5 ? 4 : 6) { dentList.removeFirst() }
            }
        }
    }

    /// `allowed` is false for touches in the system-gesture bands near the screen edges.
    /// `radius` is UITouch.majorRadius (contact size, points; 0 if unknown). `force` (v2.63 B2) is UITouch.force / maximumPossibleForce
    /// where there is 3D Touch, −1 otherwise (the UI layer reads it; this file stays Foundation only).
    /// `x, y` are screen points; the rig turns them into world points through the camera.
    func touchBegan(_ id: ObjectIdentifier, x sx: Double, y sy: Double, time: TimeInterval, allowed: Bool = true, radius: Double = 0, force: Double = -1) {
        guard N > 0 else { return }
        if introOn { let mini = introMini; endIntro(); if !mini { return } }   // v2.17: a touch on the way brings it home at once (eased in 0.25 s); this touch does not grab; during a happy hop it grabs as usual
        let (x, y) = toWorld(sx, sy)
        slpLastAny = t   // v2.23 B2: a tap anywhere counts as someone there
        if allowed && b2On && twMg == nil && twinHit(x, y) {   // v2.62: this touch takes the second slime (several fingers can)
            twinGrab(id, x, y, sx, sy, effParams)
            onEvent?(.press(gain: 0.3))
            return
        }
        if let old = fingers[id], old.sticking { release(id, quiet: true) }   // 候選 26: the same touch object came back while stuck
        var grab = allowed && (insideBody(x, y) || nearBody(x, y, R * 0.22))
        if sillOn, let g = sillG {   // v2.30: behind the bowl or outside, the bowl, the frame and the wall are in front of it; 走路: a tap on the gift stone asks instead of grabbing
            if sillPlane != .room {
                if !noBowl && sx > g.bx - g.bw / 2 && sx < g.bx + g.bw / 2 && sy > g.by + g.bh * 0.1 && sy < g.fl { grab = false }
                if sillPlane == .out && !(sx > g.gx && sx < g.jr && sy > g.gy && sy < g.bt) { grab = false }
            }
            if !grab && allowed && walkGiftAt(sx, sy) { onGiftTap?(); return }
        }
        // v2.64 擺飾變真 (web sillTouch): on the sill a finger off the body on a thing takes the thing (then the hanging ones); behind the bowl or outside the thing is in front of it
        if allowed && dreal {
            var pk = -1, hn: String? = nil
            let pr = propAt(sx, sy)
            if sillPlane == .room { if !grab { pk = pr; if pr < 0 { hn = hangAt(sx, sy) } } } else if pr >= 0 { grab = false; pk = pr }
            if pk >= 0 || hn != nil {
                let f = Finger(x: x, y: y, mode: .none, time: t)
                f.sx = sx; f.sy = sy
                if let hn, let k = hangs.firstIndex(where: { $0.name == hn }) {
                    f.hangN = hn
                    var q = hangs[k]
                    q.held = id; hangRing(&q, 0.3)
                    hangs[k] = q
                } else if props.indices.contains(pk) {
                    f.propK = pk
                    var p = props[pk]
                    let c = cos(p.a), s = sin(p.a), dx = x - p.x, dy = y - p.y
                    p.held = id; p.hlx = c * dx + s * dy; p.hly = -s * dx + c * dy; p.lastHit = t; p.fade = 0; p.alpha = 1
                    props[pk] = p
                }
                fingers[id] = f
                return
            }
        }
        if grab { escOn = false }   // v2.18: caught, it stops running
        let f = Finger(x: x, y: y, mode: !allowed ? .none : (grab ? .grab : .push), time: t)   // v2.61 C1: made here (it was made further down): softTouch keeps hold of it
        greetWait = false   // v2.63 C4: touched, it stops waiting to look at you and does as usual (web pointerdown GREET.st='')
        if grab { swimOn = false; if !(slpOn && softTouch(f)) { wake(true) } }   // v2.23: caught while swimming in, no hello; asleep, it startles awake; v2.61 C1 (wakeSoft): trusting, it waits 0.25 s to tell a light touch
        if !grab && allowed {   // v2.23: asleep, a tap beside it wakes it (that tap is no rhythm); awake, C6 listens
            if slpOn { var db = 1e9; for i in bnd { db = min(db, hypot(X[i] - x, Y[i] - y)) }; if db < R * 2 { wake(false) }; echoTaps = [] }
            else { echoTap(x, y) }
        }
        // v2.19: caught, the sniffing pseudopods draw in and it stops walking; A5 the dent still shows at once (below) and 0.1...0.25 s
        // later it flinches by itself; A7 a touch on empty space within 3R makes it turn and sniff that way 0.3 s later
        // v2.20 C5: wary, it flinches sooner
        if grab && lv(params.lifeFlinch) && !(flAt > t) && !slpOn { flAt = t + (0.1 + Double.random(in: 0..<0.15, using: &rng)) * (iv2(params.impC5) ? 1 - 0.5 * impWary : 1); flPre = lifeSt; flTapAt = flAt }   // flTapAt: v2.61 D2
        if grab { bondTouch(x, y) }   // v2.63 D6 (web: the next line): a high bond's first touch does not flinch, it leans to your finger
        if grab && params.life2 >= 0.5 { cutSniffs(); gaitOn = false; gaitK = 1; wanderMoving = false; lifeSt = slpOn ? .sleep : .rest; lifeUntil = -1; askOn = false }   // v2.61 C1: slpOn, still asleep
        let lure = !grab && allowed && (iv2(params.impC1) || iv2(params.impC2))   // v2.20: a finger on empty space goes to C1, C2 (lureStep), not just one sniff
        if !grab && allowed && !lure && lv(params.lifeAttend) {
            var db = 1e9
            for i in bnd { db = min(db, hypot(X[i] - x, Y[i] - y)) }
            if db < R * 3 { attOn = true; attAt = t + 0.3; attX = x; attY = y }
        }
        f.radius = radius; f.r0 = radius
        f.sx = sx; f.sy = sy
        f.lure = lure
        // C4: touched again while it begs, the purr comes in 0.3 s (a stroke normally takes 1 s)
        if grab && iv2(params.impC4) && t < impAskUntil { f.gentleT = 0.7; moodC = max(moodC, 0.5); impTrust = min(1, impTrust + 0.05); impAskUntil = -9 }
        if grab {
            if clusters.indices.contains(gi) { f.r0x = x - clusters[gi].xc; f.r0y = y - clusters[gi].yc }   // v2.61 A4
            fingerGrab(f, id: id, x: x, y: y)
            pressSnd = params.sndB2 >= 0.5 ? pressForce(force: force, radius: radius) : -1   // v2.63 B2 (web: sfxPlay('press', pressForce(e))); the haptic keeps the event's 0.7
            onEvent?(.press(gain: 0.7))
            pressSnd = -1
            // press flat (多米 2026-11-01: wanted to see it): a press counts only if it lands on the upper half; remember the
            // height and the bottom then (the invisible table is at that bottom)
            if params.pressFlat > 0 {
                var y0 = 1e9, y1 = -1e9
                for i in bnd { y0 = min(y0, Y[i]); y1 = max(y1, Y[i]) }
                if y < clusters[gi].yc { f.flatOn = true; f.h0 = max(R * 0.5, y1 - y0); f.bot = y1; f.flat = 1 }
            }
        }
        fingers[id] = f
        if grab && params.strokeV > 0 && params.inertiaHz > 0 {   // v2.26 F6: a second finger right after the first is a pinch or a two-finger pull: the first goes back to a grab
            f.judge = true
            for (qid, q) in fingers where q !== f && q.mode == .stroke && t - q.tDown < 0.2 { strokeGrab(q, id: qid) }
        }
        if grab { dragRebase() }
    }

    /// `x, y` is the real finger position. `predictedX/Y` is the system's guess for the next frame; it is used
    /// only on frames that received a fresh move event (Apple: predicted touches are temporary and must be
    /// replaced as real touches arrive). `distance` is the true travelled distance from coalesced touches.
    func touchMoved(_ id: ObjectIdentifier, x: Double, y: Double, predictedX: Double?, predictedY: Double?, distance: Double, radius: Double = 0) {
        if let tf = twFg[id] { tf.x += (x - tf.sx) / camZ; tf.y += (y - tf.sy) / camZ; tf.sx = x; tf.sy = y; return }   // v2.62: a touch holding the second slime, in the world only its real movement
        guard let f = fingers[id] else { return }
        // in the world the finger only follows its real movement: screen travel ÷ the current zoom (v2.15). From v2.12 the screen point was
        // mapped back every frame, so as the view backed off a resting finger ran outward in the world, the shape stretched, the view
        // backed off more and it never settled (measured: pull 3R and hold, it grew to 12R by itself, past 10R it shook and crossed;
        // 多米 build 61: past some point it twitches)
        f.rawX += (x - f.sx) / camZ; f.rawY += (y - f.sy) / camZ
        f.sx = x; f.sy = y
        if let predictedX, let predictedY {
            f.psx = predictedX; f.psy = predictedY
            f.predX = f.rawX + (predictedX - x) / camZ; f.predY = f.rawY + (predictedY - y) / camZ; f.hasPrediction = true
        } else {
            f.hasPrediction = false
        }
        f.movedThisFrame = true
        f.travel += distance; f.travelFrame += distance
        if radius > 0 { f.radius = radius }
    }

    func touchEnded(_ id: ObjectIdentifier, time: TimeInterval) {
        if twFg[id] != nil { twinRelease(id); return }   // v2.62
        guard let f = fingers[id] else { return }
        // 候選 26 放手黏連: lifted slowly (under one radius per second) the grab holds on for `stick` seconds, the patch
        // staying at the fingertip; a flick lets go at once. A tiny tick marks the stick, the pop comes at the real release
        if f.mode == .grab && params.stick > 0 && !f.sticking && hypot(f.vxS, f.vyS) < R {
            f.sticking = true; f.releaseAt = t + params.stick
            f.hasPrediction = false; f.movedThisFrame = false
            onEvent?(.tick(gain: 0))
            return
        }
        release(id, quiet: false)
    }

    /// Lets a finger go. `quiet` skips the release pop (cancelled touches, a stuck finger pressed again).
    /// v2.26 F6 stroke or grab (measured: a finger sliding across dragged the whole body along 74 to 113 pt). Moved strokeV × strokeT points within strokeT of landing, not outward: a stroke.
    /// Grabbing is the main verb: taken for a stroke it feels like it cannot be held, taken for a grab it is just v2.25; so when in doubt a grab: another finger on it, leaving from the middle (within 0.35R), or heading outward (within 60 degrees).
    private func strokeJudge(_ f: Finger, id: ObjectIdentifier) {
        if t - f.tDown > params.strokeT { f.judge = false; return }
        let dx: Double = f.rawX - f.ax, dy: Double = f.rawY - f.ay, dl: Double = hypot(dx, dy)
        if dl * camZ < params.strokeV * params.strokeT { return }
        f.judge = false
        for q in fingers.values where q !== f && (q.mode == .grab || q.mode == .stroke) { return }
        guard !clusters.isEmpty else { return }
        let rx: Double = f.ax - clusters[gi].xc, ry: Double = f.ay - clusters[gi].yc, rl: Double = hypot(rx, ry)
        if rl < R * 0.35 || (rx * dx + ry * dy) / (rl * dl) > 0.5 { return }
        let held: Double = t - f.tDown
        if dl * camZ < params.rubSpeed * 60 * max(held, 1.0 / 240.0) { stkG = min(3, stkG + 2 * held) }   // v2.26.1: the finger was already stroking while this was judged; without it three strokes no longer soothe at the higher threshold
        letGo(f, id: id)
        if flAt > t && !(impWary > 0.4) { flAt = -9 }   // a stroke does not startle it; wary, it still flinches
    }

    private func letGo(_ f: Finger, id: ObjectIdentifier) {
        f.mode = .stroke
        inertiaCatch()
        for m in f.mem { GRAB[m.i] = false }
        f.mem = []; f.reach = false; f.reachN = nil; f.slowT = 0; f.stretch = 0; f.ex = 0; f.ey = 0; f.sb = 0; f.press = 0; f.pressOn = false; f.flatOn = false; f.on = true; f.hitT = t
        for dn in dentList where dn.finger == id { dn.finger = nil; dn.pull = true; dn.held = 0 }
        dragRelease(glide: false)
    }

    /// Which tentacle a finger holds: more than half of what it holds must be on it. Pulling the body outward also grabs a line to the rim (v2.14), which can catch a few tentacle particles; that is not holding the tentacle, or a pull from the middle toward one would slip at once.
    private func gripTent(_ f: Finger) -> Int {
        if tent.count <= 5 || f.mem.isEmpty { return -1 }
        var c = [Int](repeating: 0, count: tent.count)
        for m in f.mem where TID[m.i] >= 0 && TU[m.i] >= 0.35 { c[TID[m.i]] += 1 }
        var k = -1, b = 0
        for j in c.indices where c[j] > b { b = c[j]; k = j }
        return b * 2 >= f.mem.count ? k : -1
    }

    private func tentGrip(_ f: Finger) -> Bool { gripTent(f) >= 0 }

    private func rootCentre(_ T: Tentacle) -> (x: Double, y: Double, qx: Double, qy: Double, q0x: Double, q0y: Double) {
        var x = 0.0, y = 0.0, qx = 0.0, qy = 0.0, q0x = 0.0, q0y = 0.0
        for i in T.root { x += X[i]; y += Y[i]; qx += QX[i]; qy += QY[i]; q0x += Q0X[i]; q0y += Q0Y[i] }
        let n = Double(T.root.count)
        return (x / n, y / n, qx / n, qy / n, q0x / n, q0y / n)
    }

    /// v2.27: pushing a tentacle toward its own root folds it; the rungs and the axis forbid folding while the finger insists, and it shakes (measured 60 pt a frame, the v2.8 tangle).
    /// Pushed to tentSlip of its rest length, or round the back of the body, it slides out of the finger.
    private func tentSlip(_ f: Finger, id: ObjectIdentifier) -> Bool {
        if !(params.tentSlip > 0) { return false }
        let k: Int = gripTent(f)
        if k < 0 || tent[k].root.isEmpty || clusters.isEmpty { return false }
        let c = rootCentre(tent[k])
        var rest = 0.0
        for m in f.mem where TID[m.i] == k { rest = max(rest, hypot(Q0X[m.i] - c.q0x, Q0Y[m.i] - c.q0y)) }
        let ox: Double = c.x - clusters[gi].xc, oy: Double = c.y - clusters[gi].yc, ol: Double = max(hypot(ox, oy), 1e-9)
        let fx: Double = f.rawX - c.x, fy: Double = f.rawY - c.y, fl: Double = max(hypot(fx, fy), 1e-9)
        let back: Bool = (ox * fx + oy * fy) / (ol * fl) < 0.2
        if !back && fl >= params.tentSlip * rest { return false }
        letGo(f, id: id)
        return true
    }

    /// v2.27 ringed tentacles remember their length, never a bend: the remembered shape stays straight, so it cannot fold or sink into the body. Stretch stays per the material; the root follows the body's remembered shape.
    private func tentRest(_ dt: Double, _ mat: FeelParams) {
        if tent.count <= 5 { return }
        let grabbing = fingers.values.filter { $0.mode == .grab }
        for k in tent.indices {
            if tent[k].root.isEmpty { continue }
            let c = rootCentre(tent[k])
            var tgt = 0.0, g = 0.0
            for f in grabbing where gripTent(f) == k {
                for m in f.mem where TID[m.i] == k && TUB[m.i] >= 0.35 {
                    let rest: Double = hypot(Q0X[m.i] - c.q0x, Q0Y[m.i] - c.q0y)
                    if rest <= 1 { continue }
                    let a: Double = hypot(X[m.i] - c.x, Y[m.i] - c.y) / rest
                    if a > tgt {
                        tgt = a
                        let x: Double = max(0, min(1, (t - f.tDown - mat.dwellLo) / max(0.001, mat.dwellHi - mat.dwellLo)))
                        g = x * x * (3 - 2 * x)
                    }
                }
            }
            var s: Double = tent[k].s
            if t < relaxUntil { s += (1 - s) * min(1, 6 * dt) }
            else if tgt > s { s += (min(tgt, 2.2) - s) * min(1, mat.creep * dt * g) }
            else if tgt == 0 { s += (1 - s) * min(1, mat.recover * dt) }
            tent[k].s = s
            var tx = 0.0, ty = 0.0, tl = 0.0
            for i in tent[k].all {
                let dx: Double = Q0X[i] - c.q0x, dy: Double = Q0Y[i] - c.q0y, d: Double = hypot(dx, dy)
                if d > tl { tl = d; tx = dx; ty = dy }
            }
            if tl < 1 { continue }
            tx /= tl; ty /= tl
            let sw: Double = 1 / s.squareRoot()
            for i in tent[k].all where TUB[i] >= 0.08 {
                let dx: Double = Q0X[i] - c.q0x, dy: Double = Q0Y[i] - c.q0y
                let au: Double = (dx * tx + dy * ty) * s, pu: Double = (-dx * ty + dy * tx) * sw
                QX[i] = c.qx + au * tx - pu * ty; QY[i] = c.qy + au * ty + pu * tx
            }
        }
    }

    /// v2.27 tentacles bump (多米 11-05). Only closing speed counts, so pressing still adds no force and cannot shake. The other tentacle's rest shape gets a velocity (the spring behind the release wobble;
    /// pushing particles directly is undone by shape matching within a few substeps, measured 2 pt), more toward the tip, once in 0.2 s per pair. Not a hard constraint: pressed hard they still overlap. Held particles stay put.
    private func tentBump() {
        if !(params.tentBump > 0) || tent.count <= 5 || clusters.isEmpty { return }
        let D: Double = R * 0.16, D2: Double = D * D, cap: Double = R * 0.012, n: Int = tent.count
        let g = clusters[gi]
        for a in 0..<n {
            for b in (a + 1)..<max(a + 1, n) {
                var best = 0.0, nx = 0.0, ny = 0.0, ia = -1, ib = -1
                for i in tent[a].edge {
                    for j in tent[b].edge {
                        let dx: Double = X[i] - X[j], dy: Double = Y[i] - Y[j], d2: Double = dx * dx + dy * dy
                        if d2 >= D2 || d2 < 1e-6 { continue }
                        let d: Double = d2.squareRoot(), ux: Double = dx / d, uy: Double = dy / d
                        let cl: Double = -((X[i] - PX[i] - X[j] + PX[j]) * ux + (Y[i] - PY[i] - Y[j] + PY[j]) * uy)
                        if cl > best { best = cl; nx = ux; ny = uy; ia = i; ib = j }
                    }
                }
                if best <= 0.02 || (t - tent[a].bumpT < 0.2 && t - tent[b].bumpT < 0.2) { continue }
                tent[a].bumpT = t; tent[b].bumpT = t
                let imp: Double = R * 10 * params.tentBump * (0.5 + 0.5 * min(1, best / cap))
                let heldA: Bool = tent[a].all.contains { GRAB[$0] }, heldB: Bool = tent[b].all.contains { GRAB[$0] }
                if heldA && heldB { continue }
                let sa: Double = heldA ? 0 : (heldB ? 1 : 0.5), sb: Double = heldB ? 0 : (heldA ? 1 : 0.5)
                let lx: Double = g.cs * nx + g.sn * ny, ly: Double = -g.sn * nx + g.cs * ny
                if sa > 0 { kick(a, ia, imp * sa, lx, ly) }
                if sb > 0 { kick(b, ib, -imp * sb, lx, ly) }
            }
        }
    }

    private func kick(_ k: Int, _ contact: Int, _ v: Double, _ lx: Double, _ ly: Double) {
        let u0: Double = max(0.2, TU[contact])
        for i in tent[k].all where !GRAB[i] {
            let w: Double = min(1, TU[i] / u0), q: Double = w * w * v
            QVX[i] += lx * q; QVY[i] += ly * q
        }
    }

    /// v2.27 mood colour (多米 11-05): its own colour normally, tinted when a mood comes. These are what shows; 0.4 s to catch up so the colour flows.
    private func moodColorStep(_ dt: Double) {
        if !(params.moodColor > 0) { mcC = 0; mcS = 0; mcW = 0; mcZ = 0; return }
        let q: Double = 1 - exp(-dt / 0.4)
        func cl(_ v: Double) -> Double { max(0, min(1, v)) }
        let tgtC: Double = max(cl((moodC - 0.1) / 0.45), t - happyT < 2 ? 1 : 0, !fingers.isEmpty && tickOn ? 0.7 : 0)
        mcC += (tgtC - mcC) * q
        var st = 0.0, yk = 0.0
        for f in fingers.values where f.mode == .grab && (!roughOn || f.yank) {   // v2.61 D1 (rough): only a yanked one reads red
            st = max(st, bodyStretch(f))
            yk = max(yk, hypot(f.vxS, f.vyS) / R)
        }
        // the body follows the finger (the pull), so it rarely strains long enough to want out: red reads the stretch and the yank, quick to come, slow to go
        let tgS: Double = max(moodStrain, escOn ? 1 : 0, cl((st - 0.6) / 0.5), !fingers.isEmpty && tickOn ? 0 : cl((yk - 5) / 3))
        mcS += (tgS - mcS) * (tgS > mcS ? 1 - exp(-dt / 0.12) : q)
        mcW += (max(cl(moodScare), cl(impShownWary / 0.6)) - mcW) * q
        mcZ += (slpK - mcZ) * q
    }

    /// A stroke stops on the body (or the contact patch grows): the skin under the finger is held from here
    private func strokeGrab(_ f: Finger, id: ObjectIdentifier) {
        f.mode = .grab
        f.ax = f.rawX; f.ay = f.rawY; f.x = f.rawX; f.y = f.rawY; f.fx = f.rawX; f.fy = f.rawY
        f.stretch = 0; f.ex = 0; f.ey = 0; f.sb = 0; f.step = 0; f.hold = 0; f.press = 0; f.pressOn = false; f.peak = 0; f.on = false; f.far = false
        f.vMax = 0; f.yank = false   // v2.61 D1
        f.om = 0; f.ov = 0   // v2.63 B1 B3 (web strokeGrab)
        f.tGrab = t; f.grainI = 0; f.grR = 0
        if clusters.indices.contains(gi) { f.r0x = f.rawX - clusters[gi].xc; f.r0y = f.rawY - clusters[gi].yc }   // v2.61 A4
        fingerGrab(f, id: id, x: f.rawX, y: f.rawY)
        onEvent?(.press(gain: 0.35))
        dragRebase()
    }

    private func trailAdd(_ f: Finger) {
        guard !clusters.isEmpty else { return }
        let g = clusters[gi], px: Double = f.rawX - g.xc, py: Double = f.rawY - g.yc
        trail.append(TrailPoint(x: g.cs * px + g.sn * py, y: -g.sn * px + g.cs * py, t0: t, n: f.tDown))
        if trail.count > 64 { trail.removeFirst() }
    }

    /// Each frame: judging, stroke and grab turning into each other, the trail, grains on a stroke, and how far the body is carried (moved with its previous step, no velocity left; home moves along)
    private func strokeStep(_ dt: Double) {
        let mat = effParams, strokeOn: Bool = mat.strokeV > 0 && mat.inertiaHz > 0
        if !strokeOn { for (id, f) in fingers where f.mode == .stroke { strokeGrab(f, id: id) } }
        var tx = 0.0, ty = 0.0, n = 0.0, on = false, grab = false
        for (id, f) in fingers {
            let sp: Double = hypot(f.vxS, f.vyS) * camZ
            if f.judge && f.mode == .grab { strokeJudge(f, id: id) }
            if strokeOn && f.mode == .push && sp >= mat.strokeV && (insideBody(f.rawX, f.rawY) || nearBody(f.rawX, f.rawY, R * 0.22)) {   // sliding in from outside is a stroke too
                f.mode = .stroke; f.lure = false; f.slowT = 0; f.on = true; f.hitT = t; f.pushed = true
                onEvent?(.nudge)
            }
            if f.mode == .grab && tentSlip(f, id: id) { continue }
            if f.mode == .grab {
                grab = true
                if mat.dentTrail > 0 && f.stretch < 0.6 && sp > R * 0.3 {
                    f.trD += hypot(f.vx, f.vy) * dt
                    if f.trD >= R * 0.05 { f.trD = 0; trailAdd(f) }
                }
                continue
            }
            guard f.mode == .stroke else { continue }
            f.on = insideBody(f.rawX, f.rawY) || nearBody(f.rawX, f.rawY, R * 0.15)
            f.slowT = sp < mat.strokeStop ? f.slowT + dt : 0
            // the contact patch growing is a press (the first 100 ms it grows by itself as the finger lands)
            if f.radius > 0 {
                if f.rBase <= 0 && t - f.tDown >= 0.1 { f.rBase = f.radius }
                if f.rBase > 0 && f.on && f.radius >= f.rBase + 8 { strokeGrab(f, id: id); grab = true; continue }
            }
            if f.slowT >= 0.12 {
                if f.on { strokeGrab(f, id: id); grab = true }
                else { f.mode = .push; f.pushed = false; f.lure = iv2(mat.impC1) || iv2(mat.impC2) }
                continue
            }
            if !f.on { continue }
            f.hitT = t; lastTouch = t; on = true; stkLast = t; tx += f.vxS; ty += f.vyS; n += 1
            if sp < mat.rubSpeed * 60 { stkG = min(3, stkG + 2 * dt); if stkG > 1 { stkPet = true } }
            if mat.dentTrail > 0 {
                f.trD += hypot(f.vx, f.vy) * dt
                if f.trD >= R * 0.05 { f.trD = 0; trailAdd(f) }
            }
            // the skin under the finger: grains by travel, the same limit, a little softer than a rub
            if mat.tickSpacing > 0 {
                if f.tickNext <= 0 { f.tickNext = mat.tickSpacing; f.tickAt = f.travel }
                if f.travel - f.tickAt >= f.tickNext && f.speedC > R * 0.1 && t - tickLastT >= 1 / max(1, mat.tickRate) {
                    f.tickAt = f.travel
                    f.tickNext = mat.tickSpacing * (0.7 + 0.6 * Double.random(in: 0..<1, using: &rng))
                    tickLastT = t
                    onEvent?(.tick(gain: 0.7 * min(1, f.speedC / (R * 3))))
                }
            }
        }
        if !on { stkG = max(0, stkG - 0.6 * dt) }
        if stkG < 0.5 { stkSaid = false }
        let keep: Double = mat.dentTrail
        while let q = trail.first, t - q.t0 > keep { trail.removeFirst() }
        // done stroking (0.7 s without another): comfortable, it is happy
        if stkPet && fingers.isEmpty && t - stkLast > 0.7 {
            stkPet = false
            if moodC > 0.35 && mat.emo >= 0.5 && !escOn {   // v2.63 C6 (web: the same line): rubVary 0 as before (tall, a wag, the hop, happy)
                let bx = clusters.isEmpty ? homeX : clusters[gi].xc, by = clusters.isEmpty ? homeY : clusters[gi].yc
                rubHappy(impHas ? impLX : bx, impHas ? impLY : by - R)
            }
        }
        // the body carried: the target follows the finger's speed (400 pt a second about 0.2R), at most strokeCarry; a spring with inertia follows, let go it runs past a little and comes back
        if n > 0 && !grab {
            tx = tx / n * 0.06; ty = ty / n * 0.06
            let l: Double = hypot(tx, ty), cap: Double = mat.strokeCarry * R * (reduceMotion ? 0.5 : 1)
            if l > cap { tx *= cap / l; ty *= cap / l }
        } else { tx = 0; ty = 0 }
        if stkOX != 0 || stkOY != 0 || tx != 0 || ty != 0 {
            let w: Double = 2 * Double.pi * mat.dragHz, zz: Double = 2 * (reduceMotion ? 0.9 : max(0.5, mat.dragSpring)) * w
            stkVX += (w * w * (tx - stkOX) - zz * stkVX) * dt
            stkVY += (w * w * (ty - stkOY) - zz * stkVY) * dt
            let dx: Double = stkVX * dt, dy: Double = stkVY * dt
            stkOX += dx; stkOY += dy
            if tx == 0 && ty == 0 && hypot(stkOX, stkOY) < 0.05 && hypot(stkVX, stkVY) < 0.5 {
                stkOX = 0; stkOY = 0; stkVX = 0; stkVY = 0
            } else {
                homeX += dx; homeY += dy
                for i in 0..<N where !GRAB[i] { X[i] += dx; Y[i] += dy; PX[i] += dx; PY[i] += dy }
            }
        }
    }

    /// v2.25 F4: at a release QD catches the body's shape as it is (minus the performance: the breathing and mood scale, the press push), so the next target is on the body
    /// and nothing jumps; it also takes the body's velocity about its centre (inertiaCarry, at most 6R a second). From here the spring alone decides how it goes back.
    private func inertiaCatch() {
        guard params.inertiaHz > 0, QDX.count == N, !clusters.isEmpty else { return }
        let g = clusters[gi], cs: Double = g.cs, sn: Double = g.sn, qcx: Double = g.qcx, qcy: Double = g.qcy
        let det0: Double = psm.a * psm.d - psm.b * psm.c, det: Double = det0 != 0 ? det0 : 1
        let i00: Double = psm.d / det, i01: Double = -psm.b / det, i10: Double = -psm.c / det, i11: Double = psm.a / det
        let pf = pressField()
        var mvx = 0.0, mvy = 0.0
        for i in 0..<N { mvx += X[i] - PX[i]; mvy += Y[i] - PY[i] }
        mvx /= Double(N); mvy /= Double(N)
        let kv: Double = 240 * params.inertiaCarry, cap: Double = R * 6
        for i in 0..<N {
            var px: Double = X[i] - g.xc, py: Double = Y[i] - g.yc
            if !pf.isEmpty { let q = pressPush(pf, X[i], Y[i]); px -= q.0; py -= q.1 }
            let rx: Double = cs * px + sn * py, ry: Double = -sn * px + cs * py
            QDX[i] = qcx + i00 * rx + i01 * ry; QDY[i] = qcy + i10 * rx + i11 * ry
            let vx: Double = (X[i] - PX[i] - mvx) * kv, vy: Double = (Y[i] - PY[i] - mvy) * kv
            var lx: Double = cs * vx + sn * vy, ly: Double = -sn * vx + cs * vy
            let ms: Double = hypot(lx, ly)
            if ms > cap { lx *= cap / ms; ly *= cap / ms }
            QVX[i] = lx; QVY[i] = ly
        }
    }

    private func release(_ id: ObjectIdentifier, quiet: Bool) {
        guard let f = fingers.removeValue(forKey: id) else { return }
        if f.propK >= 0 { propRelease(f) }   // v2.64 擺飾變真 (web releaseFinger: propRelease, hangRelease)
        if f.hangN != nil { hangRelease(f) }
        if f.mode == .grab { inertiaCatch() }
        for m in f.mem { GRAB[m.i] = false }
        for dn in dentList where dn.finger == id { dn.finger = nil; dn.held = t - f.tDown }   // held: how long it was pressed (D2)
        // v2.19 A4: a finger that never touched the body does not restart the fade-in; v2.20: nor one it reached by itself (lure)
        if !lv(params.lifeHeld) || f.mode == .grab || (f.hitT > -9 && !f.lure) { lastTouch = t }
        if f.mode == .grab { dragRelease(glide: !quiet) }
        if f.mode == .grab && !quiet { impRelease(f) }
        if f.mode == .grab && !quiet { moodRelease(f) }
        if f.mode == .grab && !quiet && f.scared && params.holdScared >= 0.5 && params.emo >= 0.5 && !escOn { flee(-pullDX, -pullDY, W * 0.22 * params.flee) }   // v2.63 D3: held open while scared, it protested; let go, it walks off the other way (as far as the old slip)
        if f.mode == .grab && !quiet && params.life2 >= 0.5 { lifeRelease(f) }
        if f.mode == .grab && !quiet { impAsk(f) }
        if f.mode == .grab && !quiet { e2Release(f) }   // v2.22
        if (f.mode == .grab || f.mode == .stroke) && !quiet && !escOn { eyeUser = t + 1.2 }   // v2.23: let go, it looks at you
        if f.mode == .grab && !quiet {
            // release strength: how fast it was flicked (peak speed over the last ~80 ms) or how far it was
            // stretched (tanh-limited stretch over the limit), whichever is bigger, so a slow let-go still pops
            let sv = min(1, f.peak / R / 6)
            // a full pull counts at 2R at most: clay's limit went to 8 for free sculpting, and the pop would have shrunk with it
            let ss = pow(min(1, f.stretch / max(0.01, min(effParams.maxPull, 2))), 1.5)
            var s = max(sv, ss)
            // 偶發特別回彈 (提案第 2 條): every `specialEvery` releases (±2) one comes back extra bouncy for 0.35 s
            var special = false
            releaseCount += 1
            if params.specialEvery > 0 {
                let every = Int(params.specialEvery.rounded())
                if nextSpecial == 0 { nextSpecial = max(1, every + Int.random(in: -2...2, using: &rng)) }
                if releaseCount >= nextSpecial {
                    special = true
                    specialUntil = t + 0.35
                    nextSpecial = max(releaseCount + 1, releaseCount + every + Int.random(in: -2...2, using: &rng))
                    s = min(1, s * 1.3)
                }
            }
            lastReleaseStrength = s
            relQuiet = params.flinchFx >= 0.5 && t >= flxSndT && t - flxSndT < FlxSet.win   // v2.63 D4 (web: the same test): the flinch sounded 0.3 s ago, no second pop sound
            if !relQuiet { flxRelT = t }
            onEvent?(.release(gain: 0.35 + 0.65 * s, rate: 1 + 0.1 * s, special: special))
            relQuiet = false
        }
    }

    /// The system took the touch away (edge gesture, call, app switch): let go quietly, no pop.
    func touchCancelled(_ id: ObjectIdentifier) {
        if twFg[id] != nil { twinRelease(id); return }   // v2.62
        release(id, quiet: true)
    }

    func cancelAllTouches() {
        for f in fingers.values { for m in f.mem { GRAB[m.i] = false } }
        fingers.removeAll()
        twFg.removeAll()   // v2.62
        softDrop()   // v2.61 C1: the app went to the background
        dragRelease(glide: false)   // v2.20: the offset joins home, as on a normal release
        lastTouch = t
    }

    // MARK: - External nudges (buttons, VoiceOver actions)

    /// Small whole-body shake.
    func bump(_ amount: Double = 1) {
        guard N > 0 else { return }
        let amp = R * 0.0025 * amount * (reduceMotion ? 0.5 : 1)
        let a = Double.random(in: 0..<(2 * .pi), using: &rng), ix = cos(a) * amp, iy = sin(a) * amp
        for i in 0..<N where !GRAB[i] { PX[i] -= ix; PY[i] -= iy }
    }

    /// Full rebuild (new seed). For the 揉回原形 button use `relax()`, which does not jump.
    func resetShape() {
        guard W > 0, H > 0 else { return }
        setup(width: W, height: H)
    }

    /// 揉回原形 without a jump: forget the molded shape over half a second and let the body ease back.
    func relax() {
        guard N > 0 else { return }
        relaxUntil = t + 0.5
        for dn in dentList { dn.p = 0; dn.v = 0; dn.p0 = 0 }
        for k in props.indices { if props[k].gone { props[k].backAt = t } else { props[k].lastHit = -1e3 } }   // v2.64 擺飾變真 (web relax): the things go back too
    }

    /// VoiceOver "拉長": tug the top upward.
    func stretchUp() {
        guard N > 0 else { return }
        for i in 0..<N where Q0Y[i] < -R * 0.3 && !GRAB[i] { PY[i] += R * 0.02 }
        onEvent?(.release(gain: 0.6, rate: 1, special: false))
    }

    /// v2.63 未做 83 (deskSmooth; web deskRebuild): a shape parameter changed (the desk's material switch, 回到預設, a slider, a slot). 0: setup as before
    /// (home, and on the sill dropped from above the bowl: up 0.7R and back down, the bounce). 1: only floppy changed (the three materials differ in
    /// nothing else): the same points and rest shape, floppy only sets the tentacle softness KF, so it changes in place, no rebuild (the molded shape,
    /// where it is and what it does all stay). Seed, size, density, limbs or the sill changed: on the sill's floor (not on the frame, outside, falling or held)
    /// or with no sill, rebuilt and the whole body moved back where it was (on the floor by its bottom, with no sill by its centre), home, camera and
    /// in the bowl or not as they were; otherwise as before. Verlet: positions and the previous frame move together (setup leaves PX = X: still no speed)
    private func deskRebuild() {
        guard params.deskSmooth >= 0.5, N > 0 else { setup(width: W, height: H); return }
        if params.seed == builtSeed && params.limbs == builtLimbs && params.bodySize == builtSize && params.dens == builtDens && (params.scene >= 0.5) == (builtScene >= 0.5) {
            for i in 0..<N { KF[i] = TID[i] >= 0 ? 1 - params.floppy * TU[i] : 1 }   // setup's KF = 1 − floppy × u (after a remesh TID is all −1 and KF all 1: the same)
            builtFloppy = params.floppy
            return
        }
        let on0 = sillOn
        let onFloor = on0 && !sillAir && sillPlane == .room && !sillGrab && !sillHeld
        if on0 && !onFloor { setup(width: W, height: H); return }
        var mx = 0.0, my = 0.0, y1 = -1e9
        for i in 0..<N { mx += X[i]; my += Y[i] }
        mx /= Double(N); my /= Double(N)
        for i in bnd { y1 = max(y1, Y[i]) }
        let air0 = sillAir, inBowl0 = sillInBowl, want0 = sillWant
        let cx0 = cx, cy0 = cy, homeX0 = homeX, homeY0 = homeY
        let camZ0 = camZ, camX0 = camX, camY0 = camY
        let folX0 = folX, folY0 = folY, folVX0 = folVX, folVY0 = folVY, folChase0 = folChase
        setup(width: W, height: H)
        guard sillOn == on0 else { return }
        var nx = 0.0, ny = 0.0, n1 = -1e9
        for i in 0..<N { nx += X[i]; ny += Y[i] }
        nx /= Double(N); ny /= Double(N)
        for i in bnd { n1 = max(n1, Y[i]) }
        let dx = mx - nx, dy = onFloor ? y1 - n1 : my - ny
        for i in 0..<N { X[i] += dx; PX[i] += dx; Y[i] += dy; PY[i] += dy }
        cx = cx0; cy = cy0; homeX = homeX0; homeY = homeY0
        if onFloor { sillAir = air0; sillInBowl = inBowl0; sillWant = want0 }
        camZ = camZ0; camX = camX0; camY = camY0
        folX = folX0; folY = folY0; folVX = folVX0; folVY = folVY0; folChase = folChase0
    }

    // MARK: - Per-frame

    func update(_ dt: Double) {
        guard N > 0 else { return }
        guardFold()   // v2.52 A5
        t += dt
        if params.seed != builtSeed || params.floppy != builtFloppy || params.limbs != builtLimbs || params.bodySize != builtSize || params.dens != builtDens || (params.scene >= 0.5) != (builtScene >= 0.5) {   // v2.59: day to night does not rebuild it (as on the web)
            deskRebuild()   // v2.63 未做 83 (deskSmooth 0: setup as before)
        } else if params.cSpace != builtSpace || params.cRad != builtRad {
            buildClusters()
        }
        let mat = effParams
        if mat.homeFrac != builtHome { builtHome = mat.homeFrac; cy = H * mat.homeFrac; homeY = cy }   // 候選 33
        // 候選 26: a stuck finger lets go when its time is up
        for (id, f) in fingers where f.sticking && t >= f.releaseAt { release(id, quiet: false) }

        updateCam(dt)
        for f in fingers.values where f.mode == .grab {
            if f.reach { reachGrab(f) }
            else if let n = f.reachN, n <= f.mem.count, hypot(f.rawX - f.ax, f.rawY - f.ay) < R * 0.25 {   // v2.24: back near the start, the strip lets go
                for k in n..<f.mem.count { GRAB[f.mem[k].i] = false }
                f.mem.removeLast(f.mem.count - n); f.reachN = nil; f.reach = true
            }
        }
        pressSum = 0
        if mat.press2 >= 0.5 {
            // v2.16 (多米: the press looked like a toy): 60% in 40 ms, the rest by the material (pressSink); held longer it gets
            // wider and shallower (w). Released, p springs back by pressBounce (jelly overshoots outward once); clay does not
            // bounce and lets go fast (the shape is already remembered); d fades at the relax rate on clay, with p elsewhere
            for dn in dentList {
                if let id = dn.finger, let f = fingers[id] {
                    let moved = hypot(f.rawX - f.ax, f.rawY - f.ay)
                    if moved > R * 0.4 && (mat.dentTrail <= 0 || f.stretch > 0.8) { dn.pull = true }   // v2.26 F7: rubbing (not really pulled open), the dent goes along with the finger
                    if dn.pull {
                        let k2 = 1 - exp(-dt / 0.12)
                        dn.d -= dn.d * k2; dn.p -= dn.p * k2; dn.v = 0
                    } else {
                        // past 0.15R it is a drag, not a press: no more sinking and the push fades (T28: grabbing the edge and
                        // pulling out with the push still on dropped the kept share to 0.80; without the push 0.83)
                        let drag = moved >= R * 0.15
                        if !drag { dn.tau += dt }
                        let c = 0.6 * (1 - exp(-dn.tau / 0.013)) + 0.4 * (1 - exp(-dn.tau / max(0.02, mat.pressSink)))
                        dn.p = drag ? dn.p * exp(-dt / 0.12) : max(dn.p0, c); dn.d = max(dn.d, c); dn.v = 0; dn.w = 1 - exp(-dn.tau / 1.5)
                    }
                } else {
                    dn.finger = nil
                    let b = mat.pressBounce
                    if b >= 0.95 {
                        dn.p *= exp(-dt / 0.25); dn.v = 0
                    } else {
                        let om = 2 * Double.pi * (mat.inertiaHz > 0 ? mat.inertiaHz : 5)   // v2.25: the same beat as the release
                        dn.v += (-om * om * dn.p - 2 * b * om * dn.v) * dt; dn.p += dn.v * dt
                    }
                    dn.d *= exp(-(dn.pull ? 8 : t < relaxUntil ? 6 : max(mat.recover, 0.02, dentRate(dn))) * dt)   // v2.20 D2: the dent's own recovery
                    if b < 0.95 { dn.d = min(dn.d, max(0, dn.p)) }
                }
            }
            dentList.removeAll { $0.finger == nil && $0.d < 0.02 && abs($0.p) < 0.01 && abs($0.v) < 0.05 }
            for dn in dentList { pressSum += dn.p }
            pressSum = max(-0.6, min(1.5, pressSum))
        }
        for dn in dentList where mat.press2 < 0.5 {
            if let id = dn.finger, let f = fingers[id] {
                if hypot(f.rawX - f.ax, f.rawY - f.ay) > R * 0.4 { dn.pull = true }
                let tg = dn.pull ? 0.0 : 1.0
                dn.d += (tg - dn.d) * (1 - exp(-dt / (tg > 0 ? 0.08 : 0.12)))
            } else {
                dn.finger = nil
                dn.d *= exp(-(dn.pull ? 8 : t < relaxUntil ? 6 : max(mat.recover, 0.02, dentRate(dn))) * dt)   // v2.20 D2: the dent's own recovery
            }
        }
        if mat.press2 < 0.5 { dentList.removeAll { $0.finger == nil && $0.d < 0.02 } }
        // finger lag: effective position = start + tanh-limited displacement, then chase it
        for f in fingers.values {
            // chase target: the prediction only on a frame that got a fresh move event, else the real finger,
            // so the body never rests a step ahead of a finger that stopped (手感精修提案 第 7 條)
            if f.movedThisFrame && f.hasPrediction { f.x = f.predX; f.y = f.predY } else { f.x = f.rawX; f.y = f.rawY }
            f.movedThisFrame = false
            // velocity from the real finger: raw, ~30 ms smoothed, and a ~80 ms decaying peak for the release pop
            f.vx = (f.rawX - f.lastRawX) / dt; f.vy = (f.rawY - f.lastRawY) / dt
            let sfMv: Double = hypot(f.rawX - f.lastRawX, f.rawY - f.lastRawY)   // v2.64 B8：真手指這一格動了多少（網頁 hypot(f.x−f.lx, f.y−f.ly)），只給 lagK 用
            f.lastRawX = f.rawX; f.lastRawY = f.rawY
            let kv = 1 - exp(-dt / 0.03)
            f.vxS += (f.vx - f.vxS) * kv; f.vyS += (f.vy - f.vyS) * kv
            f.peak = max(hypot(f.vx, f.vy), f.peak * exp(-dt / 0.08))
            f.speedC += (f.travelFrame / dt - f.speedC) * kv
            f.travelFrame = 0
            f.stillT = hypot(f.vxS, f.vyS) < R * 0.5 ? f.stillT + dt : 0   // v2.19 A4: held still long enough, each breath taps softly

            // v2.21 D1' pull: the stretch limit counts from where the body has already followed to (o). Counted from where the finger
            // landed, jelly stops at 1.6R and the body cannot be pulled along
            let sl = mat.slide > 0 && f.mode == .grab, ox = sl ? dragOX - dragBX : 0, oy = sl ? dragOY - dragBY : 0
            var ex = f.x - f.ax - ox, ey = f.y - f.ay - oy
            let el = hypot(ex, ey), lim = mat.maxPull * R
            if f.mode == .grab && el > 0 {
                let s = lim * tanh(el / lim) / el
                ex *= s; ey *= s
            }
            // the finger keeps 0.35R off the walls: a held patch pressed flat against a wall crossed on release (4 of 6 trials)
            let mw = R * 0.35, wl = worldWalls   // the walls are in world points (the farthest view's edge)
            let tx = max(wl.l + mw, min(wl.r - mw, f.ax + ox + ex + f.slx)), ty = max(wl.t + mw, min(wl.b - mw, f.ay + oy + ey + f.sly))   // v2.48: plus how far it has given way
            // v2.48: the finger moving back the way it gave takes that much up again; the rest fades over 2 s
            if f.slx != 0 || f.sly != 0 {
                let l: Double = hypot(f.slx, f.sly)
                if l < 0.01 {
                    f.slx = 0; f.sly = 0
                } else if !f.slLX.isNaN {
                    let ux: Double = f.slx / l, uy: Double = f.sly / l
                    let back: Double = max(0, (f.x - f.slLX) * ux + (f.y - f.slLY) * uy)
                    let nl: Double = max(0, l - back) * exp(-dt / 2)
                    f.slx = ux * nl; f.sly = uy * nl
                }
            }
            f.slLX = f.x; f.slLY = f.y
            f.tgx = tx; f.tgy = ty; f.lagK = lagK(f, dt, lag: mat.lag, sf: mat.startFollow >= 0.5, mv: sfMv)   // v2.38: the target first; chased after the two-finger limit (pairStep). v2.64 B8 起步跟手在 lagK
            if f.mode == .grab {
                let st = hypot(ex, ey) / R, step = Int(floor(st * 2.5))
                f.stretch = st; f.ex = ex; f.ey = ey
                do {   // v2.63 B1 B3 (pullFx; web: the same line): the farthest the real finger got from where it took hold, and how fast it opens new ground
                    let op: Double = hypot(f.rawX - f.ax, f.rawY - f.ay) / R, d: Double = max(0, op - f.om)
                    f.om = max(f.om, op)
                    f.ov += (d / dt - f.ov) * (1 - exp(-dt / PullFxSet.tv))
                }
                if roughOn {   // v2.61 D1 (rough): the fastest this grab has been, and whether it has been yanked (fast, outward, pulled open; stays so until it lets go)
                    let hv: Double = hypot(f.vxS, f.vyS) * camZ / R, outward: Double = ex * f.vxS + ey * f.vyS
                    if hv > f.vMax { f.vMax = hv }
                    if !f.yank && hv >= RoughSet.v && st > RoughSet.st && outward > 0 { f.yank = true }
                } else {
                    f.vMax = 0; f.yank = false
                }
                if step > f.step && st > 0.35 {
                    onEvent?(.pull(gain: min(1, 0.4 + st / 2), rate: 1 - 0.08 * min(1, st / 1.5)))
                }
                f.step = max(f.step, step)
                if mat.sndB6 >= 0.5 { while f.step > 0 && st * 2.5 < Double(f.step) - 1.5 { f.step -= 1 } }   // v2.63 B6 (web: the same line): pulled back 1.5 steps, one step down, so pulling out again snaps again
                // press (接觸點先凹): the grabbed patch spreads away from the finger. The first frame jumps to
                // `pressFirst` of the target (the first frame must move), the rest follows with `pressRise`;
                // holding still (slower than one radius per second) sinks it deeper over `pressHoldTime`.
                let still = hypot(f.vxS, f.vyS) < R
                f.hold = max(0, min(1, f.hold + (still ? dt / max(0.05, mat.pressHoldTime) : -dt / 0.3)))
                // 提案第 9 條: contact size (majorRadius) as pressure. Baseline = smallest radius in the first
                // 100 ms after landing; every extra 8 pt of radius is one unit, smoothed over 50 ms.
                if f.radius > 0 {
                    if f.r0 <= 0 || (t - f.tDown < 0.1 && f.radius < f.r0) { f.r0 = f.radius }
                    let pr = max(0, min(1, (f.radius - f.r0) / 8))
                    f.prS += (pr - f.prS) * (1 - exp(-dt / 0.05))
                }
                // v2.47 pressPull: pulled away, the spread fades (0.15R to 0.6R from where the finger landed). The spread is for a press; on a long pull held still it tore the grabbed patch
                let pulled: Double = max(st, hypot(f.rawX - f.ax, f.rawY - f.ay) / R)
                let pq: Double = mat.pressPull >= 0.5 ? max(0, min(1, (pulled - 0.15) / 0.45)) : 0
                let pressFade: Double = 1 - pq * pq * (3 - 2 * pq)
                let target: Double = R * (mat.pressBase + mat.pressHold * f.hold + 0.15 * mat.pressRadiusGain * f.prS) * pressFade
                if !f.pressOn {
                    f.press = target * mat.pressFirst
                    f.pressOn = true
                } else {
                    f.press += (target - f.press) * (1 - exp(-dt / max(0.005, mat.pressRise)))
                }
                // v2.25 F5 grains (提案第 13 條): one every `tickSpacing` points of real travel (±30%), closer as it is stretched (tickTense), at most tickRate a second, none while the finger is still
                if mat.tickSpacing > 0 {
                    let pullK: Double = min(1, f.stretch / 2), tense: Double = 1 - mat.tickTense * pullK
                    if f.tickNext <= 0 { f.tickNext = mat.tickSpacing * tense; f.tickAt = f.travel }
                    if f.travel - f.tickAt >= f.tickNext && f.speedC > R * 0.1 && t - tickLastT >= 1 / max(1, mat.tickRate) {
                        f.tickAt = f.travel   // what was travelled while capped is forgiven: no burst afterwards
                        f.tickNext = mat.tickSpacing * tense * (0.7 + 0.6 * Double.random(in: 0..<1, using: &rng))
                        tickLastT = t
                        onEvent?(.tick(gain: min(1, max(f.speedC / (R * 3), 0.5 * pullK))))
                    }
                }
                // v2.25 F5 pressing in (the 3D-Press idea; a phone has no force, time and contact size stand in): after the landing tap, grains fading over 0.3 s while the finger stays put; the contact patch growing or shrinking adds one
                // every kind of grain shares the one limit (tickLastT); a contact size that flickers on a still finger must not buzz, so at most 4 of those a second
                if mat.pressGrain >= 0.5 && !f.far {
                    let free: Bool = t - tickLastT >= 1 / max(1, mat.tickRate)
                    if free && f.grainI < Self.grainTimes.count && t - max(f.tDown, f.tGrab) >= Self.grainTimes[f.grainI] {
                        onEvent?(.grain(gain: Self.grainGains[f.grainI])); f.grainI += 1; tickLastT = t
                    } else if f.radius > 0 {
                        if f.grR <= 0 { f.grR = f.radius }
                        if free && abs(f.radius - f.grR) >= 3 && t - f.grT > 0.25 { f.grR = f.radius; f.grT = t; tickLastT = t; onEvent?(.grain(gain: 0.5)) }
                    }
                }
            }
        }

        pairStep(dt)   // v2.38 the limit between two fingers, and tearing
        for f in fingers.values { f.fx += (f.tgx - f.fx) * f.lagK; f.fy += (f.tgy - f.fy) * f.lagK }
        strokeStep(dt)   // v2.26 F6
        gooStep(dt); splitCheck(dt); twinStep(dt)   // v2.51 the strand; v2.62 the tear, the second slime
        dragStep(dt)   // v2.20 D1: home follows `drag` of the fingers' travel; how far the body itself is pulled open (sb); C3 slipping free

        // press flat: as far as the finger went down (relative to the height when it began) the remembered shape squashes,
        // wider by the inverse (area kept). The table is the bottom at the start; while pressing, home moves to "bottom on the
        // table"; on release the table goes, home comes back, it floats up, and the flat shape relaxes at `recover`
        flatOn = false
        for f in fingers.values where f.flatOn && f.mode == .grab {
            let target = max(mat.flatMin, 1 - max(0, f.fy - f.ay) / f.h0)
            if abs(target - f.flat) > 1e-4 {
                let r = target / f.flat
                for i in 0..<N { QY[i] *= r; QX[i] /= r }
                f.flat = target
            }
            flatOn = true; flatFloor = f.bot
        }
        if flatOn { var qb = -1e9; for i in bnd { qb = max(qb, QY[i]) }; flatQB = qb }
        // 候選 25 拉太遠滑脫: raw pull past 1.2× the limit for 120 ms lets go (lift and press again to grab), heaviest pop
        if mat.slip >= 0.5 {
            for f in fingers.values where f.mode == .grab {
                let raw = hypot(f.x - f.ax, f.y - f.ay) / R
                if raw > mat.maxPull * 1.2 {
                    f.over += dt
                    if f.over >= 0.12 {
                        inertiaCatch()
                        for m in f.mem { GRAB[m.i] = false }
                        f.mem = []; f.mode = .none; f.over = 0
                        lastTouch = t; lastReleaseStrength = 1
                        onEvent?(.release(gain: 1, rate: 1.1, special: false))
                    }
                } else {
                    f.over = 0
                }
            }
        }
        // 提案第 24 條 兩指捏: two grabbing fingers closing to 60% of their starting distance fire a squish, then every further 15%
        if mat.pinchSquish >= 0.5 {
            let gs = fingers.filter { $0.value.mode == .grab }.sorted { $0.value.tDown < $1.value.tDown }
            if gs.count >= 2 {
                let (ia, a) = gs[0], (ib, b) = gs[1]
                let d = hypot(a.rawX - b.rawX, a.rawY - b.rawY)
                if pinchA != ia || pinchB != ib { pinchA = ia; pinchB = ib; pinchD0 = max(1, d); pinchNext = 0.6 }
                let r = d / pinchD0
                if r <= pinchNext {
                    onEvent?(.squish(gain: 0.6 + 0.3 * (1 - r)))
                    pinchNext -= 0.15
                }
            } else {
                pinchA = nil; pinchB = nil
            }
        }

        // idle life: only when nobody is touching, fading in over a second after release
        // v2.19 A4: only a finger really on the body (grabbing, or pushing it) counts; a finger on empty space does not freeze it
        var engaged = false
        // v2.20 C1: it reaching your resting finger by itself is not you touching it (no freezing)
        for f in fingers.values where !lv(mat.lifeHeld) || f.mode == .grab || (t - f.hitT < 0.3 && !(f.lure && hypot(f.vxS, f.vyS) < R)) { engaged = true }
        let idle = engaged ? 0 : min(1, max(0, (t - lastTouch - 0.8) / 1.2))
        let L = idle * (reduceMotion ? 0.5 : 1)
        // 提案第 19 條: with idleFreeze the idle motion keeps its amplitude and only its clock stops while touched
        // (the body holds its breath instead of snapping to the rest pose); L still gates twitch, wander and sway
        tLife += dt * L
        let freeze = mat.idleFreeze >= 0.5
        let Lamp = freeze ? (reduceMotion ? 0.5 : 1) : L
        let tl = freeze ? tLife : t
        lifeLB = lv(mat.lifeHeld) ? max(Lamp, mat.heldBreath * (reduceMotion ? 0.5 : 1)) : Lamp   // v2.19 A4: the breathing goes on while held
        exert *= exp(-dt / 4)
        do {
            let tw: Double = !lv(mat.lifeRest) ? 1 : (lifeSt == .rest || lifeSt == .sleep ? mat.restWrig * (1 - 0.6 * slpK) : (lifeSt == .look ? 0.6 : 0.5))
            lifeWrg += (tw - lifeWrg) * (1 - exp(-dt / 0.8))   // v2.19 A1: the wriggle drops while resting
            let gf: Double = lv(mat.lifeGait) && (gaitOn || lifeSt == .arrive) ? 1 : 0
            goFade += (gf - goFade) * (1 - exp(-dt / 0.25))   // A3: the jellyfish pulse fades while walking; the contraction is the walking
        }
        // 提案第 23 條 breathing: accumulated phase (the period can change without a jump); at the control values
        // (3.8 s sine) this is exactly the old waveform
        do {
            var T = mat.jelly >= 0.5 ? mat.jellyT : mat.breathT, amp = 1.0
            if snwK > 0 { T = T * (1 - snwK) + mat.calmBreathT * snwK; amp *= 1 + 0.4 * snwK }   // v2.31: the glitter settling, 6 breaths a minute, taking you down with it
            do {   // v2.18: comfortable slow and deep, tense fast and shallow
                let cp = max(0, moodC), ar = max(moodA, moodScare)
                T *= (1 + 0.4 * cp) * (1 - 0.4 * ar); amp *= (1 + 0.5 * cp) * (1 - 0.4 * ar)
                if iv3(mat.e3) { T *= 1 + 0.25 * impShownTrust }   // v2.22 E3: trusting, it breathes slower
                if slpK > 0 { T *= 1 + 0.6 * slpK; amp *= 1 + 0.35 * slpK }   // v2.23 B2: asleep, slow and deep
            }
            if mat.breathDeep >= 0.5 {
                // 23c: after a grab held longer than 10 s, the next 20 s breathe 1.5× deeper and 1.2× slower, fading linearly
                let grabbing = fingers.values.contains { $0.mode == .grab }
                if grabbing {
                    if brGrabStart < 0 { brGrabStart = t }
                } else {
                    if brGrabStart >= 0 && t - brGrabStart > 10 { brDeepAt = t }
                    brGrabStart = -1
                }
                let f = max(0, 1 - (t - brDeepAt) / 20)
                amp = 1 + 0.5 * f; T *= 1 + 0.2 * f
            }
            brAmpX = 1
            if lv(mat.lifeBreath) {
                // v2.19 A6: each breath a little different (smooth noise ±15%); panting (exert) twice as fast and 30% shallower; a sigh
                // every 30...90 s (1.8× deeper, 1.6× slower), then a 1 s pause before the next
                if sighNext < 0 { sighNext = t + 30 + Double.random(in: 0..<60, using: &rng) }
                let ex = exert, cyc = Int(floor(brPhase))
                T *= (1 + 0.15 * Self.vnoise(77, brPhase * 0.9)) * (1 - 0.5 * ex); brAmpX = 1 - 0.3 * ex
                if sighCyc < 0 && t > sighNext && ex < 0.2 && lifeSt != .go { sighCyc = cyc + 1; if !slpOn { onEvent?(.fx(kind: "sigh", gain: 0.45, delay: 0)) } }
                if cyc == sighCyc { T *= 1.6; brAmpX *= 1.8 }
                else if sighCyc >= 0 && cyc > sighCyc { sighCyc = -1; pauseUntil = t + 1; sighNext = t + 30 + Double.random(in: 0..<60, using: &rng) }
            }
            amp *= brAmpX
            if t >= pauseUntil { brPhase += (tl - brPrev) / T }
            brPrev = tl; brAmp = amp
            do { let c = Int(floor(brPhase)); if c != brCyc { brCyc = c; breathBeat &+= 1 } }   // v2.19 A4: one count per breath
            let ph = brPhase - floor(brPhase)
            // 23b: inhale 40%, exhale 55%, pause 5%
            if mat.breathShape >= 0.5 {
                brWave = ph < 0.4 ? -cos(.pi * ph / 0.4) : (ph < 0.95 ? cos(.pi * (ph - 0.4) / 0.55) : -1)
            } else {
                brWave = sin(2 * .pi * ph)
            }
        }

        // jellyfish pulse (多米 2026-11-01: a regular rhythm, like a jellyfish): the first 22% of the period contracts fast
        // (sine ease-out), the rest relaxes slowly (cosine); contracted is narrower and taller, through the same reference
        // scaling as the breathing. Each contraction pushes `brLift` up; it sinks back with a 1 s time constant
        if mat.jelly >= 0.5 {
            let ph = brPhase - floor(brPhase), c = 0.22
            let w = ph < c ? sin(.pi / 2 * ph / c) : 0.5 * (1 + cos(.pi * (ph - c) / (1 - c)))
            let w2 = w * (1 - snwK) + 0.5 * (1 - cos(2 * .pi * ph)) * snwK   // v2.31: settling, a smooth slow breath instead of the pulse
            let dw = w2 - brJw
            brJw = w2; brWave = -w2; brAmp = (1 + 0.4 * snwK) * mat.jellyAmp / 0.045 * (1 + 0.5 * max(0, moodC)) * (1 - 0.4 * max(moodA, moodScare)) * brAmpX * (1 + 0.35 * slpK)
            if dw > 0 { brLift += dw * mat.jellyLift * R * Lamp * mat.life * (1 - goFade) }
        }
        brLift *= exp(-dt / 1.0)
        // pseudopods: born, grow, hold, retract, gone. Their clock runs with the idle life (stops while touched) at idlePace
        do {
            let adv = dt * L * mat.idlePace
            for k in pods.indices { pods[k].p += adv / pods[k].D }
            pods.removeAll { $0.p >= 1 }
            podClock += adv
            if mat.pods > 0 && !lv(mat.lifeRest) && pods.count < Int(mat.pods.rounded()) && podClock >= podNext {   // v2.19 A2: no random pods, pseudopods only sniff
                var a = 0.0
                for _ in 0..<10 {
                    a = Double.random(in: 0..<(2 * .pi), using: &rng)
                    if pods.allSatisfy({ abs(atan2(sin(a - $0.a), cos(a - $0.a))) > 1.1 }) { break }
                }
                pods.append(Pod(a: a, L: mat.podLen * (0.7 + 0.5 * Double.random(in: 0..<1, using: &rng)), sig: 0.22 + 0.1 * Double.random(in: 0..<1, using: &rng),
                                bend: (Double.random(in: 0..<1, using: &rng) - 0.5) * 0.8, D: 4 + 4 * Double.random(in: 0..<1, using: &rng)))
                podNext = podClock + 0.8 + 2.2 * Double.random(in: 0..<1, using: &rng)
            }
            func ease(_ x: Double) -> Double { x * x * (3 - 2 * x) }
            let cw = t < cowerUntil ? 1 : max(0, 1 - (t - cowerUntil) / 0.6)   // v2.18 curled up: pods drawn in
            let strain = moodStrain
            podE = pods.map { q in
                let e = q.p < 0.4 ? ease(q.p / 0.4) : (q.p < 0.6 ? 1 : ease((1 - q.p) / 0.4))
                return (cos(q.a), sin(q.a), q.L * R * e * (reduceMotion ? 0.5 : 1) * (1 - cw) * (1 - strain), q.sig, q.bend)
            }
            if mat.emo >= 0.5 && !clusters.isEmpty {
                let ga = atan2(clusters[gi].sn, clusters[gi].cs), rm = reduceMotion ? 0.5 : 1.0
                // wanting away: two pseudopods on the far side reach out (bending to and fro, clawing), with the strain
                if strain > 0.02 && mat.struggle >= 0.5 {   // v2.48 struggle 0: no clawing pods while pulled
                    let aw = atan2(-pullDY, -pullDX) - ga
                    for sd in [-1.0, 1.0] {
                        podE.append((cos(aw + sd * 0.5), sin(aw + sd * 0.5), R * 0.42 * strain * rm, 0.22, sd * 0.5 * sin(t * 7 + sd)))
                    }
                }
                // happy wag: one pseudopod upper right swings 4 times (1.6 s)
                let wt = t - wagT
                if wt > 0 && wt < 1.6 {
                    let e = sin(.pi * wt / 1.6), aw = -Double.pi / 2 + 0.7
                    podE.append((cos(aw), sin(aw), R * 0.32 * e * rm, 0.2, 1.1 * sin(2 * .pi * 2.5 * wt)))
                }
            }
            // v2.19 A2, A7 sniffing: a pseudopod out toward that way, its tip swaying a little while it holds (as if smelling), plus a
            // very wide bulge so the body leans that way; dropped once drawn back in
            if !sniffs.isEmpty && !clusters.isEmpty {
                let ga = atan2(clusters[gi].sn, clusters[gi].cs), rm = reduceMotion ? 0.5 : 1.0
                sniffs.removeAll { sniffEnv($0) <= 0 && t > $0.t0 + 0.1 }
                for s in sniffs {
                    let e = sniffEnv(s), ar = s.a - ga, ca = cos(ar), sa = sin(ar)
                    podE.append((ca, sa, s.L * R * e * rm, 0.2, 0.3 * sin(t * 5.3 + s.ph) * min(1, 2 * e)))
                    podE.append((ca, sa, R * 0.07 * e * rm, 0.85, 0))
                }
            }
            // v2.22 E2: a lean toward the finger (wary: away), a push at a held finger; wary and dragged, two pseudopods claw on the far side
            if iv3(mat.e2) && !clusters.isEmpty {
                let ga = atan2(clusters[gi].sn, clusters[gi].cs), rm = reduceMotion ? 0.5 : 1.0, u = t - leanT
                if u > 0 && u < 0.7 {
                    let e = sin(.pi * u / 0.7), a = leanA - ga + (leanS < 0 ? .pi : 0)
                    podE.append((cos(a), sin(a), R * mat.leanAmp * e * rm, 0.9, 0))
                }
                do {   // v2.24: the whole body shifts toward the finger and back (the bulge alone only adds 0.07R at the edge)
                    let env: Double = u > 0 && u < 0.7 ? sin(Double.pi * u / 0.7) : 0, way: Double = leanS < 0 ? -1 : 1
                    let tg: Double = R * mat.leanMove * env * rm * way, dO: Double = tg - leanO
                    if dO != 0 { moveHome(cos(leanA) * dO, sin(leanA) * dO, dt); leanO = tg }
                }
                if let g = firstGrab(), impWary > 0.4, moodStrain < 0.02 {
                    let aw = atan2(clusters[gi].yc - g.fy, clusters[gi].xc - g.fx) - ga, am = R * 0.3 * min(1, (impWary - 0.4) / 0.4) * rm
                    for sd in [-1.0, 1.0] { podE.append((cos(aw + sd * 0.5), sin(aw + sd * 0.5), am, 0.22, sd * 0.5 * sin(t * 7 + sd))) }
                }
            }
            // area: along the reference boundary, the area the pods add (∮ r·Δr + Δr²/2 dθ), taken back all round with the
            // same (r/Rb)² weight (only subtracting each pod's mean left the area 3% to 5% high)
            twinPods()   // v2.62 the merge's lumps and ripples
            podShift = 0
            if !podE.isEmpty {
                let Rb = R * 0.98, nb = bnd.count
                var num = 0.0, den = 0.0
                for k in 0..<nb {
                    let i = bnd[k], j = bnd[(k + 1) % nb], h0 = bnd[(k + nb - 1) % nb], x = QX[i], y = QY[i], r = hypot(x, y)
                    if r < 1e-6 { continue }
                    let dth = abs(atan2(QX[h0] * QY[j] - QY[h0] * QX[j], QX[h0] * QX[j] + QY[h0] * QY[j])) / 2
                    let c1 = x / r, s1 = y / r, rn = min(1.6, (r / Rb) * (r / Rb))
                    var dr = 0.0
                    for q in podE {
                        let da = atan2(s1 * q.ca - c1 * q.sa, c1 * q.ca + s1 * q.sa)
                        dr += q.amp * exp(-da * da / (2 * q.sig * q.sig)) * rn
                    }
                    num += (r * dr + dr * dr / 2) * dth; den += (r + dr) * rn * dth
                }
                podShift = den > 0 ? num / den : 0
            }
        }

        // wandering home (提案第 20、31 條): pick a spot, walk there with a smoothstep speed profile (6p(1−p): same average
        // speed and the same walk-then-rest rhythm as the constant-speed version), rest a while; stop when touched.
        // Reduce Motion halves the speed again (×0.25 together with L)
        wanderVX = 0; wanderVY = 0; strK = 1
        moodStep(dt)
        moodColorStep(dt)
        impStep(dt)   // v2.20
        e1Step(); e2Step(dt)   // v2.22
        if params.tapBack >= 0.5 || tbAt >= 0 || tbUntil >= 0 { tbStep() }   // v2.64 D8 頂回來（網頁：e2Step 後面）
        sleepStep(dt); napStep(dt); echoStep(dt)   // v2.23 B2, C6; v2.63 C9 nap at your hand (web: the same place)
        greetStep()   // v2.63 C4 (web: right after sleepStep, echoStep)
        if brOn {   // v2.63 大腦 (web: if(SILL.on)sillStepPre(); brainStep(dt,engaged); before lifeStep). sillStepPre again before the substeps, as before: it only reads the fingers
            if sillOn { sillStepPre() }
            brainStep(dt, engaged)
        }
        if mat.life2 >= 0.5 {
            lifeStep(dt, idle, engaged)   // v2.19: rest / look / go / arrive + the pulse gait + flinch, shake-off + sniffing (with lifeRest and lifeGait off, v2.18's walk-and-pause)
        } else if L > 0.5 && mat.wander > 0 && !introOn && !escOn && t > cowerUntil {
            if !wanderMoving && t > wanderNext {
                wanderSX = homeX; wanderSY = homeY
                var sp = 1.0
                if mat.camFollow >= 0.5 {
                    // v2.17: walk out from where it is; with the `dash` chance far and fast (2.5×: the camera lags, it leaves the screen
                    // a bit). Over three view widths from the start it heads back
                    let far = Double.random(in: 0..<1, using: &rng) < mat.dash
                    let dist = W * (far ? 0.5 + 0.4 * Double.random(in: 0..<1, using: &rng) : 0.2 + 0.3 * Double.random(in: 0..<1, using: &rng))   // v2.18: walks further (多米: it always sits in the middle)
                    var a = Double.random(in: 0..<(2 * .pi), using: &rng)
                    if hypot(homeX - cx, homeY - cy) > W * 3 { a = atan2(cy - homeY, cx - homeX) + Double.random(in: -0.5..<0.5, using: &rng) }
                    wanderX = homeX + cos(a) * dist; wanderY = homeY + sin(a) * dist * 0.8
                    if far { sp = 2.5 }
                } else {
                    wanderX = cx + (Double.random(in: 0..<1, using: &rng) - 0.5) * W * 0.36
                    wanderY = cy + (Double.random(in: 0..<1, using: &rng) - 0.5) * H * 0.16
                }
                wanderT = max(0.5, hypot(wanderX - homeX, wanderY - homeY) / (mat.wander * sp * R * (reduceMotion ? 0.5 : 1)))
                wanderP = 0
                wanderMoving = true
            }
            if wanderMoving {
                wanderP = min(1, wanderP + dt * L / wanderT)
                let p = wanderP, e = p * p * (3 - 2 * p)
                let nx = wanderSX + (wanderX - wanderSX) * e, ny = wanderSY + (wanderY - wanderSY) * e
                wanderVX = (nx - homeX) / dt; wanderVY = (ny - homeY) / dt
                homeX = nx; homeY = ny
                if p >= 1 {
                    wanderMoving = false
                    wanderNext = t + (mat.camFollow >= 0.5 ? 0.8 + Double.random(in: 0..<2.2, using: &rng) : 1.5 + Double.random(in: 0..<5, using: &rng))   // v2.18: shorter rests
                }
            }
        } else if !fingers.isEmpty {
            wanderMoving = false
            wanderNext = t + 2 + Double.random(in: 0..<3, using: &rng)
        }

        if mat.morph >= 0.5 { morphCoef(tl * mat.idlePace) }   // idlePace (多米 2026-11-01: the wriggle was too fast)
        let n = max(1, Int((dt * 240).rounded()))
        let sdt = dt / Double(n)
        if introOn { introStep(dt, sdt) }
        do {
            let u = introU, ts = introOn ? introS0 + (1 - introS0) * pow(u, 1.5) : 1, fo = pow(1 - u, 1.2)
            let tx = introOn ? introOX0 * fo : 0, ty = introOn ? introOY0 * fo : 0, k = introOn ? 1 : 1 - exp(-dt / 0.08)
            ivS += (ts - ivS) * k; ivOX += (tx - ivOX) * k; ivOY += (ty - ivOY) * k
            if !introOn && abs(ivS - 1) < 1e-3 { ivS = 1; ivOX = 0; ivOY = 0 }
        }
        // v2.25 F4 a drag's inertia: only while grabbed. The centroid's acceleration smoothed over 30 ms, at most 80R a second a second; the weight grows with the distance from the finger, 1 from 2R out
        do {
            let gr = fingers.values.filter { $0.mode == .grab }
            let gx: Double = clusters.isEmpty ? 0 : clusters[gi].xc, gy: Double = clusters.isEmpty ? 0 : clusters[gi].yc
            if mat.inertiaHz > 0 && mat.inertiaDrag > 0 && !gr.isEmpty && QW.count == N, let px = cpX, let py = cpY {
                let kA: Double = 1 - exp(-dt / 0.03), vx: Double = (gx - px) / dt, vy: Double = (gy - py) / dt
                let ax: Double = (vx - cvX) / dt, ay: Double = (vy - cvY) / dt
                cvX = vx; cvY = vy; caX += (ax - caX) * kA; caY += (ay - caY) * kA
                let al: Double = hypot(caX, caY), am: Double = R * 80
                if al > am { caX *= am / al; caY *= am / al }
                let r2: Double = 1 / (2 * R)
                for i in 0..<N {
                    var d = 1e9
                    for f in gr { d = min(d, hypot(X[i] - f.fx, Y[i] - f.fy)) }
                    QW[i] = GRAB[i] ? 0 : min(1, d * r2)
                }
            } else {
                caX = 0; caY = 0
                if let px = cpX, let py = cpY { cvX = (gx - px) / dt; cvY = (gy - py) / dt } else { cvX = 0; cvY = 0 }
            }
            cpX = gx; cpY = gy
        }
        lastSdt = sdt
        if sillOn { sillStepPre() }   // v2.28 窗台
        remeshCalmStep(dt)   // v2.56 補點後站穩
        fxStep(dt)   // v2.57 新六隻的招牌
        for _ in 0..<n { substep(sdt, L, Lamp, tl) }
        if sillOn && sillG != nil && !props.isEmpty { decoBody(sdt * Double(n)) } else { dbOK = false }   // v2.64 擺飾變真 v2.45: once a frame (a walk's shift is added once a frame)
        drStep(sdt * Double(n))   // v2.64 擺飾變真 v2.46: 推東西
        if mat.sndWall >= 0.5 { wallStep(dt) }   // v2.64 B9 撞側牆出聲（網頁同一個位置；sndWall 0 不呼叫）
        rateStep(dt)   // v2.54 快扯變硬
        capGrowStep(dt)   // v2.54 無限拉
        remeshCheck(dt)   // v2.54 補點
        if sillOn { sillStep(dt) }   // v2.28 窗台: landing, the bowl, the hop, home
        shkStep(dt)   // v2.31 搖晃沉澱
        tentBump()
        if clingOn { for i in 0..<N { clingPin(i) } }   // v2.36: again after the tentacle bumps (else they push it ~2.6 pt off the wall)
        pullStillStep(dt)   // v2.61
        plasticity(dt)
        twitch(L)
        eyeStep(dt)   // v2.23
    }

    /// `L` gates rate-like idle motion (sway, twitch gating); `Lamp` and `tl` are the amplitude and clock
    /// of the phase-based idle motion (breathing, wriggle, drift, float), frozen while touched with idleFreeze.
    private func substep(_ dt: Double, _ L: Double, _ Lamp: Double, _ tl: Double) {
        let mat = effParams
        // 偶發特別回彈: for 0.35 s after a special release the body is stiffer and less damped, so it wobbles once more
        let special = t < specialUntil
        var damp = mat.damp + (special ? 0.03 : 0)
        // 候選 22 放手餘韻: for `afterglow` seconds after a release the damping eases from 0.975 back to the setting
        if mat.afterglow > 0 && fingers.isEmpty {
            let since = t - lastTouch
            if since < mat.afterglow { damp = max(damp, 0.975 - (0.975 - mat.damp) * since / mat.afterglow) }
        }
        damp = min(0.995, damp)
        if introOn && introPh == .air { damp = 1 }   // v2.17 intro: no damping in the air (clay's 0.94 takes 6% a substep, it would not lift off)
        if sillOn && sillAir { damp = 1 }   // v2.28 窗台: none in the air either, or it would not fall
        let alpha = min(1, mat.alpha * (special ? 1.25 : 1) * rateKA)   // v2.54 快扯變硬、慢拉變軟
        let G: Double = sillOn ? (introOn ? R * introG : R * sillGrav * sillGVY) * dt * dt : (introOn ? R * introG * dt * dt : 0)   // v2.17 intro: gravity only while hopping in; v2.28 窗台: always; v2.30 it can turn (0 while it lifts itself)
        let Gh: Double = sillOn && !introOn ? R * sillGrav * sillGVX * dt * dt : 0
        // 1 Verlet
        let relCap: Bool = mat.pullSoft >= 0.5 && fingers.isEmpty && t - lastTouch < PullSet.relT && !introOn && sillHop == nil
        if relCap {   // v2.61 A5 (vc): just let go, no particle faster than 6R a second (before gravity is added)
            let lim: Double = PullSet.relV * R * dt
            for i in 0..<N {
                var vx: Double = (X[i] - PX[i]) * damp, vy: Double = (Y[i] - PY[i]) * damp
                let sp: Double = hypot(vx, vy)
                if sp > lim { vx *= lim / sp; vy *= lim / sp }
                PX[i] = X[i]; PY[i] = Y[i]
                X[i] += vx + Gh; Y[i] += vy + G
            }
        } else {
            for i in 0..<N {
                let vx = (X[i] - PX[i]) * damp, vy = (Y[i] - PY[i]) * damp
                PX[i] = X[i]; PY[i] = Y[i]
                X[i] += vx + Gh; Y[i] += vy + G
            }
        }
        // 2 fingers (GWT: how much each particle is held this substep, for grabHold in shape matching)
        for i in 0..<N { GWT[i] = 0 }
        if SLX.count == N { for i in 0..<N { SLX[i] = 0; SLY[i] = 0 } }
        for f in fingers.values {
            if f.mode == .grab {
                // the patch follows the finger and, while pressed, spreads away from it (squashes flat)
                for m in f.mem {
                    let k = min(0.95, mat.grabK * m.w)   // grabK: clay 1.2, the whole patch follows (多米: could not pick up the middle)
                    X[m.i] += (f.fx + m.ox + m.dx * f.press - X[m.i]) * k
                    Y[m.i] += (f.fy + m.oy + m.dy * f.press - Y[m.i]) * k
                    if m.w > GWT[m.i] { GWT[m.i] = m.w }
                }
                if mat.fingerSolid > 0 {   // v2.29: dragged across the body, the finger pushes the flesh it did not grab aside instead of passing through
                    let rf = R * mat.fingerSolid, r2 = rf * rf
                    for i in 0..<N where !GRAB[i] {
                        let ax = X[i] - f.fx, ay = Y[i] - f.fy, d2 = ax * ax + ay * ay
                        if d2 < r2 && d2 > 1e-6 { let d = sqrt(d2), sc = (rf - d) / d * 0.5; X[i] += ax * sc; Y[i] += ay * sc }
                    }
                }
            } else if f.mode == .push {
                let rf = R * 0.22
                var hit = false
                for i in 0..<N {
                    let dx = X[i] - f.fx, dy = Y[i] - f.fy, d = hypot(dx, dy)
                    if d < rf && d > 1e-6 {
                        let s = (rf - d) / d
                        X[i] += dx * s; Y[i] += dy * s
                        hit = true
                    }
                }
                // a finger pushing in from outside gets its sound and tap the first time it displaces anything
                if hit { f.hitT = t }   // v2.19 A4: tells a finger really on the body from one on empty space
                if hit && !f.pushed { f.pushed = true; onEvent?(f.lure ? .nudge : .press(gain: 0.5)) }   // v2.20 C1: it came to you: a soft tap
            }
        }
        // idle life on the reference shape: breathing, travelling-wave wriggle, tentacle drift
        // sp: v2.16 P1, pressed the whole body grows (the target area grows with it, so the area pressure does not push back)
        // v2.18 posture: comfortable it spreads (wider, lower), happy it stands tall (2 s), curled up a size smaller; trembling: a fast
        // small shake on the rest shape (pulled hard, poked)
        var posX = 1.0, posY = 1.0, trm = 0.0
        if mat.emo >= 0.5 {
            let cp = max(0, moodC), hp = t >= happyT ? max(0, 1 - (t - happyT) / 2) : 0, cw = t < cowerUntil ? 1 : max(0, 1 - (t - cowerUntil) / 0.6)
            posX = (1 + 0.05 * cp) * (1 - 0.04 * hp) * (1 - 0.06 * cw); posY = (1 - 0.06 * cp) * (1 + 0.07 * hp) * (1 - 0.06 * cw)
            trm = R * 0.016 * min(1, moodStrain + moodScare) * (reduceMotion ? 0.5 : 1) * mat.tremble   // v2.48 tremble 0: no shiver when pulled or poked (it read as broken)
            do { let ms = brainMS, mg = max(0, ms), mb = max(0, -ms); posX *= (1 - 0.02 * mg) * (1 + 0.04 * mb); posY *= (1 + 0.04 * mg) * (1 - 0.05 * mb) }   // v2.63 心情 (web v2.42 BRMS): in a good mood a little taller, in a bad one flatter
        }
        if rubvSpT > -9 {   // v2.63 C6 rubVary: melting 2 s more (only rubVary 1 sets rubvSpT)
            let u = t - rubvSpT
            let e: Double = u < 0 ? 0 : (u < 0.3 ? u / 0.3 : (u < Self.rubvSpread ? 1 : max(0, 1 - (u - Self.rubvSpread) / 0.5)))
            posX *= 1 + 0.05 * e; posY *= 1 - 0.06 * e
        }
        if shkT0 > 0 && t >= shkT0 && t < shkT0 + 0.6 { trm += R * 0.025 * shkAmp * exp(-(t - shkT0) / 0.2) * (reduceMotion ? 0.5 : 1) }   // v2.19 shaking off: the outline trembles too
        if iv3(mat.e3) { posX *= 1 - 0.02 * impShownTrust + 0.04 * impShownWary; posY *= 1 + 0.05 * impShownTrust - 0.06 * impShownWary }   // v2.22 E3: trusting rounder, taller; wary flatter
        if slpK > 0 { posX *= 1 + 0.05 * slpK; posY *= 1 - 0.07 * slpK }   // v2.23 B2: asleep, a little melted
        let sp = mat.press2 >= 0.5 ? sqrt(max(0.5, 1 + mat.pressArea * pressSum)) : 1
        let bs = lifeLB * mat.life * 0.045 * brAmp * brWave * (1 - goFade), bsx = (1 + bs) * sp * (1 + introSq) * posX, bsy = (1 - bs * 0.85) * sp * (1 - introSq) * posY   // 提案第 23 條: waveform from update()
        let wr = Lamp * mat.life * mat.wriggle * R * (1 - 0.5 * max(0, moodC)) * lifeWrg, swA = Lamp * mat.life * mat.drift * R, iR = 1 / R
        // 提案第 20 條 tentacle tail: while wandering, the tentacles' reference positions trail the motion (tips most, u²),
        // scaled by the current speed so the smoothstep profile fades it in and out. Written on the reference shape like the
        // drift; weakening the home pull on the tips instead (the proposal's variant b) was measured to bend the rest pose
        // for good (10 pt a second after stopping), this version settles within 3 s
        var tvx = 0.0, tvy = 0.0
        let wv = hypot(wanderVX, wanderVY)
        if mat.tail > 0 && wv > 1e-6 && mat.wander > 0 {
            let ga = atan2(clusters[gi].sn, clusters[gi].cs), ca = cos(ga), sa = sin(ga)
            let s = mat.tail * R * min(1.5, wv / (mat.wander * R)) / wv
            tvx = (ca * wanderVX + sa * wanderVY) * s
            tvy = (-sa * wanderVX + ca * wanderVY) * s
        }
        let Rb = R * 0.98
        // v2.25 F4: the body chases QD, QD chases Q on a spring (semi-implicit Euler); alpha stays, how fast the whole body swings is this spring alone. A drag's acceleration pushes QD the other way, more the farther from the finger
        let inertiaOn: Bool = mat.inertiaHz > 0 && QDX.count == N && !clusters.isEmpty
        if inertiaOn {
            let w: Double = 2 * Double.pi * mat.inertiaHz, w2: Double = w * w, zz: Double = 2 * (reduceMotion ? max(mat.inertiaZ, 0.7) : mat.inertiaZ) * w
            let g = clusters[gi], kd: Double = mat.inertiaDrag * (reduceMotion ? 0.5 : 1)
            let fx: Double = -(g.cs * caX + g.sn * caY) * kd, fy: Double = -(-g.sn * caX + g.cs * caY) * kd
            // v2.26 F6 a stroke pins nothing: the finger is a round head sliding over it and pushes the reference shape: the skin beside it is pushed aside and carried along, and swings back once the finger has gone; clay does not remember it
            if mat.strokeV > 0 {
                for f in fingers.values where f.mode == .stroke && f.on {
                    let px: Double = f.x - g.xc, py: Double = f.y - g.yc
                    let lx: Double = g.qcx + g.cs * px + g.sn * py, ly: Double = g.qcy - g.sn * px + g.cs * py
                    let vl: Double = hypot(f.vxS, f.vyS), vs: Double = vl > R * 6 ? R * 6 / vl : 1
                    let vx: Double = (g.cs * f.vxS + g.sn * f.vyS) * vs, vy: Double = (-g.sn * f.vxS + g.cs * f.vyS) * vs
                    let rk: Double = R * 0.5, rm: Double = reduceMotion ? 0.5 : 1
                    let pu: Double = mat.strokePush * R * rm * dt, fr: Double = mat.strokeFric * rm * dt
                    for i in 0..<N {
                        let dx: Double = QDX[i] - lx, dy: Double = QDY[i] - ly, d2: Double = dx * dx + dy * dy
                        if d2 >= rk * rk || d2 < 1e-6 { continue }
                        let d: Double = d2.squareRoot(), u: Double = 1 - d / rk, wk: Double = u * u
                        QVX[i] += dx / d * wk * pu + (vx - QVX[i]) * wk * fr
                        QVY[i] += dy / d * wk * pu + (vy - QVY[i]) * wk * fr
                    }
                }
            }
            for i in 0..<N {
                QVX[i] += (w2 * (QX[i] - QDX[i]) - zz * QVX[i] + fx * QW[i]) * dt
                QVY[i] += (w2 * (QY[i] - QDY[i]) - zz * QVY[i] + fy * QW[i]) * dt
                QDX[i] += QVX[i] * dt; QDY[i] += QVY[i] * dt
            }
        }
        // v2.48: the pseudopods fade as the remembered shape is stretched (longest edge 1.25 to 1.85 times rest). They are worked out for a round blob; on top of a
        // stretched shape that part was stretched 2.5 times again (measured: memory 2.4 times, the reference shape 5.5, a spike toward where the finger left)
        let podU: Double = max(0, min(1, (QSTR - 1.25) / 0.6))
        let podK: Double = mat.stretchCap > 0 ? 1 - podU * podU * (3 - 2 * podU) : 1
        for i in 0..<N {
            var ex: Double = inertiaOn ? QDX[i] : QX[i], ey: Double = inertiaOn ? QDY[i] : QY[i]
            // pseudopods: a Gaussian along direction a pushes the outer ring out (the inside less, by (r/Rb)², so the whole
            // field is a smooth map), minus podShift all round so the area stays; bend swings the outer part sideways
            if !podE.isEmpty && podK > 0 {
                let r = hypot(ex, ey)
                if r > 1e-6 {
                    let c1 = ex / r, s1 = ey / r, rn = min(1.6, (r / Rb) * (r / Rb))
                    var dr = 0.0, dtn = 0.0
                    for q in podE {
                        let da = atan2(s1 * q.ca - c1 * q.sa, c1 * q.ca + s1 * q.sa), g = exp(-da * da / (2 * q.sig * q.sig))
                        dr += q.amp * g * rn; dtn += q.bend * q.amp * g * rn * rn
                    }
                    dr -= podShift * rn
                    dr *= podK; dtn *= podK
                    ex += c1 * dr - s1 * dtn; ey += s1 * dr + c1 * dtn
                }
            }
            if wr != 0 {
                let qx = ex * iR, qy = ey * iR
                if mat.morph >= 0.5 {
                    // outline modes 2...5 (coefficients from morphCoef) plus the roaming bumps: radial d, tangential g;
                    // scaled down towards the centre so the whole field is a smooth map
                    let r = hypot(qx, qy)
                    if r > 1e-6 {
                        let c1 = qx / r, s1 = qy / r, kw = wr * min(1, r)
                        var cm = c1, sm = s1, d = 0.0, g = 0.0
                        for m in 2...5 {
                            let c = cm * c1 - sm * s1; sm = sm * c1 + cm * s1; cm = c
                            d += morphA[m] * cm + morphB[m] * sm; g += morphB[m] * cm - morphA[m] * sm
                        }
                        d += bumpAt(c1, s1)
                        ex += kw * (d * c1 - 0.3 * g * s1); ey += kw * (d * s1 + 0.3 * g * c1)
                    }
                } else {
                    ex += wr * (0.6 * sin(1.7 * qy + tl * 1.3 + 0.3) + 0.4 * sin(2.3 * qx - tl * 1.0 + 1.7))
                    ey += wr * (0.6 * sin(1.9 * qx - tl * 1.1 + 2.1) + 0.4 * sin(2.1 * qy + tl * 1.6 + 0.6))
                }
            }
            let k = TID[i]
            if k >= 0 {
                let tt = tent[k], u = TUB[i], u2 = u * u
                if swA != 0 {
                    let kd = Double(k)
                    // morph: two smooth noises per tentacle, one swings the whole tentacle (u²), one bends its middle (sin πu · u)
                    let phv = (mat.morph >= 0.5
                        ? 1.1 * Self.vnoise(40 + 2 * k, tl / 2.4 + kd * 0.3) * u2 + 0.6 * Self.vnoise(41 + 2 * k, tl / 1.3 + kd * 0.7) * sin(.pi * u) * u
                        : (sin(tl * 2 * .pi / (4.2 + kd * 0.9) + kd * 2.1) + 0.35 * sin(tl * 2 * .pi / (1.9 + kd * 0.4) + kd)) * u2) * swA
                    ex += -tt.uy * phv; ey += tt.ux * phv
                }
                if tvx != 0 || tvy != 0 { ex -= tvx * u2; ey -= tvy * u2 }
            }
            if trm > 0 {   // v2.18 trembling (on the rest shape, so it is never remembered)
                let r = hypot(ex, ey)
                if r > 1e-6 { let a = trm * sin(t * 41 + Double(i) * 1.7); ex += ex / r * a; ey += ey / r * a }
            }
            EX[i] = ex; EY[i] = ey
        }
        // v2.19 performed scaling of the rest shape: breathing and mood (bsx, bsy) × the flinch (flS) × stretched along the heading while
        // walking or fleeing (strK, area kept). Memory takes it off (psm)
        var m00 = bsx * flS, m01 = 0.0, m10 = 0.0, m11 = bsy * flS
        if strK != 1 {
            let u = strH - atan2(clusters[gi].sn, clusters[gi].cs), cu = cos(u), su = sin(u), ka = strK - 1, kb = 1 / strK - 1
            let d00 = 1 + ka * cu * cu + kb * su * su, d01 = (ka - kb) * cu * su, d11 = 1 + ka * su * su + kb * cu * cu
            m00 = bsx * flS * d00; m01 = bsx * flS * d01; m10 = bsy * flS * d01; m11 = bsy * flS * d11
        }
        if splitMx.m00 != 1 || splitMx.m01 != 0 || splitMx.m10 != 0 || splitMx.m11 != 1 {   // v2.62 torn, A smaller; merging, squashed and springing up (already in the reference shape's frame)
            let q = splitMx
            let a: Double = q.m00 * m00 + q.m01 * m10, b: Double = q.m00 * m01 + q.m01 * m11, c: Double = q.m10 * m00 + q.m11 * m10, d: Double = q.m10 * m01 + q.m11 * m11
            m00 = a; m01 = b; m10 = c; m11 = d
        }
        psm = (m00, m01, m10, m11)
        // 3 shape matching: each cluster's best rigid fit pulls its particles
        for i in 0..<N { GX[i] = 0; GY[i] = 0; GW[i] = 0 }
        clusters[gi].w = mat.wGlobal
        for c in 0..<clusters.count {
            let idx = clusters[c].idx, n = Double(idx.count)
            var xc = 0.0, yc = 0.0, qcx = 0.0, qcy = 0.0
            for i in idx { xc += X[i]; yc += Y[i]; qcx += EX[i]; qcy += EY[i] }
            xc /= n; yc /= n; qcx /= n; qcy /= n
            var a = 0.0, b = 0.0, cc = 0.0, d = 0.0
            for i in idx {
                let px = X[i] - xc, py = Y[i] - yc, ex0 = EX[i] - qcx, ey0 = EY[i] - qcy, qx = m00 * ex0 + m01 * ey0, qy = m10 * ex0 + m11 * ey0
                a += px * qx; b += px * qy; cc += py * qx; d += py * qy
            }
            let ang = atan2(cc - b, a + d), cs = cos(ang), sn = sin(ang)
            clusters[c].cs = cs; clusters[c].sn = sn; clusters[c].xc = xc; clusters[c].yc = yc
            clusters[c].qcx = qcx; clusters[c].qcy = qcy
            let w = clusters[c].w
            for i in idx {
                let ex0 = EX[i] - qcx, ey0 = EY[i] - qcy, qx = m00 * ex0 + m01 * ey0, qy = m10 * ex0 + m11 * ey0
                GX[i] += (xc + cs * qx - sn * qy) * w
                GY[i] += (yc + sn * qx + cs * qy) * w
                GW[i] += w
            }
        }
        // area pressure: when squashed or stretched the area drops, push goals outward so sides bulge
        let A = polygonArea()
        let A0p = (mat.press2 >= 0.5 ? A0 * (1 + mat.pressArea * pressSum) : A0) * flS * flS * splitDet   // v2.62 splitDet: torn, the target area shrinks with it. v2.16 P1: pressed from the front it thins, so it looks bigger; v2.19 the flinch really shrinks it (else the area pressure pushes it back)
        let ap = max(-0.12, min(0.12, (sqrt(A0p / A) - 1) * mat.areaGain))
        let gcx = clusters[gi].xc, gcy = clusters[gi].yc
        let pf = pressField()
        // 候選 27 局部面積壓力: weight the area pressure towards the fingers (exp(−(d/1.2R)²), mean kept at 1 so the
        // total area correction is unchanged)
        var local = false
        if mat.localArea > 0 && ap != 0 && !fingers.isEmpty {
            let gs = fingers.values.filter { $0.mode == .grab }
            if !gs.isEmpty {
                local = true
                if AW.count != N { AW = Array(repeating: 0, count: N) }
                var sum = 0.0
                let r2 = 1 / (1.44 * R * R)
                for i in 0..<N {
                    var g = 0.0
                    for f in gs {
                        let dx = X[i] - f.fx, dy = Y[i] - f.fy
                        g = max(g, exp(-(dx * dx + dy * dy) * r2))
                    }
                    AW[i] = g; sum += g
                }
                let mean = sum / Double(N)
                for i in 0..<N { AW[i] = max(0, 1 + mat.localArea * (AW[i] - mean)) }
            }
        }
        for i in 0..<N {
            var gx = GX[i] / GW[i], gy = GY[i] / GW[i]
            let api = local ? ap * AW[i] : ap
            gx = gcx + (gx - gcx) * (1 + api); gy = gcy + (gy - gcy) * (1 + api)
            if !pf.isEmpty { let q = pressPush(pf, gx, gy); gx += q.0; gy += q.1 }
            let ka = alpha * KF[i] * (1 - mat.grabHold * GWT[i])   // grabHold: the held patch listens to the finger more than to the shape
            X[i] += (gx - X[i]) * ka; Y[i] += (gy - Y[i]) * ka
        }
        // upright: turn back head-up. Kinematic (position and previous position together), so no overshoot.
        let gAng = atan2(clusters[gi].sn, clusters[gi].cs)
        let grabbing = !fingers.isEmpty
        var rotK: Double = -gAng * min(0.2, grabbing ? min(mat.upright * mat.anchor * mat.gripRot, mat.gripUp >= 0 ? mat.gripUp : 1) : mat.upright)   // v2.29 gripUp: grabbed, the body has to be able to turn, else a pulled strand can only wrap around it
        if mat.pullSoft >= 0.5 && !grabbing {   // v2.61 A5 (up): long, it turns back without flinging its tip
            var rm = 0.0
            for i in bnd {
                let ux: Double = X[i] - gcx, uy: Double = Y[i] - gcy, q: Double = ux * ux + uy * uy
                if q > rm { rm = q }
            }
            let lim: Double = PullSet.upright * R * dt / max(R * 0.5, sqrt(rm))
            rotK = max(-lim, min(lim, rotK))
        }
        if rotK != 0 { rotateFree(by: rotK, around: gcx, gcy) }
        // idle sway: pure performance displacement, no velocity left behind
        let sway = L * mat.life * 0.0009 * sin(t * 2 * .pi / 5.3)
        if sway != 0 { rotateFree(by: sway, around: gcx, gcy) }
        // 3b boundary ring: neighbours keep their distance within [0.6, 2.4] (tentacles 1.7) of rest
        let nb = bnd.count
        for _ in 0..<2 {
            for k in 0..<nb {
                let i = bnd[k], j = bnd[(k + 1) % nb]
                let tentacle = TID[i] >= 0 || TID[j] >= 0
                let dx = X[j] - X[i], dy = Y[j] - Y[i]
                // the upper bound follows the remembered shape: once a long pull is remembered the ring may stretch again,
                // otherwise it stays capped by the original perimeter
                let d = max(1e-6, hypot(dx, dy)), l0 = bndL[k], lo = l0 * 0.6
                let hi = tentacle ? l0 * 1.7 : max(l0, hypot(QX[j] - QX[i], QY[j] - QY[i])) * 2.4
                var c = 0.0
                if d > hi { c = (d - hi) / d } else if d < lo { c = (d - lo) / d }
                if c == 0 { continue }
                let wi = GRAB[i] ? 0.15 : 0.5, wj = GRAB[j] ? 0.15 : 0.5, sw = wi + wj
                X[i] += dx * c * wi / sw; Y[i] += dy * c * wi / sw
                X[j] -= dx * c * wj / sw; Y[j] -= dy * c * wj / sw
            }
        }
        // no folding back (2026-11-01: next to the held point the ring folded into a little Z, like a flap turned up): two ring
        // particles one apart stay at least 0.6 of their rest distance apart, so a sharp fold-back cannot form
        if mat.ringGuard > 0 {
            for k in 0..<nb {
                let i = bnd[k], j = bnd[(k + 2) % nb]
                let dx = X[j] - X[i], dy = Y[j] - Y[i], d = max(1e-6, hypot(dx, dy)), lo = bndL2[k] * 0.6
                if d >= lo { continue }
                let c = (d - lo) / d, wi = GRAB[i] ? 0.15 : 0.5, wj = GRAB[j] ? 0.15 : 0.5, sw = wi + wj
                X[i] += dx * c * wi / sw; Y[i] += dy * c * wi / sw
                X[j] -= dx * c * wj / sw; Y[j] -= dy * c * wj / sw
            }
        }
        // 3c non-penetration inside a group (same tentacle / body): keeps tentacles from thinning or folding.
        //    Different groups may overlap (one in front of the other), otherwise a pulled-across tentacle gets stuck.
        collide()
        // 3d tentacle rungs + medial axis (提案第 41 條): particle non-penetration only knows distances, not sides,
        //    so a tentacle pushed root-to-tip could fold over itself; the rungs keep each edge on its own side and the
        //    axis links keep advancing (the fold was the axis turning 180° within one link)
        if mat.tentRung > 0 { tentacleRungs(mat) }
        if mat.stretchCap > 0 && !EDG.isEmpty {   // v2.48: the hard limits, a few rounds together with the no-flip guard
            let rounds = max(1, Int(mat.capIter))
            for _ in 0..<rounds {
                let a: Bool = strainStep(&X, &Y, mat.capLo, mat.stretchCap * capG(mat), true, mat)
                let b: Bool = mat.noFlip > 0 ? meshGuard(&X, &Y, mat.noFlip, GRAB, mat) : false
                if b { grdFlip = true }   // v2.52 A5
                if !a && !b { break }
            }
        } else if mat.noFlip > 0 { if meshGuard(&X, &Y, mat.noFlip, GRAB) { grdFlip = true } }   // v2.29 防打結: before the walls, so the collisions have the last word and it does not sink into the floor
        // 4 home (float), bounds
        let hx = homeX + tugX + dragOX + Lamp * mat.life * R * 0.035 * sin(tl * 2 * .pi / 7.3)
        let hy = homeY + tugY + dragOY - brLift + (mat.jelly >= 0.5 ? 0 : Lamp * mat.life * R * 0.05 * sin(tl * 2 * .pi / 4.7))   // jellyfish: up and down only with the pulse
        // 候選 21: idle home spring homeK (0.003 drifts back in about half a second with no overshoot); grabbed stays 0.02 × anchor
        var hyF = flatOn ? flatFloor - flatQB : hy   // pressing flat: home is where the bottom sits on the table
        // v2.55 homeFloor: held on the sill, the home spring may not pull the body into the surface (home lowest where the bottom just touches it). Same as the web's.
        if mat.homeFloor > 0 && sillOn && sillGrab && !clingOn && !sillTanV && !flatOn, let g = sillG,
           fingers.values.allSatisfy({ $0.mode != .grab || $0.fy < gcy }) {   // only while every holding finger is above the centre (pulling up): one pulling down would have the spring yank the body up
            let fy: Double = sillPlane == .frame ? g.bt : sillPlane == .out ? g.oy : sillInBowl ? g.bf : g.fl
            var yb = -Double.infinity
            for i in bnd where Y[i] > yb { yb = Y[i] }
            let lo = gcy + (fy - yb)
            if hyF > lo { hyF += (lo - hyF) * min(1, mat.homeFloor) }
        }
        let kh: Double = sillOn ? 0.006 * (grabbing ? mat.anchor : 1) : (grabbing ? 0.02 * mat.anchor : mat.homeK), dx0 = hx - gcx, dy0 = hyF - gcy   // v2.28 窗台: a weak home only
        let hxOn = !(sillOn && (sillAir || (sillTanV && !sillLift && !sillGrab))), hyOn = !introOn && !(sillOn && !sillGrab && !sillTanV)   // v2.28 窗台: in the air nothing pulls it home; on the sill up and down is gravity's unless grabbed; v2.30 walking vertically the other way round
        let soft = sillOn && mat.softWall >= 0.5
        sillC = 0; sillCB = 0
        let hcp: Double = mat.homeCap > 0 ? mat.homeCap * h / max(mat.homeCap * h, hypot(dx0, dy0) * kh) : 1   // v2.29 homeCap: dragged along, the whole body moves at most half a spacing a substep, so the ring beside the finger is not sheared open
        let dx = dx0 * hcp, dy = dy0 * hcp
        let wl = worldWalls, padT = wl.t, padB = wl.b, padL = wl.l, padR = wl.r   // walls: the edge of the farthest view (world)
        let slipOn: Bool = mat.stretchCap > 0 && mat.capSlip > 0 && SLX.count == N && HIT.count == N
        for i in 0..<N {
            if !GRAB[i] { if hxOn { X[i] += dx * kh }; if hyOn { Y[i] += dy * kh } }   // hopping in, up and down is gravity and the floor's
            let bx0: Double = X[i], by0: Double = Y[i]
            if sillOn, let g = sillG { sillHit(i, g) }   // v2.28 窗台: the bowl and the sill
            if introOn && Y[i] > introFloor { Y[i] = introFloor; PX[i] += (X[i] - PX[i]) * 0.45 }   // intro floor: it really lands, squashes, wobbles
            if flatOn && Y[i] > flatFloor { Y[i] = flatFloor; PY[i] = Y[i] }   // the invisible table: no sinking, no bounce, free to slide
            if clingOn { clingPin(i) }   // v2.36 黏牆: the suckers are last, no collision pushes them off
            if soft {   // v2.29: left, right and top are soft, only the floor is hard; softer while a finger holds it, pushed back quickly once let go
                let wk = grabbing ? 0.04 : 0.25
                if Y[i] < padT { Y[i] += (padT - Y[i]) * wk }
                if X[i] < padL { X[i] += (padL - X[i]) * wk }
                if X[i] > padR { X[i] += (padR - X[i]) * wk }
                if Y[i] > padB { Y[i] = padB }
            } else {
                if Y[i] < padT { Y[i] = padT }
                if Y[i] > padB { Y[i] = padB }
                if X[i] < padL { X[i] = padL }
                if X[i] > padR { X[i] = padR }
            }
            if HIT.count == N {   // v2.48: what the sill, the floor and the walls pushed a held particle back by counts too; who they stopped is not pushed into them next substep
                let mx: Double = X[i] - bx0, my: Double = Y[i] - by0
                if slipOn && GRAB[i] { SLX[i] += mx; SLY[i] += my }
                HIT[i] = abs(mx) + abs(my) > 1e-4
            }
        }
        if sillOn && sillG != nil {   // v2.64 擺飾變真 (web: after the walls, before ringGuard): the things, the panel changed deco / decoReal, the pendulums
            if !props.isEmpty { propsStep(dt) }
            if decoKey() != decoKeyNow { propsInit() }
            if dreal { hangStep(dt) }
        }
        if mat.ringGuard > 0 { ringGuard(mat.stretchCap > 0 ? 1 - mat.capVel : 0); ringUnkink() }   // no boundary through boundary, little knots straightened; after the walls
        // v2.48 手指讓: however far the limits (cannot squeeze further, cannot flip, the sill, the walls) pushed the held patch back, the finger's effective
        // position gives way by capSlip times that. The patch used to follow the finger at 95%: dragged into the body or onto the sill, the limits pushed it
        // back every substep and the finger pulled it in again (measured: the top pulled down 2R, 18 points of jump a frame and 59 triangles flipped; 0.9 and 1 with this)
        if slipOn {
            for f in fingers.values where f.mode == .grab && !f.mem.isEmpty {
                var sx = 0.0, sy = 0.0, sw = 0.0
                for m in f.mem { sx += SLX[m.i] * m.w; sy += SLY[m.i] * m.w; sw += m.w }
                var heldBack = false   // v2.61 A2 (gv): stopped, a finger that has already given way 0.3R gives no further the same way
                if mat.pullSoft >= 0.5 && pullStillT > PullSet.wait {
                    let along: Double = f.slx * sx + f.sly * sy
                    heldBack = hypot(sx, sy) > 0 && along > 0 && hypot(f.slx, f.sly) > R * PullSet.drift
                }
                if sw > 0 && !heldBack {
                    if mat.endless >= 0.5, !clusters.isEmpty {   // v2.54 無限拉: the finger gives way outward and sideways, never back toward the body's centre (that was the pull that would not stretch)
                        let rx: Double = f.fx - clusters[gi].xc, ry: Double = f.fy - clusters[gi].yc, rl: Double = hypot(rx, ry)
                        if rl > 1e-6 { let d: Double = (sx * rx + sy * ry) / rl; if d < 0 { sx -= d * rx / rl; sy -= d * ry / rl } }
                    }
                    let gx: Double = sx / sw * mat.capSlip, gy: Double = sy / sw * mat.capSlip
                    if abs(sx) + abs(sy) > sw * 0.02 { grdGive = true }   // v2.52 A5
                    // v2.58 (11-24) pullGive: pulled outward, the give may not pile up to 2R (the held patch trailed a slanted 5.5R pull by 1.6R); it
                    // shrinks to pullGive × R, never below what it already was at once, and the effective position moves only by what is left after the limit
                    let s0x: Double = f.slx, s0y: Double = f.sly, gk: Double = giveK(f, mat)
                    var top: Double = R * 2
                    if gk > 0 {
                        let kept: Double = min(R * 2, hypot(s0x, s0y))
                        let lim: Double = R * (2 + (mat.pullGive - 2) * gk)
                        top = max(lim, kept)
                    }
                    f.slx = s0x + gx; f.sly = s0y + gy
                    let l: Double = hypot(f.slx, f.sly)
                    if l > top { f.slx *= top / l; f.sly *= top / l }
                    if gk > 0 { f.fx += f.slx - s0x; f.fy += f.sly - s0y }
                    else { f.fx += gx; f.fy += gy }
                }
            }
        }
    }

    private func rotateFree(by ang: Double, around cx: Double, _ cy: Double) {
        let c = cos(ang), s = sin(ang)
        for i in 0..<N where !GRAB[i] {
            var dx = X[i] - cx, dy = Y[i] - cy
            X[i] = cx + dx * c - dy * s; Y[i] = cy + dx * s + dy * c
            dx = PX[i] - cx; dy = PY[i] - cy
            PX[i] = cx + dx * c - dy * s; PY[i] = cy + dx * s + dy * c
        }
    }

    private func collide() {
        // 0.6h is below every rest spacing, so it never fights shape matching.
        // Known limit (2026-11-01): particle non-penetration cannot stop a *segment* crossing. Pushing a tentacle's
        // root towards its tip (compressing it) occasionally folds it for a few frames; widening the boundary-to-boundary
        // distance to 1.2h was tried and did not help. Candidate fixes: 手感精修提案 第 41 條.
        let dmin = h * 0.6 * splitDmin, dmin2 = dmin * dmin, inv = 1 / dmin   // v2.62 splitDmin: shrunk or squashed, the spacing shrinks too
        // 第 36 條: fixed-size hashed cell lists instead of a Dictionary built 240 times a second (no allocation per
        // substep; a bucket collision only costs an extra distance check)
        let buckets = 1024
        if cellNext.count != N { cellNext = Array(repeating: -1, count: N); cellHead = Array(repeating: -1, count: buckets) }
        for b in 0..<buckets { cellHead[b] = -1 }
        func key(_ gx: Int, _ gy: Int) -> Int { ((gx &* 73856093) ^ (gy &* 19349663)) & (buckets - 1) }
        for i in 0..<N {
            let b = key(Int(floor(X[i] * inv)), Int(floor(Y[i] * inv)))
            cellNext[i] = cellHead[b]; cellHead[b] = Int32(i)
        }
        let nb = bnd.count
        for i in 0..<N {
            let gx = Int(floor(X[i] * inv)), gy = Int(floor(Y[i] * inv))
            for ox in -1...1 {
                for oy in -1...1 {
                    var j = Int(cellHead[key(gx + ox, gy + oy)])
                    while j >= 0 {
                        defer { j = Int(cellNext[j]) }
                        if j <= i || TID[j] != TID[i] { continue }
                        if BIDX[i] >= 0 && BIDX[j] >= 0 {
                            let di = abs(BIDX[i] - BIDX[j])
                            if min(di, nb - di) <= 8 { continue }
                        }
                        let dx = X[j] - X[i], dy = Y[j] - Y[i], d2 = dx * dx + dy * dy
                        if d2 >= dmin2 || d2 < 1e-9 { continue }
                        let d = sqrt(d2), c = (dmin - d) / d
                        let wi = GRAB[i] ? 0.3 : 1.0, wj = GRAB[j] ? 0.3 : 1.0, sw = wi + wj
                        X[i] -= dx * c * wi / sw; Y[i] -= dy * c * wi / sw
                        X[j] += dx * c * wj / sw; Y[j] += dy * c * wj / sw
                    }
                }
            }
        }
    }

    private func tentacleRungs(_ mat: FeelParams) {
        for k in rungs.indices {
            let list = rungs[k], s0 = rungSign[k], nr = list.count
            if nr < 2 { continue }
            // width and side: b must stay on its own side of the local axis, at least tentRung of the rest width away
            for r in 0..<nr {
                let p = list[max(0, r - 1)], q = list[min(nr - 1, r + 1)], g = list[r]
                var tx = X[q.a] + X[q.b] - X[p.a] - X[p.b], ty = Y[q.a] + Y[q.b] - Y[p.a] - Y[p.b]
                let tl = max(1e-6, hypot(tx, ty)); tx /= tl; ty /= tl
                let nx = -ty * s0, ny = tx * s0   // unit normal from a's side to b's side
                let dx = X[g.b] - X[g.a], dy = Y[g.b] - Y[g.a], wmin = g.w0 * mat.tentRung
                let wa = GRAB[g.a] ? 0.3 : 1.0, wb = GRAB[g.b] ? 0.3 : 1.0, sw = wa + wb
                let cn = dx * nx + dy * ny
                if cn < wmin {
                    let delta = (wmin - cn) * 0.6
                    X[g.a] -= nx * delta * wa / sw; Y[g.a] -= ny * delta * wa / sw
                    X[g.b] += nx * delta * wb / sw; Y[g.b] += ny * delta * wb / sw
                }
            }
            // medial axis: each link projects at least tentAxis of its rest length onto the previous link
            // (the root link is measured from the body particles flanking the tentacle)
            if mat.tentAxis > 0 {
                let rp = rungRef[k]
                for r in 0..<(nr - 1) {
                    let g = list[r], q = list[r + 1]
                    var ux: Double, uy: Double
                    if r == 0 {
                        ux = (X[g.a] + X[g.b]) * 0.5 - (X[rp.0] + X[rp.1]) * 0.5
                        uy = (Y[g.a] + Y[g.b]) * 0.5 - (Y[rp.0] + Y[rp.1]) * 0.5
                    } else {
                        let p = list[r - 1]
                        ux = (X[g.a] + X[g.b] - X[p.a] - X[p.b]) * 0.5
                        uy = (Y[g.a] + Y[g.b] - Y[p.a] - Y[p.b]) * 0.5
                    }
                    let ul = max(1e-6, hypot(ux, uy)); ux /= ul; uy /= ul
                    let sx = (X[q.a] + X[q.b] - X[g.a] - X[g.b]) * 0.5, sy = (Y[q.a] + Y[q.b] - Y[g.a] - Y[g.b]) * 0.5
                    let s = sx * ux + sy * uy, hmin = q.hs * mat.tentAxis
                    if s >= hmin { continue }
                    let delta = (hmin - s) * 0.5
                    let wq = (GRAB[q.a] || GRAB[q.b]) ? 0.3 : 1.0, wg = (GRAB[g.a] || GRAB[g.b]) ? 0.3 : 1.0, sw = wq + wg
                    X[q.a] += ux * delta * wq / sw; Y[q.a] += uy * delta * wq / sw
                    X[q.b] += ux * delta * wq / sw; Y[q.b] += uy * delta * wq / sw
                    X[g.a] -= ux * delta * wg / sw; Y[g.a] -= uy * delta * wg / sw
                    X[g.b] -= ux * delta * wg / sw; Y[g.b] -= uy * delta * wg / sw
                }
            }
        }
    }

    // MARK: - v2.52 A4 流 (多米 11-22 決定 5: 放著會慢慢往下塌). Port of the web's flowFree / flowStep.
    // A real slime rolled into a ball and left on the table flows flat by itself (2-5); the model had 留形 and 回原形 but nothing that slumps.
    // With no finger on it and resting on the sill, the remembered shape is pressed down along gravity and spread sideways. `flow` is the share
    // of its height lost a second (0.05 ≈ half in 14 s); recover pulls it back at the same time, the two balance at recover ÷ (recover + flow)
    // of the height. It never slumps below 65% of the original height (that floor is a guard, not material: at 65% it is about 1.5 times as
    // wide, 3.2R, about all a 393 pt screen holds; with the floor at 30% the edge limits pushed the remembered shape askew within 30 s). Done in rest space: the world's
    // "down" (0, 1) is (sn, cs) there. The area is brought back by the end of plasticity, the edge lengths are held by memCap.
    private var flowFree: Bool {
        sillOn && sillPlane == .room && sillC > 0 && !sillGrab && !sillAir && sillHop == nil && sillRoute == nil && sillStickT < 0
            && !escOn && !clingOn && !gaitOn && fingers.isEmpty
    }
    private func flowStep(_ dt: Double, _ flow: Double) {
        guard N > 0, !clusters.isEmpty else { return }
        let g = clusters[gi], dx: Double = g.sn, dy: Double = g.cs
        var a0 = 1e9, a1 = -1e9, b0 = 1e9, b1 = -1e9, q0 = 1e9, q1 = -1e9
        for i in 0..<N {
            let a: Double = QX[i] * dx + QY[i] * dy, b: Double = QX[i] * dy - QY[i] * dx
            if a < a0 { a0 = a }; if a > a1 { a1 = a }; if b < b0 { b0 = b }; if b > b1 { b1 = b }
            if Q0Y[i] < q0 { q0 = Q0Y[i] }; if Q0Y[i] > q1 { q1 = Q0Y[i] }
        }
        guard a1 - a0 > (q1 - q0) * 0.65 else { return }
        let k: Double = min(0.2, flow * dt), bm: Double = (b0 + b1) / 2
        for i in 0..<N {
            let a: Double = QX[i] * dx + QY[i] * dy, b: Double = QX[i] * dy - QY[i] * dx
            let a2: Double = a1 - (a1 - a) * (1 - k), b2: Double = bm + (b - bm) * (1 + k)
            QX[i] = a2 * dx + b2 * dy; QY[i] = a2 * dy - b2 * dx
        }
    }

    private func plasticity(_ dt: Double) {
        let mat = effParams
        // where each particle sits in rest space right now (rotation only, averaged over its clusters)
        for i in 0..<N { RX[i] = 0; RY[i] = 0; GW[i] = 0 }
        // v2.19: with the same weights, where the performed scaling alone would put each particle in rest space (SX2, SY2); memory
        // compares against that, so breathing (it goes on while held), the flinch, the walking stretch and the mood postures are never remembered
        let usePS = mat.life2 >= 0.5
        let (p00, p01, p10, p11) = psm
        if usePS {
            if SX2.count != N { SX2 = Array(repeating: 0, count: N); SY2 = Array(repeating: 0, count: N) }
            for i in 0..<N { SX2[i] = 0; SY2[i] = 0 }
        }
        for c in clusters {
            for i in c.idx {
                let px = X[i] - c.xc, py = Y[i] - c.yc
                RX[i] += (c.qcx + c.cs * px + c.sn * py) * c.w
                RY[i] += (c.qcy - c.sn * px + c.cs * py) * c.w
                GW[i] += c.w
                if usePS {
                    let ex = EX[i] - c.qcx, ey = EY[i] - c.qcy
                    SX2[i] += (c.qcx + p00 * ex + p01 * ey) * c.w; SY2[i] += (c.qcy + p10 * ex + p11 * ey) * c.w
                }
            }
        }
        // tentMem: a grabbed tentacle is measured in the whole-body frame, more so towards the tip (the root stays on the
        // clusters like the body, so the junction does not get two frames). The clusters read a bent tentacle as a rotation
        // and cancel it (measured: a 0.8R pull remembered 2.7 pt). Only the grabbed tentacle: an untouched one swinging
        // would be remembered as bent (measured: holding the body 1.5 s bent the tentacles 52 pt)
        // nearMem: near the fingers (Gaussian, about 1.1R) the body is measured in the whole-body frame too. A pulled-out lump
        // reads as a rotation to the clusters and is cancelled (measured: a 0.9R pull remembered 7 pt)
        if mat.nearMem > 0 {
            let g = clusters[gi], gs = fingers.values.filter { $0.mode == .grab }, nR: Double = mat.nearR + max(0, mat.pullNearR - mat.nearR) * pullK(mat), k2 = 1 / (nR * nR * R * R)   // clay 3 = the whole lump; v2.54 pulled out long, pullNearR
            if !gs.isEmpty {
                for i in 0..<N {
                    var wf = 0.0
                    for f in gs { let dx = X[i] - f.fx, dy = Y[i] - f.fy; wf = max(wf, exp(-(dx * dx + dy * dy) * k2)) }
                    let wi = mat.nearMem * wf
                    if wi < 1e-3 { continue }
                    let px = X[i] - g.xc, py = Y[i] - g.yc, c = GW[i]
                    RX[i] = RX[i] * (1 - wi) + (g.qcx + g.cs * px + g.sn * py) * c * wi
                    RY[i] = RY[i] * (1 - wi) + (g.qcy - g.sn * px + g.cs * py) * c * wi
                    if usePS {
                        let ex = EX[i] - g.qcx, ey = EY[i] - g.qcy
                        SX2[i] = SX2[i] * (1 - wi) + (g.qcx + p00 * ex + p01 * ey) * c * wi; SY2[i] = SY2[i] * (1 - wi) + (g.qcy + p10 * ex + p11 * ey) * c * wi
                    }
                }
            }
        }
        if mat.tentMem > 0 && !tent.isEmpty {
            var tg = [Bool](repeating: false, count: tent.count)
            for i in 0..<N where GRAB[i] && TID[i] >= 0 { tg[TID[i]] = true }
            let g = clusters[gi]
            for i in 0..<N where TID[i] >= 0 && tg[TID[i]] {
                let px = X[i] - g.xc, py = Y[i] - g.yc, c = GW[i], w = mat.tentMem * TUB[i]
                RX[i] = RX[i] * (1 - w) + (g.qcx + g.cs * px + g.sn * py) * c * w
                RY[i] = RY[i] * (1 - w) + (g.qcy - g.sn * px + g.cs * py) * c * w
                if usePS {
                    let ex = EX[i] - g.qcx, ey = EY[i] - g.qcy
                    SX2[i] = SX2[i] * (1 - w) + (g.qcx + p00 * ex + p01 * ey) * c * w; SY2[i] = SY2[i] * (1 - w) + (g.qcy + p10 * ex + p11 * ey) * c * w
                }
            }
        }
        let touched = fingers.values.contains { $0.mode == .grab && !tentGrip($0) }   // v2.27: holding only a tentacle, the body does not remember (tentRest keeps its length); clay's crossings and shaking came from here
        var untie = false   // v2.58 (11-24) memUntie: the remembered shape is being untied this frame
        if touched || t < relaxUntil { remKnotChk = 0.1 }   // the last check is from before the touch: check again as soon as it is let go
        if t < relaxUntil {
            // 揉回原形: the remembered shape eases back to the original over half a second; positions follow
            // through shape matching, so nothing jumps (手感精修提案 第 28 條)
            let kr = min(1, 6 * dt)
            for i in 0..<N { QX[i] += (H0X[i] - QX[i]) * kr; QY[i] += (H0Y[i] - QY[i]) * kr }
        } else if touched && !(mat.ringGuard > 0 && ringCrossed()) {   // no memory on a crossed frame: a crossing must not become the shape
            // only after dwelling: within `dwellLo` a light press or a quick flick springs back,
            // from `dwellHi` on kneading remembers at full speed (輕按回彈，揉捏即留形)
            var g = 0.0
            let lo = mat.dwellLo, hi = max(lo + 0.001, mat.dwellHi)
            for f in fingers.values where f.mode == .grab {
                let x = max(0, min(1, (t - f.tDown - lo) / (hi - lo)))
                g = max(g, x * x * (3 - 2 * x))
            }
            let yl = mat.yield * R, kc0: Double = min(1, (mat.creep + max(0, mat.pullCreep - mat.creep) * pullK(mat)) * rateKC * dt * g) * (mat.rubSpeed > 0 && tickOn ? 0.0 : 1.0)   // v2.24: a tickle is not sculpting
            let kc: Double = mat.pullHold >= 0.5 ? kc0 * pullHoldK(mat) : kc0   // v2.61 A3 (cr): pulled long and stopped, it all but stops remembering
            // v2.24 pressLocal: while the finger has not moved off (0.15R) only the part near it remembers. With the whole body remembering, holding still wrote the
            // small shape-matching errors into the far edge, a 48° corner in 4 s (in Q itself); once it moves the whole body remembers as before, pulls keep their shape
            let plGrabs = fingers.values.filter { $0.mode == .grab }
            for f in plGrabs where !f.far && hypot(f.rawX - f.ax, f.rawY - f.ay) > R * 0.15 { f.far = true }
            let plOn: Bool = mat.pressLocal >= 0.5 && plGrabs.allSatisfy { !$0.far }, plK: Double = 1 / (0.49 * R * R)
            // v2.16: the press push is a performance, taken off before remembering (turned into rest space). Kept, clay remembered
            // the pushed shape and the next step pushed again on top: the longer the hold the wider (measured: 1.5 s moved 48 pt, was 24)
            let pf = pressField(), gcs = clusters[gi].cs, gsn = clusters[gi].sn
            // v2.38: a flipped triangle's three corners do not remember this frame (two fingers pulling up and down from the middle left 70-140 flipped
            // triangles in the remembered shape, spikes 3 s after release; the ring-crossing check alone does not see them)
            let bad: [Bool]? = mat.flipMem >= 0.5 ? flipMarks(X, Y) : nil
            if kc > 0 {
                for i in 0..<N where !(bad?[i] ?? false) {
                    // compared with the performed reference EX, not Q: touched pseudopods hold still in mid-air, and against Q
                    // they were remembered as a mark (measured: a 1.5 s hold remembered 67 pt)
                    var rx = RX[i] / GW[i], ry = RY[i] / GW[i]
                    if !pf.isEmpty { let q = pressPush(pf, X[i], Y[i]); rx -= gcs * q.0 + gsn * q.1; ry -= -gsn * q.0 + gcs * q.1 }
                    let sx = usePS ? SX2[i] / GW[i] : EX[i], sy = usePS ? SY2[i] / GW[i] : EY[i], dx = rx - sx, dy = ry - sy, dl = hypot(dx, dy)
                    if dl > yl {
                        var plw = 1.0
                        if plOn { plw = 0; for f in plGrabs { let ax: Double = X[i] - f.fx, ay: Double = Y[i] - f.fy; plw = max(plw, exp(-(ax * ax + ay * ay) * plK)) } }
                        let s: Double = (1 - yl / dl) * kc * plw * (TID[i] >= 0 ? 1 - 0.85 * TU[i] * (1 - mat.tentMem) : 1)
                        QX[i] += dx * s; QY[i] += dy * s
                        let ex = QX[i] - H0X[i], ey = QY[i] - H0Y[i], el = hypot(ex, ey), lim = R * mat.memMax   // clay 4R: pull long, spread flat
                        if el > lim { QX[i] = H0X[i] + ex * lim / el; QY[i] = H0Y[i] + ey * lim / el }
                    }
                }
            }
        } else {
            // crossed: relax at the v2.13 rate (0.3). With recover slowed to 0.05 the knot a 9R pull leaves in the tail stayed for
            // 12 s after release; relaxing shortens the strand and the knot comes undone
            // v2.58: the remembered outline crosses itself, undo it faster (0.6). Checked here every 0.1 s, also with no re-sample, while clinging, with tentacles
            let knotOn: Bool = mat.remeshHome >= 0.5 && mat.endless >= 0.5
            if knotOn {
                remKnotChk += dt
                let untying: Bool = mat.memUntie > 0 && remKnot > mat.memUntie   // while untying, every frame: stop as soon as it is undone
                if remKnotChk >= 0.1 || untying { remKnotChk = 0; remCrossQ = ringCrossedQ() }
            }
            let cq: Bool = knotOn && remCrossQ
            // v2.58 (11-24) memUntie: crossed longer than this, retreat fast and leave out the memory's own limits below until it is undone (they held the knot in place and it kept shaking)
            remKnot = cq ? remKnot + dt : 0
            untie = cq && mat.memUntie > 0 && remKnot > mat.memUntie
            var back: Double = mat.recover
            if untie { back = 4 }
            else if cq && mat.recover < 0.6 { back = 0.6 }
            else if mat.recover < 0.3 {
                if mat.ringGuard > 0 && ringCrossed() { back = 0.3 }
                else if mat.flipMem >= 0.5 && mat.endless < 0.5 && flipCount(QX, QY) > 0 { back = 0.3 }
            }
            let kr: Double = min(1, back * dt)   // v2.54 無限拉: a few flipped triangles in a long remembered shape no longer make all of it retreat fast (it lost half in 2 s); the no-flip guard opens them, a crossed ring still retreats fast   // v2.38: a flipped remembered shape too
            if kr > 0 {
                for i in 0..<N { QX[i] += (H0X[i] - QX[i]) * kr; QY[i] += (H0Y[i] - QY[i]) * kr }
            }
            if mat.flow > 0 && flowFree { flowStep(dt, mat.flow) }   // v2.52 A4 流
        }
        // tentacles barely remember: tips always spring back to their length and thickness (the body is the clay).
        // tentMem 1 (clay, 多米 2026-11-01: a pinched foot snapped straight back) turns this off; they relax at `recover`.
        // Must happen before recentering, with Q0 zero-mean, or the junction drifts apart frame by frame.
        let kt = min(1, 0.8 * (1 - mat.tentMem) * dt)
        if kt > 0 {
            for i in 0..<N where TID[i] >= 0 {
                let w = kt * TU[i]
                QX[i] += (Q0X[i] - QX[i]) * w; QY[i] += (Q0Y[i] - QY[i]) * w
            }
        }
        if mat.tentMem > 0 { restFix(mat) }
        tentRest(dt, mat)
        if !untie && mat.memSmooth > 0 { memSmoothStep(dt, mat.memSmooth) }   // v2.47
        if !untie && mat.memCap > 0 && !EDG.isEmpty {   // v2.48: the remembered shape keeps to its own limits
            for _ in 0..<3 { if !strainStep(&QX, &QY, mat.capLo, memCapNow(mat), false, mat) { break } }
        }
        if EDL.count * 2 == EDG.count {   // the remembered shape's longest edge, times rest (the pseudopods fade by it)
            var mq = 1.0, e = 0, k = 0
            while e + 1 < EDG.count {
                let i = EDG[e], j = EDG[e + 1], ddx: Double = QX[i] - QX[j], ddy: Double = QY[i] - QY[j]
                let l: Double = (ddx * ddx + ddy * ddy) / (EDL[k] * EDL[k])
                if l > mq { mq = l }
                e += 2; k += 1
            }
            QSTR = mq.squareRoot()
        }
        if !untie && mat.noFlip > 0 { meshGuard(&QX, &QY, max(mat.noFlip, 0.3), nil) }   // v2.29: the remembered shape may not flip either (measured: 102 triangles flipped after rough pulling, and it never came undone)
        var mx = 0.0, my = 0.0
        for i in 0..<N { mx += QX[i]; my += QY[i] }
        mx /= Double(N); my /= Double(N)
        for i in 0..<N { QX[i] -= mx; QY[i] -= my }
        // clay keeps its volume: the remembered shape scales back to the original area (a pulled-out lump takes a little from
        // everywhere else; without it the area was 2% high after a pull)
        var A = 0.0, B = 0.0
        let n = bnd.count
        for k in 0..<n {
            let i = bnd[k], j = bnd[(k + 1) % n]
            A += QX[i] * QY[j] - QX[j] * QY[i]; B += H0X[i] * H0Y[j] - H0X[j] * H0Y[i]
        }
        if abs(A) > 1e-6 {
            let f = (abs(B / A)).squareRoot()
            if abs(f - 1) > 1e-5 { for i in 0..<N { QX[i] *= f; QY[i] *= f } }
        }
    }

    /// The remembered tentacles must not fold either (tentMem): rungs and medial axis on the rest shape, a cap on the
    /// accumulated bend, and a rigid tip. Same rules as tentacleRungs, no finger weights.
    private func restFix(_ mat: FeelParams) {
        if rest0.count != rungs.count {
            rest0 = rungs.indices.map { k in rungs[k].indices.map { r in restBase(k, r, Q0X, Q0Y) } }
        }
        func wrap(_ a: Double) -> Double { atan2(sin(a), cos(a)) }
        for k in rungs.indices {
            let list = rungs[k], s0 = rungSign[k], nr = list.count
            if nr < 2 { continue }
            // widths: no narrower than 80% of the original's own (remembered thin, the sides crossed while pushed)
            if mat.tentRung > 0 {
                for r in 0..<nr {
                    let p = list[max(0, r - 1)], q = list[min(nr - 1, r + 1)], g = list[r]
                    var tx = QX[q.a] + QX[q.b] - QX[p.a] - QX[p.b], ty = QY[q.a] + QY[q.b] - QY[p.a] - QY[p.b]
                    let tl = max(1e-6, hypot(tx, ty)); tx /= tl; ty /= tl
                    let nx = -ty * s0, ny = tx * s0
                    let cn = (QX[g.b] - QX[g.a]) * nx + (QY[g.b] - QY[g.a]) * ny, wmin = rest0[k][r].w * 0.8
                    if cn < wmin {
                        let d = (wmin - cn) * 0.5
                        QX[g.a] -= nx * d; QY[g.a] -= ny * d; QX[g.b] += nx * d; QY[g.b] += ny * d
                    }
                }
            }
            // axis: the rule or the original's own value, whichever is smaller (the original does not always satisfy
            // the rule, and the rule alone kept pushing an untouched rest shape 6 pt off)
            let rp = rungRef[k]
            if mat.tentAxis > 0 {
                for r in 0..<(nr - 1) {
                    let g = list[r], q = list[r + 1]
                    var ux: Double, uy: Double
                    if r == 0 {
                        ux = (QX[g.a] + QX[g.b] - QX[rp.0] - QX[rp.1]) * 0.5; uy = (QY[g.a] + QY[g.b] - QY[rp.0] - QY[rp.1]) * 0.5
                    } else {
                        let p = list[r - 1]
                        ux = (QX[g.a] + QX[g.b] - QX[p.a] - QX[p.b]) * 0.5; uy = (QY[g.a] + QY[g.b] - QY[p.a] - QY[p.b]) * 0.5
                    }
                    let ul = max(1e-6, hypot(ux, uy)); ux /= ul; uy /= ul
                    let sv = ((QX[q.a] + QX[q.b] - QX[g.a] - QX[g.b]) * ux + (QY[q.a] + QY[q.b] - QY[g.a] - QY[g.b]) * uy) * 0.5
                    let hmin = min(q.hs * mat.tentAxis, rest0[k][r].s)
                    if sv < hmin {
                        let d = (hmin - sv) * 0.5
                        QX[q.a] += ux * d; QY[q.a] += uy * d; QX[q.b] += ux * d; QY[q.b] += uy * d
                        QX[g.a] -= ux * d; QY[g.a] -= uy * d; QX[g.b] -= ux * d; QY[g.b] -= uy * d
                    }
                }
            }
            // accumulated bend: measured from the first link, at most bendMax more than the original; past that the rest of
            // the tentacle turns back about that joint. Per-link rules cannot stop a little turn per link curling the tip
            // back onto the middle, and memory then curled it further (measured: the held folds in T11 were exactly that)
            func mid(_ AX: [Double], _ AY: [Double], _ r: Int) -> (Double, Double) {
                r < 0 ? ((AX[rp.0] + AX[rp.1]) * 0.5, (AY[rp.0] + AY[rp.1]) * 0.5)
                      : ((AX[list[r].a] + AX[list[r].b]) * 0.5, (AY[list[r].a] + AY[list[r].b]) * 0.5)
            }
            func ang(_ AX: [Double], _ AY: [Double], _ r: Int) -> Double {
                let p = mid(AX, AY, r - 1), q = mid(AX, AY, r)
                return atan2(q.1 - p.1, q.0 - p.0)
            }
            if nr >= 3 {
                let d0 = wrap(ang(QX, QY, 0) - ang(Q0X, Q0Y, 0))
                for r in 2..<nr {
                    let c = wrap(wrap(ang(QX, QY, r) - ang(Q0X, Q0Y, r)) - d0)
                    if abs(c) <= Self.bendMax { continue }
                    let ex = c - (c > 0 ? 1 : -1) * Self.bendMax, co = cos(-ex), sn = sin(-ex)
                    let pv = mid(QX, QY, r - 1), ut = min(TU[list[r].a], TU[list[r].b]) - 1e-6
                    for i in 0..<N where TID[i] == k && TU[i] >= ut {
                        let ox = QX[i] - pv.0, oy = QY[i] - pv.1
                        QX[i] = pv.0 + co * ox - sn * oy; QY[i] = pv.1 + sn * ox + co * oy
                    }
                }
            }
            // the last two or three rungs are almost zero wide and cannot hold the tip; remembered on its own it crumpled
            // into a bow tie. From the third rung from the end the tip turns and moves with that link, in its original shape
            let ai = max(1, nr - 3), g = list[ai], p = list[ai - 1], ut = max(TU[g.a], TU[g.b])
            let m0x = (Q0X[g.a] + Q0X[g.b]) * 0.5, m0y = (Q0Y[g.a] + Q0Y[g.b]) * 0.5
            let mx = (QX[g.a] + QX[g.b]) * 0.5, my = (QY[g.a] + QY[g.b]) * 0.5
            let d0x = m0x - (Q0X[p.a] + Q0X[p.b]) * 0.5, d0y = m0y - (Q0Y[p.a] + Q0Y[p.b]) * 0.5
            let dx = mx - (QX[p.a] + QX[p.b]) * 0.5, dy = my - (QY[p.a] + QY[p.b]) * 0.5
            let an = atan2(d0x * dy - d0y * dx, d0x * dx + d0y * dy), c = cos(an), sn = sin(an)
            for i in 0..<N where TID[i] == k && TU[i] > ut {
                let ox = Q0X[i] - m0x, oy = Q0Y[i] - m0y
                QX[i] = mx + c * ox - sn * oy; QY[i] = my + sn * ox + c * oy
            }
        }
    }

    /// Rung `r` of tentacle `k` on a shape: its width across the local axis, and how far the next rung advances along it.
    private func restBase(_ k: Int, _ r: Int, _ AX: [Double], _ AY: [Double]) -> (w: Double, s: Double) {
        let list = rungs[k], s0 = rungSign[k], nr = list.count, rp = rungRef[k]
        let p = list[max(0, r - 1)], q = list[min(nr - 1, r + 1)], g = list[r]
        var tx = AX[q.a] + AX[q.b] - AX[p.a] - AX[p.b], ty = AY[q.a] + AY[q.b] - AY[p.a] - AY[p.b]
        let tl = max(1e-6, hypot(tx, ty)); tx /= tl; ty /= tl
        let cn = (AX[g.b] - AX[g.a]) * (-ty * s0) + (AY[g.b] - AY[g.a]) * (tx * s0)
        if r >= nr - 1 { return (cn, 1e9) }
        let q2 = list[r + 1]
        var ux: Double, uy: Double
        if r == 0 {
            ux = (AX[g.a] + AX[g.b] - AX[rp.0] - AX[rp.1]) * 0.5; uy = (AY[g.a] + AY[g.b] - AY[rp.0] - AY[rp.1]) * 0.5
        } else {
            let p1 = list[r - 1]
            ux = (AX[g.a] + AX[g.b] - AX[p1.a] - AX[p1.b]) * 0.5; uy = (AY[g.a] + AY[g.b] - AY[p1.a] - AY[p1.b]) * 0.5
        }
        let ul = max(1e-6, hypot(ux, uy))
        return (cn, ((AX[q2.a] + AX[q2.b] - AX[g.a] - AX[g.b]) * ux + (AY[q2.a] + AY[q2.b] - AY[g.a] - AY[g.b]) * uy) * 0.5 / ul)
    }

    // MARK: - Idle morph (2026-11-01 多米真機回報: it looked like one shape swaying)
    // Outline modes 2...5, each coefficient on its own smooth noise (lattice noise, Catmull-Rom), higher modes faster and
    // smaller; plus two bumps (or dents) roaming round the body. Uncorrelated, so the shape keeps changing and never comes
    // back to the same few poses. A function of the clock only; same numbers as the web prototype

    private static let morphW: [Double] = [0, 0, 1, 0.8, 0.55, 0.35], morphT: [Double] = [0, 0, 2.1, 1.7, 1.45, 1.25]
    private static let bumpSig = 0.5, bumpMean = 0.5 / (2 * Double.pi).squareRoot()
    private static let bendMax = 1.2

    private static func hash1(_ n: Double) -> Double {
        let s = sin(n * 127.1 + 311.7) * 43758.5453
        return (s - floor(s)) * 2 - 1
    }

    private static func vnoise(_ ch: Int, _ x: Double) -> Double {
        let i = floor(x), f = x - i, b = Double(ch * 1013)
        let p0 = hash1(b + i - 1), p1 = hash1(b + i), p2 = hash1(b + i + 1), p3 = hash1(b + i + 2)
        return 0.5 * (2 * p1 + (p2 - p0) * f + (2 * p0 - 5 * p1 + 4 * p2 - p3) * f * f + (3 * p1 - p0 - 3 * p2 + p3) * f * f * f)
    }

    private func morphCoef(_ tl: Double) {
        for m in 2...5 {
            let dm = Double(m)
            morphA[m] = Self.morphW[m] * Self.vnoise(2 * m, tl / Self.morphT[m] + dm * 0.37) / 1.3
            morphB[m] = Self.morphW[m] * Self.vnoise(2 * m + 1, tl / Self.morphT[m] + dm * 0.61) / 1.3
        }
        for j in 0..<2 {
            let dj = Double(j)
            bumpAng[j] = dj * .pi + 3.5 * Self.vnoise(60 + 2 * j, tl / 3.3 + dj * 0.5)
            bumpAmp[j] = 0.9 * Self.vnoise(61 + 2 * j, tl / 1.9 + dj * 0.3)
        }
    }

    /// Radial push of the roaming bumps at direction (c1, s1); the mean is taken out so the area stays put to first order.
    private func bumpAt(_ c1: Double, _ s1: Double) -> Double {
        var d = 0.0
        for j in 0..<2 {
            let ca = cos(bumpAng[j]), sa = sin(bumpAng[j]), da = atan2(s1 * ca - c1 * sa, c1 * ca + s1 * sa)
            d += bumpAmp[j] * (exp(-da * da / (2 * Self.bumpSig * Self.bumpSig)) - Self.bumpMean)
        }
        return d
    }

    /// No boundary through boundary (多米 2026-11-01: a pulled strand crossed the body and looked about to break). Particle
    /// non-penetration only stops point against point; once stretched the ring is sparse and another edge slips between two points.
    /// A ring particle keeps 0.45h from the other ring segments of its own group, on the side it was on last substep (PX). Judging
    /// by "the outside" (a solid body's ring point should be outside any other segment) was tried: across a thin strand the two
    /// edges are inside each other by the strand's thickness, and that pushed them into crossing. Runs after the walls; the crossings
    /// came from the walls (the held patch pressed flat against a wall), so the finger also keeps off the walls
    private static func segX(_ ax: Double, _ ay: Double, _ bx: Double, _ by: Double,
                             _ cx: Double, _ cy: Double, _ dx: Double, _ dy: Double) -> Bool {
        let d = (bx - ax) * (dy - cy) - (by - ay) * (dx - cx)
        if abs(d) < 1e-12 { return false }
        let u = ((cx - ax) * (dy - cy) - (cy - ay) * (dx - cx)) / d, v = ((cx - ax) * (by - ay) - (cy - ay) * (bx - ax)) / d
        return u > 0 && u < 1 && v > 0 && v < 1
    }

    /// Any crossing inside one group of the boundary ring (a tentacle, or the body).
    private func ringCrossed() -> Bool {
        let n = bnd.count
        for i in 0..<n {
            let a = bnd[i], b = bnd[(i + 1) % n]
            for j in (i + 2)..<max(i + 2, n) {
                if i == 0 && j == n - 1 { continue }
                let p = bnd[j], q = bnd[(j + 1) % n]
                if TID[a] == TID[p] && TID[b] == TID[q] && Self.segX(X[a], Y[a], X[b], Y[b], X[p], Y[p], X[q], Y[q]) { return true }
            }
        }
        return false
    }

    /// Little knots straightened (2026-11-01: next to the held point two or three ring particles swapped order into a little Z the
    /// one-apart distance rule could not stop): if two ring segments 2 to 5 apart cross, the particles between are laid back on
    /// the straight line between the ends (position and previous position move together, the velocity stays)
    private func ringUnkink() {
        let n = bnd.count
        for i in 0..<n {
            let a = bnd[i], b = bnd[(i + 1) % n]
            for s in 2...5 {
                let j = (i + s) % n, p = bnd[j], q = bnd[(j + 1) % n]
                if TID[a] != TID[p] { continue }
                if !Self.segX(X[a], Y[a], X[b], Y[b], X[p], Y[p], X[q], Y[q]) { continue }
                for m in 1...s {
                    let c = bnd[(i + m) % n], f = Double(m) / Double(s + 1)
                    let dx = X[a] + (X[q] - X[a]) * f - X[c], dy = Y[a] + (Y[q] - Y[a]) * f - Y[c]
                    X[c] += dx; Y[c] += dy; PX[c] += dx; PY[c] += dy
                }
                break
            }
        }
    }

    private func ringGuard(_ rkv: Double = 0) {
        let nb = bnd.count, dm = h * 0.45, far = dm * 4
        for k in 0..<nb {
            let p = bnd[k], xp = X[p], yp = Y[p]
            for m in 0..<nb {
                if m == k || (m + 1) % nb == k { continue }
                let a = bnd[m], b = bnd[(m + 1) % nb]
                if TID[a] != TID[p] || TID[b] != TID[p] { continue }
                let xa = X[a], ya = Y[a], xb = X[b], yb = Y[b]
                if xp < min(xa, xb) - far || xp > max(xa, xb) + far || yp < min(ya, yb) - far || yp > max(ya, yb) + far { continue }
                let ex = xb - xa, ey = yb - ya, l2 = ex * ex + ey * ey
                if l2 < 1e-9 { continue }
                let u = ((xp - xa) * ex + (yp - ya) * ey) / l2
                if u <= 0 || u >= 1 { continue }
                let l = l2.squareRoot(), sn = ((xp - xa) * -ey + (yp - ya) * ex) / l
                let pex = PX[b] - PX[a], pey = PY[b] - PY[a], pl = max(1e-9, hypot(pex, pey))
                let sp = ((PX[p] - PX[a]) * -pey + (PY[p] - PY[a]) * pex) / pl
                if abs(sp) > far { continue }
                let side = sp >= 0 ? 1.0 : -1.0, cur = sn * side
                if cur >= dm { continue }
                // a pair that has really crossed (p's own two segments cut this one) is left to shape matching, which pulls it back
                // to the uncrossed remembered shape; judged by the last substep alone, a crossing got locked in
                let pm = bnd[(k + nb - 1) % nb], pn = bnd[(k + 1) % nb]
                if Self.segX(X[pm], Y[pm], xp, yp, xa, ya, xb, yb) || Self.segX(xp, yp, X[pn], Y[pn], xa, ya, xb, yb) { continue }
                let nx = -ey / l * side, ny = ex / l * side, push = dm - cur
                let wp = GRAB[p] ? 0.3 : 1.0, wa = GRAB[a] ? 0.3 : 1.0, wb = GRAB[b] ? 0.3 : 1.0, ws = wp + wa * (1 - u) + wb * u
                let mp: Double = push * wp / ws, ma: Double = push * wa * (1 - u) / ws, mb: Double = push * wb * u / ws
                X[p] += nx * mp; Y[p] += ny * mp
                X[a] -= nx * ma; Y[a] -= ny * ma
                X[b] -= nx * mb; Y[b] -= ny * mb
                if rkv > 0 {   // v2.48: the correction leaves no velocity
                    PX[p] += nx * mp * rkv; PY[p] += ny * mp * rkv
                    PX[a] -= nx * ma * rkv; PY[a] -= ny * ma * rkv
                    PX[b] -= nx * mb * rkv; PY[b] -= ny * mb * rkv
                }
            }
        }
    }

    // MARK: - v2.28 窗台: gravity, the sill, the bowl (room plane only; the frame, the outside and the routes are the next batch)

    /// The room's geometry from the view size, the same numbers as the web's `sillGeo` (the plate picture is 992×1586 at scale s).
    private func sillGeo() -> SillGeo {
        let s = min(W / 860, H / 1130), U = s * 860 / 393, off = H * 0.72 - 1177 * s, ox = (W - 992 * s) / 2, fl = off + 1228 * s
        let bw = 205 * U, bh = bw * 298 / 420, by = fl - bh, gx = ox + 156 * s, gy = off + 304 * s, gw = 680 * s, gh = 828 * s
        return SillGeo(s: s, U: U, off: off, ox: ox, fl: fl, bw: bw, bh: bh, bx: W / 2, by: by, gx: gx, gy: gy, gw: gw, gh: gh, jr: gx + gw, bt: gy + gh, oy: gy + gh + 22 * U,
                       rim: by + bh * 0.5, lip: by + bh * 0.568, back: by + bh * 0.05, cav: bw * 0.40, outer: bw * 0.5, bf: by + bh * 0.86,
                       l: max(0, ox + 40 * s) + 4, r: min(W, ox + 950 * s) - 4, sl: ox + 40 * s, sr: ox + 950 * s)
    }

    /// Called at the end of setup: the body is moved right above the bowl and dropped in (no hop-in on the sill).
    private func sillInit() {
        clingEnd(); sillStickT = -1   // v2.36
        sillG = nil; sillHop = nil; sillRoute = nil; sillLift = false; sillTanV = false; sillSurf = nil; sillGTX = 0; sillGTY = 1; sillGVX = 0; sillGVY = 1; gaitClimb = false
        sillPlane = .room; sillZoom = 1; sillZTG = 1; sillOutT = 0; sillCB = 0
        walkSettle()   // 走路: a rebuild with something still stuck to it puts the thing on the sill, it is not lost
        guard sillOn, N > 0 else { sillAir = false; sillInBowl = false; sillGrab = false; sillHeld = false; props.removeAll(); decoKeyNow = -1; return }
        let g = sillGeo()
        sillG = g
        sillZPX = W / 2; sillZPY = g.oy
        var y1 = -1e9, mx = 0.0
        for i in 0..<N { mx += X[i] }
        mx /= Double(N)
        for i in bnd { y1 = max(y1, Y[i]) }
        let dx = g.bx - mx, dy = (noBowl ? g.fl - R * 0.6 : g.rim - R * 0.9) - y1   // v2.35: no bowl, it drops onto the middle of the sill
        for i in 0..<N { X[i] += dx; PX[i] = X[i]; Y[i] += dy; PY[i] = Y[i] }
        cx = g.bx; homeX = g.bx; cy = H * 0.5; homeY = cy
        sillAir = true; sillC = 0; sillInBowl = false; sillWant = !noBowl; sillGrab = false; sillHeld = false
        sillPX = 0; sillPY = 0; sillVX = 0; sillVY = 0; sillFall = 0; sillLastHome = t
        camZ = 1; camX = viewV.x; camY = viewV.y; introSq = 0
        propsInit()   // v2.64 擺飾變真 (web sillInit: propsInit())
    }

    /// Where home may be along the sill.
    private func sillClampX(_ x: Double) -> Double {
        guard let g = sillG else { return x }
        if sillPlane == .frame { let m = R * 0.72; return max(g.gx + m, min(g.jr - m, x)) }
        if sillPlane == .out {   // outside: from beside the bowl to half hidden behind the wall on the right (world points at zoom 0.8)
            func sx(_ q: Double) -> Double { W / 2 + (q - W / 2) / 0.8 }
            return max(sx(g.bx + g.bw * 0.5 + R * 0.1), min(sx(g.jr + R * 0.15), x))
        }
        let m = R * 0.9
        return max(g.l + m, min(g.r - m, x))
    }

    /// One particle against the bowl (while it sits inside) and the sill's top. Counts the contacts for the air test.
    private func sillHit(_ i: Int, _ g: SillGeo) {
        if sillPlane == .frame {   // the frame's walls are a soft landing: let go overlapping the frame, one hard push would blow it apart
            if Y[i] > g.bt { Y[i] = g.bt; PY[i] = g.bt; PX[i] += (X[i] - PX[i]) * 0.45; sillC += 1; sillCB += 1 }
            if X[i] < g.gx { let d = g.gx - X[i]; X[i] += min(d, max(1.5, d * 0.35)); PX[i] = X[i]; PY[i] += (Y[i] - PY[i]) * 0.45; sillC += 1 }
            else if X[i] > g.jr { let d = X[i] - g.jr; X[i] -= min(d, max(1.5, d * 0.35)); PX[i] = X[i]; PY[i] += (Y[i] - PY[i]) * 0.45; sillC += 1 }
            if Y[i] < g.gy { let d = g.gy - Y[i]; Y[i] += min(d, max(1.5, d * 0.35)); PY[i] = Y[i]; PX[i] += (X[i] - PX[i]) * 0.45; sillC += 1 }
            return
        }
        if sillPlane == .out {
            if Y[i] > g.oy { Y[i] = g.oy; PY[i] = g.oy; PX[i] += (X[i] - PX[i]) * 0.45; sillC += 1; sillCB += 1 }
            return
        }
        if sillInBowl && !GRAB[i] {
            let dx = X[i] - g.bx, ad = abs(dx)
            if ad < g.cav {
                if Y[i] > g.rim {   // the inside narrows toward the bottom
                    let dp = min(1, (Y[i] - g.rim) / (g.bf - g.rim)), hw = g.cav * (1 - 0.22 * dp * dp)
                    if ad > hw { X[i] = g.bx + (dx < 0 ? -hw : hw); PX[i] = X[i] }
                }
                let u = dx / g.cav, fl = g.bf - (g.bf - g.rim) * 0.3 * u * u * u * u
                if Y[i] > fl { Y[i] = fl; PY[i] = fl; PX[i] += (X[i] - PX[i]) * 0.45; sillC += 1; sillCB += 1 }
            } else if ad < g.outer + R * 0.3 && Y[i] > g.rim - 2 && Y[i] < g.rim + R * 0.6 {   // resting on the rim
                Y[i] = g.rim - 2; PY[i] = Y[i]; PX[i] += (X[i] - PX[i]) * 0.3; sillC += 1
            }
        }
        if Y[i] > g.fl { Y[i] = g.fl; PY[i] = g.fl; PX[i] += (X[i] - PX[i]) * 0.45; sillC += 1; sillCB += 1 }
    }

    /// Before the substeps: is a finger holding it, and where.
    private func sillStepPre() {
        var g = false
        for f in fingers.values where f.mode == .grab { g = true; sillRelX = f.fx; sillRelY = f.fy }
        sillGrab = g
    }

    /// After the substeps: in the air or landed, the landing thump, into and out of the bowl, where home is, the hop.
    private func sillStep(_ dt: Double) {
        guard let g = sillG, !clusters.isEmpty else { return }
        let gcx = clusters[gi].xc, gcy = clusters[gi].yc
        var y1 = -1e9
        for i in bnd { y1 = max(y1, Y[i]) }
        sillY1 = y1
        sillVX = sillPX != 0 ? (gcx - sillPX) / dt : 0
        sillVY = sillPY != 0 ? (gcy - sillPY) / dt : 0
        sillPX = gcx; sillPY = gcy
        do { let k = 1 - exp(-dt / 0.12); sillGVX += (sillGTX - sillGVX) * k; sillGVY += (sillGTY - sillGVY) * k }   // v2.30: gravity turns slowly, so a corner does not fling it
        let wasAir = sillAir
        let hopOn = sillHop != nil, hopAir = sillHop?.air ?? false, hopT = sillHop?.t ?? 1
        // v2.31: for 0.45 s after take-off touching the bowl's side still counts as airborne (the body is wider than the rim; counted as contact, the damping ate the jump, 2 pt high)
        sillAir = (sillC == 0 || (hopAir && hopT < 0.45)) && !sillGrab && !introOn && !sillLift && !(hopOn && !hopAir)
        if sillAir {
            sillFall = max(sillFall, sillVY)
            let lim = R * 30 * lastSdt   // terminal speed
            for i in 0..<N {
                let v = Y[i] - PY[i]
                if v > lim { PY[i] = Y[i] - lim } else if v < -lim { PY[i] = Y[i] + lim }
            }
        }
        if wasAir && !sillAir && !sillGrab {   // landed
            if sillFall > R * 2.5 { onEvent?(.fx(kind: "land", gain: min(0.9, 0.25 + sillFall / (R * 14)), delay: 0)) }
            if hopAir { sillHop = nil }
            sillWant = false; sillFall = 0; sillLastHome = max(sillLastHome, t - 8)
            if sillRoute == nil { lifeSt = .rest; lifeUntil = t + 1 + Double.random(in: 0..<1, using: &rng); if sillSurf == nil { sillSurf = sillPlane == .frame ? "bar" : (sillPlane == .out ? "ledge" : (sillInBowl ? "bowl" : "floor")) } }
        }
        if sillGrab && !sillHeld {   // picked up: whatever it was doing stops
            if sillRoute != nil { routeEnd(abort: true) }
            sillHop = nil; sillSurf = nil; sillTanV = false; sillLift = false; sillGTX = 0; sillGTY = 1; sillStickT = -1
            planeSet(.room)   // lifted: back in front of everything
        }
        // let go right over the bowl: it wants in; anywhere else it lands on the sill (the frame and the walls come with the next batch)
        if sillHeld && !sillGrab && clingOn {   // v2.36: let go with suckers still on, it springs back onto the wall and keeps sticking
            planeSet(isEdge(clingSide) ? .room : .frame); surfSet(clingSide); sillInBowl = false; sillStickT = t; sillStickDur = 8 + 7 * Double.random(in: 0..<1, using: &rng); clingSaid = false
            onEvent?(.press(gain: 0.25))
        } else if sillHeld && !sillGrab && !sillInBowl, let sd = edgeSide(g, y1) {   // v2.51 黏在螢幕四周
            surfSet(sd); sillWant = false; sillStickT = t; sillStickDur = 8 + 7 * Double.random(in: 0..<1, using: &rng)
            for i in 0..<N { PX[i] = X[i]; PY[i] = Y[i] }
            onEvent?(.press(gain: 0.3))
            clingStart(sd)
        } else if sillHeld && !sillGrab && !sillInBowl {
            sillWant = !noBowl && abs(sillRelX - g.bx) < g.cav * 0.9
            if !sillWant && params.cling >= 0.5 && params.frameCling >= 0.5 && gcx > g.gx && gcx < g.jr && y1 < g.bt - 1 {
                var x0 = 1e9, x1 = -1e9, y0 = 1e9
                for i in bnd { x0 = min(x0, X[i]); x1 = max(x1, X[i]); y0 = min(y0, Y[i]) }
                let inFront = !noBowl && x0 < g.bx + g.bw / 2 && x1 > g.bx - g.bw / 2 && y1 > g.back + R * 0.5   // over the bowl it would vanish behind it
                let sp = hypot(sillVX, sillVY)
                // v2.38: yanked to the top-left corner, held, let go: half of it was on the wall above the window (top 16 pt, the frame's inside top 214 pt)
                // and sticking pushed all of it into the frame in one frame: crossed for 1.4 s, 47% of its area. Sticking out past the frame by 0.8R or crossed,
                // it does not stick and drops to the sill as before. Flipped triangles do not count: a slow, normal placing has about 40
                let messy: Bool = effParams.clingTidy >= 0.5 && (y0 < g.gy - R * 0.8 || x0 < g.gx - R * 0.8 || x1 > g.jr + R * 0.8 || ringCrossed())
                let sd: String? = !inFront && !messy && sp < R * 2.5 && y1 < g.bt - R * 0.4 ? (x1 > g.jr - R * 0.3 ? "rjamb" : x0 < g.gx + R * 0.3 ? "ljamb" : y0 < g.gy + R * 0.3 ? "ceil" : nil) : nil
                if let sd {   // v2.36: only sticking takes it onto the frame (it does not climb the frame by itself)
                    planeSet(.frame); surfSet(sd); sillStickT = t; sillStickDur = 8 + 7 * Double.random(in: 0..<1, using: &rng)
                    for i in 0..<N { PX[i] = X[i]; PY[i] = Y[i] }
                    onEvent?(.press(gain: 0.3))
                    clingStart(sd)
                }
            }
        }
        sillHeld = sillGrab
        if sillStickT > t { sillStickT = t }   // the clock went back
        if sillStickT >= 0 && params.life2 >= 0.5 && sillRoute == nil && fingers.isEmpty && t - sillStickT > (sillStickDur > 0 ? sillStickDur : 1.6) {
            sillStickT = -1
            if isEdge(sillSurf) { clingEnd(); sillTanV = false; sillSurf = nil; sillGTX = 0; sillGTY = 1 }   // v2.51: off a screen edge it just drops to the sill
            else { clingEnd(); routeStart(rtFromWall() + rtBackIn()) }   // 8-15 s on the wall, then it climbs down and comes home
        }
        clingStep(dt)
        // home: not while grabbed; in the air it follows the body; on the ground y follows and, inside the bowl, x eases back to the middle
        if !sillGrab {
            if sillAir { homeX = gcx; homeY = gcy }
            else if sillTanV { if !sillLift { homeX = gcx } }
            else { homeY = gcy; if sillInBowl && !escOn && sillRoute == nil { homeX += (g.bx - homeX) * (1 - exp(-dt / 0.3)) } }
            if sillRoute == nil && !sillTanV { homeX = sillClampX(homeX) }
        }
        // out of the bowl (lifted above the rim, or pulled aside), into the bowl (falling onto it from right above)
        if sillRoute == nil {   // a route changes planes itself
            if sillInBowl {
                var out = y1 < g.rim - R * 0.3
                if sillGrab { for f in fingers.values where f.mode == .grab && abs(f.fx - g.bx) > g.cav + R * 0.4 { out = true } }
                if out { sillInBowl = false }
            } else if !sillGrab && sillAir && sillWant && sillVY > 0 && abs(gcx - g.bx) < g.cav * 0.9 && y1 > g.rim - R * 0.2 && y1 < g.rim + R * 0.3 {
                sillInBowl = true; sillWant = false; sillSurf = "bowl"
            }
        }
        // the hop: crouch 0.12 s, then off (sillLaunch); in the air a little stretched
        if var q = sillHop {
            q.t += dt
            if !q.air {
                introSq = 0.14 * sin(min(1, q.t / 0.12) * .pi / 2)
                sillHop = q
                if q.t >= 0.12 { sillLaunch() }
            } else {
                introSq += (-0.06 - introSq) * (1 - exp(-dt / 0.08))
                sillHop = q
            }
        } else if !introOn { introSq *= exp(-dt / 0.08) }
        // startled inside the bowl: it jumps on the spot and drops back in (v2.31: beside the bowl there is no room for it)
        if escOn && (sillTanV || clingOn) && !sillGrab {   // v2.36: pulled until it wants to flee and let go, it drops off the wall and runs
            clingEnd(); sillTanV = false; sillSurf = nil; sillGTX = 0; sillGTY = 1; sillStickT = -1
        }
        if escOn && sillInBowl && !sillGrab && sillHop == nil { sillHopStart(escDX, toBowl: false) }
        walkStep(dt)   // 走路: the thing stuck to it, the ones falling, the ones fading
        if walkPending { walkPending = false; walkCheck() }   // steps read before the sill was ready
        if sillRoute != nil && !sillGrab { routeStep(dt) }
        // v2.31 it only plays with the bowl: left outside (the way home failed half-way) it tries again after 2 s
        if !sillGrab && sillPlane == .out && sillRoute == nil && !gaitOn && !escOn && fingers.isEmpty && lifeSt == .rest && t - sillLastHome > 2 {
            sillLastHome = t
            if let r = rtHome() { routeStart(r) }
        }
        // left alone a while out of the bowl, it goes back
        if !sillGrab && !sillInBowl && !sillAir && sillHop == nil && sillRoute == nil && !gaitOn && !escOn && fingers.isEmpty && lifeSt == .rest && sillStickT < 0
            && t - lastTouch > 25 && t - sillLastHome > 10 && params.envRoam > 0 && !brOn {   // v2.63 大腦: it decides itself when to go back (brainRest)
            sillLastHome = t
            if let r = rtHome() { routeStart(r) }
        }
    }

    // MARK: v2.30 routes (room plane: out of the bowl, back into the bowl)

    /// It decides to go somewhere (goStart on the sill): mostly it stays; from the bowl it sometimes climbs out; on the sill it mostly goes back in, else walks a little.
    private func sillGo() {
        lifeSt = .rest; lifeUntil = t + 2 + 2 * Double.random(in: 0..<1, using: &rng)
        guard sillG != nil, !clusters.isEmpty, sillRoute == nil, sillHop == nil, !sillAir, params.envRoam > 0, snwK <= 0.3, sillStickT < 0, !clingOn else { return }   // v2.31: while the glitter settles it stays in
        let cx0 = clusters[gi].xc, r = Double.random(in: 0..<1, using: &rng) / max(0.01, params.envRoam)
        if sillInBowl { if r < 0.16 { routeStart(rtOutFront(nil)) }; return }
        if sillPlane == .frame { routeStart(rtFromWall() + rtBackIn()); return }   // v2.31: it does not climb the frame by itself, it comes back in
        if sillPlane == .out { routeStart(rtComeBack()); return }
        if noBowl, let g = sillG, abs(cx0 - g.bx) < R * 0.3 {   // v2.35: the middle is home; now and then a little walk
            if r < 0.16, let x = floorWalkX(cx0), abs(x - cx0) > R * 0.3 { gaitTo(x, homeY, dash: false) }
            return
        }
        if r < 0.6 { routeStart(rtIntoFront()); return }
        if let x = floorWalkX(cx0), abs(x - cx0) > R * 0.3 { gaitTo(x, homeY, dash: false) }
    }
    /// A spot on the sill to walk to, anywhere it fits.
    private func floorWalkX(_ cx0: Double) -> Double? {
        guard let g = sillG else { return nil }
        let lo = g.l + R * 0.9, hi = g.r - R * 0.9
        if hi - lo < R * 0.3 { return nil }
        return lo + (hi - lo) * Double.random(in: 0..<1, using: &rng)
    }
    /// Out of the bowl over its front edge: a pseudopod reaches up, the body lifts above the edge, it is in front of the bowl now, flows down onto the sill.
    private func rtOutFront(_ x: Double?) -> [RouteStep] {
        guard let g = sillG else { return [] }
        let a = -.pi / 2 + (Double.random(in: 0..<1, using: &rng) < 0.5 ? -0.3 : 0.3)
        var steps: [RouteStep] = [.sniff(a: a, L: 0.5, T: 0.7), .move(y: g.lip - 6), .plane(.room, inBowl: false), .move(y: g.fl - 2), .surf("floor")]
        if let x { steps.append(.walk(surf: "floor", to: x)) }
        return steps
    }
    /// Back in over the front edge: walk to the bowl, lift above the edge, it is inside now, drop.
    private func rtIntoFront() -> [RouteStep] {
        guard let g = sillG else { return [] }
        if noBowl { return [.walk(surf: "floor", to: sillClampX(g.bx))] }   // v2.35: home is the middle of the sill
        return [.walk(surf: "floor", to: sillClampX(g.bx)), .sniff(a: -.pi / 2, L: 0.5, T: 0.7), .move(y: g.lip - 6), .plane(.room, inBowl: true), .drop(g: 0.8), .surf("bowl")]
    }
    /// Home from wherever it is: outside → over the ledge, up over the frame's bottom, then over the bowl's back edge; behind the bowl → over the back edge; on the sill → over the front edge.
    private func rtHome() -> [RouteStep]? {
        if sillInBowl { return nil }
        if sillPlane == .out { return rtComeBack() + rtBackIn() }
        if sillPlane == .frame { return rtFromWall() + rtBackIn() }
        return rtIntoFront()
    }
    // MARK: - v2.36 黏牆 (port of the web's CLING): a ring of suckers pinned to the wall; pulled past the threshold they let go one by one

    private var clingOn = false, clingSide = "", clingT0 = 0.0, clingAX: [Double] = [], clingAY: [Double] = []
    private var clingN0 = 0, clingN = 0, clingAcc = 0.0, clingSaid = false
    /// v2.58 (11-24): some particle is moving (over 0.003R in one substep; at rest it is far below that)
    private func clingShaking() -> Bool {
        let v: Double = R * 0.003
        for i in 0..<N where abs(X[i] - PX[i]) > v || abs(Y[i] - PY[i]) > v { return true }
        return false
    }
    private var clingKnot = 0.0, clingChk = 0.0   // v2.58 (11-24): how long the body on a screen edge has been knotted, and the 0.1 s check
    private var sillStickT = -1.0, sillStickDur = 0.0
    private func clingWallD(_ side: String, _ x: Double, _ y: Double) -> Double {
        guard let g = sillG else { return 1e9 }
        switch side {
        case "rjamb": return g.jr - x
        case "ljamb": return x - g.gx
        case "rwall": return g.r - x     // v2.51 the screen's edges (the room's walls): left, right, top; below is the sill
        case "lwall": return x - g.l
        case "top": return y - 4
        default: return y - g.gy
        }
    }
    private func isEdge(_ s: String?) -> Bool { s == "rwall" || s == "lwall" || s == "top" }
    private func clingPinAt(_ side: String, _ g: SillGeo, _ x: Double, _ y: Double) -> (x: Double, y: Double) {
        switch side {
        case "rjamb": return (g.jr, y)
        case "ljamb": return (g.gx, y)
        case "rwall": return (g.r, y)
        case "lwall": return (g.l, y)
        case "top": return (x, 4)
        default: return (x, g.gy)
        }
    }
    /// v2.51: set down slowly beside a screen edge, its bottom off the sill: which edge it sticks to
    private func edgeSide(_ g: SillGeo, _ y1: Double) -> String? {
        guard params.edgeCling >= 0.5, params.cling >= 0.5, sillPlane == .room, hypot(sillVX, sillVY) < R * 2.5, y1 < g.fl - R * 0.4, !ringCrossed() else { return nil }
        var x0 = 1e9, x1 = -1e9, y0 = 1e9
        for i in bnd { x0 = min(x0, X[i]); x1 = max(x1, X[i]); y0 = min(y0, Y[i]) }
        if x1 > g.r - R * 0.3 { return "rwall" }
        if x0 < g.l + R * 0.3 { return "lwall" }
        if y0 < 4 + R * 0.3 { return "top" }
        return nil
    }
    /// How far it must be pulled off before a sucker lets go: trusting 1 R, wary 1.5 R
    private func clingP0() -> Double { R * (params.imp >= 0.5 ? max(1, min(1.5, 1.25 - 0.25 * impTrust + 0.25 * impWary)) : 1.2) }
    private func clingStart(_ side: String) {
        guard params.cling >= 0.5 else { return }
        clingOn = true; clingSide = side; clingT0 = t; clingN0 = 0; clingN = 0; clingAcc = 0; clingSaid = false; clingKnot = 0; clingChk = 0
        clingAX = Array(repeating: .nan, count: N); clingAY = clingAX
        eyeUser = t + 1.5
        onEvent?(.fx(kind: "cling", gain: 0.6, delay: 0))   // v2.50 it splats onto the frame
    }
    private func clingEnd() {
        clingOn = false; clingN = 0
        for i in clingAX.indices { clingAX[i] = .nan; clingAY[i] = .nan }
    }
    private func clingFree(_ i: Int) {
        guard i < clingAX.count, !clingAX[i].isNaN else { return }
        clingAX[i] = .nan; clingAY[i] = .nan; clingN -= 1
    }
    private func clingPin(_ i: Int) {
        guard i < clingAX.count else { return }
        let a = clingAX[i]
        if !a.isNaN { X[i] = a; Y[i] = clingAY[i]; PX[i] = a; PY[i] = Y[i] }
    }
    private func clingStep(_ dt: Double) {
        guard clingOn, let g = sillG else { return }
        if clingT0 > t { clingT0 = t }
        let sd = clingSide
        if !sillGrab {   // the first 0.6 s the edge that touches the wall takes hold, at most 16 suckers
            if t - clingT0 < 0.6 && clingN < 16 {
                for i in bnd where i < clingAX.count {
                    if clingN >= 16 { break }
                    if !clingAX[i].isNaN || GRAB[i] { continue }
                    if clingWallD(sd, X[i], Y[i]) < R * 0.08 {
                        let pa = clingPinAt(sd, g, X[i], Y[i])
                        clingAX[i] = pa.x; clingAY[i] = pa.y
                        clingN += 1; clingN0 = max(clingN0, clingN)
                    }
                }
            }
            let mat = effParams
            if isEdge(sd) && mat.memUntie > 0 && mat.endless >= 0.5 && fingers.isEmpty {   // v2.58 (11-24): knotted on a screen edge it cannot come undone (it kept shaking): it lets go early and drops, by the same rule as having stuck long enough
                clingChk += dt
                if clingChk >= 0.1 {
                    clingChk = 0
                    let knotted: Bool = clingShaking() && (ringCrossed() || flipCount(X, Y) > 0)
                    clingKnot = knotted ? clingKnot + 0.1 : 0
                    if clingKnot > 0.6 { clingKnot = 0; sillStickT = max(0, t - 1); sillStickDur = 0.01 }
                }
            }
            if t - clingT0 >= 0.6 && clingN <= 0 { clingEnd() }   // nothing reached the wall: only gravity holds it there, as in v2.30
            return
        }
        var pull = 0.0, fx = 0.0, fy = 0.0
        for f in fingers.values where f.mode == .grab {
            let d = clingWallD(sd, f.fx, f.fy)
            if f.clD0 == nil { f.clD0 = d; for i in 0..<N where GRAB[i] { clingFree(i) } }   // what the finger holds is not pinned: it comes loose from where you took it
            let p = d - (f.clD0 ?? d)
            if p > pull { pull = p; fx = f.fx; fy = f.fy }
        }
        let p0 = clingP0()
        if pull <= p0 || clingN <= 0 { clingAcc = 0; return }
        eyeSqU = max(eyeSqU, t + 0.3)
        if !clingSaid { clingSaid = true; voice("protest") }
        for i in 0..<min(N, clingAX.count) where !GRAB[i] && clingAX[i].isNaN {   // the whole thing trembles
            PX[i] += Double.random(in: -0.5..<0.5, using: &rng) * R * 0.01; PY[i] += Double.random(in: -0.5..<0.5, using: &rng) * R * 0.01
        }
        clingAcc += dt
        let step = 0.22 / (1 + 1.5 * (pull - p0) / R)   // just past the threshold a sucker every 0.2 s, faster the further you pull
        while clingAcc >= step && clingN > 0 {
            clingAcc -= step
            var far = -1, fd = -1.0
            for i in 0..<min(N, clingAX.count) where !clingAX[i].isNaN {
                let d = hypot(X[i] - fx, Y[i] - fy)
                if d > fd { fd = d; far = i }
            }
            if far < 0 { break }
            clingFree(far)
            // the phone can do what the web cannot: each sucker letting go is a tap, heavier as more come off
            onEvent?(.tick(gain: min(1, 0.3 + 0.7 * Double(clingN0 - clingN) / Double(max(1, clingN0)))))
        }
        if clingN <= max(2, Int((Double(clingN0) * 0.25).rounded(.up))) {   // pulled off: the rest let go at once, one heavy pop
            clingEnd()
            onEvent?(.release(gain: 0.95, rate: 0.95, special: true))
            onEvent?(.fx(kind: "unstick", gain: 0.9, delay: 0))   // v2.50 the suction letting go
            voice("poke")
        }
    }

    /// v2.30/v2.36 off the wall: down a jamb to the frame's bottom and round the corner; from the top it lets go and drops
    private func rtFromWall() -> [RouteStep] {
        guard let g = sillG else { return [] }
        if sillSurf == "ceil" { return [.wait(T: 0.2), .drop(g: 0.8), .surf("bar")] }
        if sillTanV, let s = sillSurf { return [.walk(surf: s, to: g.bt - R * 0.85), .turn("bar")] }
        return []
    }
    /// From the ledge outside back onto the frame's bottom (v2.31: the target is where the frame has room; outside, the room is further right at zoom 0.8).
    private func rtComeBack() -> [RouteStep] {
        guard let g = sillG, !clusters.isEmpty else { return [] }
        let x = max(g.gx + R * 0.8, min(g.jr - R * 0.8, clusters[gi].xc))
        return [.walk(surf: "ledge", to: x), .zoomHome, .move(y: g.bt - 3), .plane(.frame, inBowl: nil), .drop(g: 0.6), .surf("bar")]
    }
    /// From behind the bowl over its back edge and in (v2.31: all the way, it does not stop on the frame's bottom where the bowl would hide it).
    private func rtBackIn() -> [RouteStep] {
        guard let g = sillG else { return [] }
        let x = max(g.gx + R * 0.72, g.bx)
        if noBowl { return [.walk(surf: "bar", to: x), .sniff(a: .pi / 2, L: 0.4, T: 0.6), .plane(.room, inBowl: false), .drop(g: 0.8), .surf("floor")] }   // v2.35: off the frame's bottom, down onto the sill
        return [.walk(surf: "bar", to: x), .sniff(a: -.pi / 2, L: 0.5, T: 0.7), .move(y: g.back - 3), .plane(.room, inBowl: true), .drop(g: 0.8), .surf("bowl")]
    }
    private func planeSet(_ pl: SillPlane) {
        guard sillPlane != pl, let g = sillG else { return }
        sillPlane = pl
        if pl == .out { sillZTG = 0.8; sillZPX = W / 2; sillZPY = g.oy; sillOutT = t } else { sillZTG = 1 }
    }

    /// Sticking to a surface: floor and bowl both mean gravity straight down (the jambs and the ceiling come with the frame).
    private func surfSet(_ name: String) {
        sillSurf = name; sillLift = false
        switch name {   // v2.30 SURF: on a jamb gravity points into the jamb (0.6), on the top it points up (0.6); it walks up and down a jamb
        case "rjamb": sillGTX = 0.6; sillGTY = 0; sillTanV = true
        case "ljamb": sillGTX = -0.6; sillGTY = 0; sillTanV = true
        case "ceil": sillGTX = 0; sillGTY = -0.6; sillTanV = false
        case "rwall": sillGTX = 0.6; sillGTY = 0; sillTanV = true    // v2.51 screen edges
        case "lwall": sillGTX = -0.6; sillGTY = 0; sillTanV = true
        case "top": sillGTX = 0; sillGTY = -0.6; sillTanV = false
        default: sillGTX = 0; sillGTY = 1; sillTanV = false
        }
        if !clusters.isEmpty { homeX = clusters[gi].xc; homeY = clusters[gi].yc }
    }
    /// A route's walking: the gait with lifeSt = .route (the life leaves it alone), climbing strokes when `climb`.
    private func gaitGo(_ tx: Double, _ ty: Double, climb: Bool) {
        lifeSt = .route; wanderSX = homeX; wanderSY = homeY; wanderX = tx; wanderY = ty; wanderMoving = true
        gaitOn = true; gaitTX = tx; gaitTY = ty; gaitDash = false; gaitClimb = climb; gaitPh = -1; gaitPrep = 0; gaitV = 0
        gaitH = atan2(ty - homeY, tx - homeX); gaitK = 1; gaitStr = 1; gaitLast = false; gaitOff = 0
    }
    private func routeStart(_ steps: [RouteStep]) {
        guard !steps.isEmpty else { return }
        if sillRoute != nil { routeEnd(abort: true) }
        sillStickT = -1; clingEnd()   // v2.36
        cutSniffs(); gaitOn = false; wanderMoving = false
        routeSeq += 1
        sillRoute = Route(steps: steps, i: -1, st0: t, id: routeSeq)
        lifeSt = .route
        routeNext()
    }
    private func routeEnd(abort: Bool) {
        guard sillRoute != nil else { return }
        sillRoute = nil; gaitOn = false; gaitK = 1; gaitClimb = false; wanderMoving = false; sillLift = false
        if abort { sillTanV = false; sillGTX = 0; sillGTY = 1; sillSurf = nil }
        if lifeSt == .route || lifeSt == .go || lifeSt == .arrive { lifeSt = .rest; lifeUntil = t + restDur() }
    }
    private func routeNext() {
        guard var Q = sillRoute else { return }
        while true {
            Q.i += 1; Q.st0 = t
            sillRoute = Q
            guard Q.i < Q.steps.count else { routeEnd(abort: false); return }
            switch Q.steps[Q.i] {
            case .plane(let pl, let ib):
                planeSet(pl)
                if let ib { sillInBowl = ib; if ib { sillWant = false } }
                continue
            case .zoomHome:
                sillZTG = 1
                continue
            case .turn(let name):   // v2.36: round a corner onto another surface (off a jamb onto the frame's bottom)
                surfSet(name)
                return
            case .walkHops:   // v2.32 興奮: home from a walk, one hop (livelier) or two (very excited); a finger cutting the way home skips it
                walkHopN = Int((2 * exLevel()).rounded()); walkHopAt = t
                continue
            case .surf(let name):
                surfSet(name)
                continue
            case .sniff(let a, let L, let T):
                _ = startSniff(a, L, 0.4, max(0.15, T - 0.5), 0.5)
                return
            case .move(let y):   // gravity off, it lifts itself: the target is far away on purpose, routeStep stops it once its bottom really reaches y
                sillLift = true; sillTanV = true; sillSurf = nil; sillGTX = 0; sillGTY = 0
                if !clusters.isEmpty { homeX = clusters[gi].xc; homeY = clusters[gi].yc }
                let dy = y - sillY1
                if abs(dy) < 2 { continue }
                gaitGo(homeX, homeY + (dy > 0 ? 1 : -1) * H * 2, climb: true)
                return
            case .drop(let gg):
                sillLift = false; sillTanV = false; sillSurf = nil; sillGTX = 0; sillGTY = gg > 0 ? gg : 1
                return
            case .walk(let name, let to):
                surfSet(name)
                guard !clusters.isEmpty else { continue }
                let d = to - (sillTanV ? clusters[gi].yc : clusters[gi].xc)
                if abs(d) < R * 0.06 { continue }
                gaitGo(sillTanV ? homeX : to, sillTanV ? to : homeY, climb: sillTanV)
                return
            case .wait:
                return
            case .fn(let f):   // v2.64 (web RT.fn): done at once; it may have ended the route
                f()
                guard let cur = sillRoute else { return }
                Q = cur
                continue
            }
        }
    }
    private func routeStep(_ dt: Double) {
        guard var Q = sillRoute else { return }
        guard Q.i >= 0, Q.i < Q.steps.count else { routeEnd(abort: false); return }
        let u = t - Q.st0
        if escOn { routeEnd(abort: true); return }
        switch Q.steps[Q.i] {
        case .sniff(_, _, let T):
            if u >= T { routeNext() }
        case .wait(let T):
            if u >= T { routeNext() }
        case .move(let y):
            if gaitOn { gaitStep(dt) }
            if lifeSt == .arrive { lifeSt = .route }
            if Q.y0 == nil || Q.i0 != Q.i { Q.y0 = sillY1; Q.i0 = Q.i; sillRoute = Q }
            let y0 = Q.y0 ?? sillY1
            let hit = y < y0 ? sillY1 <= y : sillY1 >= y
            if !gaitOn || hit { gaitOn = false; gaitK = 1; wanderMoving = false; routeNext(); return }
            if u > 8 { routeEnd(abort: true) }
        case .walk:
            if gaitOn { gaitStep(dt) }
            if lifeSt == .arrive { lifeSt = .route }
            if !gaitOn { gaitK = 1; wanderMoving = false; routeNext(); return }
            if u > 40 { routeEnd(abort: true) }
        case .drop:
            if ((sillPlane == .room ? sillC : sillCB) > 0 && u > 0.08) || u > 2.5 { sillGTY = 1; routeNext() }   // behind the bowl and outside only the floor counts: sliding down a wall is not landing
        case .turn(let s):
            let c = s == "bar" ? sillCB : sillC
            if (c > 0 && u > 0.15) || u > 1.2 { routeNext() }
        case .plane, .surf, .zoomHome, .walkHops, .fn:
            routeNext()
        }
    }

    /// A hop is only for being startled (crouch 0.12 s, then take off); in and out of the bowl it climbs (next batch).
    private func sillHopStart(_ tx: Double, toBowl: Bool) {
        guard sillHop == nil, !sillGrab, let g = sillG else { return }
        gaitOn = false; wanderMoving = false
        if sillRoute != nil { routeEnd(abort: true) }
        let tb0 = toBowl && !noBowl
        var x = tb0 ? g.bx : sillClampX(tx), tb = tb0
        if !tb && sillInBowl && abs(x - g.bx) < g.outer + R * 0.9 { tb = true; x = g.bx }
        sillHop = SillHop(air: false, t: 0, tx: x, toBowl: tb)
        lifeSt = .rest; lifeUntil = t + 3
    }

    private func sillLaunch() {
        guard var q = sillHop, let g = sillG, !clusters.isEmpty else { return }
        let g0 = R * sillGrav, hs = 1.0 / 240
        var y1 = -1e9
        for i in bnd { y1 = max(y1, Y[i]) }
        var hh = R * (0.55 + 0.25 * Double.random(in: 0..<1, using: &rng))
        if q.toBowl { hh = max(y1 - g.rim, 0) + R * (sillInBowl ? 0.9 : 0.45) }
        else if sillInBowl { hh = max(hh, y1 - g.rim + R * 0.85) }   // v2.31: inside the bowl it jumps higher, the rim eats part of it
        let vy = sqrt(2 * g0 * hh), land = q.toBowl ? g.rim : g.fl
        let T = vy / g0 + sqrt(2 * max(R * 0.1, hh + land - y1) / g0)
        let vx = max(-W * 1.6, min(W * 1.6, (q.tx - clusters[gi].xc) / T))
        for i in 0..<N { PY[i] = Y[i] + vy * hs; PX[i] = X[i] - vx * hs }
        sillWant = q.toBowl; sillAir = true; sillC = 0; sillFall = 0
        q.air = true; q.t = 0; sillHop = q
        onEvent?(.land(gain: 0.22))
    }

    // MARK: - v2.31 搖晃沉澱

    /// The glitter's own random numbers: building the body does not touch the shared ones (the web's self-test relies on that)
    private func grnd() -> Double {
        glitSeed = glitSeed &* 1664525 &+ 1013904223
        return Double(glitSeed) / 4294967296
    }
    /// The pile's shape, in radii: x right, y up, the origin at the body's bottom middle
    private func shkInside(_ shape: String, _ x: Double, _ y: Double) -> Bool {
        if shape == "star" {
            let dx = x, dy = y - 0.25, d = hypot(dx, dy)
            if d < 1e-6 { return true }
            var a = atan2(dx, dy)
            a = a.truncatingRemainder(dividingBy: 2 * Double.pi); if a < 0 { a += 2 * Double.pi }
            let sec: Double = 2 * Double.pi / 5, u = a.truncatingRemainder(dividingBy: sec), v = abs(u - sec / 2) / (sec / 2)
            return d <= 0.11 + (0.27 - 0.11) * (1 - v)
        }
        if shape == "heart" {
            let u = x / 0.24, v = (y - 0.22) / 0.24, q = u * u + v * v - 1
            return q * q * q - u * u * v * v * v <= 0
        }
        let hw = 0.58
        if abs(x) > hw { return false }
        return y >= 0 && y <= 0.30 * (1 - (x / hw) * (x / hw))
    }
    private func shkTargets(_ shape: String) {
        let B: [Double] = shape == "star" ? [-0.3, 0.3, -0.05, 0.55] : (shape == "heart" ? [-0.3, 0.3, 0, 0.5] : [-0.6, 0.6, 0, 0.32])
        for k in snwGlit.indices {
            var x = 0.0, y = 0.1
            for _ in 0..<60 {
                x = B[0] + (B[1] - B[0]) * grnd(); y = B[2] + (B[3] - B[2]) * grnd()
                if shkInside(shape, x, y) { break }
            }
            snwGlit[k].tx = x; snwGlit[k].ty = y
        }
    }
    private func shkBuild() {
        let n = max(0, Int(params.glitN.rounded()))
        snwGlit = []
        for i in 0..<n {
            snwGlit.append(Glit(tx: 0, ty: 0, sx: 0, sy: 0, h: 0, s: 0.7 + 0.4 * grnd(), r: 0.9 + 1.3 * grnd(),
                                c: i % 4 == 0 ? 1 : (i % 7 == 0 ? 2 : (i % 11 == 0 ? 3 : 0)), ph: grnd() * 6.283, sw: 0.5 + grnd()))
        }
        shkTargets(snwShape)
    }
    private func shkReset() {
        snwCloud = 0; snwK = 0; snwCleared = true; snwWasCloudy = false; snwGlow = 0; snwShape = "mound"; snwKick = nil
        shkBuild()
    }
    private func shkMeasure() {
        var sum = 0.0
        for q in snwGlit { sum += q.h }
        snwCloud = snwGlit.isEmpty ? 0 : min(1, sum / Double(snwGlit.count) / 0.7)
    }
    /// Stir: `a` is how much this stirs up (one shake 1/shakeN, holding stirRate a second). Shaken up from clear, the pile's shape is picked again
    private func shkStir(_ a: Double) {
        guard params.shake >= 0.5, a > 0, !snwGlit.isEmpty else { return }
        if snwCloud < 0.15 && a >= 0.1 {
            let r = Double.random(in: 0..<1, using: &rng)
            snwShape = r < 0.09 ? "heart" : (r < 0.21 ? "star" : "mound")
            shkTargets(snwShape)
        }
        let pr = min(1, a * 1.6)
        for k in snwGlit.indices where Double.random(in: 0..<1, using: &rng) < pr {
            snwGlit[k].h = max(snwGlit[k].h, 0.5 + 0.5 * Double.random(in: 0..<1, using: &rng))
            let rr = sqrt(Double.random(in: 0..<1, using: &rng)) * 0.8, th = Double.random(in: 0..<6.283, using: &rng)
            snwGlit[k].sx = cos(th) * rr; snwGlit[k].sy = sin(th) * rr
        }
        snwCleared = false
        shkMeasure()
        if snwCloud > 0.5 { snwWasCloudy = true }
    }
    /// One shake of the phone; dx, dy is the screen direction the contents are flung relative to the phone.
    func shake(dx: Double, dy: Double) {
        decoKick = t; decoDir = dx < 0 ? -1 : 1   // v2.37 the wind bell
        hangKick(decoDir)   // v2.64 擺飾變真 (web shkShake: hangKick(DECO.dir))
        if fx.pearls > 0 { fxPearlSink = 1 }   // v2.57 珍奶: the pearls sink to the bottom
        guard params.shake >= 0.5 else { return }
        let n = max(1, params.shakeN)
        snwLast = t
        shkStir(1 / n)
        if slpOn { wake(true) }
        happyT = t
        if t - snwLastVoice > 1.5 { snwLastVoice = t; voice("happy", 0.5) }
        // it bounces in the bowl: every particle gets a speed (Verlet: the previous position moves). Capped at 2.6R/s sideways, 0.7R/s up; the bowl's wall holds it
        if sillOn, sillG != nil, !sillGrab, !introOn, params.shakeKick > 0 {
            let k = min(2, params.shakeKick)
            var ux = dx, uy = dy
            let l = hypot(ux, uy)
            if l < 1e-3 { ux = Double.random(in: 0..<1, using: &rng) < 0.5 ? -1 : 1; uy = -0.6 } else { ux /= l; uy /= l }
            snwKick = (vx: max(-1, min(1, ux)) * R * 2.6 * k, vy: max(-1, min(0.2, uy)) * R * 0.7 * k, until: t + 0.15)
        }
    }
    /// The panel's 立刻沉澱
    func shakeSettleNow() {
        for k in snwGlit.indices { snwGlit[k].h = 0 }
        shkMeasure()
    }
    private func shkStep(_ dt: Double) {
        if snwLast - t > 1 { snwLast = -9 }; if snwLastVoice - t > 1 { snwLastVoice = -9 }; if snwClearT - t > 1 { snwClearT = -9 }   // the clock went back: timers stuck in the future reset
        if let K = snwKick {
            if t >= K.until || K.until - t > 1 { snwKick = nil }
            else if sillOn && !sillGrab && !sillAir {   // the bounce: for 0.15 s the speed is mixed toward the target, not added (three shakes in a row do not fling it out of the bowl)
                let hs = lastSdt, kx = K.vx * hs, ky = K.vy * hs
                for i in 0..<N where !GRAB[i] {
                    let vx = X[i] - PX[i], vy = Y[i] - PY[i]
                    PX[i] = X[i] - (vx + (kx - vx) * 0.35); PY[i] = Y[i] - (vy + (ky - vy) * 0.35)
                }
            }
        }
        guard params.shake >= 0.5 else { snwK *= exp(-dt / 0.3); return }
        if snwGlit.count != max(0, Int(params.glitN.rounded())) { shkBuild() }
        var touching = false
        for f in fingers.values where f.mode == .grab || (f.mode == .stroke && f.on) { touching = true }
        if touching { shkStir(params.stirRate * dt) }
        let calm = fingers.isEmpty && t - snwLast > 0.6
        if calm {   // each bit sinks at its own pace; measured: settleT 30, shaken full, about 30 s to clear
            let T = max(1, params.settleT)
            for k in snwGlit.indices where snwGlit[k].h > 0 { snwGlit[k].h = max(0, snwGlit[k].h - dt * 0.85 / (T * snwGlit[k].s)) }
        }
        for k in snwGlit.indices { snwGlit[k].ph += dt * snwGlit[k].sw }
        shkMeasure()
        let kt: Double = snwCloud > 0.03 && calm && !slpOn ? 1 : 0
        snwK += (kt - snwK) * (1 - exp(-dt / (kt > 0 ? 1.2 : 0.25)))
        if !snwCleared && snwCloud < 0.03 && calm {
            snwCleared = true
            if snwWasCloudy {   // the clear moment: glow, eyes open wide, ding
                snwWasCloudy = false; snwGlow = 1; snwClearT = t; eyePulse = t; eyeBlinkT = t - 0.1
                if slpOn { wake(false) }
                onEvent?(.ding(gain: 0.5))
            }
        }
        snwGlow *= exp(-dt / 2.2)
    }
    /// v2.31: how clouded and how aglow it is, for the jelly skin's colour (0 when the shake is off)
    /// v2.49 the small bubbles inside it: a few interior particles picked by index alone (no random draw), each bobbing slowly. Screen-space is the view's job. Web `drawBubbles`.
    private var bubN = 0, bubNb = 0, bubList: [(i: Int, r: Double, ph: Double)] = []
    var bubbleView: [(x: Double, y: Double, r: Double)] {
        let nb = Int(params.bubbles.rounded())
        guard params.water > 0, params.wet >= 0.5, nb > 0, N > 0, BIDX.count == N, TID.count == N else { return [] }
        if bubN != N || bubNb != nb {
            bubN = N; bubNb = nb; bubList = []
            var cand: [Int] = []
            for i in 0..<N where BIDX[i] < 0 && TID[i] < 0 && hypot(Q0X[i], Q0Y[i]) < R * 0.72 { cand.append(i) }
            var k = 0
            while k < nb && !cand.isEmpty {
                let j = (k * 2654435761 + 97) % cand.count
                let pick = cand.remove(at: j)
                bubList.append((i: pick, r: 0.022 + 0.03 * Double((k * 37) % 11) / 10, ph: Double(k) * 1.9))
                k += 1
            }
        }
        var out: [(x: Double, y: Double, r: Double)] = []
        for b in bubList where b.i < N {
            let bx: Double = X[b.i] + sin(t * 0.5 + b.ph) * R * 0.012, by: Double = Y[b.i] + sin(t * 0.8 + b.ph * 1.7) * R * 0.02
            out.append((x: bx, y: by, r: R * b.r))
        }
        return out
    }
    /// v2.49: it is resting on the sill or in the bowl (something under it for the gathered light to fall on)
    var restsOnSill: Bool { sillOn && sillC > 0 }

    var haze: (cloud: Double, glow: Double) { params.shake >= 0.5 && params.glit >= 0.5 ? (snwCloud, snwGlow) : (0, 0) }   // v2.47 glit 0: no glitter, so no haze either
    /// What the view draws inside the body: the haze, every bit between its place in the pile (clear) and where it hangs (cloudy), the glow. World points.
    var glitterView: GlitterView? {
        guard params.shake >= 0.5, params.glit >= 0.5, !snwGlit.isEmpty, !clusters.isEmpty else { return nil }
        let c = clusters[gi]
        var by = -1e9
        for i in bnd { by = max(by, Y[i]) }
        by -= R * 0.06
        if sillOn && sillInBowl, let g = sillG { by = min(by, g.lip - R * 0.04) }   // sitting in the bowl the pile is on the rim line, where it shows
        var dots: [(x: Double, y: Double, r: Double, c: Int, a: Double)] = []
        dots.reserveCapacity(snwGlit.count)
        for q in snwGlit {
            let h = q.h, tx = c.xc + q.tx * R, ty = by - q.ty * R
            let sx = c.xc + (q.sx + 0.08 * sin(q.ph)) * R, sy = c.yc + (q.sy + 0.05 * cos(q.ph * 1.3)) * R
            let tw = 0.6 + 0.4 * sin(q.ph * 2.1 + t * 2.5), a = (h < 0.03 ? 0.85 : 0.45 + 0.4 * h) * tw
            dots.append((tx + (sx - tx) * h, ty + (sy - ty) * h, q.r * (h < 0.03 ? 1.15 : 1), q.c, a))
        }
        return GlitterView(cloud: snwCloud, glow: snwGlow, cx: c.xc, cy: c.yc, dots: dots)
    }

    // MARK: - 走路 (v2.31 批次 4): it brings something back

    private func walkLoadOnce() {
        guard !walkLoaded else { return }
        walkLoaded = true
        guard !labNoSave else { return }
        guard let d = UserDefaults.standard.data(forKey: "nienie.walk"), let o = try? JSONDecoder().decode(WalkSave.self, from: d) else { return }
        walkItems = o.items.filter { walkKinds.contains($0.k) }
        walkBank = o.bank; walkDay = o.day; walkDayN = o.dayN; walkOpens = o.opens; walkPerm = o.perm
    }
    private func walkSave() {
        guard !labNoSave else { return }
        let o = WalkSave(items: walkItems, bank: walkBank, day: walkDay, dayN: walkDayN, opens: walkOpens, perm: walkPerm)
        if let d = try? JSONEncoder().encode(o) { UserDefaults.standard.set(d, forKey: "nienie.walk") }
    }
    /// v2.31: six places on the sill, three left of the bowl and three right (the frame's bottom has only 53 pt with the bowl in the middle)
    private func walkSlotX(_ sl: Int) -> Double {
        guard let g = sillG else { return 0 }
        let left = sl < 3
        let x0 = left ? g.l + 18 : g.bx + g.bw / 2 + 16, x1 = left ? g.bx - g.bw / 2 - 16 : g.r - 18, k = Double(left ? sl : sl - 3)
        return x0 + (x1 - x0) * k / 2
    }
    private func walkY(_ big: Bool) -> Double { (sillG?.fl ?? 0) - (big ? 15 : 11) }   // the thing's centre, its bottom on the sill
    private func walkFreeSlot() -> Int {
        let used = Set(walkItems.map(\.s) + walkFall.map(\.s))
        for sl in [0, 5, 1, 4, 2, 3] where !used.contains(sl) { return sl }
        return -1
    }
    /// Where it sticks: the upper right of the outline (the eyes are in the middle, up there it shows)
    private func walkPick() -> Int {
        guard !clusters.isEmpty else { return 0 }
        let c = clusters[gi]
        var best = bnd.first ?? 0, bv = -1e9
        for i in bnd { let v = (X[i] - c.xc) * 0.55 - (Y[i] - c.yc) * 0.85; if v > bv { bv = v; best = i } }
        return best
    }
    private func walkTier(_ n: Int) -> Int { n >= walkBig ? 2 : (n >= walkSmall ? 1 : 0) }
    private static func dayKey(_ date: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return "\(c.year ?? 0)-\(c.month ?? 0)-\(c.day ?? 0)"
    }
    // MARK: - v2.32 興奮: how lively today, from what it brought back (0-1 things 0, 2 half, 3 full); the panel can pretend. Only ever adds on top of the ordinary it
    private var walkHopN = 0, walkHopAt = 0.0, exAt = -9.0, exN = 0
    private func exLevel() -> Double {
        var n: Int
        if params.excite >= 0 { n = Int(params.excite.rounded()) }
        else { if t - exAt > 1 || exAt > t { exAt = t; walkToday(); exN = walkDayN }; n = exN }   // the date checked once a second
        return n >= 3 ? 1 : n >= 2 ? 0.5 : 0
    }
    private func walkToday() { let d = Self.dayKey(Date()); if walkDay != d { walkDay = d; walkDayN = 0 } }
    /// Walked enough: one trip out and back. However far you walked it is one thing, three a day at most, so walking never becomes a chore.
    @discardableResult
    private func walkCheck() -> Bool {
        guard params.walkShow >= 0.5 else { return false }   // v2.58 (QC-0007 #47): off, it does not go out; the steps stay banked
        guard sillOn, sillG != nil else { walkPending = sillOn; return false }   // the sill is not built yet: again on the first frame
        guard !sillGrab, walkStuck == nil else { return false }
        walkToday()
        let tier = walkTier(walkBank)
        if tier == 0 || walkDayN >= walkDayMax { return false }
        walkBank = 0; walkDayN += 1
        walkTrip(big: tier == 2)
        walkSave()
        return true
    }
    /// It is put outside on the ledge (Reduce Motion: on the frame's bottom), something stuck to it, and walks the way home.
    private func walkTrip(big: Bool) {
        guard let g = sillG, !clusters.isEmpty else { return }
        if sillRoute != nil { routeEnd(abort: true) }
        walkHopN = 0; clingEnd(); sillStickT = -1   // v2.36
        sillHop = nil; gaitOn = false; wanderMoving = false; slpLastAny = t; escOn = false   // v2.31: a leftover flight would cancel the first step of the way home and it would stay outside
        var y1 = -1e9, mx = 0.0
        for i in bnd { y1 = max(y1, Y[i]) }
        for i in 0..<N { mx += X[i] }
        mx /= Double(N)
        let rm = reduceMotion
        func sxw(_ q: Double) -> Double { W / 2 + (q - W / 2) / 0.8 }
        let tx: Double = rm ? max(g.gx + R * 0.9, min(g.jr - R * 0.9, g.jr - R * 1.3)) : max(sxw(g.bx + g.bw * 0.5 + R * 0.1), min(sxw(g.jr + R * 0.15), sxw(g.jr - R * 1.2)))
        let ty = rm ? g.bt : g.oy, dx = tx - mx, dy = ty - y1
        for i in 0..<N { X[i] += dx; PX[i] = X[i]; Y[i] += dy; PY[i] = Y[i] }
        cx += dx; homeX = tx; homeY += dy; clusters[gi].xc += dx; clusters[gi].yc += dy; sillPX = 0; sillPY = 0   // the centroid moves too: the route looks at it on its first step
        sillInBowl = false; sillWant = false; sillAir = false; sillC = 1; sillLift = false; sillTanV = false
        sillGTX = 0; sillGTY = 1; sillGVX = 0; sillGVY = 1; sillSurf = rm ? "bar" : "ledge"
        walkStuck = WalkStuck(k: walkKinds.randomElement(using: &rng) ?? "stone", big: big, i: walkPick(), a: Double.random(in: -0.4..<0.4, using: &rng), idle: 0)
        if rm { sillPlane = .frame; sillZoom = 1; sillZTG = 1; lifeSt = .rest; lifeUntil = t + 3 }
        else { sillPlane = .out; sillZoom = 0.8; sillZTG = 0.8; sillZPX = W / 2; sillZPY = g.oy; sillOutT = t; routeStart(rtComeBack() + rtBackIn() + [.walkHops]) }
    }
    /// Knocked off: it flies to a free place on the sill, bounces once. Full: the oldest is pushed off (only when you walked).
    private func walkDrop() {
        guard let q = walkStuck, sillG != nil else { return }
        walkStuck = nil
        var sl = walkFreeSlot()
        if sl < 0 {
            let idx = walkItems.firstIndex(where: { !$0.gift }) ?? 0
            let o = walkItems.remove(at: idx)
            if params.walkShow >= 0.5 { walkLeave.append(WalkLeave(k: o.k, big: o.big, x: walkSlotX(o.s), y: walkY(o.big), a: o.a, al: 1)) }
            sl = o.s
        }
        let i = q.i < N ? q.i : 0, x0 = X[i], y0 = Y[i], sx = walkSlotX(sl), ty = walkY(q.big), G = R * sillGrav * 0.6
        let h = max(R * 0.35, y0 - ty + R * 0.35), vy = -sqrt(2 * G * h)
        let T = (-vy + sqrt(max(0, vy * vy + 2 * G * (ty - y0)))) / G
        let va = (Double.random(in: 0..<1, using: &rng) < 0.5 ? -1.0 : 1.0) * (3 + 3 * Double.random(in: 0..<1, using: &rng))
        walkFall.append(WalkFall(k: q.k, big: q.big, s: sl, x: x0, y: y0, vx: (sx - x0) / max(0.05, T), vy: vy, a: q.a, va: va, ty: ty, G: G, b: 0, na: Double.random(in: -0.25..<0.25, using: &rng)))
        onEvent?(.land(gain: 0.22))
    }
    private func walkLand(_ f: WalkFall) {
        if params.walkShow < 0.5 { walkLeave.append(WalkLeave(k: f.k, big: f.big, x: walkSlotX(f.s), y: walkY(f.big), a: f.na, al: 1)) }   // v2.58: not kept on the sill, it fades
        walkItems.append(WalkItem(k: f.k, big: f.big, s: f.s, a: f.na, gift: false)); walkSave()
    }
    private func walkStep(_ dt: Double) {
        // v2.32 興奮: home, nobody touching, one or two little hops
        if walkHopN > 0 && sillRoute == nil && !sillAir && (sillInBowl || (noBowl && sillPlane == .room)) && !introOn && fingers.isEmpty && t >= walkHopAt { walkHopN -= 1; walkHopAt = t + 0.9; hop() }
        if var q = walkStuck {   // a finger on it knocks the thing off at once (whoever opens may be anxious, no waiting for the show); left alone it falls off by itself
            var touched = false
            for f in fingers.values where (f.mode == .grab || f.mode == .stroke) && t - f.tDown > 0.1 { touched = true }
            if fingers.isEmpty && sillRoute == nil && sillPlane != .out { q.idle += dt; walkStuck = q }
            if touched || q.idle > walkIdle { walkDrop() }
        }
        var k = walkFall.count - 1
        while k >= 0 {
            var f = walkFall[k]
            f.vy += f.G * dt; f.x += f.vx * dt; f.y += f.vy * dt; f.a += f.va * dt
            if f.y >= f.ty && f.vy > 0 {
                f.y = f.ty
                if f.b < 1 && f.vy > R * 1.5 { f.vy *= -0.28; f.vx = 0; f.x = walkSlotX(f.s); f.va *= -0.4; f.b += 1; walkFall[k] = f; onEvent?(.land(gain: 0.14)) }
                else { walkFall.remove(at: k); walkLand(f) }
            } else { walkFall[k] = f }
            k -= 1
        }
        k = walkLeave.count - 1
        while k >= 0 {
            walkLeave[k].al -= dt / 0.5; walkLeave[k].y -= R * 0.25 * dt
            if walkLeave[k].al <= 0 { walkLeave.remove(at: k) }
            k -= 1
        }
    }
    /// A rebuild (another slime, reset) with something still stuck or falling: straight onto the sill, nothing is lost.
    private func walkSettle() {
        walkLoadOnce()
        for f in walkFall { walkItems.append(WalkItem(k: f.k, big: f.big, s: f.s, a: f.na, gift: false)) }
        if !walkFall.isEmpty { walkFall = []; walkSave() }
        guard let q = walkStuck else { return }
        walkStuck = nil
        var sl = walkFreeSlot()
        if sl < 0 { sl = walkItems.isEmpty ? 0 : walkItems.removeFirst().s }
        walkItems.append(WalkItem(k: q.k, big: q.big, s: sl, a: q.a, gift: false))
        walkSave()
    }
    /// App opened: the second time a gift stone lies on the sill. Only a tap on it asks whether it may know how far you walked.
    func walkOpen() {
        walkLoadOnce()
        walkOpens += 1
        if params.walkShow >= 0.5 && walkOpens >= 2 && walkPerm.isEmpty && !walkItems.contains(where: { $0.gift }) {
            let fs = walkFreeSlot()
            walkItems.append(WalkItem(k: "stone", big: false, s: fs < 0 ? 2 : fs, a: 0.1, gift: true))
        }
        walkSave()
    }
    private func walkGiftAt(_ sx: Double, _ sy: Double) -> Bool {
        guard params.walkShow >= 0.5, sillG != nil, let q = walkItems.first(where: { $0.gift }) else { return false }
        return hypot(sx - walkSlotX(q.s), sy - walkY(q.big)) < 26
    }
    /// 先不要 keeps the stone and never asks again; 好 and the controller starts reading steps.
    func walkAnswer(_ yes: Bool) {
        walkLoadOnce()
        walkPerm = yes ? "ok" : "no"
        for k in walkItems.indices { walkItems[k].gift = false }
        walkSave()
    }
    /// Steps walked since the last read (CMPedometer through the controller; the panel fakes them): banked, and a trip if it is enough.
    func walkBankSteps(_ n: Int) { walkLoadOnce(); walkBank += n; walkCheck(); walkSave() }
    func walkClear() {
        walkLoadOnce()
        walkItems = []; walkFall = []; walkLeave = []; walkStuck = nil; walkBank = 0; walkDayN = 0; walkDay = ""; walkOpens = 0; walkPerm = ""; walkPending = false
        walkSave()
    }
    /// The things on the sill and the ones fading away (screen points)
    var walkBackSprites: [WalkSprite] {
        guard sillG != nil else { return [] }
        return (params.walkShow >= 0.5 ? walkItems : []).map { WalkSprite(kind: $0.k, big: $0.big, x: walkSlotX($0.s), y: walkY($0.big), a: $0.a, alpha: 1) }
            + walkLeave.map { WalkSprite(kind: $0.k, big: $0.big, x: $0.x, y: $0.y, a: $0.a, alpha: max(0, $0.al)) }
    }
    /// The one stuck to it (a little inside the outline, turning with the body) and the ones falling (world points)
    var walkWorldSprites: [WalkSprite] {
        var out: [WalkSprite] = []
        if let q = walkStuck, q.i < N, sillG != nil, !clusters.isEmpty {
            let c = clusters[gi], i = q.i, dx = c.xc - X[i], dy = c.yc - Y[i], d = max(1e-9, hypot(dx, dy)), ins: Double = q.big ? 11 : 8
            out.append(WalkSprite(kind: q.k, big: q.big, x: X[i] + dx / d * ins, y: Y[i] + dy / d * ins, a: q.a + atan2(c.sn, c.cs), alpha: 1))
        }
        for f in walkFall { out.append(WalkSprite(kind: f.k, big: f.big, x: f.x, y: f.y, a: f.a, alpha: 1)) }
        return out
    }

    // MARK: - v2.19 活物感: rest / look / go / arrive (A1, A2), the pulse gait (A3), flinch and shake-off (A5), sniffing (A7)

    private func smooth01(_ x: Double) -> Double { x <= 0 ? 0 : (x >= 1 ? 1 : x * x * (3 - 2 * x)) }
    private func sniffEnv(_ s: Sniff) -> Double {
        let u = t - s.t0
        var e: Double = u < s.T1 ? smooth01(u / s.T1) : (u < s.T1 + s.T2 ? 1 : smooth01(1 - (u - s.T1 - s.T2) / s.T3))
        if s.cut > 0 { e = min(e, s.eCut * max(0, 1 - (t - s.cut) / 0.15)) }
        return max(0, e)
    }
    /// Touched or flinching: the pseudopods out sniffing are drawn in within 0.15 s.
    private func cutSniffs() {
        for k in sniffs.indices where !(sniffs[k].cut > 0) { sniffs[k].eCut = sniffEnv(sniffs[k]); sniffs[k].cut = t }
    }
    @discardableResult
    private func startSniff(_ a: Double, _ len: Double, _ T1: Double, _ T2: Double, _ T3: Double) -> Sniff {
        cutSniffs()
        sniffSeq += 1
        let s = Sniff(a: a, L: len, t0: t, T1: T1, T2: T2, T3: T3, ph: Double.random(in: 0..<6.283, using: &rng), id: sniffSeq)
        sniffs.append(s)
        return s
    }
    /// Rest length: mostly 3...5 s, now and then a long stare; comfortable longer, tense shorter (lifeRest off: v2.18's 0.8...3 s).
    private func restDur() -> Double {
        if !lv(params.lifeRest) { return 0.8 + Double.random(in: 0..<2.2, using: &rng) }
        var d = 2.5 + Double.random(in: 0..<3.5, using: &rng)
        if Double.random(in: 0..<1, using: &rng) < 0.2 { d += 5 + Double.random(in: 0..<6, using: &rng) }
        return d * params.restMul * (1 - 0.5 * exLevel()) * (1 + 0.5 * max(0, moodC)) * (1 - 0.5 * max(moodA, moodScare)) * (iv2(params.impC5) ? 1 - 0.4 * impWary : 1)   // v2.20 C5: wary rests less
    }
    /// v2.63 C5 (web pickDir, lookNoDown): on the sill a sniff pointing down (screen y grows down, sin > 0) is mirrored over the horizon;
    /// no extra draws from rng, so lookNoDown 0 is as before. MARK v2.63 C5
    /// v2.64 C5 lookTarget：先照舊抽（rng 抽的次數不變），有對象時換成朝對象；lookNoDown 照樣套在後面
    private func pickDir() -> Double {
        var a = pickDir0()
        if params.lookTarget >= 0.5 { a = ltPick(a) } else { ltCur = nil }
        return params.lookNoDown >= 0.5 && sillOn && sin(a) > 0 ? -a : a
    }

    // MARK: v2.64 C5 張望有對象（lookTarget；規劃 .uiux/04-手感/極致優化規劃-暫定.md 的 C5，BATCH3 第 3 項；網頁 LT、LTK、ltRnd、ltHab、ltWin、ltCands、ltPick、ltArm、ltTap、ltReact）
    // 原本張望的方向只是亂抽（v2.63 起不朝下）。現在每次要探之前看看旁邊有沒有東西可看（ltCands）：
    //   touch 你碰過的地方：最後一次摸牠、放手的位置（impLX、impLY），3 分鐘內，離牠 0.9R 以上才算；記性開著時，牠最喜歡那一格也算
    //   win   窗景裡正在動的東西（winMover，畫面那邊算：這一刻在窗洞裡、每秒移動 0.08R 以上，挑最快那層；減少動態時不算）
    //   bell  掛著的風鈴、晴天娃娃，在晃的時候
    //   prop  窗台上的擺飾（蠟燭、書堆、玻璃罐），左右 3R 以內
    // 份量：碰過的地方 1 到 0.3、喜歡那格 0.6、窗景 0.8、風鈴 1.2、擺飾 0.4；同一個對象剛看過，90 秒內份量從 0 慢慢回來。份量加起來乘 0.75 是這次「有對象」的機率。
    // 看完一個小反應（ltReact，排在偽足伸到底、停了六成的時候；被碰、走開、偽足被收掉就不做）：碰過的地方朝那邊靠一下（被嚇過、戒高往反方向縮），
    // 會動的東西和風鈴眨一下眼、偽足再點一下，擺飾偽足再點一下。亂數用自己那串（ltRnd），rng 一個都不多抽。lookTarget 0：ltPick、ltReact 都不會跑，跟 v2.63 一樣。
    private enum LTK {
        static let p = 0.75, hab = 90.0, near = 3.0, touchT = 180.0, winV = 0.08, tap = 0.3
    }
    /// 網頁 ltRnd：(seed·1664525 + 1013904223) mod 2³²，跟大腦的 brnd 同一種
    private func ltRnd() -> Double {
        ltS = ltS &* 1_664_525 &+ 1_013_904_223
        return Double(ltS) / 4_294_967_296
    }
    /// 剛看過的對象份量從 0 慢慢回來；時鐘倒回去（重建）時留在未來的不算
    private func ltHab(_ k: String) -> Double {
        guard let v = ltHabT[k], v <= t else { return 1 }
        return min(1, (t - v) / LTK.hab)
    }
    private typealias LookCand = (k: String, key: String, x: Double, y: Double, w: Double)
    private func ltCands() -> [LookCand] {
        var o: [LookCand] = []
        guard clusters.indices.contains(gi) else { return o }
        let cx = clusters[gi].xc, cy = clusters[gi].yc
        func add(_ k: String, _ key: String, _ x: Double, _ y: Double, _ w0: Double) {
            if hypot(x - cx, y - cy) < R * 0.9 { return }
            let w = w0 * ltHab(key)
            if w > 0.01 { o.append((k: k, key: key, x: x, y: y, w: w)) }
        }
        if impHas && lastTouch <= t && t - lastTouch < LTK.touchT { add("touch", "touch", impLX, impLY, 1 - 0.7 * (t - lastTouch) / LTK.touchT) }
        guard sillOn, let g = sillG, sillPlane == .room, !sillInBowl else { return o }
        if mmOn { let k = mem.fav(); if k >= 0 { add("touch", "fav", memCellX(g, k), cy, 0.6) } }
        if !reduceMotion, let m = winMover?(g.gx, g.gy, g.gw, g.gh, R * LTK.winV), m.x.isFinite, m.y.isFinite { add("win", "win\(m.i)", m.x, m.y, 0.8) }
        if dreal {
            for q in hangs where q.on && q.held == nil && (abs(q.va) > 0.5 || abs(q.a) > 0.08) { add("bell", q.name, q.x - sin(q.a) * q.h * 0.7, q.y + q.h * 0.7, 1.2) }
        }
        for p in props where !p.gone && p.fade == 0 && p.alpha >= 0.6 && p.held == nil && abs(p.x - cx) < R * LTK.near { add("prop", "p:" + p.im, p.x, min(p.y, g.fl), 0.4) }   // 手機的 props 只有擺飾（網頁的 p.deco 一定成立）
        return o
    }
    /// 網頁 ltPick：有對象就朝對象（加 ±0.1 弧度），沒有就用原本抽的 a
    private func ltPick(_ a: Double) -> Double {
        ltCur = nil
        let c = ltCands()
        guard !c.isEmpty, clusters.indices.contains(gi) else { return a }
        var w = 0.0
        for q in c { w += q.w }
        if ltRnd() >= LTK.p * min(1, w) { return a }
        var r = ltRnd() * w
        var q = c[c.count - 1]
        for x in c { r -= x.w; if r <= 0 { q = x; break } }
        ltHabT[q.key] = t
        let ta = atan2(q.y - clusters[gi].yc, q.x - clusters[gi].xc)
        ltCur = LookTgt(k: q.k, key: q.key, x: q.x, y: q.y, ta: ta)
        return ta + (ltRnd() - 0.5) * 0.2
    }
    /// 網頁 ltTap：偽足再往前點一下，疊在正在探的那條上（不先收掉別的偽足）；rng 不抽
    private func ltTap(_ a: Double) {
        sniffSeq += 1
        sniffs.append(Sniff(a: a, L: LTK.tap, t0: t, T1: 0.12, T2: 0.06, T3: 0.25, ph: 0, id: sniffSeq))
    }
    /// 網頁 ltReact：看完的小反應；晚了 0.3 秒以上、不在張望、手指在上面、睡著、在逃、那條偽足被收掉或已經不在，就不做
    private func ltReact() {
        guard let r = ltReactQ else { return }
        ltReactQ = nil
        guard t - r.at <= 0.3, lifeSt == .look, fingers.isEmpty, !slpOn, !escOn,
              let s = sniffs.first(where: { $0.id == r.sid }), !(s.cut > 0) else { return }
        if r.tg.k == "touch" {
            let k = memCellAt(r.tg.x)
            let bad = impWary > 0.4 || (mmOn && sillPlane == .room && mem.cell.indices.contains(k) && mem.cell[k] < -0.3)
            if iv3(params.e2) { leanT = t; leanA = r.a; leanS = bad ? -1 : 1 } else { ltTap(r.a) }
        } else {
            ltTap(r.a)
            if r.tg.k != "prop" { eyeBlinkT = t; eyeNextBlink = max(eyeNextBlink, t + 1.2) }
        }
    }
    private func pickDir0() -> Double {
        if hypot(homeX - cx, homeY - cy) > W * 2.5 { return atan2(cy - homeY, cx - homeX) + Double.random(in: -0.6..<0.6, using: &rng) }   // too far out: sniff back
        if iv2(params.impC5) && impHas {   // v2.20: trusting sniffs toward where you last touched it (and mostly goes), wary the other way
            let dx = impLX - homeX, dy = impLY - homeY, d = hypot(dx, dy), ta = atan2(dy, dx), r = Double.random(in: 0..<1, using: &rng)
            if d > R * 1.5 && r < 0.6 * impTrust { return ta + Double.random(in: -0.3..<0.3, using: &rng) }
            if d < R * 3 && r < 0.6 * impWary { return ta + .pi + Double.random(in: -0.4..<0.4, using: &rng) }
        }
        return Double.random(in: 0..<(2 * .pi), using: &rng)
    }
    /// Set off toward `dir` (the way it just sniffed) or, with none, anywhere (up and down at 0.8); far and fast with the `dash` chance.
    private func goStart(_ dir: Double?) {
        if sillOn { sillGo(); return }   // v2.30 窗台: it picks from what it can do there (mostly it stays)
        let far = Double.random(in: 0..<1, using: &rng) < params.dash
        let dist = W * (far ? 0.5 + 0.4 * Double.random(in: 0..<1, using: &rng) : 0.2 + 0.3 * Double.random(in: 0..<1, using: &rng))
        var a = dir ?? Double.random(in: 0..<(2 * .pi), using: &rng)
        let ys = dir == nil ? 0.8 : 1.0
        if hypot(homeX - cx, homeY - cy) > W * 3 { a = atan2(cy - homeY, cx - homeX) + Double.random(in: -0.5..<0.5, using: &rng) }
        lifeSt = .go; wanderSX = homeX; wanderSY = homeY; wanderX = homeX + cos(a) * dist; wanderY = homeY + sin(a) * dist * ys; wanderMoving = true
        if lv(params.lifeGait) {
            gaitOn = true; gaitTX = wanderX; gaitTY = wanderY; gaitDash = far; gaitClimb = false; gaitPh = -1; gaitPrep = 0; gaitV = 0
            gaitH = atan2(wanderY - homeY, wanderX - homeX); gaitK = 1; gaitStr = 1; gaitLast = false; gaitOff = 0
        } else {
            wanderT = max(0.5, dist / (params.wander * (far ? 2.5 : 1) * R * (reduceMotion ? 0.25 : 1))); wanderP = 0
        }
    }
    /// One stroke lasts P s (a dash 0.62), contracting for the first c s (the speed reaches its peak within 50 ms), then relaxing and
    /// gliding (speed decays with tau); a stroke covers sd; stretched along the heading up to kA. Reduce Motion: half the rhythm,
    /// half the stroke (speed ×0.25), half the stretch.
    private func gaitConst() -> (P: Double, c: Double, tau: Double, sd: Double, kA: Double) {
        let rm = reduceMotion
        if gaitClimb { return (1.15 * (rm ? 2 : 1), 0.32 * (rm ? 2 : 1), 0.36 * (rm ? 2 : 1), 0.34 * R * (rm ? 0.5 : 1), 0.15 * (rm ? 0.5 : 1)) }   // v2.30: climbing out of the bowl, slower and shorter strokes
        return ((gaitDash ? 0.62 : 1.1) * (rm ? 2 : 1), (gaitDash ? 0.15 : 0.25) * (rm ? 2 : 1), (gaitDash ? 0.24 : 0.35) * (rm ? 2 : 1),
                (gaitDash ? 0.8 : 0.5) * R * (rm ? 0.5 : 1) * (1 + 0.3 * exLevel()) * (1 + 0.2 * brainM), (gaitDash ? 0.17 : 0.12) * (rm ? 0.5 : 1))   // v2.63 心情: a good mood, longer strides
    }
    /// v2.50 場景聲: one per stroke. Climbing (a climb route, lifting itself, on the frame) sounds like climbing, otherwise crawling on the sill.
    private func gaitSfx() {
        if gaitClimb || (sillOn && (sillTanV || sillPlane == .frame)) { onEvent?(.fx(kind: "climb", gain: 0.5, delay: 0)) }
        else if dreal, let g = sillG, sillPlane == .room, !sillInBowl, !clusters.isEmpty, abs(clusters[gi].xc - g.bx) < 200 * g.U * 0.5 { onEvent?(.fx(kind: "cloth", gain: 0.55, delay: 0)) }   // v2.64 (web gaitSfx: on the cloth; the phone only with decoReal, so 0 is v2.63)
        else { onEvent?(.fx(kind: "crawl", gain: gaitDash ? 0.55 : 0.4, delay: 0)) }
    }
    private func strokeStart(_ K: (P: Double, c: Double, tau: Double, sd: Double, kA: Double)) {
        gaitSfx()
        if sillOn { if sillTanV { gaitTX = homeX } else { gaitTY = homeY; if sillRoute == nil { gaitTX = sillClampX(gaitTX) } } }   // v2.28 窗台: along the sill; v2.30 or straight up and down while it lifts itself
        let dx = gaitTX - homeX, dy = gaitTY - homeY, rem = hypot(dx, dy)
        gaitH = atan2(dy, dx) + Double.random(in: -0.21..<0.21, using: &rng)   // each stroke veers a little (±12°): a curved path, speed and heading change together
        let per = K.c / 2 + K.tau * (1 - exp(-(K.P - K.c) / K.tau))   // how far this speed profile goes per unit of peak speed
        if rem < K.sd * 1.4 && !sillLift { gaitLast = true; gaitStr = max(0.35, min(1, rem / K.sd)) } else { gaitStr = 1 }   // the last stroke is smaller (lifting itself the target is far away on purpose)
        gaitVP = gaitStr * K.sd / per
    }
    private func gaitStep(_ dt: Double) {
        let K = gaitConst(), rm = reduceMotion ? 0.5 : 1.0
        var off = 0.0, mv = 0.0
        if gaitPh < 0 {
            // gathering for 0.3 s before setting off: draws back a little, squashed along the heading
            gaitPrep += dt
            let p = min(1, gaitPrep / 0.3)
            off = -0.05 * R * sin(.pi * p) * rm; gaitK = 1 - 0.05 * sin(.pi * p) * rm
            if p >= 1 { gaitPh = 0; gaitK = 1; strokeStart(K) }
        } else {
            gaitPh += dt
            if gaitLast && gaitPh >= K.c + 0.15 { gaitArrive(); return }   // the last stroke stops half-way through its glide; the arrival bump carries its speed on
            if gaitPh >= K.P { gaitPh -= K.P; strokeStart(K) }
            let env: Double
            if gaitPh < K.c { gaitV += (gaitVP - gaitV) * (1 - exp(-dt / 0.05)); env = sin(.pi / 2 * gaitPh / K.c) }
            else { gaitV *= exp(-dt / K.tau); env = 0.5 * (1 + cos(.pi * (gaitPh - K.c) / (K.P - K.c))) }
            gaitK = 1 + K.kA * env * gaitStr; mv = gaitV * dt
        }
        let d = mv + (off - gaitOff); gaitOff = off
        moveHome(cos(gaitH) * d, sin(gaitH) * d, dt)
        strK = gaitK; strH = gaitH
    }
    /// Arrived: the speed carries on into a bump o(u) = A·e^(−u/0.3)·sin(2πu/0.6) that starts at the last speed (no sudden kick);
    /// the stretch eases off, it squashes forward and springs back once.
    private func gaitArrive() {
        gaitOn = false; wanderMoving = false
        lifeSt = .arrive; arrT = t; arrH = gaitH; arrK0 = gaitK; arrA = gaitV / (2 * .pi / 0.6); arrOff = 0; arrK = (gaitDash ? 0.12 : 0.08) * (reduceMotion ? 0.5 : 1)
        gaitK = 1
        if gaitDash && lv(params.lifeBreath) { exert = max(exert, 0.6) }   // out of breath after a dash
    }
    /// The whole body moves together with its previous positions (a performance, no velocity left behind): it goes forward stroke by
    /// stroke instead of being dragged along by the home spring.
    private func moveHome(_ dx: Double, _ dy: Double, _ dt: Double) {
        let dx = sillOn && sillTanV ? 0 : dx, dy = sillOn && !sillTanV ? 0 : dy   // v2.28 窗台: home moves along the sill only; v2.30 straight up or down while climbing
        if dx == 0 && dy == 0 { return }
        homeX += dx; homeY += dy; wanderVX = dx / dt; wanderVY = dy / dt
        for i in 0..<N where !GRAB[i] { X[i] += dx; Y[i] += dy; PX[i] += dx; PY[i] += dy }
    }
    /// Let go: a hard pull is shaken off (A5), a long one leaves it panting (A6), and 0.5 s later it sniffs toward where your finger
    /// left (A7; not while fleeing or on the happy hop).
    private func lifeRelease(_ f: Finger) {
        let st = bodyStretch(f)   // v2.20: dragged along a long way is not a hard pull
        if lv(params.lifeFlinch) && st > 1 { shkAt = t + 0.3; shkAmp = min(1, 0.4 + (st - 1) / 1.5) }
        if lv(params.lifeBreath) && st > 1.5 { exert = max(exert, min(1, 0.3 + (st - 1.5) * 0.35)) }
        if slpOn { lifeSt = .sleep; return }   // v2.61 C1: it only turned over
        if lv(params.lifeAttend) && !escOn && !introOn && !clusters.isEmpty && hypot(f.fx - clusters[gi].xc, f.fy - clusters[gi].yc) > R * 0.4 {
            attOn = true; attAt = t + 0.5; attX = f.fx; attY = f.fy
        }
        lifeSt = .rest; lifeUntil = t + 1.5 + Double.random(in: 0..<2, using: &rng)
    }
    private func lifeStep(_ dt: Double, _ idle: Double, _ engaged: Bool) {
        swimGreet()   // v2.23: swum home, say hello
        // A5 flinch when its time comes (resting before the touch ×1.2, walking ×0.8; comfortable half; each flinch ×0.55, back with 7 s)
        flH += (1 - flH) * (1 - exp(-dt / 7))
        if params.tapSoft >= 0.5 { flTc = min(1, flTc * exp(dt / TapSet.T)) } else { flTc = 1; flTapQ = false }   // v2.61 D2
        if let s = flSay, t >= s.at || flAt != s.at { flSay = nil; onEvent?(.voice(kind: s.kind, gain: s.gain, rate: s.rate)) }   // v2.63 B5 (web: the same line): the startle on the flinch's frame; the flinch cancelled or moved, at once
        if flAt > 0 && t >= flAt {
            let byTouch: Bool = flAt == flTapAt, byTap: Bool = params.tapSoft >= 0.5 && byTouch   // byTouch: v2.63 D4
            flAt = -9
            if lv(params.lifeFlinch) {
                let pre: Double = (flPre == .rest ? 1.2 : (flPre == .go ? 0.8 : 1)) * flBoost
                var a = params.flinchAmp * pre * (moodC > 0.3 ? 0.5 : 1) * flH * (reduceMotion ? 0.5 : 1) * (iv2(params.impC5) ? 1 + 1.2 * impWary : 1)   // v2.20 C5
                a *= brainFlinch()   // v2.63 心情 (web: …*brainFlinch() on the same line)
                if byTap {   // v2.61 D2: the more light taps, the smaller
                    a = min(a, flTc)
                    if flTapQ { tapCap(a) }
                }
                flTapQ = false
                if byTouch && flBk > 0 {   // v2.63 D6 (bond; web: the same line): a high bond's first touch, the flinch × (1 − k), and it leans to your finger
                    a *= 1 - flBk
                    if iv3(params.e2) && clusters.indices.contains(gi) { leanT = t; leanA = atan2(flBY - clusters[gi].yc, flBX - clusters[gi].xc); leanS = 1 }
                }
                flBk = 0
                flAmp = a; flT0 = t; flH *= 0.55; flBoost = 1; cutSniffs()
                if lv(params.lifeBreath) { exert = max(exert, 0.1 + 2 * a) }   // a quick breath in with it
                if byTouch && params.flinchFx >= 0.5 && a >= FlxSet.lo * params.flinchAmp {   // v2.63 D4 (web: the same line): a small sound and a light tap on this frame; a pop just sounded, the tap only
                    let k: Double = min(1, a / max(1e-6, params.flinchAmp))
                    let quiet: Bool = t >= flxRelT && t - flxRelT < FlxSet.win
                    if !quiet { flxSndT = t }
                    onEvent?(.flinch(gain: quiet ? 0 : FlxSet.gain * k, hap: FlxSet.hap * k))
                }
            }
        }
        do {   // 60 ms in, held 50 ms, eased off over half a second
            let u = t - flT0
            let e: Double = u < 0 ? 0 : (u < 0.06 ? sin(.pi / 2 * u / 0.06) : (u < 0.11 ? 1 : exp(-(u - 0.11) / 0.18)))
            flS = 1 - flAmp * e
        }
        // shaking off: a few fast turns left and right (6 a second, shrinking with 0.16 s), positions turned with their previous ones
        if shkAt > 0 && t >= shkAt { shkAt = -9; shkT0 = t }
        do {
            let u = t - shkT0
            let th: Double = u >= 0 && u < 0.6 ? shkAmp * 0.13 * sin(2 * .pi * 6 * u) * exp(-u / 0.16) * (reduceMotion ? 0.5 : 1) : 0
            let d = th - shkTh
            shkTh = th
            if d != 0 && !clusters.isEmpty { rotateFree(by: d, around: clusters[gi].xc, clusters[gi].yc) }
        }
        if sillOn && sillRoute != nil { attOn = false; return }   // v2.30: on a route the route decides (sillStep); no looking about, nothing else
        // A7 sniff toward a queued point (this version only sniffs, it does not walk there: it rests after)
        if attOn && t >= attAt {
            attOn = false
            if !engaged && !escOn && !introOn && lv(params.lifeAttend) && !clusters.isEmpty {
                let dx = attX - clusters[gi].xc, dy = attY - clusters[gi].yc, d = hypot(dx, dy), ang = atan2(dy, dx)
                startSniff(ang, max(0.3, min(params.podLen * 1.1, d / R - 0.6)), 0.5, 0.7 + Double.random(in: 0..<0.4, using: &rng), 0.6)
                gaitOn = false; wanderMoving = false
                lifeSt = .look; lifeLooks = 0; lifeNoGo = true; lastDir = ang; lifeUntil = t + 1.8 + Double.random(in: 0..<0.4, using: &rng)
            }
        }
        // A1 deciding: rest → look (85%) or go; look sniffs once or twice → 65% go the last way sniffed, else rest; arrive → bump → rest
        let restOn = lv(params.lifeRest), canGo = params.wander > 0
        let free = idle > 0.5 && !introOn && !escOn && t > cowerUntil && !engaged
        if lifeUntil < 0 { lifeUntil = t + (restOn ? 1.5 + Double.random(in: 0..<1, using: &rng) : 0.8 + Double.random(in: 0..<1, using: &rng)) }
        if engaged || escOn || introOn {
            if gaitOn || lifeSt == .go { gaitOn = false; wanderMoving = false; lifeSt = .rest; lifeUntil = -1 }
            return
        }
        if !free { return }
        if slpOn {   // v2.23 B2: asleep it decides nothing; a finger resting beside it 1.2 s wakes it gently
            slpNearT = (iv2(params.impC1) || iv2(params.impC2)) && lureFinger() != nil ? slpNearT + dt : 0
            if slpNearT > 1.2 { wake(false) }
            return
        }
        let hear: Bool = echoSt == 1 && params.nearFast >= 0.5   // v2.61 C2 (nearFast): still listening (the finger may be there to stay): it looks at the finger beside it and comes over all the same; only answering holds it
        if echoSt != 0 && !hear { return }   // v2.23 C6: listening to your rhythm or answering it: it stays put
        if lifeSt == .rest && !brOn && sleepTry() { return }   // v2.63 大腦 on: brainRest decides whether it sleeps
        let lured = lureStep(dt)   // v2.20 C1 C2: a finger resting beside it takes over
        if hear && !lured { return }   // v2.61 C2: between two taps it does not wander off by itself
        let e4 = !lured && e4Step(dt)   // v2.22 E4: trusting and left alone a while, it comes to the front to say hello
        // v2.20 C4 begging: a pseudopod toward where your finger left, edging over when that is far
        if !lured && !e4 && askOn && t >= askAt && !clusters.isEmpty {
            askOn = false; voice("ask", 0.6)
            let dx = askX - clusters[gi].xc, dy = askY - clusters[gi].yc, d = max(1e-6, hypot(dx, dy)), ang = atan2(dy, dx)
            startSniff(ang, max(0.4, min(1.2, d / R - 0.7)), 0.5, 1.5, 0.7)
            if d > R * 1.6 { gaitTo(askX - dx / d * R * 1.1, askY - dy / d * R * 1.1, dash: false) }
            else { lifeSt = .look; lifeLooks = 0; lifeNoGo = true; lastDir = ang; lifeUntil = t + 2.8 }
        }
        if let q = ltReactQ, t >= q.at { if lured || e4 { ltReactQ?.at = -9 }; ltReact() }   // v2.64 C5 看完的小反應（手指在旁邊、來找你時不做）；lookTarget 0 時 ltReactQ 一直是 nil
        if params.signature >= 0.5 || sgOn != nil { sgStep(dt, lured || e4) }   // v2.64 C8 招牌動作（網頁：同一個位置；signature 0 時 sgOn 一直是 nil，不呼叫）
        if !lured && !e4 && !napOn {   // v2.63 C9: the few seconds it waits to fall asleep at your hand, it does not change what it is doing (no walking, not back to the mat); nap 0: napOn is always false
            if lifeSt == .rest && t >= lifeUntil {
                if brOn { brainRest(canGo) }   // v2.63 大腦
                else if restOn && (Double.random(in: 0..<1, using: &rng) < 0.85 || !canGo) { lifeSt = .look; lifeLooks = Double.random(in: 0..<1, using: &rng) < 0.45 + 0.35 * exLevel() ? 2 : 1; lifeNoGo = false; lifeUntil = t }
                else if canGo { goStart(nil) } else { lifeUntil = t + restDur() }
            }
            if lifeSt == .look && t >= lifeUntil {
                if lifeLooks > 0 {
                    lifeLooks -= 1
                    if brOn { brain.q = max(0, brain.q - 0.25) }   // v2.63 大腦: looking about uses up curiosity
                    if mdOn { brain.m += 0.005 }   // v2.63 心情: a look about, a very little better (the web's; clamped in the next mood step)
                    let a = pickDir(), s = startSniff(a, params.podLen * (0.75 + 0.35 * Double.random(in: 0..<1, using: &rng)), 1.2, 0.5 + Double.random(in: 0..<1, using: &rng), 0.8)
                    lastDir = a; lifeUntil = t + s.T1 + s.T2 + s.T3 + 0.3 + Double.random(in: 0..<0.5, using: &rng)
                    if let cur = ltCur { ltReactQ = LookReact(tg: cur, sid: s.id, a: a, at: t + s.T1 + s.T2 * 0.6); ltCur = nil }   // v2.64 C5（網頁 ltArm）：有對象就排一個看完的小反應；lookTarget 0 時 ltCur 一直是 nil
                } else if !lifeNoGo && canGo && (brOn ? brain.goAfterLook() : Double.random(in: 0..<1, using: &rng) < 0.65) {
                    if brOn { brainGo(lastDir) } else { goStart(lastDir + Double.random(in: -0.175..<0.175, using: &rng)) }   // v2.63 大腦
                } else {
                    lifeSt = .rest; lifeUntil = t + restDur()
                }
            }
        }
        if lifeSt == .go && !gaitOn && wanderMoving {   // gait off: v2.18's glide (dragged by the home spring)
            wanderP = min(1, wanderP + dt / wanderT)
            let p = wanderP, e = p * p * (3 - 2 * p)
            let nx = wanderSX + (wanderX - wanderSX) * e, ny = wanderSY + (wanderY - wanderSY) * e
            wanderVX = (nx - homeX) / dt; wanderVY = (ny - homeY) / dt; homeX = nx; homeY = ny
            if p >= 1 { wanderMoving = false; lifeSt = .arrive; arrT = t; arrA = 0; arrK = 0; arrK0 = 1; arrOff = 0 }
        }
        if gaitOn { gaitStep(dt) }
        if lifeSt == .arrive {
            let u = t - arrT
            if u >= 0 && u < 1.2 {
                let w = 2 * Double.pi / 0.6, dmp = exp(-u / 0.3), o = arrA * dmp * sin(w * u), d = o - arrOff
                arrOff = o
                moveHome(cos(arrH) * d, sin(arrH) * d, dt)
                strK = 1 + (arrK0 - 1) * exp(-u / 0.12) - arrK * dmp * sin(w * u); strH = arrH
            }
            if u > 0.9 || u < 0 { lifeSt = .rest; lifeUntil = t + restDur() }
        }
    }

    // MARK: - v2.20 drag (D1), quick dents (D2), the impression and what it does with it (C1...C5)

    private func bodyStretch(_ f: Finger) -> Double { f.sb >= 0 ? f.sb : f.stretch }
    /// Follow share: D1's `drag`; C3 trusting follows more, wary less; less while it strains to flee (a gentle drag leads it, a hard pull meets resistance).
    private func dragFollow() -> Double {
        guard params.drag > 0 else { return 0 }
        var k = params.drag
        if iv2(params.impC3) { k *= max(0.3, 1 + 0.43 * impTrust - 0.57 * impWary) }
        if params.emo >= 0.5 {
            let ease: Double = roughOn ? max(moodStrain, moodTugS * tugIn()) : moodStrain   // v2.61 D1
            k *= 1 - 0.7 * ease
        }
        return k
    }
    /// v2.61 D1 (rough), web tugIn: a slow pull keeps moodStrain at 0, so reading it dragFollow never let go of following the finger: pulled slowly from one
    /// side through the body, home stopped 0.84R off (following less it settles 0.46R off and the finger comes out on the other side) and the ring the strand made
    /// with the body never closed (web, hole readings over 20 seeds, 387 against 193). So a pull through the body lets go by moodTugS (how far and how long,
    /// the tug back's own); one heading outward still reads moodStrain (all of them reading it, the body gets longer and the mixed 250 break 6 to 13 sets more).
    /// How much of the pull is that kind, 0...1; one finger only.
    private func tugIn() -> Double {
        var g: Finger?
        var n = 0
        for q in fingers.values where q.mode == .grab { g = q; n += 1 }
        guard n == 1, let f = g, let r0x = f.r0x, f.tug != true else { return 0 }
        let rl: Double = hypot(r0x, f.r0y), dx: Double = f.x - f.ax, dy: Double = f.y - f.ay, dl: Double = hypot(dx, dy)
        if rl < R * 0.1 || dl < R * 0.1 { return 0 }
        let dot: Double = dx * r0x + dy * f.r0y
        let inward: Double = -dot / (rl * dl)
        let wt: Double = smooth01((rl / R - RoughSet.inR) / 0.25)
        return wt * smooth01((inward - RoughSet.inC) / 0.2)
    }
    private func dragAvg() -> (x: Double, y: Double, n: Int) {
        var sx = 0.0, sy = 0.0, n = 0
        for f in fingers.values where f.mode == .grab { sx += f.fx - f.ax; sy += f.fy - f.ay; n += 1 }
        return n > 0 ? (sx / Double(n), sy / Double(n), n) : (0, 0, 0)
    }
    /// v2.21 D1' pull (多米 build 77 video: pulled down-right, it should go down-right too; measured: jelly pulled 2.5R, the body
    /// followed 0.56R): stretched first, and pulled on past about `slide` the whole body is dragged along. Stretch = slide·tanh((1 − follow)
    /// · travel / slide), the rest moves the body. From the fingers' real travel (not the limited one), averaged: two fingers pulling
    /// apart average near 0, so it is not dragged and still stretches long. C3: wary needs a longer pull before it gives, trusting goes at once
    private func slideLen() -> Double {
        var S = params.slide * R
        if iv2(params.impC3) { S *= max(0.5, 1 + 0.8 * impWary - 0.4 * impTrust) }
        return S
    }
    private func dragTarget() -> (x: Double, y: Double, n: Int) {
        guard params.slide > 0 else { let a = dragAvg(), k = dragFollow(); return (a.x * k, a.y * k, a.n) }
        var sx = 0.0, sy = 0.0, n = 0
        for f in fingers.values where f.mode == .grab {   // v2.51 tug: a finger holding the edge does not carry the body, it pulls a strand out
            if f.tug != true { sx += f.x - f.ax; sy += f.y - f.ay }
            n += 1
        }
        if n == 0 { return (0, 0, 0) }
        var dx: Double = sx / Double(n), dy: Double = sy / Double(n), dl: Double = hypot(dx, dy)
        if dl < 1e-9 { return (0, 0, n) }
        // v2.61 A4 (iw): one finger pulling towards the body's middle: that part of the travel moves the whole body first (at most 1.6 × how far
        // from the middle it took hold), only the rest stretches it
        var wx = 0.0, wy = 0.0
        if params.pullWhole >= 0.5, n == 1, let f = fingers.values.first(where: { $0.mode == .grab }), let r0x = f.r0x {
            let rl: Double = hypot(r0x, f.r0y)
            if rl > R * 0.1 {
                let ux: Double = r0x / rl, uy: Double = f.r0y / rl
                let p: Double = -(dx * ux + dy * uy)
                if p > 0 {
                    let wt: Double = smooth01((rl / R - PullSet.wholeR0) / PullSet.wholeRamp)
                    let c: Double = min(p, rl * PullSet.wholeK) * wt
                    wx = -ux * c; wy = -uy * c
                    dx -= wx; dy -= wy
                    dl = hypot(dx, dy)
                    if !(dl > 0) { dl = 1e-9 }
                }
            }
        }
        let S = slideLen(), st: Double = S * tanh((1 - dragFollow()) * dl / S)
        return (wx + dx - dx / dl * st, wy + dy - dy / dl * st, n)
    }
    /// A finger joined or left: fold the offset into home, then rebase so the target carries on from 0.
    private func dragRebase() {
        homeX += dragOX; homeY += dragOY; dragOX = 0; dragOY = 0
        let a = dragTarget()
        dragBX = a.n > 0 ? -a.x : 0; dragBY = a.n > 0 ? -a.y : 0; dragSlipT = 0
    }
    /// Let go: others still holding → rebase; the last one → the offset joins home (it stays where it was dragged) and a fling glides
    /// on at the offset's speed (at most about 0.4R, 0.25 s time constant).
    private func dragRelease(glide: Bool) {
        if fingers.values.contains(where: { $0.mode == .grab }) { dragRebase(); return }
        pullStillT = 0   // v2.61: the last one let go
        var vx = dragVX, vy = dragVY
        let vl = hypot(vx, vy), vm = R * (params.slide > 0 ? 6 : 1.6)   // v2.21: a fling glides on up to about 1.5R (v2.20 0.4R)
        if vl > vm { vx *= vm / vl; vy *= vm / vl }
        if glide && vl > R * 0.3 { dragGX = vx; dragGY = vy }
        homeX += dragOX; homeY += dragOY
        dragOX = 0; dragOY = 0; dragVX = 0; dragVY = 0; dragBX = 0; dragBY = 0; dragSlipT = 0
    }
    /// Every frame: the offset eases toward `drag` of the travel (home moves, and the held home spring brings the body along);
    /// sb = how far the body itself is pulled open, used by the mood and the shake-off.
    /// v2.38 極限拉扯 (多米 11-09). Each finger has its own stretch limit (maxPull), two fingers had none between them: pulled opposite ways the length doubled
    /// (web: up and down to the screen edges, 9.1R, 0.04R at the thinnest, the remembered shape flipped 150 triangles, knotted after release).
    /// Between two grabbing fingers: past 60% of pairMax it gets harder and harder; the fingers really apart past tearK × pairMax for 0.12 s
    /// and it tears: the finger farther from the body lets go with the loudest pop and a strand.
    private var pairOver = 0.0
    private(set) var pairStretch = 0.0   // 0-1 of pairMax, for the sound
    private func pairStep(_ dt: Double) {
        pairStretch = 0
        let mat = effParams
        guard mat.pairMax > 0 else { pairOver = 0; return }
        let gs = fingers.values.filter { $0.mode == .grab }
        guard gs.count >= 2 else { pairOver = 0; return }
        let Lp = mat.pairMax * R, kn = 0.6 * Lp, rest = Lp - kn
        var worst: (Finger, Finger)? = nil, wr = 0.0
        for i in 0..<gs.count {
            for j in (i + 1)..<gs.count {
                let a = gs[i], b = gs[j], dx = b.tgx - a.tgx, dy = b.tgy - a.tgy, d = hypot(dx, dy)
                if d > kn {
                    let d2 = kn + rest * tanh((d - kn) / rest), s = (d - d2) / 2 / d
                    a.tgx += dx * s; a.tgy += dy * s; b.tgx -= dx * s; b.tgy -= dy * s
                }
                pairStretch = max(pairStretch, min(d, Lp) / Lp)
                let raw = hypot(b.x - a.x, b.y - a.y) / Lp
                if raw > wr { wr = raw; worst = (a, b) }
            }
        }
        if mat.tear >= 0.5, let w = worst, wr > mat.tearK {
            pairOver += dt
            if pairOver >= 0.12 {
                pairOver = 0
                let c = clusters[gi], da = hypot(w.0.x - c.xc, w.0.y - c.yc), db = hypot(w.1.x - c.xc, w.1.y - c.yc)
                tearFinger(da >= db ? w.0 : w.1)
            }
        } else { pairOver = 0 }
    }
    /// Tearing: an ordinary release (feel, trust, mood the same), the stretch counted full so the pop is the biggest; that finger holds nothing until lifted.
    // MARK: - v2.51 黏條、分裂 (多米 11-22). Port of the web's strandStep / splitNow / extraMask. From v2.62 the split makes a second slime (below, 扯斷成兩隻).
    // The strand: the physical body stretches only to a stable length; the rest of the way to the finger is a chain of `gooN` nodes (the middle lags, so it
    // bends when swung), drawn into the skin's mask. The mask is blurred and thresholded anyway, so the strand joins the body round. Half-width: 0.26R at the
    // root, thinner in the middle with length but never under 0.12R (still above the threshold after the blur, it cannot vanish), 0.2R at the finger.
    // The split: the finger farther than 3.4R (strandSplitAt; from v2.62 splitAt is only the tear's) from the centre for 0.4 s, the middle pinches shut over 0.25 s; the body's end draws back, the finger's
    // end becomes the small blob (a point, a radius, a squash). The merge: left alone `rejoin` seconds it crawls back; touching the body (or dropped on it)
    // it is drawn in over 0.45 s. Both are in one mask, so a bridge forms between them by itself as they close.
    private struct Goo {
        var id: ObjectIdentifier
        var free = false
        var n: [(x: Double, y: Double)]
        var k = 0.0, pinch = 0.0, over = 0.0, want = 0.0, L = 0.0
        var ai = -1
        var rx = 0.0, ry = 0.0, tx = 0.0, ty = 0.0
    }
    private var goo: [Goo] = []
    private let gooN = 14
    private static let strandSplitAt = 3.4   // v2.51 the strand: the finger this many radii from the centre for 0.4 s, it pinches and parts
    // v2.62 the second slime (web B2). b2On is B2.on: remeshCheck reads it (no re-sample while there are two)
    private var b2On = false
    private struct TwinCluster { var idx: [Int]; var w: Double }
    /// A touch holding the second slime (web B2.fg): world position (it follows only the real movement, as the body's fingers), its lagged position, where it took hold, the last screen point, the grabbed patch
    private final class TwinFinger {
        var x, y, fx, fy: Double
        let ax, ay: Double
        var sx, sy: Double
        let mem: [(i: Int, ox: Double, oy: Double, w: Double)]
        var dead = false   // the merge took it away; nothing until it lifts
        init(x: Double, y: Double, sx: Double, sy: Double, mem: [(i: Int, ox: Double, oy: Double, w: Double)]) {
            self.x = x; self.y = y; fx = x; fy = y; ax = x; ay = y; self.sx = sx; self.sy = sy; self.mem = mem
        }
    }
    /// The merge playing (web B2.mg): which one, when, how long; how much has flowed in; the direction to A; where the second one started; the gap then; the touching pair (B, A);
    /// the touching point from A's centre; what the drawing needs (web mg.draw: str, bridge, ring, bulge, shut)
    private final class TwinMerge {
        let fx: Int
        let t0: Double, T: Double, ux: Double, uy: Double, bx0: Double, by0: Double, gap0: Double
        let bi: Int, ai: Int
        let rx: Double, ry: Double
        var mass = 0.0, gul = false, pop = false
        var str = 0.0, bridge = 0.0, ring = 0.0, bulge = 0.0, shut = 0.0
        init(fx: Int, t0: Double, T: Double, ux: Double, uy: Double, bx0: Double, by0: Double, gap0: Double, bi: Int, ai: Int, rx: Double, ry: Double) {
            self.fx = fx; self.t0 = t0; self.T = T; self.ux = ux; self.uy = uy; self.bx0 = bx0; self.by0 = by0; self.gap0 = gap0; self.bi = bi; self.ai = ai; self.rx = rx; self.ry = ry
        }
    }
    private var twN = 0, twH = 10.0, twR = 0.0, twA0 = 1.0
    private var twBnd: [Int] = [], twBndL: [Double] = [], twBI: [Int] = []
    private var twX: [Double] = [], twY: [Double] = [], twPX: [Double] = [], twPY: [Double] = []
    private var twQ0X: [Double] = [], twQ0Y: [Double] = [], twQX: [Double] = [], twQY: [Double] = []
    private var twGX: [Double] = [], twGY: [Double] = [], twGW: [Double] = [], twGWT: [Double] = []
    private var twCl: [TwinCluster] = [], twGAng = 0.0, twGXC = 0.0, twGYC = 0.0   // its clusters (the last is the whole body) and the whole body's turn and centre
    private var twCellHead: [Int32] = [], twCellNext: [Int32] = []
    private var twEL: [Int] = [], twER: [Int] = [], twBlinkT = -9.0, twNextBlink = 0.0
    private var twTouchT = 0.0   // v2.62 mergeWait: how long the two have been touching (reset when they part)
    private var twHide = false, twIdle = 0.0, twSc = 1.0, twQa = 1.0, twQp = 1.0, twAx = 1.0, twAy = 0.0, twStretch = 0.0
    private var twFg: [ObjectIdentifier: TwinFinger] = [:]
    private var twMg: TwinMerge?
    // web SPLIT: how many tears and merges; when it tore; A's size k (eased); the second one's share; torn this time (one at a time); pulled apart past 0.6R since;
    // A's reference scaling (mx, already in the reference shape's frame), its determinant and the shrink of the no-overlap distance; the squash, the wobble, the happy eyes; the lumps on A (pods)
    private var splitN = 0, splitMerged = 0, splitT0 = -9.0, splitFracNow = 0.45, splitUsed = false, splitApart = false
    private(set) var splitK = 1.0
    private var splitMx: (m00: Double, m01: Double, m10: Double, m11: Double) = (1, 0, 0, 1)
    private var splitDet = 1.0, splitDmin = 1.0, splitWob = -9.0, splitHappy = -9.0
    private var splitSq: (ux: Double, uy: Double, a: Double, p: Double)?
    private var splitPods: [(a: Double, amp: Double, sig: Double)] = []

    private func gooW(_ q: Goo, _ u: Double) -> Double {
        let wr: Double = R * 0.26, wm: Double = R * max(0.12, 0.26 / (1 + q.L / (R * 1.4))), wt: Double = R * 0.2
        let a: Double = (1 - u) * (1 - u) * (1 - u), b: Double = u < 0.8 ? 0 : (u - 0.8) / 0.2
        var w: Double = wm + (wr - wm) * a + (wt - wm) * b * b * (3 - 2 * b)
        if q.pinch > 0 { let d = (u - 0.5) / 0.16; w *= 1 - q.pinch * exp(-d * d) }   // the waist
        return w * q.k
    }

    private func gooStep(_ dt: Double) {
        guard params.strand >= 0.5, !clusters.isEmpty else { goo.removeAll(); return }
        let gc = clusters[gi]
        for (id, f) in Array(fingers) where f.mode == .grab {
            if f.tug == nil {   // held within tugEdge×R of the outline: a strand is pulled out; nearer the middle: picked up whole
                var bd = 1e18
                for i in bnd { let e = (X[i] - f.ax) * (X[i] - f.ax) + (Y[i] - f.ay) * (Y[i] - f.ay); if e < bd { bd = e } }
                f.tug = bd.squareRoot() < R * params.tugEdge
            }
            let d: Double = hypot(f.x - f.fx, f.y - f.fy)
            var qi = goo.firstIndex(where: { $0.id == id && !$0.free })
            if qi == nil {
                if d < R * 0.3 { continue }
                goo.append(Goo(id: id, n: Array(repeating: (f.fx, f.fy), count: gooN)))
                qi = goo.count - 1
            }
            guard let q = qi else { continue }
            goo[q].rx = f.fx; goo[q].ry = f.fy; goo[q].tx = f.x; goo[q].ty = f.y; goo[q].want = d > R * 0.3 ? 1 : 0
            var bd = 1e18
            for i in bnd { let e = (X[i] - f.fx) * (X[i] - f.fx) + (Y[i] - f.fy) * (Y[i] - f.fy); if e < bd { bd = e; goo[q].ai = i } }   // let go, the root rides this boundary particle
            // the split: the finger far enough from the centre, long enough
            let far: Bool = hypot(f.x - gc.xc, f.y - gc.yc) > Self.strandSplitAt * R   // v2.62 fix: the strand keeps v2.51's 3.4R from the centre; splitAt is the tear's now (1.8 from where it took hold), shared it parted at 1.8R (web T63 g)
            if params.split >= 0.5 && !b2On && !splitUsed && far && goo[q].k > 0.9 { goo[q].over += dt } else { goo[q].over = max(0, goo[q].over - dt * 2) }
            goo[q].pinch = max(0, min(1, (goo[q].over - 0.4) / 0.25))
            if goo[q].pinch >= 1 { splitNow(q, f) }
        }
        var j = goo.count - 1
        while j >= 0 {
            if !goo[j].free {
                let held: Bool = fingers[goo[j].id].map { $0.mode == .grab } ?? false
                if !held { goo[j].free = true; goo[j].pinch = 0 }
            }
            if goo[j].free {
                let ai = goo[j].ai
                if ai >= 0 && ai < N { goo[j].rx = X[ai]; goo[j].ry = Y[ai] }
                let k = 1 - exp(-dt / 0.07)
                goo[j].tx += (goo[j].rx - goo[j].tx) * k; goo[j].ty += (goo[j].ry - goo[j].ty) * k
                goo[j].want = 1
                if hypot(goo[j].tx - goo[j].rx, goo[j].ty - goo[j].ry) < R * 0.12 { goo.remove(at: j); j -= 1; continue }
            }
            goo[j].k += (goo[j].want - goo[j].k) * (1 - exp(-dt / 0.06))
            let L: Double = hypot(goo[j].tx - goo[j].rx, goo[j].ty - goo[j].ry)
            goo[j].L = L
            for i in 0..<gooN {
                let u = Double(i) / Double(gooN - 1), sg = sin(.pi * u)
                let gx: Double = goo[j].rx + (goo[j].tx - goo[j].rx) * u
                let gy: Double = goo[j].ry + (goo[j].ty - goo[j].ry) * u + (sillOn ? L * 0.05 * sg : 0)   // a little sag under gravity
                let k: Double = i == 0 || i == gooN - 1 ? 1 : 1 - exp(-dt / (0.012 + 0.05 * sg))
                goo[j].n[i].x += (gx - goo[j].n[i].x) * k; goo[j].n[i].y += (gy - goo[j].n[i].y) * k
            }
            j -= 1
        }
    }

    private func splitNow(_ q: Int, _ f: Finger) {
        let m = goo[q].n[gooN / 2]
        goo[q].free = true; goo[q].pinch = 0; goo[q].over = 0; goo[q].tx = m.x; goo[q].ty = m.y
        twinSpawn(f)   // v2.51 the strand pinches and parts; from v2.62 what comes off is a second slime you can pinch (the same touch holds it)
    }

    // MARK: - v2.62 扯斷成兩隻、碰到合回一隻 (多米 11-26). Port of the web's splitCheck / twinSpawn / twinBuild / twinSub / twinMem / twinStep / mergeStart / mergeStep / mergeEnd / twinDrop / splitKStep.
    // The tear: a grabbing finger pulled more than splitAt radii from where it took hold (a phone held upright is 3.7R wide, from the centre it could hardly be reached),
    // outward, faster than splitV radii a second on screen (the same ruler as v2.61's yank), for 0.05 s. With the strand on it is v2.51's pinch instead.
    // At the tear the same touch takes the second one; A lets go and springs back, the remembered shape eases back over half a second (what was pulled out is the second one now).
    // The second one is a whole small slime: its own particles (A's spacing), clusters, area pressure, ring rope, clay memory, gravity, the sill and the walls, eyes, blush;
    // it can be grabbed, pulled and pinched with two fingers. Area: it takes splitFrac; A's reference shape and target area shrink to the rest together (splitK, the particles stay),
    // merged k goes back to 1 and the points and the area are the original ones. At most two: while there are two neither tears. Whether it can tear again after a merge: splitAgain.
    // The merge: once pulled apart past 0.6R (or 0.6 s after it was let go), the outlines within mergeGap R (the bridge 0.5R more, the drop 0.25R, swallowing 0.1R, for the goo
    // and the neck to have room) and touching for mergeWait seconds (parted, it starts again) start mergeFx: 0 a bridge of goo, 1 squash and pop, 2 a drop and a ripple, 3 swallowed. Then it is gone and A is its old size.
    // Left alone `rejoin` seconds it crawls back in pulses (v2.51 had that). It is drawn into A's mask, which is blurred and cut, so a round neck grows between them as they close.
    private static let mergeT: [Double] = [1.1, 0.85, 1.1, 1]   // seconds each merge plays (as the design board)
    private static let mergeReach: [Double] = [0.5, 0, 0.25, 0.1]
    private static func sstep(_ x: Double) -> Double { let u: Double = max(0, min(1, x)); return u * u * (3 - 2 * u) }
    private static func sbump(_ x: Double) -> Double { x <= 0 || x >= 1 ? 0 : sin(.pi * x) }
    private func mergeFxIndex(_ mat: FeelParams) -> Int {
        guard mat.mergeFx.isFinite else { return 0 }
        let r = Int(mat.mergeFx.rounded())
        return ((r % 4) + 4) % 4
    }

    private func splitCheck(_ dt: Double) {
        let mat = effParams
        guard mat.split >= 0.5, !(mat.strand >= 0.5), !b2On, !splitUsed, !introOn, !clusters.isEmpty else { return }   // the strand on: gooStep's way
        let gc = clusters[gi]
        for f in Array(fingers.values) where f.mode == .grab {
            let ox: Double = f.x - gc.xc, oy: Double = f.y - gc.yc, d: Double = hypot(f.x - f.ax, f.y - f.ay) / R
            let vx: Double = f.vxS, vy: Double = f.vyS, v: Double = hypot(vx, vy) * camZ / R
            if d > mat.splitAt && v > mat.splitV && ox * vx + oy * vy > 0 { f.splitT += dt } else { f.splitT = max(0, f.splitT - dt) }
            if f.splitT >= 0.05 { twinSpawn(f); return }
        }
    }

    private func twinSpawn(_ f: Finger) {
        guard !clusters.isEmpty, N > 0, let id = fingers.first(where: { $0.value === f })?.key else { return }
        let mat = effParams, gc = clusters[gi], fx: Double = f.fx, fy: Double = f.fy
        var ux: Double = gc.xc - fx, uy: Double = gc.yc - fy
        let ul: Double = hypot(ux, uy)
        if ul > 1e-9 { ux /= ul; uy /= ul } else { ux = 1; uy = 0 }   // the web divides by 1 here (all its points would land on one spot)
        let frac: Double = max(0.2, min(0.6, mat.splitFrac > 0 ? mat.splitFrac : 0.45))
        splitFracNow = frac
        let rb: Double = (frac * A0 / .pi).squareRoot(), x: Double = f.x, y: Double = f.y, sx: Double = f.sx, sy: Double = f.sy
        twinBuild(fx + ux * rb * 0.3, fy + uy * rb * 0.3, rb, ux, uy, mat)
        tearFinger(f); relaxUntil = max(relaxUntil, t + 0.5); CAPG = 1   // A: let go, the memory of what was pulled out eases off in half a second
        if remN > 0, mat.remeshHome >= 0.5, HB.count == bnd.count, remesh(back: true) { remN = 0; remCalm = t + max(0, mat.remeshCalm); remLast = t }   // re-sampled: back to the mesh it was built with (no re-sample while there are two), so the points add up again after the merge
        twinGrab(id, x, y, sx, sy, mat)
        splitN += 1; splitT0 = t; splitUsed = true; splitApart = false
    }

    private func twArea(_ px: [Double], _ py: [Double]) -> Double {
        let b = twBnd, n = b.count
        guard n > 2 else { return 0 }
        var A = 0.0
        for k in 0..<n { let i = b[k], j = b[(k + 1) % n]; A += px[i] * py[j] - px[j] * py[i] }
        return abs(A) / 2
    }

    private func twinBuild(_ cx: Double, _ cy: Double, _ rb: Double, _ ux: Double, _ uy: Double, _ mat: FeelParams) {
        let hh: Double = h
        let p0: Double = Double.random(in: 0..<1, using: &rng) * 6.283, p1: Double = Double.random(in: 0..<1, using: &rng) * 6.283
        func rr(_ a: Double) -> Double { rb * (1 + 0.045 * sin(2 * a + p0) + 0.03 * sin(3 * a + p1)) }
        var pts: [(x: Double, y: Double)] = [], bn: [Int] = []
        let M: Int = max(20, Int((2 * Double.pi * rb / (hh * 1.05)).rounded()))
        for m in 0..<M {
            let a: Double = -Double.pi / 2 + Double(m) / Double(M) * 2 * Double.pi, r: Double = rr(a)
            bn.append(pts.count); pts.append((x: cos(a) * r, y: sin(a) * r * 0.94))
        }
        var row = 0, gy: Double = -rb * 1.2
        while gy <= rb * 1.2 {
            var gx: Double = -rb * 1.2 + (row % 2 == 1 ? hh / 2 : 0)
            while gx <= rb * 1.2 {
                if hypot(gx, gy / 0.94) <= rr(atan2(gy / 0.94, gx)) - hh * 0.3 {
                    var dm = 1e9
                    for k in bn { dm = min(dm, hypot(pts[k].x - gx, pts[k].y - gy)) }
                    if dm > hh * 0.7 { pts.append((x: gx, y: gy)) }
                }
                gx += hh
            }
            gy += hh * 0.87; row += 1
        }
        let n = pts.count
        var mx = 0.0, my = 0.0
        for p in pts { mx += p.x; my += p.y }
        mx /= Double(n); my /= Double(n)
        let z = [Double](repeating: 0, count: n)
        twN = n; twBnd = bn; twH = hh; twR = rb
        twX = z; twY = z; twPX = z; twPY = z; twQ0X = z; twQ0Y = z; twQX = z; twQY = z; twGX = z; twGY = z; twGW = z; twGWT = z
        let vx: Double = -uy, vy: Double = ux, ea: Double = 1.45, ep: Double = 1 / 1.45   // just torn: drawn out along the tear, let go it springs back round (that is the shape matching's own bounce)
        for i in 0..<n {
            let qx: Double = pts[i].x - mx, qy: Double = pts[i].y - my, al: Double = qx * ux + qy * uy, pe: Double = qx * vx + qy * vy
            twQ0X[i] = qx; twQX[i] = qx; twQ0Y[i] = qy; twQY[i] = qy
            let px: Double = cx + ux * al * ea + vx * pe * ep, py: Double = cy + uy * al * ea + vy * pe * ep
            twX[i] = px; twPX[i] = px; twY[i] = py; twPY[i] = py
        }
        let nb = bn.count
        twBndL = []
        for k in 0..<nb { let i = bn[k], j = bn[(k + 1) % nb]; twBndL.append(hypot(twQ0X[j] - twQ0X[i], twQ0Y[j] - twQ0Y[i])) }
        twBI = [Int](repeating: -1, count: n)
        for k in 0..<nb { twBI[bn[k]] = k }
        twA0 = twArea(twQ0X, twQ0Y)
        twCl = []
        let cs: Double = R * mat.cSpace, cr: Double = R * mat.cRad
        if cs > 0 {
            var yy: Double = -rb * 1.3
            while yy <= rb * 1.3 {
                var xx: Double = -rb * 1.3
                while xx <= rb * 1.3 {
                    var idx: [Int] = []
                    for i in 0..<n where hypot(twQ0X[i] - xx, twQ0Y[i] - yy) < cr { idx.append(i) }
                    if idx.count >= 5 { twCl.append(TwinCluster(idx: idx, w: 1)) }
                    xx += cs
                }
                yy += cs
            }
        }
        twCl.append(TwinCluster(idx: Array(0..<n), w: mat.wGlobal))   // the whole body, last
        twGAng = 0; twGXC = cx; twGYC = cy
        func near3(_ x: Double, _ y: Double) -> [Int] {
            var o: [(d: Double, i: Int)] = []
            for i in 0..<n { o.append((d: hypot(twQ0X[i] - x, twQ0Y[i] - y), i: i)) }
            o.sort { $0.d < $1.d }
            return o.prefix(3).map { $0.i }
        }
        twEL = near3(-rb * 0.34, -rb * 0.12); twER = near3(rb * 0.34, -rb * 0.12)
        twBlinkT = -9; twNextBlink = t + 1.5 + Double.random(in: 0..<1, using: &rng) * 3
        twCellNext = [Int32](repeating: -1, count: n)
        b2On = true; twFg.removeAll(); twMg = nil; twHide = false; twTouchT = 0; twIdle = t; twSc = 1; twQa = 1; twQp = 1; twAx = ux; twAy = uy; twStretch = 0
    }

    /// A touch landing here takes the second one: inside its outline, or within 0.25R of it outside A
    private func twinHit(_ x: Double, _ y: Double) -> Bool {
        guard b2On, !twHide, twMg == nil else { return false }
        let n = twBnd.count
        guard n > 2 else { return false }
        var c = false, j = n - 1
        for k in 0..<n {
            let i1 = twBnd[k], i2 = twBnd[j]
            let ax: Double = twX[i1], ay: Double = twY[i1], bx: Double = twX[i2], by: Double = twY[i2]
            if (ay > y) != (by > y) && x < (bx - ax) * (y - ay) / (by - ay) + ax { c.toggle() }
            j = k
        }
        if c { return true }
        if insideBody(x, y) { return false }
        var d = 1e18
        for i in twBnd { let dx: Double = twX[i] - x, dy: Double = twY[i] - y; d = min(d, dx * dx + dy * dy) }
        return d.squareRoot() < R * 0.25
    }

    private func twinGrab(_ id: ObjectIdentifier, _ x: Double, _ y: Double, _ sx: Double, _ sy: Double, _ mat: FeelParams) {
        let rg: Double = R * max(0.2, mat.grabR)
        var mem: [(i: Int, ox: Double, oy: Double, w: Double)] = []
        for i in 0..<twN {
            let d: Double = hypot(twX[i] - x, twY[i] - y)
            if d < rg { let u: Double = d / rg; mem.append((i: i, ox: twX[i] - x, oy: twY[i] - y, w: 1 - u * u)) }
        }
        if mem.isEmpty {
            var o: [(d: Double, i: Int)] = []
            for i in 0..<twN { o.append((d: hypot(twX[i] - x, twY[i] - y), i: i)) }
            o.sort { $0.d < $1.d }
            for q in o.prefix(4) { mem.append((i: q.i, ox: twX[q.i] - x, oy: twY[q.i] - y, w: 0.6)) }
        }
        twFg[id] = TwinFinger(x: x, y: y, sx: sx, sy: sy, mem: mem)
        twIdle = t
    }

    private func twinRelease(_ id: ObjectIdentifier) {
        guard let f = twFg.removeValue(forKey: id) else { return }
        twIdle = t
        if f.dead || !b2On { return }
        let cap: Double = R * 8 * lastSdt   // flung, at most 8R a second (the same number as v2.51)
        for i in 0..<twN {
            let vx: Double = twX[i] - twPX[i], vy: Double = twY[i] - twPY[i], v: Double = hypot(vx, vy)
            if v > cap { twPX[i] = twX[i] - vx * cap / v; twPY[i] = twY[i] - vy * cap / v }
        }
        onEvent?(.release(gain: 0.4, rate: 1.1, special: false))
    }

    private func twinSub(_ dt: Double, _ mat: FeelParams) {
        let n = twN, nb = twBnd.count
        guard n > 0, nb > 2, twX.count == n, twBndL.count == nb, twBI.count == n else { return }
        let damp: Double = min(0.995, mat.damp), alpha: Double = min(1, mat.alpha), wl = worldWalls
        let G: Double = sillOn && sillG != nil ? R * sillGrav : 0
        for i in 0..<n {
            let vx: Double = (twX[i] - twPX[i]) * damp, vy: Double = (twY[i] - twPY[i]) * damp
            twPX[i] = twX[i]; twPY[i] = twY[i]
            twX[i] += vx; twY[i] += vy + G * dt * dt
        }
        for i in 0..<n { twGWT[i] = 0 }
        for f in twFg.values where !f.dead {
            for m in f.mem where m.i < n {
                let k: Double = min(0.95, mat.grabK * m.w)
                twX[m.i] += (f.fx + m.ox - twX[m.i]) * k; twY[m.i] += (f.fy + m.oy - twY[m.i]) * k
                if m.w > twGWT[m.i] { twGWT[m.i] = m.w }
            }
        }
        // shape matching: the reference shape × sc (shrinks while it flows in), qa along (ax, ay) and qp across (squashed, crawling), and a little breath
        let breath: Double = 0.025 * sin(t * 2 * Double.pi / 3.4) * (twFg.isEmpty ? 1 : 0.5)
        let s: Double = twSc * (1 + breath), ux: Double = twAx, uy: Double = twAy, qa: Double = twQa, qp: Double = twQp
        let m00: Double = s * (qa * ux * ux + qp * uy * uy), m01: Double = s * (qa - qp) * ux * uy, m11: Double = s * (qa * uy * uy + qp * ux * ux)
        for i in 0..<n { twGX[i] = 0; twGY[i] = 0; twGW[i] = 0 }
        let last = twCl.count - 1
        for c in 0..<twCl.count {
            let idx = twCl[c].idx, w: Double = twCl[c].w
            if idx.isEmpty { continue }
            let m = Double(idx.count)
            var xc = 0.0, yc = 0.0, qcx = 0.0, qcy = 0.0
            for i in idx { xc += twX[i]; yc += twY[i]; qcx += twQX[i]; qcy += twQY[i] }
            xc /= m; yc /= m; qcx /= m; qcy /= m
            var a = 0.0, b = 0.0, cc = 0.0, d = 0.0
            for i in idx {
                let px: Double = twX[i] - xc, py: Double = twY[i] - yc, ex: Double = twQX[i] - qcx, ey: Double = twQY[i] - qcy
                let qx: Double = m00 * ex + m01 * ey, qy: Double = m01 * ex + m11 * ey
                a += px * qx; b += px * qy; cc += py * qx; d += py * qy
            }
            let ang: Double = atan2(cc - b, a + d), cs: Double = cos(ang), sn: Double = sin(ang)
            if c == last { twGAng = ang; twGXC = xc; twGYC = yc }
            for i in idx {
                let ex: Double = twQX[i] - qcx, ey: Double = twQY[i] - qcy
                let qx: Double = m00 * ex + m01 * ey, qy: Double = m01 * ex + m11 * ey
                twGX[i] += (xc + cs * qx - sn * qy) * w; twGY[i] += (yc + sn * qx + cs * qy) * w; twGW[i] += w
            }
        }
        let A: Double = twArea(twX, twY)
        let want: Double = (twA0 * s * s * qa * qp / max(1, A)).squareRoot()
        let ap: Double = max(-0.12, min(0.12, (want - 1) * mat.areaGain)), cx: Double = twGXC, cy: Double = twGYC
        for i in 0..<n where twGW[i] > 0 {
            let gx: Double = cx + (twGX[i] / twGW[i] - cx) * (1 + ap), gy: Double = cy + (twGY[i] / twGW[i] - cy) * (1 + ap)
            let ka: Double = alpha * (1 - mat.grabHold * twGWT[i])
            twX[i] += (gx - twX[i]) * ka; twY[i] += (gy - twY[i]) * ka
        }
        if twFg.isEmpty && twMg == nil {   // turning back upright: kinematic, no speed left
            let r: Double = -twGAng * min(0.2, max(mat.upright, 0.01)), c: Double = cos(r), sn: Double = sin(r)
            for i in 0..<n {
                var dx: Double = twX[i] - cx, dy: Double = twY[i] - cy
                twX[i] = cx + dx * c - dy * sn; twY[i] = cy + dx * sn + dy * c
                dx = twPX[i] - cx; dy = twPY[i] - cy
                twPX[i] = cx + dx * c - dy * sn; twPY[i] = cy + dx * sn + dy * c
            }
        }
        // the ring rope (A's rule: 0.6 to 2.4 times, the top following the remembered shape)
        let lo0: Double = 0.6 * min(1, s * min(qa, qp))
        for _ in 0..<2 {
            for k in 0..<nb {
                let i = twBnd[k], j = twBnd[(k + 1) % nb]
                let dx: Double = twX[j] - twX[i], dy: Double = twY[j] - twY[i], dh: Double = hypot(dx, dy), d: Double = dh > 0 ? dh : 1e-6
                let l0: Double = twBndL[k], hi: Double = max(l0, hypot(twQX[j] - twQX[i], twQY[j] - twQY[i])) * 2.4, lo: Double = l0 * lo0
                var c = 0.0
                if d > hi { c = (d - hi) / d } else if d < lo { c = (d - lo) / d }
                if c == 0 { continue }
                let wi: Double = twGWT[i] != 0 ? 0.15 : 0.5, wj: Double = twGWT[j] != 0 ? 0.15 : 0.5, sw: Double = wi + wj
                twX[i] += dx * c * wi / sw; twY[i] += dy * c * wi / sw; twX[j] -= dx * c * wj / sw; twY[j] -= dy * c * wj / sw
            }
        }
        // no overlap (0.6 of the spacing; the eight ring neighbours either side are the rope's)
        do {
            let dmin: Double = twH * 0.6 * min(1, s * min(qa, qp)), d2m: Double = dmin * dmin, inv: Double = 1 / max(1e-3, dmin)
            let buckets = 1024
            if twCellNext.count != n { twCellNext = [Int32](repeating: -1, count: n) }
            if twCellHead.count != buckets { twCellHead = [Int32](repeating: -1, count: buckets) }
            for b in 0..<buckets { twCellHead[b] = -1 }
            func key(_ gx: Int, _ gy: Int) -> Int { ((gx &* 73856093) ^ (gy &* 19349663)) & (buckets - 1) }
            for i in 0..<n {
                let b = key(Int(floor(twX[i] * inv)), Int(floor(twY[i] * inv)))
                twCellNext[i] = twCellHead[b]; twCellHead[b] = Int32(i)
            }
            for i in 0..<n {
                let gx = Int(floor(twX[i] * inv)), gy = Int(floor(twY[i] * inv))
                for ox in -1...1 {
                    for oy in -1...1 {
                        var j = Int(twCellHead[key(gx + ox, gy + oy)])
                        while j >= 0 {
                            defer { j = Int(twCellNext[j]) }
                            if j <= i { continue }
                            if twBI[i] >= 0 && twBI[j] >= 0 {
                                let di = abs(twBI[i] - twBI[j])
                                if min(di, nb - di) <= 8 { continue }
                            }
                            let dx: Double = twX[j] - twX[i], dy: Double = twY[j] - twY[i], q: Double = dx * dx + dy * dy
                            if q >= d2m || q < 1e-9 { continue }
                            let d: Double = q.squareRoot(), c: Double = (dmin - d) / d
                            let wi: Double = twGWT[i] != 0 ? 0.3 : 1, wj: Double = twGWT[j] != 0 ? 0.3 : 1, sw: Double = wi + wj
                            twX[i] -= dx * c * wi / sw; twY[i] -= dy * c * wi / sw; twX[j] += dx * c * wj / sw; twY[j] += dy * c * wj / sw
                        }
                    }
                }
            }
        }
        for i in 0..<n {
            if twY[i] > wl.b { twY[i] = wl.b; twPX[i] += (twX[i] - twPX[i]) * 0.35 }
            if twY[i] < wl.t { twY[i] = wl.t }
            if twX[i] < wl.l { twX[i] = wl.l }
            if twX[i] > wl.r { twX[i] = wl.r }
        }
    }

    /// Clay memory: held, it remembers what it was pinched into (aligned with its turn); untouched it eases back at `recover`; the remembered shape centred, kept at its own area
    private func twinMem(_ dt: Double, _ mat: FeelParams) {
        let n = twN, s = twSc
        guard n > 0, s >= 0.3, twQX.count == n else { return }
        let cs: Double = cos(twGAng), sn: Double = sin(twGAng)
        let grab: Bool = twFg.values.contains(where: { !$0.dead })
        if grab && mat.creep > 0 {
            let k: Double = 1 - exp(-mat.creep * 0.5 * dt), y0: Double = R * max(0, mat.yield) * 0.1
            for i in 0..<n {
                let lx: Double = twX[i] - twGXC, ly: Double = twY[i] - twGYC
                let qx: Double = (cs * lx + sn * ly) / s, qy: Double = (-sn * lx + cs * ly) / s
                let ex: Double = qx - twQX[i], ey: Double = qy - twQY[i], e: Double = hypot(ex, ey)
                if e > y0 { let f: Double = k * (e - y0) / e; twQX[i] += ex * f; twQY[i] += ey * f }
            }
        } else if !grab {
            let k: Double = 1 - exp(-max(mat.recover, 0.02) * dt)
            for i in 0..<n { twQX[i] += (twQ0X[i] - twQX[i]) * k; twQY[i] += (twQ0Y[i] - twQY[i]) * k }
        }
        var mx = 0.0, my = 0.0
        for i in 0..<n { mx += twQX[i]; my += twQY[i] }
        mx /= Double(n); my /= Double(n)
        let g: Double = (twA0 / max(1, twArea(twQX, twQY))).squareRoot()   // the area does not move with the centring
        for i in 0..<n { twQX[i] = (twQX[i] - mx) * g; twQY[i] = (twQY[i] - my) * g }
    }

    /// The whole of it moved, its last positions with it (no speed left)
    private func twinMove(_ dx: Double, _ dy: Double) {
        for i in 0..<twN { twX[i] += dx; twY[i] += dy; twPX[i] += dx; twPY[i] += dy }
    }
    private func twinCenter() -> (x: Double, y: Double) {
        guard twN > 0 else { return (0, 0) }
        var x = 0.0, y = 0.0
        for i in 0..<twN { x += twX[i]; y += twY[i] }
        return (x / Double(twN), y / Double(twN))
    }
    /// The nearest pair of outline points (its, A's) and their distance; 0 once one of its points is inside A
    private func twinContact() -> (d: Double, bi: Int, ai: Int) {
        var d = 1e18, bi = -1, ai = -1
        for i in twBnd {
            let x: Double = twX[i], y: Double = twY[i]
            if insideBody(x, y) {
                var q = 1e18, aj = -1
                for j in bnd { let dx: Double = X[j] - x, dy: Double = Y[j] - y, e: Double = dx * dx + dy * dy; if e < q { q = e; aj = j } }
                return (0, i, aj)
            }
            for j in bnd { let dx: Double = X[j] - x, dy: Double = Y[j] - y, e: Double = dx * dx + dy * dy; if e < d { d = e; bi = i; ai = j } }
        }
        return (d.squareRoot(), bi, ai)
    }

    /* v2.64 B8 起步跟手（startFollow；網頁 lagK，1505203；BATCH3 第 7 項、第 8 項之 7）。開著時慢一拍的時間常數從 SfSet.t0（20 毫秒）起，
       照真手指這次起步後走了多遠（sfD，世界座標）在 SfSet.lead（0.6R）內直線變回 lag；每格動不到 SfSet.eps（0.002R）算停，停滿 SfSet.stop（80 毫秒）sfD 歸零，
       下一次起步又快。lag 本身比 20 毫秒還短就照 lag。不抽亂數；sf 關時就是原本那一行 1 − exp(−dt／lag)，連 sfD、sfS 都不碰。
       扯斷出來的第二團（twinStep）照網頁不套起步跟手。網頁用 f.x − f.lx（真指標），手機用 rawX − lastRawX（真手指，不含預測） */
    private func lagK(_ f: Finger, _ dt: Double, lag L: Double, sf: Bool, mv: Double) -> Double {
        guard sf else { return L > 0 ? 1 - exp(-dt / L) : 1 }
        if mv > SfSet.eps * R {
            f.sfD += mv; f.sfS = 0
        } else {
            f.sfS += dt
            if f.sfS >= SfSet.stop { f.sfD = 0 }
        }
        let u: Double = R > 0 ? min(1, f.sfD / (SfSet.lead * R)) : 1
        let ta: Double = L <= SfSet.t0 ? L : SfSet.t0 + (L - SfSet.t0) * u
        f.sfTau = ta
        return ta > 0 ? 1 - exp(-dt / ta) : 1
    }

    private func twinStep(_ dt: Double) {
        guard b2On, !clusters.isEmpty, twN > 0 else { splitKStep(dt); return }
        let mat = effParams, gc = clusters[gi]
        let kl: Double = mat.lag > 0 ? 1 - exp(-dt / mat.lag) : 1
        for f in twFg.values { f.fx += (f.x - f.fx) * kl; f.fy += (f.y - f.fy) * kl }
        var st = 0.0
        for f in twFg.values where !f.dead { st = max(st, hypot(f.x - f.ax, f.y - f.ay) / R) }
        twStretch = st
        if !twFg.isEmpty { twIdle = t; slpLastAny = t }
        if twMg == nil {
            var ta = 1.0, tp = 1.0
            if twFg.isEmpty && t - twIdle > mat.rejoin && !twHide {   // left alone rejoin seconds: it crawls back in pulses
                let c = twinCenter(), dx: Double = gc.xc - c.x, dy: Double = sillOn ? 0 : gc.yc - c.y, dl: Double = hypot(dx, dy), l: Double = dl > 0 ? dl : 1
                let ph: Double = sin((t - twIdle) * 5), p: Double = max(0, ph)
                twinMove(dx / l * R * 1.3 * p * p * dt, dy / l * R * 1.3 * p * p * dt)
                twAx = dx / l; twAy = dy / l; ta = 1 + 0.1 * ph; tp = 1 / ta
            }
            let k: Double = 1 - exp(-dt / 0.08)
            twQa += (ta - twQa) * k; twQp += (tp - twQp) * k
        }
        if !twHide {
            let ns = max(1, Int((dt * 240).rounded())), sdt = dt / Double(ns)   // A's substep
            for _ in 0..<ns { twinSub(sdt, mat) }
            twinMem(dt, mat)
        }
        if t > twNextBlink { twBlinkT = t; twNextBlink = t + 2 + 4 * Double.random(in: 0..<1, using: &rng) }
        if twMg == nil && !twHide && t - splitT0 > 0.35 {
            let c = twinContact(), gap: Double = c.d / R
            if gap > 0.6 { splitApart = true }
            let rest: Bool = twFg.isEmpty && t - twIdle > 0.6 && t - splitT0 > 0.8   // torn off still touching (common on a narrow screen): let go 0.6 s, it counts too
            let near: Double = (mat.mergeGap > 0 ? mat.mergeGap : 0.08) + Self.mergeReach[mergeFxIndex(mat)]
            if (splitApart || rest) && gap < near {   // v2.62 mergeWait (多米 11-26: touching, they merge a little later): touching this long first; parted, it starts again
                twTouchT += dt
                if twTouchT >= (mat.mergeWait >= 0 ? mat.mergeWait : 1.5) { twTouchT = 0; mergeStart(c, mat) }
            } else { twTouchT = 0 }
        }
        if twMg != nil { mergeStep(dt) }
        splitKStep(dt)
    }

    // The merges (mergeFx). All of them: mass is how much of it has flowed into A (0 to 1), A's size k = √(1 − frac·(1 − mass)), its own sc = √(1 − mass), so the area is
    // kept all the way. Its place is moved toward where this one wants it every frame (kinematic). The lumps and the ripple on A ride the pseudopods' road (podE, the area
    // made up by itself); the squash and the pop are in A's reference scaling (splitMx).
    private func mergeStart(_ c: (d: Double, bi: Int, ai: Int), _ mat: FeelParams) {
        guard !clusters.isEmpty, c.ai >= 0, c.ai < N, c.bi >= 0, c.bi < twN else { return }
        let fx = mergeFxIndex(mat), b = twinCenter(), gc = clusters[gi]
        for f in twFg.values { f.dead = true }   // the fingers let go of it as it merges (they hold nothing until lifted)
        var ux: Double = gc.xc - b.x, uy: Double = gc.yc - b.y
        let dl: Double = hypot(ux, uy), l: Double = dl > 0 ? dl : 1
        ux /= l; uy /= l
        let pax: Double = X[c.ai], pay: Double = Y[c.ai], pbx: Double = twX[c.bi], pby: Double = twY[c.bi]
        twMg = TwinMerge(fx: fx, t0: t, T: Self.mergeT[fx], ux: ux, uy: uy, bx0: b.x, by0: b.y, gap0: c.d, bi: c.bi, ai: c.ai,
                         rx: (pax + pbx) / 2 - gc.xc, ry: (pay + pby) / 2 - gc.yc)
        twAx = ux; twAy = uy
        onEvent?(.fx(kind: "cling", gain: 0.5, delay: 0))
    }

    private func mergeStep(_ dt: Double) {
        guard let g = twMg, !clusters.isEmpty else { return }
        let tau: Double = t - g.t0, gc = clusters[gi], cx: Double = gc.xc + g.rx, cy: Double = gc.yc + g.ry, aAng: Double = atan2(g.ry, g.rx), rb: Double = twR
        let b = twinCenter()
        var tx: Double = b.x, ty: Double = b.y, mass = 0.0, qa = 1.0, qp = 1.0
        g.str = 0; g.bridge = 0; g.ring = 0; g.bulge = 0; g.shut = 0
        splitPods.removeAll(); splitSq = nil
        let inAx: Double = gc.xc + (cx - gc.xc) * 0.45, inAy: Double = gc.yc + (cy - gc.yc) * 0.45   // halfway from the touching point to A's centre: where it flows to
        switch g.fx {
        case 0:   // a bridge of goo: a strand out from each (0.2 s) → they join and thicken (0.25) → it slides in along the bridge (0.35) → A bulges on that side (0.4)
            g.str = Self.sstep(tau / 0.2); g.bridge = Self.sstep((tau - 0.2) / 0.25)
            let v: Double = Self.sstep((tau - 0.45) / 0.35)
            mass = v; qa = 1 + 0.1 * g.str * (1 - v); qp = 1 / qa
            tx = g.bx0 + (inAx - g.bx0) * v; ty = g.by0 + (inAy - g.by0) * v
            splitPods.append((a: aAng, amp: R * 0.2 * Self.sbump((tau - 0.6) / 0.5), sig: 0.45))
        case 1:   // squash and pop: pushed together both squash (0.15) → a beat (0.1) → pop, it joins (0.08), A springs up tall and wobbles two or three times (0.6). Timing as the design board
            let q: Double = Self.sstep(tau / 0.15) * (1 - Self.sstep((tau - 0.25) / 0.06)), push: Double = min(1, tau / 0.15) * (g.gap0 + rb * 0.25)
            tx = g.bx0 + g.ux * push; ty = g.by0 + g.uy * push; qa = 1 - 0.28 * q; qp = 1 + 0.22 * q
            splitSq = (ux: g.ux, uy: g.uy, a: 1 - 0.14 * q, p: 1 + 0.1 * q)
            mass = Self.sstep((tau - 0.25) / 0.08)
            if mass > 0 { tx += (inAx - tx) * mass; ty += (inAy - ty) * mass }
            if tau >= 0.25 && !g.pop { g.pop = true; splitWob = t; onEvent?(.release(gain: 0.6, rate: 1.2, special: false)); voice("gulp", 0.5) }
        case 2:   // a drop and a ripple: a round neck grows between them (0.3) → it flows in (0.3) → ripples run both ways round the outline, two rings on the body (0.5). Timing as the design board
            let nk: Double = Self.sstep(tau / 0.3), push: Double = nk * (g.gap0 + rb * 0.3), v: Double = Self.sstep((tau - 0.3) / 0.3)
            mass = v; tx = g.bx0 + g.ux * push; ty = g.by0 + g.uy * push; tx += (inAx - tx) * v; ty += (inAy - ty) * v
            let p: Double = (tau - 0.6) / 0.5
            if p > 0 && p < 1 {
                let th: Double = Double.pi * Self.sstep(p), am: Double = R * 0.1 * (1 - p) * min(1, p * 6)
                splitPods.append((a: aAng + th, amp: am, sig: 0.3)); splitPods.append((a: aAng - th, amp: am, sig: 0.3))
                g.ring = p
            }
        default:   // swallowed: A opens toward it and wraps round (0.3) → it is a lump inside moving to the middle, eyes shut (0.4) → A blinks happily (0.3). Timing as the design board
            let r: Double = Self.sstep(tau / 0.3), v: Double = Self.sstep((tau - 0.3) / 0.4)
            splitPods.append((a: aAng, amp: R * 0.34 * r * (1 - v), sig: 0.55))
            let near: Double = min(1, tau / 0.3) * max(0, g.gap0 - rb * 0.05)
            tx = g.bx0 + g.ux * near; ty = g.by0 + g.uy * near; tx += (gc.xc - tx) * v; ty += (gc.yc - ty) * v
            mass = Self.sstep((tau - 0.4) / 0.3)
            g.bulge = tau > 0.25 && mass < 0.98 ? 1 - mass : 0
            g.shut = Self.sstep((tau - 0.3) / 0.25)
            if tau > 0.76 && splitHappy < g.t0 { splitHappy = t + 0.18 }
        }
        g.mass = max(g.mass, mass); twSc = max(0, 1 - g.mass).squareRoot(); twQa = qa; twQp = qp; twAx = g.ux; twAy = g.uy
        if !twHide { let k: Double = 1 - exp(-dt / 0.05); twinMove((tx - b.x) * k, (ty - b.y) * k) }
        if g.mass > 0.5 && !g.gul { g.gul = true; if g.fx != 1 { voice("gulp", 0.55) }; onEvent?(.press(gain: 0.3)) }
        if g.mass >= 0.98 { twHide = true }
        if tau >= g.T { mergeEnd() }
    }

    private func mergeEnd() {
        b2On = false; twMg = nil; twHide = false; twFg.removeAll(); splitPods.removeAll(); splitSq = nil; splitMerged += 1
        if params.splitAgain >= 0.5 { splitUsed = false }
        eyeUser = t + 1.2
    }

    /// A rebuilt body starts as one again
    private func twinDrop() {
        b2On = false; twMg = nil; twHide = false; twTouchT = 0; twFg.removeAll(); splitPods.removeAll(); splitSq = nil
        splitK = 1; splitWob = -9; splitUsed = false; splitMx = (1, 0, 0, 1); splitDet = 1; splitDmin = 1
    }

    /// A's size and squash: a world matrix (k × squashed along the touch × the spring up and the wobble) turned into A's reference frame; substep puts it before the performed scaling
    private func splitKStep(_ dt: Double) {
        let tg: Double = splitKTarget()
        splitK += (tg - splitK) * (1 - exp(-dt / 0.12))
        if abs(splitK - 1) < 1e-4 && tg == 1 { splitK = 1 }
        var a00: Double = splitK, a01 = 0.0, a10 = 0.0, a11: Double = splitK
        if let q = splitSq {
            let ax: Double = q.ux, ay: Double = q.uy
            let m00: Double = q.a * ax * ax + q.p * ay * ay, m01: Double = (q.a - q.p) * ax * ay, m11: Double = q.a * ay * ay + q.p * ax * ax
            a00 *= m00; a01 = splitK * m01; a10 = a01; a11 *= m11
        }
        let u: Double = t - splitWob
        if u >= 0 && u < 1.2 {
            let w: Double = 0.13 * exp(-u / 0.22) * cos(2 * Double.pi * 2.8 * u)
            a00 *= 1 - 0.7 * w; a01 *= 1 - 0.7 * w; a10 *= 1 + w; a11 *= 1 + w
        }
        if a00 == 1 && a01 == 0 && a10 == 0 && a11 == 1 { splitMx = (1, 0, 0, 1); splitDet = 1; splitDmin = 1; return }   // not torn, not merging: exactly the identity. Turned there and back it is off by 1e-16 and substep multiplies by an almost-1 matrix every frame (web T42: a random play's jitter 19.9 against v2.61's 8.2)
        let ga: Double = clusters.isEmpty ? 0 : atan2(clusters[gi].sn, clusters[gi].cs), c: Double = cos(ga), s: Double = sin(ga)   // R(−ga)·M·R(ga)
        let b00: Double = a00 * c + a01 * s, b01: Double = -a00 * s + a01 * c, b10: Double = a10 * c + a11 * s, b11: Double = -a10 * s + a11 * c
        let n00: Double = c * b00 + s * b10, n01: Double = c * b01 + s * b11, n10: Double = -s * b00 + c * b10, n11: Double = -s * b01 + c * b11
        splitMx = (n00, n01, n10, n11)
        splitDet = n00 * n11 - n01 * n10
        let sqMin: Double = splitSq.map { min($0.a, $0.p) } ?? 1
        splitDmin = min(1, splitK * sqMin)
    }
    private func splitKTarget() -> Double {
        guard b2On else { return 1 }
        return max(0, 1 - splitFracNow * (1 - (twMg?.mass ?? 0))).squareRoot()
    }
    /// The merge's lumps and ripples on A, on the pseudopods' road (before their area is made up)
    private func twinPods() {
        guard !splitPods.isEmpty, !clusters.isEmpty else { return }
        let ga: Double = atan2(clusters[gi].sn, clusters[gi].cs), rm: Double = reduceMotion ? 0.5 : 1
        for p in splitPods where p.amp > 0 {
            let a: Double = p.a - ga
            podE.append((ca: cos(a), sa: sin(a), amp: p.amp * rm, sig: p.sig, bend: 0))
        }
    }

    /// v2.62 the second slime as drawn (world points): its outline (empty once it has flowed in), its eyes (nil when too small or the eyes are off), the ripple inside A, the lump while swallowed
    struct TwinEyes { let lx, ly, rx, ry, ox, oy, size, open: Double; let squeeze: Bool }
    struct TwinView {
        var outline: [(x: Double, y: Double)] = []
        var eyes: TwinEyes? = nil
        var rings: [(x: Double, y: Double, r: Double, alpha: Double, w: Double)] = []
        var bulge = 0.0
    }

    /// What the skin draws besides the body, in world points: the strand (and the merge's goo) as round-capped segments (full width), the second slime.
    var gooView: (segs: [(x0: Double, y0: Double, x1: Double, y1: Double, w: Double)], twin: TwinView?) {
        var segs: [(x0: Double, y0: Double, x1: Double, y1: Double, w: Double)] = []
        for q in goo where q.k >= 0.03 {
            for i in 0..<(gooN - 1) {
                let w: Double = gooW(q, Double(i) / Double(gooN - 1)) + gooW(q, Double(i + 1) / Double(gooN - 1))
                if w < 0.5 { continue }
                segs.append((q.n[i].x, q.n[i].y, q.n[i + 1].x, q.n[i + 1].y, w))
            }
        }
        guard b2On, twN > 0 else { return (segs, nil) }
        var v = TwinView()
        let g = twMg
        if let g, g.ring > 0, !clusters.isEmpty {   // mergeFx 2: the rings on A's body (drawn clipped to it)
            let gc = clusters[gi], rx: Double = gc.xc + g.rx, ry: Double = gc.yc + g.ry, p: Double = g.ring, w: Double = R * 0.05 * (1 - 0.5 * p)
            v.rings.append((x: rx, y: ry, r: R * (0.15 + 1.5 * p), alpha: 0.55 * (1 - p), w: w))
            let p2: Double = p - 0.25
            if p2 > 0 { v.rings.append((x: rx, y: ry, r: R * (0.15 + 1.5 * p2), alpha: 0.45 * (1 - p2 / 0.75), w: w)) }
        }
        if twHide { return (segs, v) }
        v.outline = twBnd.map { i -> (x: Double, y: Double) in (x: twX[i], y: twY[i]) }
        if let g, g.str > 0 || g.bridge > 0, g.ai >= 0, g.ai < N, g.bi >= 0, g.bi < twN {   // mergeFx 0: the goo, into the same mask
            let pax: Double = X[g.ai], pay: Double = Y[g.ai], pbx: Double = twX[g.bi], pby: Double = twY[g.bi]
            let mx: Double = (pax + pbx) / 2, my: Double = (pay + pby) / 2 + (sillOn ? hypot(pax - pbx, pay - pby) * 0.06 : 0)
            if g.bridge > 0 {   // a quadratic from it to A through the sagging middle, in 8 pieces
                let w: Double = R * 0.13 + twR * 0.75 * g.bridge * (1 - 0.5 * g.mass)
                var lx: Double = pbx, ly: Double = pby
                for s in 1...8 {
                    let u: Double = Double(s) / 8, mu: Double = 1 - u
                    let qx: Double = mu * mu * pbx + 2 * mu * u * mx + u * u * pax, qy: Double = mu * mu * pby + 2 * mu * u * my + u * u * pay
                    segs.append((lx, ly, qx, qy, w)); lx = qx; ly = qy
                }
            } else {
                segs.append((pbx, pby, pbx + (mx - pbx) * g.str, pby + (my - pby) * g.str, R * 0.13))
                segs.append((pax, pay, pax + (mx - pax) * g.str, pay + (my - pay) * g.str, R * 0.13))
            }
        }
        let S: Double = R * params.eyeSize * splitFracNow.squareRoot() * twSc
        if S >= 2 && params.eyes >= 0.5 && !twEL.isEmpty && !twER.isEmpty {
            var lx = 0.0, ly = 0.0, rx = 0.0, ry = 0.0
            for i in twEL { lx += twX[i]; ly += twY[i] }
            for i in twER { rx += twX[i]; ry += twY[i] }
            lx /= Double(twEL.count); ly /= Double(twEL.count); rx /= Double(twER.count); ry /= Double(twER.count)
            let bk: Double = t - twBlinkT < 0.14 ? 0.1 : 1
            var shut: Double = g?.shut ?? 0
            if let g, g.fx != 3 { shut = max(shut, Self.sstep((g.mass - 0.6) / 0.3)) }
            var lkx = 0.0, lky = 0.0
            if let g { lkx = g.ux; lky = g.uy } else if !clusters.isEmpty {   // it looks at A
                let c = twinCenter(), dx: Double = clusters[gi].xc - c.x, dy: Double = clusters[gi].yc - c.y, dl: Double = hypot(dx, dy), l: Double = dl > 0 ? dl : 1
                lkx = dx / l; lky = dy / l
            }
            v.eyes = TwinEyes(lx: lx, ly: ly, rx: rx, ry: ry, ox: lkx * S * 0.03, oy: lky * S * 0.02, size: S, open: bk * (1 - shut), squeeze: twStretch > 1.2 && g == nil)
        }
        v.bulge = g?.bulge ?? 0
        return (segs, v)
    }

    private func tearFinger(_ f: Finger) {
        guard let id = fingers.first(where: { $0.value === f })?.key else { return }
        f.stretch = max(f.stretch, 2)
        release(id, quiet: false)
        onEvent?(.pull(gain: 1, rate: 1))
        onEvent?(.voice(kind: "tear", gain: 1, rate: 1))   // v2.50 the rip (AI sample, manifest voice.tear; silent without the file)
        onEvent?(.fx(kind: "drip", gain: 0.6, delay: 0.35))   // v2.50 the torn-off bit drips
    }
    /// v2.38 home may not be dragged out of the room. The pull (slide) has the whole body follow the finger's real position with no edge: pulled below
    /// the sill or past the frame, home went with it and the finger's effective position counted from there, pressing the body into the corner
    /// (web, pulled to the bottom right: 14 pt tall, 644 pt wide past the frame, 9% of its area, 700 flipped triangles). Home stays where the rest
    /// shape still fits in the room (15% kept for the squash it already has); the clamped axis loses its speed so a release does not fling it.
    private func dragClamp() {
        guard effParams.homeClamp >= 0.5, sillOn, sillPlane == .room, sillG != nil else { return }
        let w0 = worldWalls
        var qb = -1e9, qt = 1e9, ql = 1e9, qr = -1e9
        for i in bnd { qb = max(qb, Q0Y[i]); qt = min(qt, Q0Y[i]); ql = min(ql, Q0X[i]); qr = max(qr, Q0X[i]) }
        let lx = w0.l - ql * 0.85 - homeX, hx = w0.r - qr * 0.85 - homeX, ly = w0.t - qt * 0.85 - homeY, hy = w0.b - qb * 0.85 - homeY
        if lx < hx { if dragOX < lx { dragOX = lx; if dragVX < 0 { dragVX = 0 } } else if dragOX > hx { dragOX = hx; if dragVX > 0 { dragVX = 0 } } }
        if ly < hy { if dragOY < ly { dragOY = ly; if dragVY < 0 { dragVY = 0 } } else if dragOY > hy { dragOY = hy; if dragVY > 0 { dragVY = 0 } } }
    }
    private func dragStep(_ dt: Double) {
        if dragAvg().n == 0 {
            if dragGX != 0 || dragGY != 0 {
                if escOn || gaitOn || introOn { dragGX = 0; dragGY = 0 } else {
                    homeX += dragGX * dt; homeY += dragGY * dt
                    let k = exp(-dt / 0.25)
                    dragGX *= k; dragGY *= k
                    if hypot(dragGX, dragGY) < R * 0.05 { dragGX = 0; dragGY = 0 }
                }
            }
            return
        }
        dragGX = 0; dragGY = 0
        // the body has weight: it catches up in about 0.2 s, so a yank stretches it first
        let g = dragTarget(), e = 1 - exp(-dt / (params.slide > 0 ? 0.2 : 0.25))
        // v2.25 F4: a first-order follow stops dead with the finger and never overshoots; on a spring with inertia, drag it and stop and the whole body runs past a little and comes back
        if params.inertiaHz > 0 && params.dragSpring > 0 {
            // v2.47 dragCalm: a long pull does not run past. The spring overshoots about 16%: 0.16R on a 1R pull, 60 pt on 3.5R, the body jumping for a second with the hand still
            let far: Double = max(0, min(1, (hypot(g.x, g.y) / R - 1) / 2))
            let farS: Double = far * far * (3 - 2 * far)
            let zs: Double = params.dragCalm >= 0.5 ? params.dragSpring + max(0, 1 - params.dragSpring) * farS : params.dragSpring
            let w: Double = 2 * Double.pi * params.dragHz, zz: Double = 2 * (reduceMotion ? max(zs, 0.9) : zs) * w
            dragVX += (w * w * (g.x + dragBX - dragOX) - zz * dragVX) * dt
            dragVY += (w * w * (g.y + dragBY - dragOY) - zz * dragVY) * dt
            dragOX += dragVX * dt; dragOY += dragVY * dt
        } else {
            let nx = dragOX + (g.x + dragBX - dragOX) * e, ny = dragOY + (g.y + dragBY - dragOY) * e
            dragVX = (nx - dragOX) / dt; dragVY = (ny - dragOY) / dt; dragOX = nx; dragOY = ny
        }
        dragClamp()   // v2.38
        for f in fingers.values where f.mode == .grab { f.dragMax = max(f.dragMax, hypot(dragOX - dragBX, dragOY - dragBY)) }   // v2.22 E3: how far this grab led it
        for f in fingers.values where f.mode == .grab { f.sb = params.slide > 0 ? f.stretch : hypot(f.ex - (dragOX - dragBX), f.ey - (dragOY - dragBY)) / R }   // v2.21: the stretch already counts from where it followed to
        // C3: very wary, pulled open 1R or more for 1.5 s, the patch slips from the finger and it slinks off a little
        // (v2.63 D3 holdScared 1: it no longer slips; it protests and squeezes its eyes instead, and walks off when let go, in release)
        if iv2(params.impC3) && impWary > 0.5 {
            var st = 0.0
            var g: Finger?
            for f in fingers.values where f.mode == .grab && bodyStretch(f) > st { st = bodyStretch(f); g = f }
            dragSlipT = st > 1 ? dragSlipT + dt : 0
            if let g, dragSlipT > 1.5, params.holdScared >= 0.5 {   // v2.63 D3 (web: the same line): not slipping; a protest, the eyes > < (very wary they are wide already); again every 1.5 s still held; the wariness only the first time this grab
                dragSlipT = 0
                if !g.scared { g.scared = true; impWary = min(1, impWary + 0.05) }
                eyeSqU = max(eyeSqU, t + 0.6)
                voiceLast = -9; voice("protest")
            } else if let g, dragSlipT > 1.5 {
                inertiaCatch()
                for m in g.mem { GRAB[m.i] = false }
                g.mem = []; g.mode = .none; lastTouch = t; lastReleaseStrength = 0.8
                onEvent?(.release(gain: 0.8, rate: 1.05, special: false))
                dragRelease(glide: true); impWary = min(1, impWary + 0.05)
                if params.emo >= 0.5 { flee(-pullDX, -pullDY, W * 0.22 * params.flee) }
            }
        }
    }
    /// D2: the dent's own recovery (多米 build 75: a tap's dent took too long to go; measured 14 s to half, though the shape itself had
    /// only moved 0.02R). Pressed longer it goes slower (2.5× at 1 s or more); exponential, 2% left at `dentFade` s. 10 or more: v2.19
    private func dentRate(_ dn: Dent) -> Double {
        guard params.dentFade < 9.95 else { return 0 }
        return 4 / (params.dentFade * (1 + 1.5 * smooth01((dn.held - 0.3) / 0.7)))
    }
    /// v2.20: the app was in the background 10 min or more: first meeting again.
    func resetImpression() { impTrust = 0; impWary = 0; impHas = false; impAskUntil = -9; impBond = 0; sooOn = false; sooG = 0; sooOK = false }   // v2.63 D6 (web impReset): the bond and soothing too
    /// At release, what kind of grab it was goes into the impression: pulled until it wanted to flee, poked in a row, flung hard → wary;
    /// a gentle one takes a fifth of the wariness off (C5 calming). Before moodRelease (which clears strainMax).
    private func impRelease(_ f: Finger) {
        memTouch(f)   // v2.64 記地方 (web impRelease: memTouch(f) first, whether or not the impression is on)
        guard params.imp >= 0.5 else { return }
        impLX = f.fx; impLY = f.fy; impHas = true
        let w0 = impWary
        let quick = t - f.tDown < 0.25 && f.stretch < 0.3, nTaps = taps.filter { t - $0 < 1 }.count + 1
        let rough: Bool = roughOn, hard: Bool = rough && f.vMax >= RoughSet.v, fling: Bool = !rough && f.peak / R > 6   // v2.61 D1 (rough): hard = the hand was fast once this grab; a fling adds no wariness of its own
        let tapW: Double = nTaps >= 3 ? 0.2 : (params.tapSoft >= 0.5 ? 0 : 0.04)   // v2.61 D2 (tapSoft): fewer than three a second add none
        if moodStrainMax > 0.15 { if !rough { impWary += 0.15 + 0.25 * moodStrainMax; impTrust -= 0.15 } }   // v2.61 D1: yanked it still runs (moodRelease); wariness and trust stay put
        else if quick { impWary += tapW; if nTaps >= 3 { impTrust -= 0.1 } }
        else if fling { impWary += 0.1; impTrust -= 0.05 }
        else { if !(rough && f.yank) { impWary *= 0.8 }; if iv3(params.e3) && f.dragMax > R * 0.5 && !hard { impTrust += 0.12 } }   // v2.22 E3: led along gently, a little more trust
        if impWary > w0 { impWary = w0 + (impWary - w0) * params.wRate }   // v2.23 personality: how fast it turns wary
        if impWary > w0 + 1e-9 && bondOn { sooOK = false }   // v2.63 D6: scared again, it needs soothing again
        impTrust = max(0, min(1, impTrust)); impWary = max(0, min(1, impWary))
    }
    /// v2.63 D6 (bond; web bondTouch): a grab coming down: is it a high bond's first touch? More than BondSet.gap s since the last hold, not wary,
    /// and this touch set off a flinch: k eased over the bond lo...hi, kept in flBk for the flinch's frame
    private func bondTouch(_ x: Double, _ y: Double) {
        guard bondOn else { return }
        let first: Bool = !(t - bondLastT <= BondSet.gap && bondLastT <= t)
        bondLastT = t
        let k: Double = first && impWary < 0.4 && flAt > t && flAt == flTapAt ? smooth01((impBond - BondSet.lo) / (BondSet.hi - BondSet.lo)) : 0
        flBk = k
        if k > 0 { flBX = x; flBY = y }
    }
    /// v2.63 D6 (bond; web sooStep): very wary, a gentle hand soothes it first. gentle = a gentle hand this frame; true = no comfort and no purr
    /// this frame (moodStep). After SooSet.T s of it, a sigh (the one after a rub), then as usual
    private func sooStep(_ dt: Double, gentle: Bool) -> Bool {
        guard bondOn else { sooOn = false; return false }
        if impWary <= SooSet.w { sooOK = false }
        if !sooOn && !sooOK && impWary > SooSet.w && gentle { sooOn = true; sooG = 0 }
        guard sooOn else { return false }
        if gentle { sooG += dt }
        if sooG < SooSet.T { return true }
        sooOn = false; sooOK = true
        if lv(effParams.lifeBreath) && sighCyc < 0 { sighCyc = Int(floor(brPhase)) + 1 }
        if !slpOn { onEvent?(.fx(kind: "sigh", gain: 0.45, delay: 0)) }
        return false
    }
    /// C4 begging: released after a purr (the happy hop), 0.9 s later it reaches toward where your finger left and edges over if far;
    /// touched again within 5 s, the purr comes fast (touchBegan).
    private func impAsk(_ f: Finger) {
        guard iv2(params.impC4), !escOn, !slpOn, impTrust >= 0.2, f.gentleT > 1, moodC > 0.35, fingers.isEmpty else { return }
        impAskUntil = t + 5; attOn = false; askOn = true; askAt = t + 0.9; askX = f.fx; askY = f.fy
    }
    /// Every frame: stroking, purring and a gentle drag build trust (20...25 s of stroking to very trusting); wariness halves in 3 min.
    /// Trust does not fade with time (it does not cool off because you were away).
    private func impStep(_ dt: Double) {
        guard params.imp >= 0.5 else { return }
        let tr0 = impTrust   // v2.63 D6
        var g: Finger?
        for f in fingers.values where f.mode == .grab { if g == nil || bodyStretch(f) > bodyStretch(g!) { g = f } }
        if let g {
            let st = bodyStretch(g), sp = hypot(g.vxS, g.vyS) / R
            let e3m: Double = (iv3(params.e3) ? 3 : 1) * params.trRate   // v2.22 E3: trust grows three times faster (5 s of stroking shows); v2.23 personality
            if g.gentleT > 1 { impTrust += (0.04 + 0.04 * purr) * dt * e3m; impWary -= 0.05 * dt * e3m }
            else if st < 1.2 && sp > 0.3 && sp < 3 && moodStrain < 0.05 && hypot(dragOX, dragOY) > R * 0.3 {
                let hard: Bool = roughOn && g.vMax >= RoughSet.v   // v2.61 D1 (rough): led along gently only
                if !hard { impTrust += 0.02 * dt * e3m }
            }
        } else if stkG > 1 && t - stkLast < 0.05 {   // v2.26 F6: strokes build trust too
            let e3m: Double = (iv3(params.e3) ? 3 : 1) * params.trRate
            impTrust += (0.04 + 0.04 * purr) * dt * e3m; impWary -= 0.05 * dt * e3m
        }
        if petOn && t - petLast < 0.05 {   // v2.61 C3 (petSlow): slow strokes build trust too (not on a frame the rub or the stroke above already counted); the wariness stays put
            let rubbed: Bool = (g?.gentleT ?? 0) > 1
            let stroked: Bool = g == nil && stkG > 1 && t - stkLast < 0.05
            if !rubbed && !stroked {
                let e3m: Double = (iv3(params.e3) ? 3 : 1) * params.trRate
                impTrust += (0.04 + 0.04 * purr) * dt * e3m
            }
        }
        if bondOn {   // v2.63 D6 (bond; web: the same line): trust full and still treated gently, the bond grows slowly; it only goes up
            if g != nil { bondLastT = t }
            if tr0 >= BondSet.full && impTrust > tr0 { impBond = min(1, impBond + BondSet.rate / 60 * dt) }
        }
        impWary *= exp(-dt / (260 * (params.wFade > 0 ? params.wFade : 1)))   // v2.57 wFade: 布丁 is scared easily and forgets fast
        impTrust = max(0, min(1, impTrust)); impWary = max(0, min(1, impWary))
        let ks = 1 - exp(-dt / 1)
        impShownTrust += (impTrust - impShownTrust) * ks; impShownWary += (impWary - impShownWary) * ks
    }
    /// Walk to a point (C1 swimming over or backing off, C4 edging over): goStart's gait (the pulse; with it off, v2.18's glide).
    private func gaitTo(_ x: Double, _ y: Double, dash: Bool) {
        var x = x, y = y
        if sillOn {   // v2.28 窗台: along the sill only; not in the air, mid-hop or on a route; v2.30 from inside the bowl it climbs out first
            if sillRoute != nil || sillAir || sillHop != nil || sillTanV { return }
            x = sillClampX(x); y = homeY
            if sillInBowl { if !clusters.isEmpty && abs(x - clusters[gi].xc) > R * 0.5 { routeStart(rtOutFront(x)) }; return }
        }
        lifeSt = .go; wanderSX = homeX; wanderSY = homeY; wanderX = x; wanderY = y; wanderMoving = true
        if lv(params.lifeGait) {
            gaitOn = true; gaitTX = x; gaitTY = y; gaitDash = dash; gaitClimb = false; gaitPh = -1; gaitPrep = 0; gaitV = 0
            gaitH = atan2(y - homeY, x - homeX); gaitK = 1; gaitStr = 1; gaitLast = false; gaitOff = 0
        } else {
            wanderT = max(0.5, hypot(x - homeX, y - homeY) / (params.wander * (dash ? 2.5 : 1) * R * (reduceMotion ? 0.25 : 1))); wanderP = 0
        }
    }
    /// C1 C2: of the fingers that landed on empty space, the nearest within 3.5R of the body.
    private func lureFinger() -> Finger? {
        var best: Finger?
        var bd = 1e9
        for f in fingers.values where f.lure && f.mode == .push {
            var d = 1e9
            for i in bnd { d = min(d, hypot(X[i] - f.fx, Y[i] - f.fy)) }
            if d < R * 3.5 && d < bd { bd = d; best = f }
        }
        best?.edge = bd
        return best
    }
    private func lureEnd() {
        lureOn = false; lureSn = -1; cutSniffs()
        if lifeSt == .go || lifeSt == .look { gaitOn = false; wanderMoving = false; lifeSt = .rest; lifeUntil = t + restDur() }
    }
    private enum LureMode { case come, back, look }
    /// true: the finger has this frame, no rest or look decisions. Trusting (over 0.25 and 0.1 above wary) it swims over and touches your
    /// finger, very trusting (0.7) it nestles and rubs; wary the other way round, it backs off and points at you; neither, it just turns and sniffs.
    private func lureStep(_ dt: Double) -> Bool {
        let on1 = iv2(params.impC1), on2 = iv2(params.impC2)
        if !on1 && !on2 { if lureOn { lureEnd() }; return false }
        guard let f = lureFinger(), !escOn, !introOn, !clusters.isEmpty else { if lureOn { lureEnd() }; return false }
        let fid = fingers.first(where: { $0.value === f })?.key
        if !lureOn || lureID != fid {
            lureOn = true; lureID = fid; lureT0 = t; lureStillT = 0; lurePounced = false; lureTouched = false
            lureTouchT = -9; lureStartle = -9; lureSn = -1; lureRub = 0; lureBacked = false
        }
        let sp = hypot(f.vxS, f.vyS) / R, dx = f.fx - clusters[gi].xc, dy = f.fy - clusters[gi].yc, dist = max(1e-6, hypot(dx, dy))
        let ux = dx / dist, uy = dy / dist, ang = atan2(dy, dx), rm = reduceMotion ? 0.5 : 1.0
        lureStillT = sp < 0.3 ? lureStillT + dt : 0
        if sp > 0.6 { lurePounced = false }
        let mode: LureMode = impTrust > 0.25 && impTrust - impWary > 0.1 ? .come : (impWary > 0.2 && impWary - impTrust > 0.1 ? .back : .look)
        // C2 a fast swipe: when not trusting, a start (the flinch, pseudopods in) and a little warier
        if on2 && sp > 4 && mode != .come && t - lureStartle > 1 {
            lureStartle = t; flAt = t; flPre = .rest; impWary = min(1, impWary + 0.02); cutSniffs(); lureSn = -1
        }
        if t - lureT0 < 0.3 || t - lureStartle < 0.6 { return true }   // turns after 0.3 s (A7's timing); after a start it holds still a moment
        let track = on2 || lureStillT > 0.2, edgeR = f.edge / R
        // the pseudopod pointing at the finger: none yet → one out (held until the finger goes), else turned toward it (C2 follows);
        // its length by mode, trusting and close enough it reaches the finger
        let L: Double = mode == .back ? 0.35 : (mode == .come && edgeR < 1.1 ? min(1.4, edgeR + 0.12) : min(params.podLen * 1.1, max(0.3, edgeR * 0.6)))
        if let k = sniffs.firstIndex(where: { $0.id == lureSn }) {
            if track { sniffs[k].a += atan2(sin(ang - sniffs[k].a), cos(ang - sniffs[k].a)) * (1 - exp(-dt / 0.15)) }
            sniffs[k].L += (L - sniffs[k].L) * (1 - exp(-dt / 0.3))
        } else if track {
            lureSn = startSniff(ang, L, 0.5, 1e4, 0.6).id
        }
        switch mode {
        case .come:
            let close = impTrust > 0.7 ? 0.85 : 1.25, move = (on1 && lureStillT > 0.6) || (on2 && sp > 0.3)
            if dist > R * (close + 0.35) && move {
                let tx = f.fx - ux * R * close, ty = f.fy - uy * R * close
                if gaitOn || wanderMoving { gaitTX = tx; gaitTY = ty; wanderX = tx; wanderY = ty } else { gaitTo(tx, ty, dash: edgeR > 2) }
            }
            // C2 pounce: the finger stopped 0.25 s, 0.3R...1.6R off the edge: it stops walking, a pseudopod shoots out, the body lunges a little
            if on2 && !lurePounced && lureStillT > 0.25 && edgeR > 0.3 && edgeR < 1.6 {
                lurePounced = true; gaitOn = false; wanderMoving = false; gaitK = 1
                lureSn = startSniff(ang, min(1.6, edgeR + 0.15), 0.18, 0.6, 0.5).id
                moveHome(ux * R * 0.25 * rm, uy * R * 0.25 * rm, dt)
            }
            // it reached your finger (the push finger's hitT; the soft tap is the .nudge in substep): a little more trust, a little
            // less wariness; very trusting, it nestles against it and rubs side to side
            if t - f.hitT < 0.1 {
                if !lureTouched { lureTouched = true; lureTouchT = t; impTrust = min(1, impTrust + 0.05) }
                impWary = max(0, impWary - 0.03 * dt)
                if impTrust > 0.7 && lureStillT > 0.3 && !gaitOn {
                    let o = R * 0.06 * rm * sin(2 * .pi * 0.7 * (t - lureTouchT)), d = o - lureRub
                    lureRub = o; moveHome(-uy * d, ux * d, dt)
                }
            }
        case .back:
            if !lureBacked && dist < R * 2.6 && !gaitOn { lureBacked = true; gaitTo(f.fx - ux * R * 3, f.fy - uy * R * 3, dash: false) }
        case .look:
            break
        }
        if !gaitOn && !wanderMoving && lifeSt != .arrive { lifeSt = .look }
        return true
    }

    // MARK: - v2.22 voice (E1), every action answered (E2), the impression shows (E3), comes to say hello (E4)

    /// E1: one of its small sounds; trusting a little higher, wary lower; at most one every 0.3 s.
    private func voice(_ kind: String, _ g: Double = 0.8, at: Double? = nil) {
        guard iv3(params.e1), t - voiceLast >= 0.3 else { return }
        voiceLast = t
        let r: Double = (1 + 0.1 * impTrust - 0.08 * impWary) * Double.random(in: 0.96..<1.04, using: &rng) * params.voicePitch
        if let at, at > t, params.sndB5 >= 0.5 { flSay = FlSay(at: at, kind: kind, gain: g, rate: r); return }   // v2.63 B5 (web voice(kind, g, at)): `at` is the flinch (flAt); the sound waits for that frame
        onEvent?(.voice(kind: kind, gain: g, rate: r))
    }
    /// v2.63 B2 (web pressForce, B2K): the press sound from how hard the finger landed: the 3D Touch force where there is one, else the contact
    /// size (majorRadius 18 pt a fingertip … 42 pt a flat pad), 0.35 … 0.95; neither → 0.7 as before.
    private enum B2Set { static let lo = 0.35, hi = 0.95, rLo = 18.0, rHi = 42.0 }
    private func pressForce(force: Double, radius: Double) -> Double {
        var k = -1.0
        if force > 0 { k = force } else if radius > 1.5 { k = (radius - B2Set.rLo) / (B2Set.rHi - B2Set.rLo) }
        return k < 0 ? 0.7 : B2Set.lo + (B2Set.hi - B2Set.lo) * max(0, min(1, k))
    }
    private func firstGrab() -> Finger? { fingers.values.first { $0.mode == .grab } }
    /// E1: pulled until it wants to flee → "mm-mm"; purring → "mmm~" (once a grab each).
    private func e1Step() {
        guard iv3(params.e1) else { return }
        guard let g = firstGrab() else {
            if purr > 0.3 && stkG > 1 && !stkSaid && t - stkLast < 0.6 {   // v2.26 F6
                stkSaid = true
                if !(petOn && petSaid) { voice("mmm", 0.6) }   // v2.61 C3: one hum a spell of slow strokes, not one each
                if petOn { petSaid = true }
            }
            return
        }
        if moodStrain > 0.5 && !g.saidProt { g.saidProt = true; voice("protest") }
        if purr > 0.3 && !g.saidPurr {
            g.saidPurr = true
            if !nuzSaid && !(petOn && petSaid) { voice("mmm", 0.6) }   // already nuzzling and hummed: not again; v2.61 C3: nor within one spell of slow strokes
            if petOn { petSaid = true }
        }
    }
    /// E2 a tap (under 0.25 s, not pulled): after the flinch it leans toward your finger and says "pu"; wary, it leans away.
    private func e2Release(_ f: Finger) {
        guard iv3(params.e2), !slpOn, t - f.tDown < 0.25, f.stretch < 0.3, !clusters.isEmpty else { return }   // v2.61 C1: !slpOn (and in impAsk)
        let bm = brainM   // v2.63 心情: in a bad mood it leans away, in a good one it wags too (a poke is play)
        leanT = t + 0.3; leanA = atan2(f.fy - clusters[gi].yc, f.fx - clusters[gi].xc); leanS = impWary > 0.4 || bm < -0.35 ? -1 : 1; if bm > 0.35 { wagT = t + 0.35 }; voice("poke", 0.7)
        if params.tapBack >= 0.5 { tbArm(f) }   // v2.64 D8：傾完再頂回來
    }

    // MARK: v2.64 D8 點牠牠頂回來、呼嚕時慢眨眼（tapBack、slowBlink；規劃 .uiux/04-手感/極致優化規劃-暫定.md 的 D8，BATCH3 第 4 項；網頁 TB、TBK、tbArm、tbStep、SBL、SBLK、sblRnd、sblStep）
    // 原本點一下傾一下就結束。
    // tapBack：點一下（E2 那一下：0.25 秒內、沒拉開）之後牠朝你的手指傾一下（放手後 0.3 秒起、0.7 秒），傾完再過 TBK.gap 秒，朝你剛才點的地方再頂一下
    //   （跟「按著不動往手指推一下」同一套：E2 那一傾加 .nudge，手機輕頂一下），同時看著你 TBK.look 秒（eyeUser）；在休息就多待這 1.5 秒不換事情。
    //   你不接就算了：不改戒、熟、交情、心情，什麼都不記。等的那段你又碰牠（手指按著、碰到身體）就不頂，照現有的回應走；看著你那 1.5 秒裡再碰也一樣，沒有另外的獎勵。
    //   只在牠朝你傾的時候排（戒的往反方向傾那種不頂）；睡著、在逃（連點三下）、開場、窗台上在走路線或在空中不頂。
    // slowBlink：呼嚕（purr > 0.3，跟眼睛 ∩ 同一條線）累計 sblGap 秒（SBLK.lo 到 hi，自己那串亂數抽）就慢眨一次：∩ 先換回半睜（SBLK.lid）、看一下，
    //   慢慢閉上、閉著停一下、慢慢睜開，再回 ∩。只用既有的眼睛形狀（睜開的橢圓、閉著的一條線）；中間被擠成 > <、睡著就停掉。慢眨那段不跑平常的眨眼（也不抽它的亂數）。
    // 兩顆都 0：不排、不畫，跟改之前一樣。rng 一個都不多抽（sblRnd 是自己那串，從大腦的種子接）。
    private enum TBK { static let gap = 0.4, look = 1.5 }
    /// pre 半睜、see 看一下、close 慢慢閉、hold 閉著、reopen 慢慢睜（網頁 SBLK.open）、post 再睜一下回 ∩（秒）；lid 慢眨時睜多開；lo、hi 呼嚕累計幾秒眨一次
    private enum SBLK { static let lo = 6.0, hi = 12.0, pre = 0.3, see = 0.5, close = 0.5, hold = 0.5, reopen = 0.6, post = 0.4, lid = 0.8 }
    /// 網頁 tbArm：E2 點一下排好頂回來（傾完再 TBK.gap 秒）
    private func tbArm(_ f: Finger) {
        if leanS < 0 || escOn || slpOn { return }
        tbAt = leanT + 0.7 + TBK.gap; tbRel = t; tbX = f.fx; tbY = f.fy; tbUntil = -9
    }
    /// 網頁 tbStep：每幀（e2Step 後面）。到時間就頂、看著你；你又碰就取消
    private func tbStep() {
        guard params.tapBack >= 0.5 else { tbAt = -9; tbUntil = -9; return }
        if tbRel > t || tbAt > t + 5 || tbUntil > t + 5 { tbAt = -9; tbUntil = -9 }   // 時鐘倒回去（重建）
        if tbUntil > t && (!fingers.isEmpty || lastTouch > tbFire) { tbUntil = -9 }   // 看著你的時候你又碰：照現有的回應走，不另外給什麼
        if tbAt < 0 || t < tbAt { return }
        tbAt = -9
        if !fingers.isEmpty || lastTouch > tbRel || escOn || slpOn || introOn || !iv3(params.e2) || (sillOn && (sillRoute != nil || sillAir)) { return }
        guard clusters.indices.contains(gi) else { return }
        let a = atan2(tbY - clusters[gi].yc, tbX - clusters[gi].xc)
        leanT = t; leanA = a; leanS = 1; onEvent?(.nudge)   // 網頁 E2.nudgeT = t（手機輕頂一下）
        tbFire = t; tbUntil = t + TBK.look; eyeUser = max(eyeUser, tbUntil)
        if lifeSt == .rest { lifeUntil = max(lifeUntil, tbUntil) }
    }
    /// 網頁 sblRnd：(seed·1664525 + 1013904223) mod 2³²
    private func sblRnd() -> Double {
        sblS = sblS &* 1_664_525 &+ 1_013_904_223
        return Double(sblS) / 4_294_967_296
    }
    /// 網頁 sblStep：eyeStep 每幀叫（mode 是這一格本來的表情）；回傳慢眨這一格的眨眼量（1 睜、0 閉），沒在慢眨回 nil
    private func sblStep(_ dt: Double, _ mode: EyeMode) -> Double? {
        if sblT0 > t { sblT0 = -9 }
        if sblT0 >= 0 {
            let u = t - sblT0
            if u >= SBLK.pre + SBLK.see + SBLK.close + SBLK.hold + SBLK.reopen + SBLK.post || mode == .squeeze || mode == .sleep || slpOn { sblT0 = -9; return nil }
            var v = u
            if v < SBLK.pre { return smooth01(v / SBLK.pre) }; v -= SBLK.pre
            if v < SBLK.see { return 1 }; v -= SBLK.see
            if v < SBLK.close { return 1 - smooth01(v / SBLK.close) }; v -= SBLK.close
            if v < SBLK.hold { return 0 }; v -= SBLK.hold
            if v < SBLK.reopen { return smooth01(v / SBLK.reopen) }
            return 1
        }
        if purr > 0.3 && mode == .happy && !slpOn {
            sblAcc += dt
            if sblAcc >= sblGap { sblAcc = 0; sblGap = SBLK.lo + (SBLK.hi - SBLK.lo) * sblRnd(); sblT0 = t; return 0 }
        }
        return nil
    }
    // MARK: v2.64 C8 十隻各一個招牌動作、一個喜歡的位置（signature；規劃 .uiux/04-手感/極致優化規劃-暫定.md 的 C8，BATCH3 第 5、5b 項；網頁 SG、SGK、SGDEF、sgRnd、sgDef、sgGap、sgCut、
    // sgFavX、sgHomeFav、sgLid、sgPod、sgShrink、sgFire、sgStep，逐行照搬）。
    // 表在 .uiux/04-手感/十隻招牌-暫定.md：隻名、個性、招牌、多久一次、喜歡的位置，全是 Agent 取的，賣六隻之前要多米看過才定。
    // 招牌動作：醒著、沒人碰、在休息或張望的時間累計到 sgGap 秒（每隻自己的範圍 lo 到 hi，自己那串亂數抽；打開後第一次減半），等下一個「休息」的空檔做一次。
    //   只用現成的動作換節奏、幅度、方向：偽足（startSniff；疊上去的短偽足 sgPod，跟 ltTap 同一種）、朝一邊傾（leanT）、搖偽足（wagT）、整團轉著抖（shkAt，甩一甩那套）、
    //   縮一下（flAmp、flT0 那段形狀，sgShrink）、眼睛看你（eyeUser）、眨眼、半閉（要睡了那個 0.45）、閉上（睡著那條線）、睜大（eyePulse）、快跑（gaitTo dash）、嘆一口氣（sighNext）、叫聲（既有的 mmm）。
    //   做到一半被碰、睡著、在逃、手指放旁邊、來找你、被別的事拉走，就收掉（不補做）。
    // 喜歡的位置（fav）：窗台五格（記地方那五格）的第幾格；走得到的是 1（左，蠟燭旁）、2（中，布墊）、3（右，罐子和風鈴下）。
    //   只取代 memHomeX 裡「沒有特別喜歡的時候回布墊」那一步：你摸出來的喜歡、夜晚蠟燭照舊優先；那格被嚇過（< −0.3）就不去。喜歡布墊的三隻（蜜蜜、芋圓、桃桃）家跟原本一樣。
    //   大腦想走的時候（brainGo）有 SGK.go（六成，自己那串亂數）直接走回那格；家是天生喜歡那格、離開超過 20 秒時，大腦挑到張望也先走回去（brainRest .look，第 5b 項）。
    // 亂數只用自己那串（sgRnd，從大腦的種子接）；動作本身用到的現成函式（startSniff 的相位、voice、走路）照它們原本的抽法。
    // signature 0：不累計、不做、不抽亂數，家照舊，跟改之前一樣。網頁的計數（SG.n、SG.log，給 T89 和「牠在想什麼」用）手機沒搬。
    private enum SgKind { case stretch, dash, peek, sway, lounge, doze, wings, fizz, jitter, reach }
    /// k 招牌、name 名字（大腦在做什麼那一行）、fav 喜歡那格（0 到 4）、lo 到 hi 多久一次（秒）、wake 醒來先做一次（蜜蜜）
    private struct SgDef { let k: SgKind; let name: String; let fav: Int; let lo, hi: Double; var wake = false }
    /// 網頁 SGDEF（鍵是 SlimeKind 的 rawValue，跟網頁 SLIMES 的 id 同名）
    private static let sgDefs: [String: SgDef] = [
        "honey": SgDef(k: .stretch, name: "伸懶腰", fav: 2, lo: 30, hi: 45, wake: true),
        "mint": SgDef(k: .dash, name: "衝過去又衝回來", fav: 1, lo: 25, hi: 40),
        "taro": SgDef(k: .peek, name: "偷看你一眼就躲", fav: 2, lo: 35, hi: 55),
        "peach": SgDef(k: .sway, name: "撒嬌扭兩下", fav: 2, lo: 35, hi: 55),
        "xiancao": SgDef(k: .lounge, name: "單邊撐著發呆", fav: 1, lo: 40, hi: 60),
        "tangyuan": SgDef(k: .doze, name: "打瞌睡、抖一下醒來", fav: 1, lo: 30, hi: 45),
        "diedou": SgDef(k: .wings, name: "兩條偽足像翅膀開合", fav: 3, lo: 35, hi: 55),
        "qishui": SgDef(k: .fizz, name: "冒泡", fav: 3, lo: 20, hi: 35),
        "buding": SgDef(k: .jitter, name: "左右張望再抖一下", fav: 1, lo: 35, hi: 55),
        "zhennai": SgDef(k: .reach, name: "伸去拿罐子、嚼嚼", fav: 3, lo: 35, hi: 55),
    ]
    /// go：大腦想走的時候，直接走回喜歡那格的機率（網頁 SGK.go）
    private enum SGK { static let go = 0.6 }
    /// 正在做的那一段（網頁 SG.on）：t0 開始、end 排好的步驟最晚那一步（快跑那種）或做完（其他）、until 最晚到幾秒就收掉
    private struct SgRun { let k: SgKind; let t0: Double; var end: Double; let until: Double }
    /// 一個步驟裡要做的事（網頁 sgFire 裡 on(...) 的那些小函式）
    private enum SgAct {
        case sniff(Double, Double, Double, Double, Double)   // startSniff(a, L, T1, T2, T3)
        case pod(Double, Double, Double, Double, Double)     // sgPod(a, L, T1, T2, T3)
        case eyeHalf(Double)          // SG.eye = half，T 秒
        case eyeDoze(Double, Double)  // SG.eye = doze，c 秒慢慢閉上，到 T 秒
        case eyeOff                   // SG.eye = null
        case sigh                     // if(BRX.sighCyc<0)BRX.sighNext=t
        case gait(Double)             // gaitTo(x, HOMEY, true)
        case user(Double)             // EYE.user = t + d
        case wag(Double)              // MOOD.wagT = t + d
        case blink                    // EYE.blinkT = t
        case pulse                    // EYE.pulse = t
        case lean(Double)             // E2.leanT = t; E2.leanA = a; E2.leanS = 1
        case voice(String, Double)    // voice(k, g)
        case shrink(Double)           // sgShrink(k)
        case shake(Double)            // SHK.at = t; SHK.amp = amp
    }
    /// at 幾秒做、w 要等走到了（回到休息）才做（網頁 w）
    private struct SgStep { let at: Double; let w: Bool; let acts: [SgAct] }
    /// 網頁 SG.eye：half 半閉 0.45；不是 half 就是 doze（c 秒慢慢閉上，閉著到 T 秒）
    private struct SgEye { let half: Bool; let t0, c, T: Double }

    /// 網頁 sgRnd：(seed·1664525 + 1013904223) mod 2³²
    private func sgRnd() -> Double {
        sgS = sgS &* 1_664_525 &+ 1_013_904_223
        return Double(sgS) / 4_294_967_296
    }
    private func sgDef() -> SgDef? { Self.sgDefs[sgId] }
    /// 網頁 sgGap：這次要累計幾秒（第一次減半）；沒有招牌的那隻 9e9
    private func sgGapRnd(_ first: Bool) -> Double {
        guard let d = sgDef() else { return 9e9 }
        return (d.lo + (d.hi - d.lo) * sgRnd()) * (first ? 0.5 : 1)
    }
    private func sgCut() { sgOn = nil; sgQ = []; sgEye = nil }
    /// 網頁 sgFavX：窗台上牠天生喜歡那格的位置；喜歡布墊的回 nil（照原本那條路走）
    private func sgFavX() -> Double? {
        guard params.signature >= 0.5, sillOn, let g = sillG, let d = sgDef(), d.fav != 2 else { return nil }
        return memCellX(g, d.fav)
    }
    /// 網頁 sgHomeFav：家就是牠天生喜歡的那格（不是你摸出來的、不是夜晚蠟燭、那格沒被嚇過）
    private func sgHomeFav() -> Bool {
        guard let x = sgFavX(), let g = sillG else { return false }
        return memHomeX(g) == x
    }
    /// 網頁 sgLid：這一格眼睛最多睜多開；沒在半閉、打瞌睡回 nil
    private func sgLid() -> Double? {
        guard let e = sgEye else { return nil }
        let u = t - e.t0
        if u < 0 || u > e.T { sgEye = nil; return nil }
        if e.half { return 0.45 }
        return u < e.c ? 1 - smooth01(u / e.c) : 0   // doze：c 秒慢慢閉上，閉著到 T 秒
    }
    /// 網頁 sgPod：疊上去的偽足，不收掉正在探的那條、rng 不抽（跟 ltTap 同一種）
    private func sgPod(_ a: Double, _ L: Double, _ T1: Double, _ T2: Double, _ T3: Double) {
        sniffSeq += 1
        sniffs.append(Sniff(a: a, L: L, t0: t, T1: T1, T2: T2, T3: T3, ph: 0, id: sniffSeq))
    }
    /// 網頁 sgShrink：只借「縮一下」的形狀（60 毫秒縮、半秒放），不算被嚇：不累習慣、不喘、不出聲、不收偽足
    private func sgShrink(_ k: Double) { flAmp = k * params.flinchAmp * (reduceMotion ? 0.5 : 1); flT0 = t }
    private func sgDo(_ a: SgAct) {
        switch a {
        case let .sniff(an, L, T1, T2, T3): startSniff(an, L, T1, T2, T3)
        case let .pod(an, L, T1, T2, T3): sgPod(an, L, T1, T2, T3)
        case let .eyeHalf(T): sgEye = SgEye(half: true, t0: t, c: 0, T: T)
        case let .eyeDoze(c, T): sgEye = SgEye(half: false, t0: t, c: c, T: T)
        case .eyeOff: sgEye = nil
        case .sigh: if sighCyc < 0 { sighNext = t }
        case let .gait(x): gaitTo(x, homeY, dash: true)
        case let .user(d): eyeUser = t + d
        case let .wag(d): wagT = t + d
        case .blink: eyeBlinkT = t
        case .pulse: eyePulse = t
        case let .lean(an): leanT = t; leanA = an; leanS = 1
        case let .voice(k, g): voice(k, g)
        case let .shrink(k): sgShrink(k)
        case let .shake(amp): shkAt = t; shkAmp = amp
        }
    }
    /// 網頁 sgFire：排好這一隻招牌的步驟
    private func sgFire(_ d: SgDef) {
        guard clusters.indices.contains(gi) else { return }
        let g: SillGeo? = sillOn ? sillG : nil
        let qx = clusters[gi].xc, qy = clusters[gi].yc, P = Double.pi   // 網頁 globalC.xc、yc
        let side: Double
        if let g { side = qx >= g.bx ? 1 : -1 } else { side = qx >= cx ? 1 : -1 }   // 網頁 CX：畫面中間
        var q: [SgStep] = [], end = t, T = 0.0
        func on(_ at: Double, _ acts: [SgAct], _ w: Bool = false) { q.append(SgStep(at: t + at, w: w, acts: acts)); end = max(end, t + at) }
        switch d.k {
        case .stretch:   // 往上慢慢伸長、半閉眼，伸到頂嘆一口氣
            on(0, [.sniff(-P / 2, 0.95, 1.6, 1, 1.4), .eyeHalf(4)]); on(1.8, [.sigh]); T = 4.4
        case .dash:   // 快跑到另一頭、到了馬上快跑回來
            let x0 = qx
            let tx: Double
            if let g { tx = sillClampX(side > 0 ? g.l + R * 0.9 : g.r - R * 0.9) } else { tx = homeX - side * R * 1.2 }
            on(0, [.gait(tx)]); on(0.5, [.gait(x0)], true); on(0.6, [], true); T = 12
        case .peek:
            if impTrust >= 0.6 { on(0, [.user(1.6), .wag(0.2)]); T = 1.8 }   // 熟了：看你、搖偽足
            else { on(0, [.user(0.9)]); on(0.9, [.blink, .sniff(side > 0 ? 0.2 : P - 0.2, 0.35, 0.25, 0.9, 0.4)]); on(2.3, [.user(0.6)]); T = 3.2 }   // 怕生：看你 0.9 秒、眨眼別開往旁邊探，再偷看一眼
        case .sway:   // 看著你、搖偽足、左右左傾三下
            on(0, [.user(2.4), .wag(0), .lean(P), .voice("mmm", 0.5)]); on(0.7, [.lean(0)]); on(1.4, [.lean(P)]); T = 2.4
        case .lounge:   // 往牆那邊斜下伸一條偽足撐著 4 秒，眼睛直直看前面
            on(0, [.sniff(side > 0 ? 0.35 : P - 0.35, 0.5, 0.8, 4, 0.9), .user(5.4)]); T = 5.8
        case .doze:   // 眼睛 1.4 秒慢慢閉上、閉著 1.2 秒，縮一下、睜大醒來
            on(0, [.eyeDoze(1.4, 2.6)]); on(2.6, [.eyeOff, .shrink(0.6), .blink, .pulse]); T = 4.2
        case .wings:   // 左上右上兩條同時開、合，兩次
            for c in [0.0, 1.0] { on(c, [.pod(-P / 2 - 0.75, 0.42, 0.3, 0.1, 0.35), .pod(-P / 2 + 0.75, 0.42, 0.3, 0.1, 0.35)]) }
            T = 2.2
        case .fizz:   // 上半身一個個冒出短偽足又縮掉，六顆（先抽好六顆的方向和長度，順序照網頁：方向、長度、方向、長度…）
            var Q: [(a: Double, L: Double)] = []
            for _ in 0..<6 { let a = -P / 2 + (sgRnd() - 0.5) * 2.4; let L = 0.16 + 0.1 * sgRnd(); Q.append((a, L)) }
            on(0, [.blink])
            for (i, e) in Q.enumerated() { on(Double(i) * 0.18, [.pod(e.a, e.L, 0.07, 0.03, 0.14)]) }
            T = 1.4
        case .jitter:   // 很快看左、看右，整團抖一下
            on(0, [.sniff(P + 0.3, 0.35, 0.15, 0.2, 0.15), .pulse]); on(0.55, [.sniff(-0.3, 0.35, 0.15, 0.2, 0.15)]); on(1.1, [.shake(0.45)]); T = 2
        case .reach:   // 往罐子（擺飾 2 是書堆）伸過去停一下、縮回來，縮三下像在嚼（手機的 props 只有擺飾，網頁的 r.deco 一定成立）
            var p: Prop? = nil
            for r in props where r.im != "d_candle" && !r.gone && r.fade == 0 { p = r }
            let tx: Double = p?.x ?? qx + side * R * 2
            var ty = qy
            if let p, let g { ty = min(p.y, g.fl) }
            let a = atan2(ty - qy, tx - qx), L = max(0.5, min(1.1, hypot(tx - qx, ty - qy) / R - 0.6))
            on(0, [.sniff(a, L, 1, 1.2, 0.5)])
            for u in [2.9, 3.3, 3.7] { on(u, [.shrink(0.35)]) }
            T = 4.8
        }
        // 網頁 q.sort((x,y)=>x.at-y.at) 是穩定排序：同一個時間的照排進去的順序（Swift 的 sort 不保證穩定，所以帶著原本的位置比）
        sgQ = q.enumerated().sorted { $0.element.at != $1.element.at ? $0.element.at < $1.element.at : $0.offset < $1.offset }.map { $0.element }
        let until = t + T
        sgOn = SgRun(k: d.k, t0: t, end: d.k == .dash ? end : until, until: until)   // 做完整段才算結束（快跑那種等走回原地）
        lifeUntil = max(lifeUntil, until + 0.3)
    }
    /// 網頁 sgStep：lifeStep 每幀叫（被碰著、睡著、在逃、在聽你的節奏時 lifeStep 提早回去，不會叫到；busy：手指放旁邊、來找你）
    private func sgStep(_ dt: Double, _ busy: Bool) {
        guard params.signature >= 0.5, let d = sgDef() else { if sgOn != nil { sgCut() }; return }
        if sgGap < 0 { sgGap = sgGapRnd(true) }
        if slpWakeT != sgWk { if d.wake && slpWakeT > sgWk && slpWakeT <= t { sgAcc = max(sgAcc, sgGap) }; sgWk = slpWakeT }   // 蜜蜜：醒來先伸懶腰
        if let o = sgOn {
            if o.t0 > t || t > o.until || lastTouch > o.t0 || !fingers.isEmpty || slpOn || escOn || introOn || busy || (o.k != .dash && lifeSt != .rest) { sgCut(); return }
            while let s = sgQ.first, t >= s.at {
                if s.w && (gaitOn || wanderMoving || lifeSt != .rest) { break }   // w：等走到了（回到休息）才做下一步
                sgQ.removeFirst()
                for a in s.acts { sgDo(a) }
                if s.w { lifeUntil = max(lifeUntil, o.until + 0.3) }
            }
            if sgQ.isEmpty && t >= o.end { sgOn = nil }
            return
        }
        if lifeSt == .rest || lifeSt == .look { sgAcc += dt }
        if lifeSt != .rest || sgAcc < sgGap || busy || (sillOn && (sillRoute != nil || sillAir || sillHop != nil)) || drPush != nil || e4On || lureOn || (brOn && brain.pre != nil) { return }
        sgAcc = 0; sgGap = sgGapRnd(false); sgFire(d)
    }

    /// E2 every frame: held still 0.35 s it pushes back once (a soft tap); still 0.8 s it nuzzles; tickled it squirms, past 3 s it slips free
    /// (v2.63 D3 holdTickle 1: it never breaks free, it squirms and giggles as long as you go on).
    private func e2Step(_ dt: Double) {
        guard iv3(params.e2), !clusters.isEmpty else { nuzT0 = -1; return }
        guard let g = firstGrab(), !slpOn else { nuzT0 = -1; nuzSaid = false; tkTimes.removeAll(); tkT = 0; return }   // v2.61 C1: asleep it does not push, nuzzle or say anything
        let sp = hypot(g.vxS, g.vyS) / R, dx = g.fx - clusters[gi].xc, dy = g.fy - clusters[gi].yc, l = max(1e-6, hypot(dx, dy))
        if !g.pushed2 && t - g.tDown > 0.35 && sp < 0.5 && g.stretch < 0.3 && impWary < 0.4 {
            g.pushed2 = true
            if Double.random(in: 0..<1, using: &rng) < 0.3 { leanT = t; leanA = atan2(dy, dx); leanS = 1; onEvent?(.nudge) }
        }
        // tickling: the finger at 1.5R/s or more turning back by more than 120°, tickRev times within a second
        // v2.24 tickSeg: a leg longer than this is rubbing, not tickling (the travel between turns: the speed is smoothed, the turn is seen late and two points would measure short)
        g.tkP += hypot(g.vx, g.vy) * dt
        if sp > 1.5 && g.stretch < 0.6 {
            let a = atan2(g.vyS, g.vxS)
            if let p = g.tkA, abs(atan2(sin(a - p), cos(a - p))) > 2.1 {
                if params.tickSeg > 0 && g.tkP > params.tickSeg { tkTimes.removeAll() } else { tkTimes.append(t) }
                g.tkP = 0
            }
            g.tkA = a
        }
        tkTimes.removeAll { t - $0 >= 1 }
        let tickling = tickOn
        if tickling {
            tkT += dt
            let hold = params.holdTickle >= 0.5   // v2.63 D3 (web: the same line): it does not break free nor turn to protesting; it squirms and giggles on
            let warn: Bool = !hold && params.tickFree > 3 && tkT > params.tickFree - 2   // v2.24: the last 2 s it protests and squirms harder before it breaks free
            if t >= gigNext { gigNext = t + 0.7; shkAt = -9; shkT0 = t; shkAmp = warn ? 0.8 : 0.45; voice(warn ? "protest" : "giggle") }
            if !hold && tkT > params.tickFree {
                tkT = 0; tkTimes.removeAll()
                inertiaCatch()
                for m in g.mem { GRAB[m.i] = false }
                g.mem = []; g.mode = .none; lastTouch = t; dragRelease(glide: true)
                voiceLast = -9; voice("protest")   // the giggle just before must not swallow it
                if params.emo >= 0.5 { flee(-dx / l, -dy / l, W * 0.18 * params.flee) }
                cowerUntil = max(cowerUntil, t + 1.2)
                return
            }
        } else {
            tkT = max(0, tkT - dt)
        }
        // nuzzling: swaying side to side 0.05R, 0.6 a second; the first time "mmm~"
        if sp < 0.3 && g.stretch < 0.4 && !tickling && !(sooOn && bondOn) {   // v2.63 D6: being soothed it does not nuzzle or hum; after the sigh
            if nuzT0 < 0 { nuzT0 = t; nuzO = 0 }
            let u = t - nuzT0 - 0.8
            if u > 0 {
                if !nuzSaid { nuzSaid = true; voice("mmm", 0.6) }
                let o = R * params.nuzAmp * (reduceMotion ? 0.5 : 1) * sin(2 * .pi * 0.6 * u) * min(1, u / 0.5), d = o - nuzO
                nuzO = o; moveHome(-dy / l * d, dx / l * d, dt)
            }
        } else {
            if nuzO != 0 { moveHome(dy / l * nuzO, -dx / l * nuzO, dt); nuzO = 0 }
            nuzT0 = -1
        }
    }
    /// E4: trusting (over 0.5), untouched 10–20 s, under 3 visits this run, the last over 40 s ago: it swims to the front (the middle of the
    /// screen, a little low), waves a pseudopod, hums "mm~mm", and goes back to rest. A touch stops it.
    private func e4Step(_ dt: Double) -> Bool {
        guard iv3(params.e4), !clusters.isEmpty else { e4On = false; return false }
        if !e4On {
            if e4Wait < 0 { e4Wait = (10 + Double.random(in: 0..<10, using: &rng)) * params.e4Mul }
            guard impTrust > 0.5, Double(e4Count) < 3 + (2 * exLevel()).rounded(), (brOn ? brain.want == "greet" : t - lastTouch > e4Wait), t - e4LastT > 40, fingers.isEmpty, lifeSt == .rest else { return false }   // v2.63 大腦: it comes when it wants to be stroked (brainPick), not on a timer
            let q = toWorld(W / 2, viewV.y + H * 0.12), dx = q.x - clusters[gi].xc, dy = q.y - clusters[gi].yc, d = hypot(dx, dy)
            e4On = true; e4Wave = false; e4T0 = t
            if brOn { brain.want = ""; brain.s = max(0, brain.s - 0.6) }
            if d > R * 0.6 { gaitTo(q.x, q.y, dash: d > R * 4) } else { e4Wave = true; wagT = t; voice("hello") }
            return true
        }
        if !fingers.isEmpty { e4On = false; e4Wait = -1; return false }
        if !e4Wave {
            if (!gaitOn && !wanderMoving && lifeSt != .arrive) || t - e4T0 > 12 { e4Wave = true; e4T0 = t; wagT = t; voice("hello") }
            return true
        }
        if t - e4T0 > 2.2 { e4On = false; e4LastT = t; e4Wait = -1; e4Count += 1; lifeSt = .rest; lifeUntil = t + restDur() }
        return true
    }
    // MARK: - v2.23 eyes, B2 sleep, C6 echo, swim-in

    private func eyeAt(_ a: [Int]) -> (x: Double, y: Double) {
        var x = 0.0, y = 0.0
        for i in a { x += X[i]; y += Y[i] }
        let n = Double(max(1, a.count))
        return (x / n, y / n)
    }
    private func eyeSetup() {
        eyeL = []; eyeR = []
        for (k, ex) in [-0.27, 0.27].enumerated() {
            var o: [(Double, Int)] = []
            for i in 0..<N where TID[i] < 0 { o.append((hypot(Q0X[i] - ex * R, Q0Y[i] + 0.05 * R), i)) }
            o.sort { $0.0 < $1.0 }
            let pick = o.prefix(4).map { $0.1 }
            if k == 0 { eyeL = pick } else { eyeR = pick }
        }
        if !eyeL.isEmpty && !eyeR.isEmpty { let l = eyeAt(eyeL), r = eyeAt(eyeR); eyeD0 = max(1, hypot(r.x - l.x, r.y - l.y)) }
        eyeCX = 0; eyeCY = 0; eyeCK = 1; eyePose = nil   // v2.29
        eyeDX = 0; eyeDY = 0; eyeDK = 0; eyeGX = 0; eyeGY = 0; eyeSacT = 0; eyeUser = -9; eyeMode = .open; eyeOpenD = 1; eyeWideD = 1; eyeBlinkT = -9; eyePulse = -9; eyeSqU = -9; eyeBlink = 1
    }
    /// Where it looks: a grabbing finger → a finger beside it → where you tapped the rhythm → you (straight out) →
    /// where it walks → where it sniffs → glancing about by itself (45% of the glances at you).
    private func eyeStep(_ dt: Double) {
        guard params.eyes >= 0.5, !eyeL.isEmpty, !eyeR.isEmpty else { return }
        if eyeNextBlink - t > 8 { eyeNextBlink = t + 2 }; if eyeSacT - t > 6 { eyeSacT = t }   // the clock went back (setup restarts it): no blink scheduled in the future
        let l = eyeAt(eyeL), r = eyeAt(eyeR), cx = (l.x + r.x) / 2, cy = (l.y + r.y) / 2
        func tow(_ x: Double, _ y: Double) -> (Double, Double) {
            let dx = x - cx, dy = y - cy, d = max(1e-6, hypot(dx, dy)), k = min(1, d / (R * 1.2))
            return (dx / d * k, dy / d * k)
        }
        var g: Finger?, pf: Finger?
        for f in fingers.values { if f.mode == .grab { if g == nil { g = f } } else if pf == nil { pf = f } }
        var o: (Double, Double)?
        // v2.61 B4 (eyeTrue): the real finger, held or beside it, not the smoothed one
        if let g { o = params.eyeTrue >= 0.5 ? tow(g.rawX, g.rawY) : tow(g.fx, g.fy) }
        else if let pf { o = params.eyeTrue >= 0.5 ? tow(pf.rawX, pf.rawY) : tow(pf.fx, pf.fy) }
        else if echoSt != 0 { o = tow(echoX, echoY) }
        else if greetWait && greetOpen { o = (0, 0.9) } else if t < greetUntil { o = (0, 0) }   // v2.63 C4: falling (opened), it looks down; landed, it turns to you
        else if t < drLookT && !slpOn && drOn { o = tow(drLX, drLY) }   // v2.64 擺飾變真 (web v2.46): something moved or rang: it looks there
        else if t < eyeUser || slpOn { o = (0, 0) }
        else if escOn { o = tow(escDX, escDY) }
        else if gaitOn { o = (cos(gaitH), sin(gaitH)) }
        else if let s = sniffs.last, !(s.cut > 0) { o = (cos(s.a), sin(s.a)) }
        if o == nil {
            if t >= eyeSacT {
                eyeSacT = t + 1.2 + Double.random(in: 0..<2.8, using: &rng)
                if Double.random(in: 0..<1, using: &rng) < 0.45 + 0.15 * exLevel() { eyeSX = 0; eyeSY = 0 }
                else { let a = Double.random(in: 0..<(2 * .pi), using: &rng), k = (0.5 + Double.random(in: 0..<0.5, using: &rng)) * (params.gazeAmp > 0.1 ? 0.5 : 1); eyeSX = cos(a) * k; eyeSY = sin(a) * k * 0.7 }   // v2.24: idle glances do not grow with gazeAmp
            }
            o = (eyeSX, eyeSY)
        }
        let kg = 1 - exp(-dt / 0.06)
        eyeGX += (o!.0 - eyeGX) * kg; eyeGY += (o!.1 - eyeGY) * kg
        // v2.24 dodge (measured: pressing the middle, the finger covers the edge of both eyes): near a finger the whole face slides away: up as a rule (the finger comes from below,
        // above the fingertip is in sight); over 0.2R below the fingertip (under the finger, taken as coming from the lower right) to the nearer side of the finger
        do {
            var tx = 0.0, ty = 0.0, dk = 0.0
            if params.dodge > 0 {
                for f in fingers.values where f.mode == .grab || f.mode == .push || f.mode == .stroke {
                    let vx: Double = cx - f.rawX, vy: Double = cy - f.rawY, d: Double = max(1e-6, hypot(vx, vy)), kk: Double = smooth01(1 - d / (R * 0.85))
                    if kk <= dk { continue }
                    dk = kk
                    var ux: Double = vx / d, uy: Double = vy / d
                    if vy > R * 0.2 { let sd: Double = ux * 0.866 - uy * 0.5; ux = sd >= 0 ? 0.866 : -0.866; uy = sd >= 0 ? -0.5 : 0.5 }
                    else { ux *= min(1, d / (R * 0.3)); uy = min(uy, 0) - 0.6 }
                    let ul: Double = max(1e-6, hypot(ux, uy)), m: Double = kk * params.dodge * (reduceMotion ? 0.5 : 1)
                    tx = ux / ul * m; ty = uy / ul * m
                }
            }
            let kd: Double = 1 - exp(-dt / 0.1)
            eyeDX += (tx - eyeDX) * kd; eyeDY += (ty - eyeDY) * kd; eyeDK += (dk - eyeDK) * kd
        }
        eyePoseStep(dt)   // v2.29: keep the face inside the body
        if let g, g.peak / R > 5 && bodyStretch(g) > 0.8 && (!roughOn || g.yank) { eyeSqU = t + 0.45 }   // a yank squeezes them shut (one finger drags it along, it rarely strains to flee)
        let moodGlad: Bool = brainM > 0.45 && t < eyeUser && g == nil   // v2.63 心情: in a good mood, ∩ while it looks at you
        let happy = moodGlad || purr > 0.3 || (t >= happyT && t - happyT < 1.6) || (e4On && e4Wave) || t < echoJoyUntil || t - snwLast < 1.2   // v2.31: shaken, ∩ like on a ride
        let squeeze = moodStrain > 0.4 || tickOn || (escOn && t - escT0 < 0.5) || t < eyeSqU
        var mode: EyeMode = slpK > 0.65 ? .sleep : (squeeze ? .squeeze : (happy ? .happy : .open))
        let sbb: Double? = params.slowBlink >= 0.5 ? sblStep(dt, mode) : nil   // v2.64 D8 慢眨：這段換回睜眼的形狀，眨眼量照慢眨的曲線
        if sbb != nil { mode = .open }
        if mode != eyeMode { eyeMode = mode; if mode == .open { eyeBlinkT = t - 0.08 } }   // back to open: opening from shut
        var open = 1.0, wide = 1.0
        if slpOn || slpK > 0.02 { open = max(0, 1 - slpK * 1.5) }
        if let g { open = min(open, t - g.tDown < 0.3 ? 0.55 : 0.8) }
        if snwK > 0.02 && g == nil { open = min(open, 1 - 0.85 * snwK * min(1, max(0, (snwCloud - 0.06) / 0.3))) }   // v2.31: eyes shut while the glitter settles, breathing with you; open again once clear
        do { let u = t - flT0; if flAmp > 0.02 && u >= 0 && u < 0.22 && echoSt != 2 { open = min(open, 0.3) } }
        if brain.pre == .sleep && brOn { open = min(open, 0.45) }   // v2.63 大腦 (web v2.42 前兆): about to sleep, the eyes half shut
        let moodLow: Bool = brainM < -0.35   // v2.63 心情: in a bad mood, wide
        let drWide: Bool = drOn && drRecent(drWideT, 0.8)   // v2.64 擺飾變真: a fall while you hold it: only the eyes go wide
        if impWary > 0.5 || moodScare > 0.3 || (t - slpWakeT < 0.8 && !slpSlow) || moodLow || drWide { wide = 1.18 }   // v2.61 C1: woken slowly, not wide
        do { let u = t - eyePulse; if u >= 0 && u < 0.15 { wide *= 1 + 0.15 * sin(.pi * u / 0.15) } }
        if sbb != nil { open = min(open, SBLK.lid) }   // v2.64 D8 慢眨時半睜
        if sgEye != nil && params.signature >= 0.5, let sl = sgLid() { open = min(open, sl) }   // v2.64 C8：蜜蜜伸懶腰時半閉（要睡了那個 0.45）、湯圓打瞌睡慢慢閉上（睡著那條線）
        if mode == .open && t >= eyeNextBlink && !slpOn && sbb == nil { eyeBlinkT = t; eyeNextBlink = t + (Double.random(in: 0..<1, using: &rng) < 0.2 ? 0.32 : (2 + Double.random(in: 0..<4, using: &rng)) * (1 - 0.3 * exLevel())) }
        let u = t - eyeBlinkT
        eyeBlink = sbb ?? (u < 0 ? 1 : (u < 0.07 ? 1 - u / 0.07 : (u < 0.11 ? 0 : (u < 0.21 ? (u - 0.11) / 0.1 : 1))))   // v2.64 D8：慢眨時用慢眨的曲線
        let k = 1 - exp(-dt / 0.05)
        eyeOpenD += (open - eyeOpenD) * k; eyeWideD += (wide - eyeWideD) * k
    }
    /// Signed distance from (x, y) to the closed polygon P: positive inside (winding number), negative outside.
    private func sdRing(_ P: [(x: Double, y: Double)], _ x: Double, _ y: Double) -> Double {
        var w = 0
        var dm = 1e18
        let n = P.count
        var j = n - 1
        for i in 0..<n {
            let ax = P[j].x, ay = P[j].y, bx = P[i].x, by = P[i].y, ex = bx - ax, ey = by - ay
            let l2: Double = max(1e-9, ex * ex + ey * ey)
            let u: Double = max(0, min(1, ((x - ax) * ex + (y - ay) * ey) / l2))
            let dx = ax + ex * u - x, dy = ay + ey * u - y, d = dx * dx + dy * dy
            if d < dm { dm = d }
            let cr: Double = ex * (y - ay) - ey * (x - ax)
            if ay <= y { if by > y && cr > 0 { w += 1 } } else if by <= y && cr < 0 { w -= 1 }
            j = i
        }
        dm = sqrt(dm)
        return w != 0 ? dm : -dm
    }
    /// v2.29 眼睛不跑出身體: the eyes stay bound to their particles, with three more rules. The eye distance is at most 1.3× rest (pulled open
    /// at both sides the face is not torn apart); the face tilts at most 30° with the body plus 20° locally (two eyes stacked read as no face);
    /// both eyes keep one eye's height from the outline, else the whole face slides to the nearest spot thick enough, then the eyes close up.
    /// The correction eases in over 0.05 s; an eye really outside is clamped back this very frame. Port of the web's `eyePose`.
    private func eyePoseStep(_ dt: Double) {
        guard effParams.noFlip > 0, !eyeL.isEmpty, !eyeR.isEmpty, !clusters.isEmpty, bnd.count >= 3 else { eyePose = nil; return }
        let l = eyeAt(eyeL), r = eyeAt(eyeR), S = R * params.eyeSize, ga: Double = params.gazeAmp * (1 - 0.8 * eyeDK)
        let ox: Double = (eyeGX * ga + eyeDX) * S, oy: Double = (eyeGY * ga * 0.75 + eyeDY) * S
        let P = boundaryPoints()
        let M: Double = S * 0.118 * (params.skin >= 0.5 ? 0.68 : 1) + R * 0.02   // one eye's height (the jelly skin draws the eyes at 0.68)
        let g0 = atan2(clusters[gi].sn, clusters[gi].cs)
        let cx = (l.x + r.x) / 2 + ox, cy = (l.y + r.y) / 2 + oy, ax = r.x - l.x, ay = r.y - l.y
        let sp: Double = min(hypot(ax, ay), eyeD0 * 1.3)
        let th0 = atan2(ay, ax), dth = atan2(sin(th0 - g0), cos(th0 - g0))
        let th: Double = max(-0.5, min(0.5, atan2(sin(g0), cos(g0)))) + max(-0.35, min(0.35, dth))
        let ux = cos(th), uy = sin(th)
        func fits(_ x: Double, _ y: Double, _ s: Double) -> Bool {
            sdRing(P, x - ux * s / 2, y - uy * s / 2) >= M && sdRing(P, x + ux * s / 2, y + uy * s / 2) >= M
        }
        var tx = 0.0, ty = 0.0, tk = 1.0   // this frame's wanted correction: shift, and the eye distance factor
        if !fits(cx, cy, sp) {
            var sx = cx, sy = cy, best = -1e9
            var i = 0
            while i < N {
                if TID[i] < 0 {
                    let d = sdRing(P, X[i], Y[i]), sc: Double = min(d, M * 1.8) - 0.04 * hypot(X[i] - cx, Y[i] - cy)
                    if sc > best { best = sc; sx = X[i]; sy = Y[i] }
                }
                i += 2
            }
            var s2 = sp
            var k = 0
            while k < 3 && !fits(sx, sy, s2) { s2 *= 0.72; k += 1 }
            tk = s2 / sp
            var lo = 0.0, hi = 1.0
            if fits(sx, sy, s2) {
                for _ in 0..<6 { let m = (lo + hi) / 2; if fits(cx + (sx - cx) * m, cy + (sy - cy) * m, s2) { hi = m } else { lo = m } }
            }
            tx = (sx - cx) * hi; ty = (sy - cy) * hi
        }
        let q: Double = 1 - exp(-dt / 0.05)
        eyeCX += (tx - eyeCX) * q; eyeCY += (ty - eyeCY) * q; eyeCK += (tk - eyeCK) * q
        let s3 = sp * eyeCK
        var ex = [cx + eyeCX - ux * s3 / 2, cx + eyeCX + ux * s3 / 2], ey = [cy + eyeCY - uy * s3 / 2, cy + eyeCY + uy * s3 / 2]
        // really outside: clamp straight back in, step by step toward the thickest spot nearby
        for e in 0..<2 {
            if sdRing(P, ex[e], ey[e]) >= M * 0.6 { continue }
            var bx = ex[e], by = ey[e], bd = -1e9
            var i = 0
            while i < N {
                if TID[i] < 0 {
                    let d = sdRing(P, X[i], Y[i]), sc: Double = min(d, M) - 0.03 * hypot(X[i] - ex[e], Y[i] - ey[e])
                    if sc > bd { bd = sc; bx = X[i]; by = Y[i] }
                }
                i += 2
            }
            var lo = 0.0, hi = 1.0
            for _ in 0..<6 { let u = (lo + hi) / 2; if sdRing(P, ex[e] + (bx - ex[e]) * u, ey[e] + (by - ey[e]) * u) >= M * 0.6 { hi = u } else { lo = u } }
            ex[e] += (bx - ex[e]) * hi; ey[e] += (by - ey[e]) * hi
        }
        eyePose = (ex[0], ey[0], ex[1], ey[1])
    }
    /// B2: untouched 40 s (a tap on empty space counts) while resting, it falls asleep: eyes close, it melts a little, breathes slow and deep.
    private func sleepTry() -> Bool {
        guard iv3(params.sleep), !slpOn else { return false }
        guard idleSec >= (params.sleepAfter > 0 ? params.sleepAfter : 40), lifeSt == .rest, fingers.isEmpty, !e4On, echoSt == 0, !swimOn, snwCloud <= 0.03 else { return false }   // v2.31: not while the glitter settles, it has to open its eyes at the clear moment
        slpOn = true; lifeSt = .sleep; cutSniffs()
        return true
    }
    // MARK: v2.61 C1 (wakeSoft; .uiux/04-手感/極致優化規劃-暫定.md; web WAKEK, softTouch, tapJudge, rollStep, idleSec)
    /// Trusting (lureStep's rule: over 0.25 and 0.1 above wary), touched asleep it does not wake yet. Within T of landing, the hand past v (R a second on the screen) or dragged past st (R) is a hard one: startled, as before.
    /// Otherwise it wakes slowly (eyes opening with `slow`, no flinch, not wide); very trusting (deep) it only turns over (shifts `roll` × R and back in roT), until the n-th touch of the nap, held past `hold`, or dragged past st.
    private enum WakeSet {
        static let trust: Double = 0.25, lead: Double = 0.1, tapGap: Double = 1   // trusting enough; ahead of wary by; a third touch within this is poking
        static let v: Double = 4, st: Double = 0.8, T: Double = 0.25
        static let deep: Double = 0.7, roll: Double = 0.05, roT: Double = 1.4, n: Int = 3, hold: Double = 1.2, slow: Double = 0.5
    }
    /// How long nobody has been there. Just opened it counts from the opening (lastTouch starts at −10, so it used to fall asleep 30 s after).
    private var idleSec: Double {
        let opened: Double = params.wakeSoft >= 0.5 && slpOpenT <= t ? slpOpenT : -99
        return t - max(lastTouch, slpLastAny, opened)
    }
    /// A finger has touched it asleep. true: wait and see (tapJudge); false: startled awake, as before.
    private func softTouch(_ f: Finger) -> Bool {
        guard params.wakeSoft >= 0.5, impTrust > WakeSet.trust, impTrust - impWary > WakeSet.lead else { return false }
        if taps.filter({ t - $0 < WakeSet.tapGap }).count >= 2 { return false }   // the third within a second: poking, as before
        if let q = slpTap, q !== f { return false }
        slpTap = f; slpTapT0 = t; slpTapDone = false
        slpTapX = f.rawX; slpTapY = f.rawY; slpTapOut = f.mode != .grab   // pressed on it: where it came down; pushed in from outside: where it met the body, the way there is no drag
        return true
    }
    /// Every frame, at the start of sleepStep: light or hard, then what a light one does.
    private func tapJudge() {
        guard let f = slpTap else { return }
        if !slpOn { slpTap = nil; return }
        let there: Bool = fingers.values.contains(where: { $0 === f })
        let here: Bool = there && (f.mode == .grab || t - f.hitT < 0.1)
        let hv: Double = hypot(f.vxS, f.vyS) * camZ / R
        let off: Double = hypot(f.rawX - slpTapX, f.rawY - slpTapY) / R
        if !slpTapDone {
            if hv >= WakeSet.v || (!slpTapOut && off > WakeSet.st) {   // from outside only how fast counts while it is judged: st in T is 3.2R a second, stricter than v
                slpTap = nil; wake(true); return
            }
            if here && t - slpTapT0 < WakeSet.T { return }
            slpTapDone = true; slpTapN += 1
            if impTrust > WakeSet.deep && slpTapN < WakeSet.n && clusters.indices.contains(gi) {
                slpRollT = t; slpRollO = 0; slpRollD = f.ax >= clusters[gi].xc ? 1 : -1
            } else {
                slpTap = nil; wake(false, slow: true)
                return
            }
        }
        if !here { slpTap = nil; return }
        if f.yank { wake(true) } else if t - slpTapT0 > WakeSet.hold || off > WakeSet.st { wake(false, slow: true) }
    }
    /// The turn over: it shifts toward where the finger landed and back (moved with its previous positions, no velocity). No sound, no tap.
    private func rollStep(_ dt: Double) {
        if slpRollT < 0 { return }
        let u: Double = (t - slpRollT) / WakeSet.roT
        var o = 0.0
        if u >= 0 && u < 1 {
            let s: Double = sin(.pi * u)
            o = R * WakeSet.roll * (reduceMotion ? 0.5 : 1) * (s * s) * slpRollD
        }
        let d: Double = o - slpRollO
        slpRollO = o
        if d != 0 { moveHome(d, 0, dt) }
        if u >= 1 || u < 0 { slpRollT = -9 }
    }
    /// Switched off, or gone to the background: nothing of it is left half done (a turn over goes straight back).
    private func softDrop() {
        slpTap = nil; slpTapN = 0; slpTapDone = false
        if slpRollO != 0 { let d: Double = -slpRollO; slpRollO = 0; moveHome(d, 0, 1.0 / 60) }
        slpRollT = -9
    }
    /// Awake again: sharp (touched) it flinches 1.6× and opens wide; gently (a finger beside it) it just opens; then "mm?". slow (v2.61 C1): it opens slowly and not wide.
    /// quiet (v2.63 C4, the web's `self`): it woke by itself, no "mm?" after (coming back to the app: it wakes slowly and looks at you instead).
    private func wake(_ sharp: Bool, slow: Bool = false, quiet: Bool = false) {
        guard slpOn else { return }
        slpSlow = slow; slpTapN = 0; slpTap = nil   // v2.61 C1
        slpOn = false; slpWakeT = t; slpNearT = 0; lifeSt = .rest; lifeUntil = t + 1.5 + Double.random(in: 0..<1, using: &rng); eyeBlinkT = t
        if sharp { voiceLast = -9; voice("startle", at: t + 0.05); flAt = t + 0.05; flPre = .rest; flBoost = 1.6; if mdOn { brain.m -= 0.1 } }   // v2.63 心情: woken with a start
        if !quiet { slpAskAt = t + (sharp ? 0.45 : 0.3) }
    }
    private func sleepStep(_ dt: Double) {
        if !iv3(params.sleep) && slpOn { wake(false) }
        if params.wakeSoft < 0.5 { softDrop(); if params.greetLook < 0.5 { slpSlow = false } }   // v2.61 C1 switched off; v2.63 C4: the slow waking of coming back stays slow (the web never clears it)
        tapJudge()
        if slpOn {
            for f in fingers.values where t - f.hitT < 0.05 {   // a finger pushed in from outside touched it
                if slpTap === f || softTouch(f) { continue }   // v2.61 C1: being told light or hard
                wake(true)
                break
            }
        }
        rollStep(dt)
        let wakeTau: Double = slpSlow ? WakeSet.slow : 0.25   // v2.61 C1
        slpK += ((slpOn ? 1 : 0) - slpK) * (1 - exp(-dt / (slpOn ? 1.6 : wakeTau)))
        if slpK < 1e-3 && !slpOn { slpK = 0 }
        // v2.50 sleeping breaths, one every 4 to 7 s
        if slpOn && slpK > 0.8 {
            if slpSnoreAt <= 0 { slpSnoreAt = t + 1 + Double.random(in: 0..<2, using: &rng) }
            else if t >= slpSnoreAt { slpSnoreAt = t + 4 + Double.random(in: 0..<3, using: &rng); onEvent?(.fx(kind: "snore", gain: 0.5, delay: 0)) }
        } else { slpSnoreAt = 0 }
        if slpAskAt > 0 && t >= slpAskAt { slpAskAt = -9; voiceLast = -9; voice("ask", 0.6); eyeUser = t + 1.2 }
    }
    // MARK: v2.63 C9 (nap; .uiux/04-手感/極致優化規劃-暫定.md C9, .vibe/C9-移植說明.md; web NAP, NAPK, napReady, napStep, line by line)
    /// Purred (purr > 0.3, the line the memory and the mood use) napPurr s in all this opening (setup clears it: a slime switch, a rebuild, a rotation), then no finger
    /// for napWait s (from lastTouch): it falls asleep where it is. Not back to the mat, not the brain's 睏, no 前兆; eyes, melting, slow breath, snoring as SLP, no words.
    /// While it waits it does not change what it does (lifeStep reads napOn; the happy hop, the sniff, the begging after a release go on). Not able to sleep at the time
    /// (fleeing, in the air, walking): grace s more, then not this time, the count stays. Asleep, all as before: a light touch goes through wakeSoft, slept off it wakes by itself.
    /// The nap clears the count. Not the brain's "wants to be stroked" (that is back to 0 after 4 to 10 s of rubbing). nap 0: it still counts, changes nothing else, draws no random number
    private enum NapSet {
        static let grace: Double = 2   // the web's NAPK.grace: a constant, not a knob
    }
    /// Could it fall asleep right now (sleepOK's kind of rule, but looking about or just arrived will do; not the brain's 睏). SNW.loose: the phone's glitter has nothing loose
    private func napReady() -> Bool {
        let awake: Bool = !slpOn && fingers.isEmpty && !escOn && !introOn && !e4On && !swimOn && echoSt == 0
        let still: Bool = !gaitOn && !wanderMoving && !(snwCloud > 0.03)
        let sill: Bool = sillOn && (sillRoute != nil || sillAir || sillHop != nil || sillGrab)
        let st: Bool = lifeSt == .rest || lifeSt == .look || lifeSt == .arrive
        return awake && still && !sill && st
    }
    private func napStep(_ dt: Double) {
        if purr > 0.3 { napCum += dt }
        for f in fingers.values where f.mode == .grab || t - f.hitT < 0.05 { napX = f.rawX; napY = f.rawY }   // the web's f.x, f.y (the real finger in the world, as softTouch)
        napOn = false
        guard params.nap >= 0.5, iv3(params.sleep), !slpOn, fingers.isEmpty, napCum >= params.napPurr else { return }
        let u: Double = t - lastTouch
        if u < 0 || u >= params.napWait + NapSet.grace { return }   // let go too long ago (no nap this time): as usual
        napOn = true
        if u >= params.napWait && napReady() {
            napOn = false; napCum = 0; napN += 1
            if brOn { brain.naps += 1; brain.pre = nil; brain.why = "揉夠了，在你手邊睡著" }
            slpOn = true; lifeSt = .sleep; attOn = false; askOn = false; cutSniffs()
        }
    }
    /// C6: 2 to 8 taps on empty space, each 0.12–1.2 s apart; when you stop (1.4× the longest gap, at least 0.8 s) it looks where you
    /// tapped for 0.35 s, then answers with the same count and gaps (a squeeze, "pu" and a soft tap each). The same rhythm back within
    /// 15 s (same count, each gap within 25%): after answering it is happy (∩, a wag, "pu-yi", a little more trust).
    private func echoTap(_ x: Double, _ y: Double) {
        guard iv3(params.echo), echoSt != 2 else { return }
        if let last = echoTaps.last, t - last > 1.3 { echoTaps = [] }
        echoTaps.append(t)
        if echoTaps.count > 8 { echoTaps.removeFirst() }
        echoX = x; echoY = y; echoSt = 1
    }
    private func echoBeat(_ i: Int) {
        flAmp = 0.07 * (reduceMotion ? 0.5 : 1); flT0 = t; eyePulse = t; echoBeatT = t
        if iv3(params.e1) { onEvent?(.voice(kind: "poke", gain: 0.5, rate: (1 + 0.1 * impTrust - 0.08 * impWary) * params.voicePitch * (i % 2 == 1 ? 1.06 : 1))) }
        onEvent?(.beat)
    }
    private func echoStep(_ dt: Double) {
        guard iv3(params.echo) else { echoSt = 0; echoTaps = []; return }
        if echoSt == 1 {
            if fingers.values.contains(where: { $0.mode == .grab }) || escOn || introOn { echoSt = 0; echoTaps = []; return }
            guard let last = echoTaps.last else { echoSt = 0; return }
            var iv: [Double] = []
            for i in 1..<max(1, echoTaps.count) { iv.append(echoTaps[i] - echoTaps[i - 1]) }
            if t - last > max(0.8, 1.4 * (iv.max() ?? 0)) {
                if !iv.isEmpty && iv.allSatisfy({ $0 >= 0.12 && $0 <= 1.2 }) {
                    if let p = echoPrev, t - echoPrevT < 15, p.count == iv.count {
                        echoSame = zip(iv, p).allSatisfy { abs($0 - $1) <= 0.25 * $1 + 0.04 }
                    } else { echoSame = false }
                    echoBeats = [0]
                    for x in iv { echoBeats.append(echoBeats.last! + x) }
                    echoT0 = t + 0.35; echoI = 0; echoSt = 2; echoPrev = iv; echoPrevT = t
                    cutSniffs(); gaitOn = false; wanderMoving = false
                    if lifeSt == .go || lifeSt == .look { lifeSt = .rest }
                } else { echoSt = 0 }
                echoTaps = []
            }
        } else if echoSt == 2 {
            while echoI < echoBeats.count && t >= echoT0 + echoBeats[echoI] { echoBeat(echoI); echoI += 1 }
            if echoI >= echoBeats.count && t > echoT0 + (echoBeats.last ?? 0) + 0.4 {
                echoSt = 0; eyeUser = t + 1.5; lifeSt = .rest; lifeUntil = t + 2 + Double.random(in: 0..<1, using: &rng)
                if echoSame {
                    echoJoyUntil = t + 1.6; wagT = t; voiceLast = -9; voice("happy")
                    if params.imp >= 0.5 { impTrust = min(1, impTrust + 0.08 * params.trRate) }
                }
            }
        }
    }
    /// Swims in from off the right edge (Reduce Motion: 1.6R beside home), one squeeze-and-surge stroke after another, the view holding
    /// still; home, it looks at you, wags and says hello.
    private func swimIntro(_ side: Double) {
        let rm = reduceMotion, dx = (rm ? R * 1.6 : W / 2 + R * 1.9) * side, dy = rm ? 0 : -H * 0.06
        moveHome(dx, dy, 1.0 / 60); wanderVX = 0; wanderVY = 0
        swimOn = true; swimT0 = t; lastTouch = t - 3; onEvent?(.fx(kind: "swimin", gain: 0.7, delay: 0))
        gaitTo(cx, cy, dash: !rm)
    }
    private func swimGreet() {
        guard swimOn else { return }
        if t - swimT0 > 9 { swimOn = false; return }
        if lifeSt == .rest { swimOn = false; eyeUser = t + 2; wagT = t + 0.1; voiceLast = -9; voice("hello"); lifeUntil = t + 2.5 }
    }

    // MARK: v2.63 C4 (greetLook; .uiux/04-手感/極致優化規劃-暫定.md C4; web GREET, GREETK, greetArm, greetStep, line by line)
    /// Opened (cold start, a slime switch) it waits to land (the sill), back in the app it waits `back` s; then it turns to you for `look` s and blinks `blink` s in,
    /// before doing anything else. However long you were away, the same (11-14: not warmer the longer you were gone). Asleep, coming back wakes it slowly, without a sound.
    /// A touch ends it. No sound, the body does not move: only the eyes. The web's brainJit (the opening's random start of the needs) waits for the phone's brain.
    private enum GreetSet {
        static let land: Double = 0.15, back: Double = 0.35, look: Double = 1.4, blink: Double = 0.25, wait: Double = 8
    }
    /// open: an opening; false: back from the background, the lock screen, Control Center (SlimeController on didBecomeActive after willResignActive).
    func greetArm(open: Bool) {
        guard params.greetLook >= 0.5, params.life2 >= 0.5, params.eyes >= 0.5, fingers.isEmpty, !greetWait else { return }
        greetWait = true; greetOpen = open; greetT0 = t; greetUntil = -9; greetAir = false; greetAt = open ? -9 : t + GreetSet.back
        if !open && slpOn { wake(false, slow: true, quiet: true) }
    }
    private func greetStep() {
        guard greetWait else { return }
        if !(params.greetLook >= 0.5) || !fingers.isEmpty || t < greetT0 || t - greetT0 > GreetSet.wait { greetWait = false; return }
        if greetOpen && greetAt < 0 {   // opened: counted from the moment it lands
            if (sillOn && (sillAir || sillRoute != nil)) || introOn || swimOn { greetAir = true; return }
            if sillOn && !greetAir && t - greetT0 < 0.1 { return }
            greetAt = t + GreetSet.land
        }
        if greetOpen && lifeSt == .rest { lifeUntil = max(lifeUntil, greetAt + GreetSet.look + 0.1) }
        if t < greetAt { return }
        greetWait = false; greetUntil = t + GreetSet.look; eyeUser = max(eyeUser, greetUntil); eyeBlinkT = t + GreetSet.blink; eyeNextBlink = max(eyeNextBlink, t + GreetSet.blink + 1.2)
        if lifeSt == .rest && !slpOn { lifeUntil = max(lifeUntil, greetUntil + 0.1 + 0.6 * Double.random(in: 0..<1, using: &rng)) }
    }

    // MARK: v2.63 大腦第一片「需求和自己醒」(brain; .uiux/04-手感/極致優化規劃-暫定.md C7; web brainStep, brainRest, brainGo, brainGoHome, brainAtHome,
    // brainSillFree, sleepOK, e4OK, brainJit, line by line). The numbers are in SlimeBrain.swift. Off on the phone, as the web with DRon() false:
    // the decorations (no 推東西, no candle). The remembered places (MMon) since v2.64: MARK v2.64 記地方 below.
    // brain 0: lifeStep's old dice and sleepTry's 40 s, and the sill's "back to the bowl after 25 s" (all untouched).
    // v2.63 第二片「心情」(mood): brainMood here, read by mdOn / brainM / brainMS (posture, flinch, stride, poke, eyes, wake, pick, going home); mood 0 as slice 1.

    /// brainStep: the needs rise and fall every frame (before lifeStep); asleep and slept enough, it wakes by itself (v2.40: only a touch woke it).
    private func brainStep(_ dt: Double, _ engaged: Bool) {
        guard brOn else { return }
        let idleT = idleSec
        brain.mood(SlimeBrain.MoodIn(dt: dt, on: mdOn, purr: purr, happyT: happyT, joyUntil: echoJoyUntil, wary: impWary, scare: moodScare, half: params.moodHalf))   // v2.63 brainMood
        brainMem(dt)   // v2.64 記地方 (web brainStep: brainMood(dt);brainMem(dt))
        let lie = brain.step(SlimeBrain.In(dt: dt, idleT: idleT, restMul: params.restMul, e4Mul: params.e4Mul, night: sceneKind == 2, exLevel: exLevel(), exert: exert,
                                           comfort: moodC, wary: impWary, scare: moodScare, trust: impTrust, awakeT: params.brAwakeT, sleepT: params.brSleepT,
                                           engaged: engaged, asleep: slpOn, resting: lifeSt == .rest, jit: params.brJit >= 0.5, hidden: false, moodOn: mdOn))
        if let lie { lifeUntil = max(lifeUntil, t + 1.5 + lie) }   // v2.61 C7: just woke, it may lie there a while first
        if slpOn && brain.z <= 0.02 && idleT > 3 { brain.selfWake += 1; wake(false, quiet: true) }   // slept enough: awake by itself (the web's wake(false,true))
        if brainAtHome() { brain.homeAt = t }
        // what it is doing (the web's B.act; v2.64 DR.push 推東西 first)
        if drPush != nil { brain.act = "推東西" }
        else if slpOn { brain.act = "睡覺" }
        else if brain.pre == .sleep { brain.act = "想睡了" }
        else if brain.pre == .greet || brain.want == "greet" { brain.act = "看著你" }
        else if escOn { brain.act = "逃跑" }
        else if engaged { brain.act = "被你碰著" }
        else if sgOn != nil { brain.act = "招牌：" + (sgDef()?.name ?? "") }   // v2.64 C8（網頁 SG.on?'招牌：'+名字）
        else if e4On { brain.act = "來找你" }
        else if lureOn { brain.act = "注意你的手指" }
        else if echoSt != 0 { brain.act = "回你的節奏" }
        else if lifeSt == .look { brain.act = "張望" }
        else if lifeSt == .go || lifeSt == .arrive || gaitOn || (sillOn && sillRoute != nil) { brain.act = "走" }
        else { brain.act = "休息" }
    }
    /// sleepOK (the web's; SNW.loose: the phone's glitter has settle mode only, nothing loose)
    private func sleepOK() -> Bool {
        iv3(params.sleep) && !slpOn && lifeSt == .rest && fingers.isEmpty && !e4On && echoSt == 0 && !swimOn && !(snwCloud > 0.03)
    }
    /// e4OK: could it go to the front and say hello now
    private func e4OK() -> Bool {
        iv3(params.e4) && !e4On && impTrust > 0.5 && Double(e4Count) < 3 + (2 * exLevel()).rounded() && t - e4LastT > 40 && fingers.isEmpty && t - lastTouch > 6
    }
    /// brainAtHome: off the sill it is always home; on it, home is memHomeX() (v2.64: the cell it likes best; brMem 0: the middle of the sill)
    private func brainAtHome() -> Bool {
        guard sillOn, let g = sillG, !clusters.isEmpty else { return true }
        return sillPlane == .room && abs(clusters[gi].xc - memHomeX(g)) < R * 0.3
    }
    private func brainSillFree() -> Bool { !sillGrab && !sillAir && sillHop == nil && sillRoute == nil && sillStickT < 0 && !escOn }
    /// brainGoHome: back home (memHomeX; the middle of the sill, into the bowl when there is one). true = it set off
    private func brainGoHome() -> Bool {
        guard brainSillFree(), let g = sillG else { return false }
        let hx = memHomeX(g)
        if sillPlane == .room && !sillInBowl && abs(hx - g.bx) > 1 { gaitTo(hx, homeY, dash: false); return gaitOn || wanderMoving }   // v2.43: the cell it likes is not the middle: it walks straight there along the sill
        guard let r = rtHome() else { return false }
        sillLastHome = t; routeStart(r)
        return true
    }
    /// brainGo: on the sill it walks along it to somewhere else (toward the side it just sniffed, when it did); elsewhere goStart as before
    private func brainGo(_ dir: Double?) {
        if sillOn && sillPlane == .room && !sillInBowl {
            if brainSillFree() && !clusters.isEmpty {
                let cx0 = clusters[gi].xc
                var x: Double? = nil
                if let fx = sgFavX(), !(mmOn && mem.fav() >= 0), abs(fx - cx0) > R * 0.45, !(mmOn && mem.cell[memCellAt(fx)] < -0.3), sgRnd() < SGK.go { x = fx }   // v2.64 C8（網頁同一行）：想動時有六成直接走回牠天生喜歡的那格（只有喜歡的不在布墊、你沒摸出別的喜歡時；signature 0 時 sgFavX 一直是 nil，不抽亂數）
                else {
                    for k in 0..<6 {
                        guard let c = floorWalkX(cx0), abs(c - cx0) >= R * 0.45 else { continue }
                        if mmOn && mem.cell[memCellAt(c)] < -0.3 && k < 5 { continue }   // v2.43 (v2.64 on the phone): not to the cell it was scared in
                        x = c
                        if let d = dir { if (cos(d) > 0) == (c > cx0) { break } } else { break }   // sniffed one way: that way
                    }
                }
                if let x { gaitTo(x, homeY, dash: false) }
            }
        } else {
            var d2: Double? = nil
            if let d = dir { d2 = d + Double.random(in: -0.175..<0.175, using: &rng) }
            goStart(d2)
        }
        if gaitOn || wanderMoving || (sillOn && sillRoute != nil) { brain.e = max(0, brain.e - SlimeBrain.K.go) }   // only setting off counts as having moved
        else { lifeSt = .rest; lifeUntil = t + restDur() }
    }
    /// brainRest: rested long enough. A 前兆 done: now it really sleeps or comes; else the strongest need decides.
    private func brainRest(_ canGo: Bool) {
        let pre = brain.pre
        brain.pre = nil
        if pre == .sleep {
            if sleepOK() { brain.naps += 1; slpOn = true; lifeSt = .sleep; cutSniffs() } else { lifeUntil = t + restDur() }
            return
        }
        if pre == .greet {
            if e4OK() { brain.want = "greet"; lifeUntil = t + 0.3 } else { lifeUntil = t + restDur() }
            return
        }
        let idleT = idleSec
        let opening: Bool = params.wakeSoft >= 0.5 && t >= slpOpenT && t - slpOpenT < (params.sleepAfter > 0 ? params.sleepAfter : 40)
        let canSleep: Bool = !opening && sleepOK() && idleT > 8
        let bm = brainM   // read before the call: brainM reads brain, pick mutates it
        var goScared = false   // v2.64 (web brainPick: MMon()&&SILL.plane==='room'&&BMEM.cell[memCellAt(globalC.xc)]<-.3)
        if mmOn && sillPlane == .room && !clusters.isEmpty { goScared = mem.cell[memCellAt(clusters[gi].xc)] < -0.3 }
        let offerOK = memCanOffer()
        let catOK = drCatOK()   // v2.64 擺飾變真 (web brainPick 'cat': drCatOK())
        let w = brain.pick(t: t, greetLook: params.greetLook >= 0.5, canGo: canGo, sleepOK: canSleep, e4OK: e4OK(), brm: bm, goScared: goScared, offerOK: offerOK, catOK: catOK)
        let away: Bool = sillOn && !brainAtHome(), tel: Bool = params.brPre >= 0.5
        switch w {
        case .sleep:
            if away && brainGoHome() { brain.why += mmOn && mem.fav() >= 0 ? "（先走回牠喜歡的位置）" : (drCandleX() != nil ? "（先走到蠟燭旁邊）" : (sgFavX() != nil ? "（先走回牠喜歡的位置）" : "（先走回布墊）")) }   // v2.64 the candle (drCandleX); v2.64 C8 牠天生喜歡的那格（sgFavX）
            else if away { lifeUntil = t + 1 }
            else if tel { brain.pre = .sleep; brain.preT0 = t; lifeUntil = t + 2; cutSniffs(); if sighCyc < 0 { sighNext = t } }   // 前兆: squint, one sigh, asleep 2 s later
            else { brain.naps += 1; slpOn = true; lifeSt = .sleep; cutSniffs() }
        case .greet:
            if tel { brain.want = ""; brain.pre = .greet; brain.preT0 = t; eyeUser = t + 1.2; lifeUntil = t + 0.9 } else { lifeUntil = t + 0.3 }   // 前兆: a look at you first; then e4Step
        case .look:
            // v2.64 C8（BATCH3 第 5b 項，網頁 sgHomeFav 那一行）：好奇一直贏的那幾隻（湯圓慢、愛睡：想動漲得慢，休息久好奇照漲）永遠輪不到下面 .rest「五個都不高、離家 20 秒走回去」那條，
            // 走開就不回喜歡那格；家是牠天生喜歡的那格時，想張望也先走回去。signature 0 時 sgHomeFav 一直是 false，不多走、不抽亂數
            if away && t - brain.homeAt > 20 && sgHomeFav() && brainGoHome() { brain.why += "（離開喜歡的位置太久，先走回去）" }
            else { lifeSt = .look; lifeLooks = 1 + (brain.q > 0.7 ? 1 : 0); lifeNoGo = false; lifeUntil = t }
        case .go:
            brainGo(nil)
        case .offer:
            memOffer()   // v2.64
        case .cat:
            drCat()   // v2.64 擺飾變真 (web 'cat')
        case .rest:
            let low: Bool = brainM < -0.3   // v2.63 心情: in a bad mood it goes back after 8 s away, not 20
            if away && t - brain.homeAt > (low ? 8 : 20) && brainGoHome() { brain.why = low ? "心情不好，走回去" : (mem.fav() >= 0 && mmOn ? "五個都不高，走回牠喜歡的位置" : (drCandleX() != nil ? "五個都不高，走到蠟燭旁邊" : (sgFavX() != nil ? "五個都不高，走回牠喜歡的位置" : "五個都不高，走回布墊"))) }   // v2.64 C8 sgFavX
            else { lifeUntil = t + restDur() }
        }
    }
    /// brainJit (with greetLook): an opening starts the needs at random (SlimeBrain.jit)
    private func brainJit() {
        guard params.greetLook >= 0.5, brOn else { return }
        brain.jit(t, trust: impTrust, using: &rng)
    }
    /// The web's impBack: back after 10 min or more, the needs start again from an opening (SlimeController, before the impression is reset)
    func brainBack() { drReset(); brain.reset(t, ev: brainEv()); brainJit() }
    /// What the mood sees now (the web's brainReset ev, memSync)
    private func brainEv() -> SlimeBrain.Ev { SlimeBrain.Ev(h: happyT, j: echoJoyUntil, w: impWary, sc: moodScare) }
    /// The web's memSync (chooseSlime, after the impression is set): the other slime's wariness, happy moment, scare are not "just happened" (SlimeController.select)
    func brainSync() { brain.ev = brainEv(); mem.ev = SlimeBrain.Mem.Ev(h: happyT, w: impWary, sc: moodScare) }   // v2.64: the places' too (web memSync: BMEM.ev)
    /// brainFlinch (v2.42): in a bad mood a touch makes it flinch bigger, in a good one smaller
    private func brainFlinch() -> Double { let m = brainM; return 1 + 0.6 * max(0, -m) - 0.3 * max(0, m) }

    // MARK: v2.64 大腦第三片「記地方」(brMem; .uiux/04-手感/極致優化規劃-暫定.md C7; web BMEM, MMon, memCellAt, memCellX, memHomeX, brainMem,
    // memTouch, memCanOffer, memOffer, memSave, memGet, v2.43 and v2.61, line by line). The sill from g.l to g.r in five cells. A purr there (+0.08 a second),
    // the happy moment (+0.1): liked; the wariness rising (−1.5 × the rise), a scare (−0.5 × the rise): disliked. The liked cell is home (rest, sleep);
    // a disliked one it walks round and leaves sooner (+0.4 to go). Let go after a gentle touch, it notes which side you touched (the side);
    // trusting and wanting to be stroked, it leans that side to you, reaches a pseudopod and looks at you ('offer', the web's memOffer).
    // Not here (the decorations, 第三批第 2 項): the night candle as home (drCandleX), a fall's scare kept out of the cells (drCrash's BMEM.ev.sc).
    // brMem 0: mmOn false, memHomeX is the middle of the sill, nothing changes the cells, offerOK false (no random drawn): as v2.63.

    /// memCellAt: which of the five cells x is in (0...4). A sill with no width (never): the first
    private func memCellAt(_ x: Double) -> Int {
        guard let g = sillG else { return 0 }
        let w = g.r - g.l
        guard w > 0 else { return 0 }
        let v = ((x - g.l) / w * 5).rounded(.down)
        guard v.isFinite else { return 0 }
        return Int(max(0, min(4, v)))
    }
    /// memCellX: where it sits in cell k (its middle, kept 0.9R inside the sill's ends)
    private func memCellX(_ g: SillGeo, _ k: Int) -> Double {
        let lo = g.l + R * 0.9, hi = g.r - R * 0.9
        return max(lo, min(hi, g.l + (g.r - g.l) * (Double(k) + 0.5) / 5))
    }
    /// memHomeX: where home is on the sill. The cell it likes best (past 0.3); none: the mat in the middle, unless it was scared there:
    /// then where it is, unless it was scared there too: the nearest cell it was not scared in. brMem 0: the middle (the web's g.bx; no candle on the phone)
    private func memHomeX(_ g: SillGeo) -> Double {
        let cdl = drCandleX()   // v2.64 擺飾變真 (web v2.46): at night the lit candle; nil while decoReact is off
        let sx = sgFavX()   // v2.64 C8：這隻天生喜歡的那格（signature 0、喜歡布墊的三隻、不在窗台：nil）
        if !mmOn { return cdl ?? sx ?? g.bx }
        let k = mem.fav()
        if k >= 0 { return memCellX(g, k) }
        if let cdl, mem.cell[memCellAt(cdl)] >= -0.3 { return cdl }   // nothing liked much: home beside the candle
        if let sx, mem.cell[memCellAt(sx)] >= -0.3 { return sx }   // v2.64 C8（網頁同一行）：沒有你摸出來的喜歡、不是夜晚蠟燭：家在這隻天生喜歡的那格
        if mem.cell[memCellAt(g.bx)] >= -0.3 { return g.bx }   // nothing liked much: the mat in the middle
        guard !clusters.isEmpty else { return g.bx }
        let cx = clusters[gi].xc, c = memCellAt(cx)
        if mem.cell[c] >= -0.3 { return cx }   // scared at the mat: where it is now, if not scared there
        var b = c, bd = 9
        for j in 0..<5 where mem.cell[j] >= -0.3 && abs(j - c) < bd { bd = abs(j - c); b = j }
        return memCellX(g, b)
    }
    /// brainMem: every frame with the brain (after the mood). Off, or not on the sill's front: only what it sees now is noted, so nothing old counts later
    private func brainMem(_ dt: Double) {
        guard mmOn, sillPlane == .room, !clusters.isEmpty else { mem.ev = SlimeBrain.Mem.Ev(h: happyT, w: impWary, sc: moodScare); return }
        let k = memCellAt(clusters[gi].xc)
        if purr > 0.3 { mem.add(k, 0.08 * dt) }   // purring here: this cell liked more and more (10 s of rubbing +0.8)
        if happyT != mem.ev.h { if happyT > mem.ev.h { mem.add(k, 0.1) }; mem.ev.h = happyT }
        if impWary > mem.ev.w { mem.add(k, -1.5 * (impWary - mem.ev.w)) }   // yanked, poked in a row here
        mem.ev.w = impWary
        if moodScare > mem.ev.sc { mem.add(k, -0.5 * (moodScare - mem.ev.sc)) }
        mem.ev.sc = moodScare
        memSave(force: false)
    }
    /// memTouch (web, from impRelease, before the impression's switch): let go, which side of it you touched (a yank does not count)
    private func memTouch(_ f: Finger) {
        guard mmOn, moodStrainMax <= 0.15, !clusters.isEmpty else { return }
        let sx: Double = max(-1, min(1, (f.ax - clusters[gi].xc) / R))
        mem.side += (sx - mem.side) * 0.15; mem.dirty = true
    }
    /// memCanOffer: wanting to be stroked, trusting, and it knows your side: lean that side over (shares the need with coming to you; not twice in 15 s)
    private func memCanOffer() -> Bool {
        let at: Double = mem.offerAt != 0 ? mem.offerAt : -99   // the web's BMEM.offerAt||-99
        return mmOn && params.imp >= 0.5 && impTrust >= 0.4 && abs(mem.side) >= 0.3 && t - at > 15 && fingers.isEmpty
    }
    /// memOffer: the side you touch leans to you (the E2 lean), a short pseudopod that way, a look at you
    private func memOffer() {
        let a: Double = mem.side > 0 ? 0 : .pi
        leanT = t; leanA = a; leanS = 1
        startSniff(a, 0.5, 0.5, 1, 0.6)
        eyeUser = t + 1.6
        mem.leans += 1; mem.offerAt = t
        brain.s = max(0, brain.s - 0.2)
        lifeUntil = t + 2.4
    }
    /// memSave: changed, and 3 s since the last write (force: leaving, a slime switch): the controller writes it (memWrite). The clock run back (at > t): write
    func memSave(force: Bool) {
        guard mem.dirty else { return }
        if !force && t - mem.at < 3 && mem.at <= t { return }
        mem.at = t; mem.dirty = false
        memWrite?()
    }
    /// What the controller keeps for the slime on screen (the web's memPut). ts: ms since 1970
    func memSaved(ts: Double) -> SlimeBrain.Mem.Saved { mem.saved(ts: ts) }
    /// memGet's end (the controller has already faded the disliked cells): this slime's places come back, no offer pending
    func memSet(cell: [Double], side: Double) {
        mem.cell = cell.count == 5 ? cell : [0, 0, 0, 0, 0]
        mem.side = side; mem.offerAt = -99; mem.leans = 0; mem.dirty = false
    }

    /// Every few seconds a cluster gets a small impulse; sometimes the whole body.
    private func twitch(_ L: Double) {
        if t < nextTwitch { return }
        nextTwitch = t + 2.2 + Double.random(in: 0..<4.5, using: &rng)
        if L < 0.5 || params.life <= 0 || lv(params.lifeRest) { return }   // v2.19 A1: no causeless twitches
        let amp = R * 0.0012 * params.life * (reduceMotion ? 0.5 : 1)   // per-substep displacement = velocity
        let whole = Double.random(in: 0..<1, using: &rng) < 0.25
        let c = whole ? clusters[gi] : clusters[Int.random(in: 0..<max(1, clusters.count - 1), using: &rng)]
        let a = Double.random(in: 0..<(2 * .pi), using: &rng), s = whole ? 0.6 : 1.0
        let ix = cos(a) * amp * s, iy = sin(a) * amp * s
        for i in c.idx where !GRAB[i] { PX[i] -= ix; PY[i] -= iy }
    }

    // MARK: - v2.52 A5 保險計數與量測讀數 (《虛擬手感》3-3 第 8、9 欄). Web: GRD, and what fuzz.js measures.

    /// How often each guard acted, in display frames. While a guard acts the body is not moving by its material numbers, so it is counted.
    /// hi: a bit of the mesh at its upper stretch limit; lo: at its lower one (squeezed; often on while it sits on the sill or is pressed into
    /// itself); flip: the no-flip guard; give: the finger gave way. giveMax: the farthest the finger's effective position has given (radii);
    /// givePull: how far it gave while pulling outward (the rule is 0: it may give only pushing into the body or into a wall, 3-3 鏈五).
    struct GuardStats: Equatable {
        var frames = 0, hi = 0, lo = 0, flip = 0, give = 0
        var giveMax = 0.0, givePull = 0.0
        func pct(_ n: Int) -> Double { frames > 0 ? (1000.0 * Double(n) / Double(frames)).rounded() / 10 : 0 }
    }
    private(set) var guardStats = GuardStats()
    private var grdHi = false, grdLo = false, grdFlip = false, grdGive = false
    func guardReset() { guardStats = GuardStats(); grdHi = false; grdLo = false; grdFlip = false; grdGive = false }
    /// At the start of each update: last frame's flags go into the counts.
    private func guardFold() {
        guardStats.frames += 1
        if grdHi { guardStats.hi += 1 }
        if grdLo { guardStats.lo += 1 }
        if grdFlip { guardStats.flip += 1 }
        if grdGive { guardStats.give += 1 }
        grdHi = false; grdLo = false; grdFlip = false; grdGive = false
        guard !clusters.isEmpty else { return }
        let c = clusters[gi]
        for f in fingers.values where f.mode == .grab && (f.slx != 0 || f.sly != 0) {
            let l: Double = hypot(f.slx, f.sly) / R
            if l > guardStats.giveMax { guardStats.giveMax = l }
            let ox: Double = f.x - c.xc, oy: Double = f.y - c.yc, ol: Double = hypot(ox, oy)
            if ol > R * 1.2 && hypot(f.x - f.ax, f.y - f.ay) > R * 0.5 && (f.x - f.ax) * ox + (f.y - f.ay) * oy > 0 {
                let back: Double = -(f.slx * ox + f.sly * oy) / ol / R
                if back > guardStats.givePull { guardStats.givePull = back }
            }
        }
    }

    /// What the fuzz test reads each frame (the same measures as the web's fuzz.js).
    struct LabShape {
        var flips = 0          // triangles really turned over: area below −2% of rest (pressed flat on the sill, area 0, does not count)
        var memFlips = 0       // the same in the remembered shape
        var strain = 0.0       // the longest mesh edge, times its rest length
        var memStrain = 0.0
        var nan = 0
    }
    func labShape() -> LabShape {
        var o = LabShape()
        var k = 0, q = 0
        while k + 2 < TRI.count, q < TRA.count {
            let a = TRI[k], b = TRI[k + 1], c = TRI[k + 2], lim: Double = -0.02 * TRA[q]
            if 0.5 * ((X[b] - X[a]) * (Y[c] - Y[a]) - (Y[b] - Y[a]) * (X[c] - X[a])) < lim { o.flips += 1 }
            if 0.5 * ((QX[b] - QX[a]) * (QY[c] - QY[a]) - (QY[b] - QY[a]) * (QX[c] - QX[a])) < lim { o.memFlips += 1 }
            k += 3; q += 1
        }
        var e = 0, j = 0
        while e + 1 < EDG.count, j < EDL.count {
            let a = EDG[e], b = EDG[e + 1], r: Double = EDL[j]
            let l: Double = hypot(X[a] - X[b], Y[a] - Y[b]) / r, lq: Double = hypot(QX[a] - QX[b], QY[a] - QY[b]) / r
            if l > o.strain { o.strain = l }
            if lq > o.memStrain { o.memStrain = lq }
            e += 2; j += 1
        }
        for i in 0..<N where !X[i].isFinite || !Y[i].isFinite { o.nan += 1 }
        return o
    }
    /// Where the turned-over triangles are, from the body's centre in radii (x right, y down), with each one's rest area as a share of the
    /// mean triangle: tells a thin sliver in the rest mesh from a real fold.
    func labFlipSites() -> [(x: Double, y: Double, rest: Double)] {
        guard !clusters.isEmpty, !TRA.isEmpty else { return [] }
        let c = clusters[gi], mean: Double = TRA.reduce(0, +) / Double(TRA.count)
        var out: [(x: Double, y: Double, rest: Double)] = []
        var k = 0, q = 0
        while k + 2 < TRI.count, q < TRA.count {
            let a = TRI[k], b = TRI[k + 1], d = TRI[k + 2]
            if 0.5 * ((X[b] - X[a]) * (Y[d] - Y[a]) - (Y[b] - Y[a]) * (X[d] - X[a])) < -0.02 * TRA[q] {
                out.append(((X[a] + X[b] + X[d]) / 3 - c.xc, (Y[a] + Y[b] + Y[d]) / 3 - c.yc, TRA[q] / mean))
            }
            k += 3; q += 1
        }
        return out.map { ($0.x / R, $0.y / R, $0.rest) }
    }
    /// The outline's sharpest corner in degrees (180 is a fold) and how many corners are past 75°.
    func labSharp() -> (max: Double, spikes: Int) {
        let n = bnd.count
        guard n >= 3 else { return (0, 0) }
        var m = 0.0, cnt = 0
        for i in 0..<n {
            let a = bnd[(i + n - 1) % n], b = bnd[i], c = bnd[(i + 1) % n]
            let ux: Double = X[b] - X[a], uy: Double = Y[b] - Y[a], vx: Double = X[c] - X[b], vy: Double = Y[c] - Y[b]
            let an: Double = abs(atan2(ux * vy - uy * vx, ux * vx + uy * vy)) * 180 / .pi
            if an > m { m = an }
            if an > 75 { cnt += 1 }
        }
        return (m, cnt)
    }
    /// Does the outline cross itself anywhere (web selfX > 0).
    func labCrossed() -> Bool { ringCrossed() }
    /// The particles' positions (a copy), the body's centre and radius: the fuzz test takes its jitter and picks its grab points from these.
    func labParticles() -> (x: [Double], y: [Double]) { (X, Y) }
    var labCentre: (x: Double, y: Double) { clusters.isEmpty ? (cx, cy) : (clusters[gi].xc, clusters[gi].yc) }
    var labRadius: Double { R }

    // MARK: - v2.52 C1 細絲、C2 水的呼吸: what the skin needs to know

    /// 0...1: how near the most-stretched grabbing finger is to the effective stretch limit, 0 up to 60% of it and 1 at the limit.
    /// With `thin` on the skin's rounding shrinks by it (多米 11-22 決定 6: the rounding hid a thinning strand of body). Web: jelRound().
    var thinLevel: Double {
        guard params.thin >= 0.5 else { return 0 }
        let lim: Double = max(0.01, effParams.maxPull)
        var s = 0.0
        for f in fingers.values where f.mode == .grab { s = max(s, f.stretch / lim) }
        return s > 0.6 ? min(1, (s - 0.6) / 0.4) : 0
    }
    /// −1...1 with its breath; the skin bends what is seen through it by this (C2, `wbreath`). Web: jelBreath().
    var breathWave: Double { sin(2 * .pi * brPhase) }

    // MARK: - Readouts for sound and haptics

    /// Kneading level 0...1: how fast grabbing fingers move (drives the looped rub sound).
    func rubLevel() -> Double {
        var sp = 0.0
        // smoothed travel rate from coalesced touches (a per-frame difference flickers at 120 Hz)
        for f in fingers.values where f.mode == .grab || (f.mode == .stroke && f.on) { sp = max(sp, f.speedC / R) }
        return fingers.isEmpty ? 0 : min(1, sp / 5)   // the controller scales this by `rubMax`
    }

    /// Stretch (radii, tanh-limited) of the most-stretched grabbing finger: drives the strand loop's pitch, brightness and loudness.
    var pullStretch: Double { max(fingers.values.filter { $0.mode == .grab }.map(\.stretch).max() ?? 0, pairStretch * effParams.pairMax / 2) }   // v2.38: two fingers pulling apart count as a pull too (web PAIR.stR)

    /// v2.63 B1 B3 (pullFx; web pullO): the fastest a grabbing finger opens new ground (radii a second), once it is past PullFxSet.d0 from where it took hold; 0 = none
    var pullOpen: Double {
        var m = 0.0
        for f in fingers.values where f.mode == .grab && f.om >= PullFxSet.d0 { m = max(m, f.ov) }
        return m
    }

    /// Any finger holding the body (not pushing from outside).
    var isGrabbing: Bool { fingers.values.contains { $0.mode == .grab } }

    /// Largest UITouch.majorRadius among the fingers down (for the panel readout).
    var maxTouchRadius: Double { fingers.values.map { $0.radius }.max() ?? 0 }

    /// How close the most-stretched grabbing finger is to the stretch limit, 0...1 (sharpness bonus, 提案第 15 條).
    var stretchLevel: Double {
        var m = 0.0
        for f in fingers.values where f.mode == .grab { m = max(m, f.stretch / max(0.01, min(effParams.maxPull, 2))) }   // same 2R cap as the pop
        return min(1, m)
    }

    /// How deep the press spread is, 0...1 relative to pressBase (sharpness drops a little while squashing, 提案第 15 條).
    var squashLevel: Double {
        var m = 0.0
        for f in fingers.values where f.mode == .grab { m = max(m, f.press / max(1, params.pressBase * R)) }
        return min(1, m)
    }

    /// How far the body is from its rest fit right now, 0...1 (drives continuous haptics while touched).
    var deformation: Double {
        guard N > 0 else { return 0 }
        var m = 0.0
        for i in 0..<N where GW[i] > 0 {
            m = max(m, hypot(X[i] - GX[i] / GW[i], Y[i] - GY[i] / GW[i]))
        }
        return min(1, m / (R * 0.6))
    }

    var isTouched: Bool { fingers.values.contains { $0.mode != .none } }

    /// v2.19 A4: how long the grabbing finger has been held still (s); past 0.8 s each breath comes through as one soft tap.
    var heldStill: Double { fingers.values.filter { $0.mode == .grab }.map(\.stillT).max() ?? 0 }
}

// MARK: - v2.57 新六隻的招牌 (web fxStep, fxInner, drawFx; 多米 11-22). Drawn on top of the jelly skin by the view; nothing here changes the physics.
extension SlimeRig {
    struct FxView {
        var stains: [(x: Double, y: Double, r: Double, k: Double)]   // world points, r already × R
        var core: [(x: Double, y: Double)]
        var coreSoft: [(x: Double, y: Double)] = []   // v2.61b: filled instead of core when params.coreSoft is on
        var pearls: [(x: Double, y: Double)]
        var capFlow: Double
    }
    /// How clouded a shaken slime is, for 汽水's fog (the glitter's haze is 0 while no glitter is drawn)
    var fogCloud: Double { params.shake >= 0.5 ? snwCloud : 0 }

    func fxReset() { fxStains = []; fxCoreN = 0; fxCore = []; fxCoreSoftN = 0; fxCoreSoft = []; fxCapFlow = 0; fxPearlN = 0; fxPearls = []; fxPearlSink = 0 }

    /// Inner body particles within rad·R of (0, cy·R) in the rest shape, evenly picked, at most `max` (by index, no random draws)
    private func fxInner(_ cyK: Double, _ rad: Double, _ maxN: Int) -> [Int] {
        var cand: [Int] = []
        for i in 0..<N where BIDX[i] < 0 && TID[i] < 0 && hypot(Q0X[i], Q0Y[i] - R * cyK) < R * rad { cand.append(i) }
        let st = max(1, Int((Double(cand.count) / Double(maxN)).rounded(.up)))
        return stride(from: 0, to: cand.count, by: st).map { cand[$0] }
    }

    func fxStep(_ dt: Double) {
        guard N > 0, !fx.isEmpty else { if !fxStains.isEmpty { fxStains = [] }; return }
        if fx.pearls > 0 {
            if fxPearlN != N {   // lower half of the belly, one high one low (by index they bunched beside the eyes like more eyes; in an arc like a mouth)
                fxPearlN = N; var used = Set<Int>(); fxPearls = []
                let n = fx.pearls
                for k in 0..<n {
                    let u: Double = n > 1 ? Double(k) / Double(n - 1) - 0.5 : 0, tx = u * R * 0.95, ty = R * (k % 2 == 1 ? 0.58 : 0.38 + 0.04 * Double(k % 3))
                    var bi = -1, bd = 1e9
                    for i in 0..<N where BIDX[i] < 0 && TID[i] < 0 && !used.contains(i) { let d = hypot(Q0X[i] - tx, Q0Y[i] - ty); if d < bd { bd = d; bi = i } }
                    if bi >= 0 { used.insert(bi); fxPearls.append((i: bi, x: X[bi], y: Y[bi])) }
                }
            }
            fxPearlSink *= exp(-dt / 5)
            var by = -1e9, cxs = 0.0
            for i in bnd { by = max(by, Y[i]); cxs += X[i] }
            cxs /= Double(max(1, bnd.count))
            let q = 1 - exp(-dt / 0.14), s = min(1, fxPearlSink * 1.6), n = fxPearls.count
            for k in fxPearls.indices {   // sunk: in a row just above the lowest point; 5 s back to their places; too far (a scene change, swimming in) jumps there
                let p = fxPearls[k]
                guard p.i < N else { continue }
                let tx = X[p.i] + (cxs + (Double(k) - Double(n - 1) / 2) * R * 0.24 - X[p.i]) * s * 0.8, ty = Y[p.i] + (by - R * 0.2 - Y[p.i]) * s
                if hypot(tx - p.x, ty - p.y) > R * 2 { fxPearls[k].x = tx; fxPearls[k].y = ty } else { fxPearls[k].x += (tx - p.x) * q; fxPearls[k].y += (ty - p.y) * q }
            }
        }
        if fx.cap != nil {   // held: runs down in 0.9 s; let go: back in a little over 3 s
            let g: Double = fingers.values.contains(where: { $0.mode == .grab }) ? 1 : 0
            fxCapFlow += (g - fxCapFlow) * (1 - exp(-dt / (g > 0 ? 0.9 : 3.2)))
        }
        if fx.purple != nil {   // rubbed: purple in a second; let go: down to a third in 7 s, spreading to 0.8R
            for k in fxStains.indices { fxStains[k].hot = false }
            for g in fingers.values where g.mode == .grab {
                var bi = -1, bd = 1e9
                for i in 0..<N { let d = hypot(X[i] - g.x, Y[i] - g.y); if d < bd { bd = d; bi = i } }
                if bi < 0 || bd > R * 0.5 { continue }
                var si = -1
                for (k, o) in fxStains.enumerated() where o.i < N { if hypot(X[o.i] - X[bi], Y[o.i] - Y[bi]) < R * 0.3 { si = k; break } }
                if si < 0 { fxStains.append((i: bi, k: 0, r: 0.28, hot: true)); if fxStains.count > 6 { fxStains.removeFirst() }; si = fxStains.count - 1 }
                fxStains[si].hot = true; fxStains[si].k = min(1, fxStains[si].k + dt * 1.1)
            }
            for k in fxStains.indices.reversed() {
                fxStains[k].r += (0.8 - fxStains[k].r) * (1 - exp(-dt / 5))
                if !fxStains[k].hot { fxStains[k].k *= exp(-dt / 7) }
                if fxStains[k].k < 0.01 || fxStains[k].i >= N { fxStains.remove(at: k) }
            }
        } else if !fxStains.isEmpty { fxStains = [] }
    }

    /// What the view draws for the chosen slime's signature; nil when it has none
    var fxView: FxView? {
        guard N > 0, !fx.isEmpty else { return nil }
        if fx.core != nil && fxCoreN != N { fxCoreN = N; fxCore = fxInner(0.4, 0.44, 22) }   // twenty-odd faint ones make an even lump; fewer, stronger ones looked like dirt
        let soft = fx.core != nil && params.coreSoft >= 0.5   // v2.61b (web coreSoft: fxInner(.42,.3,14))
        if soft && fxCoreSoftN != N { fxCoreSoftN = N; fxCoreSoft = fxInner(0.42, 0.3, 14) }
        return FxView(stains: fx.purple == nil ? [] : fxStains.filter { $0.i < N }.map { (x: X[$0.i], y: Y[$0.i], r: R * $0.r, k: $0.k) },
                      core: fx.core == nil || soft ? [] : fxCore.filter { $0 < N }.map { (x: X[$0], y: Y[$0]) },
                      coreSoft: soft ? fxCoreSoft.filter { $0 < N }.map { (x: X[$0], y: Y[$0]) } : [],
                      pearls: fxPearls.map { (x: $0.x, y: $0.y) },
                      capFlow: fxCapFlow)
    }
}

/// v2.61 A1 網格聯集的皮: what the mesh skin (JellySkin.swift) reads from the rig besides its particles (`labParticles`) and its ring (`bnd`). Here, not there,
/// so that this file needs Foundation only.
protocol SkinMeshSource: AnyObject {
    /// The body's triangles, three particle indices each (SlimeRig.TRI)
    var skinTri: [Int] { get }
    /// Their edges, two particle indices each, every edge once (SlimeRig.EDG)
    var skinEdg: [Int] { get }
    /// The rest shape the triangles were cut from (SlimeRig.Q0X, Q0Y)
    var skinRest: (x: [Double], y: [Double]) { get }
    /// Left, right and bottom wall in world points, infinite = none (SlimeRig.worldWalls)
    var skinWalls: (l: Double, r: Double, b: Double) { get }
}

/// v2.61 A1: what the mesh skin reads (JellySkin.swift, SkinMeshSource). Read only. TRI and EDG are replaced whole, never changed in place: the skin
/// tells a new mesh by the arrays having changed.
extension SlimeRig: SkinMeshSource {
    var skinTri: [Int] { TRI }
    var skinEdg: [Int] { EDG }
    var skinRest: (x: [Double], y: [Double]) { (Q0X, Q0Y) }
    var skinWalls: (l: Double, r: Double, b: Double) { let w = worldWalls; return (w.l, w.r, w.b) }
}

// MARK: - v2.64 擺飾變真 (未做 24; .uiux/04-手感/擺飾變真提案-暫定.md; web PROPDEF, propsInit, propIn, propAt, propHome, propKnock, propRelease, HANG, hangInit,
// hangAt, hangRing, hangKick, hangRelease, hangStep, SOFTB, selfMove, softHold, decoBody, propPair, propsStep, v2.44 to v2.61, line by line; the same numbers).
// 蠟燭和右端那件（擺飾 2 是書堆，其他是玻璃罐）是剛體，座標是畫面點（窗台那一層世界座標就是畫面座標）；牠推東西，東西不推牠，牠的點一個都不改。
// 風鈴、晴天娃娃是擺錘。decoReal 0：props 是空的、擺錘關著、圖照 v2.63 烤在背景裡，不抽亂數，這裡只剩檢查開關有沒有變。
extension SlimeRig {
    /// 網頁的 PROPDEF（d_ 開頭那三件；v2.30 的石頭盤、盆栽〔props 2〕手機沒有）。poly：圖片 0...1 方格裡的外框
    static let propDefs: [String: PropDef] = [
        "d_candle": PropDef(kind: "glass", asp: 264.0 / 254, wd: 56, com: 0.62, m: 150, tap: 7, poly: [(0.12, 0.995), (0.88, 0.995), (0.97, 0.80), (0.99, 0.15), (0.90, 0.02), (0.10, 0.02), (0.01, 0.15), (0.03, 0.80)]),
        "d_jar": PropDef(kind: "glass", asp: 342.0 / 283, wd: 60, com: 0.60, m: 70, tap: 6.5, poly: [(0.14, 0.995), (0.86, 0.995), (0.99, 0.80), (0.99, 0.38), (0.82, 0.02), (0.18, 0.02), (0.01, 0.38), (0.01, 0.80)]),
        "d_books": PropDef(kind: "book", asp: 313.0 / 460, wd: 104, com: 0.68, m: 420, tap: 1.2, poly: [(0.04, 0.995), (0.96, 0.995), (0.99, 0.50), (0.90, 0.12), (0.62, 0), (0.36, 0), (0.08, 0.22), (0.01, 0.60)])]
    /// 網頁 DECODEF 裡兩件掛著的寬度和長寬比
    private static let hangDef: [String: (w: Double, asp: Double)] = ["bell": (50, 514.0 / 206), "teru": (54, 429.0 / 267)]
    private enum PropK { static let mu = 0.55 }   // PROP_MU：窗台的摩擦
    /// SOFTB（v2.61 C7 bumpSoft）：牠自己走路撞到的，角度最多 lean、位置最多挪 move 個半徑，碰完 hold 秒內都夾著；k 推的力道、w 最快轉速、back 每秒收回幾弧度
    private enum SoftB { static let lean = 0.16, move = 0.08, hold = 1.6, k = 0.12, w = 1.6, back = 2.0 }

    /// DREAL()：擺飾是真的（而且有擺飾、在窗台上）
    var dreal: Bool { params.decoReal >= 0.5 && params.deco >= 0.5 && sillOn && sillG != nil }
    /// DRon()：牠對擺飾有反應（大腦開著）
    private var drOn: Bool { dreal && brOn && params.decoReact >= 0.5 }
    private func decoKey() -> Int { (dreal ? 10 : 0) + Int(params.deco.rounded()) }
    private func wrapA(_ a: Double) -> Double { atan2(sin(a), cos(a)) }
    private func sgn(_ v: Double) -> Double { v > 0 ? 1 : (v < 0 ? -1 : 0) }
    /// drRecent：有值、不在未來（時鐘被重建倒回去）、T 秒內
    private func drRecent(_ v: Double?, _ T: Double) -> Bool { if let v { return t >= v && t - v < T }; return false }

    /// propsInit：東西擺回原位（重建、面板改了擺飾或擺飾變真）
    private func propsInit() {
        props.removeAll(); decoKeyNow = decoKey(); hangInit(); drPush = nil
        for f in fingers.values { f.propK = -1; f.hangN = nil }
        guard dreal, let g = sillG else { return }
        let U = g.U
        for im in ["d_candle", Int(params.deco.rounded()) == 2 ? "d_books" : "d_jar"] {
            guard let d = Self.propDefs[im] else { continue }
            let wd = d.wd * U, hg = wd * d.asp
            var P: [(Double, Double)] = d.poly.map { (($0.0 - 0.5) * wd, ($0.1 - d.com) * hg) }
            var A = 0.0
            for i in 0..<P.count { let a = P[i], b = P[(i + 1) % P.count]; A += a.0 * b.1 - b.0 * a.1 }
            if A < 0 { P.reverse() }
            var nx: [Double] = [], ny: [Double] = []
            var r = 0.0, base = -1e9, hw = 0.0
            for i in 0..<P.count {
                let a = P[i], b = P[(i + 1) % P.count], ex = b.0 - a.0, ey = b.1 - a.1, l0 = hypot(ex, ey), l: Double = l0 > 0 ? l0 : 1
                nx.append(ey / l); ny.append(-ex / l)
                r = max(r, hypot(a.0, a.1)); base = max(base, a.1); hw = max(hw, abs(a.0))
            }
            let x: Double = im == "d_candle" ? g.l + wd / 2 + 8 : g.r - wd / 2 - 8, y = g.fl - base
            props.append(Prop(im: im, kind: d.kind, tap: d.tap, w: wd, h: hg, ox: wd * 0.5, oy: hg * d.com, px: P.map { $0.0 }, py: P.map { $0.1 }, nx: nx, ny: ny,
                              r: r, hw: hw, base: base, m: d.m, I: d.m * (wd * wd + hg * hg) / 12, x: x, y: y, t: t))
        }
    }
    /// propIn：(x, y) 在外框裡（容許外面 pad 點）
    private func propIn(_ p: Prop, _ x: Double, _ y: Double, _ pad: Double) -> Bool {
        let c = cos(p.a), s = sin(p.a), dx = x - p.x, dy = y - p.y, lx = c * dx + s * dy, ly = -s * dx + c * dy
        for k in 0..<min(p.px.count, p.nx.count) where (lx - p.px[k]) * p.nx[k] + (ly - p.py[k]) * p.ny[k] > pad { return false }
        return true
    }
    /// propAt：畫面上這一點底下的東西，前面的先；−1 沒有
    private func propAt(_ x: Double, _ y: Double) -> Int {
        for k in props.indices.reversed() where !props[k].gone && props[k].alpha > 0.5 && propIn(props[k], x, y, R * 0.08) { return k }
        return -1
    }
    private func propHome(_ p: inout Prop) {
        p.x = p.hx; p.y = p.hy; p.a = 0; p.vx = 0; p.vy = 0; p.va = 0; p.gone = false; p.fell = false; p.tip = false; p.fade = 1; p.alpha = 0; p.lastHit = t
    }
    /// propKnock：碰到的聲音（0.14 秒內只一次）；far：掉到看不到的地方，遠遠一聲
    private func propKnock(_ p: inout Prop, _ g: Double, far: Bool = false) {
        if t - p.knockT < 0.14 { return }
        p.knockT = t
        if far { onEvent?(.fx(kind: "fallout", gain: max(0.3, min(1, g)), delay: 0)); return }
        onEvent?(.knock(kind: p.im == "d_candle" ? "candle" : p.kind, gain: max(0.05, min(1, g))))
        drLook(selfT: p.selfT, fingT: p.fingT, catT: p.catT, lookAt: &p.lookAt, 0.12, p.x, p.y)   // v2.46
    }
    /// propRelease：放手；很快點一下（0.25 秒內、移動不到 0.12R）往手指的反方向晃
    private func propRelease(_ f: Finger) {
        let k = f.propK
        guard props.indices.contains(k) else { return }
        var p = props[k]
        p.held = nil; p.lastHit = t; p.fingT = t
        if t - f.tDown < 0.25 && hypot(f.rawX - f.ax, f.rawY - f.ay) < R * 0.12 { p.va += (f.ax < p.x ? 1 : -1) * p.tap; propKnock(&p, 0.22) }
        props[k] = p
    }

    // 網頁的 HANG：a 角度（正的是下端往左），va 角速度。搖手機踢一下，手指抓著就跟手指，放手自己晃到停；風鈴會響
    private func hangInit() {
        for k in hangs.indices {
            hangs[k].a = 0; hangs[k].va = 0; hangs[k].held = nil; hangs[k].ringT = -9; hangs[k].on = false; hangs[k].x = 0; hangs[k].y = 0; hangs[k].w = 0; hangs[k].h = 0
            hangs[k].selfT = nil; hangs[k].fingT = nil; hangs[k].lookAt = nil; hangs[k].touch = false
        }
        guard dreal, let g = sillG else { return }
        let U = g.U
        var list: [(String, Double, Double)] = [("bell", g.jr - 46 * U, g.gy)]
        if Int(params.deco.rounded()) >= 2 { list.append(("teru", g.gx + 46 * U, g.gy)) }
        for (n, x, y) in list {
            guard let k = hangs.firstIndex(where: { $0.name == n }), let d = Self.hangDef[n] else { continue }
            let w = d.w * U
            hangs[k].on = true; hangs[k].x = x; hangs[k].y = y; hangs[k].w = w; hangs[k].h = w * d.asp
        }
    }
    /// hangAt：畫面上這一點底下的鐘或紙籤（上面那段細繩不算）
    private func hangAt(_ sx: Double, _ sy: Double) -> String? {
        guard dreal else { return nil }
        for q in hangs where q.on {
            let dx = sx - q.x, dy = sy - q.y, c = cos(q.a), s = sin(q.a), lx = c * dx + s * dy, ly = -s * dx + c * dy
            if abs(lx) < q.w / 2 + 10 && ly > q.h * 0.25 && ly < q.h + 10 { return q.name }
        }
        return nil
    }
    private func hangRing(_ q: inout Hang, _ g: Double) {
        if !q.ring || t - q.ringT < 0.16 { return }
        q.ringT = t
        onEvent?(.knock(kind: "bell", gain: max(0.08, min(1, g))))
        drLook(selfT: q.selfT, fingT: q.fingT, catT: nil, lookAt: &q.lookAt, 0.15, q.x - sin(q.a) * q.h * 0.7, q.y + q.h * 0.7)   // v2.46
    }
    /// hangKick：搖手機（dir ±1）
    private func hangKick(_ dir: Double) {
        guard dreal else { return }
        for k in hangs.indices where hangs[k].on && hangs[k].held == nil { var q = hangs[k]; q.va += dir * q.kick; hangRing(&q, 0.5); hangs[k] = q }
    }
    private func hangRelease(_ f: Finger) {
        guard let k = hangs.firstIndex(where: { $0.name == f.hangN }) else { return }
        var q = hangs[k]
        q.held = nil; q.fingT = t
        if t - f.tDown < 0.25 && hypot(f.rawX - f.ax, f.rawY - f.ay) < R * 0.12 { q.va += (f.ax < q.x ? -1 : 1) * q.tap; hangRing(&q, 0.45) }
        hangs[k] = q
    }
    /// hangStep（每一小步）：抓著就轉向手指；放開是有阻尼的擺；晃過正中間夠快，風鈴響
    private func hangStep(_ dt: Double) {
        for k in hangs.indices where hangs[k].on {
            var q = hangs[k]
            var hd: Finger? = nil
            if let id = q.held { hd = fingers[id]; if hd == nil || hd?.hangN != q.name { q.held = nil; hd = nil } }
            let a0 = q.a
            if let hd {
                q.fingT = t
                let ta = max(-1.2, min(1.2, atan2(-(hd.rawX - q.x), max(8, hd.rawY - q.y))))
                q.va += ((ta - q.a) / 0.06 - q.va) * 0.3
            } else { q.va += (-q.w2 * sin(q.a) - q.damp * q.va) * dt }
            q.a += q.va * dt
            if q.a > 1.4 { q.a = 1.4; q.va = min(0, q.va) } else if q.a < -1.4 { q.a = -1.4; q.va = max(0, q.va) }
            if a0 * q.a < 0 && abs(q.va) > 1.5 { hangRing(&q, abs(q.va) / 7) }
            if q.held == nil && abs(q.a) < 0.002 && abs(q.va) < 0.02 { q.a = 0; q.va = 0 }
            hangs[k] = q
        }
    }

    /// selfMove（bumpSoft）：牠自己在動：身上沒有手指、1.5 秒內沒被碰、不在空中、沒在跳
    private func selfMove() -> Bool {
        if !(params.bumpSoft >= 0.5) || sillAir || sillHop != nil || sillGrab || (t >= lastTouch && t - lastTouch < 1.5) { return false }
        for f in fingers.values where f.mode == .grab || f.mode == .stroke || (f.mode == .push && t - f.hitT < 0.5 && !f.lure) { return false }
        return true
    }
    /// softHold：牠自己走路撞到的，SoftB.hold 秒內角度最多 SoftB.lean、位置最多 SoftB.move 個半徑
    private func softHold(_ p: inout Prop, _ dt: Double) {
        if !drRecent(p.softT, SoftB.hold) || p.held != nil || p.tip || drRecent(p.fingT, 1.2) || drRecent(p.catT, 2) { return }
        let w = wrapA(p.a), m = R * SoftB.move
        if abs(w) > SoftB.lean { p.a -= sgn(w) * min(abs(w) - SoftB.lean, SoftB.back * dt); if p.va * w > 0 { p.va = 0 } }
        if p.x > p.softX + m { p.x = p.softX + m; if p.vx > 0 { p.vx = 0 } } else if p.x < p.softX - m { p.x = p.softX - m; if p.vx < 0 { p.vx = 0 } }
    }
    /// decoBody（一幀一次，在小步之後）：落在東西裡的點，用它們跟上一幀比真的移動了多少去帶東西（走路的整團平移也算），只往牠移動的方向推，
    /// 牠停下來不會把東西煞住。牠的點一個都不改。掛著的兩件被穿過去的點帶著晃。
    private func decoBody(_ dt: Double) {
        guard dreal, params.decoBody >= 0.5, dt > 0, N > 0 else { dbOK = false; return }
        if dbX.count != N || dbY.count != N { dbX = [Double](repeating: 0, count: N); dbY = [Double](repeating: 0, count: N); dbOK = false }
        var ok = dbOK && sillPlane == .room
        let lim = R * 0.4
        if ok { for i in stride(from: 0, to: N, by: 7) where abs(X[i] - dbX[i]) > lim || abs(Y[i] - dbY[i]) > lim { ok = false; break } }   // 重擺、換層那種瞬間移動不算
        if ok {
            let K: Double = 14 * params.decoPush, vc = 3000.0, selfM = selfMove()
            for k in props.indices {
                var p = props[k]
                if p.gone || p.alpha < 0.6 || p.held != nil || (drOn && drRecent(p.catT, 1.5)) { continue }   // v2.46 牠正在推的那件：偽足縮回來時不把它帶回來
                let r2 = p.r * p.r
                var n = 0, sx = 0.0, sy = 0.0, tq = 0.0, ux = 0.0, uy = 0.0
                for i in 0..<N {
                    let dx = X[i] - p.x, dy = Y[i] - p.y
                    if dx * dx + dy * dy > r2 || !propIn(p, X[i], Y[i], 0) { continue }
                    let vx = max(-vc, min(vc, (X[i] - dbX[i]) / dt)), vy = max(-vc, min(vc, (Y[i] - dbY[i]) / dt))
                    let rx = vx - (p.vx - p.va * dy), ry = vy - (p.vy + p.va * dx)
                    n += 1; sx += rx; sy += ry; ux += vx; uy += vy; tq += dx * ry - dy * rx
                }
                if n == 0 { continue }
                let soft = selfM && !p.tip
                if soft { if !drRecent(p.softT, SoftB.hold) { p.softX = p.x }; p.softT = t } else { p.softT = nil }
                let fn = Double(n)
                let cov = min(1, fn / 5), kk = K * (100 / p.m) * cov * dt, us = hypot(ux, uy) / fn
                let ex: Double = us > 1 ? ux / fn / us : 0, ey: Double = us > 1 ? uy / fn / us : 0
                let ru = max(0, sx / fn * ex + sy / fn * ey), mx = ru * ex, my = ru * ey, sp = ru
                if soft {
                    p.vx += mx * kk * SoftB.k
                    if p.tc > 0 { p.va = max(-SoftB.w, min(SoftB.w, p.va + mx * kk / p.base * 0.6)) }
                } else {
                    p.vx += mx * kk
                    if my > 0 || sp > R * 3 { p.vy += my * kk * 0.5 }   // 往上只有很快才帶得起來：牠慢慢站起來不會把東西吸上去
                    p.va += tq / fn / (p.I / p.m) * kk * 0.6
                    if p.tc > 0 { p.va += mx * kk / p.base * 0.6 }   // 站在窗台上：底被窗台卡住、上面被帶著走，所以往被帶的方向晃
                }
                if sp > R * 0.5 { p.lastHit = t; p.selfT = t }
                if sp > R * 2.2 && !(soft && drRecent(p.softK, 6)) { if soft { p.softK = t }; propKnock(&p, min(1, sp / (R * 9))) }
                props[k] = p
            }
            for k in hangs.indices where hangs[k].on && hangs[k].held == nil {
                var q = hangs[k]
                let c = cos(q.a), sn = sin(q.a)
                var n = 0, sw = 0.0
                for i in 0..<N {
                    let dx = X[i] - q.x, dy = Y[i] - q.y
                    if dy < 0 || dy > q.h + 4 || abs(dx) > q.h { continue }
                    let lx = c * dx + sn * dy, ly = -sn * dx + c * dy
                    if abs(lx) > q.w / 2 || ly < q.h * 0.25 || ly > q.h { continue }
                    n += 1; sw += -((X[i] - dbX[i]) / dt * c + (Y[i] - dbY[i]) / dt * sn) / ly
                }
                if n > 0 {
                    q.selfT = t
                    let w = max(-12, min(12, sw / Double(n)))
                    q.va += (w - q.va) * min(1, Double(n) / 3) * 20 * dt
                    if !q.touch { hangRing(&q, 0.2 + abs(w) / 6) }
                }
                q.touch = n > 0
                hangs[k] = q
            }
        }
        for i in 0..<N { dbX[i] = X[i]; dbY[i] = Y[i] }
        dbOK = true
    }
    /// propPair：A 的角推出 B 外面，再給一個回彈 0.1 的衝量
    private func propPair(_ A: inout Prop, _ B: inout Prop) {
        let ca = cos(A.a), sa = sin(A.a), cb = cos(B.a), sb = sin(B.a), wa = 1 / A.m, wb = 1 / B.m
        for q in 0..<A.px.count {
            let qx = A.px[q], qy = A.py[q]
            let wx = A.x + ca * qx - sa * qy, wy = A.y + sa * qx + ca * qy, dx = wx - B.x, dy = wy - B.y, lx = cb * dx + sb * dy, ly = -sb * dx + cb * dy
            var best = -1e9, bk = -1
            for k in 0..<min(B.px.count, B.nx.count) {
                let d = (lx - B.px[k]) * B.nx[k] + (ly - B.py[k]) * B.ny[k]
                if d > 0 { bk = -2; break }
                if d > best { best = d; bk = k }
            }
            if bk < 0 { continue }
            let nx = cb * B.nx[bk] - sb * B.ny[bk], ny = sb * B.nx[bk] + cb * B.ny[bk], pen = -best, sum = wa + wb
            A.x += nx * pen * 0.6 * wa / sum; A.y += ny * pen * 0.6 * wa / sum; B.x -= nx * pen * 0.6 * wb / sum; B.y -= ny * pen * 0.6 * wb / sum
            let rax = wx - A.x, ray = wy - A.y, rbx = wx - B.x, rby = wy - B.y
            let vn = (A.vx - A.va * ray - B.vx + B.va * rby) * nx + (A.vy + A.va * rax - B.vy - B.va * rbx) * ny
            if vn >= 0 { continue }
            let ra = rax * ny - ray * nx, rb = rbx * ny - rby * nx, j = -1.1 * vn / (wa + wb + ra * ra / A.I + rb * rb / B.I)
            A.vx += nx * j * wa; A.vy += ny * j * wa; A.va += ra * j / A.I; B.vx -= nx * j * wb; B.vy -= ny * j * wb; B.va -= rb * j / B.I
            A.lastHit = t; B.lastHit = t
            if -vn > R * 1.2 { propKnock(&A, min(1, -vn / (R * 9))); propKnock(&B, min(1, -vn / (R * 9))) }
        }
    }
    /// propsStep（每一小步）：重力、手指拿著、窗台（摩擦，很快時回彈 0.15）、躺平停住、倒下、掉出窗台再回來
    private func propsStep(_ dt: Double) {
        guard let g = sillG else { return }
        let G0 = R * sillGrav
        for k in props.indices {
            var p = props[k]
            if p.gone { if t >= p.backAt { propHome(&p) }; props[k] = p; continue }   // propSlotFree：這幾件一律算空著
            if p.fade != 0 { p.alpha = max(0, min(1, p.alpha + p.fade * dt / 0.4)); if p.fade < 0 && p.alpha <= 0 { propHome(&p) } else if p.fade > 0 && p.alpha >= 1 { p.fade = 0 } }
            var hd: Finger? = nil
            if let id = p.held { hd = fingers[id]; if hd == nil || hd?.propK != k { p.held = nil; hd = nil } }
            if let hd {   // 手指抓的是你按到的那一點，東西繞著那一點被帶著走。抓上面往旁邊推會倒，抓下面拖是平移
                p.fingT = t
                let c0 = cos(p.a), s0 = sin(p.a), rx = c0 * p.hlx - s0 * p.hly, ry = s0 * p.hlx + c0 * p.hly
                let ex = hd.rawX - (p.x + rx), ey = hd.rawY - (p.y + ry), k2 = p.w * p.w * 0.1, den = rx * rx + ry * ry + k2
                p.vx += (ex / 0.05 - p.vx) * 0.25; p.vy += (ey / 0.05 - p.vy) * 0.25
                p.va += ((rx * ey - ry * ex) / den / 0.05 - p.va) * 0.2
                if p.tc == 0 { p.va -= rx * G0 / den * dt }   // 拿離窗台時像提著：重的那頭垂下去
                p.vy += G0 * dt * 0.5
                p.lastHit = t
            } else { p.vy += G0 * dt }
            p.x += p.vx * dt; p.y += p.vy * dt; p.a += p.va * dt
            let c = cos(p.a), s = sin(p.a)
            var touch = 0
            for q in 0..<p.px.count {
                let rx = c * p.px[q] - s * p.py[q], ry = s * p.px[q] + c * p.py[q], wx = p.x + rx, wy = p.y + ry
                if wy > g.fl && wy < g.fl + R * 0.5 && wx > g.sl && wx < g.sr {
                    p.y -= (wy - g.fl) * 0.7; touch += 1
                    let vn = p.vy + p.va * rx
                    if vn > 0 {
                        let e: Double = vn > R * 1.5 ? 0.15 : 0, j = -(1 + e) * vn / (1 / p.m + rx * rx / p.I)
                        p.vy += j / p.m; p.va += j * rx / p.I
                        let vt = p.vx - p.va * ry, lim = PropK.mu * abs(j), jt = max(-lim, min(lim, -vt / (1 / p.m + ry * ry / p.I)))
                        p.vx += jt / p.m; p.va -= ry * jt / p.I
                        if vn > R * 1.2 { propKnock(&p, vn / (R * 9)) }
                    }
                }
            }
            softHold(&p, dt)
            p.tc = touch
            if p.held == nil && touch >= 2 { let f = PropK.mu * G0 * dt; p.vx = abs(p.vx) <= f ? 0 : p.vx - sgn(p.vx) * f }   // v2.45 平放著滑會被窗台磨停
            if touch > 0 {
                p.vx *= 0.9985; p.va *= 0.994
                if p.held == nil && touch >= 2 && abs(p.vx) + abs(p.vy) < 7 && abs(p.va) < 0.22 {   // 兩個點著地才算停；只差一點點就慢慢躺平
                    p.vx = 0; p.vy = 0; p.va = 0
                    let w = wrapA(p.a)
                    if abs(w) < 0.08 { p.a -= w * 0.2 }
                }
            }
            if abs(wrapA(p.a)) > 0.6 { p.upT = t }   // 蠟燭倒了火就熄，扶正 3 秒後再亮
            if p.held == nil {   // v2.46 倒下那一下（歪過 0.6 算倒，回到 0.3 以內才算站回來）
                let w = abs(wrapA(p.a))
                if w > 0.6 && !p.tip { p.tip = true; drCrash(&p, 0.35); onEvent?(.fx(kind: "topple", gain: 0.7, delay: 0)) } else if w < 0.3 { p.tip = false }
            }
            if p.y > g.fl + R * 0.9 && !p.fell { p.fell = true; propKnock(&p, 0.55, far: true); drCrash(&p, 0.45) }   // 掉到窗台下面：看不到了，聽得到一聲
            if p.y > g.fl + R * 2.5 || p.x > W + R * 2 || p.x < -R * 2 {
                if !p.fell { propKnock(&p, 0.45, far: true); drCrash(&p, 0.45) }
                p.gone = true; p.upT = t + 20; p.alpha = 0; p.backAt = t + 20; p.vx = 0; p.vy = 0; p.va = 0; p.fade = 0; p.held = nil
            }
            props[k] = p
        }
        if props.count > 1 {
            for i in 0..<(props.count - 1) {
                for j in (i + 1)..<props.count where !props[i].gone && !props[j].gone && props[i].alpha > 0.6 && props[j].alpha > 0.6 {
                    var A = props[i], B = props[j]
                    propPair(&A, &B); propPair(&B, &A)
                    props[i] = A; props[j] = B
                }
            }
        }
        for k in props.indices where !props[k].gone && props[k].held == nil && props[k].fade == 0 && t - props[k].lastHit >= 25 {   // 25 秒沒人碰：倒著或移位的淡出、回原位
            let w = wrapA(props[k].a)
            if abs(w) > 0.08 || hypot(props[k].x - props[k].hx, props[k].y - props[k].hy) > 2 { props[k].fade = -1 } else { props[k].lastHit = t }
        }
    }

    // MARK: 給畫面讀的（畫面點；窗台那一層世界座標就是畫面座標）
    struct PropView { let im: String; let x, y, a, w, h, ox, oy, alpha: Double; let lit: Bool; let shadow: Double }
    /// 蠟燭和右端那件現在在哪（擺飾變真關著時是空的）。lit：夜晚的蠟燭、站起來超過 3 秒。shadow：窗台上影子的濃淡（0 沒有），網頁 drawProps
    var propViews: [PropView] {
        guard dreal, let g = sillG else { return [] }
        var o: [PropView] = []
        for p in props where !p.gone && p.alpha > 0.01 {
            let near = max(0, 1 - abs(g.fl - (p.y + p.base)) / (R * 0.8))
            o.append(PropView(im: p.im, x: p.x, y: p.y, a: p.a, w: p.w, h: p.h, ox: p.ox, oy: p.oy, alpha: p.alpha,
                              lit: p.im == "d_candle" && sceneKind == 2 && t - p.upT > 3, shadow: near > 0 && p.x > g.sl && p.x < g.sr ? near * p.alpha : 0))
        }
        return o
    }
    /// 掛著那件的角度：擺飾變真開著是擺錘，關著是 v2.37 搖手機之後的晃（amp）
    func hangAngle(_ name: String, amp: Double) -> Double {
        if dreal, let q = hangs.first(where: { $0.name == name }), q.on { return q.a }
        return decoSwing(amp)
    }
}

// MARK: - v2.64 擺飾變真第 3 片「牠有反應」(decoReact, decoCat, decoScare; web DR, drReset, drSelf, drLook, drCrash, drCandleX, drCatPick, drCatOK, drCat, drStep,
// v2.46, line by line; the same numbers). 只用大腦現有的五個需求，不加新數字；牠的點一個都不改。decoReact 0（或大腦關著）：drOn false，這裡什麼都不做、不抽亂數。
// 看：東西被碰到出聲、風鈴響。牠自己帶到的、推的不算。眼睛看過去 1.4 秒、好奇 +；好奇超過 0.6 而且在休息，就伸偽足探。
// 嚇：東西倒下或掉下窗台。怕漲 0.35／0.45 × 遠近 × 習慣（同一件每倒一次減半，只算這一次打開）× 牠自己帶倒的一半。晚 0.12 秒縮一下；睡著嚇醒。
// 你抓著牠、摸著牠、剛放手 1 秒內不嚇，只睜大眼 0.8 秒。不記進「這格被嚇過」。
// 蠟燭：夜晚、蠟燭亮著、在原位，而且牠沒有特別喜歡的位置：家挪到蠟燭旁邊。
// 推：熟 0.5 以上、心情 0.2 以上、好奇 0.6 以上，休息到時間時跟其他需求一起比。走到東西旁邊、看你、伸偽足，偽足伸出去六成以後東西每秒往窗台邊挪 0.2R。一次打開最多 2 次、隔 45 秒。牠推下去的不嚇，開心一下。
extension SlimeRig {
    /// drReset（網頁 brainReset 裡）：每次打開、換一隻都從頭
    func drReset() { drHab = [:]; drWideT = nil; drLookT = -9; drCats = 0; drCatT = -99; drCatLast = ""; drPush = nil }
    private func drSelf(_ selfT: Double?, _ fingT: Double?) -> Bool { drRecent(selfT, 1.2) && !drRecent(fingT, 1.2) }
    /// drLook：東西動了、響了，牠看過去；好奇夠高、在休息就伸偽足探
    private func drLook(selfT: Double?, fingT: Double?, catT: Double?, lookAt: inout Double?, _ dq: Double, _ x: Double, _ y: Double) {
        if !drOn || slpOn || drSelf(selfT, fingT) || drRecent(catT, 3) || drRecent(lookAt, 1.5) { return }
        lookAt = t
        brain.q = min(1, brain.q + dq); drLookT = t + 1.4; drLX = x; drLY = y
        if brain.q > 0.6 && lifeSt == .rest && fingers.isEmpty && sillRoute == nil && !attOn && brainSillFree() && lv(params.lifeAttend) {
            attOn = true; attAt = t + 0.45; attX = x; attY = y
            brain.q = max(0, brain.q - 0.25)
        }
    }
    /// drCrash：倒下、滑出去、落地是同一件事，4 秒內只算一次
    private func drCrash(_ p: inout Prop, _ base: Double) {
        if !drOn || drRecent(p.crashAt, 4) { return }
        p.crashAt = t
        if drRecent(p.catT, 4) { happyT = t; voice("happy", 0.6); eyeUser = t + 1.4; return }   // 牠自己推下去的：開心一下
        guard let g = sillG, !clusters.isEmpty else { return }
        let n = drHab[p.im] ?? 0, d = hypot(p.x - clusters[gi].xc, min(p.y, g.fl) - clusters[gi].yc), near = max(0.5, min(1, 1 - 0.5 * (d - R) / (2 * R)))
        let amt = base * near * pow(0.5, Double(n)) * (drSelf(p.selfT, p.fingT) ? 0.5 : 1) * params.decoScare
        drHab[p.im] = n + 1
        var held = t >= lastTouch && t - lastTouch < 1
        for f in fingers.values where f.mode == .grab || f.mode == .stroke || f.mode == .push { held = true }
        if held { drHab[p.im] = n; if amt >= 0.02 { drWideT = t; eyePulse = t }; return }   // 抓著、摸著、剛放手：只睜大眼 0.8 秒，身體、怕、心情、習慣都不動
        if amt < 0.02 { return }
        moodScare = min(1, moodScare + amt); mem.ev.sc = max(mem.ev.sc, moodScare)   // 不記進「這格被嚇過」
        if slpOn { if amt >= 0.08 { wake(true) } }
        else {
            if amt >= 0.08 { voice("startle", min(0.9, 0.4 + amt), at: t + 0.12) }
            flAt = t + 0.12; flPre = lifeSt == .rest ? .rest : .go; flBoost = 1 + amt; eyePulse = t + 0.12
        }
        drLookT = t + 1.6; drLX = p.x; drLY = min(p.y, g.fl)
    }
    /// drCandleX：夜晚蠟燭亮著、在原位：家在蠟燭旁邊的 x；不然 nil
    private func drCandleX() -> Double? {
        guard drOn, sceneKind == 2, let g = sillG, let p = props.last(where: { $0.im == "d_candle" }) else { return nil }
        if p.gone || p.fade != 0 || t - p.upT <= 3 || abs(p.x - p.hx) > R * 0.3 { return nil }
        return max(g.l + R * 0.9, min(g.bx, p.hx + p.hw + R * 0.85))
    }
    /// drCatPick：站好、在原位、沒人拿著的那件；上次推過的那件讓給另一件
    private func drCatPick() -> Int {
        var b = -1
        for k in props.indices {
            let p = props[k]
            if p.gone || p.fade != 0 || p.held != nil || p.alpha < 1 || abs(p.a) > 0.1 || abs(p.x - p.hx) > 4 { continue }
            if b < 0 || props[b].im == drCatLast { b = k }
        }
        return b
    }
    private func drCatOK() -> Bool {
        drOn && params.decoCat >= 0.5 && drCats < 2 && t - drCatT > 45 && impTrust >= 0.5 && (!mdOn || brainM > 0.2) && brain.q > 0.6 && sillPlane == .room && !sillInBowl
            && brainSillFree() && fingers.isEmpty && drCatPick() >= 0
    }
    /// drCat：走到東西旁邊、看你、等一下、伸偽足推、再看你、再推
    private func drCat() {
        let k = drCatPick()
        guard props.indices.contains(k), let g = sillG else { lifeUntil = t + restDur(); return }
        let p = props[k], side: Double = p.hx > g.bx ? 1 : -1, tx = sillClampX(p.x - side * (p.hw + R * 1.05)), a: Double = side > 0 ? 0.3 : .pi - 0.3
        drCats += 1; drCatT = t; drCatLast = p.im
        brain.q = max(0, brain.q - 0.5)
        let look: (Double) -> RouteStep = { T in .fn({ [weak self] in guard let self else { return }; self.eyeUser = self.t + T }) }
        routeStart([.walk(surf: "floor", to: tx), look(1.6), .wait(T: 0.9),
                    .fn({ [weak self] in guard let self else { return }; self.drPush = (k: k, side: side, route: self.sillRoute?.id ?? -1) }),
                    .sniff(a: a, L: 1.1, T: 2.2), look(1.2), .sniff(a: a, L: 1.3, T: 2.4),
                    .fn({ [weak self] in guard let self else { return }; self.drPush = nil; self.eyeUser = self.t + 1.2 })])
    }
    /// drStep（一幀一次）：偽足伸出去六成以後，東西每秒往窗台邊挪 0.2R
    private func drStep(_ dt: Double) {
        guard let U = drPush else { return }
        let k = U.k
        guard props.indices.contains(k) else { drPush = nil; return }
        let p = props[k]
        if !drOn || sillRoute?.id != U.route || p.gone || p.held != nil || p.fell { drPush = nil; return }
        guard let s = sniffs.last, !(s.cut > 0), sniffEnv(s) >= 0.6 else { return }
        props[k].vx = U.side * R * 0.2; props[k].lastHit = t; props[k].catT = t; props[k].selfT = t
    }
}
