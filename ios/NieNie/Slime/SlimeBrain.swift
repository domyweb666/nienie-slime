import Foundation

/// v2.63 手機大腦第一片「需求和自己醒」(.uiux/04-手感/極致優化規劃-暫定.md C7; .uiux/04-手感/大腦提案-暫定.md).
/// Port of the web's BRAIN, brnd, brainReset, brainJit and the number parts of brainStep, brainPick, brainGoAfterLook (prototype/web/index.html, v2.41 to v2.61),
/// line by line: the same numbers, the same LCG for its own random draws (brnd), the same seconds.
/// Five needs, each 0...1: z 睏, q 好奇, s 想被摸, f 怕 (the wariness, plus how scared it is right now), e 想動. When it is done resting, the strongest one
/// decides what it does next; none above 0.35 and it rests on. Before sleeping it squints and sighs for 2 s, before coming to you it looks at you (前兆, brPre).
/// Each waking and each sleep draws its own pace (作息亂數, brJit). Asleep, the 睏 runs out and it wakes by itself.
/// Not in this slice (the phone treats them as off, the web's MDon(), MMon(), DRon() false): the mood (BRAIN.m, mS, ev, brainMood; slice 2, item 4),
/// the remembered places (BMEM), what it does with the decorations (DR, drCat, memOffer). With those off the web's formulas lose their mood and memory terms,
/// written below as 0 where the web has them, so the line-by-line check stays easy.
/// What touches the body (sleep, walk, look, go home) is in SlimeRig.swift (brainStep, brainRest, brainGo, brainGoHome); this file only keeps numbers.
/// Foundation only (the Linux check builds it with the physics files).
struct SlimeBrain {
    /// The web's B.pre.k: what it is about to do once the 前兆 is over
    enum Pre { case sleep, greet }
    /// The web's brainPick choices this slice can make ('offer' needs MMon, 'cat' needs DRon: both off on the phone, so they score −1 and never win)
    enum Choice: String { case rest, look, go, sleep, greet }

    // the needs (the web's BRAIN starting values; brainReset puts them back)
    var z = 0.3, q = 0.3, s = 0.0, f = 0.0, e = 0.4
    var pre: Pre?
    var preT0 = 0.0
    /// The web's B.want: what brainPick chose last ('' after e4Step took 'greet'); e4Step waits for "greet"
    var want = ""
    /// For a readout (the web's 「牠在想什麼」 brainHud; the phone has none yet): what it is doing, why it chose the last thing
    var act = "休息", why = ""
    var ex0 = 0.0, homeAt = 0.0
    /// brnd's state. The web starts it once at 20261114 when the page loads, brainReset leaves it, brainJit draws a new one
    var seed: UInt32 = 20_261_114
    var naps = 0, selfWake = 0
    /// v2.61 C7 (brJit): zAt how sleepy before it wants to sleep, jA how fast it gets sleepy this waking, jS how fast it sleeps it off this time;
    /// slp = asleep when they were last drawn; ojT = until when brainPick adds the opening's bigger random (OPENJ)
    var zAt = 0.5, jA = 1.0, jS = 1.0, slp = false, ojT = -9.0

    /// The web's BRJ (v2.61 C7): a the waking's sleepiness rate ×a0...a1 (log-uniform), s the sleep's ×s0...s1 (squared), z the sleepiness it sleeps at,
    /// e how much of the wish to move a waking keeps at least, q the most curiosity a waking brings, lie the most seconds it lies there after waking
    enum Jit {
        static let a0: Double = 0.3, a1: Double = 2.6, s0: Double = 0.45, s1: Double = 2.4, z0: Double = 0.4, z1: Double = 0.75, e0: Double = 0.5, q: Double = 0.6, lie: Double = 9
    }
    /// The web's BR_Q, BR_E, BR_GO, BR_REST: idle, curiosity fills in 30 s and the wish to move in 90 s; setting off uses up 0.5 of it; under 0.35 for all it rests
    enum K {
        static let q: Double = 30, e: Double = 90, go: Double = 0.5, rest: Double = 0.35
    }
    /// The web's OPENJ: for 40 s after an opening each choice gets ±0.4 of random instead of ±0.08
    enum OpenJ {
        static let s: Double = 40, n: Double = 0.8
    }
    /// The web's BR_NAMES (the ones this slice can choose)
    static func name(_ c: Choice) -> String {
        switch c {
        case .rest: return "休息"
        case .look: return "張望"
        case .go: return "走"
        case .sleep: return "睡覺"
        case .greet: return "來找你"
        }
    }

    /// brnd: the brain's own random numbers, so the order of the rig's other draws stays as it was (the web: Math.random untouched for the selftest's seeds).
    /// seed = seed·1664525 + 1013904223 mod 2³², the web's (Math.imul(seed,1664525)+1013904223)>>>0
    mutating func rnd() -> Double {
        seed = seed &* 1_664_525 &+ 1_013_904_223
        return Double(seed) / 4_294_967_296
    }

    /// brainReset: every opening (the rig's setup) and every slime starts from the same place, however long you were away. The seed and the counts stay
    mutating func reset(_ t: Double) {
        pre = nil; preT0 = 0
        z = 0.3; q = 0.3; s = 0; f = 0; e = 0.4
        want = ""; act = "休息"; why = ""; ex0 = 0; homeAt = t
        zAt = 0.5; jA = 1; jS = 1; slp = false; ojT = -9
    }

    /// brainJit (v2.61 C7, with greetLook): an opening (cold start, a slime switch, back after 10 min) starts four of the needs at random,
    /// and for OpenJ.s s each choice gets a bigger random: the first three things are not the same every time. The caller checks greetLook and the brain.
    /// The draws come from the rig's generator (the web's Math.random), in the web's order: seed, z, q, e, s.
    mutating func jit<G: RandomNumberGenerator>(_ t: Double, trust: Double, using g: inout G) {
        seed = UInt32(truncatingIfNeeded: g.next())   // the web's (Math.random()*4294967296)>>>0
        z = 0.15 + 0.3 * Double.random(in: 0..<1, using: &g)
        q = 0.05 + 0.65 * Double.random(in: 0..<1, using: &g)
        e = 0.15 + 0.7 * Double.random(in: 0..<1, using: &g)
        s = 0.4 * Double.random(in: 0..<1, using: &g) * trust
        ojT = t + OpenJ.s
    }

    /// What brainStep reads from the body and the clock this frame.
    struct In {
        var dt: Double
        var idleT: Double       // idleSec(): how long nobody has been there
        var restMul: Double     // the slime's personality (mat.restMul)
        var e4Mul: Double       // mat.e4Mul
        var night: Bool         // viewBg() === 'night'
        var exLevel: Double     // exLevel(): what it brought back from walks today
        var exert: Double       // BRX.exert: out of breath
        var comfort: Double     // MOOD.c
        var wary: Double        // IMP.w
        var scare: Double       // MOOD.scare
        var trust: Double       // IMP.tr
        var awakeT: Double      // mat.brAwakeT
        var sleepT: Double      // mat.brSleepT
        var engaged: Bool       // a finger is on it
        var asleep: Bool        // SLP.on
        var resting: Bool       // LIFE.st === 'rest'
        var jit: Bool           // mat.brJit >= .5
        var hidden: Bool        // document.hidden (the phone's rig does not step in the background: false)
    }

    /// brainStep from `const cl=` to the four clamps: the needs rise and fall. Returns, on a waking with brJit on, how long it may lie there first
    /// (the web's BRJ.lie*brnd()**2; the caller does LIFE.until = max(LIFE.until, t + 1.5 + that)). Mood off: mg and mb are 0 (the web's BRM() with MDon() false).
    mutating func step(_ i: In) -> Double? {
        func cl(_ v: Double) -> Double { max(0, min(1, v)) }
        let pz: Double = i.restMul != 0 ? i.restMul : 1   // mat.restMul||1
        let mg = 0.0, mb = 0.0   // brainMood, brainMem: slice 2 and 3
        f = cl(max(i.wary, i.scare) + 0.35 * mb)   // 心情差：容易怕
        if i.engaged { pre = nil }
        var lie: Double? = nil
        if !i.jit { zAt = 0.5; jA = 1; jS = 1; slp = i.asleep }
        else if slp != i.asleep {   // v2.61 C7: each round of the day drawn again; what it wants first on waking differs (now a look about, now lying there a while)
            slp = i.asleep
            if i.asleep { let r = rnd(); jS = Jit.s0 + (Jit.s1 - Jit.s0) * r * r }
            else {
                jA = Jit.a0 * pow(Jit.a1 / Jit.a0, rnd())
                zAt = Jit.z0 + (Jit.z1 - Jit.z0) * rnd()
                e *= Jit.e0 + (1 - Jit.e0) * rnd()
                q = max(q, Jit.q * rnd())
                let r = rnd(); lie = Jit.lie * r * r
            }
        }
        if i.asleep { z -= i.dt / i.sleepT * jS; e += i.dt / (i.jit ? 180 : 90) }   // asleep: the sleepiness goes, the strength comes back
        else {
            z += i.dt / i.awakeT * jA * pz * (i.idleT > 20 ? 2 : 1) * (i.night ? 1.5 : 1)
            if i.resting && !i.engaged { q += i.dt / K.q * (1 + 0.5 * mg); e += i.dt / (K.e * pz) * (1 + i.exLevel) * (1 + 0.5 * mg) }   // idle: more and more wanting something to do, wanting to move (faster on a day you walked a lot)
        }
        let ex = i.exert
        if ex > ex0 + 0.05 { z += 0.25 * (ex - ex0); e -= 0.3 * (ex - ex0) }   // out of breath (a run, fleeing, a hard pull): a little tired, less keen to move
        ex0 = ex
        if i.engaged { s -= i.dt / (i.comfort > 0.2 ? 4 : 10); q -= i.dt / 8 }   // touched: the wish to be stroked goes (a gentle rub faster), its attention is on your hand
        else if !i.asleep && !i.hidden { s += i.dt / 45 * i.trust / (i.e4Mul != 0 ? i.e4Mul : 1) }   // untouched: only a trusting one misses you; 芋圓 is shy, it hardly rises while it does not know you
        z = cl(z); q = cl(q); s = cl(s); e = cl(e)
        return lie
    }

    /// brainPick: rested long enough, each need scores (fear holds back sleeping, coming to you and going, and pushes looking about); the highest wins,
    /// none above K.rest and it rests on; close scores are split by a little random. The draws are only made for the choices that can be made, in the web's order
    /// (look, go, sleep, greet; offer and cat draw nothing while they cannot be chosen). sleepOK here is the web's `!opening&&sleepOK()&&idleT>8`.
    /// One row of brainPick's table: the choice, its score, the need's name and value for `why`
    struct Score { let k: Choice; let v: Double; let why: String; let n: Double }
    mutating func pick(t: Double, greetLook: Bool, canGo: Bool, sleepOK: Bool, e4OK: Bool) -> Choice {
        let na: Double = greetLook && t < ojT ? OpenJ.n : 0.16
        let calm = 1 - f, brm = 0.0   // BRM(): mood off
        var c: [Score] = [Score(k: .rest, v: K.rest, why: "都不高", n: 0)]
        do { let r = rnd(); c.append(Score(k: .look, v: q + 0.3 * f + (r - 0.5) * na, why: "好奇", n: q)) }
        if canGo { let r = rnd(); c.append(Score(k: .go, v: e * (1 - 0.5 * z) * (1 - 0.5 * f) * (1 + 0.3 * brm) + (r - 0.5) * na + 0, why: "想動", n: e)) }   // + 0: the scared cell (MMon), slice 3
        else { c.append(Score(k: .go, v: -1, why: "想動", n: e)) }
        if sleepOK && z > zAt { let r = rnd(); c.append(Score(k: .sleep, v: z * calm + (r - 0.5) * na, why: "睏", n: z)) } else { c.append(Score(k: .sleep, v: -1, why: "睏", n: z)) }
        if e4OK { let r = rnd(); c.append(Score(k: .greet, v: s * calm + (r - 0.5) * na, why: "想被摸", n: s)) } else { c.append(Score(k: .greet, v: -1, why: "想被摸", n: s)) }
        var b = c[0]
        for x in c where x.v > b.v { b = x }
        want = b.k.rawValue
        why = b.k == .rest ? "五個都不高，繼續休息" : b.why + " " + String(format: "%.2f", b.n) + " 最高，" + Self.name(b.k)
        return b.k
    }

    /// brainGoAfterLook: done looking about, does it go over there? By how much it wants to move (v2.40: 65% of the time)
    mutating func goAfterLook() -> Bool {
        let r = rnd()
        return e * (1 - 0.5 * z) * (1 - 0.5 * f) + (r - 0.5) * 0.16 > K.rest
    }
}
