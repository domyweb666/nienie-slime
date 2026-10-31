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
    @Published var muted = false { didSet { sound.muted = muted } }
    @Published private(set) var reduceMotion = UIAccessibility.isReduceMotionEnabled
    /// Blind-test slots (3-4 做法五): two saved parameter sets, switched by number only, kept in UserDefaults.
    @Published private(set) var activeSlot: Int?
    @Published private(set) var slotSaved: [Int: Bool] = [:]
    /// Latency test (3-4 做法三): the screen flashes white for one frame when a finger lands.
    @Published var latencyTest = false
    /// Frame readout for the hidden panel, refreshed a couple of times a second by the view.
    @Published private(set) var stats = SlimeView.FrameStats()

    init() {
        var p: [SlimeMaterial: FeelParams] = [:]
        for m in SlimeMaterial.allCases { p[m] = m.defaults }
        params = p
        rig = SlimeRig(params: SlimeMaterial.clay.defaults)
        rig.reduceMotion = reduceMotion
        rig.onEvent = { [weak self] e in self?.handle(e) }
        for n in [1, 2] { slotSaved[n] = UserDefaults.standard.data(forKey: Self.slotKey(n)) != nil }

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
            self?.sound.rub(level: 0)
        }
    }

    var current: FeelParams { params[material] ?? material.defaults }

    // MARK: - Events → sound + haptics (same event, same frame)

    private func handle(_ e: SlimeEvent) {
        switch e {
        case .press(let gain):
            sound.press(gain: gain)
            haptics.transient(intensity: 0.25 + 0.35 * gain, sharpness: 0.2)
        case .pull(let gain, let rate):
            sound.pull(gain: gain, rate: rate)
            haptics.transient(intensity: 0.15 + 0.2 * gain, sharpness: 0.5)
        case .release(let gain, let rate):
            sound.release(gain: gain, rate: rate)
            haptics.pop(strength: (gain - 0.35) / 0.65)
        case .tap:
            sound.press(gain: 0.5)
            haptics.transient(intensity: 0.45, sharpness: 0.35)
        }
    }

    /// Called by the slime view once per display frame, after the rig stepped.
    func frame(dt: Double) {
        sound.rub(level: rig.rubLevel())
        haptics.updateContinuous(deformation: rig.isTouched ? rig.deformation : 0)
    }

    func report(_ s: SlimeView.FrameStats) { stats = s }

    var audioBufferMs: Double { AVAudioSession.sharedInstance().ioBufferDuration * 1000 }

    /// One line for the panel: real Hz, worst frame, dropped frames, main-thread work, finger contact radius, audio buffer.
    var hudText: String {
        String(format: "%.0f Hz｜最長幀 %.1f ms｜掉 %ld｜算 %.2f ms｜指 %.0f pt｜音訊緩衝 %.1f ms",
               stats.hz, stats.maxFrameMs, stats.dropped, stats.workMs, stats.touchRadius, audioBufferMs)
    }

    // MARK: - Buttons

    func select(_ m: SlimeMaterial) {
        material = m
        rig.params = current
        activeSlot = nil
        rig.bump(2)
        sound.press(gain: 0.5)
    }

    /// 揉回原形: the remembered shape fades back over half a second, no jump (手感精修提案 第 28 條).
    func resetShape() {
        rig.relax()
        rig.bump(1)
        sound.press(gain: 0.7)
    }

    // MARK: - Tuning panel

    func binding(for field: TuneField) -> Binding<Double> {
        Binding(
            get: { self.current[keyPath: field.key] },
            set: { v in
                var p = self.current
                p[keyPath: field.key] = v
                self.params[self.material] = p
                self.rig.params = p
                self.activeSlot = nil
            }
        )
    }

    func restoreDefaults() {
        params[material] = material.defaults
        rig.params = current
        activeSlot = nil
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
        rig.params = p
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
