import Foundation
// Linux command-line harness for the rig (type-checks and runs the Foundation-only parts of the iOS app).
// usage: harness fuzz <first> <last> [key=value ...] | flow | eff
let args = CommandLine.arguments
func apply(_ p: inout FeelParams, _ kv: [String]) {
    for s in kv {
        let a = s.split(separator: "="); guard a.count == 2, let v = Double(a[1]) else { continue }
        switch a[0] {
        case "strand": p.strand = v
        case "seed": p.seed = v
        case "noFlip": p.noFlip = v
        case "dens": p.dens = v
        case "strandAt": p.strandAt = v
        case "sillCap": p.sillCap = v
        case "lump": p.lump = v
        case "tugEdge": p.tugEdge = v
        case "split": p.split = v
        case "edgeCling": p.edgeCling = v
        case "flow": p.flow = v
        case "maxPull": p.maxPull = v
        case "life2": p.life2 = v
        case "endless": p.endless = v
        case "remesh": p.remesh = v
        case "rateK": p.rateK = v
        case "slide": p.slide = v
        case "capSlip": p.capSlip = v
        case "pullCreep": p.pullCreep = v
        case "frameCling": p.frameCling = v
        case "creep": p.creep = v
        case "grey": if v >= 0.5 { p.greyBox() }
        default: print("unknown key \(a[0])")
        }
    }
}
if args.count >= 4, args[1] == "fuzz" {
    var p = SlimeMaterial.clay.defaults
    if !args.contains("--plain") { SlimeKind.taro.apply(&p) }
    apply(&p, Array(args.dropFirst(4)).filter { !$0.hasPrefix("--") })
    let r = SlimeFuzz.run(seeds: Array(Int(args[2])!...Int(args[3])!), params: p, width: 393, height: 852)
    print(r.summary.text)
    let s = r.summary
    print("JSON {\"n\":\(s.n),\"flipFrPct\":\(String(format: "%.1f", s.flipFramePct)),\"flipMaxAll\":\(s.flipMaxAll),\"strainMax\":\(String(format: "%.1f", s.strainMax)),\"qStrainMax\":\(String(format: "%.1f", s.memStrainMax)),\"jerkHoldMax\":\(String(format: "%.1f", s.jerkHoldMax)),\"jerkHoldMeanAvg\":\(String(format: "%.2f", s.jerkHoldMeanAvg)),\"endSharpMax\":\(String(format: "%.0f", s.endSharpMax)),\"endSpikeTrials\":\(s.endSpikeTrials),\"endFlipTrials\":\(s.endFlipTrials),\"qFlipTrials\":\(s.memFlipTrials),\"xTrials\":\(s.crossTrials),\"nan\":\(s.nan)}")
    if args.contains("--trials") { for t in r.trials { print(t.seed, t.frames, t.flipFrames, t.flipMax, String(format: "%.1f %.1f %.2f %.0f", t.strainMax, t.jerkHold, t.jerkHoldMean, t.endSharp), t.endSpikes, t.endFlips) } }
}
if args.count >= 2, args[1] == "idle" {
    var p = SlimeMaterial.clay.defaults
    if !args.contains("--plain") { SlimeKind.taro.apply(&p) }
    apply(&p, Array(args.dropFirst(2)).filter { !$0.hasPrefix("--") })
    let rig = SlimeRig(params: p); rig.labNoSave = true; rig.seedRandom(7); rig.setup(width: 393, height: 852)
    var maxF = 0, frames = 0, maxS = 0.0
    for k in 0..<900 { rig.update(1.0 / 60); if k >= 90 { let s = rig.labShape(); if s.flips > 0 { frames += 1 }; maxF = max(maxF, s.flips); maxS = max(maxS, rig.labSharp().max) } }
    let g = rig.guardStats
    print("idle 13.5 s: frames with flips \(frames)/810, most \(maxF), sharpest corner \(Int(maxS)) deg; guards hi \(g.pct(g.hi))% lo \(g.pct(g.lo))% flip \(g.pct(g.flip))%")
}
if args.count >= 2, args[1] == "sites" {
    var p = SlimeMaterial.clay.defaults
    if !args.contains("--plain") { SlimeKind.taro.apply(&p) }
    apply(&p, Array(args.dropFirst(2)).filter { !$0.hasPrefix("--") })
    let rig = SlimeRig(params: p); rig.labNoSave = true; rig.seedRandom(7); rig.setup(width: 393, height: 852)
    var seen: [String: Int] = [:]
    for k in 0..<900 { rig.update(1.0 / 60); if k >= 90 { for s in rig.labFlipSites() { seen[String(format: "(%.2f, %.2f) rest×%.2f", s.x, s.y, s.rest), default: 0] += 1 } } }
    for (k, v) in seen.sorted(by: { $0.value > $1.value }).prefix(8) { print(v, k) }
    let c = rig.labCentre, pp = rig.labParticles(); var x0 = 1e9, x1 = -1e9, y0 = 1e9, y1 = -1e9
    for i in 0..<pp.x.count { x0 = min(x0, pp.x[i]); x1 = max(x1, pp.x[i]); y0 = min(y0, pp.y[i]); y1 = max(y1, pp.y[i]) }
    print(String(format: "body box from centre (R): x %.2f..%.2f  y %.2f..%.2f", (x0 - c.x) / rig.labRadius, (x1 - c.x) / rig.labRadius, (y0 - c.y) / rig.labRadius, (y1 - c.y) / rig.labRadius))
}
if args.count >= 3, args[1] == "desk" {
    // the same state as the web test (js_desk.js): slot 1 = clay defaults, slot 2 and current = alpha 0.26, inertiaZ 0.2
    let web = (try? String(contentsOfFile: args[2], encoding: .utf8)) ?? ""
    let header = String(web.split(separator: "\n").first ?? "")
    var p = SlimeMaterial.clay.defaults; SlimeKind.taro.apply(&p)
    let s1 = FeelSnap.pick(p, base: "clay")
    p.alpha = 0.26; p.inertiaZ = 0.2
    let cur = FeelSnap.pick(p, base: "clay")
    let eff = SlimeRig.effective(p).maxPull
    let text = FeelExport.text(header: header, slimeName: "芋圓", current: cur, effectivePull: eff != p.maxPull ? eff : nil, slots: [s1, cur, nil],
                               changed: ["軟 0.18→0.26", "彈：晃幾下 0.3→0.2"], log: [])
    print("stamp", FeelKnob.stamp, "| same text as the web:", text == web)
    if text != web { let a = text.split(separator: "\n"), b = web.split(separator: "\n"); for i in 0..<max(a.count, b.count) where (i < a.count ? a[i] : "") != (i < b.count ? b[i] : "") { print("swift:", i < a.count ? a[i] : "-"); print("web:  ", i < b.count ? b[i] : "-") } }
    if let r = FeelExport.parse(text) {
        let again = FeelExport.text(header: header, slimeName: "芋圓", current: r.current, effectivePull: eff != p.maxPull ? eff : nil, slots: r.slots, changed: ["軟 0.18→0.26", "彈：晃幾下 0.3→0.2"], log: [])
        print("round trip:", again == text, "| pv", r.pv, "ps", r.ps)
    } else { print("parse failed") }
    let old = #"{"base":"clay","v":{"alpha":0.2,"pressSink":0.3,"lag":0.2,"yield":0.05,"creep":6,"recover":0.05,"inertiaZ":0.3,"inertiaHz":3,"slide":1.5},"A":{"base":"mochi","v":{"alpha":0.3}},"B":null}"#
    if let m = FeelDeskStore.decode(old.data(using: .utf8)!) { print("old store:", m.old, m.store.k["alpha"] ?? -1, m.store.s[0]?.base ?? "-", m.store.s[0]?.k["creep"] ?? -1, m.store.s[1] == nil) }
    var n = 0; var b = FeelBlind(0, 1, keep: cur, now: 0, coin: { n += 1; return n == 1 })
    b.show(1 - b.current); b.show(1 - b.current)
    print(b.line(choice: 0, a: s1, b: cur, question: "哪個比較軟", now: 41, date: Date(timeIntervalSince1970: 0)))
    print(b.reveal(choice: 0))
    print("units:", FeelKnob.unit("alpha", 0.18), FeelKnob.unit("recover", 0.05), FeelKnob.unit("flow", 0.05), FeelKnob.unit("lag", 0.22), FeelKnob.unit("recover", 1), FeelKnob.unit("stick", 0))
}

// v2.54 無限拉: the same pulls as the web's pull test. Grab 0.3R inside the edge facing the pull, drag dist·R over 40 frames, hold 60,
// let go, 120 frames. Prints the body's length along the pull while held and 2 s after (in radii).
if args.count >= 2, args[1] == "pull" {
    final class Tok {}
    var p = SlimeMaterial.clay.defaults
    if !args.contains("--plain") { SlimeKind.taro.apply(&p) }
    apply(&p, Array(args.dropFirst(2)).filter { !$0.hasPrefix("--") })
    for (dx, dy, dist) in [(0.0, -1.0, 4.0), (0.5, -1.0, 5.5), (1.0, -1.0, 4.0), (0.0, -1.0, 2.0)] {
        let rig = SlimeRig(params: p); rig.labNoSave = true; rig.seedRandom(7); rig.setup(width: 393, height: 852)
        var clock = 0.0, DT = 1.0 / 60
        for _ in 0..<120 { rig.update(DT); clock += DT }
        let R = rig.labRadius, L = hypot(dx, dy), ux = dx / L, uy = dy / L
        func len() -> Double { let b = rig.boundaryPoints(); var a = -1e9, c = 1e9; for q in b { let v = q.x * ux + q.y * uy; a = max(a, v); c = min(c, v) }; return (a - c) / R }
        let b = rig.boundaryPoints(); var best = b[0]; var bv = -1e9
        for q in b { let v = q.x * ux + q.y * uy; if v > bv { bv = v; best = q } }
        let g = rig.toScreen(best.x - ux * R * 0.3, best.y - uy * R * 0.3)
        let tok = Tok(), id = ObjectIdentifier(tok)
        rig.touchBegan(id, x: g.x, y: g.y, time: clock)
        for _ in 0..<4 { rig.update(DT); clock += DT }
        var ex = g.x, ey = g.y
        for s in 1...40 {
            let nx = max(4, min(389, g.x + ux * dist * R * Double(s) / 40)), ny = max(4, min(848, g.y + uy * dist * R * Double(s) / 40))
            rig.touchMoved(id, x: nx, y: ny, predictedX: nil, predictedY: nil, distance: hypot(nx - ex, ny - ey)); ex = nx; ey = ny
            rig.update(DT); clock += DT
        }
        for _ in 0..<60 { rig.update(DT); clock += DT }
        let held = len()
        rig.touchEnded(id, time: clock)
        for _ in 0..<120 { rig.update(DT); clock += DT }
        print(String(format: "dir %.1f,%.1f dist %.1f  finger %.2fR  held %.2fR  after2s %.2fR  remesh %d (%.1f ms) N %d", dx, dy, dist, hypot(ex - g.x, ey - g.y) / R, held, len(), rig.remeshCount, rig.remeshMs, rig.N)); print(rig.remT.map { String(format: "%.1f", $0) })
        _ = tok
    }
}
