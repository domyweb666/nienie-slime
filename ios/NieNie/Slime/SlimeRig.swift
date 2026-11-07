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
    // fleeing: home rushes out on an ease-out (fast, the camera lags and it leaves the screen a bit), then it curls up a moment
    private var escOn = false, escT0 = 0.0, escT = 1.0, escSX = 0.0, escSY = 0.0, escDX = 0.0, escDY = 0.0
    private var introMini = false
    /// Purr strength 0...1 (the controller turns it into soft taps).
    private(set) var purr = 0.0
    // v2.19 活物感 (多米 build 73: no sense of life, it does not read as a creature; .uiux/04-手感/活物感提案-暫定.md).
    // rest / look / go / arrive (A1, A2). sniffs: pseudopods reaching out to sniff (a = screen angle, L length, T1 out, T2 hold, T3 back;
    // cut: touched or flinching, drawn in within 0.15 s); att: a point queued to sniff at (A7); lifeWrg: wriggle share; goFade: the
    // jellyfish pulse fades while walking (the contraction is the walking); lifeUntil −1 = choose on the next frame
    private enum LifeState { case rest, look, go, arrive, sleep }   // v2.23 sleep (B2)
    private struct Sniff { var a, L, t0, T1, T2, T3, ph: Double; var cut = 0.0, eCut = 0.0, id = 0 }
    private var sniffSeq = 0
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
    private(set) var eyeMode = EyeMode.open
    struct EyeView { let lx, ly, rx, ry, gx, gy, lookX, lookY, open, wide, blink, size, spread: Double; let mode: EyeMode }
    /// The eyes as drawn (world points): each on the mean of its 4 particles; gaze −1...1; size = R × eyeSize; spread = how far apart vs rest.
    var eyeView: EyeView? {
        guard params.eyes >= 0.5, !eyeL.isEmpty, !eyeR.isEmpty else { return nil }
        let l = eyeAt(eyeL), r = eyeAt(eyeR)
        let ga: Double = params.gazeAmp * (1 - 0.8 * eyeDK)   // v2.24: the whole face slides on the body; the closer the finger, the less it slides toward it
        return EyeView(lx: l.x, ly: l.y, rx: r.x, ry: r.y, gx: eyeGX, gy: eyeGY, lookX: eyeGX * ga + eyeDX, lookY: eyeGY * ga * 0.75 + eyeDY, open: eyeOpenD, wide: eyeWideD, blink: eyeBlink,
                       size: R * params.eyeSize, spread: max(0.8, min(1.3, hypot(r.x - l.x, r.y - l.y) / eyeD0)), mode: eyeMode)
    }
    // B2 sleep: k eases 0...1 (1.6 s falling asleep, 0.25 s waking); lastAny = the last touch anywhere (a tap on empty space counts)
    private var slpOn = false, slpK = 0.0, slpLastAny = -99.0, slpWakeT = -9.0, slpAskAt = -9.0, slpNearT = 0.0, flBoost = 1.0
    // C6 echo: st 0 idle, 1 listening, 2 answering; beats = offsets from t0; prev = the rhythm it answered last (you repeating it = happy)
    private var echoTaps: [Double] = [], echoSt = 0, echoX = 0.0, echoY = 0.0, echoBeats: [Double] = [], echoI = 0, echoT0 = 0.0
    private var echoPrev: [Double]?, echoPrevT = -99.0, echoSame = false, echoJoyUntil = -9.0
    private(set) var echoBeatT = -9.0
    private var swimOn = false, swimT0 = 0.0   // swimming in (cold start, a slime switch)
    /// v2.23 收集: switching slimes brings that one's impression back (this run only).
    func setImpression(trust: Double, wary: Double) { impTrust = trust; impWary = wary; impShownTrust = trust; impShownWary = wary; impHas = false; impAskUntil = -9 }
    /// v2.22 E3: the body colour leans with the impression.
    var showsImpression: Bool { iv3(params.e3) }

    /// Four hops in place at home: squash to gather before take-off (rest shape wider and lower), stretch in the air, the landing left
    /// to gravity and the floor (it really hits it, so no two wobbles are alike). Distance is drawn: it starts up-right at 0.15×, each
    /// hop comes closer and bigger, the last lands at home. Reduce Motion: no travel, one small hop at home.
    func startIntro() {
        guard params.intro >= 0.5, N > 0 else { return }
        if params.introSwim >= 0.5 && params.life2 >= 0.5 && lv(params.lifeGait) { swimIntro(1); return }   // v2.23 開場游過來
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
        if f.gentleT > 1 && moodC > 0.35 && fingers.isEmpty { happyT = t; wagT = t + 0.1; hop(); voice("happy") }
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
    private var tickOn: Bool { Double(tkTimes.count) >= params.tickRev }   // v2.24
    private static let grainTimes: [Double] = [0.06, 0.13, 0.21, 0.30], grainGains: [Double] = [0.8, 0.6, 0.42, 0.28]   // v2.25 F5
    private func moodStep(_ dt: Double) {
        guard params.emo >= 0.5 else { moodStrain = 0; tugX = 0; tugY = 0; purr = 0; escOn = false; return }
        var g: Finger?
        for f in fingers.values where f.mode == .grab { if g == nil || bodyStretch(f) > bodyStretch(g!) { g = f } }
        if let g {
            let st = bodyStretch(g), sp = hypot(g.vxS, g.vyS) / R   // v2.20: how far the body itself is pulled open (dragging it along is not a hard pull)
            // v2.24 rubSpeed: the limit in real speed (60 pt a second is about 1 cm), a tickle does not count; really rubbing, comfort comes twice as fast as held still
            let v24: Bool = params.rubSpeed > 0, spPt: Double = sp * R, rubbing: Bool = v24 && spPt > R * 0.3
            let rubOK: Bool = v24 ? (spPt < params.rubSpeed * 60 && !tickOn) : sp < 2
            g.gentleT = st < 0.6 && rubOK ? g.gentleT + dt * (rubbing ? 2 : 1) : max(0, g.gentleT - 2 * dt)
            if g.gentleT > 1 { moodC = min(1, moodC + (rubbing ? 0.6 : 0.35) * dt); moodA += (0.15 - moodA) * (1 - exp(-dt / 1.5)) }
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
            if stkG > 1 && t - stkLast < 0.05 {   // v2.26 F6: a stroke counts as comfort; the finger is on it half the time, so it rises twice as fast as a rub
                moodC = min(1, moodC + 1.2 * dt); moodA += (0.15 - moodA) * (1 - exp(-dt / 1.5))
            } else {
                moodC -= moodC * k; moodA -= moodA * k
            }
        }
        moodScare *= exp(-dt / 0.8)
        let tg = moodStrain * R * 0.35; tugX = -pullDX * tg; tugY = -pullDY * tg   // tug of war: you can still pull it
        let gentleNow: Bool = g != nil ? g!.gentleT > 1 : (stkG > 1 && t - stkLast < 0.6)
        let pt: Double = gentleNow && moodC > 0.2 ? min(1, (moodC - 0.2) / 0.5) : 0
        purr += (pt - purr) * (1 - exp(-dt / 0.3))
        if escOn {
            let p = min(1, (t - escT0) / escT), e = 1 - pow(1 - p, 3)
            let nx = escSX + (escDX - escSX) * e, ny = escSY + (escDY - escSY) * e
            wanderVX = (nx - homeX) / dt; wanderVY = (ny - homeY) / dt; homeX = nx; homeY = ny
            if lv(params.lifeGait) { strK = 1 + 0.15 * pow(1 - p, 2) * (reduceMotion ? 0.5 : 1); strH = atan2(escDY - escSY, escDX - escSX) }   // v2.19: stretched along the dash
            if p >= 1 {
                escOn = false; cowerUntil = t + 1.2 + Double.random(in: 0..<0.8); wanderNext = max(wanderNext, t + 2 + Double.random(in: 0..<1.5))
                if params.life2 >= 0.5 {   // v2.19 A6: out of breath after running away
                    if lv(params.lifeBreath) { exert = max(exert, 0.8) }
                    lifeSt = .rest; lifeUntil = cowerUntil + 1 + Double.random(in: 0..<1)
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
    private var camRSt = 0.0, camRUntil = -9.0   // v2.24 camGrip: how far this grab pulled; until when a release may move the shape back in
    private func updateCam(_ dt: Double) {
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
        enum Mode { case grab, push, none, stroke }   // v2.26 F6 stroke: sliding over it, nothing pinned
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
        var hitT = -9.0, stillT = 0.0                // v2.19: last time a push touched the body (A4); how long it has been held still (breath tap)
        var ex = 0.0, ey = 0.0, sb = -1.0            // v2.20: the limited stretch vector; how far the body itself is pulled open (minus what followed), −1 = not yet
        var lure = false, edge = 0.0                 // v2.20 C1 C2: landed on empty space (left to lureStep); distance to the body's edge
        var tkA: Double?, pushed2 = false            // v2.22 E2: last heading (tickle turns), pushed back once
        var judge = false, slowT = 0.0, on = false, trD = 0.0, tGrab = -9.0, rBase = 0.0   // v2.26 F6: still to be judged (stroke or grab); how long slow; on the body; travel since the last trail point; when a stroke became a grab; contact size to compare with
        var grainI = 0, grR = 0.0, grT = -9.0        // v2.25 F5: press grains played, contact size at the last grain, its time
        var tkP = 0.0, far = false, reachN: Int?     // v2.24: travel since the last turn (tickle or rub); moved off its spot (0.15R, it is no longer just a press); mem count before the reach strip
        var saidProt = false, saidPurr = false       // v2.22 E1: protested / hummed once this grab
        var dragMax = 0.0                            // v2.22: how far this grab dragged it (E3)
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
        R = max(60, min(W * params.bodySize, H * 0.18, 160))   // bodySize: 0.26 before v2.9, 0.22 v2.10 to v2.23, 0.30 v2.24 (about 4 cm wide; a finger is 1.6 to 2 cm)
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
        // v2.19
        lifeSt = .rest; lifeUntil = -1; lifeLooks = 0; lifeNoGo = false; sniffs = []; attOn = false; lifeWrg = 1; goFade = 0; arrT = -9; arrOff = 0
        gaitOn = false; gaitK = 1; gaitOff = 0; gaitV = 0; flAt = -9; flT0 = -9; flAmp = 0; flH = 1; flS = 1; shkAt = -9; shkT0 = -9; shkAmp = 0; shkTh = 0
        exert = 0; sighNext = -1; sighCyc = -1; pauseUntil = -9; brAmpX = 1; brCyc = 0; strK = 1; psm = (1, 0, 0, 1); lifeLB = 1
        // v2.20: a rebuild drops the fingers without a release, so the offset must go too or home stays off (measured on the web:
        // later tests leaned with it, a 3 s press moved 61 pt instead of 30)
        dragOX = 0; dragOY = 0; dragVX = 0; dragVY = 0; dragBX = 0; dragBY = 0; dragGX = 0; dragGY = 0; dragSlipT = 0; lureOn = false; lureSn = -1; askOn = false
        e4On = false; e4Wait = -1   // v2.22
        leanT = -9; leanO = 0; nuzT0 = -1; nuzO = 0; nuzSaid = false; tkTimes = []; tkT = 0; gigNext = 0; camRSt = 0; camRUntil = -9
        QDX = QX; QDY = QY; QVX = [Double](repeating: 0, count: N); QVY = QVX; QW = QVX; cvX = 0; cvY = 0; caX = 0; caY = 0; cpX = nil; cpY = nil; tickLastT = -9   // v2.25
        stkOX = 0; stkOY = 0; stkVX = 0; stkVY = 0; stkG = 0; stkLast = -9; stkSaid = false; stkPet = false; trail = []   // v2.26
        eyeSetup(); slpOn = false; slpK = 0; slpLastAny = -99; slpAskAt = -9; slpNearT = 0; flBoost = 1   // v2.23 (setup restarts the clock)
        echoSt = 0; echoTaps = []; echoJoyUntil = -9; echoPrevT = -99; echoBeatT = -9; swimOn = false
        SX2 = Array(repeating: 0, count: N); SY2 = Array(repeating: 0, count: N)
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
    /// `radius` is UITouch.majorRadius (contact size, points; 0 if unknown).
    /// `x, y` are screen points; the rig turns them into world points through the camera.
    func touchBegan(_ id: ObjectIdentifier, x sx: Double, y sy: Double, time: TimeInterval, allowed: Bool = true, radius: Double = 0) {
        guard N > 0 else { return }
        if introOn { let mini = introMini; endIntro(); if !mini { return } }   // v2.17: a touch on the way brings it home at once (eased in 0.25 s); this touch does not grab; during a happy hop it grabs as usual
        let (x, y) = toWorld(sx, sy)
        slpLastAny = t   // v2.23 B2: a tap anywhere counts as someone there
        if let old = fingers[id], old.sticking { release(id, quiet: true) }   // 候選 26: the same touch object came back while stuck
        let grab = allowed && (insideBody(x, y) || nearBody(x, y, R * 0.22))
        if grab { escOn = false }   // v2.18: caught, it stops running
        if grab { swimOn = false; wake(true) }   // v2.23: caught while swimming in, no hello; asleep, it startles awake
        if !grab && allowed {   // v2.23: asleep, a tap beside it wakes it (that tap is no rhythm); awake, C6 listens
            if slpOn { var db = 1e9; for i in bnd { db = min(db, hypot(X[i] - x, Y[i] - y)) }; if db < R * 2 { wake(false) }; echoTaps = [] }
            else { echoTap(x, y) }
        }
        // v2.19: caught, the sniffing pseudopods draw in and it stops walking; A5 the dent still shows at once (below) and 0.1...0.25 s
        // later it flinches by itself; A7 a touch on empty space within 3R makes it turn and sniff that way 0.3 s later
        // v2.20 C5: wary, it flinches sooner
        if grab && lv(params.lifeFlinch) && !(flAt > t) { flAt = t + (0.1 + Double.random(in: 0..<0.15)) * (iv2(params.impC5) ? 1 - 0.5 * impWary : 1); flPre = lifeSt }
        if grab && params.life2 >= 0.5 { cutSniffs(); gaitOn = false; gaitK = 1; wanderMoving = false; lifeSt = .rest; lifeUntil = -1; askOn = false }
        let lure = !grab && allowed && (iv2(params.impC1) || iv2(params.impC2))   // v2.20: a finger on empty space goes to C1, C2 (lureStep), not just one sniff
        if !grab && allowed && !lure && lv(params.lifeAttend) {
            var db = 1e9
            for i in bnd { db = min(db, hypot(X[i] - x, Y[i] - y)) }
            if db < R * 3 { attOn = true; attAt = t + 0.3; attX = x; attY = y }
        }
        let f = Finger(x: x, y: y, mode: !allowed ? .none : (grab ? .grab : .push), time: t)
        f.radius = radius; f.r0 = radius
        f.sx = sx; f.sy = sy
        f.lure = lure
        // C4: touched again while it begs, the purr comes in 0.3 s (a stroke normally takes 1 s)
        if grab && iv2(params.impC4) && t < impAskUntil { f.gentleT = 0.7; moodC = max(moodC, 0.5); impTrust = min(1, impTrust + 0.05); impAskUntil = -9 }
        if grab {
            fingerGrab(f, id: id, x: x, y: y)
            onEvent?(.press(gain: 0.7))
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
        for f in fingers.values where f.mode == .grab {
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
        f.tGrab = t; f.grainI = 0; f.grR = 0
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
        let mat = params, strokeOn: Bool = mat.strokeV > 0 && mat.inertiaHz > 0
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
                    f.tickNext = mat.tickSpacing * (0.7 + 0.6 * Double.random(in: 0..<1))
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
            if moodC > 0.35 && mat.emo >= 0.5 && !escOn { happyT = t; wagT = t + 0.1; hop(); voice("happy") }
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
        if f.mode == .grab { inertiaCatch() }
        for m in f.mem { GRAB[m.i] = false }
        for dn in dentList where dn.finger == id { dn.finger = nil; dn.held = t - f.tDown }   // held: how long it was pressed (D2)
        // v2.19 A4: a finger that never touched the body does not restart the fade-in; v2.20: nor one it reached by itself (lure)
        if !lv(params.lifeHeld) || f.mode == .grab || (f.hitT > -9 && !f.lure) { lastTouch = t }
        if f.mode == .grab { dragRelease(glide: !quiet) }
        if f.mode == .grab && !quiet { impRelease(f) }
        if f.mode == .grab && !quiet { moodRelease(f) }
        if f.mode == .grab && !quiet && params.life2 >= 0.5 { lifeRelease(f) }
        if f.mode == .grab && !quiet { impAsk(f) }
        if f.mode == .grab && !quiet { e2Release(f) }   // v2.22
        if (f.mode == .grab || f.mode == .stroke) && !quiet && !escOn { eyeUser = t + 1.2 }   // v2.23: let go, it looks at you
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
        dragRelease(glide: false)   // v2.20: the offset joins home, as on a normal release
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
            let tx = max(wl.l + mw, min(wl.r - mw, f.ax + ox + ex)), ty = max(wl.t + mw, min(wl.b - mw, f.ay + oy + ey))
            let k = mat.lag > 0 ? 1 - exp(-dt / mat.lag) : 1
            f.fx += (tx - f.fx) * k; f.fy += (ty - f.fy) * k
            if f.mode == .grab {
                let st = hypot(ex, ey) / R, step = Int(floor(st * 2.5))
                f.stretch = st; f.ex = ex; f.ey = ey
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
                // v2.25 F5 grains (提案第 13 條): one every `tickSpacing` points of real travel (±30%), closer as it is stretched (tickTense), at most tickRate a second, none while the finger is still
                if mat.tickSpacing > 0 {
                    let pullK: Double = min(1, f.stretch / 2), tense: Double = 1 - mat.tickTense * pullK
                    if f.tickNext <= 0 { f.tickNext = mat.tickSpacing * tense; f.tickAt = f.travel }
                    if f.travel - f.tickAt >= f.tickNext && f.speedC > R * 0.1 && t - tickLastT >= 1 / max(1, mat.tickRate) {
                        f.tickAt = f.travel   // what was travelled while capped is forgiven: no burst afterwards
                        f.tickNext = mat.tickSpacing * tense * (0.7 + 0.6 * Double.random(in: 0..<1))
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

        strokeStep(dt)   // v2.26 F6
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
                if sighNext < 0 { sighNext = t + 30 + Double.random(in: 0..<60) }
                let ex = exert, cyc = Int(floor(brPhase))
                T *= (1 + 0.15 * Self.vnoise(77, brPhase * 0.9)) * (1 - 0.5 * ex); brAmpX = 1 - 0.3 * ex
                if sighCyc < 0 && t > sighNext && ex < 0.2 && lifeSt != .go { sighCyc = cyc + 1 }
                if cyc == sighCyc { T *= 1.6; brAmpX *= 1.8 }
                else if sighCyc >= 0 && cyc > sighCyc { sighCyc = -1; pauseUntil = t + 1; sighNext = t + 30 + Double.random(in: 0..<60) }
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
            let dw = w - brJw
            brJw = w; brWave = -w; brAmp = mat.jellyAmp / 0.045 * (1 + 0.5 * max(0, moodC)) * (1 - 0.4 * max(moodA, moodScare)) * brAmpX * (1 + 0.35 * slpK)
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
        sleepStep(dt); echoStep(dt)   // v2.23 B2, C6
        if mat.life2 >= 0.5 {
            lifeStep(dt, idle, engaged)   // v2.19: rest / look / go / arrive + the pulse gait + flinch, shake-off + sniffing (with lifeRest and lifeGait off, v2.18's walk-and-pause)
        } else if L > 0.5 && mat.wander > 0 && !introOn && !escOn && t > cowerUntil {
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
        for _ in 0..<n { substep(sdt, L, Lamp, tl) }
        tentBump()
        plasticity(dt)
        twitch(L)
        eyeStep(dt)   // v2.23
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
            trm = R * 0.016 * min(1, moodStrain + moodScare) * (reduceMotion ? 0.5 : 1)
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
        for i in 0..<N {
            var ex: Double = inertiaOn ? QDX[i] : QX[i], ey: Double = inertiaOn ? QDY[i] : QY[i]
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
        // v2.19 performed scaling of the rest shape: breathing and mood (bsx, bsy) × the flinch (flS) × stretched along the heading while
        // walking or fleeing (strK, area kept). Memory takes it off (psm)
        var m00 = bsx * flS, m01 = 0.0, m10 = 0.0, m11 = bsy * flS
        if strK != 1 {
            let u = strH - atan2(clusters[gi].sn, clusters[gi].cs), cu = cos(u), su = sin(u), ka = strK - 1, kb = 1 / strK - 1
            let d00 = 1 + ka * cu * cu + kb * su * su, d01 = (ka - kb) * cu * su, d11 = 1 + ka * su * su + kb * cu * cu
            m00 = bsx * flS * d00; m01 = bsx * flS * d01; m10 = bsy * flS * d01; m11 = bsy * flS * d11
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
        let A0p = (mat.press2 >= 0.5 ? A0 * (1 + mat.pressArea * pressSum) : A0) * flS * flS   // v2.16 P1: pressed from the front it thins, so it looks bigger; v2.19 the flinch really shrinks it (else the area pressure pushes it back)
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
        let hx = homeX + tugX + dragOX + Lamp * mat.life * R * 0.035 * sin(tl * 2 * .pi / 7.3)
        let hy = homeY + tugY + dragOY - brLift + (mat.jelly >= 0.5 ? 0 : Lamp * mat.life * R * 0.05 * sin(tl * 2 * .pi / 4.7))   // jellyfish: up and down only with the pulse
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
            let yl = mat.yield * R, kc: Double = min(1, mat.creep * dt * g) * (mat.rubSpeed > 0 && tickOn ? 0.0 : 1.0)   // v2.24: a tickle is not sculpting
            // v2.24 pressLocal: while the finger has not moved off (0.15R) only the part near it remembers. With the whole body remembering, holding still wrote the
            // small shape-matching errors into the far edge, a 48° corner in 4 s (in Q itself); once it moves the whole body remembers as before, pulls keep their shape
            let plGrabs = fingers.values.filter { $0.mode == .grab }
            for f in plGrabs where !f.far && hypot(f.rawX - f.ax, f.rawY - f.ay) > R * 0.15 { f.far = true }
            let plOn: Bool = mat.pressLocal >= 0.5 && plGrabs.allSatisfy { !$0.far }, plK: Double = 1 / (0.49 * R * R)
            // v2.16: the press push is a performance, taken off before remembering (turned into rest space). Kept, clay remembered
            // the pushed shape and the next step pushed again on top: the longer the hold the wider (measured: 1.5 s moved 48 pt, was 24)
            let pf = pressField(), gcs = clusters[gi].cs, gsn = clusters[gi].sn
            if kc > 0 {
                for i in 0..<N {
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
        tentRest(dt, mat)
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
        let s = Sniff(a: a, L: len, t0: t, T1: T1, T2: T2, T3: T3, ph: Double.random(in: 0..<6.283), id: sniffSeq)
        sniffs.append(s)
        return s
    }
    /// Rest length: mostly 3...5 s, now and then a long stare; comfortable longer, tense shorter (lifeRest off: v2.18's 0.8...3 s).
    private func restDur() -> Double {
        if !lv(params.lifeRest) { return 0.8 + Double.random(in: 0..<2.2) }
        var d = 2.5 + Double.random(in: 0..<3.5)
        if Double.random(in: 0..<1) < 0.2 { d += 5 + Double.random(in: 0..<6) }
        return d * params.restMul * (1 + 0.5 * max(0, moodC)) * (1 - 0.5 * max(moodA, moodScare)) * (iv2(params.impC5) ? 1 - 0.4 * impWary : 1)   // v2.20 C5: wary rests less
    }
    private func pickDir() -> Double {
        if hypot(homeX - cx, homeY - cy) > W * 2.5 { return atan2(cy - homeY, cx - homeX) + Double.random(in: -0.6..<0.6) }   // too far out: sniff back
        if iv2(params.impC5) && impHas {   // v2.20: trusting sniffs toward where you last touched it (and mostly goes), wary the other way
            let dx = impLX - homeX, dy = impLY - homeY, d = hypot(dx, dy), ta = atan2(dy, dx), r = Double.random(in: 0..<1)
            if d > R * 1.5 && r < 0.6 * impTrust { return ta + Double.random(in: -0.3..<0.3) }
            if d < R * 3 && r < 0.6 * impWary { return ta + .pi + Double.random(in: -0.4..<0.4) }
        }
        return Double.random(in: 0..<(2 * .pi))
    }
    /// Set off toward `dir` (the way it just sniffed) or, with none, anywhere (up and down at 0.8); far and fast with the `dash` chance.
    private func goStart(_ dir: Double?) {
        let far = Double.random(in: 0..<1) < params.dash
        let dist = W * (far ? 0.5 + 0.4 * Double.random(in: 0..<1) : 0.2 + 0.3 * Double.random(in: 0..<1))
        var a = dir ?? Double.random(in: 0..<(2 * .pi))
        let ys = dir == nil ? 0.8 : 1.0
        if hypot(homeX - cx, homeY - cy) > W * 3 { a = atan2(cy - homeY, cx - homeX) + Double.random(in: -0.5..<0.5) }
        lifeSt = .go; wanderSX = homeX; wanderSY = homeY; wanderX = homeX + cos(a) * dist; wanderY = homeY + sin(a) * dist * ys; wanderMoving = true
        if lv(params.lifeGait) {
            gaitOn = true; gaitTX = wanderX; gaitTY = wanderY; gaitDash = far; gaitPh = -1; gaitPrep = 0; gaitV = 0
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
        return ((gaitDash ? 0.62 : 1.1) * (rm ? 2 : 1), (gaitDash ? 0.15 : 0.25) * (rm ? 2 : 1), (gaitDash ? 0.24 : 0.35) * (rm ? 2 : 1),
                (gaitDash ? 0.8 : 0.5) * R * (rm ? 0.5 : 1), (gaitDash ? 0.17 : 0.12) * (rm ? 0.5 : 1))
    }
    private func strokeStart(_ K: (P: Double, c: Double, tau: Double, sd: Double, kA: Double)) {
        let dx = gaitTX - homeX, dy = gaitTY - homeY, rem = hypot(dx, dy)
        gaitH = atan2(dy, dx) + Double.random(in: -0.21..<0.21)   // each stroke veers a little (±12°): a curved path, speed and heading change together
        let per = K.c / 2 + K.tau * (1 - exp(-(K.P - K.c) / K.tau))   // how far this speed profile goes per unit of peak speed
        if rem < K.sd * 1.4 { gaitLast = true; gaitStr = max(0.35, min(1, rem / K.sd)) } else { gaitStr = 1 }   // the last stroke is smaller
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
        if lv(params.lifeAttend) && !escOn && !introOn && !clusters.isEmpty && hypot(f.fx - clusters[gi].xc, f.fy - clusters[gi].yc) > R * 0.4 {
            attOn = true; attAt = t + 0.5; attX = f.fx; attY = f.fy
        }
        lifeSt = .rest; lifeUntil = t + 1.5 + Double.random(in: 0..<2)
    }
    private func lifeStep(_ dt: Double, _ idle: Double, _ engaged: Bool) {
        swimGreet()   // v2.23: swum home, say hello
        // A5 flinch when its time comes (resting before the touch ×1.2, walking ×0.8; comfortable half; each flinch ×0.55, back with 7 s)
        flH += (1 - flH) * (1 - exp(-dt / 7))
        if flAt > 0 && t >= flAt {
            flAt = -9
            if lv(params.lifeFlinch) {
                let pre: Double = (flPre == .rest ? 1.2 : (flPre == .go ? 0.8 : 1)) * flBoost
                let a = params.flinchAmp * pre * (moodC > 0.3 ? 0.5 : 1) * flH * (reduceMotion ? 0.5 : 1) * (iv2(params.impC5) ? 1 + 1.2 * impWary : 1)   // v2.20 C5
                flAmp = a; flT0 = t; flH *= 0.55; flBoost = 1; cutSniffs()
                if lv(params.lifeBreath) { exert = max(exert, 0.1 + 2 * a) }   // a quick breath in with it
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
        // A7 sniff toward a queued point (this version only sniffs, it does not walk there: it rests after)
        if attOn && t >= attAt {
            attOn = false
            if !engaged && !escOn && !introOn && lv(params.lifeAttend) && !clusters.isEmpty {
                let dx = attX - clusters[gi].xc, dy = attY - clusters[gi].yc, d = hypot(dx, dy), ang = atan2(dy, dx)
                startSniff(ang, max(0.3, min(params.podLen * 1.1, d / R - 0.6)), 0.5, 0.7 + Double.random(in: 0..<0.4), 0.6)
                gaitOn = false; wanderMoving = false
                lifeSt = .look; lifeLooks = 0; lifeNoGo = true; lastDir = ang; lifeUntil = t + 1.8 + Double.random(in: 0..<0.4)
            }
        }
        // A1 deciding: rest → look (85%) or go; look sniffs once or twice → 65% go the last way sniffed, else rest; arrive → bump → rest
        let restOn = lv(params.lifeRest), canGo = params.wander > 0
        let free = idle > 0.5 && !introOn && !escOn && t > cowerUntil && !engaged
        if lifeUntil < 0 { lifeUntil = t + (restOn ? 1.5 + Double.random(in: 0..<1) : 0.8 + Double.random(in: 0..<1)) }
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
        if echoSt != 0 { return }   // v2.23 C6: listening to your rhythm or answering it: it stays put
        if lifeSt == .rest && sleepTry() { return }
        let lured = lureStep(dt)   // v2.20 C1 C2: a finger resting beside it takes over
        let e4 = !lured && e4Step(dt)   // v2.22 E4: trusting and left alone a while, it comes to the front to say hello
        // v2.20 C4 begging: a pseudopod toward where your finger left, edging over when that is far
        if !lured && !e4 && askOn && t >= askAt && !clusters.isEmpty {
            askOn = false; voice("ask", 0.6)
            let dx = askX - clusters[gi].xc, dy = askY - clusters[gi].yc, d = max(1e-6, hypot(dx, dy)), ang = atan2(dy, dx)
            startSniff(ang, max(0.4, min(1.2, d / R - 0.7)), 0.5, 1.5, 0.7)
            if d > R * 1.6 { gaitTo(askX - dx / d * R * 1.1, askY - dy / d * R * 1.1, dash: false) }
            else { lifeSt = .look; lifeLooks = 0; lifeNoGo = true; lastDir = ang; lifeUntil = t + 2.8 }
        }
        if !lured && !e4 {
            if lifeSt == .rest && t >= lifeUntil {
                if restOn && (Double.random(in: 0..<1) < 0.85 || !canGo) { lifeSt = .look; lifeLooks = Double.random(in: 0..<1) < 0.45 ? 2 : 1; lifeNoGo = false; lifeUntil = t }
                else if canGo { goStart(nil) } else { lifeUntil = t + restDur() }
            }
            if lifeSt == .look && t >= lifeUntil {
                if lifeLooks > 0 {
                    lifeLooks -= 1
                    let a = pickDir(), s = startSniff(a, params.podLen * (0.75 + 0.35 * Double.random(in: 0..<1)), 1.2, 0.5 + Double.random(in: 0..<1), 0.8)
                    lastDir = a; lifeUntil = t + s.T1 + s.T2 + s.T3 + 0.3 + Double.random(in: 0..<0.5)
                } else if !lifeNoGo && canGo && Double.random(in: 0..<1) < 0.65 {
                    goStart(lastDir + Double.random(in: -0.175..<0.175))
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
        if params.emo >= 0.5 { k *= 1 - 0.7 * moodStrain }
        return k
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
        for f in fingers.values where f.mode == .grab { sx += f.x - f.ax; sy += f.y - f.ay; n += 1 }
        if n == 0 { return (0, 0, 0) }
        let dx = sx / Double(n), dy = sy / Double(n), dl = hypot(dx, dy)
        if dl < 1e-9 { return (0, 0, n) }
        let S = slideLen(), st: Double = S * tanh((1 - dragFollow()) * dl / S)
        return (dx - dx / dl * st, dy - dy / dl * st, n)
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
        var vx = dragVX, vy = dragVY
        let vl = hypot(vx, vy), vm = R * (params.slide > 0 ? 6 : 1.6)   // v2.21: a fling glides on up to about 1.5R (v2.20 0.4R)
        if vl > vm { vx *= vm / vl; vy *= vm / vl }
        if glide && vl > R * 0.3 { dragGX = vx; dragGY = vy }
        homeX += dragOX; homeY += dragOY
        dragOX = 0; dragOY = 0; dragVX = 0; dragVY = 0; dragBX = 0; dragBY = 0; dragSlipT = 0
    }
    /// Every frame: the offset eases toward `drag` of the travel (home moves, and the held home spring brings the body along);
    /// sb = how far the body itself is pulled open, used by the mood and the shake-off.
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
            let w: Double = 2 * Double.pi * params.dragHz, zz: Double = 2 * (reduceMotion ? max(params.dragSpring, 0.9) : params.dragSpring) * w
            dragVX += (w * w * (g.x + dragBX - dragOX) - zz * dragVX) * dt
            dragVY += (w * w * (g.y + dragBY - dragOY) - zz * dragVY) * dt
            dragOX += dragVX * dt; dragOY += dragVY * dt
        } else {
            let nx = dragOX + (g.x + dragBX - dragOX) * e, ny = dragOY + (g.y + dragBY - dragOY) * e
            dragVX = (nx - dragOX) / dt; dragVY = (ny - dragOY) / dt; dragOX = nx; dragOY = ny
        }
        for f in fingers.values where f.mode == .grab { f.dragMax = max(f.dragMax, hypot(dragOX - dragBX, dragOY - dragBY)) }   // v2.22 E3: how far this grab led it
        for f in fingers.values where f.mode == .grab { f.sb = params.slide > 0 ? f.stretch : hypot(f.ex - (dragOX - dragBX), f.ey - (dragOY - dragBY)) / R }   // v2.21: the stretch already counts from where it followed to
        // C3: very wary, pulled open 1R or more for 1.5 s, the patch slips from the finger and it slinks off a little
        if iv2(params.impC3) && impWary > 0.5 {
            var st = 0.0
            var g: Finger?
            for f in fingers.values where f.mode == .grab && bodyStretch(f) > st { st = bodyStretch(f); g = f }
            dragSlipT = st > 1 ? dragSlipT + dt : 0
            if let g, dragSlipT > 1.5 {
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
    func resetImpression() { impTrust = 0; impWary = 0; impHas = false; impAskUntil = -9 }
    /// At release, what kind of grab it was goes into the impression: pulled until it wanted to flee, poked in a row, flung hard → wary;
    /// a gentle one takes a fifth of the wariness off (C5 calming). Before moodRelease (which clears strainMax).
    private func impRelease(_ f: Finger) {
        guard params.imp >= 0.5 else { return }
        impLX = f.fx; impLY = f.fy; impHas = true
        let w0 = impWary
        let quick = t - f.tDown < 0.25 && f.stretch < 0.3, nTaps = taps.filter { t - $0 < 1 }.count + 1, fling = f.peak / R > 6
        if moodStrainMax > 0.15 { impWary += 0.15 + 0.25 * moodStrainMax; impTrust -= 0.15 }
        else if quick { impWary += nTaps >= 3 ? 0.2 : 0.04; if nTaps >= 3 { impTrust -= 0.1 } }
        else if fling { impWary += 0.1; impTrust -= 0.05 }
        else { impWary *= 0.8; if iv3(params.e3) && f.dragMax > R * 0.5 { impTrust += 0.12 } }   // v2.22 E3: led along gently, a little more trust
        if impWary > w0 { impWary = w0 + (impWary - w0) * params.wRate }   // v2.23 personality: how fast it turns wary
        impTrust = max(0, min(1, impTrust)); impWary = max(0, min(1, impWary))
    }
    /// C4 begging: released after a purr (the happy hop), 0.9 s later it reaches toward where your finger left and edges over if far;
    /// touched again within 5 s, the purr comes fast (touchBegan).
    private func impAsk(_ f: Finger) {
        guard iv2(params.impC4), !escOn, impTrust >= 0.2, f.gentleT > 1, moodC > 0.35, fingers.isEmpty else { return }
        impAskUntil = t + 5; attOn = false; askOn = true; askAt = t + 0.9; askX = f.fx; askY = f.fy
    }
    /// Every frame: stroking, purring and a gentle drag build trust (20...25 s of stroking to very trusting); wariness halves in 3 min.
    /// Trust does not fade with time (it does not cool off because you were away).
    private func impStep(_ dt: Double) {
        guard params.imp >= 0.5 else { return }
        var g: Finger?
        for f in fingers.values where f.mode == .grab { if g == nil || bodyStretch(f) > bodyStretch(g!) { g = f } }
        if let g {
            let st = bodyStretch(g), sp = hypot(g.vxS, g.vyS) / R
            let e3m: Double = (iv3(params.e3) ? 3 : 1) * params.trRate   // v2.22 E3: trust grows three times faster (5 s of stroking shows); v2.23 personality
            if g.gentleT > 1 { impTrust += (0.04 + 0.04 * purr) * dt * e3m; impWary -= 0.05 * dt * e3m }
            else if st < 1.2 && sp > 0.3 && sp < 3 && moodStrain < 0.05 && hypot(dragOX, dragOY) > R * 0.3 { impTrust += 0.02 * dt * e3m }
        } else if stkG > 1 && t - stkLast < 0.05 {   // v2.26 F6: strokes build trust too
            let e3m: Double = (iv3(params.e3) ? 3 : 1) * params.trRate
            impTrust += (0.04 + 0.04 * purr) * dt * e3m; impWary -= 0.05 * dt * e3m
        }
        impWary *= exp(-dt / 260)
        impTrust = max(0, min(1, impTrust)); impWary = max(0, min(1, impWary))
        let ks = 1 - exp(-dt / 1)
        impShownTrust += (impTrust - impShownTrust) * ks; impShownWary += (impWary - impShownWary) * ks
    }
    /// Walk to a point (C1 swimming over or backing off, C4 edging over): goStart's gait (the pulse; with it off, v2.18's glide).
    private func gaitTo(_ x: Double, _ y: Double, dash: Bool) {
        lifeSt = .go; wanderSX = homeX; wanderSY = homeY; wanderX = x; wanderY = y; wanderMoving = true
        if lv(params.lifeGait) {
            gaitOn = true; gaitTX = x; gaitTY = y; gaitDash = dash; gaitPh = -1; gaitPrep = 0; gaitV = 0
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
    private func voice(_ kind: String, _ g: Double = 0.8) {
        guard iv3(params.e1), t - voiceLast >= 0.3 else { return }
        voiceLast = t
        onEvent?(.voice(kind: kind, gain: g, rate: (1 + 0.1 * impTrust - 0.08 * impWary) * Double.random(in: 0.96..<1.04) * params.voicePitch))
    }
    private func firstGrab() -> Finger? { fingers.values.first { $0.mode == .grab } }
    /// E1: pulled until it wants to flee → "mm-mm"; purring → "mmm~" (once a grab each).
    private func e1Step() {
        guard iv3(params.e1) else { return }
        guard let g = firstGrab() else {
            if purr > 0.3 && stkG > 1 && !stkSaid && t - stkLast < 0.6 { stkSaid = true; voice("mmm", 0.6) }   // v2.26 F6
            return
        }
        if moodStrain > 0.5 && !g.saidProt { g.saidProt = true; voice("protest") }
        if purr > 0.3 && !g.saidPurr { g.saidPurr = true; if !nuzSaid { voice("mmm", 0.6) } }   // already nuzzling and hummed: not again
    }
    /// E2 a tap (under 0.25 s, not pulled): after the flinch it leans toward your finger and says "pu"; wary, it leans away.
    private func e2Release(_ f: Finger) {
        guard iv3(params.e2), t - f.tDown < 0.25, f.stretch < 0.3, !clusters.isEmpty else { return }
        leanT = t + 0.3; leanA = atan2(f.fy - clusters[gi].yc, f.fx - clusters[gi].xc); leanS = impWary > 0.4 ? -1 : 1; voice("poke", 0.7)
    }
    /// E2 every frame: held still 0.35 s it pushes back once (a soft tap); still 0.8 s it nuzzles; tickled it squirms, past 3 s it slips free.
    private func e2Step(_ dt: Double) {
        guard iv3(params.e2), !clusters.isEmpty else { nuzT0 = -1; return }
        guard let g = firstGrab() else { nuzT0 = -1; nuzSaid = false; tkTimes.removeAll(); tkT = 0; return }
        let sp = hypot(g.vxS, g.vyS) / R, dx = g.fx - clusters[gi].xc, dy = g.fy - clusters[gi].yc, l = max(1e-6, hypot(dx, dy))
        if !g.pushed2 && t - g.tDown > 0.35 && sp < 0.5 && g.stretch < 0.3 && impWary < 0.4 {
            g.pushed2 = true
            if Double.random(in: 0..<1) < 0.3 { leanT = t; leanA = atan2(dy, dx); leanS = 1; onEvent?(.nudge) }
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
            let warn: Bool = params.tickFree > 3 && tkT > params.tickFree - 2   // v2.24: the last 2 s it protests and squirms harder before it breaks free
            if t >= gigNext { gigNext = t + 0.7; shkAt = -9; shkT0 = t; shkAmp = warn ? 0.8 : 0.45; voice(warn ? "protest" : "giggle") }
            if tkT > params.tickFree {
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
        if sp < 0.3 && g.stretch < 0.4 && !tickling {
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
            if e4Wait < 0 { e4Wait = (10 + Double.random(in: 0..<10)) * params.e4Mul }
            guard impTrust > 0.5, e4Count < 3, t - lastTouch > e4Wait, t - e4LastT > 40, fingers.isEmpty, lifeSt == .rest else { return false }
            let q = toWorld(W / 2, viewV.y + H * 0.12), dx = q.x - clusters[gi].xc, dy = q.y - clusters[gi].yc, d = hypot(dx, dy)
            e4On = true; e4Wave = false; e4T0 = t
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
        if let g { o = tow(g.fx, g.fy) }
        else if let pf { o = tow(pf.fx, pf.fy) }
        else if echoSt != 0 { o = tow(echoX, echoY) }
        else if t < eyeUser || slpOn { o = (0, 0) }
        else if escOn { o = tow(escDX, escDY) }
        else if gaitOn { o = (cos(gaitH), sin(gaitH)) }
        else if let s = sniffs.last, !(s.cut > 0) { o = (cos(s.a), sin(s.a)) }
        if o == nil {
            if t >= eyeSacT {
                eyeSacT = t + 1.2 + Double.random(in: 0..<2.8)
                if Double.random(in: 0..<1) < 0.45 { eyeSX = 0; eyeSY = 0 }
                else { let a = Double.random(in: 0..<(2 * .pi)), k = (0.5 + Double.random(in: 0..<0.5)) * (params.gazeAmp > 0.1 ? 0.5 : 1); eyeSX = cos(a) * k; eyeSY = sin(a) * k * 0.7 }   // v2.24: idle glances do not grow with gazeAmp
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
        if let g, g.peak / R > 5 && bodyStretch(g) > 0.8 { eyeSqU = t + 0.45 }   // a yank squeezes them shut (one finger drags it along, it rarely strains to flee)
        let happy = purr > 0.3 || (t >= happyT && t - happyT < 1.6) || (e4On && e4Wave) || t < echoJoyUntil
        let squeeze = moodStrain > 0.4 || tickOn || (escOn && t - escT0 < 0.5) || t < eyeSqU
        let mode: EyeMode = slpK > 0.65 ? .sleep : (squeeze ? .squeeze : (happy ? .happy : .open))
        if mode != eyeMode { eyeMode = mode; if mode == .open { eyeBlinkT = t - 0.08 } }   // back to open: opening from shut
        var open = 1.0, wide = 1.0
        if slpOn || slpK > 0.02 { open = max(0, 1 - slpK * 1.5) }
        if let g { open = min(open, t - g.tDown < 0.3 ? 0.55 : 0.8) }
        do { let u = t - flT0; if flAmp > 0.02 && u >= 0 && u < 0.22 && echoSt != 2 { open = min(open, 0.3) } }
        if impWary > 0.5 || moodScare > 0.3 || t - slpWakeT < 0.8 { wide = 1.18 }
        do { let u = t - eyePulse; if u >= 0 && u < 0.15 { wide *= 1 + 0.15 * sin(.pi * u / 0.15) } }
        if mode == .open && t >= eyeNextBlink && !slpOn { eyeBlinkT = t; eyeNextBlink = t + (Double.random(in: 0..<1) < 0.2 ? 0.32 : 2 + Double.random(in: 0..<4)) }
        let u = t - eyeBlinkT
        eyeBlink = u < 0 ? 1 : (u < 0.07 ? 1 - u / 0.07 : (u < 0.11 ? 0 : (u < 0.21 ? (u - 0.11) / 0.1 : 1)))
        let k = 1 - exp(-dt / 0.05)
        eyeOpenD += (open - eyeOpenD) * k; eyeWideD += (wide - eyeWideD) * k
    }
    /// B2: untouched 40 s (a tap on empty space counts) while resting, it falls asleep: eyes close, it melts a little, breathes slow and deep.
    private func sleepTry() -> Bool {
        guard iv3(params.sleep), !slpOn else { return false }
        guard t - max(lastTouch, slpLastAny) >= 40, lifeSt == .rest, fingers.isEmpty, !e4On, echoSt == 0, !swimOn else { return false }
        slpOn = true; lifeSt = .sleep; cutSniffs()
        return true
    }
    /// Awake again: sharp (touched) it flinches 1.6× and opens wide; gently (a finger beside it) it just opens; then "mm?".
    private func wake(_ sharp: Bool) {
        guard slpOn else { return }
        slpOn = false; slpWakeT = t; slpNearT = 0; lifeSt = .rest; lifeUntil = t + 1.5 + Double.random(in: 0..<1); eyeBlinkT = t
        if sharp { flAt = t + 0.05; flPre = .rest; flBoost = 1.6 }
        slpAskAt = t + (sharp ? 0.45 : 0.3)
    }
    private func sleepStep(_ dt: Double) {
        if !iv3(params.sleep) && slpOn { wake(false) }
        if slpOn, fingers.values.contains(where: { t - $0.hitT < 0.05 }) { wake(true) }   // a finger pushed in from outside touched it
        slpK += ((slpOn ? 1 : 0) - slpK) * (1 - exp(-dt / (slpOn ? 1.6 : 0.25)))
        if slpK < 1e-3 && !slpOn { slpK = 0 }
        if slpAskAt > 0 && t >= slpAskAt { slpAskAt = -9; voiceLast = -9; voice("ask", 0.6); eyeUser = t + 1.2 }
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
                echoSt = 0; eyeUser = t + 1.5; lifeSt = .rest; lifeUntil = t + 2 + Double.random(in: 0..<1)
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
        swimOn = true; swimT0 = t; lastTouch = t - 3
        gaitTo(cx, cy, dash: !rm)
    }
    private func swimGreet() {
        guard swimOn else { return }
        if t - swimT0 > 9 { swimOn = false; return }
        if lifeSt == .rest { swimOn = false; eyeUser = t + 2; wagT = t + 0.1; voiceLast = -9; voice("hello"); lifeUntil = t + 2.5 }
    }

    /// Every few seconds a cluster gets a small impulse; sometimes the whole body.
    private func twitch(_ L: Double) {
        if t < nextTwitch { return }
        nextTwitch = t + 2.2 + Double.random(in: 0..<4.5)
        if L < 0.5 || params.life <= 0 || lv(params.lifeRest) { return }   // v2.19 A1: no causeless twitches
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
        for f in fingers.values where f.mode == .grab || (f.mode == .stroke && f.on) { sp = max(sp, f.speedC / R) }
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

    /// v2.19 A4: how long the grabbing finger has been held still (s); past 0.8 s each breath comes through as one soft tap.
    var heldStill: Double { fingers.values.filter { $0.mode == .grab }.map(\.stillT).max() ?? 0 }
}
