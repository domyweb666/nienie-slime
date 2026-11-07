import AVFoundation
import UIKit

/// Where slime sounds come from. v2 (2026-11-01, layered): the physics decides how loud, how high and how bright
/// each layer plays. Same table as the web prototype's `prototype/web/sfx/engine.js` and
/// `.uiux/04-手感/音效參數對應-暫定.md`; change the numbers in all three together.
protocol SlimeSoundSource: AnyObject {
    var muted: Bool { get set }
    var master: Double { get set }
    var pitchJitter: Double { get set }
    var pullMax: Double { get set }      // loudest the stretching-strand loop gets
    var rubMax: Double { get set }       // loudest the rub loop gets (the rub level passed to frame is already scaled by it)
    var settleAmt: Double { get set }    // after-release bubbles / hiss, 0 = off
    var music: Double { get set }        // v2.21 background lofi volume, 0 = off
    /// Finger landed. `intensity` 0...1 (the controller folds in contact size).
    func press(intensity: Double)
    /// Stretched past another step: one strand snaps.
    func strand(gain: Double)
    /// Let go. `gain` is the release event's 0.35...1; strength s = (gain − 0.35) / 0.65.
    func release(gain: Double)
    /// Every frame. `rub` 0...1 (already × rubMax), `stretch` in radii of the most-stretched grabbing finger.
    func frame(dt: Double, rub: Double, stretch: Double, grabbing: Bool)
    /// App going to the background: loops off, nothing pending.
    func stopAll()
    /// v2.22 E1: one of its small sounds (`voice.<kind>` in the manifest); `rate` is the pitch from the impression.
    func voice(_ kind: String, gain: Double, rate: Double)
    /// v2.31 搖晃沉澱: the ding when it has settled clear (three sines, baked to a file)
    func ding(gain: Double)
    /// 候選 17: one release "pop" file, for Core Haptics to register (nil until there is one).
    var releaseSampleURL: URL? { get }
}

/// Sample bank + layered playback. Reads `manifest.json` from the bundle:
/// v2 `{"version":2, "press":{"body":[],"wet":[],"air":[]}, "release":{...}, "pull":{"loop":[],"strand":[]},
/// "rub":{"loop":[]}, "settle":{"bubble":[],"hiss":[]}}`; the old flat `{"press":[...]}` still loads (one layer "all").
/// Every buffer is decoded into memory at launch, so a touch never waits on disk. `.ambient` session: the silent switch mutes it.
final class SlimeAudio: SlimeSoundSource {
    var muted = false { didSet { applyVolume(); if muted { pending.removeAll() } } }
    var master = 0.9 { didSet { applyVolume() } }
    var pitchJitter = 0.08
    var pullMax = 0.6
    var rubMax = 0.7
    var settleAmt = 1.0
    private(set) var releaseSampleURL: URL?
    /// v2.21 background lofi (多米 build 77: put lofi behind it), `bgm-lofi.caf` (ALAC: AAC pads silence, and AVAudioPlayer loops the whole file, so an m4a has a gap) from `prototype/sfx-design/design_lofi.py`: a 126 s loop.
    /// Streamed by AVAudioPlayer (decoded whole it would be about 44 MB of stereo floats), outside the effects' engine, so "sounds only"
    /// and the effects' volume do not touch it. Ducks to 0.6 while a finger holds the body (0.4 s down, 1.2 s back), paused in the background.
    var music = 0.0 { didSet { bgmTarget = -1 } }
    private var bgm: AVAudioPlayer?
    private var bgmTarget = -1.0

    // ---- the table (keep in step with engine.js) ----
    private struct Play { var gain: Double; var rate: Double; var lowpass: Double; var delay = 0.0; var deco = false }
    private let maxVoices = 14              // one-shots at once; past this the decoration layers (air, settle, strand) are dropped
    private let retrigger = 0.06            // same kind again within 60 ms: wet layer only, × 0.6
    private static func rnd(_ a: Double, _ b: Double) -> Double { Double.random(in: a...b) }
    private static func clamp(_ x: Double, _ a: Double, _ b: Double) -> Double { max(a, min(b, x)) }

    private let pressLayers: [(String, (Double) -> Play?)] = [
        ("body", { i in i > 0.3 ? Play(gain: 0.9 * pow(i, 1.2), rate: 1.06 - 0.14 * i, lowpass: 2600) : nil }),
        ("wet", { i in Play(gain: 0.45 + 0.45 * i, rate: 1, lowpass: 1600 + 3400 * i) }),
        ("air", { i in Double.random(in: 0..<1) < 0.35 + 0.6 * i
            ? Play(gain: 0.25 + 0.45 * i, rate: SlimeAudio.rnd(0.9, 1.15), lowpass: 6000, delay: SlimeAudio.rnd(0.015, 0.045), deco: true) : nil }),
    ]
    private let releaseLayers: [(String, (Double) -> Play?)] = [
        ("air", { s in Play(gain: 0.55 + 0.45 * s, rate: 1.08 - 0.14 * s, lowpass: 7000) }),
        ("wet", { s in Play(gain: 0.25 + 0.6 * s, rate: 1, lowpass: 1800 + 4200 * s) }),
        ("body", { s in s > 0.2 ? Play(gain: 0.85 * pow(s, 1.3), rate: 1.05 - 0.1 * s, lowpass: 2400) : nil }),
    ]
    // pull: st = stretch (radii), v = its rate of change (radii/s, smoothed 60 ms)
    private let pullOn = 0.2
    private func pullGain(_ st: Double, _ v: Double) -> Double { 0.12 * Self.clamp((st - 0.2) / 0.4, 0, 1) + 0.88 * min(1, v / 2.5) }
    private func pullRate(_ st: Double) -> Double { 0.85 + 0.4 * tanh(st / 3) }
    private func pullLowpass(_ st: Double) -> Double { 1000 + 3500 * tanh(st / 3) }
    private func strandRate(_ st: Double, _ v: Double) -> Double { st > 0.4 ? (2 + 16 * tanh(st / 3)) * (0.25 + 0.75 * min(1, v / 2.5)) : 0 }
    private func strandPlay(_ st: Double) -> Play { Play(gain: Self.rnd(0.12, 0.3), rate: (0.85 + 0.5 * tanh(st / 3)) * Self.rnd(0.92, 1.08), lowpass: 9000, deco: true) }
    // rub: n = level / rubMax; ducks under the strand loop once pulled far
    private func rubDuck(_ st: Double) -> Double { Self.clamp(1 - (st - 0.3) / 0.7, 0, 1) }

    // ---- engine ----
    private let engine = AVAudioEngine()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 48_000, channels: 1)!
    private var bank: [String: [AVAudioPCMBuffer]] = [:]   // "press.body" → takes

    private final class Voice {
        let player = AVAudioPlayerNode()
        let speed = AVAudioUnitVarispeed()
        let eq = AVAudioUnitEQ(numberOfBands: 1)
        var busyUntil = 0.0
        var level = 0.0          // loops: smoothed volume
        var playing = false      // loops
        init() {
            let b = eq.bands[0]
            b.filterType = .lowPass
            b.frequency = 8000
            b.bandwidth = 0.7
            b.bypass = false
        }
    }
    private var voices: [Voice] = []
    private let pullVoice = Voice()
    private let rubVoice = Voice()

    private var lastKind: [String: Double] = [:]
    private var pending: [(at: Double, key: String, play: Play)] = []
    private var st = 0.0, stV = 0.0
    private var wasGrabbing = false
    private var lastStretch = 0.0, heldFor = 0.0

    init() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        // 提案第 10 條: a short IO buffer so the sound lands closer to the touch and the haptic
        // (the default is around 20 ms; the real value shows in the panel readout)
        try? session.setPreferredIOBufferDuration(0.005)
        try? session.setActive(true)

        for _ in 0..<(maxVoices + 4) {
            let v = Voice()
            attach(v)
            voices.append(v)
        }
        attach(pullVoice)
        attach(rubVoice)
        applyVolume()
        engine.prepare()
        loadBank()
        startEngine()
        if let url = Bundle.main.url(forResource: "bgm-lofi", withExtension: "caf"), let p = try? AVAudioPlayer(contentsOf: url) {
            p.numberOfLoops = -1; p.volume = 0; p.prepareToPlay(); bgm = p
        }

        let nc = NotificationCenter.default
        nc.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] note in
            guard let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  AVAudioSession.InterruptionType(rawValue: raw) == .ended else { return }
            self?.startEngine()
        }
        nc.addObserver(forName: .AVAudioEngineConfigurationChange, object: engine, queue: .main) { [weak self] _ in
            self?.pullVoice.playing = false
            self?.rubVoice.playing = false
            self?.startEngine()
        }
        nc.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            self?.startEngine()
            self?.bgmTarget = -1   // the next frame starts the music again (fading in)
        }
    }

    private func applyVolume() { engine.mainMixerNode.outputVolume = muted ? 0 : Float(master) }

    private func attach(_ v: Voice) {
        engine.attach(v.player)
        engine.attach(v.speed)
        engine.attach(v.eq)
        engine.connect(v.player, to: v.speed, format: format)
        engine.connect(v.speed, to: v.eq, format: format)
        engine.connect(v.eq, to: engine.mainMixerNode, format: format)
    }

    private func startEngine() {
        guard !engine.isRunning else { return }
        try? AVAudioSession.sharedInstance().setActive(true)
        try? engine.start()
    }

    // MARK: - Loading

    private func loadBank() {
        guard let url = Bundle.main.url(forResource: "manifest", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let manifest = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
        for (kind, value) in manifest {
            var layers: [String: [String]] = [:]
            if let flat = value as? [String] {
                layers[kind == "rub" ? "loop" : kind == "pull" ? "strand" : "all"] = flat   // old one-pack-per-kind format
            } else if let dict = value as? [String: [String]] {
                layers = dict
            } else { continue }
            for (layer, files) in layers {
                var buffers: [AVAudioPCMBuffer] = []
                for name in files {
                    let base = (name as NSString).deletingPathExtension, ext = (name as NSString).pathExtension
                    guard let fileURL = Bundle.main.url(forResource: base, withExtension: ext.isEmpty ? nil : ext),
                          let buffer = load(fileURL) else { continue }
                    buffers.append(buffer)
                    if kind == "release", layer == "air" || layer == "all", releaseSampleURL == nil { releaseSampleURL = fileURL }
                }
                bank["\(kind).\(layer)"] = buffers
            }
        }
    }

    /// Reads a file and converts it to the engine's mono 48k float format.
    private func load(_ url: URL) -> AVAudioPCMBuffer? {
        guard let file = try? AVAudioFile(forReading: url) else { return nil }
        let inFormat = file.processingFormat
        let frames = AVAudioFrameCount(file.length)
        guard frames > 0, let inBuf = AVAudioPCMBuffer(pcmFormat: inFormat, frameCapacity: frames) else { return nil }
        do { try file.read(into: inBuf) } catch { return nil }
        if inFormat.sampleRate == format.sampleRate && inFormat.channelCount == format.channelCount {
            return inBuf
        }
        guard let converter = AVAudioConverter(from: inFormat, to: format) else { return nil }
        let outFrames = AVAudioFrameCount(Double(frames) * format.sampleRate / inFormat.sampleRate) + 1024
        guard let outBuf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: outFrames) else { return nil }
        var consumed = false
        var error: NSError?
        _ = converter.convert(to: outBuf, error: &error) { _, status in
            if consumed {
                status.pointee = .endOfStream
                return nil
            }
            consumed = true
            status.pointee = .haveData
            return inBuf
        }
        return error == nil ? outBuf : nil
    }

    // MARK: - One-shots

    private var now: Double { CACurrentMediaTime() }
    private func jitter() -> Double { 1 + Double.random(in: -pitchJitter...pitchJitter) }

    private func one(_ key: String, _ p: Play) {
        guard !muted, let takes = bank[key], !takes.isEmpty else { return }
        if p.delay > 0 {
            var q = p
            q.delay = 0
            pending.append((at: now + p.delay, key: key, play: q))
            return
        }
        let t = now
        let busy = voices.filter { $0.busyUntil > t }.count
        if p.deco && busy >= maxVoices { return }
        // a free voice; if none, steal the one closest to finishing (only past maxVoices, so rare)
        guard let v = voices.first(where: { $0.busyUntil <= t }) ?? voices.min(by: { $0.busyUntil < $1.busyUntil }) else { return }
        startEngine()
        guard engine.isRunning else { return }
        let buf = takes[Int.random(in: 0..<takes.count)]
        let rate = p.rate * jitter()
        v.player.stop()
        v.speed.rate = Float(Self.clamp(rate, 0.25, 4))
        v.eq.bands[0].frequency = Float(min(20_000, p.lowpass))
        v.player.volume = Float(Self.clamp(p.gain, 0, 1))
        v.player.scheduleBuffer(buf, at: nil, options: [], completionHandler: nil)
        v.player.play()
        v.busyUntil = t + Double(buf.frameLength) / format.sampleRate / max(0.25, rate) + 0.02
    }

    /// One event: each layer picks its own take, its own pitch, and decides whether to sound.
    private func layered(_ kind: String, _ x: Double, _ layers: [(String, (Double) -> Play?)]) {
        guard !muted else { return }
        let t = now, again = t - (lastKind[kind] ?? -1) < retrigger
        lastKind[kind] = t
        if bank["\(kind).all"] != nil {   // old format
            one("\(kind).all", Play(gain: 0.4 + 0.6 * x, rate: 1, lowpass: 20_000))
            return
        }
        for (name, spec) in layers {
            if again && name != "wet" { continue }
            guard var p = spec(x) else { continue }
            if again { p.gain *= 0.6 }
            one("\(kind).\(name)", p)
        }
    }

    func press(intensity: Double) {
        pending.removeAll()   // touching again cuts the last release's tail
        layered("press", Self.clamp(intensity, 0, 1), pressLayers)
    }

    func voice(_ kind: String, gain: Double, rate: Double) {
        one("voice.\(kind)", Play(gain: Self.clamp(gain, 0, 1), rate: rate, lowpass: 4000))
    }

    func ding(gain: Double) {
        one("ding.all", Play(gain: Self.clamp(gain, 0, 1), rate: 1, lowpass: 16000))
    }

    func strand(gain: Double) {
        var p = strandPlay(st)
        p.gain = Self.clamp(p.gain * (0.6 + 0.8 * gain), 0, 1)
        p.deco = false
        one("pull.strand", p)
    }

    func release(gain: Double) {
        let s = Self.clamp((gain - 0.35) / 0.65, 0, 1)
        layered("release", s, releaseLayers)
        guard settleAmt > 0, !muted else { return }
        if lastStretch >= 0.4 {
            // pulled: 1–3 small bubbles between 0.12 and 0.7 s later
            for _ in 0..<Int((1 + 2 * s).rounded()) where Double.random(in: 0..<1) < 0.7 {
                let p = Play(gain: (Self.rnd(0.12, 0.22) + 0.15 * s) * settleAmt, rate: Self.rnd(0.85, 1.35), lowpass: 6000, deco: true)
                pending.append((at: now + Self.rnd(0.12, 0.7), key: "settle.bubble", play: p))
            }
        } else if heldFor >= 0.5 && Double.random(in: 0..<1) < 0.6 {
            // pressed a while without pulling: air refilling, a very small hiss
            one("settle.hiss", Play(gain: (0.35 + 0.35 * s) * settleAmt, rate: Self.rnd(0.9, 1.1), lowpass: 8000, delay: 0.03, deco: true))
        }
    }

    // MARK: - Every frame: loops and the pending queue

    func frame(dt rawDt: Double, rub: Double, stretch rawStretch: Double, grabbing: Bool) {
        let dt = Self.clamp(rawDt, 0.001, 0.1)
        let stretch = grabbing ? rawStretch : 0
        if let p = bgm {
            let target = music * (grabbing ? 0.6 : 1)
            if abs(target - bgmTarget) > 0.005 {
                if target > 0 && !p.isPlaying { p.play() }
                p.setVolume(Float(target), fadeDuration: target < bgmTarget ? 0.4 : 1.2)
                bgmTarget = target
            }
        }
        let vraw = abs(stretch - st) / dt
        st = stretch
        stV += (vraw - stV) * (1 - exp(-dt / 0.06))
        // this grab's longest pull and how long it was held: reset when a grab starts, kept after letting go
        // (the release event comes before the next frame, so release() reads the grab that just ended)
        if grabbing && !wasGrabbing { lastStretch = 0; heldFor = 0 }
        if grabbing { lastStretch = max(lastStretch, stretch); heldFor += dt }
        wasGrabbing = grabbing

        if !pending.isEmpty {
            let t = now
            let due = pending.filter { $0.at <= t }
            pending.removeAll { $0.at <= t }
            for e in due { one(e.key, e.play) }
        }

        // stretching-strand loop: thinner = higher and brighter, faster = louder, held still = almost silent
        let pulling = grabbing && stretch > pullOn && !muted
        let pullTarget = pulling ? pullMax * Self.clamp(pullGain(stretch, stV), 0, 1) : 0
        driveLoop(pullVoice, key: "pull.loop", target: pullTarget, dt: dt, attack: 0.05, decay: 0.12,
                  rate: pulling ? pullRate(stretch) : nil, lowpass: pulling ? pullLowpass(stretch) : nil)
        if pulling, Double.random(in: 0..<1) < strandRate(stretch, stV) * dt { one("pull.strand", strandPlay(stretch)) }

        // rub loop, giving way to the strand loop once pulled far
        let level = muted ? 0 : Self.clamp(rub, 0, 1) * rubDuck(stretch)
        let n = rubMax > 0 ? Self.clamp(level / rubMax, 0, 1) : 0
        driveLoop(rubVoice, key: "rub.loop", target: level, dt: dt, attack: 0.06, decay: 0.06,
                  rate: 0.94 + 0.12 * n, lowpass: 1400 + 2600 * n)
    }

    private func driveLoop(_ v: Voice, key: String, target: Double, dt: Double, attack: Double, decay: Double, rate: Double?, lowpass: Double?) {
        if target > 0.005 && !v.playing {
            guard let takes = bank[key], !takes.isEmpty else { return }
            startEngine()
            guard engine.isRunning else { return }
            v.player.stop()
            v.player.volume = 0
            v.level = 0
            v.player.scheduleBuffer(takes[Int.random(in: 0..<takes.count)], at: nil, options: [.loops], completionHandler: nil)
            v.player.play()
            v.playing = true
        }
        guard v.playing else { return }
        v.level += (target - v.level) * (1 - exp(-dt / (target > v.level ? attack : decay)))
        v.player.volume = Float(v.level)
        if let rate { v.speed.rate += (Float(rate) - v.speed.rate) * Float(1 - exp(-dt / 0.03)) }
        if let lowpass { v.eq.bands[0].frequency += (Float(lowpass) - v.eq.bands[0].frequency) * Float(1 - exp(-dt / 0.03)) }
        if target <= 0.005 && v.level < 0.004 {
            v.player.stop()
            v.playing = false
            v.level = 0
        }
    }

    func stopAll() {
        pending.removeAll()
        bgm?.pause(); bgmTarget = -1
        for v in [pullVoice, rubVoice] where v.playing {
            v.player.stop()
            v.playing = false
            v.level = 0
        }
        st = 0
        stV = 0
        wasGrabbing = false
    }
}
