import SwiftUI
import UIKit

/// Glue between the SwiftUI chrome and the slime: owns the rig, sound and haptics,
/// and routes each rig event to picture, sound and touch in the same frame.
final class SlimeController: ObservableObject {
    let rig: SlimeRig
    let haptics = SlimeHaptics()
    let sound: SlimeSoundSource = SlimeAudio()

    @Published private(set) var material: SlimeMaterial = .mochi
    @Published private(set) var params: [SlimeMaterial: FeelParams]
    @Published var muted = false { didSet { sound.muted = muted } }
    @Published var soundStyle: SoundStyle = .wet { didSet { sound.style = soundStyle } }
    @Published private(set) var reduceMotion = UIAccessibility.isReduceMotionEnabled

    init() {
        var p: [SlimeMaterial: FeelParams] = [:]
        for m in SlimeMaterial.allCases { p[m] = m.defaults }
        params = p
        rig = SlimeRig(params: SlimeMaterial.mochi.defaults)
        rig.reduceMotion = reduceMotion
        sound.pitch = rig.params.pitch
        rig.onEvent = { [weak self] e in self?.handle(e) }

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
        }
    }

    var current: FeelParams { params[material] ?? material.defaults }

    // MARK: - Events → sound + haptics

    private func handle(_ e: SlimeEvent) {
        switch e {
        case .squish(let i):
            sound.press(i)
            haptics.transient(intensity: 0.25 + 0.35 * i, sharpness: 0.2)
        case .tap:
            sound.tap()
            haptics.transient(intensity: 0.45, sharpness: 0.35)
        case .boing(let i):
            sound.release(i)
            haptics.pop(strength: i)
        case .creak(let i):
            sound.stretch(i)
            haptics.transient(intensity: 0.15 + 0.2 * i, sharpness: 0.5)
        }
    }

    /// Called by the slime view once per display frame, after the rig stepped.
    func frame(dt: Double) {
        sound.bed(speed: rig.kneadSpeed(dt: dt), dt: dt)
        haptics.updateContinuous(deformation: rig.isTouched ? rig.deformation : 0)
    }

    // MARK: - Buttons

    func select(_ m: SlimeMaterial) {
        material = m
        rig.params = current
        sound.pitch = current.pitch
        rig.bump(3)
        sound.press(0.4)
    }

    func resetShape() {
        rig.resetShape()
        sound.press(0.7)
    }

    func previewSoundStyle(_ s: SoundStyle) {
        soundStyle = s
        sound.press(0.6)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) { [weak self] in self?.sound.release(0.6) }
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
            }
        )
    }

    func restoreDefaults() {
        params[material] = material.defaults
        rig.params = current
        sound.pitch = current.pitch
    }

    /// Same JSON shape as the prototype's 複製數值.
    var exportText: String {
        let p = current
        let pairs = TuneField.all.map { f in "\"\(f.name)\":\(Self.fmt(p[keyPath: f.key]))" }
        return "{\"手感\":\"\(material.name)\"," + pairs.joined(separator: ",") + "}"
    }

    private static func fmt(_ v: Double) -> String {
        let r = (v * 100).rounded() / 100
        return r == r.rounded() ? String(Int(r)) : String(r)
    }
}
