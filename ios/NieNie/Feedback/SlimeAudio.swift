import AVFoundation
import os
import UIKit

enum SoundStyle: String, CaseIterable, Identifiable {
    case wet, soft, quiet
    var id: String { rawValue }
    var name: String {
        switch self {
        case .wet: return "濕黏"
        case .soft: return "柔軟"
        case .quiet: return "安靜"
        }
    }
}

/// Where slime sounds come from. The synth is the prototype's sound; a recorded-sample
/// bank can implement the same calls later and be swapped in.
protocol SlimeSoundSource: AnyObject {
    var style: SoundStyle { get set }
    var muted: Bool { get set }
    var pitch: Double { get set }
    func press(_ i: Double)
    func stretch(_ i: Double)
    func release(_ i: Double)
    func tap()
    /// Called every frame with how fast fingers knead across the slime (0...1).
    func bed(speed: Double, dt: Double)
}

/// Port of the prototype's WebAudio synth: filtered-noise bursts, short sine sweeps,
/// tiny wet "clicks", and a continuous pink-noise bed that follows kneading speed.
/// Uses the `.ambient` session, so the ring/silent switch mutes it.
final class SlimeAudio: SlimeSoundSource {
    var style: SoundStyle = .wet
    var muted = false { didSet { core.masterTarget = muted ? 0 : 0.9 } }
    var pitch = 1.0

    private let engine = AVAudioEngine()
    private var source: AVAudioSourceNode?
    private let core: SynthCore
    private var bedLvl = 0.0

    init() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
        let sr = session.sampleRate > 0 ? session.sampleRate : 48_000
        core = SynthCore(sampleRate: sr)

        let format = AVAudioFormat(standardFormatWithSampleRate: sr, channels: 1)!
        let core = self.core
        let node = AVAudioSourceNode(format: format) { _, _, frameCount, audioBufferList -> OSStatus in
            let abl = UnsafeMutableAudioBufferListPointer(audioBufferList)
            guard let data = abl[0].mData?.assumingMemoryBound(to: Float.self) else { return noErr }
            core.render(into: data, count: Int(frameCount))
            for b in 1..<abl.count {
                if let other = abl[b].mData?.assumingMemoryBound(to: Float.self) {
                    other.update(from: data, count: Int(frameCount))
                }
            }
            return noErr
        }
        source = node
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
        engine.prepare()
        startEngine()

        let nc = NotificationCenter.default
        nc.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] note in
            guard let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  AVAudioSession.InterruptionType(rawValue: raw) == .ended else { return }
            self?.startEngine()
        }
        nc.addObserver(forName: .AVAudioEngineConfigurationChange, object: engine, queue: .main) { [weak self] _ in
            self?.startEngine()
        }
        nc.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            self?.startEngine()
        }
    }

    private func startEngine() {
        guard !engine.isRunning else { return }
        try? AVAudioSession.sharedInstance().setActive(true)
        try? engine.start()
    }

    // MARK: - Building blocks (same shapes as the prototype's nz / tn / clicks)

    private var ok: Bool { !muted }
    private func rnd(_ a: Double, _ b: Double) -> Double { Double.random(in: a...b) }
    private func P() -> Double { pitch * rnd(0.92, 1.08) }

    private func nz(_ t: Double, pink: Bool, lowpass: Bool, _ f0: Double, _ f1: Double, q: Double,
                    peak: Double, a: Double, d: Double) {
        core.enqueue(SynthCore.Voice(isTone: false, pink: pink, lowpass: lowpass, delay: t, attack: a, decay: d,
                                     peak: peak, f0: f0, f1: f1, q: q, sampleRate: core.sampleRate))
    }

    private func tn(_ t: Double, _ f0: Double, _ f1: Double, peak: Double, a: Double, d: Double) {
        core.enqueue(SynthCore.Voice(isTone: true, pink: false, lowpass: false, delay: t, attack: a, decay: d,
                                     peak: peak, f0: f0, f1: f1, q: 1, sampleRate: core.sampleRate))
    }

    /// wet clicks: tiny sticky crackles, the core of slime ASMR
    private func clicks(_ t: Double, _ n: Int, _ spread: Double, _ vol: Double) {
        for _ in 0..<max(0, n) {
            nz(t + Double.random(in: 0..<1) * spread, pink: false, lowpass: false, rnd(1800, 5200), 0, q: rnd(2, 5),
               peak: vol * rnd(0.4, 1), a: 0.001, d: rnd(0.004, 0.014))
        }
    }

    // MARK: - Sounds

    func press(_ i: Double) {
        guard ok else { return }
        let p = P()
        switch style {
        case .wet:
            nz(0, pink: true, lowpass: false, 900 * p, 280 * p, q: 2.2, peak: 0.32 * i + 0.08, a: 0.006, d: 0.16)
            nz(0, pink: true, lowpass: true, 500, 0, q: 0.7, peak: 0.2 * i + 0.05, a: 0.004, d: 0.1)
            clicks(0.01, 3 + Int((i * 5).rounded()), 0.09, 0.12)
        case .soft:
            nz(0, pink: true, lowpass: true, 420 * p, 180, q: 0.6, peak: 0.35 * i + 0.1, a: 0.02, d: 0.18)
            tn(0, 120 * p, 70, peak: 0.18 * i + 0.05, a: 0.01, d: 0.16)
        case .quiet:
            nz(0, pink: true, lowpass: true, 300 * p, 150, q: 0.6, peak: 0.12 * i + 0.04, a: 0.03, d: 0.2)
        }
    }

    func stretch(_ i: Double) {
        guard ok else { return }
        switch style {
        case .wet: clicks(0, 2 + Int((i * 3).rounded()), 0.05, 0.09)
        case .soft: tn(0, 300 * pitch * (1 + i * 0.4), 340 * pitch * (1 + i * 0.45), peak: 0.035, a: 0.02, d: 0.08)
        case .quiet: break
        }
    }

    func release(_ i: Double) {
        guard ok else { return }
        let p = P()
        switch style {
        case .wet:
            tn(0, 230 * p, 70, peak: 0.22 * i + 0.06, a: 0.003, d: 0.07)
            nz(0, pink: true, lowpass: true, 1400, 300, q: 0.8, peak: 0.16 * i + 0.04, a: 0.002, d: 0.07)
            clicks(0.02, 2 + Int((i * 3).rounded()), 0.06, 0.1)
        case .soft:
            tn(0, 520 * p, 260 * p, peak: 0.14 * i + 0.05, a: 0.004, d: 0.09)
            tn(0.05, 780 * p, 420 * p, peak: 0.05 * i + 0.02, a: 0.004, d: 0.07)
        case .quiet:
            tn(0, 320 * p, 200 * p, peak: 0.06 * i + 0.02, a: 0.01, d: 0.08)
        }
    }

    func tap() {
        guard ok else { return }
        let p = P()
        switch style {
        case .wet:
            nz(0, pink: true, lowpass: false, 700 * p, 300, q: 2, peak: 0.18, a: 0.003, d: 0.08)
            clicks(0, 2, 0.03, 0.1)
        case .soft: tn(0, 600 * p, 320 * p, peak: 0.12, a: 0.003, d: 0.07)
        case .quiet: tn(0, 400 * p, 260 * p, peak: 0.05, a: 0.005, d: 0.06)
        }
    }

    func bed(speed: Double, dt: Double) {
        bedLvl += (speed - bedLvl) * min(1, dt * 12)
        let v = muted ? 0 : bedLvl
        switch style {
        case .wet:
            core.setBed(gain: v * 0.16, gainTau: 0.03, freq: 400 + v * 900, freqTau: 0.04)
            if Double.random(in: 0..<1) < v * 28 * dt { clicks(0, 1 + Int((v * 2).rounded()), 0.02, 0.08) }
        case .soft:
            core.setBed(gain: v * 0.1, gainTau: 0.05, freq: 250 + v * 350, freqTau: 0.05)
        case .quiet:
            core.setBed(gain: v * 0.04, gainTau: 0.06, freq: 200 + v * 200, freqTau: 0.06)
        }
    }
}

// MARK: - Real-time synth

/// Everything the audio thread touches. Voices are queued from the main thread under a lock;
/// the render callback only ever *tries* the lock, so it never blocks.
final class SynthCore {
    struct Voice {
        var isTone: Bool
        var pink: Bool
        var lowpass: Bool
        var delay: Int
        var attack: Int
        var decay: Int
        var peak: Float
        var f0: Float
        var f1: Float          // 0 = no sweep (noise only)
        var q: Float
        var noiseStart: Int
        // running state
        var pos = 0
        var gain: Float = 0.0001
        var attackMul: Float = 1
        var decayMul: Float = 1
        var freq: Float = 0
        var freqMul: Float = 1
        var phase: Float = 0
        var b0: Float = 0, b1: Float = 0, b2: Float = 0, a1: Float = 0, a2: Float = 0
        var x1: Float = 0, x2: Float = 0, y1: Float = 0, y2: Float = 0

        init(isTone: Bool, pink: Bool, lowpass: Bool, delay: Double, attack: Double, decay: Double,
             peak: Double, f0: Double, f1: Double, q: Double, sampleRate: Double) {
            self.isTone = isTone
            self.pink = pink
            self.lowpass = lowpass
            self.delay = Int(delay * sampleRate)
            self.attack = max(1, Int(attack * sampleRate))
            self.decay = max(1, Int(decay * sampleRate))
            self.peak = Float(max(0.0002, peak))
            self.f0 = Float(f0)
            self.f1 = Float(f1)
            self.q = Float(q)
            self.noiseStart = Int(Double.random(in: 0..<1.5) * sampleRate)
        }
    }

    let sampleRate: Double
    private let noise: [Float]
    private let pinkNoise: [Float]

    private let capacity = 96
    private let voices: UnsafeMutablePointer<Voice>
    private var active: [Bool]
    private let pendingCapacity = 64
    private let pending: UnsafeMutablePointer<Voice>
    private var pendingCount = 0
    private let lock: UnsafeMutablePointer<os_unfair_lock>

    // values written by the main thread, read by the audio thread
    var masterTarget: Float = 0.9
    private var bedGainTarget: Float = 0, bedGainTau: Float = 0.03
    private var bedFreqTarget: Float = 600, bedFreqTau: Float = 0.04

    // audio-thread state
    private var master: Float = 0.9
    private var bedGain: Float = 0
    private var bedFreq: Float = 600
    private var bedPos = 0
    private var bed = (b0: Float(0), b1: Float(0), b2: Float(0), a1: Float(0), a2: Float(0))
    private var bedZ = (x1: Float(0), x2: Float(0), y1: Float(0), y2: Float(0))
    private var bedCounter = 0

    init(sampleRate: Double) {
        self.sampleRate = sampleRate
        let n = Int(sampleRate * 2)
        var white = [Float](repeating: 0, count: n), pinkBuf = [Float](repeating: 0, count: n)
        var b0: Float = 0, b1: Float = 0, b2: Float = 0
        for i in 0..<n {
            let w = Float.random(in: -1...1)
            white[i] = w
            b0 = 0.997 * b0 + w * 0.03; b1 = 0.985 * b1 + w * 0.06; b2 = 0.95 * b2 + w * 0.12
            pinkBuf[i] = (b0 + b1 + b2) * 0.6
        }
        noise = white
        pinkNoise = pinkBuf
        voices = .allocate(capacity: capacity)
        pending = .allocate(capacity: pendingCapacity)
        active = [Bool](repeating: false, count: capacity)
        lock = .allocate(capacity: 1)
        lock.initialize(to: os_unfair_lock())
        bed = SynthCore.coefficients(lowpass: true, freq: 600, q: 0.7, sampleRate: Float(sampleRate))
    }

    deinit {
        voices.deallocate()
        pending.deallocate()
        lock.deallocate()
    }

    func enqueue(_ v: Voice) {
        os_unfair_lock_lock(lock)
        if pendingCount < pendingCapacity {
            (pending + pendingCount).initialize(to: v)
            pendingCount += 1
        }
        os_unfair_lock_unlock(lock)
    }

    func setBed(gain: Double, gainTau: Double, freq: Double, freqTau: Double) {
        bedGainTarget = Float(gain); bedGainTau = Float(gainTau)
        bedFreqTarget = Float(freq); bedFreqTau = Float(freqTau)
    }

    /// RBJ biquad. Bandpass is the constant 0 dB peak kind, like WebAudio's.
    static func coefficients(lowpass: Bool, freq: Float, q: Float, sampleRate: Float)
        -> (b0: Float, b1: Float, b2: Float, a1: Float, a2: Float) {
        let f = min(max(freq, 20), sampleRate * 0.45)
        let w0 = 2 * Float.pi * f / sampleRate
        let cosw = cos(w0), alpha = sin(w0) / (2 * max(q, 0.05))
        let a0 = 1 + alpha
        if lowpass {
            return ((1 - cosw) / 2 / a0, (1 - cosw) / a0, (1 - cosw) / 2 / a0, -2 * cosw / a0, (1 - alpha) / a0)
        } else {
            return (alpha / a0, 0, -alpha / a0, -2 * cosw / a0, (1 - alpha) / a0)
        }
    }

    private func pullPending() {
        guard os_unfair_lock_trylock(lock) else { return }
        var slot = 0
        for i in 0..<pendingCount {
            while slot < capacity && active[slot] { slot += 1 }
            if slot >= capacity { break }
            (voices + slot).initialize(to: pending[i])
            active[slot] = true
        }
        pendingCount = 0
        os_unfair_lock_unlock(lock)
    }

    private func start(_ v: inout Voice) {
        let sr = Float(sampleRate)
        v.gain = 0.0001
        v.attackMul = pow(v.peak / 0.0001, 1 / Float(v.attack))
        v.decayMul = pow(0.0001 / v.peak, 1 / Float(v.decay))
        v.freq = v.f0
        v.freqMul = v.f1 > 0 && v.f0 > 0 ? pow(v.f1 / v.f0, 1 / Float(v.attack + v.decay)) : 1
        if !v.isTone {
            let c = SynthCore.coefficients(lowpass: v.lowpass, freq: v.freq, q: v.q, sampleRate: sr)
            v.b0 = c.b0; v.b1 = c.b1; v.b2 = c.b2; v.a1 = c.a1; v.a2 = c.a2
        }
    }

    func render(into out: UnsafeMutablePointer<Float>, count: Int) {
        pullPending()
        let sr = Float(sampleRate)
        out.update(repeating: 0, count: count)

        // the kneading bed
        let gk = 1 - exp(-1 / (max(bedGainTau, 0.001) * sr))
        let fk = 1 - exp(-1 / (max(bedFreqTau, 0.001) * sr))
        let pn = pinkNoise.count
        pinkNoise.withUnsafeBufferPointer { pinkBuf in
            for i in 0..<count {
                bedGain += (bedGainTarget - bedGain) * gk
                bedFreq += (bedFreqTarget - bedFreq) * fk
                if bedCounter % 64 == 0 {
                    bed = SynthCore.coefficients(lowpass: true, freq: bedFreq, q: 0.7, sampleRate: sr)
                }
                bedCounter &+= 1
                let x = pinkBuf[bedPos]
                bedPos = (bedPos + 1) % pn
                let y = bed.b0 * x + bed.b1 * bedZ.x1 + bed.b2 * bedZ.x2 - bed.a1 * bedZ.y1 - bed.a2 * bedZ.y2
                bedZ = (x, bedZ.x1, y, bedZ.y1)
                out[i] += y * bedGain
            }
        }

        // one-shot voices
        noise.withUnsafeBufferPointer { whiteBuf in
            pinkNoise.withUnsafeBufferPointer { pinkBuf in
                for s in 0..<capacity where active[s] {
                    var v = voices[s]
                    let total = v.attack + v.decay
                    let buf = v.pink ? pinkBuf : whiteBuf
                    var i = 0
                    while i < count {
                        if v.delay > 0 { v.delay -= 1; i += 1; continue }
                        if v.pos == 0 { start(&v) }
                        var x: Float
                        if v.isTone {
                            x = sin(v.phase)
                            v.phase += 2 * .pi * v.freq / sr
                            if v.phase > 2 * .pi { v.phase -= 2 * .pi }
                        } else {
                            let n = buf[(v.noiseStart + v.pos) % buf.count]
                            x = v.b0 * n + v.b1 * v.x1 + v.b2 * v.x2 - v.a1 * v.y1 - v.a2 * v.y2
                            v.x2 = v.x1; v.x1 = n; v.y2 = v.y1; v.y1 = x
                            if v.freqMul != 1 && v.pos % 32 == 0 {
                                let c = SynthCore.coefficients(lowpass: v.lowpass, freq: v.freq, q: v.q, sampleRate: sr)
                                v.b0 = c.b0; v.b1 = c.b1; v.b2 = c.b2; v.a1 = c.a1; v.a2 = c.a2
                            }
                        }
                        out[i] += x * v.gain
                        v.gain *= v.pos < v.attack ? v.attackMul : v.decayMul
                        v.freq *= v.freqMul
                        v.pos += 1
                        i += 1
                        if v.pos >= total { active[s] = false; break }
                    }
                    voices[s] = v
                }
            }
        }

        // master gain + a gentle soft clip in place of the prototype's compressor
        let mk: Float = 1 - exp(-1 / (0.01 * sr))
        for i in 0..<count {
            master += (masterTarget - master) * mk
            out[i] = tanh(out[i] * master)
        }
    }
}
