import CoreHaptics
import UIKit

/// Two kinds of haptics (2-4 #5):
/// - continuous: one long event whose intensity follows how deformed the slime is
///   (intensity = deformation^1.5, 0...0.8, sharpness ~0.25)
/// - transient: the "pop" on release, stronger when released harder
final class SlimeHaptics {
    var enabled = true { didSet { if !enabled { stopContinuous() } } }

    private let supported = CHHapticEngine.capabilitiesForHardware().supportsHaptics
    private var engine: CHHapticEngine?
    private var engineRunning = false
    private var continuous: CHHapticAdvancedPatternPlayer?
    private var lastSentIntensity: Float = -1

    let continuousSharpness: Float = 0.25
    let continuousMax: Double = 0.8

    init() {
        guard supported else { return }
        do {
            let e = try CHHapticEngine()
            e.playsHapticsOnly = true
            e.isAutoShutdownEnabled = false
            e.stoppedHandler = { [weak self] _ in
                DispatchQueue.main.async {
                    self?.engineRunning = false
                    self?.continuous = nil
                }
            }
            e.resetHandler = { [weak self] in
                DispatchQueue.main.async {
                    self?.engineRunning = false
                    self?.continuous = nil
                    self?.startEngine()
                }
            }
            engine = e
            startEngine()
        } catch {
            engine = nil
        }
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            self?.startEngine()
        }
    }

    private func startEngine() {
        guard let engine, !engineRunning else { return }
        do {
            try engine.start()
            engineRunning = true
        } catch {
            engineRunning = false
        }
    }

    /// Called every frame. `deformation` is 0...1; pass 0 when no finger is on the slime.
    func updateContinuous(deformation: Double) {
        guard enabled, supported else { return }
        let intensity = Float(min(continuousMax, pow(max(0, deformation), 1.5) * continuousMax))
        if intensity < 0.01 {
            stopContinuous()
            return
        }
        startEngine()
        guard let engine, engineRunning else { return }
        if continuous == nil {
            do {
                let event = CHHapticEvent(eventType: .hapticContinuous, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: continuousSharpness),
                ], relativeTime: 0, duration: 60)
                let player = try engine.makeAdvancedPlayer(with: CHHapticPattern(events: [event], parameters: []))
                player.loopEnabled = true
                try player.sendParameters([CHHapticDynamicParameter(parameterID: .hapticIntensityControl, value: intensity, relativeTime: 0)],
                                          atTime: CHHapticTimeImmediate)
                try player.start(atTime: CHHapticTimeImmediate)
                continuous = player
                lastSentIntensity = intensity
            } catch {
                continuous = nil
            }
            return
        }
        // only send meaningful changes; flooding the engine every frame adds nothing
        if abs(intensity - lastSentIntensity) > 0.015 {
            try? continuous?.sendParameters([CHHapticDynamicParameter(parameterID: .hapticIntensityControl, value: intensity, relativeTime: 0)],
                                            atTime: CHHapticTimeImmediate)
            lastSentIntensity = intensity
        }
    }

    func stopContinuous() {
        guard let player = continuous else { return }
        try? player.stop(atTime: CHHapticTimeImmediate)
        continuous = nil
        lastSentIntensity = -1
    }

    /// One-shot tap. `intensity` 0...1.
    func transient(intensity: Double, sharpness: Double) {
        guard enabled, supported else { return }
        startEngine()
        guard let engine, engineRunning else { return }
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(max(0, min(1, intensity)))),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: Float(max(0, min(1, sharpness)))),
        ], relativeTime: 0)
        do {
            let player = try engine.makePlayer(with: CHHapticPattern(events: [event], parameters: []))
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {}
    }

    /// Release "pop": 0.3...0.7 depending on how hard it was let go (參數表).
    func pop(strength: Double) {
        transient(intensity: 0.3 + 0.4 * max(0, min(1, strength)), sharpness: 0.45)
    }
}
