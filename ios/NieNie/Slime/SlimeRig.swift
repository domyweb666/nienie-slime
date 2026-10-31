import Foundation

/// Things the rig asks the outside world to play. Picture, sound and haptics
/// all react to the same event in the same frame.
enum SlimeEvent {
    case press(gain: Double)                 // a finger landed on the body
    case pull(gain: Double, rate: Double)    // stretched past another step
    case release(gain: Double, rate: Double, special: Bool) // let go; gain follows release strength; special = 偶發特別回彈
    case tick(gain: Double)                  // texture tick while kneading (提案第 13 條)
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
    private var builtSeed = -1.0, builtFloppy = -1.0, builtSpace = -1.0, builtRad = -1.0
    private var relaxUntil = -1.0            // 揉回原形: until when the remembered shape eases back to the original
    private(set) var lastReleaseStrength = 0.0
    private var tLife = 0.0                                                // idle-life clock, runs only while untouched (提案第 19 條)
    private var releaseCount = 0, nextSpecial = 0, specialUntil = -1.0     // 偶發特別回彈 (提案第 2 條)

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
        var tickAt = 0.0, tickNext = 0.0             // texture ticks: travel at the last tick, spacing to the next (提案第 13 條)
        var step = 0
        var stretch = 0.0                            // tanh-limited stretch at the last update, in radii
        let tDown: Double                            // rig time when the finger landed (dwell for plasticity)
        var press = 0.0, hold = 0.0, pressOn = false // press spread (points), hold level 0...1
        var pushed = false                           // push mode: has it displaced anything yet
        var mode: Mode
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
        let base: [(Double, Double, Double)] = [(100, 2.1, 0.17), (55, 1.8, 0.15), (140, 1.65, 0.14), (8, 1.5, 0.14), (198, 1.35, 0.13)]
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
        R = max(60, min(W * 0.26, H * 0.14, 160))
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
        cy = H * 0.40
        homeX = cx; homeY = cy
        h = R / 9
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
        GX = X; GY = X; GW = X; RX = X; RY = X
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
        builtSeed = params.seed; builtFloppy = params.floppy
        t = 0; lastTouch = -10; nextTwitch = 3; relaxUntil = -1
        tLife = 0; releaseCount = 0; nextSpecial = 0; specialUntil = -1
        wanderMoving = false; wanderNext = 3; wanderVX = 0; wanderVY = 0
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
        rungs = []; rungSign = []; rungRef = []
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

    var centroid: (x: Double, y: Double) { (clusters.isEmpty ? cx : clusters[gi].xc, clusters.isEmpty ? cy : clusters[gi].yc) }
    var bodyAngle: Double { clusters.isEmpty ? 0 : atan2(clusters[gi].sn, clusters[gi].cs) }
    var highlight: (x: Double, y: Double) { N > 0 ? (X[hiIdx], Y[hiIdx]) : (cx, cy) }

    // MARK: - Fingers

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
    func touchBegan(_ id: ObjectIdentifier, x: Double, y: Double, time: TimeInterval, allowed: Bool = true, radius: Double = 0) {
        guard N > 0 else { return }
        let grab = allowed && (insideBody(x, y) || nearBody(x, y, R * 0.22))
        let f = Finger(x: x, y: y, mode: !allowed ? .none : (grab ? .grab : .push), time: t)
        f.radius = radius; f.r0 = radius
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
            if f.mem.isEmpty {
                let order = (0..<N).sorted { hypot(X[$0] - x, Y[$0] - y) < hypot(X[$1] - x, Y[$1] - y) }
                for i in order.prefix(6) {
                    let ox = X[i] - x, oy = Y[i] - y, d = hypot(ox, oy), inv = d > 1e-6 ? 1 / d : 0
                    f.mem.append((i, ox, oy, 1, ox * inv, oy * inv))
                    GRAB[i] = true
                }
            }
            onEvent?(.press(gain: 0.7))
        }
        fingers[id] = f
    }

    /// `x, y` is the real finger position. `predictedX/Y` is the system's guess for the next frame; it is used
    /// only on frames that received a fresh move event (Apple: predicted touches are temporary and must be
    /// replaced as real touches arrive). `distance` is the true travelled distance from coalesced touches.
    func touchMoved(_ id: ObjectIdentifier, x: Double, y: Double, predictedX: Double?, predictedY: Double?, distance: Double, radius: Double = 0) {
        guard let f = fingers[id] else { return }
        f.rawX = x; f.rawY = y
        if let predictedX, let predictedY {
            f.predX = predictedX; f.predY = predictedY; f.hasPrediction = true
        } else {
            f.hasPrediction = false
        }
        f.movedThisFrame = true
        f.travel += distance; f.travelFrame += distance
        if radius > 0 { f.radius = radius }
    }

    func touchEnded(_ id: ObjectIdentifier, time: TimeInterval) {
        guard let f = fingers.removeValue(forKey: id) else { return }
        for m in f.mem { GRAB[m.i] = false }
        lastTouch = t
        if f.mode == .grab {
            // release strength: how fast it was flicked (peak speed over the last ~80 ms) or how far it was
            // stretched (tanh-limited stretch over the limit), whichever is bigger, so a slow let-go still pops
            let sv = min(1, f.peak / R / 6)
            let ss = pow(min(1, f.stretch / max(0.01, params.maxPull)), 1.5)
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
        guard let f = fingers.removeValue(forKey: id) else { return }
        for m in f.mem { GRAB[m.i] = false }
        lastTouch = t
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
        if params.seed != builtSeed || params.floppy != builtFloppy {
            setup(width: W, height: H)
        } else if params.cSpace != builtSpace || params.cRad != builtRad {
            buildClusters()
        }
        let mat = params

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
            let tx = f.ax + ex, ty = f.ay + ey
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

        // idle life: only when nobody is touching, fading in over a second after release
        let idle = fingers.isEmpty ? min(1, max(0, (t - lastTouch - 0.8) / 1.2)) : 0
        let L = idle * (reduceMotion ? 0.5 : 1)
        // 提案第 19 條: with idleFreeze the idle motion keeps its amplitude and only its clock stops while touched
        // (the body holds its breath instead of snapping to the rest pose); L still gates twitch, wander and sway
        tLife += dt * L
        let freeze = mat.idleFreeze >= 0.5
        let Lamp = freeze ? (reduceMotion ? 0.5 : 1) : L
        let tl = freeze ? tLife : t

        // wandering home (提案第 20、31 條): pick a spot, walk there with a smoothstep speed profile (6p(1−p): same average
        // speed and the same walk-then-rest rhythm as the constant-speed version), rest a while; stop when touched.
        // Reduce Motion halves the speed again (×0.25 together with L)
        wanderVX = 0; wanderVY = 0
        if L > 0.5 && mat.wander > 0 {
            if !wanderMoving && t > wanderNext {
                wanderSX = homeX; wanderSY = homeY
                wanderX = cx + (Double.random(in: 0..<1) - 0.5) * W * 0.36
                wanderY = cy + (Double.random(in: 0..<1) - 0.5) * H * 0.16
                wanderT = max(0.5, hypot(wanderX - homeX, wanderY - homeY) / (mat.wander * R * (reduceMotion ? 0.5 : 1)))
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
                    wanderNext = t + 1.5 + Double.random(in: 0..<5)
                }
            }
        } else if !fingers.isEmpty {
            wanderMoving = false
            wanderNext = t + 2 + Double.random(in: 0..<3)
        }

        let n = max(1, Int((dt * 240).rounded()))
        let sdt = dt / Double(n)
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
        let damp = min(0.995, mat.damp + (special ? 0.03 : 0)), alpha = mat.alpha * (special ? 1.25 : 1)
        // 1 Verlet
        for i in 0..<N {
            let vx = (X[i] - PX[i]) * damp, vy = (Y[i] - PY[i]) * damp
            PX[i] = X[i]; PY[i] = Y[i]
            X[i] += vx; Y[i] += vy
        }
        // 2 fingers
        for f in fingers.values {
            if f.mode == .grab {
                // the patch follows the finger and, while pressed, spreads away from it (squashes flat)
                for m in f.mem {
                    let k = 0.55 * m.w
                    X[m.i] += (f.fx + m.ox + m.dx * f.press - X[m.i]) * k
                    Y[m.i] += (f.fy + m.oy + m.dy * f.press - Y[m.i]) * k
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
        let bs = Lamp * mat.life * 0.045 * sin(tl * 2 * .pi / 3.8), bsx = 1 + bs, bsy = 1 - bs * 0.85
        let wr = Lamp * mat.life * mat.wriggle * R, swA = Lamp * mat.life * mat.drift * R, iR = 1 / R
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
        for i in 0..<N {
            var ex = QX[i], ey = QY[i]
            if wr != 0 {
                let qx = ex * iR, qy = ey * iR
                ex += wr * (0.6 * sin(1.7 * qy + tl * 1.3 + 0.3) + 0.4 * sin(2.3 * qx - tl * 1.0 + 1.7))
                ey += wr * (0.6 * sin(1.9 * qx - tl * 1.1 + 2.1) + 0.4 * sin(2.1 * qy + tl * 1.6 + 0.6))
            }
            let k = TID[i]
            if k >= 0 {
                let tt = tent[k], u = TUB[i], u2 = u * u
                if swA != 0 {
                    let kd = Double(k)
                    let phv = (sin(tl * 2 * .pi / (4.2 + kd * 0.9) + kd * 2.1) + 0.35 * sin(tl * 2 * .pi / (1.9 + kd * 0.4) + kd)) * swA * u2
                    ex += -tt.uy * phv; ey += tt.ux * phv
                }
                if tvx != 0 || tvy != 0 { ex -= tvx * u2; ey -= tvy * u2 }
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
        let ap = max(-0.12, min(0.12, (sqrt(A0 / A) - 1) * mat.areaGain))
        let gcx = clusters[gi].xc, gcy = clusters[gi].yc
        for i in 0..<N {
            var gx = GX[i] / GW[i], gy = GY[i] / GW[i]
            gx = gcx + (gx - gcx) * (1 + ap); gy = gcy + (gy - gcy) * (1 + ap)
            let ka = alpha * KF[i]
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
                let d = max(1e-6, hypot(dx, dy)), l0 = bndL[k], lo = l0 * 0.6, hi = l0 * (tentacle ? 1.7 : 2.4)
                var c = 0.0
                if d > hi { c = (d - hi) / d } else if d < lo { c = (d - lo) / d }
                if c == 0 { continue }
                let wi = GRAB[i] ? 0.15 : 0.5, wj = GRAB[j] ? 0.15 : 0.5, sw = wi + wj
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
        let hx = homeX + Lamp * mat.life * R * 0.035 * sin(tl * 2 * .pi / 7.3)
        let hy = homeY + Lamp * mat.life * R * 0.05 * sin(tl * 2 * .pi / 4.7)
        let kh = 0.02 * (grabbing ? mat.anchor : 1), dx = hx - gcx, dy = hy - gcy
        let padT = 90.0, padB = H - 120, padL = 8.0, padR = W - 8
        for i in 0..<N {
            if !GRAB[i] { X[i] += dx * kh; Y[i] += dy * kh }
            if Y[i] < padT { Y[i] = padT }
            if Y[i] > padB { Y[i] = padB }
            if X[i] < padL { X[i] = padL }
            if X[i] > padR { X[i] = padR }
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
        let dmin = h * 0.6, dmin2 = dmin * dmin, inv = 1 / dmin
        var grid: [Int: [Int]] = [:]
        grid.reserveCapacity(N)
        func key(_ gx: Int, _ gy: Int) -> Int { gx &* 73856 &+ gy }
        for i in 0..<N {
            grid[key(Int(X[i] * inv), Int(Y[i] * inv)), default: []].append(i)
        }
        let nb = bnd.count
        for i in 0..<N {
            let gx = Int(X[i] * inv), gy = Int(Y[i] * inv)
            for ox in -1...1 {
                for oy in -1...1 {
                    guard let cell = grid[key(gx + ox, gy + oy)] else { continue }
                    for j in cell {
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
        let touched = fingers.values.contains { $0.mode == .grab }
        if t < relaxUntil {
            // 揉回原形: the remembered shape eases back to the original over half a second; positions follow
            // through shape matching, so nothing jumps (手感精修提案 第 28 條)
            let kr = min(1, 6 * dt)
            for i in 0..<N { QX[i] += (Q0X[i] - QX[i]) * kr; QY[i] += (Q0Y[i] - QY[i]) * kr }
        } else if touched {
            // only after dwelling: within `dwellLo` a light press or a quick flick springs back,
            // from `dwellHi` on kneading remembers at full speed (輕按回彈，揉捏即留形)
            var g = 0.0
            let lo = mat.dwellLo, hi = max(lo + 0.001, mat.dwellHi)
            for f in fingers.values where f.mode == .grab {
                let x = max(0, min(1, (t - f.tDown - lo) / (hi - lo)))
                g = max(g, x * x * (3 - 2 * x))
            }
            let yl = mat.yield * R, kc = min(1, mat.creep * dt * g)
            if kc > 0 {
                for i in 0..<N {
                    let rx = RX[i] / GW[i], ry = RY[i] / GW[i], dx = rx - QX[i], dy = ry - QY[i], dl = hypot(dx, dy)
                    if dl > yl {
                        let s = (1 - yl / dl) * kc * (TID[i] >= 0 ? 1 - 0.85 * TU[i] : 1)
                        QX[i] += dx * s; QY[i] += dy * s
                        let ex = QX[i] - Q0X[i], ey = QY[i] - Q0Y[i], el = hypot(ex, ey), lim = R * 1.1
                        if el > lim { QX[i] = Q0X[i] + ex * lim / el; QY[i] = Q0Y[i] + ey * lim / el }
                    }
                }
            }
        } else {
            let kr = min(1, mat.recover * dt)
            if kr > 0 {
                for i in 0..<N { QX[i] += (Q0X[i] - QX[i]) * kr; QY[i] += (Q0Y[i] - QY[i]) * kr }
            }
        }
        // tentacles barely remember: tips always spring back to their length and thickness (the body is the clay).
        // Must happen before recentering, with Q0 zero-mean, or the junction drifts apart frame by frame.
        let kt = min(1, 0.8 * dt)
        for i in 0..<N where TID[i] >= 0 {
            let w = kt * TU[i]
            QX[i] += (Q0X[i] - QX[i]) * w; QY[i] += (Q0Y[i] - QY[i]) * w
        }
        var mx = 0.0, my = 0.0
        for i in 0..<N { mx += QX[i]; my += QY[i] }
        mx /= Double(N); my /= Double(N)
        for i in 0..<N { QX[i] -= mx; QY[i] -= my }
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

    /// Largest UITouch.majorRadius among the fingers down (for the panel readout).
    var maxTouchRadius: Double { fingers.values.map { $0.radius }.max() ?? 0 }

    /// How close the most-stretched grabbing finger is to the stretch limit, 0...1 (sharpness bonus, 提案第 15 條).
    var stretchLevel: Double {
        var m = 0.0
        for f in fingers.values where f.mode == .grab { m = max(m, f.stretch / max(0.01, params.maxPull)) }
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
