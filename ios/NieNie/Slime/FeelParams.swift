import UIKit

/// Feel parameters, same names and meanings as the web prototype's `PRESETS`
/// (prototype/web/index.html) and 參數表.
struct FeelParams: Equatable {
    var alpha: Double      // shape-matching stiffness per substep (0...1)
    var damp: Double       // Verlet velocity damping per substep
    var yield: Double      // deformation (in radii) before the body starts remembering a shape
    var creep: Double      // how fast the remembered shape follows the current one (per second)
    var recover: Double    // how fast the remembered shape relaxes back (per second)
    var grabR: Double      // grab radius, in radii
    var maxPull: Double    // soft stretch limit, in radii
    var lag: Double        // sticky lag behind the finger (s)
    var wGlobal: Double    // weight of the whole-body cluster (bigger = more like one lump)
    var cSpace: Double     // cluster spacing, in radii (smaller = softer)
    var cRad: Double       // cluster radius, in radii
    var upright: Double    // how fast it turns back head-up (per substep)
    var anchor: Double     // how much harder it stays put while grabbed
    var areaGain: Double   // area pressure: how much the sides bulge when squashed
    var gripRot: Double    // extra upright strength while grabbed
    var life: Double       // idle motion amount (0 = still)
    var drift: Double      // tentacle sway amplitude, in radii
    var wriggle: Double    // whole-body travelling-wave amplitude, in radii
    var wander: Double     // idle roaming speed, radii per second
    var floppy: Double     // how much softer tentacle tips are (0...0.9)
    var seed: Double       // shape seed (1...30); changing it rebuilds the body
}

struct SlimeColors {
    var base: UIColor
    var shade: UIColor
    var line: UIColor
    var light: UIColor
}

enum SlimeMaterial: String, CaseIterable, Identifiable {
    case jelly, mochi, clay

    var id: String { rawValue }

    var name: String {
        switch self {
        case .jelly: return "果凍"
        case .mochi: return "麻糬"
        case .clay: return "黏土"
        }
    }

    /// Same numbers as the prototype's PRESETS (2026-10-31, v2.2).
    var defaults: FeelParams {
        switch self {
        case .jelly:
            return FeelParams(alpha: 0.34, damp: 0.986, yield: 1.5, creep: 0, recover: 1, grabR: 0.36, maxPull: 1.6,
                              lag: 0.05, wGlobal: 0.12, cSpace: 0.3, cRad: 0.42, upright: 0.004, anchor: 4,
                              areaGain: 0.6, gripRot: 3, life: 1, drift: 0.16, wriggle: 0.07, wander: 0.25,
                              floppy: 0.5, seed: 7)
        case .mochi:
            return FeelParams(alpha: 0.28, damp: 0.966, yield: 0.14, creep: 0.9, recover: 0.18, grabR: 0.32, maxPull: 1.8,
                              lag: 0.08, wGlobal: 0.10, cSpace: 0.3, cRad: 0.45, upright: 0.004, anchor: 4,
                              areaGain: 0.6, gripRot: 3, life: 1, drift: 0.16, wriggle: 0.07, wander: 0.25,
                              floppy: 0.55, seed: 7)
        case .clay:
            return FeelParams(alpha: 0.40, damp: 0.940, yield: 0.05, creep: 3, recover: 0.03, grabR: 0.32, maxPull: 2.0,
                              lag: 0.12, wGlobal: 0.08, cSpace: 0.3, cRad: 0.45, upright: 0.002, anchor: 4,
                              areaGain: 0.5, gripRot: 3, life: 0.8, drift: 0.14, wriggle: 0.06, wander: 0.22,
                              floppy: 0.6, seed: 7)
        }
    }

    var colors: SlimeColors {
        switch self {
        case .jelly:
            return SlimeColors(base: UIColor(hex: 0x7FE0C2), shade: UIColor(hex: 0x4FB99E),
                               line: UIColor(hex: 0x2B6E61), light: UIColor(hex: 0xE9FFF7))
        case .mochi:
            return SlimeColors(base: UIColor(hex: 0xC9B6FF), shade: UIColor(hex: 0x9E86E6),
                               line: UIColor(hex: 0x4E3C8F), light: UIColor(hex: 0xFAF6FF))
        case .clay:
            return SlimeColors(base: UIColor(hex: 0xFFD96B), shade: UIColor(hex: 0xF0B64A),
                               line: UIColor(hex: 0x8B5A20), light: UIColor(hex: 0xFFF6D6))
        }
    }
}

/// One tunable slider in the hidden panel (prototype's `F`).
struct TuneField: Identifiable {
    let key: WritableKeyPath<FeelParams, Double>
    let name: String
    let hint: String
    let range: ClosedRange<Double>
    let step: Double
    var id: String { name }

    static let all: [TuneField] = [
        TuneField(key: \.alpha, name: "回彈硬度", hint: "越大越快回去、越硬", range: 0.05...0.8, step: 0.01),
        TuneField(key: \.damp, name: "晃動阻尼", hint: "越小放手晃越久", range: 0.85...0.999, step: 0.001),
        TuneField(key: \.yield, name: "定型門檻（×半徑）", hint: "變形超過這個才開始留形", range: 0.02...1.5, step: 0.01),
        TuneField(key: \.creep, name: "定型速度", hint: "揉多快記住新形狀", range: 0...6, step: 0.1),
        TuneField(key: \.recover, name: "回原形速度", hint: "放著多快變回原樣", range: 0...1.5, step: 0.01),
        TuneField(key: \.grabR, name: "抓取範圍（×半徑）", hint: "一指抓到多大一塊", range: 0.2...0.8, step: 0.01),
        TuneField(key: \.maxPull, name: "拉伸上限（×半徑）", hint: "最多拉多遠", range: 0.6...2.6, step: 0.05),
        TuneField(key: \.lag, name: "黏滯", hint: "跟手的延遲感（秒）", range: 0...0.3, step: 0.01),
        TuneField(key: \.wGlobal, name: "整體性", hint: "越大整團越像一塊", range: 0...1, step: 0.01),
        TuneField(key: \.cSpace, name: "區塊間距（×半徑）", hint: "越小區塊越多越軟", range: 0.15...0.7, step: 0.05),
        TuneField(key: \.cRad, name: "區塊半徑（×半徑）", hint: "越小越軟、越容易拉出一塊", range: 0.25...1, step: 0.01),
        TuneField(key: \.upright, name: "回正", hint: "放手後轉回頭朝上的速度", range: 0...0.02, step: 0.001),
        TuneField(key: \.anchor, name: "抓著時的定身", hint: "越大身體越不會整團跟著手走、轉掉", range: 1...8, step: 0.5),
        TuneField(key: \.areaGain, name: "面積壓力", hint: "壓扁時旁邊鼓出來的程度", range: 0...1.5, step: 0.05),
        TuneField(key: \.gripRot, name: "抓著時不轉", hint: "越大拉它時身體越不會歪掉", range: 1...8, step: 0.5),
        TuneField(key: \.life, name: "活物感", hint: "沒碰時自己動的幅度", range: 0...1.5, step: 0.05),
        TuneField(key: \.drift, name: "觸手飄動", hint: "沒碰時觸手擺動的幅度（×半徑）", range: 0...0.4, step: 0.01),
        TuneField(key: \.wriggle, name: "蠕動", hint: "沒碰時整個身體輪廓慢慢變形的幅度（×半徑）", range: 0...0.2, step: 0.01),
        TuneField(key: \.wander, name: "遊走", hint: "沒碰時在畫面裡移動的速度（×半徑／秒）", range: 0...1, step: 0.05),
        TuneField(key: \.floppy, name: "觸手軟度", hint: "越大觸手末端越軟、越會甩", range: 0...0.9, step: 0.05),
        TuneField(key: \.seed, name: "外形亂數種子", hint: "換一個數字就換一個形狀（會重置）", range: 1...30, step: 1),
    ]
}

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: alpha)
    }
}
