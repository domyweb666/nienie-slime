import AVFoundation
import CoreMotion
import SwiftUI
import UIKit

/// Glue between the SwiftUI chrome and the slime: owns the rig, sound and haptics,
/// and routes each rig event to picture, sound and touch in the same frame.
final class SlimeController: ObservableObject {
    let rig: SlimeRig
    let haptics = SlimeHaptics()
    let sound: SlimeSoundSource = SlimeAudio()

    @Published private(set) var material: SlimeMaterial = .clay   // 多米 2026-10-31 選黏土
    /// v2.23 收集: the slime on screen (its material is the default material; the panel can swap the material for a blind test)
    @Published private(set) var slime: SlimeKind = .honey
    private var impressions: [SlimeKind: (trust: Double, wary: Double)] = [:]   // each slime's impression, this run only
    @Published private(set) var params: [SlimeMaterial: FeelParams]
    /// v2.21 speaker button: 0 music and sounds, 1 sounds only, 2 silent
    @Published var soundMode = 0 { didSet { sound.muted = soundMode == 2; syncAudio() } }
    /// v2.40 環境音: "rain", "fire" or "lofi", kept in UserDefaults (long press the speaker button to choose)
    @Published var ambience = UserDefaults.standard.string(forKey: "nienie.amb") ?? "rain" {
        didSet { UserDefaults.standard.set(ambience, forKey: "nienie.amb"); sound.setAmbience(ambience) }
    }
    @Published private(set) var reduceMotion = UIAccessibility.isReduceMotionEnabled
    /// Blind-test slots (3-4 做法五): two saved parameter sets, switched by number only, kept in UserDefaults.
    @Published private(set) var activeSlot: Int?
    @Published private(set) var slotSaved: [Int: Bool] = [:]
    /// Latency test (3-4 做法三): the screen flashes white for one frame when a finger lands.
    @Published var latencyTest = false
    /// 走路 (v2.31 批次 4): the gift stone was tapped, the app asks whether it may know how far you walked
    @Published var walkAsk = false
    private let pedometer = CMPedometer()
    /// v2.31 搖晃沉澱: the phone's shakes from CoreMotion (no permission needed natively), one shake at most every 0.18 s
    private let motion = CMMotionManager()
    private var lastShakeAt: TimeInterval = 0
    /// The panel's readout: the strongest shake in the last 2 s (m/s²), so a shake that does nothing tells whether the sensor is off or the threshold is too high
    private var shakePeak = 0.0, shakePeakAt: TimeInterval = 0
    /// Frame readout for the hidden panel, refreshed a couple of times a second by the view.
    @Published private(set) var stats = SlimeView.FrameStats()

    // continuous-haptic shaping state (提案第 12 條)
    private var lastDeformation = 0.0
    private var rateSmoothed = 0.0

    init() {
        var p: [SlimeMaterial: FeelParams] = [:]
        for m in SlimeMaterial.allCases { p[m] = m.defaults }
        params = p
        // v2.33 一隻為主: always 芋圓 while 一隻為主 is on (the default); off, the slime chosen last time
        let saved = SlimeMaterial.clay.defaults.one >= 0.5 ? SlimeKind.taro : (SlimeKind(rawValue: UserDefaults.standard.string(forKey: "slime") ?? "") ?? .honey)
        slime = saved; material = saved.material
        var start = saved.material.defaults
        saved.apply(&start)
        rig = SlimeRig(params: start)
        rig.reduceMotion = reduceMotion
        rig.onEvent = { [weak self] e in self?.handle(e) }
        rig.onGiftTap = { [weak self] in self?.walkAsk = true }
        // v2.34 熟留下來: each slime's saved trust comes back before anything can store a 0 over it; wariness starts at 0
        savedTrust = Self.trustLoad()
        if start.trKeep >= 0.5 {
            for (k, tr) in savedTrust { impressions[k] = (tr, 0) }
            if let tr = savedTrust[saved] { rig.setImpression(trust: tr, wary: 0) }
        }
        for n in [1, 2] { slotSaved[n] = UserDefaults.standard.data(forKey: Self.slotKey(n)) != nil }
        syncAudio()
        sound.setAmbience(ambience)   // v2.40 環境音, once at launch
        rig.walkOpen()   // 走路: the second open leaves the gift stone
        walkReadSteps()
        startMotion()   // v2.31 搖晃沉澱

        NotificationCenter.default.addObserver(forName: UIAccessibility.reduceMotionStatusDidChangeNotification,
                                               object: nil, queue: .main) { [weak self] _ in
            guard let self else { return }
            self.reduceMotion = UIAccessibility.isReduceMotionEnabled
            self.rig.reduceMotion = self.reduceMotion
        }
        NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification,
                                               object: nil, queue: .main) { [weak self] _ in
            self?.rig.cancelAllTouches()
            self?.haptics.stopContinuous()
            self?.sound.stopAll()
            self?.motion.stopDeviceMotionUpdates()
            self?.trustSave(force: true)   // v2.34: leaving, write the trust now
        }
        // v2.20: the impression lives for this run only; 10 min or more in the background and it is a first meeting again
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification,
                                               object: nil, queue: .main) { [weak self] _ in self?.backgroundAt = Date() }
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification,
                                               object: nil, queue: .main) { [weak self] _ in
            guard let self, let at = self.backgroundAt else { return }
            if Date().timeIntervalSince(at) >= 600 {
                if self.current.trKeep >= 0.5 {   // v2.34: only the wariness goes; the trust stays
                    self.rig.setImpression(trust: self.rig.impTrust, wary: 0)
                    self.impressions = self.impressions.mapValues { (trust: $0.trust, wary: 0.0) }
                } else { self.rig.resetImpression(); self.impressions = [:] }
            }
            self.backgroundAt = nil
            self.walkReadSteps()   // 走路: what you walked while it was away
            self.startMotion()
        }
        // 搖晃沉澱 (多米 11-08: shaking does nothing on build 117): a system alert resigns active without going to the background
        // (the motion & fitness prompt after 好 on the gift stone, Control Center, a banner pulled down), so willEnterForeground never came
        // and the shake stayed stopped until the app went to the background. Every return to active turns it back on
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification,
                                               object: nil, queue: .main) { [weak self] _ in self?.startMotion() }
    }

    /// The material's numbers with the chosen slime's shape seed and personality on top.
    var current: FeelParams {
        var p = params[material] ?? material.defaults
        slime.apply(&p)
        return p
    }

    // MARK: - Events → sound + haptics (same event, same frame)

    private func handle(_ e: SlimeEvent) {
        let p = current
        switch e {
        case .press(let gain):
            sound.press(intensity: pressIntensity(gain, radius: rig.maxTouchRadius, weight: p.sndPressSize))
            haptics.transient(intensity: 0.25 + 0.35 * gain, sharpness: p.pressSharp)
        case .squish(let gain):
            // 提案第 24 條: two fingers pinching closer
            sound.press(intensity: gain)
            haptics.transient(intensity: 0.3 + 0.4 * gain, sharpness: 0.3)
        case .pull(let gain, let rate):
            _ = rate   // pitch now follows the stretch inside the audio (v2 layered sound)
            sound.strand(gain: gain)
            if p.tickSpacing <= 0 { haptics.transient(intensity: 0.15 + 0.2 * gain, sharpness: 0.5) }   // v2.25: with grains the stretch is already felt
        case .release(let gain, let rate, let special):
            // special (偶發特別回彈): louder sample, one extra tap
            let g = special ? min(1, gain * 1.3) : gain
            // 候選 17: the pop plays as an audio event inside the haptic pattern instead of through AVAudioEngine
            let viaHaptics = p.popViaHaptics >= 0.5 && haptics.popAudioReady
            _ = rate
            if !viaHaptics { sound.release(gain: g) }
            let s = max(0, min(1, (gain - 0.35) / 0.65))
            // v2.25 F5: a gentle release one tap, a hard one the whole train; with inertia on the taps follow its swing (half a period)
            let extra: Int = Int((max(0, p.popCount - 1) * s).rounded()), popGap: Double = p.inertiaHz > 0 ? 1 / (2 * p.inertiaHz) : p.popGap
            haptics.pop(strength: s, count: 1 + extra + (special ? 1 : 0), gap: popGap, decay: p.popDecay,
                        sharpness: p.popSharp, minIntensity: p.popMin, maxIntensity: p.popMax, audioVolume: viaHaptics ? g : nil)
        case .tick(let gain):
            haptics.tick(intensity: p.tickMin + (p.tickMax - p.tickMin) * gain, sharpness: p.tickSharp + p.hapSharpStretch * rig.stretchLevel)
        case .grain(let gain):
            haptics.tick(intensity: p.grainMin + (p.grainMax - p.grainMin) * gain, sharpness: p.grainSharp)   // v2.25 F5
        case .tap:
            sound.press(intensity: 0.5)
            haptics.transient(intensity: 0.45, sharpness: 0.35)
        case .voice(let kind, let gain, let rate):
            sound.voice(kind, gain: gain, rate: rate)
        case .land(let gain):
            // v2.28 窗台: it landed after a fall or a hop (the web plays the press sound); a soft dull tap
            sound.press(intensity: gain * 0.6)
            haptics.transient(intensity: 0.15 + 0.3 * gain, sharpness: 0.2)
        case .ding(let gain):
            // v2.31 搖晃沉澱: settled clear; a small bright tap with it
            sound.ding(gain: gain)
            haptics.transient(intensity: 0.3, sharpness: 0.6)
        case .beat:
            // v2.23 C6: one beat of its answer to your rhythm, a soft round tap
            haptics.transient(intensity: 0.3, sharpness: 0.2)
        case .nudge:
            // v2.20 C1: it swam over and touched your resting finger: one soft, round tap (lighter than a press)
            sound.press(intensity: 0.2)
            haptics.transient(intensity: 0.2, sharpness: 0.15)
        }
    }

    /// Called by the slime view once per display frame, after the rig stepped.
    func frame(dt: Double) {
        let p = current
        // v2 layered sound: the strand loop, strands, rub loop and the after-release tail all follow the physics here
        sound.frame(dt: dt, rub: rig.rubLevel() * p.rubMax, stretch: rig.pullStretch, grabbing: rig.isGrabbing)
        // continuous haptic from the deformation and/or its rate of change (提案第 12 條); with the default
        // weights (static 1, rate 0) this is the old intensity = deformation^1.5 × hapMax
        let deformation = (p.hapStatic > 0 || p.hapRate > 0) && rig.isTouched ? rig.deformation : 0
        let rate = abs(deformation - lastDeformation) / max(1e-4, dt)
        lastDeformation = deformation
        rateSmoothed += (rate - rateSmoothed) * (1 - exp(-dt / 0.04))
        let level = p.hapStatic * pow(deformation, 1.5) + p.hapRate * min(1, rateSmoothed / max(0.01, p.hapRateNorm))
        // 提案第 15 條: sharpness rises when stretched, drops a little when squashing
        var contLevel: Double = min(1, level) * p.hapMax
        var contSharp: Double = p.hapSharp + p.hapSharpStretch * rig.stretchLevel - p.hapSharpSquash * rig.squashLevel
        let pk = rig.purr * p.purr
        // v2.25 F5: the purr is the one thing left on the continuous channel: a low rumble swelling 3 times a second
        if p.purrRoll >= 0.5 && pk > 0.05 {
            purrPhase = (purrPhase + dt * 3).truncatingRemainder(dividingBy: 1)
            let am: Double = 0.65 + 0.35 * sin(2 * Double.pi * purrPhase)
            contLevel = max(contLevel, (0.12 + 0.28 * min(1, pk)) * am)
            contSharp = 0.05
        }
        haptics.updateContinuous(level: contLevel, sharpness: contSharp)
        // v2.18 呼嚕: stroked gently while comfortable, two soft taps every half second, the second weaker (a purr is a slow
        // rumble; the phone can only tap). Strength from the rig's purr level × the panel's purr
        if p.purrRoll < 0.5 && pk > 0.05 {
            purrClock += dt
            if purrClock >= 0.5 { purrClock = 0; purrSecond = 0.09; haptics.transient(intensity: 0.12 + 0.25 * min(1, pk), sharpness: 0.05) }
            if purrSecond > 0 { purrSecond -= dt; if purrSecond <= 0 { haptics.transient(intensity: 0.07 + 0.15 * min(1, pk), sharpness: 0.05) } }
        } else { purrClock = 0.5; purrSecond = 0 }
        // v2.19 A4: held still for 0.8 s, each breath comes through the finger as one very soft tap (the purr takes over once it purrs)
        if p.life2 >= 0.5 && p.lifeHeld >= 0.5 && pk <= 0.05 && rig.heldStill > 0.8 && rig.breathBeat != lastBreathBeat {
            haptics.transient(intensity: 0.11, sharpness: 0.05)
        }
        lastBreathBeat = rig.breathBeat
        haptics.flush()
        trustClock += dt
        if trustClock >= 3 { trustClock = 0; trustSave(force: false) }   // v2.34: every 3 s, only when it changed
    }
    private var trustClock = 0.0

    // MARK: - v2.34 熟留下來: trust per slime in UserDefaults ("nienie.imp", {"v":1,"tr":{"taro":0.55}}), same shape as the web's localStorage

    private var savedTrust: [SlimeKind: Double] = [:]
    private static func trustLoad() -> [SlimeKind: Double] {
        guard let d = UserDefaults.standard.data(forKey: "nienie.imp"),
              let o = (try? JSONSerialization.jsonObject(with: d)) as? [String: Any],
              let tr = o["tr"] as? [String: Double] else { return [:] }
        var out: [SlimeKind: Double] = [:]
        for (k, v) in tr { if let s = SlimeKind(rawValue: k), v.isFinite { out[s] = max(0, min(1, v)) } }
        return out
    }
    /// Writes when a slime's trust moved by more than 0.005 since the last write (force: on leaving, any change)
    private func trustSave(force: Bool) {
        guard current.trKeep >= 0.5 else { return }
        var all = savedTrust
        for (k, v) in impressions { all[k] = v.trust }
        all[slime] = rig.impTrust
        let moved = all.contains { k, v in abs(v - (savedTrust[k] ?? -1)) > (force ? 1e-6 : 0.005) }
        guard moved else { return }
        var tr: [String: Double] = [:]
        for (k, v) in all { tr[k.rawValue] = (v * 1000).rounded() / 1000 }
        guard let d = try? JSONSerialization.data(withJSONObject: ["v": 1, "tr": tr]) else { return }
        UserDefaults.standard.set(d, forKey: "nienie.imp")
        savedTrust = all
    }
    private var purrClock = 0.5, purrSecond = 0.0, lastBreathBeat = 0, purrPhase = 0.0
    private var backgroundAt: Date?

    func report(_ s: SlimeView.FrameStats) { stats = s }

    /// v2.25 F5 haptic ladder (panel): how faint can this phone still be felt? No public number, only the hand can answer
    func hapticTest(_ intensity: Double, continuous: Bool) { haptics.test(intensity: intensity, continuous: continuous) }

    var audioBufferMs: Double { AVAudioSession.sharedInstance().ioBufferDuration * 1000 }

    /// One line for the panel: real Hz, worst frame, dropped frames, main-thread work, finger contact radius, audio buffer;
    /// then the shake sensor: on or off, the strongest shake in the last 2 s against the threshold (both m/s²).
    var hudText: String {
        String(format: "%.0f Hz｜最長幀 %.1f ms｜掉 %ld｜算 %.2f ms｜指 %.0f pt｜音訊緩衝 %.1f ms",
               stats.hz, stats.maxFrameMs, stats.dropped, stats.workMs, stats.touchRadius, audioBufferMs)
        + "｜晃動感測 " + (motion.isDeviceMotionActive ? "開" : "關")
        + String(format: " %.1f／門檻 %.1f", shakePeak, current.shakeG)
    }

    // MARK: - Parameter plumbing

    private func pushParams() {
        rig.params = current
        syncAudio()
        haptics.setAudioThroughHaptics(current.popViaHaptics >= 0.5, url: sound.releaseSampleURL)
    }

    private func syncAudio() {
        sound.master = current.volMaster
        sound.pitchJitter = current.pitchJitter
        sound.pullMax = current.sndPullMax
        sound.rubMax = current.rubMax
        sound.settleAmt = current.sndSettle
        sound.music = soundMode == 0 ? current.volMusic : 0
    }

    /// Press loudness from how the finger landed and how big its contact patch is (UITouch.majorRadius):
    /// a fingertip (~18 pt) plays lighter, a flat finger pad (~42 pt) heavier. 0 = unknown radius → unchanged.
    private func pressIntensity(_ gain: Double, radius: Double, weight: Double) -> Double {
        guard radius > 0 else { return gain }
        let size = max(0, min(1, (radius - 18) / 24))
        return max(0, min(1, gain * (1 + weight * (0.8 * size - 0.4))))
    }

    // MARK: - 走路 (v2.31 批次 4): real steps from CMPedometer, only after 多米 said yes on the gift stone; the steps stay on this phone

    func walkAnswer(_ yes: Bool) {
        rig.walkAnswer(yes)
        if yes {   // it counts from this morning: what you already walked today counts
            UserDefaults.standard.set(Calendar.current.startOfDay(for: Date()), forKey: "nienie.walk.lastRead")
            walkReadSteps()
        }
    }
    /// The panel's pretend steps (the web has the same buttons)
    func walkFake(_ n: Int) { rig.walkBankSteps(n) }
    func walkClear() { rig.walkClear(); UserDefaults.standard.removeObject(forKey: "nienie.walk.lastRead") }
    private func walkReadSteps() {
        guard rig.walkPerm == "ok", CMPedometer.isStepCountingAvailable() else { return }
        let now = Date()
        let from = (UserDefaults.standard.object(forKey: "nienie.walk.lastRead") as? Date) ?? Calendar.current.startOfDay(for: now)
        guard now.timeIntervalSince(from) > 1 else { return }
        pedometer.queryPedometerData(from: from, to: now) { [weak self] data, error in
            DispatchQueue.main.async {
                guard let self, error == nil, let n = data?.numberOfSteps.intValue else { return }
                UserDefaults.standard.set(now, forKey: "nienie.walk.lastRead")
                if n > 0 { self.rig.walkBankSteps(n) }
            }
        }
    }

    // MARK: - v2.31 搖晃沉澱: the phone's shakes, and the panel's pretend ones

    /// Device motion at 60 Hz; the acceleration without gravity, in m/s², past shakeG counts as one shake. Screen direction: the phone flung right, it goes left in the bowl.
    private func startMotion() {
        guard motion.isDeviceMotionAvailable, !motion.isDeviceMotionActive else { return }
        motion.deviceMotionUpdateInterval = 1.0 / 60
        motion.startDeviceMotionUpdates(to: .main) { [weak self] m, _ in
            guard let self, let m else { return }
            let a = m.userAcceleration
            let mag = sqrt(a.x * a.x + a.y * a.y + a.z * a.z) * 9.81
            let now = m.timestamp
            if mag > self.shakePeak || now - self.shakePeakAt > 2 { self.shakePeak = mag; self.shakePeakAt = now }
            if mag > self.current.shakeG && now - self.lastShakeAt > 0.18 {
                self.lastShakeAt = now
                self.rig.shake(dx: -a.x, dy: a.y)
            }
        }
    }
    /// The panel: 假裝搖一下 / 三下 (220 ms apart, alternating sides) / 立刻沉澱
    func shakeFake(_ n: Int) {
        if n <= 1 { rig.shake(dx: 0, dy: 0); return }
        for k in 0..<n {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22 * Double(k)) { [weak self] in self?.rig.shake(dx: k % 2 == 1 ? 1 : -1, dy: -0.5) }
        }
    }
    func shakeSettleNow() { rig.shakeSettleNow() }

    // MARK: - Buttons

    /// v2.23 收集: another slime swims in (its own colours, shape, personality; its impression from earlier this run comes back).
    func select(_ k: SlimeKind) {
        guard k != slime else { return }
        impressions[slime] = (rig.impTrust, rig.impWary)
        slime = k; material = k.material
        UserDefaults.standard.set(k.rawValue, forKey: "slime")
        pushParams()
        activeSlot = nil
        rig.resetShape()
        if let imp = impressions[k] { rig.setImpression(trust: imp.trust, wary: imp.wary) }
        else if current.trKeep >= 0.5, let tr = savedTrust[k] { rig.setImpression(trust: tr, wary: 0) }   // v2.34
        else { rig.resetImpression() }
        rig.startIntro()
        sound.press(intensity: 0.5)
    }

    /// Panel only: the same slime on another material (blind tests).
    func selectMaterial(_ m: SlimeMaterial) {
        material = m
        pushParams()
        activeSlot = nil
        rig.bump(2)
        sound.press(intensity: 0.5)
    }

    /// 揉回原形: the remembered shape fades back over half a second, no jump (手感精修提案 第 28 條).
    func resetShape() {
        rig.relax()
        rig.bump(1)
        sound.press(intensity: 0.7)
    }

    // MARK: - Tuning panel

    func binding(for field: TuneField) -> Binding<Double> {
        Binding(
            get: { self.current[keyPath: field.key] },
            set: { v in
                var p = self.current
                p[keyPath: field.key] = v
                self.params[self.material] = p
                self.pushParams()
                self.activeSlot = nil
            }
        )
    }

    func restoreDefaults() {
        params[material] = material.defaults
        pushParams()
        activeSlot = nil
    }

    /// Apply one second-batch candidate on top of the current numbers (one at a time for blind tests).
    func applyCandidate(_ c: Candidate) {
        var p = current
        c.apply(&p, material)
        params[material] = p
        pushParams()
        activeSlot = nil
        rig.bump(1)
    }

    // MARK: - Blind-test slots

    private static func slotKey(_ n: Int) -> String { "feelSlot\(n)" }

    func saveSlot(_ n: Int) {
        guard let data = try? JSONEncoder().encode(current) else { return }
        UserDefaults.standard.set(data, forKey: Self.slotKey(n))
        slotSaved[n] = true
        activeSlot = n
    }

    /// A slot saved by an older build lacks the parameters added since; decoding it straight fails as a whole (every new
    /// parameter broke the old slots). Lay the saved keys over the current numbers instead: missing keys keep today's value,
    /// unknown keys are dropped.
    private func decodeSlot(_ data: Data) -> FeelParams? {
        guard let baseData = try? JSONEncoder().encode(current),
              var base = (try? JSONSerialization.jsonObject(with: baseData)) as? [String: Any],
              let saved = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else { return nil }
        for (k, v) in saved where base[k] != nil { base[k] = v }
        guard let merged = try? JSONSerialization.data(withJSONObject: base) else { return nil }
        return try? JSONDecoder().decode(FeelParams.self, from: merged)
    }

    func loadSlot(_ n: Int) {
        guard let data = UserDefaults.standard.data(forKey: Self.slotKey(n)),
              let p = decodeSlot(data) else { return }
        params[material] = p
        pushParams()
        activeSlot = n
        rig.bump(1)
    }

    /// Same JSON shape as the prototype's 複製數值.
    var exportText: String {
        let p = current
        let pairs = TuneField.all.map { f in "\"\(f.name)\":\(Self.fmt(p[keyPath: f.key]))" }
        return "{\"史萊姆\":\"\(slime.name)\",\"手感\":\"\(material.name)\"," + pairs.joined(separator: ",") + "}"
    }

    private static func fmt(_ v: Double) -> String {
        let r = (v * 1000).rounded() / 1000
        return r == r.rounded() ? String(Int(r)) : String(r)
    }
}
