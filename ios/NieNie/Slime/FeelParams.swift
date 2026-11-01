import UIKit

/// Feel parameters, same names and meanings as the web prototype's `PRESETS`
/// (prototype/web/index.html) and 參數表. Haptic and sound numbers only exist here.
struct FeelParams: Equatable, Codable {
    var alpha: Double      // shape-matching stiffness per substep (0...1)
    var damp: Double       // Verlet velocity damping per substep
    var yield: Double      // deformation (in radii) before the body starts remembering a shape
    var creep: Double      // how fast the remembered shape follows the current one (per second)
    var recover: Double    // how fast the remembered shape relaxes back (per second)
    var grabR: Double      // grab radius, in radii
    var maxPull: Double    // soft stretch limit, in radii
    var lag: Double        // sticky lag behind the finger (s)
    var wGlobal: Double    // weight of the whole-body cluster (bigger = more like one lump)
    var cSpace: Double     // cluster spacing, in radii (smaller = softer)
    var cRad: Double       // cluster radius, in radii
    var upright: Double    // how fast it turns back head-up (per substep)
    var anchor: Double     // how much harder it stays put while grabbed
    var areaGain: Double   // area pressure: how much the sides bulge when squashed
    var gripRot: Double    // extra upright strength while grabbed
    var life: Double       // idle motion amount (0 = still)
    var drift: Double      // tentacle sway amplitude, in radii
    var wriggle: Double    // whole-body travelling-wave amplitude, in radii
    var wander: Double     // idle roaming speed, radii per second
    var floppy: Double     // how much softer tentacle tips are (0...0.9)
    var seed: Double       // shape seed (1...30); changing it rebuilds the body

    // v2.3 press (接觸點先凹): the grabbed patch spreads away from the finger. The side view
    // cannot show depth, so "pressing in" is drawn as squashing flat. Visible spread is about
    // half the number (the finger constraint and shape matching meet in the middle).
    var pressBase: Double = 0.12      // spread on contact, in radii
    var pressHold: Double = 0.18      // extra spread while held still, in radii
    var pressHoldTime: Double = 0.6   // seconds held still to reach the full extra spread
    var pressRise: Double = 0.06      // time constant of the spread (s)
    var pressFirst: Double = 0.5      // fraction of the target applied on the very first frame
    // plasticity only after dwelling (輕按回彈，揉捏即留形)
    var dwellLo: Double = 0.2         // seconds grabbed before the body starts remembering
    var dwellHi: Double = 0.6         // seconds grabbed until it remembers at full speed

    // v2.4 second-batch candidates (手感精修提案). Defaults are the control values (the v2.3 behaviour);
    // the panel's 候選 buttons apply one candidate at a time for blind tests.
    var idleFreeze: Double = 0        // 1: idle motion freezes its clock while touched instead of fading to the rest pose (第 19 條)
    var specialEvery: Double = 0      // every N releases (±2) one comes back extra bouncy; 0 = off (第 2 條)
    var pressRadiusGain: Double = 0   // extra press spread from contact size (UITouch.majorRadius); 0 = off (第 9 條)
    // haptics (第 38 條 on the panel; candidates 12, 13, 14)
    var hapMax: Double = 0.8          // continuous haptic ceiling
    var hapStatic: Double = 1         // continuous haptic: weight of deformation^1.5
    var hapRate: Double = 0           // continuous haptic: weight of the rate of change (candidate 0.75 with static 0.25)
    var hapRateNorm: Double = 2.5     // rate of change that counts as full, per second
    var hapSharp: Double = 0.25       // continuous haptic sharpness
    var hapSharpStretch: Double = 0   // extra sharpness when stretched (第三批第 15 條)
    var popMin: Double = 0.3          // release pop intensity at zero strength
    var popMax: Double = 0.7          // release pop intensity at full strength
    var popSharp: Double = 0.45       // release pop sharpness
    var popCount: Double = 1          // taps per release (candidate: clay 1, mochi 2, jelly 3)
    var popGap: Double = 0.09         // seconds between taps
    var popDecay: Double = 0.5        // each tap is this fraction of the previous
    var tickSpacing: Double = 0       // texture tick every N points of finger travel; 0 = off (candidate 8)
    var tickMin: Double = 0.10        // tick intensity when the finger is slow
    var tickMax: Double = 0.30        // tick intensity at 3 radii per second
    var tickSharp: Double = 0.4       // tick sharpness
    // 提案第 41 條 (2026-11-01): tentacle rungs. 0 = the v2.4 behaviour, where a tentacle pushed root-to-tip could fold over itself
    var tentRung: Double = 0.5        // the two edges of a tentacle stay on their own sides, at least this fraction of the rest width apart
    var tentAxis: Double = 0.85       // each link of a tentacle's medial axis keeps advancing by at least this fraction of its rest length
    // 提案第 20 條 (2026-11-01): while wandering the tentacles trail the motion
    var tail: Double = 0.12           // tentacle tail while wandering, in radii at the nominal wander speed (tips most); 0 = off
    // 第三批其餘 (2026-11-01): all defaults are the control values
    var homeK: Double = 0.02          // idle home spring per substep (候選 21: 0.003)
    var afterglow: Double = 0         // seconds of extra wobble after a release, damping eases from 0.975 (候選 22: 0.25)
    var breathT: Double = 3.8         // breathing period, seconds (候選 23a: 6)
    var breathShape: Double = 0       // 1: inhale 40%, exhale 55%, pause 5% (候選 23b)
    var breathDeep: Double = 0        // 1: a grab held over 10 s makes the next 20 s breathe deeper and slower (候選 23c)
    var pinchSquish: Double = 1       // 1: squish events when two grabbing fingers close in (提案第 24 條)
    var slip: Double = 0              // 1: pulling past 1.2× maxPull for 120 ms slips out of the fingers (候選 25)
    var stick: Double = 0             // seconds a slow lift keeps holding before the release (候選 26: 0.1)
    var localArea: Double = 0         // area pressure weighted towards the fingers (候選 27: 1)
    var homeFrac: Double = 0.40       // home height as a fraction of the screen (候選 33: 0.46)
    var inkVar: Double = 0            // outline width follows compression, 1.3× squashed, 0.8× stretched (候選 34)
    var pressSharp: Double = 0.2      // sharpness of the press tap (提案第 15 條)
    var hapSharpSquash: Double = 0    // sharpness taken away while squashing (候選 15: 0.05)
    var popViaHaptics: Double = 0     // 1: the release pop plays as a Core Haptics audio event in the taps' pattern (候選 17)
    // 2026-11-01 多米真機回報 (build 46): idle wriggle looked like one shape swaying; clay sprang straight back and kept no mark
    var morph: Double = 1             // 1: idle outline follows smooth noise (modes 2–5 plus two roaming bumps), never repeats; 0 = v2.7 travelling waves
    var tentMem: Double = 0           // tentacles remember like the body and relax at `recover`; 0 = v2.7 (tips barely remember, spring back in ~1 s)
    // v2.9 (多米 second device report, build 48): not a starfish. No fixed tentacles; pseudopods grow, hold and retract anywhere
    // (the top too); a regular jellyfish pulse; free sculpting, pulled long and spread flat like dough
    var limbs: Double = 0             // fixed tentacles (5 = the old starfish shape; changing it rebuilds the body)
    var pods: Double = 2              // pseudopods growing at once while untouched; 0 = off
    var podLen: Double = 0.6          // pseudopod length at full extension, in radii (each one 0.7 to 1.2× of it; 1.1 in v2.10)
    var idlePace: Double = 0.45       // pace of the idle morph and the pseudopods (1 = v2.9 web, which 多米 found too fast)
    var bodySize: Double = 0.22       // body radius as a fraction of the screen width (0.26 before; changing it rebuilds the body)
    var jelly: Double = 1             // 1: jellyfish pulse (fast contraction, slow relax, a lift on each contraction); 0: the plain breathing
    var jellyT: Double = 3            // jellyfish pulse period, seconds
    var jellyAmp: Double = 0.06       // how much narrower at full contraction (taller by 0.85 of it; 0.1 in v2.10)
    var jellyLift: Double = 0.08      // lift per contraction, in radii; sinks back with a 1 s time constant (0.12 in v2.10)
    var nearMem: Double = 0           // near the fingers the body remembers in the whole-body frame (clay 1: a pulled-out lump stays)
    var memMax: Double = 1.1          // how far the remembered shape may move from the original, in radii (clay 4)
    var grabHold: Double = 0          // how much less the grabbed patch listens to shape matching (clay 0.85: it follows the finger)
    // v2.11 (多米 build 53): smaller self-driven deformation; grab the middle of a pulled strand and pull again; no crossing;
    // press it flat
    var grabK: Double = 0.55          // how far the grabbed patch moves to the finger per substep (× its weight); clay 1.2
    var nearR: Double = 1.58          // radius of the whole-body-frame memory around the fingers, in radii; clay 3 = the whole lump
    var ringGuard: Double = 1         // 1: a boundary particle may not pass through another boundary segment
    var pressFlat: Double = 0         // 1: pressing down from the upper half flattens it on an invisible table (clay)
    var flatMin: Double = 0.3         // flattest, as a fraction of the height when the press began
    // v2.12 (多米 build 55: pulled a little bigger and it would not go further; measured: the screen edge, right 1.1R, up 1.8R)
    var zoomMin: Double = 0           // the view zooms out to fit a big shape, down to this; 0 = no limit and no walls (v2.13, 多米), 1 = off, v2.12 was 0.45
    // v2.13 (多米: zoom out without limit, as far as the slime is pulled)
    var camFill: Double = 0.7         // while grabbed the shape fills at most this much of the view, leaving room for the finger; 1 = tight (v2.12)
    var camCenter: Double = 1         // 1: once big or pulled the view centres on the shape, so there is room ahead of the finger to pull again
                                      // (v2.15 default; in v2.13 it ran to 15R because the resting finger was dragged out by the view); 0: on home
    // v2.14 (多米 build 59: only the edge could be pulled; nothing happened pulling from the middle)
    var grabReach: Double = 1         // 1: grabbed from inside out of reach of the boundary, a strip to the boundary is added once the finger moves
    // v2.15 (多米 build 61: a tap should leave something, maybe a dent)
    var dent: Double = 1              // 1: a press leaves a dent (a crescent of shade upper-left), fading at the relax rate
    var dentSize: Double = 0.3        // dent radius, in radii
    // v2.16 (多米: the press looked like a toy). Defaults are clay; jelly and mochi set theirs in `defaults`
    var press2: Double = 1            // 1: the whole body thins and spreads, the dent bends with the body, fast then slow sinking,
                                      // a material rebound on release, the highlight squeezed aside, a deeper shadow; 0: v2.15 crescent
    var pressArea: Double = 0.06      // fully pressed, the body's area grows this much (pressed from the front it gets thinner, so wider)
    var pressSpread: Double = 0.10    // around the finger the body is pushed out this much (in radii, most at 0.3R from the finger)
    var pressSink: Double = 0.8       // 60% in the first 40 ms, the rest takes this long (s)
    var pressBounce: Double = 1       // release damping: 1 no rebound (clay), lower rebounds more (jelly 0.3)
    // v2.17 (多米: when the app opens it comes hopping over from far away; the camera should not pin it to the middle: it moves,
    // sometimes off screen, and the camera follows slowly)
    var intro: Double = 1             // 1: four hops in from far away on a cold start (about 2.8 s), a touch on the way brings it home at once
    var camFollow: Double = 1         // 1: the camera follows once it walks off-centre, it may leave the screen; still while grabbed. 0: v2.16
    var followZone: Double = 0.5      // how far from the centre (1 = half the view) before the camera starts to follow
    var followSpeed: Double = 1.4     // follow spring (rad/s), critically damped; 1.4 catches up in about 2 s
    var dash: Double = 0.25           // chance a wander walks far and fast (2.5× speed); the camera lags and it leaves the screen a bit
    var specks: Double = 1            // 1: faint fixed specks far behind (parallax 0.55) so a moving camera reads as moving
    var dens: Double = 12             // particles per radius (v2.12 and before: 9); at 8R the boundary was too sparse and the tail folded
                                      // across (measured: crossings on every hold at 9, 1 frame in 4 holds at 12); about 1.7× the particles
    // sound
    var volMaster: Double = 0.9       // output volume
    var rubMax: Double = 0.7          // loudest the rub loop gets
    var pitchJitter: Double = 0.08    // random pitch ±
    var sndPullMax: Double = 0.6      // loudest the stretching-strand loop gets (v2 layered sound)
    var sndSettle: Double = 1         // after-release tail: bubbles after a pull, a small hiss after a long press; 0 = off
    var sndPressSize: Double = 0.5    // how much contact size (majorRadius) changes the press sound; 0 = off
}

struct SlimeColors {
    var base: UIColor
    var shade: UIColor
    var line: UIColor
    var light: UIColor
}

enum SlimeMaterial: String, CaseIterable, Identifiable {
    case jelly, mochi, clay

    var id: String { rawValue }

    var name: String {
        switch self {
        case .jelly: return "果凍"
        case .mochi: return "麻糬"
        case .clay: return "黏土"
        }
    }

    /// Same numbers as the prototype's PRESETS (2026-10-31, v2.2; press and dwell added 2026-11-01, v2.3;
    /// wriggle, clay memory and tentMem changed after 多米's device report on build 46, the old values are `v27`).
    var defaults: FeelParams {
        var p: FeelParams
        switch self {
        case .jelly:
            p = FeelParams(alpha: 0.34, damp: 0.986, yield: 1.5, creep: 0, recover: 1, grabR: 0.36, maxPull: 1.6,
                           lag: 0.05, wGlobal: 0.12, cSpace: 0.3, cRad: 0.42, upright: 0.004, anchor: 4,
                           areaGain: 0.6, gripRot: 3, life: 1, drift: 0.16, wriggle: 0.05, wander: 0.25,
                           floppy: 0.5, seed: 7)
            p.pressArea = 0.04; p.pressSpread = 0.06; p.pressSink = 0.2; p.pressBounce = 0.3   // v2.16
        case .mochi:
            p = FeelParams(alpha: 0.28, damp: 0.966, yield: 0.14, creep: 0.9, recover: 0.18, grabR: 0.32, maxPull: 1.8,
                           lag: 0.08, wGlobal: 0.10, cSpace: 0.3, cRad: 0.45, upright: 0.004, anchor: 4,
                           areaGain: 0.6, gripRot: 3, life: 1, drift: 0.16, wriggle: 0.05, wander: 0.25,
                           floppy: 0.55, seed: 7)
            p.pressArea = 0.05; p.pressSpread = 0.08; p.pressSink = 0.45; p.pressBounce = 0.6   // v2.16
        case .clay:
            // clay remembers at once, tentacles too; the mark relaxes slowly: half in about 15 s (v2.14, 多米 build 59: it sprang back
            // too fast; v2.8 to v2.13 recover 0.3, about 10 s)
            p = FeelParams(alpha: 0.40, damp: 0.940, yield: 0.05, creep: 6, recover: 0.05, grabR: 0.32, maxPull: 7,
                           lag: 0.12, wGlobal: 0.08, cSpace: 0.3, cRad: 0.45, upright: 0.002, anchor: 4,
                           areaGain: 0.5, gripRot: 3, life: 0.8, drift: 0.14, wriggle: 0.05, wander: 0.22,
                           floppy: 0.6, seed: 7)
            // free sculpting (多米 2026-11-01: pull it long, spread it flat like dough)
            p.dwellLo = 0; p.dwellHi = 0.1; p.tentMem = 1; p.nearMem = 1; p.memMax = 5; p.grabHold = 0.85   // v2.15: pull 7R, remember 5R (past about 8.5R long it shook; v2.13 20 and 12, v2.12 8 and 4)
            p.grabK = 1.2; p.nearR = 3   // pressFlat off since v2.12 (多米: take it out)
        }
        return p
    }

    /// v2.7 control (before the build 46 device report): the starfish shape with five tentacles, travelling-wave wriggle,
    /// plain breathing; clay elastic for 0.2 s, tips spring back, 33 s to forget
    func applyV27(_ p: inout FeelParams) {
        p.morph = 0; p.tentMem = 0
        p.camFollow = 0   // before v2.17 the view stayed at home and the wander kept to the middle
        p.limbs = 5; p.pods = 0; p.jelly = 0; p.idlePace = 1; p.bodySize = 0.26; p.zoomMin = 1; p.camFill = 1; p.dens = 9; p.nearMem = 0; p.memMax = 1.1; p.grabHold = 0; p.grabK = 0.55; p.pressFlat = 0
        switch self {
        case .jelly, .mochi: p.wriggle = 0.07
        case .clay: p.wriggle = 0.06; p.dwellLo = 0.2; p.dwellHi = 0.6; p.creep = 3; p.recover = 0.03; p.maxPull = 2.0
        }
    }

    var colors: SlimeColors {
        switch self {
        case .jelly:
            return SlimeColors(base: UIColor(hex: 0x7FE0C2), shade: UIColor(hex: 0x4FB99E),
                               line: UIColor(hex: 0x2B6E61), light: UIColor(hex: 0xE9FFF7))
        case .mochi:
            return SlimeColors(base: UIColor(hex: 0xC9B6FF), shade: UIColor(hex: 0x9E86E6),
                               line: UIColor(hex: 0x4E3C8F), light: UIColor(hex: 0xFAF6FF))
        case .clay:
            return SlimeColors(base: UIColor(hex: 0xFFD96B), shade: UIColor(hex: 0xF0B64A),
                               line: UIColor(hex: 0x8B5A20), light: UIColor(hex: 0xFFF6D6))
        }
    }
}

/// One second-batch candidate (手感精修提案): a named change applied on top of the current numbers.
/// Blind test, one at a time: 存 1 (control) → 套候選 → 存 2 → 切 1／切 2.
struct Candidate: Identifiable {
    let id: Int
    let name: String
    let hint: String
    let apply: (inout FeelParams, SlimeMaterial) -> Void

    static let batch2: [Candidate] = [
        Candidate(id: 6, name: "6 黏滯 0.03", hint: "黏放在身體上，手指不延遲") { p, _ in p.lag = 0.03 },
        Candidate(id: 12, name: "12 觸覺跟變化率", hint: "手停就靜，一動就震") { p, _ in p.hapStatic = 0.25; p.hapRate = 0.75 },
        Candidate(id: 13, name: "13 質地微震", hint: "手指每走 8 點一下") { p, _ in p.tickSpacing = 8 },
        Candidate(id: 14, name: "14 啵依材質", hint: "黏土一下、麻糬兩下、果凍三下") { p, m in
            switch m {
            case .clay: p.popCount = 1; p.popSharp = 0.3
            case .mochi: p.popCount = 2; p.popGap = 0.1; p.popDecay = 0.4; p.popSharp = 0.4
            case .jelly: p.popCount = 3; p.popGap = 0.09; p.popDecay = 0.5; p.popSharp = 0.5
            }
        },
        Candidate(id: 18, name: "18 關停留門檻（對照）", hint: "抓住就記形，輕按也留痕") { p, _ in p.dwellLo = 0; p.dwellHi = 0 },
        Candidate(id: 19, name: "19 碰到時凍住", hint: "活物感停住，不縮回標準姿勢") { p, _ in p.idleFreeze = 1 },
        Candidate(id: 2, name: "2 偶發特別回彈", hint: "每 8 次放手多晃一下") { p, _ in p.specialEvery = 8 },
        Candidate(id: 9, name: "9 接觸面積壓力", hint: "指腹壓得越扁攤得越開") { p, _ in p.pressRadiusGain = 1 },
        Candidate(id: 41, name: "41 對照：關橫檔", hint: "v2.4 以前：觸手被壓縮會對折") { p, _ in p.tentRung = 0; p.tentAxis = 0 },
        Candidate(id: 21, name: "21 回家慢", hint: "放手後半秒飄回去，不過衝") { p, _ in p.homeK = 0.003 },
        Candidate(id: 22, name: "22 放手餘韻", hint: "放手後 0.25 秒多晃一下") { p, _ in p.afterglow = 0.25 },
        Candidate(id: 23, name: "23 呼吸", hint: "6 秒一次、吸短吐長、被摸久變深") { p, _ in p.breathT = 6; p.breathShape = 1; p.breathDeep = 1 },
        Candidate(id: 15, name: "15 銳利度跟材質", hint: "黏土 0.2、麻糬 0.3、果凍 0.45；拉 +0.15、壓 −0.05") { p, m in
            switch m {
            case .clay: p.hapSharp = 0.2
            case .mochi: p.hapSharp = 0.3
            case .jelly: p.hapSharp = 0.45
            }
            p.hapSharpStretch = 0.15; p.hapSharpSquash = 0.05
        },
        Candidate(id: 17, name: "17 啵走觸覺管線", hint: "放手音由 Core Haptics 播，跟震動同一個 pattern；要有錄音檔，第一次套了要重開 app") { p, _ in p.popViaHaptics = 1 },
        Candidate(id: 25, name: "25 拉太遠滑脫", hint: "拉過上限 1.2 倍 0.12 秒就脫手") { p, _ in p.slip = 1 },
        Candidate(id: 26, name: "26 放手黏連", hint: "慢抬手多黏 0.1 秒") { p, _ in p.stick = 0.1 },
        Candidate(id: 27, name: "27 局部鼓", hint: "面積壓力集中在手指附近") { p, _ in p.localArea = 1 },
        Candidate(id: 33, name: "33 家 0.46H", hint: "身體的家往下 6%") { p, _ in p.homeFrac = 0.46 },
        Candidate(id: 34, name: "34 描邊粗細", hint: "被壓的邊變粗、被拉的變細") { p, _ in p.inkVar = 1 },
        Candidate(id: 212, name: "v2.12 對照（鏡頭最遠 0.45）", hint: "鏡頭最遠 0.45、牆在最遠鏡頭的邊、鏡頭貼邊、每個半徑 9 個點、從中間抓拉不動；黏土拉伸 8R、記形 4R、回原形 0.3") { p, m in
            p.zoomMin = 0.45; p.camFill = 1; p.camCenter = 0; p.dens = 9; p.grabReach = 0; p.dent = 0; p.camFollow = 0; if m == .clay { p.maxPull = 8; p.memMax = 4; p.recover = 0.3 } },
        Candidate(id: 216, name: "v2.16 對照（鏡頭釘在中間）", hint: "鏡頭不跟、整隻一定在畫面裡、遊走只在中間一小塊") { p, _ in p.camFollow = 0 },
        Candidate(id: 215, name: "v2.15 對照（月牙凹痕）", hint: "按壓只有那一小塊攤開、凹痕是左上一彎硬邊月牙、0.08 秒到底，放手不分材質一樣淡") { p, _ in p.press2 = 0 },
        Candidate(id: 270, name: "v2.7 對照（舊外形）", hint: "海星外形五條觸手、固定行進波蠕動、正弦呼吸、黏土輕捏回彈") { p, m in m.applyV27(&p) },
    ]
}

/// One tunable slider in the hidden panel (prototype's `F`).
struct TuneField: Identifiable {
    let key: WritableKeyPath<FeelParams, Double>
    let name: String
    let hint: String
    let range: ClosedRange<Double>
    let step: Double
    var section = "手感"
    var id: String { name }

    static let sections = ["手感", "按壓與記形", "活物感", "觸覺", "聲音", "外形"]

    static let all: [TuneField] = [
        TuneField(key: \.alpha, name: "回彈硬度", hint: "越大越快回去、越硬", range: 0.05...0.8, step: 0.01),
        TuneField(key: \.damp, name: "晃動阻尼", hint: "越小放手晃越久", range: 0.85...0.999, step: 0.001),
        TuneField(key: \.grabR, name: "抓取範圍（×半徑）", hint: "一指抓到多大一塊", range: 0.2...0.8, step: 0.01),
        TuneField(key: \.dent, name: "點一下留凹痕", hint: "1：按到身體就出現凹痕（左上一彎陰影），放手跟回原形同速淡掉；拉開 0.4R 以上算拉，凹痕收掉；0 關（v2.14）", range: 0...1, step: 1),
        TuneField(key: \.dentSize, name: "凹痕大小（×半徑）", hint: "凹痕最大半徑", range: 0.1...0.5, step: 0.01),
        TuneField(key: \.intro, name: "開場跑過來", hint: "1：冷啟動時從遠處一跳一跳跑過來（約 2.8 秒），途中碰一下就直接到家；0 關（v2.17）", range: 0...1, step: 1),
        TuneField(key: \.camFollow, name: "鏡頭跟著走", hint: "1：史萊姆走離中心就慢慢跟過去，它可以跑出畫面；抓著時鏡頭不動。0 是 v2.16（鏡頭釘在家）", range: 0...1, step: 1),
        TuneField(key: \.followZone, name: "鏡頭開始追（×半個畫面）", hint: "史萊姆中心離畫面中心多遠鏡頭才開始追", range: 0.1...1, step: 0.05),
        TuneField(key: \.followSpeed, name: "鏡頭追的快慢", hint: "彈簧頻率（每秒弧度）；1.4 約 2 秒追上，越大越緊", range: 0.4...5, step: 0.1),
        TuneField(key: \.dash, name: "走遠的機率", hint: "每次遊走有多少機率走遠、走快（2.5 倍速），鏡頭跟不上就會跑出畫面一點", range: 0...1, step: 0.05),
        TuneField(key: \.specks, name: "背景光點", hint: "1：遠處固定的淡光點，鏡頭動的時候看得出來", range: 0...1, step: 1),
        TuneField(key: \.press2, name: "按壓真實版", hint: "1：v2.16 按壓（整團壓薄攤開、凹痕跟著身體變形、先快後慢地沉、放手依材質回彈、亮光被擠開、影子變深）；0 是 v2.15 的月牙凹痕", range: 0...1, step: 1),
        TuneField(key: \.pressArea, name: "壓薄攤開：面積", hint: "按到底時整團面積多幾成（從正面按下去前後變薄，看起來變大一圈）", range: 0...0.15, step: 0.01),
        TuneField(key: \.pressSpread, name: "壓薄攤開：手指附近（×半徑）", hint: "手指周圍那圈往外推多少（離手指約 0.3R 推最多）", range: 0...0.3, step: 0.01),
        TuneField(key: \.pressSink, name: "下沉時間（秒）", hint: "40 毫秒先到六成，剩下的多久沉到底；黏土 0.8、果凍 0.2", range: 0.05...2, step: 0.05),
        TuneField(key: \.pressBounce, name: "放手回彈阻尼", hint: "1 不彈（黏土）；越小放手彈越多下（果凍 0.3）", range: 0.1...1, step: 0.05),
        TuneField(key: \.grabReach, name: "從中間抓也拉得動", hint: "1：從身體裡面抓、範圍碰不到外圈時，手指一動往拉的方向補抓一條到外圈；0 是 v2.13（從中間拉沒反應）", range: 0...1, step: 1),
        TuneField(key: \.maxPull, name: "拉伸上限（×半徑）", hint: "最多拉多遠（軟上限）；黏土 7（v2.15，超過約 8.5R 會抖），v2.13 是 20，v2.12 是 8", range: 0.6...30, step: 0.1),
        TuneField(key: \.lag, name: "黏滯", hint: "跟手的延遲感（秒）；候選 6 是 0.03", range: 0...0.3, step: 0.01),
        TuneField(key: \.wGlobal, name: "整體性", hint: "越大整團越像一塊", range: 0...1, step: 0.01),
        TuneField(key: \.cSpace, name: "區塊間距（×半徑）", hint: "越小區塊越多越軟", range: 0.15...0.7, step: 0.05),
        TuneField(key: \.cRad, name: "區塊半徑（×半徑）", hint: "越小越軟、越容易拉出一塊", range: 0.25...1, step: 0.01),
        TuneField(key: \.upright, name: "回正", hint: "放手後轉回頭朝上的速度", range: 0...0.02, step: 0.001),
        TuneField(key: \.anchor, name: "抓著時的定身", hint: "越大身體越不會整團跟著手走、轉掉", range: 1...8, step: 0.5),
        TuneField(key: \.areaGain, name: "面積壓力", hint: "壓扁時旁邊鼓出來的程度", range: 0...1.5, step: 0.05),
        TuneField(key: \.gripRot, name: "抓著時不轉", hint: "越大拉它時身體越不會歪掉", range: 1...8, step: 0.5),
        TuneField(key: \.tentRung, name: "觸手橫檔", hint: "兩邊成對的粒子不能翻到對面、寬度不低於靜止的幾成；0 關＝v2.4 以前（第 41 條）", range: 0...0.9, step: 0.05),
        TuneField(key: \.tentAxis, name: "觸手中軸不折返", hint: "中軸每一節在上一節方向上至少前進靜止節距的幾成；0 關（第 41 條）", range: 0...1, step: 0.05),
        TuneField(key: \.homeK, name: "回家彈簧", hint: "放手後身體飄回家的彈簧（每小步）；0.02 原本，候選 21 是 0.003", range: 0.002...0.04, step: 0.001),
        TuneField(key: \.afterglow, name: "放手餘韻（秒）", hint: "放手後幾秒內阻尼從 0.975 回到設定值，多晃一下；0 關，候選 22 是 0.25", range: 0...0.6, step: 0.05),
        TuneField(key: \.pinchSquish, name: "兩指捏 squish", hint: "1：兩指靠近到起始距離 60% 發一次，之後每再縮 15% 一次（第 24 條）", range: 0...1, step: 1),
        TuneField(key: \.slip, name: "拉太遠滑脫", hint: "1：拉超過上限 1.2 倍持續 0.12 秒就脫手（候選 25）", range: 0...1, step: 1),
        TuneField(key: \.stick, name: "放手黏連（秒）", hint: "慢抬手時抓取多保持幾秒；0 關，候選 26 是 0.1", range: 0...0.2, step: 0.02),
        TuneField(key: \.localArea, name: "局部面積壓力", hint: "面積壓力往手指附近集中的程度；0 全身平均，候選 27 是 1", range: 0...2, step: 0.1),

        TuneField(key: \.pressBase, name: "按壓攤開（×半徑）", hint: "按下去那塊往四周攤多少（看得到的約一半）", range: 0...0.3, step: 0.01, section: "按壓與記形"),
        TuneField(key: \.pressHold, name: "按住再攤（×半徑）", hint: "按住不動時再多攤多少", range: 0...0.3, step: 0.01, section: "按壓與記形"),
        TuneField(key: \.pressHoldTime, name: "按壓下沉時間", hint: "按住多久攤到最深（秒）", range: 0.1...2, step: 0.05, section: "按壓與記形"),
        TuneField(key: \.pressRise, name: "按壓時間常數", hint: "攤開多快到位（秒）", range: 0.01...0.3, step: 0.01, section: "按壓與記形"),
        TuneField(key: \.pressFirst, name: "按壓第一幀比例", hint: "按下那一幀先到目標的幾成", range: 0...1, step: 0.05, section: "按壓與記形"),
        TuneField(key: \.pressRadiusGain, name: "接觸面積壓力", hint: "指腹壓扁（majorRadius 變大）再多攤多少；0 關，候選 9 是 1", range: 0...3, step: 0.1, section: "按壓與記形"),
        TuneField(key: \.yield, name: "定型門檻（×半徑）", hint: "變形超過這個才開始留形", range: 0.02...1.5, step: 0.01, section: "按壓與記形"),
        TuneField(key: \.creep, name: "定型速度", hint: "揉多快記住新形狀", range: 0...6, step: 0.1, section: "按壓與記形"),
        TuneField(key: \.dwellLo, name: "定型停留起點", hint: "抓住幾秒後開始記形（秒）", range: 0...1, step: 0.05, section: "按壓與記形"),
        TuneField(key: \.dwellHi, name: "定型停留終點", hint: "抓住幾秒後全速記形（秒）", range: 0...2, step: 0.05, section: "按壓與記形"),
        TuneField(key: \.recover, name: "回原形速度", hint: "放著多快變回原樣；黏土 0.05（v2.14，放手 2 秒退一成、15 秒退一半），v2.8 到 v2.13 是 0.3，v2.7 是 0.03", range: 0...1.5, step: 0.01, section: "按壓與記形"),
        TuneField(key: \.grabK, name: "抓住的力道", hint: "被抓那塊每小步往手指靠幾成（再乘距離權重）；以前 0.55，黏土 1.2 整塊跟手", range: 0.2...2, step: 0.05, section: "按壓與記形"),
        TuneField(key: \.nearR, name: "記形範圍（×半徑）", hint: "手指附近多大範圍用整身座標記形；黏土 3＝整團，拉出來的整條都記住", range: 0.5...4, step: 0.1, section: "按壓與記形"),
        TuneField(key: \.pressFlat, name: "一壓就攤平", hint: "1：從上半部往下壓時下面有看不見的桌面，壓多少扁多少；v2.12 起預設關", range: 0...1, step: 1, section: "按壓與記形"),
        TuneField(key: \.zoomMin, name: "鏡頭最遠", hint: "形狀變大時畫面自動縮小，最小縮到幾倍；0 不限制、也沒有牆（多米：鏡頭無限拉遠），1 關，v2.12 是 0.45", range: 0...1, step: 0.05, section: "按壓與記形"),
        TuneField(key: \.camFill, name: "鏡頭留邊", hint: "抓著時形狀最多佔畫面幾成就開始退；1 貼邊（v2.12），越小留越多邊給手指繼續拉；沒碰時都貼邊", range: 0.3...1, step: 0.05, section: "按壓與記形"),
        TuneField(key: \.camCenter, name: "鏡頭對準形狀", hint: "1：形狀大到要縮鏡頭、或抓著拉開時，鏡頭對準形狀中心，兩邊都留邊，再抓那一端還有地方拉（v2.15 預設）；0 對準家", range: 0...1, step: 1, section: "按壓與記形"),
        TuneField(key: \.dens, name: "點的密度", hint: "每個半徑幾個點；12（v2.13），以前 9：拉到 8R 時外圈太疏、尾端交叉。越密越吃效能，改了會重建身體", range: 6...14, step: 1, section: "按壓與記形"),
        TuneField(key: \.flatMin, name: "最扁", hint: "壓到最扁是原本高度的幾成", range: 0.15...0.8, step: 0.05, section: "按壓與記形"),
        TuneField(key: \.ringGuard, name: "邊不能穿邊", hint: "1：邊界的點不能穿過另一段邊界（多米：交叉時像快壞掉）；0 關", range: 0...1, step: 1),
        TuneField(key: \.grabHold, name: "抓住跟手", hint: "被抓那塊不聽彈性、跟手指走的程度；黏土 0.85，0 是以前（落後手指約 1 個半徑）", range: 0...1, step: 0.05, section: "按壓與記形"),
        TuneField(key: \.nearMem, name: "手指附近記形", hint: "手指附近用整身座標記形，拉出一塊就留一塊；0 只用局部區塊", range: 0...1, step: 0.05, section: "按壓與記形"),
        TuneField(key: \.memMax, name: "記形上限（×半徑）", hint: "記住的形狀最多離原形多遠；黏土 5（v2.15，超過約 8.5R 會抖），v2.13 是 12，v2.12 是 4，以前 1.1", range: 0.5...20, step: 0.1, section: "按壓與記形"),
        TuneField(key: \.tentMem, name: "觸手記形", hint: "1：觸手跟身體一樣留形、一樣慢慢回；0：v2.7 尖端一秒多彈回", range: 0...1, step: 0.05, section: "按壓與記形"),

        TuneField(key: \.life, name: "活物感", hint: "沒碰時自己動的幅度", range: 0...1.5, step: 0.05, section: "活物感"),
        TuneField(key: \.drift, name: "觸手飄動", hint: "沒碰時觸手擺動的幅度（×半徑）", range: 0...0.4, step: 0.01, section: "活物感"),
        TuneField(key: \.wriggle, name: "蠕動", hint: "沒碰時整個身體輪廓慢慢變形的幅度（×半徑）", range: 0...0.3, step: 0.01, section: "活物感"),
        TuneField(key: \.idlePace, name: "自己動的速度", hint: "偽足伸縮與蠕動的快慢；1 是 v2.9 網頁版（多米：太快）", range: 0.1...1.5, step: 0.05, section: "活物感"),
        TuneField(key: \.pods, name: "偽足數量", hint: "沒碰時同一時間最多幾條在伸縮，隨機方向、上方也會長；0 關", range: 0...3, step: 1, section: "活物感"),
        TuneField(key: \.podLen, name: "偽足長度（×半徑）", hint: "伸到最長多長（每條再隨機 0.7 到 1.2 倍）", range: 0...1.4, step: 0.05, section: "活物感"),
        TuneField(key: \.jelly, name: "水母呼吸", hint: "1：規律一縮一放，收縮快放鬆慢、收縮時上浮；0：原本的呼吸", range: 0...1, step: 1, section: "活物感"),
        TuneField(key: \.jellyT, name: "水母呼吸週期（秒）", hint: "一縮一放幾秒", range: 1.5...6, step: 0.1, section: "活物感"),
        TuneField(key: \.jellyAmp, name: "水母收縮幅度", hint: "收縮時變窄幾成（同時變高八成五）", range: 0...0.25, step: 0.01, section: "活物感"),
        TuneField(key: \.jellyLift, name: "水母上浮（×半徑）", hint: "每次收縮往上浮多少，放鬆時慢慢沉回", range: 0...0.3, step: 0.01, section: "活物感"),
        TuneField(key: \.morph, name: "蠕動不重複", hint: "1：輪廓與觸手跟著平滑亂數變，形狀一直在換；0：v2.7 固定行進波", range: 0...1, step: 1, section: "活物感"),
        TuneField(key: \.wander, name: "遊走", hint: "沒碰時在畫面裡移動的速度（×半徑／秒）", range: 0...1, step: 0.05, section: "活物感"),
        TuneField(key: \.tail, name: "遊走拖尾（×半徑）", hint: "遊走時觸手往移動反方向拖的量，照速度自己淡入淡出；0 關（第 20 條）", range: 0...0.4, step: 0.02, section: "活物感"),
        TuneField(key: \.floppy, name: "觸手軟度", hint: "越大觸手末端越軟、越會甩", range: 0...0.9, step: 0.05, section: "活物感"),
        TuneField(key: \.idleFreeze, name: "碰到時凍住", hint: "1：活物感時鐘停住不歸零（候選 19）", range: 0...1, step: 1, section: "活物感"),
        TuneField(key: \.specialEvery, name: "特別回彈", hint: "每幾次放手來一次特別 Q 的回彈，0 關（候選 2 是 8）", range: 0...12, step: 1, section: "活物感"),
        TuneField(key: \.breathT, name: "呼吸週期（秒）", hint: "一次呼吸幾秒；原本 3.8，候選 23a 是 6", range: 2...8, step: 0.1, section: "活物感"),
        TuneField(key: \.breathShape, name: "呼吸不對稱", hint: "1：吸 40%、吐 55%、停 5%；0 正弦（候選 23b）", range: 0...1, step: 1, section: "活物感"),
        TuneField(key: \.breathDeep, name: "被摸久呼吸變深", hint: "1：連續抓超過 10 秒，放手後 20 秒內振幅 ×1.5、週期 ×1.2 再衰減（候選 23c）", range: 0...1, step: 1, section: "活物感"),

        TuneField(key: \.hapMax, name: "連續觸覺上限", hint: "捏的時候最多震多強", range: 0...1, step: 0.05, section: "觸覺"),
        TuneField(key: \.hapStatic, name: "連續觸覺：變形量比重", hint: "拉著不動也震的那部分", range: 0...1, step: 0.05, section: "觸覺"),
        TuneField(key: \.hapRate, name: "連續觸覺：變化率比重", hint: "正在變才震的那部分（候選 12：0.75，變形量 0.25）", range: 0...1, step: 0.05, section: "觸覺"),
        TuneField(key: \.hapRateNorm, name: "變化率多少算滿", hint: "每秒變形量變化多少算 1", range: 0.5...6, step: 0.1, section: "觸覺"),
        TuneField(key: \.hapSharp, name: "連續觸覺銳利度", hint: "偏悶還是偏脆", range: 0...1, step: 0.05, section: "觸覺"),
        TuneField(key: \.hapSharpStretch, name: "拉伸銳利度加成", hint: "拉長時銳利度多加多少（第三批 15）", range: 0...0.5, step: 0.05, section: "觸覺"),
        TuneField(key: \.popMin, name: "啵最輕", hint: "輕輕放手那一下", range: 0...1, step: 0.05, section: "觸覺"),
        TuneField(key: \.popMax, name: "啵最重", hint: "用力甩或拉到底放手那一下", range: 0...1, step: 0.05, section: "觸覺"),
        TuneField(key: \.popSharp, name: "啵銳利度", hint: "候選 14：黏土 0.3", range: 0...1, step: 0.05, section: "觸覺"),
        TuneField(key: \.popCount, name: "啵幾下", hint: "候選 14：黏土 1、麻糬 2、果凍 3", range: 1...4, step: 1, section: "觸覺"),
        TuneField(key: \.popGap, name: "啵的間隔", hint: "幾下之間隔幾秒", range: 0.03...0.3, step: 0.01, section: "觸覺"),
        TuneField(key: \.popDecay, name: "啵的衰減", hint: "每下是前一下的幾成", range: 0.1...1, step: 0.05, section: "觸覺"),
        TuneField(key: \.tickSpacing, name: "質地微震間距", hint: "手指每走幾點一下；0 關，候選 13 是 8", range: 0...30, step: 1, section: "觸覺"),
        TuneField(key: \.tickMin, name: "微震最輕", hint: "手慢時", range: 0...0.6, step: 0.02, section: "觸覺"),
        TuneField(key: \.tickMax, name: "微震最重", hint: "手快時（每秒 3 個半徑）", range: 0...0.8, step: 0.02, section: "觸覺"),
        TuneField(key: \.tickSharp, name: "微震銳利度", hint: "顆粒偏鈍還是偏脆", range: 0...1, step: 0.05, section: "觸覺"),
        TuneField(key: \.pressSharp, name: "按下銳利度", hint: "手指碰到那一下的銳利度（第 15 條）", range: 0...1, step: 0.05, section: "觸覺"),
        TuneField(key: \.hapSharpSquash, name: "壓扁銳利度減少", hint: "按壓攤開時銳利度減多少（候選 15 是 0.05）", range: 0...0.3, step: 0.01, section: "觸覺"),
        TuneField(key: \.popViaHaptics, name: "啵走觸覺管線", hint: "1：放手音由 Core Haptics 播，跟震動同一個 pattern；要有錄音檔，第一次套了要重開 app（候選 17）", range: 0...1, step: 1, section: "觸覺"),

        TuneField(key: \.volMaster, name: "主音量", hint: "所有聲音一起", range: 0...1, step: 0.05, section: "聲音"),
        TuneField(key: \.rubMax, name: "揉的音量上限", hint: "揉最快時多大聲", range: 0...1, step: 0.05, section: "聲音"),
        TuneField(key: \.pitchJitter, name: "音高抖動", hint: "每次隨機差多少", range: 0...0.3, step: 0.01, section: "聲音"),
        TuneField(key: \.sndPullMax, name: "拉絲音量上限", hint: "拉的時候連續黏絲聲最大多大聲；拉越快越大聲、停住幾乎沒聲", range: 0...1, step: 0.05, section: "聲音"),
        TuneField(key: \.sndSettle, name: "放手餘韻", hint: "拉過放手冒小氣泡、按久放手一聲小嘶的音量；0 關", range: 0...2, step: 0.1, section: "聲音"),
        TuneField(key: \.sndPressSize, name: "按的音量跟接觸面積", hint: "指尖輕、指腹重的差多少；0 關", range: 0...1, step: 0.05, section: "聲音"),

        TuneField(key: \.seed, name: "外形亂數種子", hint: "換一個數字就換一個形狀（會重置）", range: 1...30, step: 1, section: "外形"),
        TuneField(key: \.bodySize, name: "身體大小", hint: "半徑是畫面寬的幾成（會重置）；以前 0.26，0.22 留空間拉長、攤平", range: 0.15...0.3, step: 0.01, section: "外形"),
        TuneField(key: \.limbs, name: "固定觸手數", hint: "0：沒有固定觸手的一團；5：以前的海星外形（會重置）", range: 0...5, step: 1, section: "外形"),
        TuneField(key: \.homeFrac, name: "家的高度", hint: "身體的家在畫面高度的幾成；原本 0.40，候選 33 是 0.46", range: 0.3...0.55, step: 0.01, section: "外形"),
        TuneField(key: \.inkVar, name: "描邊粗細隨壓縮", hint: "1：被壓的邊描邊加粗到 1.3 倍、被拉的減到 0.8 倍；0 固定（候選 34）", range: 0...1, step: 0.1, section: "外形"),
    ]
}

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: alpha)
    }
}
