import Metal
import QuartzCore
import UIKit

// v2.59 窗景 (多米 11-24: only what is outside the window changes; the original one stays, free, always there to go back to).
// The web splits each scene's SVG into layers (prototype/web/windows.js). `tools/export-windows-ios.py` writes those layers out as pictures and their
// timetables as windows.json; here they are drawn with Metal, each frame, into one picture the size of the window's hole. The phone never reads an SVG.

/// One of the twelve: what the desk shows, and the colour the day wall leans to
struct WindowDef {
    let id: String
    let set: Int            // 0 島上, 1 四季, 2 去不了的地方
    let name: String
    let line: String
    let only: Bool          // night only
    let day: [Double]?      // r, g, b, a, 0 to 1
    /// What is said when it is picked
    var said: String { name + "：" + line + (only ? "（只有夜晚）" : "") }
    var dayColor: UIColor? {
        guard let d = day, d.count >= 4, d[3] > 0 else { return nil }
        return UIColor(red: CGFloat(d[0]), green: CGFloat(d[1]), blue: CGFloat(d[2]), alpha: CGFloat(d[3]))
    }
}

struct WindowError: Error { let why: String }

/// A 2D matrix as six numbers, in the order the web (and the canvas) has them
struct WindowAff {
    var a = 1.0, b = 0.0, c = 0.0, d = 1.0, e = 0.0, f = 0.0
    /// self × n: n happens first
    func times(_ n: WindowAff) -> WindowAff {
        var o = WindowAff()
        o.a = a * n.a + c * n.b
        o.b = b * n.a + d * n.b
        o.c = a * n.c + c * n.d
        o.d = b * n.c + d * n.d
        o.e = a * n.e + c * n.f + e
        o.f = b * n.e + d * n.f + f
        return o
    }
    func apply(_ x: Double, _ y: Double) -> (x: Double, y: Double) {
        let px: Double = a * x + c * y + e
        let py: Double = b * x + d * y + f
        return (x: px, y: py)
    }
    /// nil when it flattens everything to a line or a point
    var inverse: WindowAff? {
        let det: Double = a * d - b * c
        guard abs(det) > 1e-12 else { return nil }
        var o = WindowAff()
        o.a = d / det
        o.b = -b / det
        o.c = -c / det
        o.d = a / det
        o.e = (c * f - d * e) / det
        o.f = (b * e - a * f) / det
        return o
    }
}

/// One SMIL timetable (web: winTrack, winEase)
struct WindowTrack {
    let dur: Double
    let begin: Double
    let keys: [Double]
    let vals: [[Double]]
    let ease: [[Double]]

    /// The value at T, always three numbers (missing ones 0); `n` is how many there really are
    func at(_ T: Double) -> (x: Double, y: Double, z: Double, n: Int) {
        let n: Int = vals.count
        guard n > 1 else { return Self.pack(vals.first ?? [], vals.first ?? [], 0) }
        var p: Double = (T - begin) / dur
        p -= p.rounded(.down)
        var i = 0
        while i < n - 2 && p >= keys[i + 1] { i += 1 }
        let d: Double = keys[i + 1] - keys[i]
        var u: Double = 1
        if d > 0 { u = min(1, max(0, (p - keys[i]) / d)) }
        if i < ease.count { u = Self.bezier(ease[i], u) }
        return Self.pack(vals[i], vals[i + 1], u)
    }
    private static func pack(_ a: [Double], _ b: [Double], _ u: Double) -> (x: Double, y: Double, z: Double, n: Int) {
        func m(_ k: Int) -> Double {
            let p0: Double = k < a.count ? a[k] : 0
            let p1: Double = k < b.count ? b[k] : 0
            return p0 + (p1 - p0) * u
        }
        return (x: m(0), y: m(1), z: m(2), n: max(a.count, b.count))
    }
    private static func bezier(_ e: [Double], _ x: Double) -> Double {
        func f(_ u: Double, _ p: Double, _ q: Double) -> Double {
            let v: Double = 1 - u
            let s1: Double = 3 * v * v * u * p
            let s2: Double = 3 * v * u * u * q
            let s3: Double = u * u * u
            return s1 + s2 + s3
        }
        var lo: Double = 0, hi: Double = 1
        for _ in 0..<18 {
            let m: Double = (lo + hi) / 2
            if f(m, e[0], e[2]) < x { lo = m } else { hi = m }
        }
        return f((lo + hi) / 2, e[1], e[3])
    }
}

/// One step of a layer's movement (web: winMat)
enum WindowOp {
    case fixed(WindowAff)
    case translate(WindowTrack)
    case scale(WindowTrack)
    case skewX(WindowTrack)
    case rotate(WindowTrack)

    func at(_ T: Double) -> WindowAff {
        var o = WindowAff()
        switch self {
        case .fixed(let m):
            return m
        case .translate(let tr):
            let v = tr.at(T)
            o.e = v.x; o.f = v.y
        case .scale(let tr):
            let v = tr.at(T)
            o.a = v.x; o.d = v.n > 1 ? v.y : v.x
        case .skewX(let tr):
            let v = tr.at(T)
            o.c = tan(v.x * Double.pi / 180)
        case .rotate(let tr):
            let v = tr.at(T)
            let r: Double = v.x * Double.pi / 180
            let co: Double = cos(r), si: Double = sin(r)
            o.a = co; o.b = si; o.c = -si; o.d = co
            o.e = v.y - co * v.y + si * v.z
            o.f = v.z - si * v.y - co * v.z
        }
        return o
    }
}

enum WindowAlpha {
    case fixed(Double)
    case moving(WindowTrack)
    func at(_ T: Double) -> Double {
        switch self {
        case .fixed(let v): return v
        case .moving(let tr): return tr.at(T).x
        }
    }
}

enum WindowBlend: Int { case over = 0, add, multiply, screen }

struct WindowClip { let n: Int; let x: Double; let y: Double; let r: Double }

struct WindowDash {
    let lines: [[Double]]     // x0, y0, x1, y1
    let color: [Double]       // r, g, b, a
    let width: Double
    let round: Bool
    let on: Double
    let off: Double
    let offset: WindowTrack
}

struct WindowItem {
    let image: String         // empty for a dash
    let box: [Double]         // bx, by, bw, bh, before any op
    let blend: WindowBlend
    let ops: [WindowOp]
    let alphas: [WindowAlpha]
    let clip: WindowClip?
    let dash: WindowDash?
}

/// windows.json, read once, the first time a window is asked for
final class WindowLibrary {
    static let shared: WindowLibrary? = WindowLibrary()
    static let setNames: [String] = ["島上", "四季", "去不了的地方"]
    let wins: [WindowDef]
    let w: Double
    let h: Double
    private let scenes: [String: Any]

    static var all: [WindowDef] { shared?.wins ?? [] }
    static func def(_ id: String) -> WindowDef? {
        guard !id.isEmpty else { return nil }
        return all.first { $0.id == id }
    }
    static func key(_ id: String, night: Bool) -> String { id + "|" + (night ? "night" : "day") }
    static func url(_ name: String, _ ext: String) -> URL? {
        if let u = Bundle.main.url(forResource: name, withExtension: ext) { return u }
        return Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "win")
    }

    private init?() {
        guard let u = WindowLibrary.url("windows", "json"), let data = try? Data(contentsOf: u),
              let any = try? JSONSerialization.jsonObject(with: data), let root = any as? [String: Any],
              let list = root["wins"] as? [[String: Any]], let sc = root["scenes"] as? [String: Any] else {
            NSLog("[windows] reason: windows.json missing or unreadable")
            return nil
        }
        var out: [WindowDef] = []
        for o in list {
            guard let id = o["id"] as? String, let name = o["name"] as? String else { continue }
            let set: Int = Int(WindowLibrary.num(o["set"]) ?? 0)
            let only: Bool = (o["only"] as? NSNumber)?.boolValue ?? false
            let line: String = (o["line"] as? String) ?? ""
            out.append(WindowDef(id: id, set: set, name: name, line: line, only: only, day: WindowLibrary.nums(o["day"])))
        }
        wins = out
        w = WindowLibrary.num(root["w"]) ?? 680
        h = WindowLibrary.num(root["h"]) ?? 828
        scenes = sc
    }

    private static func num(_ v: Any?) -> Double? { (v as? NSNumber)?.doubleValue }
    private static func nums(_ v: Any?) -> [Double]? {
        guard let a = v as? [NSNumber] else { return nil }
        return a.map { $0.doubleValue }
    }

    private static func track(_ v: Any?) throws -> WindowTrack {
        guard let o = v as? [String: Any], let dur = num(o["d"]), dur > 0, let raw = o["v"] as? [Any] else { throw WindowError(why: "track") }
        var vals: [[Double]] = []
        for r in raw {
            if let a = nums(r) { vals.append(a) } else if let x = num(r) { vals.append([x]) } else { throw WindowError(why: "track values") }
        }
        guard !vals.isEmpty else { throw WindowError(why: "empty track") }
        var keys: [Double] = nums(o["k"]) ?? []
        if keys.count != vals.count {
            let last: Double = Double(max(1, vals.count - 1))
            keys = vals.indices.map { Double($0) / last }
        }
        var ease: [[Double]] = []
        if let es = o["e"] as? [Any] {
            for e in es {
                guard let a = nums(e), a.count == 4 else { throw WindowError(why: "track ease") }
                ease.append(a)
            }
        }
        return WindowTrack(dur: dur, begin: num(o["b"]) ?? 0, keys: keys, vals: vals, ease: ease)
    }

    private static func op(_ v: Any) throws -> WindowOp {
        guard let o = v as? [String: Any], let k = o["k"] as? String else { throw WindowError(why: "op") }
        switch k {
        case "m":
            guard let m = nums(o["v"]), m.count == 6 else { throw WindowError(why: "op matrix") }
            return .fixed(WindowAff(a: m[0], b: m[1], c: m[2], d: m[3], e: m[4], f: m[5]))
        case "translate": return .translate(try track(o["t"]))
        case "scale": return .scale(try track(o["t"]))
        case "skewX": return .skewX(try track(o["t"]))
        case "rotate": return .rotate(try track(o["t"]))
        default: throw WindowError(why: "op " + k)
        }
    }

    private static func dash(_ v: Any) throws -> WindowDash {
        guard let o = v as? [String: Any], let raw = o["lines"] as? [Any], let c = nums(o["c"]), c.count >= 3,
              let wd = num(o["w"]), let p = nums(o["p"]), !p.isEmpty else { throw WindowError(why: "dash") }
        var lines: [[Double]] = []
        for l in raw {
            guard let a = nums(l), a.count == 4 else { throw WindowError(why: "dash line") }
            lines.append(a)
        }
        let on: Double = p[0]
        let off: Double = p.count > 1 ? p[1] : p[0]
        guard on > 0, off >= 0 else { throw WindowError(why: "dash pattern") }
        let color: [Double] = c.count > 3 ? c : c + [1.0]
        return WindowDash(lines: lines, color: color, width: wd, round: (o["cap"] as? String) == "round", on: on, off: off, offset: try track(o["t"]))
    }

    /// The layers of one scene, back to front
    func items(_ id: String, night: Bool) throws -> [WindowItem] {
        let key = WindowLibrary.key(id, night: night)
        guard let list = scenes[key] as? [[String: Any]], !list.isEmpty else { throw WindowError(why: "no scene " + key) }
        var out: [WindowItem] = []
        for o in list {
            var ops: [WindowOp] = []
            let rawOps: [Any] = (o["m"] as? [Any]) ?? []
            for m in rawOps { ops.append(try WindowLibrary.op(m)) }
            var al: [WindowAlpha] = []
            let rawAl: [Any] = (o["a"] as? [Any]) ?? []
            for a in rawAl {
                if let x = WindowLibrary.num(a) { al.append(.fixed(x)) } else { al.append(.moving(try WindowLibrary.track(a))) }
            }
            let blend: WindowBlend
            switch (o["o"] as? String) ?? "over" {
            case "over": blend = .over
            case "add": blend = .add
            case "multiply": blend = .multiply
            case "screen": blend = .screen
            default: throw WindowError(why: "blend in " + key)
            }
            var clip: WindowClip?
            if let c = o["c"] as? [String: Any] {
                guard let n = WindowLibrary.num(c["n"]), let x = WindowLibrary.num(c["x"]), let y = WindowLibrary.num(c["y"]), let r = WindowLibrary.num(c["r"]) else {
                    throw WindowError(why: "clip in " + key)
                }
                clip = WindowClip(n: Int(n), x: x, y: y, r: r)
            }
            if let d = o["d"], !(d is NSNull) {
                let ds = try WindowLibrary.dash(d)
                out.append(WindowItem(image: "", box: [0, 0, 0, 0], blend: blend, ops: ops, alphas: al, clip: clip, dash: ds))
                continue
            }
            guard let name = o["i"] as? String, let b = WindowLibrary.nums(o["b"]), b.count == 4 else { throw WindowError(why: "layer in " + key) }
            out.append(WindowItem(image: name, box: b, blend: blend, ops: ops, alphas: al, clip: clip, dash: nil))
        }
        return out
    }
}

/// One scene, ready to draw: its layers and a texture for each (several layers may share one)
final class WindowStage {
    let key: String
    let def: WindowDef
    let night: Bool
    let items: [WindowItem]
    let textures: [MTLTexture?]   // one per item, nil for a dash

    private init(key: String, def: WindowDef, night: Bool, items: [WindowItem], textures: [MTLTexture?]) {
        self.key = key; self.def = def; self.night = night; self.items = items; self.textures = textures
    }

    /// Off the main thread: the pictures are decoded and their mipmaps made here
    static func load(def: WindowDef, night: Bool, device: MTLDevice, queue: MTLCommandQueue) throws -> WindowStage {
        guard let lib = WindowLibrary.shared else { throw WindowError(why: "windows.json") }
        let items = try lib.items(def.id, night: night)
        var made: [String: MTLTexture] = [:]
        var textures: [MTLTexture?] = []
        for it in items {
            if it.dash != nil { textures.append(nil); continue }
            if let t = made[it.image] { textures.append(t); continue }
            let t: MTLTexture = try autoreleasepool { () throws -> MTLTexture in
                try WindowStage.texture(it.image, device)
            }
            made[it.image] = t
            textures.append(t)
        }
        guard let cmd = queue.makeCommandBuffer(), let blit = cmd.makeBlitCommandEncoder() else { throw WindowError(why: "mipmaps") }
        for t in made.values where t.mipmapLevelCount > 1 { blit.generateMipmaps(for: t) }
        blit.endEncoding()
        cmd.commit()
        cmd.waitUntilCompleted()
        return WindowStage(key: WindowLibrary.key(def.id, night: night), def: def, night: night, items: items, textures: textures)
    }

    private static func texture(_ name: String, _ device: MTLDevice) throws -> MTLTexture {
        guard let u = WindowLibrary.url(name, "webp"), let cg = UIImage(contentsOfFile: u.path)?.cgImage else { throw WindowError(why: "picture " + name) }
        let w = cg.width, h = cg.height
        let info = CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        guard w > 0, h > 0, let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: info),
              let data = ctx.data else { throw WindowError(why: "bitmap " + name) }
        let full = CGRect(x: 0, y: 0, width: w, height: h)
        ctx.clear(full)
        ctx.draw(cg, in: full)   // an unflipped bitmap context: memory row 0 is the picture's top row
        let d = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: w, height: h, mipmapped: true)
        d.usage = [.shaderRead]
        d.storageMode = .shared
        guard let t = device.makeTexture(descriptor: d) else { throw WindowError(why: "texture " + name) }
        t.replace(region: MTLRegionMake2D(0, 0, w, h), mipmapLevel: 0, withBytes: data, bytesPerRow: ctx.bytesPerRow)
        return t
    }
}

/// Draws a stage into one picture the size of the window's hole, shows it in a layer of its own, and hands it to the water skin to bend.
/// Main thread only, except the loading. It shares the skin's command queue, so the skin always sees this frame's picture.
final class WindowRenderer {
    let layer = CAMetalLayer()
    enum Request { case ready(WindowStage), waiting, failed(String) }

    private let device: MTLDevice
    private let queue: MTLCommandQueue
    private let quadPSO: [MTLRenderPipelineState]   // by WindowBlend
    private let dashPSO: MTLRenderPipelineState
    private let sampler: MTLSamplerState
    private let gate = DispatchSemaphore(value: 2)   // frames on the GPU at once: never wait for a drawable
    private let loadQueue = DispatchQueue(label: "nienie.windows", qos: .userInitiated)

    private var stages: [String: WindowStage] = [:]
    private var order: [String] = []                 // oldest first; two are kept (day and night of one window change over at once)
    private var loading: Set<String> = []
    private var failed: [String: String] = [:]
    private var wantedKey = ""

    private var rect = CGRect.zero                   // in view points, on whole pixels
    private var scale: CGFloat = 0
    private var tex: MTLTexture?                     // the window's picture, with mipmaps
    private var texKey = ""                          // the stage drawn into it, "" = nothing yet
    private var lastDraw: CFTimeInterval = 0
    private var shownFrames = 0
    private let t0: CFTimeInterval = CACurrentMediaTime()
    private var mixed: MTLTexture?                   // 1×, the whole view: the window's picture with the room over it

    init?(device: MTLDevice, queue: MTLCommandQueue) {
        guard let lib = device.makeDefaultLibrary(), let vs = lib.makeFunction(name: "winVertex"),
              let fq = lib.makeFunction(name: "winQuad"), let fd = lib.makeFunction(name: "winDash") else { return nil }
        func pso(_ fn: MTLFunction, _ blend: WindowBlend) -> MTLRenderPipelineState? {
            let d = MTLRenderPipelineDescriptor()
            d.vertexFunction = vs
            d.fragmentFunction = fn
            d.colorAttachments[0].pixelFormat = .bgra8Unorm
            d.colorAttachments[0].isBlendingEnabled = true
            d.colorAttachments[0].rgbBlendOperation = .add
            d.colorAttachments[0].alphaBlendOperation = .add
            d.colorAttachments[0].sourceAlphaBlendFactor = .one
            d.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
            let src: MTLBlendFactor = blend == .multiply ? .destinationColor : .one
            let dst: MTLBlendFactor
            switch blend {
            case .over, .multiply: dst = .oneMinusSourceAlpha
            case .add: dst = .one
            case .screen: dst = .oneMinusSourceColor
            }
            d.colorAttachments[0].sourceRGBBlendFactor = src
            d.colorAttachments[0].destinationRGBBlendFactor = dst
            return try? device.makeRenderPipelineState(descriptor: d)
        }
        guard let p0 = pso(fq, .over), let p1 = pso(fq, .add), let p2 = pso(fq, .multiply), let p3 = pso(fq, .screen), let pd = pso(fd, .over) else { return nil }
        let sd = MTLSamplerDescriptor()
        sd.minFilter = .linear; sd.magFilter = .linear; sd.mipFilter = .linear
        sd.sAddressMode = .clampToEdge; sd.tAddressMode = .clampToEdge
        guard let sm = device.makeSamplerState(descriptor: sd) else { return nil }
        self.device = device
        self.queue = queue
        quadPSO = [p0, p1, p2, p3]
        dashPSO = pd
        sampler = sm
        layer.device = device
        layer.pixelFormat = .bgra8Unorm
        layer.isOpaque = false          // nothing drawn yet: the sky behind shows
        layer.framebufferOnly = true
        layer.colorspace = CGColorSpace(name: CGColorSpace.sRGB)
        layer.isHidden = true
    }

    // MARK: loading

    /// The stage if it is ready; otherwise it starts loading
    func request(_ def: WindowDef, night: Bool) -> Request {
        let key = WindowLibrary.key(def.id, night: night)
        if key != wantedKey {
            wantedKey = key
            if let i = order.firstIndex(of: key) { order.remove(at: i); order.append(key) }
        }
        if let s = stages[key] { return .ready(s) }
        if let why = failed[key] { return .failed(why) }
        if !loading.contains(key) {
            loading.insert(key)
            let dev = device, q = queue
            loadQueue.async { [weak self] in
                var stage: WindowStage?
                var why = ""
                do {
                    stage = try WindowStage.load(def: def, night: night, device: dev, queue: q)
                } catch {
                    why = (error as? WindowError)?.why ?? "\(error)"
                }
                let result = stage, reason = why
                DispatchQueue.main.async { [weak self] in self?.loaded(key, result, reason) }
            }
        }
        return .waiting
    }

    private func loaded(_ key: String, _ stage: WindowStage?, _ why: String) {
        guard loading.remove(key) != nil else { return }   // cleared meanwhile: nobody wants it
        guard let stage else { failed[key] = why; return }
        stages[key] = stage
        order.removeAll { $0 == key }
        order.append(key)
        while order.count > 2 {
            guard let i = order.firstIndex(where: { $0 != wantedKey }) else { break }
            stages[order[i]] = nil
            order.remove(at: i)
        }
    }

    /// Another window was picked: a failed one may be tried again
    func forgetFailures() { failed = [:] }

    /// Back to the original window: nothing is kept
    func clear() {
        if stages.isEmpty && loading.isEmpty && failed.isEmpty && tex == nil && mixed == nil { return }
        stages = [:]; order = []; loading = []; failed = [:]; wantedKey = ""
        tex = nil; texKey = ""; mixed = nil; shownFrames = 0
        rect = .zero; scale = 0
    }

    // MARK: drawing

    /// Where the window's hole is, in view points; kept on whole pixels so the picture is not smeared
    func place(_ hole: CGRect, scale s: CGFloat) {
        guard s > 0, hole.width > 1, hole.height > 1 else { return }
        let x0: CGFloat = (hole.minX * s).rounded(.down) / s
        let y0: CGFloat = (hole.minY * s).rounded(.down) / s
        let x1: CGFloat = (hole.maxX * s).rounded(.up) / s
        let y1: CGFloat = (hole.maxY * s).rounded(.up) / s
        let r = CGRect(x: x0, y: y0, width: x1 - x0, height: y1 - y0)
        if r == rect && s == scale && tex != nil { return }
        rect = r; scale = s
        let w: Int = max(2, Int((r.width * s).rounded()))
        let h: Int = max(2, Int((r.height * s).rounded()))
        layer.frame = r
        layer.contentsScale = s
        layer.drawableSize = CGSize(width: w, height: h)
        let d = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: w, height: h, mipmapped: true)
        d.usage = [.renderTarget, .shaderRead]
        d.storageMode = .private
        tex = device.makeTexture(descriptor: d)
        texKey = ""
    }

    /// A few frames have been handed over, so the layer has its picture: what is behind it can go
    var settled: Bool { shownFrames > 3 }

    /// At most 60 times a second. `still` (Reduce Motion): the moment 0, drawn again only now and then (it heals itself after the background).
    func draw(_ stage: WindowStage, still: Bool) {
        guard let tex else { return }
        let now: CFTimeInterval = CACurrentMediaTime()
        if texKey == stage.key {
            let wait: CFTimeInterval = still && settled ? 1 : 1.0 / 60 - 0.003
            if now - lastDraw < wait { return }
        }
        if UIApplication.shared.applicationState == .background { return }
        guard gate.wait(timeout: .now()) == .success else { return }   // the GPU is behind: skip this frame
        guard let cmd = queue.makeCommandBuffer() else { gate.signal(); return }
        let g = gate
        cmd.addCompletedHandler { _ in g.signal() }
        lastDraw = now
        let T: Double = still ? 0 : now - t0
        let rp = MTLRenderPassDescriptor()
        rp.colorAttachments[0].texture = tex
        rp.colorAttachments[0].loadAction = .clear
        rp.colorAttachments[0].clearColor = MTLClearColor(red: 0.78, green: 0.88, blue: 0.96, alpha: 1)
        rp.colorAttachments[0].storeAction = .store
        if let enc = cmd.makeRenderCommandEncoder(descriptor: rp) {
            enc.setFragmentSamplerState(sampler, index: 0)
            let w = Double(tex.width), h = Double(tex.height)
            for (i, it) in stage.items.enumerated() { paint(it, stage.textures[i], T, w, h, enc) }
            enc.endEncoding()
        }
        if tex.mipmapLevelCount > 1, let blit = cmd.makeBlitCommandEncoder() {   // the skin looks at it three times smaller
            blit.generateMipmaps(for: tex)
            blit.endEncoding()
        }
        texKey = stage.key
        if let drawable = layer.nextDrawable() {
            let dp = MTLRenderPassDescriptor()
            dp.colorAttachments[0].texture = drawable.texture
            dp.colorAttachments[0].loadAction = .clear
            dp.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
            dp.colorAttachments[0].storeAction = .store
            if let enc = cmd.makeRenderCommandEncoder(descriptor: dp) {
                enc.setFragmentSamplerState(sampler, index: 0)
                picture(tex, SIMD4<Float>(-1, 1, 1, -1), enc)
                enc.endEncoding()
            }
            cmd.present(drawable)
            shownFrames += 1
        }
        cmd.commit()
    }

    /// For the skin: the window's picture where the hole is, the room (wall and things, the hole see-through) over it, 1× like the room. nil until a window has been drawn.
    func mix(into cmd: MTLCommandBuffer, room: MTLTexture) -> MTLTexture? {
        guard let tex, !texKey.isEmpty else { return nil }
        let W = room.width, H = room.height
        if mixed?.width != W || mixed?.height != H {
            let d = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: W, height: H, mipmapped: false)
            d.usage = [.renderTarget, .shaderRead]
            d.storageMode = .private
            mixed = device.makeTexture(descriptor: d)
        }
        guard let out = mixed else { return nil }
        let rp = MTLRenderPassDescriptor()
        rp.colorAttachments[0].texture = out
        rp.colorAttachments[0].loadAction = .clear
        rp.colorAttachments[0].clearColor = MTLClearColor(red: 0.78, green: 0.88, blue: 0.96, alpha: 1)
        rp.colorAttachments[0].storeAction = .store
        guard let enc = cmd.makeRenderCommandEncoder(descriptor: rp) else { return nil }
        enc.setFragmentSamplerState(sampler, index: 0)
        let fw = Double(W), fh = Double(H)
        let l: Double = Double(rect.minX) / fw * 2 - 1
        let r: Double = Double(rect.maxX) / fw * 2 - 1
        let t: Double = 1 - Double(rect.minY) / fh * 2
        let b: Double = 1 - Double(rect.maxY) / fh * 2
        picture(tex, SIMD4<Float>(Float(l), Float(t), Float(r), Float(b)), enc)
        picture(room, SIMD4<Float>(-1, 1, 1, -1), enc)
        enc.endEncoding()
        return out
    }

    /// A whole texture over a rectangle given in clip space: left, top, right, bottom
    private func picture(_ t: MTLTexture, _ e: SIMD4<Float>, _ enc: MTLRenderCommandEncoder) {
        var u: [SIMD4<Float>] = []
        u.reserveCapacity(6)
        u.append(SIMD4<Float>(e.x, e.y, 0, 0)); u.append(SIMD4<Float>(e.z, e.y, 0, 0))
        u.append(SIMD4<Float>(e.x, e.w, 0, 0)); u.append(SIMD4<Float>(e.z, e.w, 0, 0))
        u.append(SIMD4<Float>(1, 0, 0, 0)); u.append(SIMD4<Float>(0, 0, 0, 0))
        send(u, t, quadPSO[WindowBlend.over.rawValue], enc)
    }

    private func send(_ u: [SIMD4<Float>], _ t: MTLTexture?, _ pso: MTLRenderPipelineState, _ enc: MTLRenderCommandEncoder) {
        enc.setRenderPipelineState(pso)
        u.withUnsafeBytes { raw in
            guard let p = raw.baseAddress else { return }
            enc.setVertexBytes(p, length: raw.count, index: 0)
            enc.setFragmentBytes(p, length: raw.count, index: 0)
        }
        if let t { enc.setFragmentTexture(t, index: 0) }
        enc.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
    }

    private func paint(_ it: WindowItem, _ texture: MTLTexture?, _ T: Double, _ w: Double, _ h: Double, _ enc: MTLRenderCommandEncoder) {
        var alpha: Double = 1
        for a in it.alphas { alpha *= a.at(T) }
        if alpha < 0.004 { return }
        alpha = min(1, alpha)
        let uw: Double = WindowLibrary.shared?.w ?? 680
        let uh: Double = WindowLibrary.shared?.h ?? 828
        var m = WindowAff(a: w / uw, b: 0, c: 0, d: h / uh, e: 0, f: 0)   // design units → pixels
        var mc: WindowAff?
        for i in 0...it.ops.count {
            if let c = it.clip, c.n == i { mc = m }
            if i < it.ops.count { m = m.times(it.ops[i].at(T)) }
        }
        if let d = it.dash { strokes(d, m, alpha, T, w, h, enc); return }
        guard let texture else { return }
        let x0: Double = it.box[0], y0: Double = it.box[1]
        let x1: Double = x0 + it.box[2], y1: Double = y0 + it.box[3]
        var inv: WindowAff?
        if it.clip != nil {
            guard let i = mc?.inverse else { return }   // squeezed to nothing
            inv = i
        }
        var u: [SIMD4<Float>] = []
        u.reserveCapacity(6)
        var minX = Double.infinity, maxX = -Double.infinity, minY = Double.infinity, maxY = -Double.infinity
        for k in 0..<4 {
            let cx: Double = (k & 1) == 0 ? x0 : x1
            let cy: Double = k < 2 ? y0 : y1
            let p = m.apply(cx, cy)
            minX = min(minX, p.x); maxX = max(maxX, p.x)
            minY = min(minY, p.y); maxY = max(maxY, p.y)
            var qx: Double = 0, qy: Double = 0
            if let i = inv, let c = it.clip {
                let q = i.apply(p.x, p.y)
                qx = q.x - c.x; qy = q.y - c.y
            }
            let nx: Double = p.x / w * 2 - 1
            let ny: Double = 1 - p.y / h * 2
            u.append(SIMD4<Float>(Float(nx), Float(ny), Float(qx), Float(qy)))
        }
        if maxX <= 0 || minX >= w || maxY <= 0 || minY >= h { return }   // wholly outside the hole
        let radius: Double = it.clip?.r ?? 0
        u.append(SIMD4<Float>(Float(alpha), Float(radius), 0, 0))
        u.append(SIMD4<Float>(0, 0, 0, 0))
        send(u, texture, quadPSO[it.blend.rawValue], enc)
    }

    /// The waterfall's dashes; the pattern starts afresh on every line, as on a canvas
    private func strokes(_ d: WindowDash, _ m: WindowAff, _ alpha: Double, _ T: Double, _ w: Double, _ h: Double, _ enc: MTLRenderCommandEncoder) {
        let period: Double = d.on + d.off
        guard period > 0 else { return }
        var off: Double = d.offset.at(T).x.truncatingRemainder(dividingBy: period)
        if off < 0 { off += period }
        let hw: Double = d.width / 2
        let pad: Double = hw + 3
        let color = SIMD4<Float>(Float(d.color[0]), Float(d.color[1]), Float(d.color[2]), Float(d.color[3]))
        for l in d.lines {
            let dx: Double = l[2] - l[0], dy: Double = l[3] - l[1]
            let len: Double = (dx * dx + dy * dy).squareRoot()
            guard len > 0 else { continue }
            let tx: Double = dx / len, ty: Double = dy / len
            var start: Double = -off
            while start < len {
                let s: Double = max(0, start)
                let e: Double = min(len, start + d.on)
                start += period
                guard e > s else { continue }
                let part: Double = e - s
                var u: [SIMD4<Float>] = []
                u.reserveCapacity(6)
                for k in 0..<4 {
                    let a: Double = (k & 1) == 0 ? -pad : part + pad
                    let c: Double = k < 2 ? -pad : pad
                    let lx: Double = l[0] + tx * (s + a) - ty * c
                    let ly: Double = l[1] + ty * (s + a) + tx * c
                    let p = m.apply(lx, ly)
                    let nx: Double = p.x / w * 2 - 1
                    let ny: Double = 1 - p.y / h * 2
                    u.append(SIMD4<Float>(Float(nx), Float(ny), Float(a), Float(c)))
                }
                u.append(SIMD4<Float>(Float(alpha), Float(hw), Float(part), d.round ? 1 : 0))
                u.append(color)
                send(u, nil, dashPSO, enc)
            }
        }
    }
}
