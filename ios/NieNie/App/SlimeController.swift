import AVFoundation
import SwiftUI
import UIKit

/// Glue between the SwiftUI chrome and the slime: owns the rig, sound and haptics,
/// and routes each rig event to picture, sound and touch in the same frame.
final class SlimeController: ObservableObject {
    let rig: SlimeRig
    let haptics = SlimeHaptics()
    let sound: SlimeSoundSource = SlimeAudio()

    @Published private(set) var material: SlimeMaterial = .clay   // 多米 2026-10-31 選黏土
    @Published private(set) var params: [SlimeMaterial: FeelParams]
    /// v2.21 speaker button: 0 music and sounds, 1 sounds only, 2 silent
    @Published var soundMode = 0 { didSet { sound.muted = soundMode == 2; syncAudio() } }
    @Published private(set) var reduceMotion = UIAccessibility.isReduceMotionEnabled
    /// Blind-test slots (3-4 做法五): two saved parameter sets, switched by number only, kept in UserDefaults.
    @Published private(set) var activeSlot: Int?
    @Published private(set) var slotSaved: [Int: Bool] = [:]
    /// Latency test (3-4 做法三): the screen flashes white for one frame when a finger lands.
    @Published var latencyTest = false
    /// Frame readout for the hidden panel, refreshed a couple of times a second by the view.
    @Published private(set) var stats = SlimeView.FrameStats()

    // continuous-haptic shaping state (提案第 12 條)
    private var lastDeformation = 0.0
    private var rateSmoothed = 0.0

    init() {
        var p: [SlimeMaterial: FeelParams] = [:]
        for m in SlimeMaterial.allCases { p[m] = m.defaults }
        params = p
        rig = SlimeRig(params: SlimeMaterial.clay.defaults)
        rig.reduceMotion = reduceMotion
        rig.onEvent = { [weak self] e in self?.handle(e) }
        for n in [1, 2] { slotSaved[n] = UserDefaults.standard.data(forKey: Self.slotKey(n)) != nil }
        syncAudio()

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
        }
        // v2.20: the impression lives for this run only; 10 min or more in the background and it is a first meeting again
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification,
                                               object: nil, queue: .main) { [weak self] _ in self?.backgroundAt = Date() }
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification,
                                               object: nil, queue: .main) { [weak self] _ in
            guard let self, let at = self.backgroundAt else { return }
            if Date().timeIntervalSince(at) >= 600 { self.rig.resetImpression() }
            self.backgroundAt = nil
        }
    }

    var current: FeelParams { params[material] ?? material.defaults }

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
            haptics.transient(intensity: 0.15 + 0.2 * gain, sharpness: 0.5)
        case .release(let gain, let rate, let special):
            // special (偶發特別回彈): louder sample, one extra tap
            let g = special ? min(1, gain * 1.3) : gain
            // 候選 17: the pop plays as an audio event inside the haptic pattern instead of through AVAudioEngine
            let viaHaptics = p.popViaHaptics >= 0.5 && haptics.popAudioReady
            _ = rate
            if !viaHaptics { sound.release(gain: g) }
            let s = max(0, min(1, (gain - 0.35) / 0.65))
            haptics.pop(strength: s, count: Int(p.popCount.rounded()) + (special ? 1 : 0), gap: p.popGap, decay: p.popDecay,
                        sharpness: p.popSharp, minIntensity: p.popMin, maxIntensity: p.popMax, audioVolume: viaHaptics ? g : nil)
        case .tick(let gain):
            haptics.tick(intensity: p.tickMin + (p.tickMax - p.tickMin) * gain, sharpness: p.tickSharp)
        case .tap:
            sound.press(intensity: 0.5)
            haptics.transient(intensity: 0.45, sharpness: 0.35)
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
        let deformation = rig.isTouched ? rig.deformation : 0
        let rate = abs(deformation - lastDeformation) / max(1e-4, dt)
        lastDeformation = deformation
        rateSmoothed += (rate - rateSmoothed) * (1 - exp(-dt / 0.04))
        let level = p.hapStatic * pow(deformation, 1.5) + p.hapRate * min(1, rateSmoothed / max(0.01, p.hapRateNorm))
        // 提案第 15 條: sharpness rises when stretched, drops a little when squashing
        haptics.updateContinuous(level: min(1, level) * p.hapMax,
                                 sharpness: p.hapSharp + p.hapSharpStretch * rig.stretchLevel - p.hapSharpSquash * rig.squashLevel)
        // v2.18 呼嚕: stroked gently while comfortable, two soft taps every half second, the second weaker (a purr is a slow
        // rumble; the phone can only tap). Strength from the rig's purr level × the panel's purr
        let pk = rig.purr * p.purr
        if pk > 0.05 {
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
    }
    private var purrClock = 0.5, purrSecond = 0.0, lastBreathBeat = 0
    private var backgroundAt: Date?

    func report(_ s: SlimeView.FrameStats) { stats = s }

    var audioBufferMs: Double { AVAudioSession.sharedInstance().ioBufferDuration * 1000 }

    /// One line for the panel: real Hz, worst frame, dropped frames, main-thread work, finger contact radius, audio buffer.
    var hudText: String {
        String(format: "%.0f Hz｜最長幀 %.1f ms｜掉 %ld｜算 %.2f ms｜指 %.0f pt｜音訊緩衝 %.1f ms",
               stats.hz, stats.maxFrameMs, stats.dropped, stats.workMs, stats.touchRadius, audioBufferMs)
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

    // MARK: - Buttons

    func select(_ m: SlimeMaterial) {
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

    func loadSlot(_ n: Int) {
        guard let data = UserDefaults.standard.data(forKey: Self.slotKey(n)),
              let p = try? JSONDecoder().decode(FeelParams.self, from: data) else { return }
        params[material] = p
        pushParams()
        activeSlot = n
        rig.bump(1)
    }

    /// Same JSON shape as the prototype's 複製數值.
    var exportText: String {
        let p = current
        let pairs = TuneField.all.map { f in "\"\(f.name)\":\(Self.fmt(p[keyPath: f.key]))" }
        return "{\"手感\":\"\(material.name)\"," + pairs.joined(separator: ",") + "}"
    }

    private static func fmt(_ v: Double) -> String {
        let r = (v * 1000).rounded() / 1000
        return r == r.rounded() ? String(Int(r)) : String(r)
    }
}
