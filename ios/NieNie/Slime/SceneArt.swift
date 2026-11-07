import UIKit

/// v2.28 窗台 / v2.31 (多米 11-06, 11-07): the room behind it, baked once per view size and kind, in three pictures so the view can
/// put them behind or in front of the body: `sky` (the sky, clouds or stars, hills), `wall` (the wall with the window cut out and the
/// plate picture, drawn over the body while it is outside), `props` (the pebble dish, the succulent and the bowl; behind it on the sill,
/// in front of it behind the bowl or outside). `bowlFront` is the bowl's front half, over the body while it sits inside. Night tints
/// the pictures as on the web. Port of the web's `sceneFor`, `drawDeco`, `drawProps` (bowl only) and `bowlFront`.
/// `sprite` draws the small things it brings back from a walk (走路: stone, leaf, petal, acorn, cap, feather), port of `walkSprite`.
enum SceneArt {
    struct Images { let sky: UIImage; let wall: UIImage; let props: UIImage; let bowlFront: UIImage }
    private static var cache: [String: Images] = [:]
    private static var sprites: [String: UIImage] = [:]
    private static let night = UIColor(red: 38 / 255, green: 42 / 255, blue: 92 / 255, alpha: 0.62)

    private static func asset(_ name: String) -> UIImage? {
        if let u = Bundle.main.url(forResource: name, withExtension: "webp"), let im = UIImage(contentsOfFile: u.path) { return im }
        return UIImage(named: name)
    }

    private static func format(scale: CGFloat = 0) -> UIGraphicsImageRendererFormat {
        let f = UIGraphicsImageRendererFormat()
        f.opaque = false
        if scale > 0 { f.scale = scale }
        return f
    }

    /// The picture with the night tint over its opaque pixels only (web: source-atop).
    private static func tinted(_ im: UIImage, _ on: Bool) -> UIImage {
        guard on else { return im }
        return UIGraphicsImageRenderer(size: im.size, format: format(scale: im.scale)).image { c in
            im.draw(at: .zero)
            c.cgContext.setBlendMode(.sourceAtop)
            night.setFill()
            c.cgContext.fill(CGRect(origin: .zero, size: im.size))
        }
    }

    /// kind 1 = day, 2 = night. nil when the pictures are missing from the bundle.
    static func make(kind: Int, size: CGSize, g: SlimeRig.SillGeo) -> Images? {
        let key = "\(kind)|\(size.width)|\(size.height)"
        if let c = cache[key] { return c }
        guard let plate = asset("scene-plate"), let bowl = asset("scene-bowl"), let succ = asset("scene-succ"), let peb = asset("scene-peb") else { return nil }
        let isNight = kind == 2
        let W = Double(size.width), H = Double(size.height)
        let s = min(W / 860, H / 1130), off = H * 0.72 - 1177 * s, ox = (W - 992 * s) / 2
        let gx = ox + 156 * s, gy = off + 304 * s, gw = 680 * s, gh = 828 * s
        let win = CGRect(x: gx, y: gy, width: gw, height: gh)
        let full = CGRect(origin: .zero, size: size)
        let cs = CGColorSpaceCreateDeviceRGB()

        // the sky in the window: a gradient, clouds by day, stars and a moon by night, hills
        let sky = UIGraphicsImageRenderer(size: size, format: format()).image { c in
            let ctx = c.cgContext
            let top = isNight ? UIColor(hex: 0x141B3D) : UIColor(hex: 0x9CCBF0)
            let bot = isNight ? UIColor(hex: 0x2F3A6B) : UIColor(hex: 0xDCEEF8)
            if let grad = CGGradient(colorsSpace: cs, colors: [top.cgColor, bot.cgColor] as CFArray, locations: [0, 1]) {
                ctx.saveGState()
                ctx.clip(to: win)
                ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: gy), end: CGPoint(x: 0, y: gy + gh), options: [])
                ctx.restoreGState()
            }
            if isNight {
                UIColor(white: 1, alpha: 0.85).setFill()
                var q: UInt64 = 7
                func rnd() -> Double { q = (q * 16807) % 2147483647; return Double(q) / 2147483647 }
                for _ in 0..<46 {
                    let x = gx + rnd() * gw, y = gy + rnd() * gh * 0.8, r = 0.5 + rnd() * 1.1
                    ctx.fillEllipse(in: CGRect(x: x - r, y: y - r, width: 2 * r, height: 2 * r))
                }
                UIColor(hex: 0xF6EFC8).setFill()
                let mr = gw * 0.075
                ctx.fillEllipse(in: CGRect(x: gx + gw * 0.74 - mr, y: gy + gh * 0.2 - mr, width: 2 * mr, height: 2 * mr))
                UIColor(hex: 0x141B3D).setFill()
                let mr2 = gw * 0.068
                ctx.fillEllipse(in: CGRect(x: gx + gw * 0.70 - mr2, y: gy + gh * 0.185 - mr2, width: 2 * mr2, height: 2 * mr2))
            } else {
                UIColor(white: 1, alpha: 0.92).setFill()
                let clouds: [(Double, Double, Double)] = [(0.26, 0.24, 1), (0.72, 0.14, 0.8), (0.82, 0.5, 1.15), (0.3, 0.62, 0.7)]
                let puffs: [(Double, Double, Double)] = [(-1.1, 0.2, 0.62), (-0.3, -0.25, 0.9), (0.6, -0.05, 0.75), (1.3, 0.25, 0.5)]
                for (cx, cy, r) in clouds {
                    let u = gw * 0.1 * r, X0 = gx + gw * cx, Y0 = gy + gh * cy
                    for (dx, dy, rr) in puffs {
                        let rad = rr * u
                        ctx.fillEllipse(in: CGRect(x: X0 + dx * u - rad, y: Y0 + dy * u - rad, width: 2 * rad, height: 2 * rad))
                    }
                    ctx.fill(CGRect(x: X0 - u * 1.6, y: Y0 + u * 0.1, width: u * 3.3, height: u * 0.62))
                }
            }
            let hillColor = isNight ? UIColor(red: 30 / 255, green: 40 / 255, blue: 80 / 255, alpha: 0.9) : UIColor(red: 120 / 255, green: 165 / 255, blue: 150 / 255, alpha: 0.45)
            hillColor.setFill()
            let hills = UIBezierPath()
            hills.move(to: CGPoint(x: gx, y: gy + gh))
            for i in 0...40 {
                let qq = Double(i) / 40
                hills.addLine(to: CGPoint(x: gx + gw * qq, y: gy + gh * (0.9 - 0.035 * sin(qq * 9) - 0.02 * sin(qq * 21))))
            }
            hills.addLine(to: CGPoint(x: gx + gw, y: gy + gh))
            hills.close()
            hills.fill()
        }

        // the room: wall colour, the window cut out, the plate picture (sill and frame) on top; tinted at night
        let wall = UIGraphicsImageRenderer(size: size, format: format()).image { c in
            let ctx = c.cgContext
            UIColor(red: 0xF2 / 255, green: 0xE7 / 255, blue: 0xDC / 255, alpha: 1).setFill()
            ctx.fill(full)
            ctx.clear(win)
            plate.draw(in: CGRect(x: ox, y: off, width: 992 * s, height: 1586 * s))
            if isNight { ctx.setBlendMode(.sourceAtop); night.setFill(); ctx.fill(full) }
        }

        // the pebble dish and the succulent on the sill's ends, the bowl in the middle (v2.31: pictures only, nothing to push)
        let props = UIGraphicsImageRenderer(size: size, format: format()).image { c in
            let ctx = c.cgContext
            let U = g.U, fl = g.fl
            func shadow(_ x: Double, _ y: Double, _ rx: Double, _ ry: Double) {
                let c0 = UIColor(red: 120 / 255, green: 70 / 255, blue: 40 / 255, alpha: 0.28).cgColor
                let c1 = UIColor(red: 120 / 255, green: 70 / 255, blue: 40 / 255, alpha: 0).cgColor
                guard let gr = CGGradient(colorsSpace: cs, colors: [c0, c1] as CFArray, locations: [0, 1]) else { return }
                ctx.saveGState()
                ctx.translateBy(x: x, y: y)
                ctx.scaleBy(x: rx, y: ry)
                ctx.drawRadialGradient(gr, startCenter: .zero, startRadius: 0, endCenter: .zero, endRadius: 1, options: [])
                ctx.restoreGState()
            }
            let pebW = 76 * U, pebH = pebW * 159 / 240, pebX = g.l + pebW / 2 + 2
            shadow(pebX, fl - 2, pebW * 0.52, 11 * U)
            tinted(peb, isNight).draw(in: CGRect(x: pebX - pebW / 2, y: fl - pebH, width: pebW, height: pebH))
            let sucW = 70 * U, sucH = sucW * 300 / 220, sucX = g.r - sucW / 2 - 2
            shadow(sucX, fl - 2, sucW * 0.52, 11 * U)
            tinted(succ, isNight).draw(in: CGRect(x: sucX - sucW / 2, y: fl - sucH, width: sucW, height: sucH))
            shadow(g.bx, fl - 2, g.bw * 0.52, 11 * U)
            tinted(bowl, isNight).draw(in: CGRect(x: g.bx - g.bw / 2, y: g.by, width: g.bw, height: g.bh))
        }

        // the bowl's front half: the picture with its inside and everything above the rim cut away
        let bs = bowl.size
        let front = UIGraphicsImageRenderer(size: bs, format: format(scale: bowl.scale)).image { c in
            let ctx = c.cgContext
            bowl.draw(at: .zero)
            ctx.setBlendMode(.clear)
            let ey = bs.height * 0.308, rx = bs.width * 0.424, ry = bs.height * 0.26
            ctx.fillEllipse(in: CGRect(x: bs.width / 2 - rx, y: ey - ry, width: 2 * rx, height: 2 * ry))
            ctx.fill(CGRect(x: 0, y: 0, width: bs.width, height: ey))
            if isNight { ctx.setBlendMode(.sourceAtop); night.setFill(); ctx.fill(CGRect(origin: .zero, size: bs)) }
        }
        let out = Images(sky: sky, wall: wall, props: props, bowlFront: front)
        cache[key] = out
        return out
    }

    // MARK: - 走路: the small things (drawn by code as placeholders, assets later), 96×96, drawn about the centre

    static func sprite(_ kind: String, night: Bool) -> UIImage {
        let key = kind + (night ? "n" : "")
        if let im = sprites[key] { return im }
        let size = CGSize(width: 96, height: 96)
        let im = UIGraphicsImageRenderer(size: size, format: format(scale: 2)).image { c in
            let ctx = c.cgContext
            ctx.translateBy(x: 48, y: 48)
            ctx.setLineWidth(3); ctx.setLineJoin(.round); ctx.setLineCap(.round)
            let cs = CGColorSpaceCreateDeviceRGB()
            func fill(_ p: UIBezierPath, _ a: UInt32, _ b: UInt32, line: UInt32) {
                ctx.saveGState()
                ctx.addPath(p.cgPath); ctx.clip()
                if let gr = CGGradient(colorsSpace: cs, colors: [UIColor(hex: a).cgColor, UIColor(hex: b).cgColor] as CFArray, locations: [0, 1]) {
                    ctx.drawLinearGradient(gr, start: CGPoint(x: -20, y: -30), end: CGPoint(x: 20, y: 30), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
                }
                ctx.restoreGState()
                ctx.setStrokeColor(UIColor(hex: line).cgColor)
                ctx.addPath(p.cgPath); ctx.strokePath()
            }
            func stroke(_ p: UIBezierPath, _ line: UInt32) { ctx.setStrokeColor(UIColor(hex: line).cgColor); ctx.addPath(p.cgPath); ctx.strokePath() }
            switch kind {
            case "stone":
                let p = UIBezierPath(ovalIn: CGRect(x: -36, y: -23, width: 72, height: 54))
                p.apply(CGAffineTransform(rotationAngle: -0.12))
                fill(p, 0xC9C2B6, 0x8D8578, line: 0x6E675C)
                ctx.setFillColor(UIColor(white: 1, alpha: 0.4).cgColor)
                let hi = UIBezierPath(ovalIn: CGRect(x: -11, y: -5, width: 22, height: 10))
                hi.apply(CGAffineTransform(rotationAngle: -0.4)); hi.apply(CGAffineTransform(translationX: -12, y: -7))
                ctx.addPath(hi.cgPath); ctx.fillPath()
            case "leaf":
                let p = UIBezierPath()
                p.move(to: CGPoint(x: -38, y: 24))
                p.addCurve(to: CGPoint(x: 38, y: -32), controlPoint1: CGPoint(x: -30, y: -26), controlPoint2: CGPoint(x: 10, y: -38))
                p.addCurve(to: CGPoint(x: -38, y: 24), controlPoint1: CGPoint(x: 36, y: 0), controlPoint2: CGPoint(x: 8, y: 34))
                fill(p, 0xA6C86B, 0x5F9142, line: 0x467031)
                let v = UIBezierPath(); v.move(to: CGPoint(x: -38, y: 24)); v.addQuadCurve(to: CGPoint(x: 28, y: -24), controlPoint: CGPoint(x: -4, y: 0))
                stroke(v, 0x467031)
            case "petal":
                let p = UIBezierPath()
                p.move(to: CGPoint(x: 0, y: 36))
                p.addCurve(to: CGPoint(x: -6, y: -36), controlPoint1: CGPoint(x: -38, y: 14), controlPoint2: CGPoint(x: -30, y: -26))
                p.addQuadCurve(to: CGPoint(x: 6, y: -36), controlPoint: CGPoint(x: 0, y: -28))
                p.addCurve(to: CGPoint(x: 0, y: 36), controlPoint1: CGPoint(x: 30, y: -26), controlPoint2: CGPoint(x: 38, y: 14))
                fill(p, 0xFFD9E2, 0xF29AB2, line: 0xD97A96)
            case "acorn":
                let p = UIBezierPath()
                p.move(to: CGPoint(x: -24, y: -6))
                p.addCurve(to: CGPoint(x: 0, y: 38), controlPoint1: CGPoint(x: -24, y: 20), controlPoint2: CGPoint(x: -8, y: 32))
                p.addCurve(to: CGPoint(x: 24, y: -6), controlPoint1: CGPoint(x: 8, y: 32), controlPoint2: CGPoint(x: 24, y: 20))
                p.close()
                fill(p, 0xC98F4E, 0x8F5A27, line: 0x6D431C)
                let cap = UIBezierPath(ovalIn: CGRect(x: -29, y: -27, width: 58, height: 30))
                fill(cap, 0xA57A4A, 0x6F4C2A, line: 0x6D431C)
                let stem = UIBezierPath(); stem.move(to: CGPoint(x: 0, y: -26)); stem.addLine(to: CGPoint(x: 2, y: -37))
                stroke(stem, 0x6D431C)
            case "cap":
                let p = UIBezierPath()
                for i in 0..<24 {
                    let a = Double(i) / 24 * .pi * 2, r: Double = i % 2 == 1 ? 32 : 37
                    let pt = CGPoint(x: cos(a) * r, y: sin(a) * r)
                    if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                }
                p.close()
                fill(p, 0xEE7A62, 0xC44A3C, line: 0x993526)
                ctx.setFillColor(UIColor(white: 1, alpha: 0.28).cgColor)
                ctx.fillEllipse(in: CGRect(x: -22, y: -22, width: 44, height: 44))
            default:   // feather
                let p = UIBezierPath()
                p.move(to: CGPoint(x: -34, y: 30))
                p.addCurve(to: CGPoint(x: 34, y: -36), controlPoint1: CGPoint(x: -30, y: -10), controlPoint2: CGPoint(x: 4, y: -34))
                p.addCurve(to: CGPoint(x: -22, y: 30), controlPoint1: CGPoint(x: 34, y: -6), controlPoint2: CGPoint(x: 8, y: 24))
                p.close()
                fill(p, 0xFFFAF0, 0xDED3C0, line: 0xB8AB94)
                let v = UIBezierPath(); v.move(to: CGPoint(x: -40, y: 38)); v.addQuadCurve(to: CGPoint(x: 26, y: -28), controlPoint: CGPoint(x: -6, y: 0))
                stroke(v, 0xB8AB94)
            }
            if night {
                ctx.translateBy(x: -48, y: -48)
                ctx.setBlendMode(.sourceAtop)
                Self.night.setFill()   // the parameter shadows the colour
                ctx.fill(CGRect(origin: .zero, size: size))
            }
        }
        sprites[key] = im
        return im
    }
}
