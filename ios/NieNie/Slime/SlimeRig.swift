import Foundation

/// Things the rig asks the outside world to play. Picture, sound and haptics
/// all react to the same event in the same frame.
enum SlimeEvent {
    case press(gain: Double)                 // a finger landed on the body
    case pull(gain: Double, rate: Double)    // stretched past another step
    case release(gain: Double, rate: Double, special: Bool) // let go; gain follows release strength; special = 偶發特別回彈
    case tick(gain: Double)                  // texture tick while kneading (提案第 13 條)
    case squish(gain: Double)                // two grabbing fingers pinched closer (提案第 24 條)
    case tap                                 // VoiceOver / buttons
}

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
    /// Reduce Motion: idle motion and twitches halved. Feedback stays on.
    var reduceMotion = false
    var onEvent: ((SlimeEvent) -> Void)?

    private(set) var W = 0.0, H = 0.0, R = 100.0, cx = 0.0, cy = 0.0, h = 10.0
    private(set) var homeX = 0.0, homeY = 0.0
    private(set) var N = 0

    // particle state (positions in view points)
    private var X: [Double] = [], Y: [Double] = [], PX: [Double] = [], PY: [Double] = []
    private var Q0X: [Double] = [], Q0Y: [Double] = []   // original rest shape (zero mean)
    private var QX: [Double] = [], QY: [Double] = []     // remembered (plastic) rest shape
    private var EX: [Double] = [], EY: [Double] = []     // rest shape with idle breathing / wriggle / drift
    private var GX: [Double] = [], GY: [Double] = [], GW: [Double] = []
    private var RX: [Double] = [], RY: [Double] = []
    private var TU: [Double] = [], TUB: [Double] = [], KF: [Double] = []
    private var TID: [Int] = [], BIDX: [Int] = []
    private var GRAB: [Bool] = []

    private(set) var bnd: [Int] = []     // boundary particle indices, in ring order
    private var bndL: [Double] = []      // rest distance between ring neighbours
    private var bndL2: [Double] = []     // rest distance between ring particles two apart (no folding back)

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
    // fleeing: home rushes out on an ease-out (fast, the camera lags and it leaves the screen a bit), then it curls up a moment
    private var escOn = false, escT0 = 0.0, escT = 1.0, escSX = 0.0, escSY = 0.0, escDX = 0.0, escDY = 0.0
    private var introMini = false
    /// Purr strength 0...1 (the controller turns it into soft taps).
    private(set) var purr = 0.0

    /// Four hops in place at home: squash to gather before take-off (rest shape wider and lower), stretch in the air, the landing left
    /// to gravity and the floor (it really hits it, so no two wobbles are alike). Distance is drawn: it starts up-right at 0.15×, each
    /// hop comes closer and bigger, the last lands at home. Reduce Motion: no travel, one small hop at home.
    func startIntro() {
        guard params.intro >= 0.5, N > 0 else { return }
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
        if moodStrainMax > 0.15 {
            flee(-pullDX, -pullDY, W * (0.45 + 0.35 * moodStrainMax) * params.flee); moodStrainMax = 0; return
        }
        if t - f.tDown < 0.25 && f.stretch < 0.3 {
            taps = taps.filter { t - $0 < 1 }; taps.append(t)
            moodScare = min(1, moodScare + 0.45); moodA = min(1, moodA + 0.3); moodC = max(-1, moodC - 0.1); cowerUntil = max(cowerUntil, t + 0.5)
            if taps.count >= 3 {
                var ux = clusters[gi].xc - f.ax, uy = clusters[gi].yc - f.ay
                let ul = hypot(ux, uy)
                if ul < R * 0.1 { let a = Double.random(in: 0..<(2 * .pi)); ux = cos(a); uy = sin(a) } else { ux /= ul; uy /= ul }
                flee(ux, uy, W * 0.28 * params.flee); taps = []; moodC = max(-1, moodC - 0.3); moodA = 1
            }
            return
        }
        if f.gentleT > 1 && moodC > 0.35 && fingers.isEmpty { happyT = t; wagT = t + 0.1; hop() }
    }
    private func flee(_ dx: Double, _ dy: Double, _ dist: Double) {
        guard dist > 0 else { return }
        let l = max(1e-9, hypot(dx, dy)), ux = dx / l, uy = dy / l
        escOn = true; escT0 = t; escT = max(0.6, dist / (R * 2.4)); escSX = homeX; escSY = homeY
        escDX = homeX + ux * dist; escDY = homeY + uy * dist * 0.8
        wanderMoving = false; moodScare = min(1, moodScare + 0.5)
    }
    /// The happy hop: the intro's hop, once, without travelling (mini: a touch grabs as usual).
    private func hop() {
        guard !introOn, N > 0 else { return }
        var y1 = -1e9
        for i in bnd { y1 = max(y1, Y[i]) }
        introMini = true; introOn = true; introPh = .crouch; introK = 0; introN = 1; introPT = 0; introSq = 0; introFloor = y1
        introU = 1; introS0 = 1; introOX0 = 0; introOY0 = 0; introPX = homeX; introPY = y1
    }
    /// Every frame: the mood follows the hand (the most stretched grabbing finger), the purr, home while fleeing.
    private func moodStep(_ dt: Double) {
        guard params.emo >= 0.5 else { moodStrain = 0; tugX = 0; tugY = 0; purr = 0; escOn = false; return }
        var g: Finger?
        for f in fingers.values where f.mode == .grab { if g == nil || f.stretch > g!.stretch { g = f } }
        if let g {
            let st = g.stretch, sp = hypot(g.vxS, g.vyS) / R
            g.gentleT = st < 0.6 && sp < 2 ? g.gentleT + dt : max(0, g.gentleT - 2 * dt)
            if g.gentleT > 1 { moodC = min(1, moodC + 0.35 * dt); moodA += (0.15 - moodA) * (1 - exp(-dt / 1.5)) }
            g.strainT = st > 1.5 ? g.strainT + dt : max(0, g.strainT - dt)
            let sv = max(0, min(1, (g.strainT - 0.5) / 1))
            moodStrain += (sv - moodStrain) * (1 - exp(-dt / 0.15)); moodStrainMax = max(moodStrainMax, moodStrain)
            if moodStrain > 0 { moodC = max(-1, moodC - 0.6 * dt * moodStrain); moodA = min(1, moodA + 0.8 * dt * moodStrain) }
            if !clusters.isEmpty {
                let px = g.fx - clusters[gi].xc, py = g.fy - clusters[gi].yc, pl = hypot(px, py)
                if pl > R * 0.2 { pullDX = px / pl; pullDY = py / pl }
            }
        } else {
            moodStrain *= exp(-dt / 0.2)
            let k = 1 - exp(-dt / 6)
            moodC -= moodC * k; moodA -= moodA * k
        }
        moodScare *= exp(-dt / 0.8)
        let tg = moodStrain * R * 0.35; tugX = -pullDX * tg; tugY = -pullDY * tg   // tug of war: you can still pull it
        let pt = g != nil && g!.gentleT > 1 && moodC > 0.2 ? min(1, (moodC - 0.2) / 0.5) : 0
        purr += (pt - purr) * (1 - exp(-dt / 0.3))
        if escOn {
            let p = min(1, (t - escT0) / escT), e = 1 - pow(1 - p, 3)
            let nx = escSX + (escDX - escSX) * e, ny = escSY + (escDY - escSY) * e
            wanderVX = (nx - homeX) / dt; wanderVY = (ny - homeY) / dt; homeX = nx; homeY = ny
            if p >= 1 { escOn = false; cowerUntil = t + 1.2 + Double.random(in: 0..<0.8); wanderNext = max(wanderNext, t + 2 + Double.random(in: 0..<1.5)) }
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
                onEvent?(.press(gain: 0.15 + 0.45 * ivS))
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
        if !(params.zoomMin > 0) { return (-.infinity, .infinity, -.infinity, .infinity) }
        let v = viewV, zm = camMin, ax = (W - 16) / 2 / zm, ay = (H - 210) / 2 / zm
        return (v.x - ax, v.x + ax, v.y - ay, v.y + ay)
    }
    private func updateCam(_ dt: Double) {
        let v = viewV, pad = R * 0.35
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
        let follow = params.camFollow >= 0.5 && !big && !grabbingNow && !introOn
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
        let cxT = fit ? clampC(ox, x1 + pad - hx, x0 - pad + hx) : ox, cyT = fit ? clampC(oy, y1 + pad - hy, y0 - pad + hy) : oy
        let k = follow ? 1 : 1 - exp(-dt / 0.35), kz = 1 - exp(-dt / 0.35)
        camZ += (zt - camZ) * kz; camX += (cxT - camX) * k; camY += (cyT - camY) * k
    }   // press flat: pressing now, table height, remembered bottom below the centroid
    private var builtLimbs = -1.0, builtSize = -1.0, builtDens = -1.0

    final class Finger {
        enum Mode { case grab, push, none }
        var ax, ay, x, y, fx, fy: Double            // anchor, chase target, lagged effective position
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
        var tickAt = 0.0, tickNext = 0.0             // texture ticks: travel at the last tick, spacing to the next (提案第 13 條)
        var step = 0
        var stretch = 0.0                            // tanh-limited stretch at the last update, in radii
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

    private func defineShape() {
        var r = LCG(seed: Int(params.seed.rounded()) * 7 + 3)
        ph = [r.next() * 6.28, r.next() * 6.28, r.next() * 6.28, (-72 + (r.next() - 0.5) * 30) * .pi / 180]
        // screen coords, y down: 90° is straight down. Most hang below or sideways.
        // v2.9: limbs 0 by default, no fixed tentacles (多米: not a starfish); what reaches out are the pseudopods
        let base: [(Double, Double, Double)] = Array([(100, 2.1, 0.17), (55, 1.8, 0.15), (140, 1.65, 0.14), (8, 1.5, 0.14), (198, 1.35, 0.13)]
            .prefix(max(0, min(5, Int(params.limbs.rounded())))))
        tent = base.map { item -> Tentacle in
            let (deg, L, w) = item
            let a = (deg + (r.next() - 0.5) * 22) * .pi / 180
            let curl = (r.next() - 0.5) * 0.6
            let droop = 0.15 + 0.3 * max(0, -sin(a))
            return Tentacle(a: a, ux: cos(a), uy: sin(a), L: L * (0.85 + r.next() * 0.3), w: w * (0.85 + r.next() * 0.3),
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
        if tent.isEmpty { return 0.98 + 0.07 * sin(2 * a + ph[0]) + 0.05 * sin(3 * a + ph[1]) + 0.03 * sin(5 * a + ph[2]) }
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
            let px = sx + dx * u, py = sy + dy * u, d = hypot(x - px, y - py), w = tt.w * R * (1 - 0.12 * u)
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
        R = max(60, min(W * params.bodySize, H * 0.14, 160))   // bodySize: 0.26 before v2.9; smaller leaves room to pull and spread
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
        // highlight rides on the upper-left of the blob
        var bd = 1e9
        for i in 0..<N where TID[i] < 0 {
            let d = hypot(Q0X[i] + R * 0.28, Q0Y[i] + R * 0.32)
            if d < bd { bd = d; hiIdx = i }
        }
        fingers.removeAll()
        A0 = polygonArea()
        builtSeed = params.seed; builtFloppy = params.floppy; builtLimbs = params.limbs; builtSize = params.bodySize; builtDens = params.dens
        pods = []; podClock = 0; podNext = 0.5; podShift = 0; podE = []; brJw = 0; brLift = 0; flatOn = false
        camZ = 1; camX = viewV.x; camY = viewV.y
        folX = viewV.x; folY = viewV.y; folVX = 0; folVY = 0; folChase = false
        introOn = false; introSq = 0; ivS = 1; ivOX = 0; ivOY = 0
        moodC = 0; moodA = 0; moodStrain = 0; moodStrainMax = 0; moodScare = 0; cowerUntil = -9; happyT = -9; wagT = -9; taps = []
        tugX = 0; tugY = 0; escOn = false; purr = 0
        dentList.removeAll()
        t = 0; lastTouch = -10; nextTwitch = 3; relaxUntil = -1
        tLife = 0; releaseCount = 0; nextSpecial = 0; specialUntil = -1
        wanderMoving = false; wanderNext = 3; wanderVX = 0; wanderVY = 0
        brPhase = 0; brPrev = 0; brAmp = 1; brWave = 0; brDeepAt = -99; brGrabStart = -1; pinchA = nil; pinchB = nil
    }

    private func buildClusters() {
        clusters = []
        let cs = R * params.cSpace, cr = R * params.cRad
        var cy = -2.6 * R
        while cy <= 2.6 * R {
            var cx = -2.6 * R
            while cx <= 2.6 * R {
                var idx: [Int] = []
                for i in 0..<N where hypot(Q0X[i] - cx, Q0Y[i] - cy) < cr { idx.append(i) }
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
        var p = 0.0, v = 0.0, p0 = 0.0, tau = 0.0, w = 0.0
        var nb: [(i: Int, ox: Double, oy: Double)] = []
        init(i: Int, finger: ObjectIdentifier) { self.i = i; self.finger = finger } }
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
        guard ml >= R * 0.12, !f.mem.isEmpty else { return }
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
        for i in bnd {
            let dx = X[i] - cx, dy = Y[i] - cy
            if dx * ux + dy * uy <= 0 { continue }
            let pr = abs(dx * uy - dy * ux)
            if pr < bs { bs = pr; bi = i }
        }
        guard bi >= 0 else { return }
        let ex = X[bi] - cx, ey = Y[bi] - cy, l2 = max(1e-9, ex * ex + ey * ey), gr = params.grabR * R
        for i in 0..<N where !GRAB[i] {
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

    /// `allowed` is false for touches in the system-gesture bands near the screen edges.
    /// `radius` is UITouch.majorRadius (contact size, points; 0 if unknown).
    /// `x, y` are screen points; the rig turns them into world points through the camera.
    func touchBegan(_ id: ObjectIdentifier, x sx: Double, y sy: Double, time: TimeInterval, allowed: Bool = true, radius: Double = 0) {
        guard N > 0 else { return }
        if introOn { let mini = introMini; endIntro(); if !mini { return } }   // v2.17: a touch on the way brings it home at once (eased in 0.25 s); this touch does not grab; during a happy hop it grabs as usual
        let (x, y) = toWorld(sx, sy)
        if let old = fingers[id], old.sticking { release(id, quiet: true) }   // 候選 26: the same touch object came back while stuck
        let grab = allowed && (insideBody(x, y) || nearBody(x, y, R * 0.22))
        if grab { escOn = false }   // v2.18: caught, it stops running
        let f = Finger(x: x, y: y, mode: !allowed ? .none : (grab ? .grab : .push), time: t)
        f.radius = radius; f.r0 = radius
        f.sx = sx; f.sy = sy
        if grab {
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
            onEvent?(.press(gain: 0.7))
            // press flat (多米 2026-11-01: wanted to see it): a press counts only if it lands on the upper half; remember the
            // height and the bottom then (the invisible table is at that bottom)
            if params.pressFlat > 0 {
                var y0 = 1e9, y1 = -1e9
                for i in bnd { y0 = min(y0, Y[i]); y1 = max(y1, Y[i]) }
                if y < clusters[gi].yc { f.flatOn = true; f.h0 = max(R * 0.5, y1 - y0); f.bot = y1; f.flat = 1 }
            }
        }
        if grab && params.dent > 0 {
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
        fingers[id] = f
    }

    /// `x, y` is the real finger position. `predictedX/Y` is the system's guess for the next frame; it is used
    /// only on frames that received a fresh move event (Apple: predicted touches are temporary and must be
    /// replaced as real touches arrive). `distance` is the true travelled distance from coalesced touches.
    func touchMoved(_ id: ObjectIdentifier, x: Double, y: Double, predictedX: Double?, predictedY: Double?, distance: Double, radius: Double = 0) {
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
    private func release(_ id: ObjectIdentifier, quiet: Bool) {
        guard let f = fingers.removeValue(forKey: id) else { return }
        for m in f.mem { GRAB[m.i] = false }
        for dn in dentList where dn.finger == id { dn.finger = nil }
        lastTouch = t
        if f.mode == .grab && !quiet { moodRelease(f) }
        if f.mode == .grab && !quiet {
            // release strength: how fast it was flicked (peak speed over the last ~80 ms) or how far it was
            // stretched (tanh-limited stretch over the limit), whichever is bigger, so a slow let-go still pops
            let sv = min(1, f.peak / R / 6)
            // a full pull counts at 2R at most: clay's limit went to 8 for free sculpting, and the pop would have shrunk with it
            let ss = pow(min(1, f.stretch / max(0.01, min(params.maxPull, 2))), 1.5)
            var s = max(sv, ss)
            // 偶發特別回彈 (提案第 2 條): every `specialEvery` releases (±2) one comes back extra bouncy for 0.35 s
            var special = false
            releaseCount += 1
            if params.specialEvery > 0 {
                let every = Int(params.specialEvery.rounded())
                if nextSpecial == 0 { nextSpecial = max(1, every + Int.random(in: -2...2)) }
                if releaseCount >= nextSpecial {
                    special = true
                    specialUntil = t + 0.35
                    nextSpecial = max(releaseCount + 1, releaseCount + every + Int.random(in: -2...2))
                    s = min(1, s * 1.3)
                }
            }
            lastReleaseStrength = s
            onEvent?(.release(gain: 0.35 + 0.65 * s, rate: 1 + 0.1 * s, special: special))
        }
    }

    /// The system took the touch away (edge gesture, call, app switch): let go quietly, no pop.
    func touchCancelled(_ id: ObjectIdentifier) {
        release(id, quiet: true)
    }

    func cancelAllTouches() {
        for f in fingers.values { for m in f.mem { GRAB[m.i] = false } }
        fingers.removeAll()
        lastTouch = t
    }

    // MARK: - External nudges (buttons, VoiceOver actions)

    /// Small whole-body shake.
    func bump(_ amount: Double = 1) {
        guard N > 0 else { return }
        let amp = R * 0.0025 * amount * (reduceMotion ? 0.5 : 1)
        let a = Double.random(in: 0..<(2 * .pi)), ix = cos(a) * amp, iy = sin(a) * amp
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
    }

    /// VoiceOver "拉長": tug the top upward.
    func stretchUp() {
        guard N > 0 else { return }
        for i in 0..<N where Q0Y[i] < -R * 0.3 && !GRAB[i] { PY[i] += R * 0.02 }
        onEvent?(.release(gain: 0.6, rate: 1, special: false))
    }

    // MARK: - Per-frame

    func update(_ dt: Double) {
        guard N > 0 else { return }
        t += dt
        if params.seed != builtSeed || params.floppy != builtFloppy || params.limbs != builtLimbs || params.bodySize != builtSize || params.dens != builtDens {
            setup(width: W, height: H)
        } else if params.cSpace != builtSpace || params.cRad != builtRad {
            buildClusters()
        }
        let mat = params
        if mat.homeFrac != builtHome { builtHome = mat.homeFrac; cy = H * mat.homeFrac; homeY = cy }   // 候選 33
        // 候選 26: a stuck finger lets go when its time is up
        for (id, f) in fingers where f.sticking && t >= f.releaseAt { release(id, quiet: false) }

        updateCam(dt)
        for f in fingers.values where f.reach && f.mode == .grab { reachGrab(f) }
        pressSum = 0
        if mat.press2 >= 0.5 {
            // v2.16 (多米: the press looked like a toy): 60% in 40 ms, the rest by the material (pressSink); held longer it gets
            // wider and shallower (w). Released, p springs back by pressBounce (jelly overshoots outward once); clay does not
            // bounce and lets go fast (the shape is already remembered); d fades at the relax rate on clay, with p elsewhere
            for dn in dentList {
                if let id = dn.finger, let f = fingers[id] {
                    let moved = hypot(f.rawX - f.ax, f.rawY - f.ay)
                    if moved > R * 0.4 { dn.pull = true }
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
                        let om = 2 * Double.pi * 5
                        dn.v += (-om * om * dn.p - 2 * b * om * dn.v) * dt; dn.p += dn.v * dt
                    }
                    dn.d *= exp(-(dn.pull ? 8 : t < relaxUntil ? 6 : max(mat.recover, 0.02)) * dt)
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
                dn.d *= exp(-(dn.pull ? 8 : t < relaxUntil ? 6 : max(mat.recover, 0.02)) * dt)
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
            f.lastRawX = f.rawX; f.lastRawY = f.rawY
            let kv = 1 - exp(-dt / 0.03)
            f.vxS += (f.vx - f.vxS) * kv; f.vyS += (f.vy - f.vyS) * kv
            f.peak = max(hypot(f.vx, f.vy), f.peak * exp(-dt / 0.08))
            f.speedC += (f.travelFrame / dt - f.speedC) * kv
            f.travelFrame = 0

            var ex = f.x - f.ax, ey = f.y - f.ay
            let el = hypot(ex, ey), lim = mat.maxPull * R
            if f.mode == .grab && el > 0 {
                let s = lim * tanh(el / lim) / el
                ex *= s; ey *= s
            }
            // the finger keeps 0.35R off the walls: a held patch pressed flat against a wall crossed on release (4 of 6 trials)
            let mw = R * 0.35, wl = worldWalls   // the walls are in world points (the farthest view's edge)
            let tx = max(wl.l + mw, min(wl.r - mw, f.ax + ex)), ty = max(wl.t + mw, min(wl.b - mw, f.ay + ey))
            let k = mat.lag > 0 ? 1 - exp(-dt / mat.lag) : 1
            f.fx += (tx - f.fx) * k; f.fy += (ty - f.fy) * k
            if f.mode == .grab {
                let st = hypot(ex, ey) / R, step = Int(floor(st * 2.5))
                f.stretch = st
                if step > f.step && st > 0.35 {
                    onEvent?(.pull(gain: min(1, 0.4 + st / 2), rate: 1 - 0.08 * min(1, st / 1.5)))
                }
                f.step = max(f.step, step)
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
                let target = R * (mat.pressBase + mat.pressHold * f.hold + 0.15 * mat.pressRadiusGain * f.prS)
                if !f.pressOn {
                    f.press = target * mat.pressFirst
                    f.pressOn = true
                } else {
                    f.press += (target - f.press) * (1 - exp(-dt / max(0.005, mat.pressRise)))
                }
                // 提案第 13 條: texture ticks, one every `tickSpacing` points of real travel (±30%), at most two a frame
                if mat.tickSpacing > 0 {
                    if f.tickNext <= 0 { f.tickNext = mat.tickSpacing; f.tickAt = f.travel }
                    var ticks = 0
                    while f.travel - f.tickAt >= f.tickNext && ticks < 2 {
                        f.tickAt += f.tickNext
                        f.tickNext = mat.tickSpacing * (0.7 + 0.6 * Double.random(in: 0..<1))
                        ticks += 1
                        onEvent?(.tick(gain: min(1, f.speedC / (R * 3))))
                    }
                }
            }
        }

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
                if r <= pinchNext { onEvent?(.squish(gain: 0.6 + 0.3 * (1 - r))); pinchNext -= 0.15 }
            } else {
                pinchA = nil; pinchB = nil
            }
        }

        // idle life: only when nobody is touching, fading in over a second after release
        let idle = fingers.isEmpty ? min(1, max(0, (t - lastTouch - 0.8) / 1.2)) : 0
        let L = idle * (reduceMotion ? 0.5 : 1)
        // 提案第 19 條: with idleFreeze the idle motion keeps its amplitude and only its clock stops while touched
        // (the body holds its breath instead of snapping to the rest pose); L still gates twitch, wander and sway
        tLife += dt * L
        let freeze = mat.idleFreeze >= 0.5
        let Lamp = freeze ? (reduceMotion ? 0.5 : 1) : L
        let tl = freeze ? tLife : t
        // 提案第 23 條 breathing: accumulated phase (the period can change without a jump); at the control values
        // (3.8 s sine) this is exactly the old waveform
        do {
            var T = mat.jelly >= 0.5 ? mat.jellyT : mat.breathT, amp = 1.0
            do {   // v2.18: comfortable slow and deep, tense fast and shallow
                let cp = max(0, moodC), ar = max(moodA, moodScare)
                T *= (1 + 0.4 * cp) * (1 - 0.4 * ar); amp *= (1 + 0.5 * cp) * (1 - 0.4 * ar)
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
            brPhase += (tl - brPrev) / T; brPrev = tl; brAmp = amp
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
            let dw = w - brJw
            brJw = w; brWave = -w; brAmp = mat.jellyAmp / 0.045 * (1 + 0.5 * max(0, moodC)) * (1 - 0.4 * max(moodA, moodScare))
            if dw > 0 { brLift += dw * mat.jellyLift * R * Lamp * mat.life }
        }
        brLift *= exp(-dt / 1.0)
        // pseudopods: born, grow, hold, retract, gone. Their clock runs with the idle life (stops while touched) at idlePace
        do {
            let adv = dt * L * mat.idlePace
            for k in pods.indices { pods[k].p += adv / pods[k].D }
            pods.removeAll { $0.p >= 1 }
            podClock += adv
            if mat.pods > 0 && pods.count < Int(mat.pods.rounded()) && podClock >= podNext {
                var a = 0.0
                for _ in 0..<10 {
                    a = Double.random(in: 0..<(2 * .pi))
                    if pods.allSatisfy({ abs(atan2(sin(a - $0.a), cos(a - $0.a))) > 1.1 }) { break }
                }
                pods.append(Pod(a: a, L: mat.podLen * (0.7 + 0.5 * Double.random(in: 0..<1)), sig: 0.22 + 0.1 * Double.random(in: 0..<1),
                                bend: (Double.random(in: 0..<1) - 0.5) * 0.8, D: 4 + 4 * Double.random(in: 0..<1)))
                podNext = podClock + 0.8 + 2.2 * Double.random(in: 0..<1)
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
                if strain > 0.02 {
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
            // area: along the reference boundary, the area the pods add (∮ r·Δr + Δr²/2 dθ), taken back all round with the
            // same (r/Rb)² weight (only subtracting each pod's mean left the area 3% to 5% high)
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
        wanderVX = 0; wanderVY = 0
        moodStep(dt)
        if L > 0.5 && mat.wander > 0 && !introOn && !escOn && t > cowerUntil {
            if !wanderMoving && t > wanderNext {
                wanderSX = homeX; wanderSY = homeY
                var sp = 1.0
                if mat.camFollow >= 0.5 {
                    // v2.17: walk out from where it is; with the `dash` chance far and fast (2.5×: the camera lags, it leaves the screen
                    // a bit). Over three view widths from the start it heads back
                    let far = Double.random(in: 0..<1) < mat.dash
                    let dist = W * (far ? 0.5 + 0.4 * Double.random(in: 0..<1) : 0.2 + 0.3 * Double.random(in: 0..<1))   // v2.18: walks further (多米: it always sits in the middle)
                    var a = Double.random(in: 0..<(2 * .pi))
                    if hypot(homeX - cx, homeY - cy) > W * 3 { a = atan2(cy - homeY, cx - homeX) + Double.random(in: -0.5..<0.5) }
                    wanderX = homeX + cos(a) * dist; wanderY = homeY + sin(a) * dist * 0.8
                    if far { sp = 2.5 }
                } else {
                    wanderX = cx + (Double.random(in: 0..<1) - 0.5) * W * 0.36
                    wanderY = cy + (Double.random(in: 0..<1) - 0.5) * H * 0.16
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
                    wanderNext = t + (mat.camFollow >= 0.5 ? 0.8 + Double.random(in: 0..<2.2) : 1.5 + Double.random(in: 0..<5))   // v2.18: shorter rests
                }
            }
        } else if !fingers.isEmpty {
            wanderMoving = false
            wanderNext = t + 2 + Double.random(in: 0..<3)
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
        for _ in 0..<n { substep(sdt, L, Lamp, tl) }
        plasticity(dt)
        twitch(L)
    }

    /// `L` gates rate-like idle motion (sway, twitch gating); `Lamp` and `tl` are the amplitude and clock
    /// of the phase-based idle motion (breathing, wriggle, drift, float), frozen while touched with idleFreeze.
    private func substep(_ dt: Double, _ L: Double, _ Lamp: Double, _ tl: Double) {
        let mat = params
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
        let alpha = mat.alpha * (special ? 1.25 : 1)
        let G = introOn ? R * introG * dt * dt : 0   // v2.17 intro: gravity only while hopping in
        // 1 Verlet
        for i in 0..<N {
            let vx = (X[i] - PX[i]) * damp, vy = (Y[i] - PY[i]) * damp
            PX[i] = X[i]; PY[i] = Y[i]
            X[i] += vx; Y[i] += vy + G
        }
        // 2 fingers (GWT: how much each particle is held this substep, for grabHold in shape matching)
        for i in 0..<N { GWT[i] = 0 }
        for f in fingers.values {
            if f.mode == .grab {
                // the patch follows the finger and, while pressed, spreads away from it (squashes flat)
                for m in f.mem {
                    let k = min(0.95, mat.grabK * m.w)   // grabK: clay 1.2, the whole patch follows (多米: could not pick up the middle)
                    X[m.i] += (f.fx + m.ox + m.dx * f.press - X[m.i]) * k
                    Y[m.i] += (f.fy + m.oy + m.dy * f.press - Y[m.i]) * k
                    if m.w > GWT[m.i] { GWT[m.i] = m.w }
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
                if hit && !f.pushed { f.pushed = true; onEvent?(.press(gain: 0.5)) }
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
            trm = R * 0.016 * min(1, moodStrain + moodScare) * (reduceMotion ? 0.5 : 1)
        }
        let sp = mat.press2 >= 0.5 ? sqrt(max(0.5, 1 + mat.pressArea * pressSum)) : 1
        let bs = Lamp * mat.life * 0.045 * brAmp * brWave, bsx = (1 + bs) * sp * (1 + introSq) * posX, bsy = (1 - bs * 0.85) * sp * (1 - introSq) * posY   // 提案第 23 條: waveform from update()
        let wr = Lamp * mat.life * mat.wriggle * R * (1 - 0.5 * max(0, moodC)), swA = Lamp * mat.life * mat.drift * R, iR = 1 / R
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
        for i in 0..<N {
            var ex = QX[i], ey = QY[i]
            // pseudopods: a Gaussian along direction a pushes the outer ring out (the inside less, by (r/Rb)², so the whole
            // field is a smooth map), minus podShift all round so the area stays; bend swings the outer part sideways
            if !podE.isEmpty {
                let r = hypot(ex, ey)
                if r > 1e-6 {
                    let c1 = ex / r, s1 = ey / r, rn = min(1.6, (r / Rb) * (r / Rb))
                    var dr = 0.0, dtn = 0.0
                    for q in podE {
                        let da = atan2(s1 * q.ca - c1 * q.sa, c1 * q.ca + s1 * q.sa), g = exp(-da * da / (2 * q.sig * q.sig))
                        dr += q.amp * g * rn; dtn += q.bend * q.amp * g * rn * rn
                    }
                    dr -= podShift * rn
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
                let px = X[i] - xc, py = Y[i] - yc, qx = (EX[i] - qcx) * bsx, qy = (EY[i] - qcy) * bsy
                a += px * qx; b += px * qy; cc += py * qx; d += py * qy
            }
            let ang = atan2(cc - b, a + d), cs = cos(ang), sn = sin(ang)
            clusters[c].cs = cs; clusters[c].sn = sn; clusters[c].xc = xc; clusters[c].yc = yc
            clusters[c].qcx = qcx; clusters[c].qcy = qcy
            let w = clusters[c].w
            for i in idx {
                let qx = (EX[i] - qcx) * bsx, qy = (EY[i] - qcy) * bsy
                GX[i] += (xc + cs * qx - sn * qy) * w
                GY[i] += (yc + sn * qx + cs * qy) * w
                GW[i] += w
            }
        }
        // area pressure: when squashed or stretched the area drops, push goals outward so sides bulge
        let A = polygonArea()
        let A0p = mat.press2 >= 0.5 ? A0 * (1 + mat.pressArea * pressSum) : A0   // v2.16 P1: pressed from the front it thins, so it looks bigger
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
        let rotK = -gAng * min(0.2, mat.upright * (grabbing ? mat.anchor * mat.gripRot : 1))
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
        // 4 home (float), bounds
        let hx = homeX + tugX + Lamp * mat.life * R * 0.035 * sin(tl * 2 * .pi / 7.3)
        let hy = homeY + tugY - brLift + (mat.jelly >= 0.5 ? 0 : Lamp * mat.life * R * 0.05 * sin(tl * 2 * .pi / 4.7))   // jellyfish: up and down only with the pulse
        // 候選 21: idle home spring homeK (0.003 drifts back in about half a second with no overshoot); grabbed stays 0.02 × anchor
        let hyF = flatOn ? flatFloor - flatQB : hy   // pressing flat: home is where the bottom sits on the table
        let kh = grabbing ? 0.02 * mat.anchor : mat.homeK, dx = hx - gcx, dy = hyF - gcy
        let wl = worldWalls, padT = wl.t, padB = wl.b, padL = wl.l, padR = wl.r   // walls: the edge of the farthest view (world)
        for i in 0..<N {
            if !GRAB[i] { X[i] += dx * kh; if !introOn { Y[i] += dy * kh } }   // hopping in, up and down is gravity and the floor's
            if introOn && Y[i] > introFloor { Y[i] = introFloor; PX[i] += (X[i] - PX[i]) * 0.45 }   // intro floor: it really lands, squashes, wobbles
            if flatOn && Y[i] > flatFloor { Y[i] = flatFloor; PY[i] = Y[i] }   // the invisible table: no sinking, no bounce, free to slide
            if Y[i] < padT { Y[i] = padT }
            if Y[i] > padB { Y[i] = padB }
            if X[i] < padL { X[i] = padL }
            if X[i] > padR { X[i] = padR }
        }
        if mat.ringGuard > 0 { ringGuard(); ringUnkink() }   // no boundary through boundary, little knots straightened; after the walls
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
        let dmin = h * 0.6, dmin2 = dmin * dmin, inv = 1 / dmin
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

    private func plasticity(_ dt: Double) {
        let mat = params
        // where each particle sits in rest space right now (rotation only, averaged over its clusters)
        for i in 0..<N { RX[i] = 0; RY[i] = 0; GW[i] = 0 }
        for c in clusters {
            for i in c.idx {
                let px = X[i] - c.xc, py = Y[i] - c.yc
                RX[i] += (c.qcx + c.cs * px + c.sn * py) * c.w
                RY[i] += (c.qcy - c.sn * px + c.cs * py) * c.w
                GW[i] += c.w
            }
        }
        // tentMem: a grabbed tentacle is measured in the whole-body frame, more so towards the tip (the root stays on the
        // clusters like the body, so the junction does not get two frames). The clusters read a bent tentacle as a rotation
        // and cancel it (measured: a 0.8R pull remembered 2.7 pt). Only the grabbed tentacle: an untouched one swinging
        // would be remembered as bent (measured: holding the body 1.5 s bent the tentacles 52 pt)
        // nearMem: near the fingers (Gaussian, about 1.1R) the body is measured in the whole-body frame too. A pulled-out lump
        // reads as a rotation to the clusters and is cancelled (measured: a 0.9R pull remembered 7 pt)
        if mat.nearMem > 0 {
            let g = clusters[gi], gs = fingers.values.filter { $0.mode == .grab }, k2 = 1 / (mat.nearR * mat.nearR * R * R)   // clay 3 = the whole lump
            if !gs.isEmpty {
                for i in 0..<N {
                    var wf = 0.0
                    for f in gs { let dx = X[i] - f.fx, dy = Y[i] - f.fy; wf = max(wf, exp(-(dx * dx + dy * dy) * k2)) }
                    let wi = mat.nearMem * wf
                    if wi < 1e-3 { continue }
                    let px = X[i] - g.xc, py = Y[i] - g.yc, c = GW[i]
                    RX[i] = RX[i] * (1 - wi) + (g.qcx + g.cs * px + g.sn * py) * c * wi
                    RY[i] = RY[i] * (1 - wi) + (g.qcy - g.sn * px + g.cs * py) * c * wi
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
            }
        }
        let touched = fingers.values.contains { $0.mode == .grab }
        if t < relaxUntil {
            // 揉回原形: the remembered shape eases back to the original over half a second; positions follow
            // through shape matching, so nothing jumps (手感精修提案 第 28 條)
            let kr = min(1, 6 * dt)
            for i in 0..<N { QX[i] += (Q0X[i] - QX[i]) * kr; QY[i] += (Q0Y[i] - QY[i]) * kr }
        } else if touched && !(mat.ringGuard > 0 && ringCrossed()) {   // no memory on a crossed frame: a crossing must not become the shape
            // only after dwelling: within `dwellLo` a light press or a quick flick springs back,
            // from `dwellHi` on kneading remembers at full speed (輕按回彈，揉捏即留形)
            var g = 0.0
            let lo = mat.dwellLo, hi = max(lo + 0.001, mat.dwellHi)
            for f in fingers.values where f.mode == .grab {
                let x = max(0, min(1, (t - f.tDown - lo) / (hi - lo)))
                g = max(g, x * x * (3 - 2 * x))
            }
            let yl = mat.yield * R, kc = min(1, mat.creep * dt * g)
            // v2.16: the press push is a performance, taken off before remembering (turned into rest space). Kept, clay remembered
            // the pushed shape and the next step pushed again on top: the longer the hold the wider (measured: 1.5 s moved 48 pt, was 24)
            let pf = pressField(), gcs = clusters[gi].cs, gsn = clusters[gi].sn
            if kc > 0 {
                for i in 0..<N {
                    // compared with the performed reference EX, not Q: touched pseudopods hold still in mid-air, and against Q
                    // they were remembered as a mark (measured: a 1.5 s hold remembered 67 pt)
                    var rx = RX[i] / GW[i], ry = RY[i] / GW[i]
                    if !pf.isEmpty { let q = pressPush(pf, X[i], Y[i]); rx -= gcs * q.0 + gsn * q.1; ry -= -gsn * q.0 + gcs * q.1 }
                    let dx = rx - EX[i], dy = ry - EY[i], dl = hypot(dx, dy)
                    if dl > yl {
                        let s = (1 - yl / dl) * kc * (TID[i] >= 0 ? 1 - 0.85 * TU[i] * (1 - mat.tentMem) : 1)
                        QX[i] += dx * s; QY[i] += dy * s
                        let ex = QX[i] - Q0X[i], ey = QY[i] - Q0Y[i], el = hypot(ex, ey), lim = R * mat.memMax   // clay 4R: pull long, spread flat
                        if el > lim { QX[i] = Q0X[i] + ex * lim / el; QY[i] = Q0Y[i] + ey * lim / el }
                    }
                }
            }
        } else {
            // crossed: relax at the v2.13 rate (0.3). With recover slowed to 0.05 the knot a 9R pull leaves in the tail stayed for
            // 12 s after release; relaxing shortens the strand and the knot comes undone
            let kr = min(1, (mat.ringGuard > 0 && mat.recover < 0.3 && ringCrossed() ? 0.3 : mat.recover) * dt)
            if kr > 0 {
                for i in 0..<N { QX[i] += (Q0X[i] - QX[i]) * kr; QY[i] += (Q0Y[i] - QY[i]) * kr }
            }
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
            A += QX[i] * QY[j] - QX[j] * QY[i]; B += Q0X[i] * Q0Y[j] - Q0X[j] * Q0Y[i]
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

    private func ringGuard() {
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
                X[p] += nx * push * wp / ws; Y[p] += ny * push * wp / ws
                X[a] -= nx * push * wa * (1 - u) / ws; Y[a] -= ny * push * wa * (1 - u) / ws
                X[b] -= nx * push * wb * u / ws; Y[b] -= ny * push * wb * u / ws
            }
        }
    }

    /// Every few seconds a cluster gets a small impulse; sometimes the whole body.
    private func twitch(_ L: Double) {
        if t < nextTwitch { return }
        nextTwitch = t + 2.2 + Double.random(in: 0..<4.5)
        if L < 0.5 || params.life <= 0 { return }
        let amp = R * 0.0012 * params.life * (reduceMotion ? 0.5 : 1)   // per-substep displacement = velocity
        let whole = Double.random(in: 0..<1) < 0.25
        let c = whole ? clusters[gi] : clusters[Int.random(in: 0..<max(1, clusters.count - 1))]
        let a = Double.random(in: 0..<(2 * .pi)), s = whole ? 0.6 : 1.0
        let ix = cos(a) * amp * s, iy = sin(a) * amp * s
        for i in c.idx where !GRAB[i] { PX[i] -= ix; PY[i] -= iy }
    }

    // MARK: - Readouts for sound and haptics

    /// Kneading level 0...1: how fast grabbing fingers move (drives the looped rub sound).
    func rubLevel() -> Double {
        var sp = 0.0
        // smoothed travel rate from coalesced touches (a per-frame difference flickers at 120 Hz)
        for f in fingers.values where f.mode == .grab { sp = max(sp, f.speedC / R) }
        return fingers.isEmpty ? 0 : min(1, sp / 5)   // the controller scales this by `rubMax`
    }

    /// Stretch (radii, tanh-limited) of the most-stretched grabbing finger: drives the strand loop's pitch, brightness and loudness.
    var pullStretch: Double { fingers.values.filter { $0.mode == .grab }.map(\.stretch).max() ?? 0 }

    /// Any finger holding the body (not pushing from outside).
    var isGrabbing: Bool { fingers.values.contains { $0.mode == .grab } }

    /// Largest UITouch.majorRadius among the fingers down (for the panel readout).
    var maxTouchRadius: Double { fingers.values.map { $0.radius }.max() ?? 0 }

    /// How close the most-stretched grabbing finger is to the stretch limit, 0...1 (sharpness bonus, 提案第 15 條).
    var stretchLevel: Double {
        var m = 0.0
        for f in fingers.values where f.mode == .grab { m = max(m, f.stretch / max(0.01, min(params.maxPull, 2))) }   // same 2R cap as the pop
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
}
