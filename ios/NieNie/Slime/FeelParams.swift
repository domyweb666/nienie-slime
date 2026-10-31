import UIKit

/// Feel parameters, same names and meanings as the web prototype's `PRESETS`
/// (prototype/web/index.html) and 參數表. Haptic and sound numbers only exist here.
struct FeelParams: Equatable, Codable {
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

    // v2.3 press (接觸點先凹): the grabbed patch spreads away from the finger. The side view
    // cannot show depth, so "pressing in" is drawn as squashing flat. Visible spread is about
    // half the number (the finger constraint and shape matching meet in the middle).
    var pressBase: Double = 0.12      // spread on contact, in radii
    var pressHold: Double = 0.18      // extra spread while held still, in radii
    var pressHoldTime: Double = 0.6   // seconds held still to reach the full extra spread
    var pressRise: Double = 0.06      // time constant of the spread (s)
    var pressFirst: Double = 0.5      // fraction of the target applied on the very first frame
    // plasticity only after dwelling (輕按回彈，揉捏即留形)
    var dwellLo: Double = 0.2         // seconds grabbed before the body starts remembering
    var dwellHi: Double = 0.6         // seconds grabbed until it remembers at full speed

    // v2.4 second-batch candidates (手感精修提案). Defaults are the control values (the v2.3 behaviour);
    // the panel's 候選 buttons apply one candidate at a time for blind tests.
    var idleFreeze: Double = 0        // 1: idle motion freezes its clock while touched instead of fading to the rest pose (第 19 條)
    var specialEvery: Double = 0      // every N releases (±2) one comes back extra bouncy; 0 = off (第 2 條)
    var pressRadiusGain: Double = 0   // extra press spread from contact size (UITouch.majorRadius); 0 = off (第 9 條)
    // haptics (第 38 條 on the panel; candidates 12, 13, 14)
    var hapMax: Double = 0.8          // continuous haptic ceiling
    var hapStatic: Double = 1         // continuous haptic: weight of deformation^1.5
    var hapRate: Double = 0           // continuous haptic: weight of the rate of change (candidate 0.75 with static 0.25)
    var hapRateNorm: Double = 2.5     // rate of change that counts as full, per second
    var hapSharp: Double = 0.25       // continuous haptic sharpness
    var hapSharpStretch: Double = 0   // extra sharpness when stretched (第三批第 15 條)
    var popMin: Double = 0.3          // release pop intensity at zero strength
    var popMax: Double = 0.7          // release pop intensity at full strength
    var popSharp: Double = 0.45       // release pop sharpness
    var popCount: Double = 1          // taps per release (candidate: clay 1, mochi 2, jelly 3)
    var popGap: Double = 0.09         // seconds between taps
    var popDecay: Double = 0.5        // each tap is this fraction of the previous
    var tickSpacing: Double = 0       // texture tick every N points of finger travel; 0 = off (candidate 8)
    var tickMin: Double = 0.10        // tick intensity when the finger is slow
    var tickMax: Double = 0.30        // tick intensity at 3 radii per second
    var tickSharp: Double = 0.4       // tick sharpness
    // 提案第 41 條 (2026-11-01): tentacle rungs. 0 = the v2.4 behaviour, where a tentacle pushed root-to-tip could fold over itself
    var tentRung: Double = 0.5        // the two edges of a tentacle stay on their own sides, at least this fraction of the rest width apart
    var tentAxis: Double = 0.85       // each link of a tentacle's medial axis keeps advancing by at least this fraction of its rest length
    // sound
    var volMaster: Double = 0.9       // output volume
    var rubMax: Double = 0.7          // loudest the rub loop gets
    var pitchJitter: Double = 0.08    // random pitch ±
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

    /// Same numbers as the prototype's PRESETS (2026-10-31, v2.2; press and dwell added 2026-11-01, v2.3).
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

/// One second-batch candidate (手感精修提案): a named change applied on top of the current numbers.
/// Blind test, one at a time: 存 1 (control) → 套候選 → 存 2 → 切 1／切 2.
struct Candidate: Identifiable {
    let id: Int
    let name: String
    let hint: String
    let apply: (inout FeelParams, SlimeMaterial) -> Void

    static let batch2: [Candidate] = [
        Candidate(id: 6, name: "6 黏滯 0.03", hint: "黏放在身體上，手指不延遲") { p, _ in p.lag = 0.03 },
        Candidate(id: 12, name: "12 觸覺跟變化率", hint: "手停就靜，一動就震") { p, _ in p.hapStatic = 0.25; p.hapRate = 0.75 },
        Candidate(id: 13, name: "13 質地微震", hint: "手指每走 8 點一下") { p, _ in p.tickSpacing = 8 },
        Candidate(id: 14, name: "14 啵依材質", hint: "黏土一下、麻糬兩下、果凍三下") { p, m in
            switch m {
            case .clay: p.popCount = 1; p.popSharp = 0.3
            case .mochi: p.popCount = 2; p.popGap = 0.1; p.popDecay = 0.4; p.popSharp = 0.4
            case .jelly: p.popCount = 3; p.popGap = 0.09; p.popDecay = 0.5; p.popSharp = 0.5
            }
        },
        Candidate(id: 18, name: "18 關停留門檻（對照）", hint: "抓住就記形，輕按也留痕") { p, _ in p.dwellLo = 0; p.dwellHi = 0 },
        Candidate(id: 19, name: "19 碰到時凍住", hint: "活物感停住，不縮回標準姿勢") { p, _ in p.idleFreeze = 1 },
        Candidate(id: 2, name: "2 偶發特別回彈", hint: "每 8 次放手多晃一下") { p, _ in p.specialEvery = 8 },
        Candidate(id: 9, name: "9 接觸面積壓力", hint: "指腹壓得越扁攤得越開") { p, _ in p.pressRadiusGain = 1 },
        Candidate(id: 41, name: "41 對照：關橫檔", hint: "v2.4 以前：觸手被壓縮會對折") { p, _ in p.tentRung = 0; p.tentAxis = 0 },
    ]
}

/// One tunable slider in the hidden panel (prototype's `F`).
struct TuneField: Identifiable {
    let key: WritableKeyPath<FeelParams, Double>
    let name: String
    let hint: String
    let range: ClosedRange<Double>
    let step: Double
    var section = "手感"
    var id: String { name }

    static let sections = ["手感", "按壓與記形", "活物感", "觸覺", "聲音", "外形"]

    static let all: [TuneField] = [
        TuneField(key: \.alpha, name: "回彈硬度", hint: "越大越快回去、越硬", range: 0.05...0.8, step: 0.01),
        TuneField(key: \.damp, name: "晃動阻尼", hint: "越小放手晃越久", range: 0.85...0.999, step: 0.001),
        TuneField(key: \.grabR, name: "抓取範圍（×半徑）", hint: "一指抓到多大一塊", range: 0.2...0.8, step: 0.01),
        TuneField(key: \.maxPull, name: "拉伸上限（×半徑）", hint: "最多拉多遠", range: 0.6...2.6, step: 0.05),
        TuneField(key: \.lag, name: "黏滯", hint: "跟手的延遲感（秒）；候選 6 是 0.03", range: 0...0.3, step: 0.01),
        TuneField(key: \.wGlobal, name: "整體性", hint: "越大整團越像一塊", range: 0...1, step: 0.01),
        TuneField(key: \.cSpace, name: "區塊間距（×半徑）", hint: "越小區塊越多越軟", range: 0.15...0.7, step: 0.05),
        TuneField(key: \.cRad, name: "區塊半徑（×半徑）", hint: "越小越軟、越容易拉出一塊", range: 0.25...1, step: 0.01),
        TuneField(key: \.upright, name: "回正", hint: "放手後轉回頭朝上的速度", range: 0...0.02, step: 0.001),
        TuneField(key: \.anchor, name: "抓著時的定身", hint: "越大身體越不會整團跟著手走、轉掉", range: 1...8, step: 0.5),
        TuneField(key: \.areaGain, name: "面積壓力", hint: "壓扁時旁邊鼓出來的程度", range: 0...1.5, step: 0.05),
        TuneField(key: \.gripRot, name: "抓著時不轉", hint: "越大拉它時身體越不會歪掉", range: 1...8, step: 0.5),
        TuneField(key: \.tentRung, name: "觸手橫檔", hint: "兩邊成對的粒子不能翻到對面、寬度不低於靜止的幾成；0 關＝v2.4 以前（第 41 條）", range: 0...0.9, step: 0.05),
        TuneField(key: \.tentAxis, name: "觸手中軸不折返", hint: "中軸每一節在上一節方向上至少前進靜止節距的幾成；0 關（第 41 條）", range: 0...1, step: 0.05),

        TuneField(key: \.pressBase, name: "按壓攤開（×半徑）", hint: "按下去那塊往四周攤多少（看得到的約一半）", range: 0...0.3, step: 0.01, section: "按壓與記形"),
        TuneField(key: \.pressHold, name: "按住再攤（×半徑）", hint: "按住不動時再多攤多少", range: 0...0.3, step: 0.01, section: "按壓與記形"),
        TuneField(key: \.pressHoldTime, name: "按壓下沉時間", hint: "按住多久攤到最深（秒）", range: 0.1...2, step: 0.05, section: "按壓與記形"),
        TuneField(key: \.pressRise, name: "按壓時間常數", hint: "攤開多快到位（秒）", range: 0.01...0.3, step: 0.01, section: "按壓與記形"),
        TuneField(key: \.pressFirst, name: "按壓第一幀比例", hint: "按下那一幀先到目標的幾成", range: 0...1, step: 0.05, section: "按壓與記形"),
        TuneField(key: \.pressRadiusGain, name: "接觸面積壓力", hint: "指腹壓扁（majorRadius 變大）再多攤多少；0 關，候選 9 是 1", range: 0...3, step: 0.1, section: "按壓與記形"),
        TuneField(key: \.yield, name: "定型門檻（×半徑）", hint: "變形超過這個才開始留形", range: 0.02...1.5, step: 0.01, section: "按壓與記形"),
        TuneField(key: \.creep, name: "定型速度", hint: "揉多快記住新形狀", range: 0...6, step: 0.1, section: "按壓與記形"),
        TuneField(key: \.dwellLo, name: "定型停留起點", hint: "抓住幾秒後開始記形（秒）", range: 0...1, step: 0.05, section: "按壓與記形"),
        TuneField(key: \.dwellHi, name: "定型停留終點", hint: "抓住幾秒後全速記形（秒）", range: 0...2, step: 0.05, section: "按壓與記形"),
        TuneField(key: \.recover, name: "回原形速度", hint: "放著多快變回原樣", range: 0...1.5, step: 0.01, section: "按壓與記形"),

        TuneField(key: \.life, name: "活物感", hint: "沒碰時自己動的幅度", range: 0...1.5, step: 0.05, section: "活物感"),
        TuneField(key: \.drift, name: "觸手飄動", hint: "沒碰時觸手擺動的幅度（×半徑）", range: 0...0.4, step: 0.01, section: "活物感"),
        TuneField(key: \.wriggle, name: "蠕動", hint: "沒碰時整個身體輪廓慢慢變形的幅度（×半徑）", range: 0...0.2, step: 0.01, section: "活物感"),
        TuneField(key: \.wander, name: "遊走", hint: "沒碰時在畫面裡移動的速度（×半徑／秒）", range: 0...1, step: 0.05, section: "活物感"),
        TuneField(key: \.floppy, name: "觸手軟度", hint: "越大觸手末端越軟、越會甩", range: 0...0.9, step: 0.05, section: "活物感"),
        TuneField(key: \.idleFreeze, name: "碰到時凍住", hint: "1：活物感時鐘停住不歸零（候選 19）", range: 0...1, step: 1, section: "活物感"),
        TuneField(key: \.specialEvery, name: "特別回彈", hint: "每幾次放手來一次特別 Q 的回彈，0 關（候選 2 是 8）", range: 0...12, step: 1, section: "活物感"),

        TuneField(key: \.hapMax, name: "連續觸覺上限", hint: "捏的時候最多震多強", range: 0...1, step: 0.05, section: "觸覺"),
        TuneField(key: \.hapStatic, name: "連續觸覺：變形量比重", hint: "拉著不動也震的那部分", range: 0...1, step: 0.05, section: "觸覺"),
        TuneField(key: \.hapRate, name: "連續觸覺：變化率比重", hint: "正在變才震的那部分（候選 12：0.75，變形量 0.25）", range: 0...1, step: 0.05, section: "觸覺"),
        TuneField(key: \.hapRateNorm, name: "變化率多少算滿", hint: "每秒變形量變化多少算 1", range: 0.5...6, step: 0.1, section: "觸覺"),
        TuneField(key: \.hapSharp, name: "連續觸覺銳利度", hint: "偏悶還是偏脆", range: 0...1, step: 0.05, section: "觸覺"),
        TuneField(key: \.hapSharpStretch, name: "拉伸銳利度加成", hint: "拉長時銳利度多加多少（第三批 15）", range: 0...0.5, step: 0.05, section: "觸覺"),
        TuneField(key: \.popMin, name: "啵最輕", hint: "輕輕放手那一下", range: 0...1, step: 0.05, section: "觸覺"),
        TuneField(key: \.popMax, name: "啵最重", hint: "用力甩或拉到底放手那一下", range: 0...1, step: 0.05, section: "觸覺"),
        TuneField(key: \.popSharp, name: "啵銳利度", hint: "候選 14：黏土 0.3", range: 0...1, step: 0.05, section: "觸覺"),
        TuneField(key: \.popCount, name: "啵幾下", hint: "候選 14：黏土 1、麻糬 2、果凍 3", range: 1...4, step: 1, section: "觸覺"),
        TuneField(key: \.popGap, name: "啵的間隔", hint: "幾下之間隔幾秒", range: 0.03...0.3, step: 0.01, section: "觸覺"),
        TuneField(key: \.popDecay, name: "啵的衰減", hint: "每下是前一下的幾成", range: 0.1...1, step: 0.05, section: "觸覺"),
        TuneField(key: \.tickSpacing, name: "質地微震間距", hint: "手指每走幾點一下；0 關，候選 13 是 8", range: 0...30, step: 1, section: "觸覺"),
        TuneField(key: \.tickMin, name: "微震最輕", hint: "手慢時", range: 0...0.6, step: 0.02, section: "觸覺"),
        TuneField(key: \.tickMax, name: "微震最重", hint: "手快時（每秒 3 個半徑）", range: 0...0.8, step: 0.02, section: "觸覺"),
        TuneField(key: \.tickSharp, name: "微震銳利度", hint: "顆粒偏鈍還是偏脆", range: 0...1, step: 0.05, section: "觸覺"),

        TuneField(key: \.volMaster, name: "主音量", hint: "所有聲音一起", range: 0...1, step: 0.05, section: "聲音"),
        TuneField(key: \.rubMax, name: "揉的音量上限", hint: "揉最快時多大聲", range: 0...1, step: 0.05, section: "聲音"),
        TuneField(key: \.pitchJitter, name: "音高抖動", hint: "每次隨機差多少", range: 0...0.3, step: 0.01, section: "聲音"),

        TuneField(key: \.seed, name: "外形亂數種子", hint: "換一個數字就換一個形狀（會重置）", range: 1...30, step: 1, section: "外形"),
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
