import Metal
import QuartzCore
import UIKit

/// v2.28 果凍皮 / v2.31 皮 A 清透 (多米 11-07): the body drawn as a lit, see-through jelly on a CAMetalLayer, under the eyes.
/// Port of the web's `jelRender`: the body's outline is painted into a 1× mask each frame, blurred small (half resolution) and
/// large (eighth resolution), and one lighting pass turns the three into the skin (JellySkin.metal). The flat layers stay for
/// the blue control and for phones without Metal.
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

    private let device: MTLDevice
    private let queue: MTLCommandQueue
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
        maskCtx = CGContext(data: nil, width: W, height: H, bitsPerComponent: 8, bytesPerRow: W, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue)
        maskCtx?.translateBy(x: 0, y: CGFloat(H)); maskCtx?.scaleBy(x: 1, y: -1)   // row 0 at the top, like the layer
    }

    /// v2.49: the pictures behind the body, back to front, each stretched over the whole view (the room is baked that way). Nothing is redrawn while `key` stays the same.
    /// An empty list (the plain blue sky, pictures missing) turns the water skin off: it falls back to the v2.48 skin.
    func setBackground(key: String, images: [CGImage]) {
        guard W > 0, H > 0 else { return }
        if key == bgKey { return }
        bgKey = key
        bgBase = nil; liveRect = .null
        guard !images.isEmpty else { bg = nil; return }
        let info = CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        guard let ctx = CGContext(data: nil, width: W, height: H, bitsPerComponent: 8, bytesPerRow: W * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: info), let data = ctx.data else { bg = nil; return }
        ctx.setFillColor(red: 0.78, green: 0.88, blue: 0.96, alpha: 1)
        ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))
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

    /// One frame. `path` is the body in screen points; `rpx` the body radius in points on screen; colours already tinted by mood and impression.
    /// v2.47 `round`: the outline is cut from the small blur instead of the mask (sharp corners round off, concave ones join); it scales that blur. 0 = the mask's own edge.
    func render(path: CGPath, rpx: Double, dents: [Dent], body: UIColor, shade: UIColor, line: UIColor, skin: Skin, round: Double = 0, water: Double = 0, refr: Double = 0.3, absorb: Double = 0.68,
                shine: Double = 1, opaque: Double = 0, extra: [CGPath] = [],   // v2.51: highlights × shine; the thick part hides the room; extra shapes (the strand, the small blob) join the mask
                hiOff: Bool = false, rimOff: Bool = false) {                    // v2.52 C4: the highlights, or the second highlight and the rim of light, left out (to read each layer's cost)
        guard let mask, let h1, let h2, let q1, let q2, let ctx = maskCtx, let data = ctx.data else { return }
        // 1 the mask
        ctx.setFillColor(gray: 0, alpha: 1)
        ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))
        ctx.setFillColor(gray: 1, alpha: 1)
        ctx.addPath(path)
        ctx.fillPath()
        for e in extra { ctx.addPath(e); ctx.fillPath() }
        mask.replace(region: MTLRegionMake2D(0, 0, W, H), mipmapLevel: 0, withBytes: data, bytesPerRow: ctx.bytesPerRow)
        guard let cmd = queue.makeCommandBuffer(), let drawable = layer.nextDrawable() else { return }
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
        blur(mask, h1, 1 / Float(h1.width), 0, s1); blur(h1, h2, 0, 1 / Float(h2.height), s1)
        blur(mask, q1, 1 / Float(q1.width), 0, s2); blur(q1, q2, 0, 1 / Float(q2.height), s2)
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
        u.append(SIMD4<Float>(skin.arc * hi, round > 0 ? 0.46 : 0, rimOff ? 0 : skin.wet * sh, 0))
        let wv: Float = bg != nil ? Float(max(0, min(1, water))) * min(1, skin.wet) : 0   // v2.49: no baked room, no water skin
        u.append(SIMD4<Float>(wv, Float(refr), Float(absorb), Float(max(0, min(1, opaque)))))
        let rp = MTLRenderPassDescriptor()
        rp.colorAttachments[0].texture = drawable.texture
        rp.colorAttachments[0].loadAction = .clear
        rp.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        rp.colorAttachments[0].storeAction = .store
        if let enc = cmd.makeRenderCommandEncoder(descriptor: rp) {
            enc.setRenderPipelineState(lightPSO)
            enc.setFragmentTexture(mask, index: 0); enc.setFragmentTexture(h2, index: 1); enc.setFragmentTexture(q2, index: 2); enc.setFragmentTexture(bg ?? mask, index: 3)
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
