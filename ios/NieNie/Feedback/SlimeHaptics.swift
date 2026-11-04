import CoreHaptics
import UIKit

/// Two kinds of haptics (2-4 #5):
/// - continuous: one long event whose intensity and sharpness the controller drives every frame
///   (from deformation and, with candidate 12, its rate of change)
/// - transient: the release "pop" (one or more taps in one pattern) and, with candidate 13,
///   texture ticks while kneading
final class SlimeHaptics {
    var enabled = true { didSet { if !enabled { stopContinuous() } } }

    private let supported = CHHapticEngine.capabilitiesForHardware().supportsHaptics
    private var engine: CHHapticEngine?
    private var engineRunning = false
    private var continuous: CHHapticAdvancedPatternPlayer?
    private var lastSentIntensity: Float = -1
    private var lastSentSharpness: Float = -1
    private var baseSharpness: Float = 0.25
    private var continuousStartedAt: CFTimeInterval = 0
    private var pendingTicks: [(intensity: Float, sharpness: Float)] = []
    // 候選 17: the release sample registered with the engine, played in the same pattern as the taps
    private var popAudioID: CHHapticAudioResourceID?
    private var popAudioURL: URL?
    private(set) var popAudioReady = false

    /// Hysteresis (手感精修提案 第 16 條): the continuous player starts above `onThreshold`, and stops
    /// only below `offThreshold` after at least `minOn`, so the engine does not click on and off
    /// while the level hovers around the threshold.
    let onThreshold: Float = 0.03
    let offThreshold: Float = 0.008
    let minOn: CFTimeInterval = 0.12

    init() {
        guard supported else { return }
        do {
            let e = try CHHapticEngine()
            // 候選 17: audio events are allowed once 啵走觸覺管線 has been switched on. Apple: the flag only changes after
            // an engine restart (docs checked 2026-11), so it is read at launch; haptics-only also starts playback faster
            e.playsHapticsOnly = !UserDefaults.standard.bool(forKey: "audioThroughHaptics")
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

    private func clamp01(_ v: Double) -> Float { Float(max(0, min(1, v))) }

    /// Called every frame. `level` is the final 0...1 intensity (the controller shapes it from the
    /// deformation and its rate, 提案第 12 條); `sharpness` 0...1.
    func updateContinuous(level: Double, sharpness: Double) {
        guard enabled, supported else { return }
        let intensity = clamp01(level), sharp = clamp01(sharpness)
        if continuous == nil {
            guard intensity >= onThreshold else { return }
            startEngine()
            guard let engine, engineRunning else { return }
            do {
                let event = CHHapticEvent(eventType: .hapticContinuous, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: sharp),
                ], relativeTime: 0, duration: 60)
                let player = try engine.makeAdvancedPlayer(with: CHHapticPattern(events: [event], parameters: []))
                player.loopEnabled = true
                try player.sendParameters([CHHapticDynamicParameter(parameterID: .hapticIntensityControl, value: intensity, relativeTime: 0)],
                                          atTime: CHHapticTimeImmediate)
                try player.start(atTime: CHHapticTimeImmediate)
                continuous = player
                lastSentIntensity = intensity
                lastSentSharpness = sharp
                baseSharpness = sharp
                continuousStartedAt = CACurrentMediaTime()
            } catch {
                continuous = nil
            }
            return
        }
        if intensity < offThreshold && CACurrentMediaTime() - continuousStartedAt >= minOn {
            stopContinuous()
            return
        }
        // only send meaningful changes; flooding the engine every frame adds nothing
        var params: [CHHapticDynamicParameter] = []
        if abs(intensity - lastSentIntensity) > 0.015 {
            params.append(CHHapticDynamicParameter(parameterID: .hapticIntensityControl, value: intensity, relativeTime: 0))
            lastSentIntensity = intensity
        }
        if abs(sharp - lastSentSharpness) > 0.02 {
            // the sharpness control is an offset added to the event's own sharpness (−1...1)
            params.append(CHHapticDynamicParameter(parameterID: .hapticSharpnessControl, value: sharp - baseSharpness, relativeTime: 0))
            lastSentSharpness = sharp
        }
        if !params.isEmpty {
            try? continuous?.sendParameters(params, atTime: CHHapticTimeImmediate)
        }
    }

    /// 候選 17. Registers the release sample so `pop` can play it as an audio event (sample-level sync with the taps).
    /// The engine is created haptics-only unless this was switched on before, so the first time needs an app restart.
    func setAudioThroughHaptics(_ on: Bool, url: URL?) {
        if on { UserDefaults.standard.set(true, forKey: "audioThroughHaptics") }
        guard on, let url, let engine, supported else { popAudioID = nil; popAudioReady = false; return }
        if popAudioURL == url, popAudioID != nil { return }
        startEngine()
        guard engineRunning, !engine.playsHapticsOnly else { popAudioReady = false; return }
        popAudioURL = url
        popAudioID = try? engine.registerAudioResource(url, options: [:])
        popAudioReady = popAudioID != nil
    }

    func stopContinuous() {
        guard let player = continuous else { return }
        try? player.stop(atTime: CHHapticTimeImmediate)
        continuous = nil
        lastSentIntensity = -1
        lastSentSharpness = -1
    }

    private func play(_ events: [CHHapticEvent]) {
        guard !events.isEmpty, enabled, supported else { return }
        startEngine()
        guard let engine, engineRunning else { return }
        do {
            let player = try engine.makePlayer(with: CHHapticPattern(events: events, parameters: []))
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {}
    }

    private func tap(intensity: Double, sharpness: Double, at time: Double) -> CHHapticEvent {
        CHHapticEvent(eventType: .hapticTransient, parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: clamp01(intensity)),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: clamp01(sharpness)),
        ], relativeTime: time)
    }

    /// v2.25 F5 haptic ladder: one tap (sharpness 0.25, like a grain) or half a second continuous (sharpness 0.05, like the purr).
    func test(intensity: Double, continuous isContinuous: Bool) {
        if isContinuous {
            play([CHHapticEvent(eventType: .hapticContinuous, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: clamp01(intensity)),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.05),
            ], relativeTime: 0, duration: 0.5)])
        } else {
            play([tap(intensity: intensity, sharpness: 0.25, at: 0)])
        }
    }

    /// One-shot tap. `intensity` 0...1.
    func transient(intensity: Double, sharpness: Double) {
        play([tap(intensity: intensity, sharpness: sharpness, at: 0)])
    }

    /// Release pop: `count` taps in one pattern, `gap` seconds apart, each `decay` of the previous
    /// (提案第 14 條: clay one, mochi two, jelly three). Intensity runs minIntensity...maxIntensity with `strength`.
    func pop(strength: Double, count: Int, gap: Double, decay: Double, sharpness: Double, minIntensity: Double, maxIntensity: Double,
             audioVolume: Double? = nil) {
        var amp = minIntensity + (maxIntensity - minIntensity) * max(0, min(1, strength))
        var events: [CHHapticEvent] = []
        // 候選 17: the recorded pop as an audio event at time 0 of the same pattern (CHHapticEvent(audioResourceID:), docs checked 2026-11)
        if let vol = audioVolume, let id = popAudioID {
            events.append(CHHapticEvent(audioResourceID: id,
                                        parameters: [CHHapticEventParameter(parameterID: .audioVolume, value: clamp01(vol))],
                                        relativeTime: 0))
        }
        for k in 0..<max(1, min(6, count)) {
            events.append(tap(intensity: amp, sharpness: sharpness, at: Double(k) * max(0.03, gap)))
            amp *= decay
        }
        play(events)
    }

    /// Texture tick (提案第 13 條): queued; `flush()` plays everything queued this frame as one pattern.
    func tick(intensity: Double, sharpness: Double) {
        pendingTicks.append((clamp01(intensity), clamp01(sharpness)))
    }

    func flush() {
        guard !pendingTicks.isEmpty else { return }
        let ticks = pendingTicks
        pendingTicks.removeAll()
        var events: [CHHapticEvent] = []
        for (k, t) in ticks.enumerated() {
            events.append(tap(intensity: Double(t.intensity), sharpness: Double(t.sharpness), at: Double(k) * 0.004))
        }
        play(events)
    }
}
