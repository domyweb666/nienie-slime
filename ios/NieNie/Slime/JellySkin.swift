import Metal
import QuartzCore
import UIKit

/// v2.61 A1: one frame of the mesh skin on the CPU. Port of the web's `jelMeshMask` and `jelThick` (JELX.mode 9), same thresholds:
/// the display points (inside particles as they are, the ring's smoothed ¼ ½ ¼ like the outline), and where the body is thin a line of 0.12R along its edges,
/// so nothing is thinner than what the blurred mask can show. Every scratch buffer only grows; nothing is allocated a frame once it has.
final class SkinMesh {
    /// One keep-alive line: the ends in ab, the radius in r.x. Same layout as CapIn in JellySkin.metal (32 bytes)
    struct Cap { var ab: SIMD4<Float>; var r: SIMD4<Float> }
    static let lineW = 0.12      // web JELX.wmin: how wide the line is at full, in radii
    static let thinOn = 0.26     // thinner than this (radii) the line starts...
    static let thinSpan = 0.10   // ...and is full this much thinner
    private static let fanSteps = 48

    private(set) var n = 0                  // vertices the triangles use
    private(set) var fanN = 0               // vertices after those: the small blob as plain triangles
    private(set) var index: [UInt16] = []   // the triangles; goes to the GPU only when `rev` changes
    private(set) var rev = 0
    private(set) var capN = 0               // keep-alive lines, cut at the walls
    private(set) var lineN = 0              // after those: the strand's pieces, not cut
    private(set) var clipL = -Double.infinity, clipR = Double.infinity, clipB = Double.infinity   // the walls on screen
    private var radius = 0.0                // the body's radius on screen this frame
    var verts: UnsafeMutablePointer<SIMD2<Float>> { v.p }
    var caps: UnsafeMutablePointer<Cap> { cap.p }

    /// Memory that only grows
    private final class Scratch<T> {
        private(set) var p: UnsafeMutablePointer<T>
        private var room: Int
        init(_ count: Int) { room = count; p = UnsafeMutablePointer<T>.allocate(capacity: count) }
        deinit { p.deallocate() }
        /// The first `keep` elements survive a move
        func need(_ count: Int, keep: Int = 0) {
            guard count > room else { return }
            let c = count + count / 2, q = UnsafeMutablePointer<T>.allocate(capacity: c)
            if keep > 0 { UnsafeMutableRawPointer(q).copyMemory(from: UnsafeRawPointer(p), byteCount: keep * MemoryLayout<T>.stride) }
            p.deallocate()
            p = q; room = c
        }
    }
    private let v = Scratch<SIMD2<Float>>(1024)     // display points, screen
    private let ix = Scratch<SIMD2<Float>>(1024)    // the same, the ring pushed in by the line's radius (what the lines run through)
    private let rv = Scratch<SIMD2<Float>>(256)     // the ring's display points in ring order
    private let nrm = Scratch<SIMD2<Float>>(256)    // each ring edge's inward normal
    private let g = Scratch<Float>(256)             // each ring point's share of the line, 0...1
    private let cap = Scratch<Cap>(2048)

    // the mesh these were made for; kept to see when it has changed (a re-sample, a rebuild). Arrays that share storage compare at once
    private var tri: [Int] = [], ring: [Int] = [], edg: [Int32] = []
    private var near: [Int32] = []    // each particle's ring position: its own, or the nearest one in the rest shape
    private var third: [Int32] = []   // each ring edge's triangle's third particle, −1 = the edge is in no triangle

    private func rekey(_ src: SkinMeshSource, _ t: [Int], _ bnd: [Int], _ count: Int) -> Bool {
        tri = []; ring = []; n = 0
        let e: [Int] = src.skinEdg, rest = src.skinRest, nb = bnd.count
        guard count > 2, count < 65536, nb > 2, t.count > 2, t.count % 3 == 0, e.count % 2 == 0, rest.x.count == count, rest.y.count == count else { return false }
        for i in t where i < 0 || i >= count { return false }
        for i in e where i < 0 || i >= count { return false }
        for i in bnd where i < 0 || i >= count { return false }
        var at = [Int](repeating: -1, count: count)
        for k in 0..<nb { at[bnd[k]] = k }
        near = [Int32](repeating: 0, count: count)
        for i in 0..<count {
            if at[i] >= 0 { near[i] = Int32(at[i]); continue }
            var bd = Double.infinity, bk = 0
            for k in 0..<nb {
                let dx: Double = rest.x[bnd[k]] - rest.x[i], dy: Double = rest.y[bnd[k]] - rest.y[i], d: Double = dx * dx + dy * dy
                if d < bd { bd = d; bk = k }
            }
            near[i] = Int32(bk)
        }
        third = [Int32](repeating: -1, count: nb)
        var q = 0
        while q + 2 < t.count {
            for s in 0..<3 {
                let a: Int = t[q + s], b: Int = t[q + (s + 1) % 3], c: Int = t[q + (s + 2) % 3]
                let ka: Int = at[a], kb: Int = at[b]
                if ka < 0 || kb < 0 { continue }
                if kb == (ka + 1) % nb { third[ka] = Int32(c) } else if ka == (kb + 1) % nb { third[kb] = Int32(c) }
            }
            q += 3
        }
        index = t.map { UInt16($0) }
        edg = e.map { Int32($0) }
        v.need(count + Self.fanSteps * 3); ix.need(count)
        rv.need(nb); nrm.need(nb); g.need(nb)
        cap.need(e.count / 2 + 64)
        tri = t; ring = bnd; n = count
        rev += 1
        return true
    }

    /// This frame's points and lines. `outline` is the ring on screen (smoothed, in ring order); the rest goes x → x × zoom + ox. `R` is the radius on screen.
    /// - Returns: false when there is nothing to draw the mesh from (the outline path is drawn then)
    func update(_ src: SkinMeshSource, x: [Double], y: [Double], ring bnd: [Int], outline: [(x: Double, y: Double)], zoom: Double, ox: Double, oy: Double, R: Double) -> Bool {
        fanN = 0; capN = 0; lineN = 0
        let t: [Int] = src.skinTri, count = x.count, nb = bnd.count
        guard R > 0, zoom > 0, y.count == count, outline.count == nb else { return false }
        if count != n || t != tri || bnd != ring {
            guard rekey(src, t, bnd, count) else { return false }
        }
        radius = R
        let vp = v.p, ip = ix.p, rp = rv.p, np = nrm.p, gp = g.p, cp = cap.p
        for i in 0..<count {
            let sx: Double = x[i] * zoom + ox, sy: Double = y[i] * zoom + oy
            vp[i] = SIMD2<Float>(Float(sx), Float(sy))
        }
        for k in 0..<nb {
            let s = SIMD2<Float>(Float(outline[k].x), Float(outline[k].y))
            vp[bnd[k]] = s
            rp[k] = s
        }
        // inward normals: towards the third corner of the triangle each ring edge belongs to, so a flipped one still points into the flesh
        for k in 0..<nb {
            let q = Int(third[k])
            if q < 0 { np[k] = SIMD2<Float>(0, 0); continue }
            let a = rp[k], b = rp[k + 1 == nb ? 0 : k + 1], c = vp[q]
            let ex: Float = b.x - a.x, ey: Float = b.y - a.y, tx: Float = c.x - a.x, ty: Float = c.y - a.y
            let side: Float = ex * ty - ey * tx >= 0 ? 1 : -1
            let len: Float = (ex * ex + ey * ey).squareRoot(), l: Float = len > 0 ? len : 1
            np[k] = SIMD2<Float>(-ey / l * side, ex / l * side)
        }
        // how thick the body is behind each ring point: along its inward normal to the outline opposite (web jelThick)
        let Rf = Float(R), lim: Float = 0.3 * Rf, far: Float = (lim + 60) * (lim + 60)
        let on: Float = Float(Self.thinOn) * Rf, span: Float = Float(Self.thinSpan) * Rf
        for k in 0..<nb {
            let n0 = np[k], n1 = np[k == 0 ? nb - 1 : k - 1]
            let sx: Float = n0.x + n1.x, sy: Float = n0.y + n1.y, d: Float = (sx * sx + sy * sy).squareRoot()
            if d < 1e-4 { gp[k] = 1; continue }   // no normal: thickness 0
            let nx: Float = sx / d, ny: Float = sy / d, px: Float = rp[k].x, py: Float = rp[k].y
            var best: Float = lim
            for m in 0..<nb {
                let m1 = m + 1 == nb ? 0 : m + 1
                if m == k || m1 == k { continue }
                let ax: Float = rp[m].x - px, ay: Float = rp[m].y - py, bx: Float = rp[m1].x - px, by: Float = rp[m1].y - py
                let da: Float = ax * ax + ay * ay, db: Float = bx * bx + by * by
                if min(da, db) > far { continue }
                let ex: Float = bx - ax, ey: Float = by - ay, den: Float = nx * ey - ny * ex
                if abs(den) < 1e-9 { continue }
                let tt: Float = (ax * ey - ay * ex) / den, u: Float = (ax * ny - ay * nx) / den
                if tt > 0.5 && u >= 0 && u <= 1 && tt < best { best = tt }
            }
            gp[k] = max(0, min(1, (on - best) / span))
        }
        // the lines run one radius inside the outline, and one radius above the floor (cut in half by the sill they would be too thin again)
        let w = src.skinWalls
        clipL = w.l.isFinite ? w.l * zoom + ox : -Double.infinity
        clipR = w.r.isFinite ? w.r * zoom + ox : Double.infinity
        clipB = w.b.isFinite ? w.b * zoom + oy : Double.infinity
        let rr = Float(R * Self.lineW / 2)
        for i in 0..<count { ip[i] = vp[i] }
        for k in 0..<nb {
            let n0 = np[k], n1 = np[k == 0 ? nb - 1 : k - 1]
            let sx: Float = n0.x + n1.x, sy: Float = n0.y + n1.y, d: Float = (sx * sx + sy * sy).squareRoot()
            if d < 1e-4 { continue }
            let i = bnd[k], s = rp[k]
            ip[i] = SIMD2<Float>(s.x + sx / d * rr, s.y + sy / d * rr)
        }
        if clipB.isFinite {
            let yb: Float = Float(clipB) - rr
            for i in 0..<count where ip[i].y > yb { ip[i].y = yb }
        }
        var e = 0, c = 0
        while e + 1 < edg.count {
            let i = Int(edg[e]), j = Int(edg[e + 1])
            let rad: Float = max(gp[Int(near[i])], gp[Int(near[j])]) * rr
            if rad >= 0.05 {   // below that the web's shader throws it away
                cp[c] = Cap(ab: SIMD4<Float>(ip[i].x, ip[i].y, ip[j].x, ip[j].y), r: SIMD4<Float>(rad, 0, 0, 0))
                c += 1
            }
            e += 2
        }
        capN = c
        return true
    }

    /// v2.51's strand: one round-ended piece, screen points, `w` its full width. After `update`.
    func line(_ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, _ w: Double) {
        cap.need(capN + lineN + 1, keep: capN + lineN)
        cap.p[capN + lineN] = Cap(ab: SIMD4<Float>(Float(x0), Float(y0), Float(x1), Float(y1)), r: SIMD4<Float>(Float(w / 2), 0, 0, 0))
        lineN += 1
    }

    /// v2.51's small blob: an ellipse as plain triangles, screen points. After `update`, once a frame (room for it is made with the mesh).
    func ellipse(_ cx: Double, _ cy: Double, _ rx: Double, _ ry: Double) {
        let steps = Self.fanSteps, p = v.p + n
        let turn: Double = 2 * .pi / Double(steps)
        for s in 0..<steps {
            let a0: Double = Double(s) * turn, a1: Double = Double(s + 1) * turn
            p[3 * s] = SIMD2<Float>(Float(cx), Float(cy))
            p[3 * s + 1] = SIMD2<Float>(Float(cx + rx * cos(a0)), Float(cy + ry * sin(a0)))
            p[3 * s + 2] = SIMD2<Float>(Float(cx + rx * cos(a1)), Float(cy + ry * sin(a1)))
        }
        fanN = steps * 3
    }

    /// The same union as a path, for what is clipped to the body (the eyes, the blush, the filling, the glitter). The outline's winding number at a point is its
    /// upright triangles minus its flipped ones, so adding each flipped one twice the upright way leaves every covered point above zero (the fill is non-zero).
    /// Nothing flipped and nothing thin, it is `body` itself.
    func clip(_ body: CGPath) -> CGPath {
        let vp = v.p, ip = ix.p, gp = g.p, nb = ring.count
        let out = CGMutablePath()
        var any = false
        func at(_ x: Float, _ y: Float) -> CGPoint { CGPoint(x: CGFloat(x), y: CGFloat(y)) }
        var q = 0
        while q + 2 < index.count {
            let a = vp[Int(index[q])], b = vp[Int(index[q + 1])], c = vp[Int(index[q + 2])]
            q += 3
            let bx: Float = b.x - a.x, by: Float = b.y - a.y, cx: Float = c.x - a.x, cy: Float = c.y - a.y
            if bx * cy - by * cx > -0.5 { continue }   // twice its area in square points: upright, or too small to see
            any = true
            out.move(to: at(a.x, a.y))   // the upright way round, twice in one go
            out.addLine(to: at(c.x, c.y)); out.addLine(to: at(b.x, b.y)); out.addLine(to: at(a.x, a.y))
            out.addLine(to: at(c.x, c.y)); out.addLine(to: at(b.x, b.y))
            out.closeSubpath()
        }
        // the line along the outline only (on the web at most 100 px of 32000 of the inner edges' lines stuck out past it: drawn, but not in this path)
        let rr = Float(radius * Self.lineW / 2)
        for k in 0..<nb {
            let k1 = k + 1 == nb ? 0 : k + 1, r: Float = max(gp[k], gp[k1]) * rr
            if r < 0.5 { continue }
            let a = ip[ring[k]], b = ip[ring[k1]]
            let dx: Float = b.x - a.x, dy: Float = b.y - a.y, l: Float = (dx * dx + dy * dy).squareRoot()
            let ux: Float = l > 1e-5 ? dx / l * r : r, uy: Float = l > 1e-5 ? dy / l * r : 0
            any = true
            out.move(to: at(a.x + uy, a.y - ux))   // a six-sided capsule, wound like the body
            out.addLine(to: at(b.x + uy, b.y - ux)); out.addLine(to: at(b.x + ux, b.y + uy)); out.addLine(to: at(b.x - uy, b.y + ux))
            out.addLine(to: at(a.x - uy, a.y + ux)); out.addLine(to: at(a.x - ux, a.y - uy))
            out.closeSubpath()
        }
        if !any { return body }
        out.addPath(body)
        return out
    }
}

/// v2.28 果凍皮 / v2.31 皮 A 清透 (多米 11-07): the body drawn as a lit, see-through jelly on a CAMetalLayer, under the eyes.
/// Port of the web's `jelRender`: the body's outline is painted into a 1× mask each frame, blurred small (half resolution) and
/// large (eighth resolution), and one lighting pass turns the three into the skin (JellySkin.metal). The flat layers stay for
/// the blue control and for phones without Metal. v2.61 A1 (skinU): the mask is the union of the body's triangles instead, drawn by the GPU (SkinMesh).
final class JellySkin {
    let layer = CAMetalLayer()
    struct Dent { var x, y, r, d: Float }
    struct Skin { var kEdge, kCore, aEdge, aCore, amb, dif, glow, line, nk, shin, s0, s1, spec, sheen, arc: Float; var wet: Float = 0 }
    /// The web's JSKINS: A clear (多米 11-07), B milky (what A becomes while the glitter clouds it)
    static let skinA = Skin(kEdge: 0.45, kCore: 0.42, aEdge: 0.52, aCore: 0.80, amb: 0.86, dif: 0.24, glow: 0.60, line: 0.38, nk: 0.95, shin: 320, s0: 0.42, s1: 0.66, spec: 0.85, sheen: 0.12, arc: 0.92)
    /// v2.47 水潤 (多米 11-16: it should look full of water): A, clearer and brighter, with the shader's second highlight and rim of light. The web's JSKINS.W
    static let skinW = Skin(kEdge: 0.50, kCore: 0.30, aEdge: 0.44, aCore: 0.66, amb: 0.88, dif: 0.26, glow: 0.80, line: 0.34, nk: 1.05, shin: 260, s0: 0.34, s1: 0.60, spec: 0.96, sheen: 0.20, arc: 1, wet: 1)
    static let skinB = Skin(kEdge: 0.50, kCore: 0.16, aEdge: 0.86, aCore: 0.97, amb: 0.88, dif: 0.20, glow: 0.46, line: 0.26, nk: 0.90, shin: 320, s0: 0.42, s1: 0.68, spec: 0.80, sheen: 0.10, arc: 0.88)
    /// A toward B by `cloud`, a little brighter by `glow` (web: jelSkin)
    static func skin(cloud: Double, glow: Double, wet: Bool = false) -> Skin {
        let a = wet ? skinW : skinA, b = skinB, c = Float(min(1, max(0, cloud))), g = Float(min(1, max(0, glow)))
        func m(_ x: Float, _ y: Float) -> Float { x + (y - x) * c }
        var o = Skin(kEdge: m(a.kEdge, b.kEdge), kCore: m(a.kCore, b.kCore), aEdge: m(a.aEdge, b.aEdge), aCore: m(a.aCore, b.aCore), amb: m(a.amb, b.amb), dif: m(a.dif, b.dif),
                     glow: m(a.glow, b.glow), line: m(a.line, b.line), nk: m(a.nk, b.nk), shin: m(a.shin, b.shin), s0: m(a.s0, b.s0), s1: m(a.s1, b.s1), spec: m(a.spec, b.spec),
                     sheen: m(a.sheen, b.sheen), arc: m(a.arc, b.arc), wet: m(a.wet, b.wet))
        o.glow = min(1, o.glow + 0.5 * g); o.sheen += 0.1 * g; o.kEdge += 0.15 * g
        return o
    }

    let device: MTLDevice            // v2.59: the window scenes draw on the same queue, so the skin sees this frame's window
    let queue: MTLCommandQueue
    /// v2.59 窗景: with a window scene on, `bg` is the room with the hole see-through, and the window's picture is put behind it on the GPU each frame
    var windows: WindowRenderer?
    var windowOn = false
    private let blurPSO: MTLRenderPipelineState, lightPSO: MTLRenderPipelineState
    private let sampler: MTLSamplerState
    private var mask: MTLTexture?, h1: MTLTexture?, h2: MTLTexture?, q1: MTLTexture?, q2: MTLTexture?
    private var maskCtx: CGContext?
    private var bg: MTLTexture?, bgKey = ""   // v2.49: the room behind it (sky, wall, props), baked once a scene, for the water skin to bend
    /// v2.52 C3: something that moves behind the body, in view points; `x`, `y` is where its anchor (the middle of its width, `anchorY` down its height) sits, turned by `angle` about it
    struct Sprite { var image: CGImage; var x, y, w, h, anchorY, angle, alpha: Double }
    private var bgBase: CGContext?, bgLive: CGContext?   // the baked room kept as it was; and a copy the moving things are drawn into
    private var liveRect = CGRect.null                   // the part of the texture that differs from the baked room right now
    private var W = 0, H = 0
    // v2.61 A1 網格聯集的皮: the mask drawn by the GPU. Three sets of buffers, so a frame still being drawn is never written over; none is made a frame once big enough
    private struct Slot { var verts: MTLBuffer?; var caps: MTLBuffer? }
    private var triPSO: MTLRenderPipelineState?, capPSO: MTLRenderPipelineState?
    private var samples = 1
    private var maskG: MTLTexture?, maskMS: MTLTexture?   // the mask the mesh is drawn into; its multisampled half, which never leaves the tile memory
    private var slots = [Slot](repeating: Slot(verts: nil, caps: nil), count: 3), slot = 0
    private var indexBuf: MTLBuffer?, indexRev = -1, indexN = 0
    private let inflight = DispatchSemaphore(value: 3)
    /// Whether this phone can draw the mesh skin (false: the outline path)
    var meshReady: Bool { triPSO != nil && capPSO != nil && maskG != nil && (samples == 1 || maskMS != nil) }

    init?() {
        guard let dev = MTLCreateSystemDefaultDevice(), let q = dev.makeCommandQueue(), let lib = dev.makeDefaultLibrary(),
              let vs = lib.makeFunction(name: "jelVertex"), let fb = lib.makeFunction(name: "jelBlur"), let fl = lib.makeFunction(name: "jelLight") else { return nil }
        device = dev; queue = q
        let bd = MTLRenderPipelineDescriptor()
        bd.vertexFunction = vs; bd.fragmentFunction = fb
        bd.colorAttachments[0].pixelFormat = .r16Float
        let ld = MTLRenderPipelineDescriptor()
        ld.vertexFunction = vs; ld.fragmentFunction = fl
        ld.colorAttachments[0].pixelFormat = .bgra8Unorm
        guard let bp = try? dev.makeRenderPipelineState(descriptor: bd), let lp = try? dev.makeRenderPipelineState(descriptor: ld) else { return nil }
        blurPSO = bp; lightPSO = lp
        let sd = MTLSamplerDescriptor()
        sd.minFilter = .linear; sd.magFilter = .linear; sd.sAddressMode = .clampToEdge; sd.tAddressMode = .clampToEdge
        guard let sm = dev.makeSamplerState(descriptor: sd) else { return nil }
        sampler = sm
        // v2.61 A1: a library without these keeps the outline path
        let ns = dev.supportsTextureSampleCount(4) ? 4 : 1
        samples = ns
        func maxBlend(_ vn: String, _ fn: String) -> MTLRenderPipelineState? {
            guard let vf = lib.makeFunction(name: vn), let ff = lib.makeFunction(name: fn) else { return nil }
            let d = MTLRenderPipelineDescriptor()
            d.vertexFunction = vf; d.fragmentFunction = ff
            d.rasterSampleCount = ns
            d.colorAttachments[0].pixelFormat = .r8Unorm
            d.colorAttachments[0].isBlendingEnabled = true
            d.colorAttachments[0].rgbBlendOperation = .max
            d.colorAttachments[0].alphaBlendOperation = .max
            return try? dev.makeRenderPipelineState(descriptor: d)
        }
        triPSO = maxBlend("jelMeshVertex", "jelMeshFragment")
        capPSO = maxBlend("jelCapVertex", "jelCapFragment")
        layer.device = dev
        layer.pixelFormat = .bgra8Unorm
        layer.isOpaque = false
        layer.framebufferOnly = true
        layer.presentsWithTransaction = true   // the eyes are Core Animation layers in the same transaction: present with them, no lag between
    }

    /// Called from layoutSubviews: the mask at 1× points, the blurs at half and eighth, the drawable at the screen's scale.
    func resize(width: Int, height: Int, scale: CGFloat) {
        guard width > 0, height > 0 else { return }
        layer.contentsScale = scale
        layer.drawableSize = CGSize(width: CGFloat(width) * scale, height: CGFloat(height) * scale)
        if width == W && height == H { return }
        W = width; H = height
        bg = nil; bgKey = ""; bgBase = nil; bgLive = nil; liveRect = .null
        func tex(_ w: Int, _ h: Int, _ f: MTLPixelFormat, render: Bool) -> MTLTexture? {
            let d = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: f, width: max(2, w), height: max(2, h), mipmapped: false)
            d.usage = render ? [.renderTarget, .shaderRead] : [.shaderRead]
            d.storageMode = render ? .private : .shared
            return device.makeTexture(descriptor: d)
        }
        mask = tex(W, H, .r8Unorm, render: false)
        h1 = tex(W >> 1, H >> 1, .r16Float, render: true); h2 = tex(W >> 1, H >> 1, .r16Float, render: true)
        q1 = tex(W >> 3, H >> 3, .r16Float, render: true); q2 = tex(W >> 3, H >> 3, .r16Float, render: true)
        maskG = tex(W, H, .r8Unorm, render: true); maskMS = nil   // v2.61 A1
        if samples > 1 {
            let d = MTLTextureDescriptor()
            d.textureType = .type2DMultisample
            d.pixelFormat = .r8Unorm
            d.width = max(2, W); d.height = max(2, H)
            d.sampleCount = samples
            d.usage = [.renderTarget]
            #if targetEnvironment(simulator)
            d.storageMode = .private
            #else
            d.storageMode = .memoryless
            #endif
            maskMS = device.makeTexture(descriptor: d)
        }
        maskCtx = CGContext(data: nil, width: W, height: H, bitsPerComponent: 8, bytesPerRow: W, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue)
        maskCtx?.translateBy(x: 0, y: CGFloat(H)); maskCtx?.scaleBy(x: 1, y: -1)   // row 0 at the top, like the layer
    }

    /// v2.49: the pictures behind the body, back to front, each stretched over the whole view (the room is baked that way). Nothing is redrawn while `key` stays the same.
    /// An empty list (the plain blue sky, pictures missing) turns the water skin off: it falls back to the v2.48 skin.
    /// v2.59 `clear`: nothing under the pictures (the window's hole stays see-through).
    func setBackground(key: String, images: [CGImage], clear: Bool = false) {
        guard W > 0, H > 0 else { return }
        if key == bgKey { return }
        bgKey = key
        bgBase = nil; liveRect = .null
        guard !images.isEmpty else { bg = nil; return }
        let info = CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        guard let ctx = CGContext(data: nil, width: W, height: H, bitsPerComponent: 8, bytesPerRow: W * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: info), let data = ctx.data else { bg = nil; return }
        if clear { ctx.clear(CGRect(x: 0, y: 0, width: W, height: H)) } else {
            ctx.setFillColor(red: 0.78, green: 0.88, blue: 0.96, alpha: 1)
            ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))
        }
        for im in images { ctx.draw(im, in: CGRect(x: 0, y: 0, width: W, height: H)) }   // an unflipped bitmap context: memory row 0 is the picture's top row, like the mask
        let d = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: W, height: H, mipmapped: false)
        d.usage = [.shaderRead]; d.storageMode = .shared
        guard let tx = device.makeTexture(descriptor: d) else { bg = nil; return }
        tx.replace(region: MTLRegionMake2D(0, 0, W, H), mipmapLevel: 0, withBytes: data, bytesPerRow: ctx.bytesPerRow)
        bg = tx
        bgBase = ctx
    }

    /// v2.52 C3 (多米 11-22 決定 8): the things that move behind the body (the wind bell, the teru teru bozu, what it brought back from its walks) are drawn
    /// into the room the water skin bends, each frame, in the part around the body only. Before, the body bent a room without them, so behind it they vanished.
    /// `rect` is that part in view points. An empty list, or nothing near the body, puts the baked room back (once) and then costs nothing.
    /// - Returns: whether anything was drawn this frame
    @discardableResult
    func setDynamic(_ sprites: [Sprite], around rect: CGRect) -> Bool {
        guard let bg, let base = bgBase, let src = base.data else { return false }
        let full = CGRect(x: 0, y: 0, width: W, height: H)
        var want = CGRect.null
        var near: [Sprite] = []
        if !sprites.isEmpty && !rect.isNull {
            let r = rect.integral.intersection(full)
            if !r.isNull && r.width >= 1 && r.height >= 1 {
                for s in sprites where s.alpha > 0.01 {
                    let reach = hypot(s.w, s.h)   // turned any way about its anchor, it stays inside this
                    if CGRect(x: s.x - reach, y: s.y - reach, width: reach * 2, height: reach * 2).intersects(r) { near.append(s) }
                }
                if !near.isEmpty { want = r }
            }
        }
        if want.isNull && liveRect.isNull { return false }   // nothing to draw, nothing to put back
        let area = want.union(liveRect).integral.intersection(full)   // where the body is now, and where it was (that part goes back to the baked room)
        guard !area.isNull, area.width >= 1, area.height >= 1 else { liveRect = .null; return false }
        if bgLive == nil {
            let info = CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
            bgLive = CGContext(data: nil, width: W, height: H, bitsPerComponent: 8, bytesPerRow: base.bytesPerRow, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: info)
            bgLive?.translateBy(x: 0, y: CGFloat(H)); bgLive?.scaleBy(x: 1, y: -1)   // view coordinates: row 0 at the top
        }
        guard let live = bgLive, let dst = live.data, live.bytesPerRow == base.bytesPerRow else { return false }
        let x0 = Int(area.minX), y0 = Int(area.minY), w = Int(area.width), h = Int(area.height), bpr = base.bytesPerRow
        guard x0 >= 0, y0 >= 0, w > 0, h > 0, x0 + w <= W, y0 + h <= H else { return false }
        for y in y0..<(y0 + h) { memcpy(dst + y * bpr + x0 * 4, src + y * bpr + x0 * 4, w * 4) }   // the baked room under them
        if !near.isEmpty {
            live.saveGState()
            live.clip(to: area)
            for s in near {
                live.saveGState()
                live.translateBy(x: s.x, y: s.y); live.rotate(by: s.angle); live.scaleBy(x: 1, y: -1)   // the picture upright in a context whose y runs down
                live.setAlpha(s.alpha)
                live.draw(s.image, in: CGRect(x: -s.w / 2, y: -(1 - s.anchorY) * s.h, width: s.w, height: s.h))
                live.restoreGState()
            }
            live.restoreGState()
        }
        bg.replace(region: MTLRegionMake2D(x0, y0, w, h), mipmapLevel: 0, withBytes: dst + y0 * bpr + x0 * 4, bytesPerRow: bpr)
        liveRect = want
        return !near.isEmpty
    }

    /// v2.61 A1: the mesh into `target`: all the triangles, then the keep-alive lines (cut at the walls), then the strand's pieces (not cut). 4× multisampled, resolved at the end.
    /// - Returns: false when a buffer could not be made
    private func drawMesh(_ m: SkinMesh, into cmd: MTLCommandBuffer, target: MTLTexture) -> Bool {
        guard let triPSO, let capPSO, m.n > 0 else { return false }
        if indexBuf == nil || indexRev != m.rev {   // a re-sample or a rebuild: a new buffer (the old one may still be read)
            let made = m.index.withUnsafeBytes { (raw: UnsafeRawBufferPointer) -> MTLBuffer? in
                guard let p = raw.baseAddress, raw.count > 0 else { return nil }
                return device.makeBuffer(bytes: p, length: raw.count, options: .storageModeShared)
            }
            guard let b = made else { return false }
            indexBuf = b; indexRev = m.rev; indexN = m.index.count
        }
        guard let ib = indexBuf else { return false }
        func room(_ b: MTLBuffer?, _ bytes: Int) -> MTLBuffer? {
            if let b, b.length >= bytes { return b }
            return device.makeBuffer(length: bytes + bytes / 2, options: .storageModeShared)
        }
        slot = (slot + 1) % slots.count
        let nv = m.n + m.fanN, nc = m.capN + m.lineN
        let vBytes = nv * MemoryLayout<SIMD2<Float>>.stride, cBytes = nc * MemoryLayout<SkinMesh.Cap>.stride
        guard let vb = room(slots[slot].verts, vBytes), let cb = room(slots[slot].caps, max(64, cBytes)) else { return false }
        slots[slot].verts = vb; slots[slot].caps = cb
        vb.contents().copyMemory(from: UnsafeRawPointer(m.verts), byteCount: vBytes)
        if cBytes > 0 { cb.contents().copyMemory(from: UnsafeRawPointer(m.caps), byteCount: cBytes) }
        let rp = MTLRenderPassDescriptor()
        if let ms = maskMS {
            rp.colorAttachments[0].texture = ms
            rp.colorAttachments[0].resolveTexture = target
            rp.colorAttachments[0].storeAction = .multisampleResolve
        } else {
            rp.colorAttachments[0].texture = target
            rp.colorAttachments[0].storeAction = .store
        }
        rp.colorAttachments[0].loadAction = .clear
        rp.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        guard let enc = cmd.makeRenderCommandEncoder(descriptor: rp) else { return false }
        var u = SIMD4<Float>(2 / Float(W), 2 / Float(H), 0, 0)
        enc.setRenderPipelineState(triPSO)
        enc.setVertexBuffer(vb, offset: 0, index: 0)
        enc.setVertexBytes(&u, length: MemoryLayout<SIMD4<Float>>.size, index: 1)
        enc.drawIndexedPrimitives(type: .triangle, indexCount: indexN, indexType: .uint16, indexBuffer: ib, indexBufferOffset: 0)
        if m.fanN > 0 { enc.drawPrimitives(type: .triangle, vertexStart: m.n, vertexCount: m.fanN) }
        if nc > 0 {
            let fw = Double(target.width), fh = Double(target.height)
            enc.setRenderPipelineState(capPSO)
            enc.setVertexBuffer(cb, offset: 0, index: 0)
            // the walls on screen (web: the scissor around the lines), kept inside the texture
            let x0: Double = max(0, min(fw, m.clipL)).rounded(.down), x1: Double = max(0, min(fw, m.clipR)).rounded(.up)
            let y1: Double = max(1, min(fh, m.clipB + 1)).rounded(.up)
            if m.capN > 0 && x1 > x0 {
                enc.setScissorRect(MTLScissorRect(x: Int(x0), y: 0, width: Int(x1 - x0), height: Int(y1)))
                enc.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: m.capN)
            }
            if m.lineN > 0 {
                enc.setScissorRect(MTLScissorRect(x: 0, y: 0, width: target.width, height: target.height))
                enc.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: m.lineN, baseInstance: m.capN)
            }
        }
        enc.endEncoding()
        return true
    }

    /// One frame. `path` is the body in screen points; `rpx` the body radius in points on screen; colours already tinted by mood and impression.
    /// v2.47 `round`: the outline is cut from the small blur instead of the mask (sharp corners round off, concave ones join); it scales that blur. 0 = the mask's own edge.
    func render(path: CGPath, rpx: Double, dents: [Dent], body: UIColor, shade: UIColor, line: UIColor, skin: Skin, round: Double = 0, water: Double = 0, refr: Double = 0.3, absorb: Double = 0.68,
                shine: Double = 1, opaque: Double = 0, edgeClean: Double = 0, extra: [CGPath] = [],   // v2.51: highlights × shine; the thick part hides the room; extra shapes (the strand, the small blob) join the mask
                hiOff: Bool = false, rimOff: Bool = false,                      // v2.52 C4: the highlights, or the second highlight and the rim of light, left out (to read each layer's cost)
                mesh: SkinMesh? = nil) {                                        // v2.61 A1 skinU: the mask from the body's triangles; nil = from `path` and `extra`, as up to v2.60
        guard let mask, let h1, let h2, let q1, let q2, let ctx = maskCtx, let data = ctx.data else { return }
        // 1 the mask
        func paint() {
            ctx.setFillColor(gray: 0, alpha: 1)
            ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))
            ctx.setFillColor(gray: 1, alpha: 1)
            ctx.addPath(path)
            ctx.fillPath()
            for e in extra { ctx.addPath(e); ctx.fillPath() }
            mask.replace(region: MTLRegionMake2D(0, 0, W, H), mipmapLevel: 0, withBytes: data, bytesPerRow: ctx.bytesPerRow)
        }
        let onMesh = mesh != nil && meshReady
        if onMesh { inflight.wait() } else { paint() }
        guard let cmd = queue.makeCommandBuffer(), let drawable = layer.nextDrawable() else {
            if onMesh { inflight.signal() }
            return
        }
        var bodyMask: MTLTexture = mask   // what the blurs and the light read
        if onMesh {
            let done = inflight
            cmd.addCompletedHandler { _ in done.signal() }
            if let m = mesh, let g = maskG, drawMesh(m, into: cmd, target: g) { bodyMask = g } else { paint() }
        }
        var room: MTLTexture? = bg
        if windowOn, let b = bg { room = windows?.mix(into: cmd, room: b) }   // v2.59: nil until the window has been drawn once
        // 2 the blurs: small for the edge, large for the inner shading
        let s1 = Float(max(0.6, rpx * 0.07 / 2) * (round > 0 ? round : 1)), s2 = Float(max(0.6, rpx * 0.42 / 8))
        func blur(_ src: MTLTexture, _ dst: MTLTexture, _ dx: Float, _ dy: Float, _ s: Float) {
            let rp = MTLRenderPassDescriptor()
            rp.colorAttachments[0].texture = dst
            rp.colorAttachments[0].loadAction = .clear
            rp.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
            rp.colorAttachments[0].storeAction = .store
            guard let enc = cmd.makeRenderCommandEncoder(descriptor: rp) else { return }
            enc.setRenderPipelineState(blurPSO)
            enc.setFragmentTexture(src, index: 0)
            enc.setFragmentSamplerState(sampler, index: 0)
            var u = SIMD4<Float>(dx, dy, s, 0)
            enc.setFragmentBytes(&u, length: MemoryLayout<SIMD4<Float>>.size, index: 0)
            enc.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
            enc.endEncoding()
        }
        blur(bodyMask, h1, 1 / Float(h1.width), 0, s1); blur(h1, h2, 0, 1 / Float(h2.height), s1)
        blur(bodyMask, q1, 1 / Float(q1.width), 0, s2); blur(q1, q2, 0, 1 / Float(q2.height), s2)
        // 3 the light
        func rgb(_ c: UIColor) -> SIMD3<Float> {
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            c.getRed(&r, green: &g, blue: &b, alpha: &a)
            return SIMD3<Float>(Float(r), Float(g), Float(b))
        }
        func mix(_ a: SIMD3<Float>, _ b: SIMD3<Float>, _ k: Float) -> SIMD4<Float> { let m = a + (b - a) * k; return SIMD4<Float>(m.x, m.y, m.z, 1) }
        let bc = rgb(body), sc = rgb(shade), lc = rgb(line), white = SIMD3<Float>(1, 1, 1)
        var u: [SIMD4<Float>] = []
        u.reserveCapacity(16)
        u.append(SIMD4<Float>(Float(W), Float(H), Float(rpx), Float(min(6, dents.count))))
        for i in 0..<6 { let d = i < dents.count ? dents[i] : Dent(x: 0, y: 0, r: 1, d: 0); u.append(SIMD4<Float>(d.x, d.y, max(0.5, d.r), d.d)) }
        u.append(mix(bc, white, skin.kEdge)); u.append(mix(bc, sc, skin.kCore)); u.append(mix(sc, lc, 0.35)); u.append(mix(bc, white, 0.3))
        u.append(SIMD4<Float>(skin.aEdge, skin.aCore, skin.amb, skin.dif))
        u.append(SIMD4<Float>(skin.glow, skin.line, skin.nk, skin.shin))
        let sh = Float(max(0, min(1, shine))), hi: Float = hiOff ? 0 : sh
        u.append(SIMD4<Float>(skin.s0, skin.s1, skin.spec * hi, skin.sheen * hi))
        u.append(SIMD4<Float>(skin.arc * hi, round > 0 ? 0.46 : 0, rimOff ? 0 : skin.wet * sh, Float(edgeClean)))   // w: v2.61b edgeClean
        let wv: Float = room != nil ? Float(max(0, min(1, water))) * min(1, skin.wet) : 0   // v2.49: no baked room, no water skin
        u.append(SIMD4<Float>(wv, Float(refr), Float(absorb), Float(max(0, min(1, opaque)))))
        let rp = MTLRenderPassDescriptor()
        rp.colorAttachments[0].texture = drawable.texture
        rp.colorAttachments[0].loadAction = .clear
        rp.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        rp.colorAttachments[0].storeAction = .store
        if let enc = cmd.makeRenderCommandEncoder(descriptor: rp) {
            enc.setRenderPipelineState(lightPSO)
            enc.setFragmentTexture(bodyMask, index: 0); enc.setFragmentTexture(h2, index: 1); enc.setFragmentTexture(q2, index: 2); enc.setFragmentTexture(room ?? bodyMask, index: 3)
            enc.setFragmentSamplerState(sampler, index: 0)
            u.withUnsafeBytes { raw in enc.setFragmentBytes(raw.baseAddress!, length: raw.count, index: 0) }
            enc.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
            enc.endEncoding()
        }
        cmd.commit()
        cmd.waitUntilScheduled()
        drawable.present()
    }
}
