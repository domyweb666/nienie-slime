import UIKit

/// Feel parameters, same names as the prototype's `DEF` and 參數表.
struct FeelParams: Equatable {
    var response: Double   // spring response time (s)
    var damping: Double    // damping ratio
    var lag: Double        // sticky lag behind the finger (s)
    var maxPull: Double    // soft stretch limit, in body radii
    var neck: Double       // how thin the base of a pull gets
    var press: Double      // how flat a press can squash
    var creep: Double      // molding speed
    var yield: Double      // deformation (in radii) before molding starts
    var recover: Double    // speed of relaxing back to rest shape
    var pitch: Double      // sound pitch multiplier
}

struct SlimeColors {
    var base: UIColor
    var shade: UIColor
    var line: UIColor
    var light: UIColor
}

enum SlimeMaterial: String, CaseIterable, Identifiable {
    case bouncy, mochi, clay

    var id: String { rawValue }

    var name: String {
        switch self {
        case .bouncy: return "Q彈"
        case .mochi: return "麻糬"
        case .clay: return "黏土"
        }
    }

    var defaults: FeelParams {
        switch self {
        case .bouncy:
            return FeelParams(response: 0.28, damping: 0.42, lag: 0.04, maxPull: 1.5, neck: 0.55, press: 0.3,
                              creep: 0.25, yield: 0.3, recover: 0.6, pitch: 1.12)
        case .mochi:
            return FeelParams(response: 0.42, damping: 0.6, lag: 0.08, maxPull: 1.7, neck: 0.6, press: 0.38,
                              creep: 1.2, yield: 0.12, recover: 0.12, pitch: 0.98)
        case .clay:
            return FeelParams(response: 0.55, damping: 0.85, lag: 0.12, maxPull: 1.9, neck: 0.65, press: 0.42,
                              creep: 4, yield: 0.04, recover: 0, pitch: 0.86)
        }
    }

    var colors: SlimeColors {
        switch self {
        case .bouncy:
            return SlimeColors(base: UIColor(hex: 0x7FE0C2), shade: UIColor(hex: 0x4FB99E),
                               line: UIColor(hex: 0x2B6E61), light: UIColor(hex: 0xE9FFF7))
        case .mochi:
            return SlimeColors(base: UIColor(hex: 0xC9B6FF), shade: UIColor(hex: 0x9E86E6),
                               line: UIColor(hex: 0x4E3C8F), light: UIColor(hex: 0xFAF6FF))
        case .clay:
            return SlimeColors(base: UIColor(hex: 0xFFD86B), shade: UIColor(hex: 0xEDB23C),
                               line: UIColor(hex: 0x8A5A12), light: UIColor(hex: 0xFFF8DC))
        }
    }
}

/// One tunable slider in the hidden panel (prototype's `F` + `RANGE`).
struct TuneField: Identifiable {
    let key: WritableKeyPath<FeelParams, Double>
    let name: String
    let hint: String
    let range: ClosedRange<Double>
    let step: Double
    var id: String { name }

    static let all: [TuneField] = [
        TuneField(key: \.response, name: "回彈速度（秒）", hint: "越小彈得越快", range: 0.12...0.9, step: 0.01),
        TuneField(key: \.damping, name: "晃動（阻尼）", hint: "越小越會晃、越 Q", range: 0.15...1, step: 0.01),
        TuneField(key: \.lag, name: "黏滯", hint: "拉的時候跟手的延遲感", range: 0...0.3, step: 0.01),
        TuneField(key: \.press, name: "按壓深度", hint: "按住能壓多扁", range: 0.1...0.6, step: 0.01),
        TuneField(key: \.maxPull, name: "拉伸上限", hint: "最多拉多長", range: 0.6...2.4, step: 0.05),
        TuneField(key: \.creep, name: "定型速度", hint: "揉多快就記住新形狀", range: 0...6, step: 0.1),
        TuneField(key: \.recover, name: "回原形速度", hint: "放著多快變回原樣", range: 0...1.5, step: 0.02),
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
