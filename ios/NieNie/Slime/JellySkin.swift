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
    struct Skin { var kEdge, kCore, aEdge, aCore, amb, dif, glow, line, nk, shin, s0, s1, spec, sheen, arc: Float }
    /// The web's JSKINS: A clear (多米 11-07), B milky (what A becomes while the glitter clouds it)
    static let skinA = Skin(kEdge: 0.45, kCore: 0.42, aEdge: 0.52, aCore: 0.80, amb: 0.86, dif: 0.24, glow: 0.60, line: 0.38, nk: 0.95, shin: 320, s0: 0.42, s1: 0.66, spec: 0.85, sheen: 0.12, arc: 0.92)
    static let skinB = Skin(kEdge: 0.50, kCore: 0.16, aEdge: 0.86, aCore: 0.97, amb: 0.88, dif: 0.20, glow: 0.46, line: 0.26, nk: 0.90, shin: 320, s0: 0.42, s1: 0.68, spec: 0.80, sheen: 0.10, arc: 0.88)
    /// A toward B by `cloud`, a little brighter by `glow` (web: jelSkin)
    static func skin(cloud: Double, glow: Double) -> Skin {
        let a = skinA, b = skinB, c = Float(min(1, max(0, cloud))), g = Float(min(1, max(0, glow)))
        func m(_ x: Float, _ y: Float) -> Float { x + (y - x) * c }
        var o = Skin(kEdge: m(a.kEdge, b.kEdge), kCore: m(a.kCore, b.kCore), aEdge: m(a.aEdge, b.aEdge), aCore: m(a.aCore, b.aCore), amb: m(a.amb, b.amb), dif: m(a.dif, b.dif),
                     glow: m(a.glow, b.glow), line: m(a.line, b.line), nk: m(a.nk, b.nk), shin: m(a.shin, b.shin), s0: m(a.s0, b.s0), s1: m(a.s1, b.s1), spec: m(a.spec, b.spec),
                     sheen: m(a.sheen, b.sheen), arc: m(a.arc, b.arc))
        o.glow = min(1, o.glow + 0.5 * g); o.sheen += 0.1 * g; o.kEdge += 0.15 * g
        return o
    }

    private let device: MTLDevice
    private let queue: MTLCommandQueue
    private let blurPSO: MTLRenderPipelineState, lightPSO: MTLRenderPipelineState
    private let sampler: MTLSamplerState
    private var mask: MTLTexture?, h1: MTLTexture?, h2: MTLTexture?, q1: MTLTexture?, q2: MTLTexture?
    private var maskCtx: CGContext?
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

    /// One frame. `path` is the body in screen points; `rpx` the body radius in points on screen; colours already tinted by mood and impression.
    func render(path: CGPath, rpx: Double, dents: [Dent], body: UIColor, shade: UIColor, line: UIColor, skin: Skin) {
        guard let mask, let h1, let h2, let q1, let q2, let ctx = maskCtx, let data = ctx.data else { return }
        // 1 the mask
        ctx.setFillColor(gray: 0, alpha: 1)
        ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))
        ctx.setFillColor(gray: 1, alpha: 1)
        ctx.addPath(path)
        ctx.fillPath()
        mask.replace(region: MTLRegionMake2D(0, 0, W, H), mipmapLevel: 0, withBytes: data, bytesPerRow: ctx.bytesPerRow)
        guard let cmd = queue.makeCommandBuffer(), let drawable = layer.nextDrawable() else { return }
        // 2 the blurs: small for the edge, large for the inner shading
        let s1 = Float(max(0.6, rpx * 0.07 / 2)), s2 = Float(max(0.6, rpx * 0.42 / 8))
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
        u.reserveCapacity(15)
        u.append(SIMD4<Float>(Float(W), Float(H), Float(rpx), Float(min(6, dents.count))))
        for i in 0..<6 { let d = i < dents.count ? dents[i] : Dent(x: 0, y: 0, r: 1, d: 0); u.append(SIMD4<Float>(d.x, d.y, max(0.5, d.r), d.d)) }
        u.append(mix(bc, white, skin.kEdge)); u.append(mix(bc, sc, skin.kCore)); u.append(mix(sc, lc, 0.35)); u.append(mix(bc, white, 0.3))
        u.append(SIMD4<Float>(skin.aEdge, skin.aCore, skin.amb, skin.dif))
        u.append(SIMD4<Float>(skin.glow, skin.line, skin.nk, skin.shin))
        u.append(SIMD4<Float>(skin.s0, skin.s1, skin.spec, skin.sheen))
        u.append(SIMD4<Float>(skin.arc, 0, 0, 0))
        let rp = MTLRenderPassDescriptor()
        rp.colorAttachments[0].texture = drawable.texture
        rp.colorAttachments[0].loadAction = .clear
        rp.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        rp.colorAttachments[0].storeAction = .store
        if let enc = cmd.makeRenderCommandEncoder(descriptor: rp) {
            enc.setRenderPipelineState(lightPSO)
            enc.setFragmentTexture(mask, index: 0); enc.setFragmentTexture(h2, index: 1); enc.setFragmentTexture(q2, index: 2)
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
