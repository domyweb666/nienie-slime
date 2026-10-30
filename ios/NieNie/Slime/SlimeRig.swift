import Foundation

/// Things the rig asks the outside world to play. Picture, sound and haptics
/// all react to the same event in the same frame.
enum SlimeEvent {
    case squish(Double)   // touched / pressed (0...1)
    case tap              // quick tap
    case boing(Double)    // released after a pull or press (0...1)
    case creak(Double)    // stretching past a step (0...1)
}

/// Procedural slime: 18 control points, one spring each, gesture rules on top.
/// A line-by-line port of `prototype/web/index.html` (designed deformation, not physics).
final class SlimeRig {
    static let K = 18
    private let K = SlimeRig.K

    var params: FeelParams
    /// Reduce Motion: slower, calmer springs and no surprise bounce. Feedback stays on.
    var reduceMotion = false
    var onEvent: ((SlimeEvent) -> Void)?

    private(set) var W = 0.0, H = 0.0, R = 100.0, ground = 0.0, cx = 0.0, cy = 0.0

    private(set) var ang = [Double](repeating: 0, count: SlimeRig.K)  // rest angle
    private(set) var r0 = [Double](repeating: 0, count: SlimeRig.K)   // rest radius
    private var ox = [Double](repeating: 0, count: SlimeRig.K)        // current offset from rest
    private var oy = [Double](repeating: 0, count: SlimeRig.K)
    private var vx = [Double](repeating: 0, count: SlimeRig.K)
    private var vy = [Double](repeating: 0, count: SlimeRig.K)
    private var mx = [Double](repeating: 0, count: SlimeRig.K)        // remembered (molded) offset
    private var my = [Double](repeating: 0, count: SlimeRig.K)
    private var tx = [Double](repeating: 0, count: SlimeRig.K)        // target from fingers
    private var ty = [Double](repeating: 0, count: SlimeRig.K)
    private var tw = [Double](repeating: 0, count: SlimeRig.K)
    private(set) var sq = 0.0   // whole-body squash spring (positive = flatter)
    private var sqv = 0.0
    private var releases = 0

    final class Finger {
        enum Mode { case grab, press, push, none }
        var x, y, sx, sy, lx, ly, fx, fy, bx, by: Double
        var t0: TimeInterval
        var moved = 0.0, still = 0.0, press = 0.0
        var k: Int
        var mode: Mode
        var ex = 0.0, ey = 0.0
        var creak = 0

        init(x: Double, y: Double, t0: TimeInterval, k: Int, mode: Mode) {
            self.x = x; self.y = y; sx = x; sy = y; lx = x; ly = y; fx = x; fy = y; bx = x; by = y
            self.t0 = t0; self.k = k; self.mode = mode
        }
    }
    private(set) var fingers: [ObjectIdentifier: Finger] = [:]

    init(params: FeelParams) {
        self.params = params
    }

    // MARK: - Setup

    private func restR(_ a: Double) -> Double {
        let c = cos(a), s = sin(a), ry = s < 0 ? R : R * 0.72
        let ellipse = 1 / sqrt(pow(c / (R * 1.1), 2) + pow(s / ry, 2))
        // the little pointy tip on top
        return ellipse * (1 + 0.2 * exp(-pow((a + .pi / 2) / 0.32, 2)))
    }

    func setup(width: Double, height: Double) {
        W = width; H = height
        R = max(70, min(W * 0.3, H * 0.17, 190))
        ground = min(H * 0.64, H - 140)
        cx = W / 2
        for k in 0..<K {
            ang[k] = -.pi / 2 + Double(k) / Double(K) * .pi * 2
            r0[k] = restR(ang[k])
        }
        var maxY = -1e9
        for k in 0..<K { maxY = max(maxY, sin(ang[k]) * r0[k]) }
        cy = ground - maxY
        for k in 0..<K { ox[k] = 0; oy[k] = 0; vx[k] = 0; vy[k] = 0; mx[k] = 0; my[k] = 0 }
        sq = 0; sqv = 0
        fingers.removeAll()
    }

    private func restX(_ k: Int) -> Double { cx + cos(ang[k]) * r0[k] }
    private func restY(_ k: Int) -> Double { cy + sin(ang[k]) * r0[k] }

    /// Where control point k is drawn. Squash: top comes down, sides go out.
    func shape(_ k: Int) -> (x: Double, y: Double) {
        let bx = cos(ang[k]) * r0[k], by = sin(ang[k]) * r0[k]
        let sx = 1 + sq * 0.55, sy = 1 - sq
        let x = cx + bx * sx + ox[k]
        var y = cy + (by < 0 ? by * sy : by) + oy[k]
        if y > ground { y = ground }
        return (x, y)
    }

    func points() -> [(x: Double, y: Double)] {
        (0..<K).map { shape($0) }
    }

    // MARK: - Fingers

    func insideBody(_ x: Double, _ y: Double) -> Bool {
        var c = false
        var j = K - 1
        for i in 0..<K {
            let a = shape(i), b = shape(j)
            if (a.y > y) != (b.y > y) && x < (b.x - a.x) * (y - a.y) / (b.y - a.y) + a.x { c.toggle() }
            j = i
        }
        return c
    }

    private func nearestBone(_ x: Double, _ y: Double) -> Int {
        var best = 0, bd = 1e9
        for k in 0..<K {
            let p = shape(k), d = hypot(p.x - x, p.y - y)
            if d < bd { bd = d; best = k }
        }
        return best
    }

    /// `allowed` is false for touches in the system-gesture bands near the screen edges.
    func touchBegan(_ id: ObjectIdentifier, x: Double, y: Double, time: TimeInterval, allowed: Bool = true) {
        let ins = insideBody(x, y), near = hypot(x - cx, y - (cy - R * 0.2)) < R * 2.2
        let k = nearestBone(x, y), b = shape(k)
        let mode: Finger.Mode = !allowed ? .none : (ins ? .grab : (near ? .push : .none))
        let f = Finger(x: x, y: y, t0: time, k: k, mode: mode)
        fingers[id] = f
        if mode == .grab {
            // first frame: the spot under the finger dips in right away
            let dx = cx - b.x, dy = cy - b.y, l = hypot(dx, dy) == 0 ? 1 : hypot(dx, dy)
            ox[k] += dx / l * R * 0.05; oy[k] += dy / l * R * 0.05
            vx[k] += dx / l * R * 1.2; vy[k] += dy / l * R * 1.2
            onEvent?(.squish(0.45))
        }
    }

    /// `x, y` is where the slime should chase (may be a predicted touch);
    /// `distance` is how far the real finger travelled since the last call.
    func touchMoved(_ id: ObjectIdentifier, x: Double, y: Double, distance: Double) {
        guard let f = fingers[id] else { return }
        f.moved += distance
        f.x = x; f.y = y
    }

    func touchEnded(_ id: ObjectIdentifier, time: TimeInterval) {
        guard let f = fingers.removeValue(forKey: id) else { return }
        guard f.mode == .grab || f.mode == .press else { return }
        let quick = time - f.t0 < 0.22 && f.moved < 12
        if quick {
            sqv += reduceMotion ? 2 : 3.5
            onEvent?(.tap)
        } else {
            let st = hypot(f.ex, f.ey) / R
            onEvent?(.boing(min(1, 0.2 + st * 0.5 + f.press * 0.4)))
            releases += 1
            if releases % 8 == 0 && !reduceMotion {
                // every so often, an extra jiggly bounce
                sqv -= 4
                for k in 0..<K {
                    vx[k] += Double.random(in: -0.5...0.5) * R * 1.5
                    vy[k] += Double.random(in: -0.5...0.5) * R * 1.5
                }
            }
        }
    }

    func cancelAllTouches() { fingers.removeAll() }

    // MARK: - External nudges (buttons, VoiceOver actions)

    func bump(_ amount: Double = 3) { sqv += reduceMotion ? amount * 0.6 : amount }

    func resetShape() {
        for k in 0..<K { mx[k] = 0; my[k] = 0 }
        bump(3)
    }

    /// VoiceOver "拉長": tug the top upward as if pulled.
    func stretchUp() {
        for d in -3...3 {
            let k = (d + K) % K, w = exp(-Double(d * d) / 2.2)
            vy[k] -= R * 6 * w
        }
        onEvent?(.boing(0.6))
    }

    // MARK: - Per-frame rules

    /// Spring constants, made calmer under Reduce Motion (參數表: 0.5 s, 0.9).
    private var springParams: (response: Double, damping: Double) {
        reduceMotion ? (max(params.response, 0.5), max(params.damping, 0.9)) : (params.response, params.damping)
    }

    func update(_ dt: Double) {
        let mat = params
        for k in 0..<K { tw[k] = 0; tx[k] = 0; ty[k] = 0 }
        var sqT = 0.0

        for f in fingers.values {
            let sp = hypot(f.x - f.lx, f.y - f.ly) / max(dt, 1e-3)
            f.lx = f.x; f.ly = f.y
            // sticky lag: the slime follows the finger a little behind
            let kl = 1 - exp(-dt / max(0.005, mat.lag))
            f.fx += (f.x - f.fx) * kl; f.fy += (f.y - f.fy) * kl

            switch f.mode {
            case .grab, .press:
                if sp < R * 0.4 { f.still += dt } else { f.still = 0 }
                if f.mode == .grab && f.still > 0.2 && f.moved < 12 {
                    f.mode = .press
                    var bk = 0, bd = 1e9
                    for k in 0..<K {
                        if sin(ang[k]) > -0.2 { continue }
                        let d = abs(shape(k).x - f.x)
                        if d < bd { bd = d; bk = k }
                    }
                    f.k = bk
                    onEvent?(.squish(0.8))
                }
                if f.mode == .press {
                    f.press = min(1, f.press + dt / 0.6)
                    sqT = max(sqT, f.press * mat.press)
                    let k = f.k, dx = cx - restX(k), dy = cy - restY(k)
                    let l = hypot(dx, dy) == 0 ? 1 : hypot(dx, dy)
                    addTarget(k, dx / l * R * 0.12 * f.press, dy / l * R * 0.12 * f.press, 1)
                    continue
                }
                // pull: drag vector, softly limited
                var ex = f.fx - f.sx, ey = f.fy - f.sy
                let el = hypot(ex, ey), lim = mat.maxPull * R
                let s = el > 0 ? lim * tanh(el / lim) / el : 0
                ex *= s; ey *= s
                f.ex = ex; f.ey = ey
                // the grabbed point and its neighbours follow, weaker further away; the base gets thinner
                let k0 = f.k
                for d in -4...4 {
                    let k = (k0 + d + K) % K, w = exp(-Double(d * d) / 2.2)
                    var txk = mx[k] + ex * w, tyk = my[k] + ey * w
                    if d != 0 && el > R * 0.2 {
                        let nx = cos(ang[k0]), ny = sin(ang[k0])
                        let side = -Double(d.signum()) * w * (1 - w) * mat.neck * min(1, el / R) * R * 0.5
                        txk += -ny * side; tyk += nx * side
                    }
                    addTarget(k, txk, tyk, w)
                }
                let st = el / R, step = Int(floor(st * 5))
                if step > f.creak && st > 0.4 { onEvent?(.creak(min(1, st / 1.6))) }
                f.creak = step

            case .push:
                // finger outside: the edge it touches is pushed in
                for k in 0..<K {
                    let p = shape(k), d = hypot(p.x - f.x, p.y - f.y), rf = R * 0.2
                    if d < rf + R * 0.25 {
                        let dx = cx - p.x, dy = cy - p.y, l = hypot(dx, dy) == 0 ? 1 : hypot(dx, dy)
                        let depth = max(0, rf + R * 0.25 - d)
                        let w = min(1, depth / (R * 0.25))
                        addTarget(k, ox[k] + dx / l * depth * 0.5, oy[k] + dy / l * depth * 0.5, w)
                    }
                }

            case .none:
                break
            }
        }

        // springs: each control point chases its target (touched) or its remembered shape (free)
        let sp = springParams
        let om = 2 * Double.pi / sp.response, kk = om * om, cc = 2 * sp.damping * om
        for k in 0..<K {
            let w = min(1, tw[k])
            let gx = w > 0 ? tx[k] / max(tw[k], 1e-6) : mx[k]
            let gy = w > 0 ? ty[k] / max(tw[k], 1e-6) : my[k]
            let Gx = mx[k] + (gx - mx[k]) * w, Gy = my[k] + (gy - my[k]) * w
            let ax = kk * (Gx - ox[k]) - cc * vx[k], ay = kk * (Gy - oy[k]) - cc * vy[k]
            vx[k] += ax * dt; vy[k] += ay * dt
            ox[k] += vx[k] * dt; oy[k] += vy[k] * dt
            // keep it a clean shape: never fold inside out, never stretch absurdly
            let rx = cos(ang[k]), ry = sin(ang[k])
            let rad = ox[k] * rx + oy[k] * ry, tan = -ox[k] * ry + oy[k] * rx
            let radC = max(-r0[k] * 0.7, min(R * 2, rad)), tanC = max(-R * 1.4, min(R * 1.4, tan))
            ox[k] = radC * rx - tanC * ry; oy[k] = radC * ry + tanC * rx
            // molding memory (mode C): long, big deformations are kept; then slowly relax back
            let dx = ox[k] - mx[k], dy = oy[k] - my[k], dl = hypot(dx, dy), yl = mat.yield * R
            if w > 0.05 && dl > yl {
                let kc = min(1, mat.creep * dt * w)
                mx[k] += dx * (1 - yl / dl) * kc; my[k] += dy * (1 - yl / dl) * kc
            }
            if w < 0.05 {
                let kr = min(1, mat.recover * dt)
                mx[k] *= 1 - kr; my[k] *= 1 - kr
            }
        }

        // keep the area roughly constant: pulling one part out makes the rest a little slimmer
        var A = 0.0, A0 = 0.0
        for i in 0..<K {
            let j = (i + 1) % K, a = shape(i), b = shape(j)
            A += a.x * b.y - b.x * a.y
            A0 += restX(i) * restY(j) - restX(j) * restY(i)
        }
        let ratio = A0 / A
        if ratio.isFinite && ratio > 0 {
            let adj = max(-0.08, min(0.08, sqrt(ratio) - 1))
            for k in 0..<K where tw[k] < 0.3 {
                ox[k] += cos(ang[k]) * r0[k] * adj * 0.15
                oy[k] += sin(ang[k]) * r0[k] * adj * 0.15
            }
        }

        let sk = kk * 0.8, sc = cc * 0.9
        sqv += (sk * (sqT - sq) - sc * sqv) * dt
        sq += sqv * dt
        sq = max(-0.35, min(0.6, sq))
    }

    private func addTarget(_ k: Int, _ x: Double, _ y: Double, _ w: Double) {
        tx[k] += x * w; ty[k] += y * w; tw[k] += w
    }

    // MARK: - Readouts for sound and haptics

    /// How fast active fingers are moving, 0...1 (drives the kneading sound bed).
    func kneadSpeed(dt: Double) -> Double {
        var spd = 0.0
        for f in fingers.values where f.mode != .none {
            spd += hypot(f.x - f.bx, f.y - f.by) / max(dt, 1e-3)
            f.bx = f.x; f.by = f.y
        }
        return min(1, spd / (R * 6))
    }

    /// How deformed the body is right now, 0...1 (drives continuous haptics).
    var deformation: Double {
        var m = 0.0
        for k in 0..<K { m = max(m, hypot(ox[k] - mx[k], oy[k] - my[k])) }
        return min(1, max(abs(sq) / 0.45, m / (R * 1.2)))
    }

    var isTouched: Bool { fingers.values.contains { $0.mode != .none } }
}
