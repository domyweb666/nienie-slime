import Foundation

/// 手感調節台 v1 (v2.52, 多米 11-22 交辦 B 組; 《虛擬手感》3-4 第十一節的規格): what the desk knows, apart from how it looks.
/// Seven main knobs, one for each word on the feel card (軟、黏滯、留形、回原形、彈兩條、韌), the secondary ones under 更多;
/// a saved feel; the text that is copied out and can be pasted back to the same numbers; a blind comparison of two saved feels.
/// The same names, ranges and text as the web's `prototype/web/desk.js` (change one, change the other).
/// Foundation only, so it builds and runs on the Linux harness too.
struct FeelKnob: Identifiable {
    let id: String   // the parameter's name in the web prototype (same keys in the copied text and in "nienie.feel")
    let key: WritableKeyPath<FeelParams, Double>
    let name: String   // the word on the feel card
    let hint: String   // the reference: how to squeeze it to judge this one knob
    let range: ClosedRange<Double>
    let step: Double
    let section: String

    /// The name of this set of defaults. Change it when a knob's default changes for any material; the stamp below catches it if you forget.
    static let version = "v2.52"

    static let main: [FeelKnob] = [
        FeelKnob(id: "alpha", key: \.alpha, name: "軟", hint: "按三秒，看周圍跟著塌多少。越右越硬", range: 0.05...0.8, step: 0.01, section: "捏下去"),
        FeelKnob(id: "lag", key: \.lag, name: "黏滯（慢一拍）", hint: "慢拖一次、快拖一次，看被抓的那塊差多少", range: 0...0.3, step: 0.01, section: "捏下去"),
        FeelKnob(id: "creep", key: \.creep, name: "留形", hint: "拉長放開，看形狀留多少。0 完全不留", range: 0...6, step: 0.1, section: "捏完"),
        FeelKnob(id: "recover", key: \.recover, name: "回原形", hint: "放著不碰，看多久退一半。越左越久", range: 0...1.5, step: 0.01, section: "捏完"),
        FeelKnob(id: "inertiaZ", key: \.inertiaZ, name: "彈：晃幾下", hint: "戳一下放開，數晃幾下才停。越左晃越多下", range: 0.05...1, step: 0.01, section: "放手"),
        FeelKnob(id: "inertiaHz", key: \.inertiaHz, name: "彈：晃多快", hint: "同一個手勢，看第一下多快（每秒幾下）", range: 0...6, step: 0.1, section: "放手"),
        FeelKnob(id: "maxPull", key: \.maxPull, name: "韌", hint: "慢慢拉，看身體本身拉到多長（幾個半徑）", range: 0.6...10, step: 0.1, section: "拉"),
    ]
    static let more: [FeelKnob] = [
        FeelKnob(id: "pressSink", key: \.pressSink, name: "按下去沉多久", hint: "手指按著不動，凹下去要幾秒", range: 0.05...2, step: 0.05, section: "更多"),
        FeelKnob(id: "yield", key: \.yield, name: "多用力才留形", hint: "越左輕輕捏就留下形狀，越右要捏很大力", range: 0.02...1.5, step: 0.01, section: "更多"),
        FeelKnob(id: "slide", key: \.slide, name: "拉多長整隻跟著走", hint: "拉長到這個長度（幾個半徑），再拉整隻被拖著走", range: 0...3, step: 0.1, section: "更多"),
        FeelKnob(id: "stick", key: \.stick, name: "黏手", hint: "慢慢抬手時，那塊多黏幾秒才放（候選 26 是 0.1）；0 關", range: 0...0.2, step: 0.02, section: "更多"),
        FeelKnob(id: "flow", key: \.flow, name: "流", hint: "放著不碰，每秒往下塌掉高度的幾成；0 不塌", range: 0...0.5, step: 0.01, section: "更多"),
    ]
    static let all: [FeelKnob] = main + more
    static let sections = ["捏下去", "捏完", "放手", "拉"]
    /// The 13 numbers of one saved feel. The strand is a switch; saved with the rest, so "the strand" can be compared blind with "the body itself pulls to 7".
    static let keys: [String] = all.map(\.id) + ["strand"]

    static func get(_ p: FeelParams, _ id: String) -> Double {
        if id == "strand" { return p.strand }
        return all.first { $0.id == id }.map { p[keyPath: $0.key] } ?? 0
    }
    static func set(_ p: inout FeelParams, _ id: String, _ v: Double) {
        guard v.isFinite else { return }
        if id == "strand" { p.strand = v >= 0.5 ? 1 : 0; return }
        if let k = all.first(where: { $0.id == id }) { p[keyPath: k.key] = min(k.range.upperBound, max(k.range.lowerBound, v)) }
    }
    static func name(_ id: String) -> String { id == "strand" ? "黏條" : (all.first { $0.id == id }?.name ?? id) }
    static func materialName(_ base: String) -> String { SlimeMaterial(rawValue: base)?.name ?? base }

    /// Three decimals at most, no trailing zeros: the same text as the web's `dfmt`.
    static func fmt(_ v: Double) -> String {
        let r = (v * 1000).rounded() / 1000
        return r == r.rounded() ? String(Int(r)) : String(r)
    }

    /// What the number means in time: 軟 is "pulled back this share every 1/240 s", shown as its time constant; 回原形 and 流 as a half-time.
    static func unit(_ id: String, _ v: Double) -> String {
        func half(_ x: Double) -> String { fmt(x > 0.35 ? ((log(2) / x) * 10).rounded() / 10 : (log(2) / x).rounded()) }
        switch id {
        case "alpha": return v > 0 && v < 1 ? "約 \(Int((1000.0 / 240 / -log(1 - v)).rounded())) 毫秒" : ""
        case "lag": return "\(Int((v * 1000).rounded())) 毫秒"
        case "recover": return v > 0 ? "退一半約 \(half(v)) 秒" : "不會退"
        case "flow": return v > 0 ? "約 \(half(v)) 秒塌一半" : "不塌"
        case "stick": return v > 0 ? "\(Int((v * 1000).rounded())) 毫秒" : "關"
        default: return ""
        }
    }

    /// A fingerprint of the three materials' defaults for these 13 numbers (FNV-1a): a feel saved on other defaults is recognised.
    static let stamp: String = {
        var s = ""
        for m in [SlimeMaterial.clay, .mochi, .jelly] { let p = m.defaults; for k in keys { s += fmt(get(p, k)) + "," } }
        var h: UInt32 = 0x811c_9dc5
        for b in s.utf8 { h ^= UInt32(b); h = h &* 0x0100_0193 }
        let hex = String(h, radix: 16)
        return String((String(repeating: "0", count: max(0, 8 - hex.count)) + hex).prefix(6))
    }()
}

/// One saved feel: the material it started from, the defaults it was tuned on, the 13 numbers.
struct FeelSnap: Codable, Equatable {
    var base: String
    var pv: String?
    var ps: String?
    var k: [String: Double]

    static func pick(_ p: FeelParams, base: String) -> FeelSnap {
        var k: [String: Double] = [:]
        for id in FeelKnob.keys { k[id] = Double(FeelKnob.fmt(FeelKnob.get(p, id))) ?? FeelKnob.get(p, id) }
        return FeelSnap(base: base, pv: FeelKnob.version, ps: FeelKnob.stamp, k: k)
    }
    func apply(to p: inout FeelParams) { for id in FeelKnob.keys { if let v = k[id] { FeelKnob.set(&p, id, v) } } }
    /// Every key present (a missing one takes the material's default), so an older or a pasted feel is whole.
    func filled() -> FeelSnap? {
        guard let m = SlimeMaterial(rawValue: base) else { return nil }
        let d = m.defaults
        var o = self
        for id in FeelKnob.keys where !(o.k[id]?.isFinite ?? false) { o.k[id] = FeelKnob.get(d, id) }
        return o
    }
    /// What differs between two saved feels, as "名字 a／b".
    static func diff(_ a: FeelSnap, _ b: FeelSnap) -> [String] {
        var o: [String] = []
        if a.base != b.base { o.append("材料 \(FeelKnob.materialName(a.base))／\(FeelKnob.materialName(b.base))") }
        for id in FeelKnob.keys where FeelKnob.fmt(a.k[id] ?? 0) != FeelKnob.fmt(b.k[id] ?? 0) {
            o.append("\(FeelKnob.name(id)) \(FeelKnob.fmt(a.k[id] ?? 0))／\(FeelKnob.fmt(b.k[id] ?? 0))")
        }
        return o
    }
}

/// What is kept in UserDefaults under "nienie.feel" (the same shape as the web's localStorage entry).
struct FeelDeskStore: Codable {
    var v = 2
    var pv: String
    var ps: String
    var base: String
    var k: [String: Double]
    var s: [FeelSnap?]
    var log: [String]

    /// The v2.39 to v2.51 desk kept {base, v, A, B}: nine knobs, two slots. They come back as the current feel and slots 1 and 2.
    private struct Old: Codable {
        struct Snap: Codable { var base: String; var v: [String: Double] }
        var base: String
        var v: [String: Double]
        var A: Snap?
        var B: Snap?
    }
    /// - Returns: the store, and whether it was the old format
    static func decode(_ d: Data) -> (store: FeelDeskStore, old: Bool)? {
        if let s = try? JSONDecoder().decode(FeelDeskStore.self, from: d), s.v == 2 { return (s, false) }
        guard let o = try? JSONDecoder().decode(Old.self, from: d) else { return nil }
        func up(_ base: String, _ v: [String: Double]) -> FeelSnap? { FeelSnap(base: base, pv: "v2.39", ps: "", k: v).filled() }
        guard let cur = up(o.base, o.v) else { return nil }
        return (FeelDeskStore(pv: "v2.39", ps: "", base: cur.base, k: cur.k, s: [o.A.flatMap { up($0.base, $0.v) }, o.B.flatMap { up($0.base, $0.v) }, nil], log: []), true)
    }
}

/// The copied text (3-4 第 6 欄: pasted back, the same numbers come up again). The last line, `#nienie-feel`, is for the program; the lines above it are for people.
enum FeelExport {
    /// The numbers in a fixed key order, so the same feel gives the same line on the phone and on the web.
    static func json(current: FeelSnap, slots: [FeelSnap?]) -> String {
        func kj(_ k: [String: Double]) -> String { "{" + FeelKnob.keys.map { "\"\($0)\":\(FeelKnob.fmt(k[$0] ?? 0))" }.joined(separator: ",") + "}" }
        func sj(_ s: FeelSnap?) -> String {
            guard let s else { return "null" }
            return "{\"base\":\"\(s.base)\",\"pv\":\"\(s.pv ?? "")\",\"ps\":\"\(s.ps ?? "")\",\"k\":\(kj(s.k))}"
        }
        return "{\"v\":2,\"pv\":\"\(FeelKnob.version)\",\"ps\":\"\(FeelKnob.stamp)\",\"base\":\"\(current.base)\",\"k\":\(kj(current.k)),\"s\":[\(slots.map(sj).joined(separator: ","))]}"
    }

    /// - Parameters:
    ///   - header: build, defaults, model, refresh rate, low power (the phone fills these in)
    ///   - effectivePull: the stretch limit the physics really uses, when it differs from the knob
    ///   - changed: the knobs moved since the app opened, "名字 a→b"
    ///   - extra: lines only the phone has (the fuzz test's result), put after the blind comparisons
    static func text(header: String, slimeName: String, current: FeelSnap, effectivePull: Double?, slots: [FeelSnap?], changed: [String], log: [String], extra: [String] = []) -> String {
        func piece(_ id: String) -> String {
            let v = current.k[id] ?? 0
            if id == "strand" { return "\(FeelKnob.name(id)) \(v >= 0.5 ? "開" : "關")" }
            let u = id == "maxPull" ? (effectivePull.map { "實際 \(FeelKnob.fmt($0))" } ?? "") : FeelKnob.unit(id, v)
            return "\(FeelKnob.name(id)) \(FeelKnob.fmt(v))" + (u.isEmpty ? "" : "（\(u)）")
        }
        var t = header + "\n材料：\(FeelKnob.materialName(current.base))起點（\(slimeName)）"
        t += "\n旋鈕：" + FeelKnob.main.map { piece($0.id) }.joined(separator: "、")
        t += "\n更多：" + (FeelKnob.more.map { piece($0.id) } + [piece("strand")]).joined(separator: "、")
        for (i, s) in slots.enumerated() {
            guard let s, let m = SlimeMaterial(rawValue: s.base) else { continue }
            let d = m.defaults
            let diff = FeelKnob.keys.filter { FeelKnob.fmt(s.k[$0] ?? 0) != FeelKnob.fmt(FeelKnob.get(d, $0)) }.map { "\(FeelKnob.name($0)) \(FeelKnob.fmt(s.k[$0] ?? 0))" }
            t += "\n存檔 \(i + 1)（\(m.name)，預設 \((s.pv ?? "").isEmpty ? "?" : (s.pv ?? "?"))）：" + (diff.isEmpty ? "跟預設一樣" : "跟\(m.name)預設不同的：" + diff.joined(separator: "、"))
        }
        t += "\n這次動過：" + (changed.isEmpty ? "沒有" : changed.joined(separator: "、"))
        for l in log.suffix(5) { t += "\n" + l }
        for l in extra { t += "\n" + l }
        return t + "\n#nienie-feel " + json(current: current, slots: slots)
    }

    /// The current feel and the three slots out of a pasted text; nil when the `#nienie-feel` line is missing or broken.
    static func parse(_ text: String) -> (current: FeelSnap, slots: [FeelSnap?], pv: String, ps: String)? {
        guard let line = text.split(whereSeparator: \.isNewline).last(where: { $0.hasPrefix("#nienie-feel") }) else { return nil }
        let body = line.dropFirst("#nienie-feel".count).trimmingCharacters(in: .whitespaces)
        guard let d = body.data(using: .utf8), let o = (try? JSONSerialization.jsonObject(with: d)) as? [String: Any],
              (o["v"] as? NSNumber)?.intValue == 2, let base = o["base"] as? String, let k = o["k"] as? [String: Any] else { return nil }
        func nums(_ a: [String: Any]) -> [String: Double] { var r: [String: Double] = [:]; for (key, v) in a { if let n = v as? NSNumber { r[key] = n.doubleValue } }; return r }
        guard let cur = FeelSnap(base: base, pv: o["pv"] as? String, ps: o["ps"] as? String, k: nums(k)).filled() else { return nil }
        var slots: [FeelSnap?] = [nil, nil, nil]
        if let arr = o["s"] as? [Any] {
            for (i, e) in arr.prefix(3).enumerated() {
                guard let s = e as? [String: Any], let b = s["base"] as? String, let sk = s["k"] as? [String: Any] else { continue }
                slots[i] = FeelSnap(base: b, pv: s["pv"] as? String, ps: s["ps"] as? String, k: nums(sk)).filled()
            }
        }
        return (cur, slots, (o["pv"] as? String) ?? "", (o["ps"] as? String) ?? "")
    }
}

/// 盲比 (3-4 鏈四: knowing which one is the new one bends the judgement). Two saved feels are called 1 號 and 2 號 at random, which one comes
/// first is random too; while squeezing no number is on screen; only after choosing is it told which was which, and one line is logged.
struct FeelBlind {
    let pair: (Int, Int)     // the two slots, as the user picked them
    let map: [Int]           // map[0] is the slot behind 1 號, map[1] behind 2 號
    let first: Int           // which number was shown first (0 or 1)
    var current: Int
    var switches = 0
    let startedAt: Double    // seconds, any monotonic clock
    let keep: FeelSnap       // what was on the desk before, to go back to on cancel or "分不出來"

    init(_ a: Int, _ b: Int, keep: FeelSnap, now: Double, coin: () -> Bool = { Bool.random() }) {
        pair = (a, b)
        map = coin() ? [b, a] : [a, b]
        first = coin() ? 0 : 1
        current = first
        startedAt = now
        self.keep = keep
    }
    var slot: Int { map[current] }
    mutating func show(_ n: Int) { guard n != current, n == 0 || n == 1 else { return }; current = n; switches += 1 }

    /// - Parameter choice: 0 or 1 for 1 號 or 2 號, nil for 分不出來
    func line(choice: Int?, a: FeelSnap, b: FeelSnap, question: String, now: Double, date: Date = Date()) -> String {
        let c = Calendar.current.dateComponents([.month, .day, .hour, .minute], from: date)
        func p2(_ x: Int?) -> String { let v = x ?? 0; return v < 10 ? "0\(v)" : "\(v)" }
        let diff = FeelSnap.diff(a, b)
        let pick = choice.map { "選 \($0 + 1) 號＝存檔 \(map[$0] + 1)" } ?? "分不出來"
        let q = question.trimmingCharacters(in: .whitespacesAndNewlines)
        return "盲比 \(p2(c.month))-\(p2(c.day)) \(p2(c.hour)):\(p2(c.minute))｜\(FeelKnob.materialName(a.base))｜存檔 \(pair.0 + 1) 對 \(pair.1 + 1)｜差在：\(diff.isEmpty ? "沒有差" : diff.joined(separator: "、"))｜先摸 \(first + 1) 號｜換了 \(switches) 次、\(Int((now - startedAt).rounded())) 秒｜\(pick)" + (q.isEmpty ? "" : "｜題目：\(q)")
    }
    func reveal(choice: Int?) -> String {
        "揭曉：1 號是存檔 \(map[0] + 1)，2 號是存檔 \(map[1] + 1)。" + (choice.map { "你選的是存檔 \(map[$0] + 1)，現在用的就是它。" } ?? "你說分不出來。") + "已經記一行，複製數值時會帶上。"
    }
}

/// v2.52 A2 (交辦: 被任何場景、模式蓋掉的參數，滑桿旁邊標「實際是 X」): what the sliders say against what the physics uses.
struct FeelEffective {
    let set: FeelParams     // the sliders
    let used: FeelParams    // after the grey box (when it is on), the scene and the modes
    private let grey: FeelParams
    init(_ p: FeelParams, grey on: Bool) {
        set = p
        var g = p
        if on { g.greyBox() }
        grey = g
        used = SlimeRig.effective(g)
    }
    /// "實際是 X（為什麼）", or that the slider does nothing right now; nil when the slider's own number is what is used.
    func note(_ key: KeyPath<FeelParams, Double>) -> String? {
        let v = set[keyPath: key], u = used[keyPath: key], sill = set.scene >= 0.5, strand = set.strand >= 0.5
        if u != v {
            let why: String
            if grey[keyPath: key] != v { why = "灰盒開著" }
            else if key == \FeelParams.maxPull { why = strand ? "黏條開著，窗台上身體只拉到這裡，再遠是黏條" : "窗台上的拉伸上限對照開著" }
            else if key == \FeelParams.memMax { why = strand ? "黏條開著" : "窗台上的拉伸上限對照開著" }
            else if set.limbs > 0 && (key == \FeelParams.noFlip || key == \FeelParams.gripUp || key == \FeelParams.homeCap || key == \FeelParams.fingerSolid) { why = "手腳開著" }
            else { why = "窗台場景固定用這個值" }
            return "實際是 \(FeelKnob.fmt(u))（\(why)）"
        }
        if key == \FeelParams.strandAt && !(sill && strand) { return "現在不作用（\(sill ? "黏條關著" : "不在窗台")）" }
        if key == \FeelParams.flow && set.flow > 0 && !sill { return "現在不作用（不在窗台）" }
        return nil
    }
}
