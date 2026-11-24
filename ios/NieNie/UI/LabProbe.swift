import CoreGraphics
import Foundation
import QuartzCore

/// v2.61 B7 and A7: what the feel desk's 量測 reads. One object, used on the main thread only (the skin is counted on a queue of its own).
/// Off unless the desk is open; nothing here is saved.
final class LabProbe {
    static let shared = LabProbe()

    /// 碰著時固定 120: the display link asks for 120, 120, 120 instead of 60, 120, 120 while a finger is down
    var lock120 = false

    /// The desk is open: touches are timed. Closing it stops the skin reading too
    var on = false {
        didSet {
            if !on { open = false; skinOn = false }
        }
    }

    // MARK: - B7 觸控到畫面、聲音、震動

    /// One finger landing. All in seconds on the clock of UITouch.timestamp, CADisplayLink and CACurrentMediaTime (mach time since boot); 0 = did not happen.
    struct Lag {
        var touch = 0.0      // UITouch.timestamp
        var handler = 0.0    // touchesBegan was entered
        var sound0 = 0.0     // before and after the press sound's players were told to play
        var sound1 = 0.0
        var hap0 = 0.0       // before and after the haptic player was told to start
        var hap1 = 0.0
        var frame0 = 0.0     // the next frame: starting, and handed over
        var frame1 = 0.0
        var target = 0.0     // ...and when the system means to show it (CADisplayLink.targetTimestamp)
    }
    private static let room = 64
    private var ring = [Lag](repeating: Lag(), count: LabProbe.room)   // written in place: nothing is allocated a touch
    private(set) var lagCount = 0
    private var cur = Lag()
    private var open = false

    func begin(touch: TimeInterval) {
        guard on else { return }
        cur = Lag()
        cur.touch = touch
        cur.handler = CACurrentMediaTime()
        open = true
    }
    func soundStart() { if on && open && cur.sound0 == 0 { cur.sound0 = CACurrentMediaTime() } }
    func soundEnd() { if on && open && cur.sound1 == 0 { cur.sound1 = CACurrentMediaTime() } }
    func hapStart() { if on && open && cur.hap0 == 0 { cur.hap0 = CACurrentMediaTime() } }
    func hapEnd() { if on && open && cur.hap1 == 0 { cur.hap1 = CACurrentMediaTime() } }
    /// The first frame after the touch closes the record
    func frame(start: Double, end: Double, target: Double) {
        guard on, open else { return }
        cur.frame0 = start; cur.frame1 = end; cur.target = target
        ring[lagCount % Self.room] = cur
        lagCount += 1
        open = false
    }
    func lagReset() { lagCount = 0; open = false }

    private var kept: [Lag] {
        let n = min(lagCount, Self.room)
        return (0..<n).map { ring[(lagCount - n + $0) % Self.room] }
    }
    private static func ms(_ v: Double) -> String { String(format: "%.1f", v) }
    /// "中間 12.3（8.1 到 20.4，12 下）"; nothing measured: "沒有"
    private static func spread(_ a: [Double]) -> String {
        guard !a.isEmpty else { return "沒有" }
        let s = a.sorted()
        return "中間 \(ms(s[s.count / 2]))（\(ms(s[0])) 到 \(ms(s[s.count - 1]))，\(s.count) 下）"
    }
    private struct Column {
        let name: String
        let key: KeyPath<Lag, Double>
    }
    private static let columns: [Column] = [
        Column(name: "程式收到手指", key: \Lag.handler),
        Column(name: "叫聲音播之前", key: \Lag.sound0),
        Column(name: "叫聲音播完", key: \Lag.sound1),
        Column(name: "叫震動之前", key: \Lag.hap0),
        Column(name: "叫震動完", key: \Lag.hap1),
        Column(name: "開始算那一格", key: \Lag.frame0),
        Column(name: "那一格交出去", key: \Lag.frame1),
        Column(name: "系統排定上螢幕", key: \Lag.target),
    ]
    /// Milliseconds after the touch; nil when that step did not happen
    private static func after(_ l: Lag, _ key: KeyPath<Lag, Double>) -> Double? {
        let v: Double = l[keyPath: key]
        return v > 0 ? (v - l.touch) * 1000 : nil
    }
    private static func all(_ k: [Lag], _ key: KeyPath<Lag, Double>) -> [Double] { k.compactMap { l -> Double? in after(l, key) } }

    /// One line for the desk
    var lagShort: String {
        let k = kept
        guard !k.isEmpty else { return "觸控：還沒量到，點牠一下" }
        func mid(_ key: KeyPath<Lag, Double>) -> String {
            let a = Self.all(k, key).sorted()
            return a.isEmpty ? "沒有" : Self.ms(a[a.count / 2])
        }
        let s: String = mid(\Lag.sound1), h: String = mid(\Lag.hap1), d: String = mid(\Lag.target)
        return "觸控 \(k.count) 下，中間值（毫秒）：叫完聲音 \(s)、叫完震動 \(h)、畫面排定 \(d)"
    }
    /// The copied text
    var lagText: String {
        let k = kept
        var t = "觸控延遲（毫秒，從系統記的手指碰到那一刻 UITouch.timestamp 起算，最近 \(k.count) 下）"
        for c in Self.columns { t += "\n" + c.name + "：" + Self.spread(Self.all(k, c.key)) }
        t += "\n沒量到：手指碰到玻璃到系統記時間、合成和面板亮起來、喇叭出聲、馬達轉動。這幾段要用 240 格影片補。"
        t += "\n「叫聲音播完」「叫震動完」是程式叫完的時間，那時聲音和震動還沒出來。「排定上螢幕」是系統給的時間，畫面可能再晚一格。"
        if !k.isEmpty { t += "\n最近幾下，欄位順序同上：" }
        for l in k.suffix(20) {
            let cells: [String] = Self.columns.map { c -> String in
                if let v = Self.after(l, c.key) { return Self.ms(v) }
                return "-"
            }
            t += "\n" + cells.joined(separator: " ")
        }
        return t
    }
    var lagAny: Bool { lagCount > 0 }

    // MARK: - A7 皮的塊數、洞數、每格跳動

    /// How long one press of 量皮 lasts, seconds
    static let skinSeconds = 5.0
    private(set) var skinOn = false
    private var skinUntil = 0.0
    private var skinGen = 0
    private var skinBusy = false
    private var skinPrev: [(x: Double, y: Double)] = []
    private var skinLast = 0.0     // how far the outline's fastest point went last frame
    private var skinMove = 0.0     // ...and since the last reading
    private var skinFrames = 0     // frames drawn while measuring
    private var skinReads = 0      // frames counted
    private var skinMain = 0.0     // seconds on the main thread, all frames
    private var skinMs = 0.0, skinMsMax = 0.0
    private var pieces = 0, holes = 0, piecesMax = 0, holesMax = 0
    private var splitReads = 0, holeReads = 0, popReads = 0
    private var popMax = 0.0       // points
    private let reader = SkinReader()
    private let queue = DispatchQueue(label: "nienie.skinreader", qos: .userInitiated)

    func skinStart() {
        guard on else { return }
        skinReset()
        skinOn = true
        skinUntil = CACurrentMediaTime() + Self.skinSeconds
    }
    func skinReset() {
        skinGen += 1
        skinOn = false
        skinPrev = []; skinLast = 0; skinMove = 0
        skinFrames = 0; skinReads = 0; skinMain = 0; skinMs = 0; skinMsMax = 0
        pieces = 0; holes = 0; piecesMax = 0; holesMax = 0
        splitReads = 0; holeReads = 0; popReads = 0; popMax = 0
    }

    /// Called once a frame by the slime view (from tick, whatever the skin is), so the five seconds end even when no skin is drawn
    func skinTick() {
        if skinOn && CACurrentMediaTime() > skinUntil { skinOn = false }
    }

    /// Called by the slime view once a frame, only while measuring. The mask's own triangles and lines are copied (a few dozen KB) and counted off the main thread;
    /// while a count is running the frames in between are skipped.
    /// - Parameters:
    ///   - mesh: this frame's mesh skin, nil = the outline path
    ///   - paths: what is filled when there is no mesh
    ///   - outline: the ring on screen, to tell the body's own movement from a jump of the skin
    func skinFrame(mesh: SkinMesh?, paths: [CGPath], outline: [(x: Double, y: Double)], size: CGSize, R: Double, round: Double) {
        guard skinOn else { return }
        let t0: Double = CACurrentMediaTime()
        if outline.count == skinPrev.count {
            var d = 0.0
            for i in 0..<outline.count {
                let dx: Double = outline[i].x - skinPrev[i].x, dy: Double = outline[i].y - skinPrev[i].y
                d = max(d, (dx * dx + dy * dy).squareRoot())
            }
            skinLast = d
        }   // else the points were laid out again: take last frame's
        skinPrev = outline
        skinMove += skinLast
        skinFrames += 1
        let w = Int(size.width.rounded()), h = Int(size.height.rounded())
        if !skinBusy && R > 1 && w > 8 && h > 8 {
            let sigma: Double = round > 0 ? max(0.6, R * 0.07 / 2) * round : 0
            var job = SkinReader.Job(w: w, h: h, R: R, sigma: sigma, move: skinMove, gen: skinGen)
            if let m = mesh {
                job.n = m.n; job.fanN = m.fanN; job.capN = m.capN
                job.index = m.index
                job.verts = Array(UnsafeMutableBufferPointer(start: m.verts, count: m.n + m.fanN))
                job.caps = Array(UnsafeMutableBufferPointer(start: m.caps, count: m.capN + m.lineN))
                let fw = Double(w), fh = Double(h)
                let x0: Double = max(0, min(fw, m.clipL)), x1: Double = max(0, min(fw, m.clipR)), y1: Double = max(1, min(fh, m.clipB + 1))
                job.clip = CGRect(x: x0, y: 0, width: max(0, x1 - x0), height: y1)
            } else {
                job.paths = paths
            }
            skinMove = 0
            skinBusy = true
            let r = reader, task = job
            queue.async { [weak self] in
                let out = r.read(task)
                DispatchQueue.main.async { self?.skinDone(out, gen: task.gen) }
            }
        }
        skinMain += CACurrentMediaTime() - t0
    }
    private func skinDone(_ result: SkinReader.Result?, gen: Int) {
        skinBusy = false
        guard let r = result, gen == skinGen else { return }
        skinReads += 1
        skinMs += r.ms; skinMsMax = max(skinMsMax, r.ms)
        pieces = r.pieces; holes = r.holes
        piecesMax = max(piecesMax, pieces); holesMax = max(holesMax, holes)
        if r.pieces > 1 { splitReads += 1 }
        if r.holes > 0 { holeReads += 1 }
        popMax = max(popMax, r.pop)
        if r.popBig { popReads += 1 }
    }
    var skinText: String {
        if skinReads == 0 { return skinOn ? "皮：量測中……" : (skinFrames > 0 ? "皮：沒量到" : "皮：還沒量，按「量皮 5 秒」再捏（灰盒開著量不到）") }
        let avg: Double = skinMs / Double(skinReads), main: Double = skinMain / Double(max(1, skinFrames)) * 1000
        var t = skinOn ? "皮（量測中）：" : "皮："
        t += "現在 \(pieces) 塊、\(holes) 洞｜最多 \(piecesMax) 塊、\(holesMax) 洞"
        t += "｜斷開 \(splitReads) 次、有洞 \(holeReads) 次、突然跳 \(popReads) 次"
        t += "｜外框一次最多跳 \(Self.ms(popMax)) 點（扣掉身體自己走的）"
        t += "｜畫了 \(skinFrames) 格、數了 \(skinReads) 格"
        t += "｜數一次 \(Self.ms(avg)) 毫秒（最長 \(Self.ms(skinMsMax))，在背景）、主執行緒每格多 " + String(format: "%.2f", main) + " 毫秒"
        return t
    }
}

/// v2.61 A7: the skin's shape as the light pass cuts it, rebuilt on the CPU: the mask (the mesh's triangles and lines, or the outline path) painted at 1×, half size, the small blur,
/// cut at 0.46 (JellySkin.render's `round`). Counted like the web's tool (patches/F1-量測工具/probe.js): pieces from 0.004 R², the ones at the screen's edge as one; holes from 0.002 R²;
/// a jump is how far the edge went past the body's own movement and 4 points. Not the GPU's own texture: what the GPU itself draws wrong is not seen here.
/// `read` runs on one serial queue.
final class SkinReader {
    struct Job {
        var w: Int
        var h: Int
        var R: Double            // the body's radius on screen, points
        var sigma: Double        // the small blur, half-size pixels; 0 = not rounded, cut the mask itself
        var move: Double         // how far the outline's own points went since the last reading, points
        var gen: Int
        var n = 0
        var fanN = 0
        var capN = 0
        var index: [UInt16] = []
        var verts: [SIMD2<Float>] = []
        var caps: [SkinMesh.Cap] = []
        var clip: CGRect = .zero   // the walls on screen, for the first capN lines
        var paths: [CGPath] = []

        init(w: Int, h: Int, R: Double, sigma: Double, move: Double, gen: Int) {
            self.w = w; self.h = h; self.R = R; self.sigma = sigma; self.move = move; self.gen = gen
        }
    }
    struct Result {
        var pieces: Int
        var holes: Int
        var pop: Double     // points past the body's own movement, 0 = none
        var popBig: Bool
        var ms: Double
    }

    private var W = 0, H = 0, w = 0, h = 0
    private var ctx: CGContext?
    private var a: [Float] = [], b: [Float] = []
    private var m: [UInt8] = [], prev: [UInt8] = [], seen: [UInt8] = []
    private var stack: [Int32] = []
    private var d0: [Float] = [], d1: [Float] = []
    private var prevGen = -1

    private func room(_ j: Job) -> Bool {
        if ctx != nil && W == j.w && H == j.h { return true }
        W = j.w; H = j.h
        w = max(2, W / 2); h = max(2, H / 2)
        let c = CGContext(data: nil, width: W, height: H, bitsPerComponent: 8, bytesPerRow: W, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue)
        c?.translateBy(x: 0, y: CGFloat(H)); c?.scaleBy(x: 1, y: -1)   // row 0 at the top, like JellySkin's mask
        ctx = c
        let k = w * h
        a = [Float](repeating: 0, count: k)
        b = a; d0 = a; d1 = a
        m = [UInt8](repeating: 0, count: k)
        prev = m; seen = m
        stack = [Int32](repeating: 0, count: k)
        prevGen = -1
        return c != nil
    }

    func read(_ j: Job) -> Result? {
        let t0: Double = CACurrentMediaTime()
        guard room(j), let c = ctx, let data = c.data else { return nil }
        paint(j, c)
        shrink(data.assumingMemoryBound(to: UInt8.self), c.bytesPerRow)
        if j.sigma > 0 { blur(Float(j.sigma)) }
        let cut: Float = j.sigma > 0 ? 0.46 : 0.5, count = w * h
        for i in 0..<count { m[i] = a[i] > cut ? 1 : 0 }
        let sx: Double = Double(W) / Double(w), sy: Double = Double(H) / Double(h)
        let px: Double = sx * sy / (j.R * j.R)   // one pixel, in R²
        let np = countPieces(px), nh = countHoles(px)
        var pop = 0.0
        if prevGen == j.gen {
            Self.distance(m, &d0, w, h); Self.distance(prev, &d1, w, h)
            var far: Float = 0
            for i in 0..<count where m[i] != prev[i] { far = max(far, m[i] == 0 ? d0[i] : d1[i]) }
            if far < 1e5 { pop = Double(far) * sx - j.move - 4 }   // an empty picture has no distance to the body
        }
        prev = m
        prevGen = j.gen
        return Result(pieces: np, holes: nh, pop: max(0, pop), popBig: pop > 0.12 * j.R, ms: (CACurrentMediaTime() - t0) * 1000)
    }

    private func paint(_ j: Job, _ c: CGContext) {
        c.setFillColor(gray: 0, alpha: 1)
        c.fill(CGRect(x: 0, y: 0, width: W, height: H))
        c.setFillColor(gray: 1, alpha: 1)
        if j.verts.isEmpty {
            for p in j.paths { c.addPath(p); c.fillPath() }
            return
        }
        // every triangle wound the same way, so one non-zero fill is their union, without seams between neighbours
        let path = CGMutablePath()
        func at(_ p: SIMD2<Float>) -> CGPoint { CGPoint(x: CGFloat(p.x), y: CGFloat(p.y)) }
        func tri(_ p: SIMD2<Float>, _ q: SIMD2<Float>, _ r: SIMD2<Float>) {
            let ux: Float = q.x - p.x, uy: Float = q.y - p.y, vx: Float = r.x - p.x, vy: Float = r.y - p.y
            let flipped: Bool = ux * vy - uy * vx < 0
            path.move(to: at(p))
            path.addLine(to: at(flipped ? r : q))
            path.addLine(to: at(flipped ? q : r))
            path.closeSubpath()
        }
        let nv = j.verts.count
        var k = 0
        while k + 2 < j.index.count {
            let i0 = Int(j.index[k]), i1 = Int(j.index[k + 1]), i2 = Int(j.index[k + 2])
            if i0 < nv && i1 < nv && i2 < nv { tri(j.verts[i0], j.verts[i1], j.verts[i2]) }
            k += 3
        }
        k = j.n
        while k + 2 < nv { tri(j.verts[k], j.verts[k + 1], j.verts[k + 2]); k += 3 }
        c.addPath(path)
        c.fillPath()
        c.setStrokeColor(gray: 1, alpha: 1)
        c.setLineCap(.round)
        func line(_ q: SkinMesh.Cap) {
            c.setLineWidth(CGFloat(q.r.x) * 2)
            c.move(to: CGPoint(x: CGFloat(q.ab.x), y: CGFloat(q.ab.y)))
            c.addLine(to: CGPoint(x: CGFloat(q.ab.z), y: CGFloat(q.ab.w)))
            c.strokePath()
        }
        let nc = max(0, min(j.capN, j.caps.count))
        if nc > 0 && j.clip.width > 0 {
            c.saveGState()
            c.clip(to: j.clip)
            for i in 0..<nc { line(j.caps[i]) }
            c.restoreGState()
        }
        for i in nc..<j.caps.count { line(j.caps[i]) }
    }

    /// The 1× mask to half size, sampled between pixels as the shader does
    private func shrink(_ p: UnsafeMutablePointer<UInt8>, _ row: Int) {
        let sx: Double = Double(W) / Double(w), sy: Double = Double(H) / Double(h)
        for y in 0..<h {
            let v: Double = max(0, (Double(y) + 0.5) * sy - 0.5)
            let y0 = min(H - 1, Int(v)), y1 = min(H - 1, y0 + 1), fy = Float(v - Double(y0))
            for x in 0..<w {
                let u: Double = max(0, (Double(x) + 0.5) * sx - 0.5)
                let x0 = min(W - 1, Int(u)), x1 = min(W - 1, x0 + 1), fx = Float(u - Double(x0))
                let a0 = Float(p[y0 * row + x0]), a1 = Float(p[y0 * row + x1]), b0 = Float(p[y1 * row + x0]), b1 = Float(p[y1 * row + x1])
                let top: Float = a0 + (a1 - a0) * fx, bottom: Float = b0 + (b1 - b0) * fx
                a[y * w + x] = (top + (bottom - top) * fy) / 255
            }
        }
    }

    /// jelBlur twice: across, then down
    private func blur(_ s: Float) {
        let r = Int((s * 2.6).rounded(.up))
        var g = [Float](repeating: 0, count: 2 * r + 1)
        var sum: Float = 0
        for i in 0..<g.count {
            let q: Float = Float(i - r) / s
            let e: Float = expf(-0.5 * q * q)
            g[i] = e
            sum += e
        }
        for i in 0..<g.count { g[i] /= sum }
        let w = self.w, h = self.h, taps = g.count
        var pa = a, pb = b   // moved into locals (no copy: the object lets go of them), so the inner loops do not go through the object
        a = []; b = []
        for y in 0..<h {
            for x in 0..<w {
                var t: Float = 0
                for i in 0..<taps { t += pa[y * w + max(0, min(w - 1, x + i - r))] * g[i] }
                pb[y * w + x] = t
            }
        }
        for y in 0..<h {
            for x in 0..<w {
                var t: Float = 0
                for i in 0..<taps { t += pb[max(0, min(h - 1, y + i - r)) * w + x] * g[i] }
                pa[y * w + x] = t
            }
        }
        a = pa; b = pb
    }

    /// Flood from `s` over the pixels equal to `value`; `diag` also takes the corner neighbours.
    /// - Returns: how many pixels, and whether one of them is at the screen's edge
    private func flood(_ s: Int, _ value: UInt8, diag: Bool) -> (n: Int, edge: Bool) {
        var top = 1, n = 0, edge = false
        stack[0] = Int32(s)
        seen[s] = 1
        while top > 0 {
            top -= 1
            let p = Int(stack[top]), x = p % w, y = p / w
            n += 1
            if x == 0 || y == 0 || x == w - 1 || y == h - 1 { edge = true }
            for oy in -1...1 {
                for ox in -1...1 {
                    if ox == 0 && oy == 0 { continue }
                    if !diag && ox != 0 && oy != 0 { continue }
                    let nx = x + ox, ny = y + oy
                    if nx < 0 || ny < 0 || nx >= w || ny >= h { continue }
                    let q = ny * w + nx
                    if m[q] == value && seen[q] == 0 {   // each pixel goes on the stack once, so it never overflows
                        seen[q] = 1
                        stack[top] = Int32(q)
                        top += 1
                    }
                }
            }
        }
        return (n, edge)
    }
    private func countPieces(_ px: Double) -> Int {
        for i in 0..<seen.count { seen[i] = 0 }
        var count = 0, atEdge = false
        for s in 0..<m.count where m[s] == 1 && seen[s] == 0 {
            let f = flood(s, 1, diag: true)
            if Double(f.n) * px < 0.004 { continue }
            if f.edge {
                if !atEdge { atEdge = true; count += 1 }
            } else {
                count += 1
            }
        }
        return count
    }
    /// After `countPieces` (the body's pixels are marked seen already)
    private func countHoles(_ px: Double) -> Int {
        var count = 0
        for s in 0..<m.count where m[s] == 0 && seen[s] == 0 {
            let f = flood(s, 0, diag: false)
            if !f.edge && Double(f.n) * px >= 0.002 { count += 1 }
        }
        return count
    }

    /// How far each pixel is from the nearest body pixel of `q` (half-size pixels), two passes. Static: `d` is one of the object's own arrays.
    private static func distance(_ q: [UInt8], _ d: inout [Float], _ w: Int, _ h: Int) {
        let dg: Float = 1.4142
        for i in 0..<(w * h) { d[i] = q[i] == 1 ? 0 : 1e6 }
        for y in 0..<h {
            for x in 0..<w {
                let i = y * w + x
                var v: Float = d[i]
                if v == 0 { continue }
                if x > 0 { v = min(v, d[i - 1] + 1) }
                if y > 0 {
                    v = min(v, d[i - w] + 1)
                    if x > 0 { v = min(v, d[i - w - 1] + dg) }
                    if x < w - 1 { v = min(v, d[i - w + 1] + dg) }
                }
                d[i] = v
            }
        }
        for y in stride(from: h - 1, through: 0, by: -1) {
            for x in stride(from: w - 1, through: 0, by: -1) {
                let i = y * w + x
                var v: Float = d[i]
                if v == 0 { continue }
                if x < w - 1 { v = min(v, d[i + 1] + 1) }
                if y < h - 1 {
                    v = min(v, d[i + w] + 1)
                    if x < w - 1 { v = min(v, d[i + w + 1] + dg) }
                    if x > 0 { v = min(v, d[i + w - 1] + dg) }
                }
                d[i] = v
            }
        }
    }
}
