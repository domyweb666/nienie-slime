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
    static let version = "v2.61"

    static let main: [FeelKnob] = [
        FeelKnob(id: "alpha", key: \.alpha, name: "軟", hint: "按三秒，看周圍跟著塌多少。越右越硬", range: 0.05...0.8, step: 0.01, section: "捏下去"),
        FeelKnob(id: "lag", key: \.lag, name: "黏滯（慢一拍）", hint: "慢拖一次、快拖一次，看被抓的那塊差多少", range: 0...0.3, step: 0.01, section: "捏下去"),
        FeelKnob(id: "creep", key: \.creep, name: "留形", hint: "拉長放開，看形狀留多少。0 完全不留（v2.54 起往外拉長時另外加快，見隱藏面板「拉長時定型速度」）", range: 0...40, step: 0.5, section: "捏完"),
        FeelKnob(id: "recover", key: \.recover, name: "回原形", hint: "放著不碰，看多久退一半。越左越久", range: 0...1.5, step: 0.01, section: "捏完"),
        FeelKnob(id: "inertiaZ", key: \.inertiaZ, name: "彈：晃幾下", hint: "戳一下放開，數晃幾下才停。越左晃越多下", range: 0.05...1, step: 0.01, section: "放手"),
        FeelKnob(id: "inertiaHz", key: \.inertiaHz, name: "彈：晃多快", hint: "同一個手勢，看第一下多快（每秒幾下）", range: 0...6, step: 0.1, section: "放手"),
        FeelKnob(id: "maxPull", key: \.maxPull, name: "韌", hint: "慢慢拉，看身體本身拉到多長（幾個半徑）", range: 0.6...10, step: 0.1, section: "拉"),
    ]
    static let more: [FeelKnob] = [
        FeelKnob(id: "pressSink", key: \.pressSink, name: "按下去沉多久", hint: "手指按著不動，凹下去要幾秒", range: 0.05...2, step: 0.05, section: "更多"),
        FeelKnob(id: "yield", key: \.yield, name: "多用力才留形", hint: "越左輕輕捏就留下形狀，越右要捏很大力", range: 0.02...1.5, step: 0.01, section: "更多"),
        FeelKnob(id: "slide", key: \.slide, name: "拉多長整隻跟著走", hint: "拉長到這個長度（幾個半徑），再拉整隻被拖著走。v2.54 黏土 4（以前 1.5，拉 1.5R 就整隻被拖走，看起來像拉不長）", range: 0...8, step: 0.1, section: "更多"),
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

/// v2.61 第一批 (.vibe/第一批-合約.md): the fourteen switches, the same names and words as the web's desk (KEYS61, TIER61, GRP61, PULL3 in index.html).
/// They belong to the desk, not to a material: the controller lays them over whatever material and slime is on screen, so neither changes them.
/// Only the three of the pull go into a saved feel and the copied text's last line; the stamp of the defaults does not know them, so older saved feels stay valid.
struct FeelBatch: Equatable {
    struct Key {
        let id: String
        let key: WritableKeyPath<FeelParams, Double>
    }
    static let keys: [Key] = [
        Key(id: "skinU", key: \FeelParams.skinU),
        Key(id: "pullHold", key: \FeelParams.pullHold),
        Key(id: "pullWhole", key: \FeelParams.pullWhole),
        Key(id: "pullSoft", key: \FeelParams.pullSoft),
        Key(id: "rough", key: \FeelParams.rough),
        Key(id: "tapSoft", key: \FeelParams.tapSoft),
        Key(id: "petSlow", key: \FeelParams.petSlow),
        Key(id: "wakeSoft", key: \FeelParams.wakeSoft),
        Key(id: "nearFast", key: \FeelParams.nearFast),
        Key(id: "greetLook", key: \FeelParams.greetLook),
        Key(id: "brJit", key: \FeelParams.brJit),
        Key(id: "bumpSoft", key: \FeelParams.bumpSoft),
        Key(id: "eyeTrue", key: \FeelParams.eyeTrue),
        Key(id: "snd61", key: \FeelParams.snd61),
    ]
    static let pull: [String] = ["pullHold", "pullWhole", "pullSoft"]
    static func pullName(_ id: String) -> String {
        switch id {
        case "pullHold": return "A3 停住"
        case "pullWhole": return "A4 整隻先走"
        case "pullSoft": return "A5 收回去"
        default: return id
        }
    }
    struct Group: Identifiable {
        let name: String
        let ids: [String]
        var id: String { name }
    }
    static let groups: [Group] = [
        Group(name: "皮", ids: ["skinU"]),
        Group(name: "牠怎麼記你", ids: ["rough", "tapSoft", "petSlow"]),
        Group(name: "聲音", ids: ["snd61"]),
        Group(name: "眼睛和旁邊", ids: ["eyeTrue", "nearFast", "greetLook"]),
        Group(name: "睡醒", ids: ["wakeSoft"]),
    ]
    enum Tier: String, CaseIterable, Identifiable {
        case b158, fix, pull
        var id: String { rawValue }
        var name: String {
            switch self {
            case .b158: return "build 158"
            case .fix: return "只修錯"
            case .pull: return "修錯加拉的三條"
            }
        }
    }

    private(set) var on: [Bool]   // one for each of `keys`, in that order

    /// 只修錯: this build's defaults
    init() {
        let d = SlimeMaterial.clay.defaults
        on = Self.keys.map { d[keyPath: $0.key] >= 0.5 }
    }
    init(_ t: Tier) {
        self.init()
        switch t {
        case .b158: on = Self.keys.map { _ in false }
        case .fix: break
        case .pull: for id in Self.pull { self[id] = true }
        }
    }
    static func index(_ id: String) -> Int? { keys.firstIndex { $0.id == id } }
    static func index(_ key: KeyPath<FeelParams, Double>) -> Int? { keys.firstIndex { $0.key == key } }
    subscript(id: String) -> Bool {
        get { Self.index(id).map { on[$0] } ?? false }
        set { if let i = Self.index(id) { on[i] = newValue } }
    }
    mutating func set(_ i: Int, _ v: Bool) { if on.indices.contains(i) { on[i] = v } }
    func all(_ ids: [String]) -> Bool { ids.allSatisfy { self[$0] } }
    var pullOn: [Bool] { Self.pull.map { self[$0] } }
    mutating func setPull(_ v: [Bool]) { for (id, x) in zip(Self.pull, v) { self[id] = x } }
    func apply(to p: inout FeelParams) {
        for i in 0..<on.count { p[keyPath: Self.keys[i].key] = on[i] ? 1 : 0 }
    }
    var tier: Tier? { Tier.allCases.first { FeelBatch($0) == self } }
    /// The same line as the web's copied text
    var line: String {
        let off: [String] = Self.keys.indices.filter { !on[$0] }.map { Self.keys[$0].id }
        let name: String = tier?.name ?? "自己切的", list: String = off.isEmpty ? "沒有" : off.joined(separator: "、")
        return "這一批（v2.61）：\(name)；關著的：\(list)"
    }
}

/// v2.61 甲乙: two ways of pulling behind 甲 and 乙, which is which by a coin each time it is started and not shown until 揭曉. The change waits until no finger is on the body.
struct PullBlind {
    enum What: String, CaseIterable, Identifiable {
        case all, hold, whole, soft
        var id: String { rawValue }
        var name: String {
            switch self {
            case .all: return "全關對全開"
            case .hold: return "全開對只關 A3"
            case .whole: return "全開對只關 A4"
            case .soft: return "全開對只關 A5"
            }
        }
        /// The two sets, A3, A4, A5
        var sets: (first: [Bool], second: [Bool]) {
            switch self {
            case .all: return ([false, false, false], [true, true, true])
            case .hold: return ([true, true, true], [false, true, true])
            case .whole: return ([true, true, true], [true, false, true])
            case .soft: return ([true, true, true], [true, true, false])
            }
        }
    }
    let what: What
    let sides: [[Bool]]       // 甲, 乙
    let keep: [Bool]          // the three as they were, to go back to
    let startedAt: Double
    var shown: Int?           // on the body now: 0 甲, 1 乙, nil = not changed yet
    var pending: Int?         // waiting for the hand to let go: 0, 1, or 2 = stop comparing
    var switches = 0
    var revealed = false

    init(_ what: What, keep: [Bool], now: Double, coin: Bool = Bool.random()) {
        self.what = what
        let s = what.sets
        sides = coin ? [s.second, s.first] : [s.first, s.second]
        self.keep = keep
        startedAt = now
    }
    static func name(_ i: Int) -> String { i == 0 ? "甲" : "乙" }
    static func label(_ f: [Bool]) -> String {
        if !f.contains(true) { return "三顆全關" }
        if !f.contains(false) { return "三顆全開" }
        let off: [String] = zip(FeelBatch.pull, f).filter { !$0.1 }.map { FeelBatch.pullName($0.0) }
        return "只關" + off.joined(separator: "、")
    }
    var answer: String { "甲是\(Self.label(sides[0]))，乙是\(Self.label(sides[1]))。" }
    func line(now: Double, date: Date = Date()) -> String {
        let c = Calendar.current.dateComponents([.month, .day, .hour, .minute], from: date)
        func p2(_ x: Int?) -> String { let v = x ?? 0; return v < 10 ? "0\(v)" : "\(v)" }
        return "甲乙 \(p2(c.month))-\(p2(c.day)) \(p2(c.hour)):\(p2(c.minute))｜\(what.name)｜\(answer)｜換了 \(switches) 次、\(Int((now - startedAt).rounded())) 秒"
    }
}

/// One saved feel: the material it started from, the defaults it was tuned on, the 13 numbers and, since v2.61, the three switches of the pull.
/// v2.54 手感風格 10 選 1 (多米 11-22: name the feels that are optimal in some mathematical or programming sense, and let me pick).
/// Each is clay's defaults with a few knobs laid over, applied like a saved feel (no bump), so it can be saved to a slot and compared blind.
/// Same ids, names, words and numbers as the web's `STYLES` in desk.js (change one, change the other). 韌 (maxPull) is not touched: with
/// 無限拉 on it does nothing.
struct FeelStyle: Identifiable {
    let id: String
    let name: String
    let math: String   // the model behind it
    let feel: String   // what the hand should notice
    let k: [String: Double]

    static let all: [FeelStyle] = [
        FeelStyle(id: "crit", name: "臨界阻尼", math: "ζ＝1 的二階系統：沒有過衝、最快停下", feel: "放手不晃，一下就定住", k: ["inertiaZ": 1, "inertiaHz": 4, "lag": 0.05]),
        FeelStyle(id: "jelly", name: "欠阻尼彈簧", math: "ζ≈0.15：能量每晃一下只掉一點", feel: "放手晃三四下才停，偏果凍", k: ["inertiaZ": 0.15, "inertiaHz": 3.4, "creep": 3, "recover": 0.5, "yield": 0.3, "alpha": 0.3, "lag": 0.05]),
        FeelStyle(id: "maxwell", name: "麥斯威爾黏彈", math: "彈簧串阻尼：拉住不放，應力慢慢鬆掉", feel: "拉成什麼樣就留什麼樣，最像黏土", k: ["creep": 40, "recover": 0.02, "lag": 0.12, "inertiaZ": 0.7, "yield": 0.03]),
        FeelStyle(id: "voigt", name: "凱文–沃伊特", math: "彈簧並阻尼：變形要時間，最後全部回去", feel: "慢一拍彈回原形，像記憶枕", k: ["creep": 4, "recover": 0.45, "lag": 0.2, "inertiaZ": 1, "alpha": 0.12]),
        FeelStyle(id: "bingham", name: "賓漢塑性", math: "有降伏應力：力不夠是彈性，過了門檻才流動", feel: "輕碰彈回，用力捏才留形", k: ["yield": 0.5, "creep": 30, "alpha": 0.3, "inertiaZ": 0.4]),
        FeelStyle(id: "drop", name: "表面張力水滴", math: "周長最小化：形狀往圓收", feel: "捏完自己慢慢收圓，像一滴水", k: ["recover": 0.3, "creep": 12, "alpha": 0.22, "inertiaZ": 0.45, "inertiaHz": 3.5]),
        FeelStyle(id: "honey", name: "重力流蜂蜜", math: "薄膜流：高的地方往低的地方流", feel: "放著自己往下塌、攤開，拉起來很拖", k: ["flow": 0.12, "lag": 0.25, "recover": 0.02, "alpha": 0.12, "inertiaZ": 0.9]),
        FeelStyle(id: "direct", name: "零延遲直接操控", math: "延遲 0、追手增益 1：手指在哪那塊就在哪", feel: "最跟手，沒有慢一拍", k: ["lag": 0, "alpha": 0.4, "pressSink": 0.1, "inertiaZ": 0.7]),
        FeelStyle(id: "stickslip", name: "黏著–滑脫", math: "靜摩擦大於動摩擦：先黏住，力夠了一下滑開", feel: "抬手時黏住一下才放，有「拔起來」的感覺", k: ["stick": 0.15, "lag": 0.18, "yield": 0.05]),
        FeelStyle(id: "lowpass", name: "一階低通追手", math: "指數平滑 τ＝0.3 秒：高頻抖動濾掉", feel: "像拖著一團有重量的東西，很穩", k: ["lag": 0.3, "alpha": 0.15, "inertiaZ": 0.5, "inertiaHz": 2.2, "slide": 2.5]),
    ]

    /// Clay's defaults for the 13 numbers, the strand off, this style's knobs on top.
    var snap: FeelSnap {
        let d = SlimeMaterial.clay.defaults
        var k: [String: Double] = [:]
        for id in FeelKnob.keys { k[id] = Double(FeelKnob.fmt(FeelKnob.get(d, id))) ?? FeelKnob.get(d, id) }
        k["strand"] = 0
        for (id, v) in self.k { k[id] = v }
        return FeelSnap(base: SlimeMaterial.clay.rawValue, pv: FeelKnob.version, ps: FeelKnob.stamp, k: k)
    }
    /// The desk's numbers are exactly this style (the button lights up).
    func matches(_ s: FeelSnap) -> Bool {
        let m = snap
        return s.base == m.base && FeelKnob.keys.allSatisfy { FeelKnob.fmt(s.k[$0] ?? 0) == FeelKnob.fmt(m.k[$0] ?? 0) }
    }
}

struct FeelSnap: Codable, Equatable {
    var base: String
    var pv: String?
    var ps: String?
    var k: [String: Double]

    static func pick(_ p: FeelParams, base: String) -> FeelSnap {
        var k: [String: Double] = [:]
        for id in FeelKnob.keys { k[id] = Double(FeelKnob.fmt(FeelKnob.get(p, id))) ?? FeelKnob.get(p, id) }
        for id in FeelBatch.pull {
            if let i = FeelBatch.index(id) { k[id] = p[keyPath: FeelBatch.keys[i].key] >= 0.5 ? 1 : 0 }
        }
        return FeelSnap(base: base, pv: FeelKnob.version, ps: FeelKnob.stamp, k: k)
    }
    /// v2.61: A3, A4, A5 (a feel saved before has none of them: off)
    var pullOn: [Bool] { FeelBatch.pull.map { (k[$0] ?? 0) >= 0.5 } }
    mutating func setPull(_ v: [Bool]) {
        for (id, x) in zip(FeelBatch.pull, v) { k[id] = x ? 1 : 0 }
    }
    func apply(to p: inout FeelParams) { for id in FeelKnob.keys { if let v = k[id] { FeelKnob.set(&p, id, v) } } }
    /// Every key present (a missing one takes the material's default), so an older or a pasted feel is whole.
    func filled() -> FeelSnap? {
        guard let m = SlimeMaterial(rawValue: base) else { return nil }
        let d = m.defaults
        var o = self
        for id in FeelKnob.keys where !(o.k[id]?.isFinite ?? false) { o.k[id] = FeelKnob.get(d, id) }
        o.setPull(pullOn)   // v2.61
        return o
    }
    /// What differs between two saved feels, as "名字 a／b".
    static func diff(_ a: FeelSnap, _ b: FeelSnap) -> [String] {
        var o: [String] = []
        if a.base != b.base { o.append("材料 \(FeelKnob.materialName(a.base))／\(FeelKnob.materialName(b.base))") }
        for id in FeelKnob.keys where FeelKnob.fmt(a.k[id] ?? 0) != FeelKnob.fmt(b.k[id] ?? 0) {
            o.append("\(FeelKnob.name(id)) \(FeelKnob.fmt(a.k[id] ?? 0))／\(FeelKnob.fmt(b.k[id] ?? 0))")
        }
        return o + pullDiff(a, b, "／")
    }
    /// v2.61: the switches of the pull that differ, "A3 停住 開／關"
    static func pullDiff(_ a: FeelSnap, _ b: FeelSnap, _ mark: String) -> [String] {
        var o: [String] = []
        let pa = a.pullOn, pb = b.pullOn
        for (i, id) in FeelBatch.pull.enumerated() where pa[i] != pb[i] {
            let x: String = pa[i] ? "開" : "關", y: String = pb[i] ? "開" : "關"
            o.append("\(FeelBatch.pullName(id)) \(x)\(mark)\(y)")
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
        let ids: [String] = FeelKnob.keys + FeelBatch.pull   // v2.61: the web adds the three at the end too
        func kj(_ k: [String: Double]) -> String { "{" + ids.map { "\"\($0)\":\(FeelKnob.fmt(k[$0] ?? 0))" }.joined(separator: ",") + "}" }
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
            var diff = FeelKnob.keys.filter { FeelKnob.fmt(s.k[$0] ?? 0) != FeelKnob.fmt(FeelKnob.get(d, $0)) }.map { "\(FeelKnob.name($0)) \(FeelKnob.fmt(s.k[$0] ?? 0))" }
            for (n, id) in FeelBatch.pull.enumerated() where s.pullOn[n] { diff.append(FeelBatch.pullName(id) + " 開") }   // v2.61
            t += "\n存檔 \(i + 1)（\(m.name)，預設 \((s.pv ?? "").isEmpty ? "?" : (s.pv ?? "?"))）：" + (diff.isEmpty ? "跟預設一樣" : "跟\(m.name)預設不同的：" + diff.joined(separator: "、"))
        }
        t += "\n這次動過：" + (changed.isEmpty ? "沒有" : changed.joined(separator: "、"))
        for l in log.suffix(60) { t += "\n" + l }   // every blind comparison kept (60 at most): ten rounds a pair would not fit in the last five
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
        if (key == \FeelParams.maxPull || key == \FeelParams.memMax) && set.endless >= 0.5 && grey[keyPath: key] == v { return "現在不作用（無限拉開著，沒有上限）" }   // v2.54
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
