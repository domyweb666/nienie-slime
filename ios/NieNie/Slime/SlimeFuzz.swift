import Foundation

/// v2.52 A5 亂捏測試 on the phone (《虛擬手感》3-3 第 8、9、10 欄; 多米 11-22 交辦 A5). A port of `prototype/web/fuzz.js`:
/// fixed seeds make a few dozen runs of random pulls, two-finger pulls, scrubs, stirs and zig-zags, and every frame it measures "broken":
/// triangles turned over, the longest mesh edge, how much the body jumps while the finger holds still, the sharpest corner left after
/// letting go. v2.52 adds what the web's fuzz.js got at the same time: how often each guard acted, and the physics alone in ms a frame.
///
/// It runs on a rig of its own (the slime on screen is not touched, nothing the user stored is read or written), off the main thread,
/// at a fixed 1/60 s a frame whatever the display does. The rig's random draws are seeded, so a seed gives the same run on every build.
/// It catches "broken", not "good to squeeze" (CLAUDE.md: 程式自測只當回歸測試).
struct SlimeFuzz {
    /// One seed's run.
    struct Trial {
        var seed = 0
        var frames = 0, flipFrames = 0, flipMax = 0, memFlipMax = 0, crossFrames = 0, nan = 0
        var strainMax = 0.0, memStrainMax = 0.0, jerkHold = 0.0, jerkHoldMean = 0.0, sharpMax = 0.0
        var endSharp = 0.0
        var endSpikes = 0, endFlips = 0, endMemFlips = 0
        var endCrossed = false
        var guards = SlimeRig.GuardStats()
        var physMs = 0.0, physMsMax = 0.0
    }

    /// All seeds together, the same fields as the web's `__fz.sum`.
    struct Summary {
        var n = 0
        var flipTrials = 0, flipMaxAll = 0, memFlipTrials = 0, crossTrials = 0, endSpikeTrials = 0, endFlipTrials = 0, endCrossTrials = 0, nan = 0
        var flipFramePct = 0.0, strainMax = 0.0, memStrainMax = 0.0, jerkHoldMax = 0.0, jerkHoldMeanAvg = 0.0, sharpMaxAll = 0.0, endSharpMax = 0.0
        var capHiPct = 0.0, capLoPct = 0.0, flipGuardPct = 0.0, givePct = 0.0, giveMax = 0.0, givePullMax = 0.0
        var physMs = 0.0, physMsMax = 0.0
        var seconds = 0.0

        /// Three lines for the panel and the export (plain words first, the numbers after).
        var text: String {
            guard n > 0 else { return "亂捏測試還沒跑過。" }
            func f(_ v: Double, _ d: Int = 1) -> String { String(format: "%.\(d)f", v) }
            return "亂捏 \(n) 組（\(f(seconds, 0)) 秒）：有翻面的格 \(f(flipFramePct))%、同時最多翻 \(flipMaxAll) 個；一小段最長拉到 \(f(strainMax)) 倍；按住不動每格跳 平均 \(f(jerkHoldMeanAvg, 2))、最大 \(f(jerkHoldMax)) 點\n"
                + "放手兩秒後：最尖 \(f(endSharpMax, 0)) 度、留尖角 \(endSpikeTrials) 組、留翻面 \(endFlipTrials) 組、外框交叉 \(endCrossTrials) 組、NaN \(nan)\n"
                + "保險作用的格：拉到上限 \(f(capHiPct))%、壓到下限 \(f(capLoPct))%、防翻面 \(f(flipGuardPct))%、手指讓 \(f(givePct))%；手指最多讓 \(f(giveMax, 2)) 個半徑、往外拉時 \(f(givePullMax, 2))｜物理每格 \(f(physMs, 2)) 毫秒、最長 \(f(physMsMax)) 毫秒"
        }
    }

    /// The web's `seeded` (mulberry32), so a seed draws the same gesture script as fuzz.js.
    private struct Script {
        var a: UInt32
        mutating func next() -> Double {
            a = a &+ 0x6D2B_79F5
            var t = a
            t = (t ^ (t >> 15)) &* (t | 1)
            t ^= t &+ ((t ^ (t >> 7)) &* (t | 61))
            return Double(t ^ (t >> 14)) / 4_294_967_296
        }
    }
    private final class Token {}

    /// - Parameters:
    ///   - seeds: the web's default is 1000...1039; the handoff's "30 組" is 1000...1029
    ///   - params: the numbers to test (the desk's current ones); the body is rebuilt from them for every seed
    ///   - progress: called after each seed (on the calling thread); return false to stop early
    static func run(seeds: [Int], params: FeelParams, width: Double, height: Double,
                    progress: ((_ done: Int, _ total: Int) -> Bool)? = nil) -> (summary: Summary, trials: [Trial]) {
        let t0 = ProcessInfo.processInfo.systemUptime
        var out: [Trial] = []
        for (k, seed) in seeds.enumerated() {
            out.append(trial(seed: seed, params: params, width: width, height: height))
            if let p = progress, !p(k + 1, seeds.count) { break }
        }
        var s = summarize(out)
        s.seconds = ProcessInfo.processInfo.systemUptime - t0
        return (s, out)
    }

    static func summarize(_ out: [Trial]) -> Summary {
        var s = Summary()
        s.n = out.count
        guard !out.isEmpty else { return s }
        let n = Double(out.count)
        var frames = 0, flipFrames = 0
        for o in out {
            frames += o.frames; flipFrames += o.flipFrames
            if o.flipMax > 0 { s.flipTrials += 1 }
            if o.memFlipMax > 0 { s.memFlipTrials += 1 }
            if o.crossFrames > 0 { s.crossTrials += 1 }
            if o.endSpikes > 0 { s.endSpikeTrials += 1 }
            if o.endFlips > 0 || o.endMemFlips > 0 { s.endFlipTrials += 1 }
            if o.endCrossed { s.endCrossTrials += 1 }
            s.flipMaxAll = max(s.flipMaxAll, o.flipMax); s.nan = max(s.nan, o.nan)
            s.strainMax = max(s.strainMax, o.strainMax); s.memStrainMax = max(s.memStrainMax, o.memStrainMax)
            s.jerkHoldMax = max(s.jerkHoldMax, o.jerkHold); s.jerkHoldMeanAvg += o.jerkHoldMean / n
            s.sharpMaxAll = max(s.sharpMaxAll, o.sharpMax); s.endSharpMax = max(s.endSharpMax, o.endSharp)
            let g = o.guards
            s.capHiPct += g.pct(g.hi) / n; s.capLoPct += g.pct(g.lo) / n; s.flipGuardPct += g.pct(g.flip) / n; s.givePct += g.pct(g.give) / n
            s.giveMax = max(s.giveMax, g.giveMax); s.givePullMax = max(s.givePullMax, g.givePull)
            s.physMs += o.physMs / n; s.physMsMax = max(s.physMsMax, o.physMsMax)
        }
        s.flipFramePct = frames > 0 ? 100 * Double(flipFrames) / Double(frames) : 0
        return s
    }

    static func trial(seed: Int, params: FeelParams, width W: Double, height H: Double) -> Trial {
        let DT = 1.0 / 60
        var rnd = Script(a: UInt32(truncatingIfNeeded: UInt64(seed) &* 2_654_435_761))
        let rig = SlimeRig(params: params)
        rig.labNoSave = true
        rig.seedRandom(UInt64(seed))
        rig.setup(width: W, height: H)
        var clock = 0.0
        for _ in 0..<90 { rig.update(DT); clock += DT }
        rig.guardReset()
        var M = Trial()
        M.seed = seed
        let R = rig.labRadius
        var vx: [Double]? = nil, vy: [Double] = []
        var still = 0, holdN = 0
        var msSum = 0.0
        let tokens = [Token(), Token()]   // touches are told apart by identity only; these two live for the whole trial
        let id1 = ObjectIdentifier(tokens[0]), id2 = ObjectIdentifier(tokens[1])
        var last: [ObjectIdentifier: (x: Double, y: Double)] = [:]

        func step(_ holding: Bool) {
            let p0 = rig.labParticles()
            let u0 = ProcessInfo.processInfo.systemUptime
            rig.update(DT)
            let ms: Double = (ProcessInfo.processInfo.systemUptime - u0) * 1000
            clock += DT
            msSum += ms; if ms > M.physMsMax { M.physMsMax = ms }
            M.frames += 1
            let sh = rig.labShape()
            if sh.flips > 0 { M.flipFrames += 1 }
            if sh.flips > M.flipMax { M.flipMax = sh.flips }
            if sh.memFlips > M.memFlipMax { M.memFlipMax = sh.memFlips }
            if M.frames % 2 == 0 && rig.labCrossed() { M.crossFrames += 1 }
            if sh.strain > M.strainMax { M.strainMax = sh.strain }
            if sh.memStrain > M.memStrainMax { M.memStrainMax = sh.memStrain }
            M.nan += sh.nan
            // how much it jumps while the finger holds still: the largest change of a particle's velocity, the whole body's travel taken off
            let p1 = rig.labParticles(), n = min(p0.x.count, p1.x.count)
            guard n > 0 else { return }
            var ax = 0.0, ay = 0.0
            for i in 0..<n { ax += p1.x[i] - p0.x[i]; ay += p1.y[i] - p0.y[i] }
            ax /= Double(n); ay /= Double(n)
            var nx = [Double](repeating: 0, count: n), ny = [Double](repeating: 0, count: n)
            var j = 0.0
            for i in 0..<n {
                nx[i] = p1.x[i] - p0.x[i] - ax; ny[i] = p1.y[i] - p0.y[i] - ay
                if let v = vx, v.count == n { let d: Double = hypot(nx[i] - v[i], ny[i] - vy[i]); if d > j { j = d } }
            }
            vx = nx; vy = ny
            still = holding ? still + 1 : 0
            if still > 40 { if j > M.jerkHold { M.jerkHold = j }; M.jerkHoldMean += j; holdN += 1 }
        }
        func clampS(_ x: Double, _ y: Double) -> (Double, Double) { (max(4, min(W - 4, x)), max(4, min(H - 4, y))) }
        func down(_ id: ObjectIdentifier, _ x: Double, _ y: Double) { last[id] = (x, y); rig.touchBegan(id, x: x, y: y, time: clock) }
        func move(_ id: ObjectIdentifier, _ x: Double, _ y: Double) {
            let p = last[id] ?? (x, y)
            last[id] = (x, y)
            rig.touchMoved(id, x: x, y: y, predictedX: nil, predictedY: nil, distance: hypot(x - p.x, y - p.y))
        }
        func up(_ id: ObjectIdentifier) { last[id] = nil; rig.touchEnded(id, time: clock) }
        /// A point inside the body, on a particle: where a finger lands
        func pick() -> (Double, Double) {
            let a: Double = rnd.next() * 6.283, rr: Double = rnd.next().squareRoot() * 0.95, c = rig.labCentre
            let tx: Double = c.x + cos(a) * R * rr, ty: Double = c.y + sin(a) * R * rr
            let p = rig.labParticles()
            var bi = 0, bd = 1e18
            for i in 0..<p.x.count { let d: Double = (p.x[i] - tx) * (p.x[i] - tx) + (p.y[i] - ty) * (p.y[i] - ty); if d < bd { bd = d; bi = i } }
            guard !p.x.isEmpty else { return (c.x, c.y) }
            let s = rig.toScreen(p.x[bi], p.y[bi])
            return (s.x, s.y)
        }
        @discardableResult
        func drag(_ id: ObjectIdentifier, _ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, _ n: Int) -> (Double, Double) {
            guard n > 0 else { return clampS(x1, y1) }
            for s in 1...n {
                let k: Double = Double(s) / Double(n), q = clampS(x0 + (x1 - x0) * k, y0 + (y1 - y0) * k)
                move(id, q.0, q.1); step(false)
            }
            return clampS(x1, y1)
        }

        let ng = 5 + Int(rnd.next() * 4)
        for _ in 0..<ng {
            let kind = Int(rnd.next() * 6), a: Double = rnd.next() * 6.283, dist: Double = (0.5 + rnd.next() * 3.5) * R
            let n = 4 + Int(rnd.next() * 36), hd = Int(rnd.next() * 100)
            let (sx, sy) = pick()
            if kind == 0 || kind == 1 {   // one finger: pull, hold, let go
                down(id1, sx, sy); for _ in 0..<4 { step(true) }
                drag(id1, sx, sy, sx + cos(a) * dist, sy + sin(a) * dist, n)
                for _ in 0..<hd { step(true) }
                up(id1)
            } else if kind == 2 {   // two fingers pulling apart
                let (tx, ty) = pick()
                down(id1, sx, sy); down(id2, tx, ty); for _ in 0..<4 { step(true) }
                let ex: Double = sx + cos(a) * dist * 0.6, ey: Double = sy + sin(a) * dist * 0.6, fx: Double = tx - cos(a) * dist * 0.6, fy: Double = ty - sin(a) * dist * 0.6
                for s in 1...n {
                    let k: Double = Double(s) / Double(n)
                    let e1 = clampS(sx + (ex - sx) * k, sy + (ey - sy) * k), e2 = clampS(tx + (fx - tx) * k, ty + (fy - ty) * k)
                    move(id1, e1.0, e1.1); move(id2, e2.0, e2.1); step(false)
                }
                for _ in 0..<hd { step(true) }
                up(id1); for _ in 0..<6 { step(false) }; up(id2)
            } else if kind == 3 {   // scrubbing back and forth
                down(id1, sx, sy); step(true)
                var px = sx, py = sy
                for k in 0..<6 {
                    let sg: Double = k % 2 == 1 ? -1 : 1
                    let bx: Double = sx + cos(a) * dist * 0.5 * sg + (rnd.next() - 0.5) * R * 0.6, by: Double = sy + sin(a) * dist * 0.5 * sg + (rnd.next() - 0.5) * R * 0.6
                    (px, py) = drag(id1, px, py, bx, by, 5 + Int(rnd.next() * 8))
                }
                up(id1)
            } else if kind == 4 {   // stirring in circles
                down(id1, sx, sy); step(true)
                let rr: Double = dist * 0.4, turns = 40 + Int(rnd.next() * 60)
                for k in 1...turns {
                    let th: Double = a + Double(k) * 0.35, p = clampS(sx + cos(th) * rr - cos(a) * rr, sy + sin(th) * rr - sin(a) * rr)
                    move(id1, p.0, p.1); step(false)
                }
                for _ in 0..<(hd / 2) { step(true) }
                up(id1)
            } else {   // out, back on itself, then off another way
                down(id1, sx, sy); for _ in 0..<3 { step(true) }
                var p = drag(id1, sx, sy, sx + cos(a) * dist, sy + sin(a) * dist, n)
                for _ in 0..<(hd / 3) { step(true) }
                let b: Double = a + 1.6 + rnd.next() * 3
                p = drag(id1, p.0, p.1, sx + cos(b) * dist, sy + sin(b) * dist, 6 + Int(rnd.next() * 20))
                for _ in 0..<hd { step(true) }
                up(id1)
            }
            let rest = 10 + Int(rnd.next() * 80)
            for _ in 0..<rest { step(false) }
            let sh = rig.labSharp()
            if sh.max > M.sharpMax { M.sharpMax = sh.max }
        }
        for _ in 0..<120 { step(false) }
        let sh = rig.labSharp(), end = rig.labShape()
        M.endSharp = sh.max; M.endSpikes = sh.spikes; M.endFlips = end.flips; M.endMemFlips = end.memFlips; M.endCrossed = rig.labCrossed()
        M.jerkHoldMean = holdN > 0 ? M.jerkHoldMean / Double(holdN) : 0
        rig.update(DT)   // fold the last frame's guard flags
        M.guards = rig.guardStats
        M.physMs = M.frames > 0 ? msSum / Double(M.frames) : 0
        return M
    }
}
