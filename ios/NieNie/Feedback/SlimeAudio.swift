import AVFoundation
import UIKit

/// Where slime sounds come from. Four kinds, same as the web prototype's sfx/manifest.json:
/// press (finger lands), pull (stretched past a step), release (let go), rub (looped while kneading).
protocol SlimeSoundSource: AnyObject {
    var muted: Bool { get set }
    func press(gain: Double)
    func pull(gain: Double, rate: Double)
    func release(gain: Double, rate: Double)
    /// Called every frame with the kneading level 0...1; 0 fades the loop out.
    func rub(level: Double)
}

/// Recorded-sample bank. Reads `manifest.json` from the app bundle (same format as the web
/// prototype: {"press":[...], "pull":[...], "release":[...], "rub":[...]}) and the listed audio
/// files next to it. Each play picks a random take and shifts pitch by ±8%. With no files it
/// stays silent. Uses the `.ambient` session, so the ring/silent switch mutes it.
final class SlimeAudio: SlimeSoundSource {
    var muted = false {
        didSet { engine.mainMixerNode.outputVolume = muted ? 0 : 0.9 }
    }

    private let engine = AVAudioEngine()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 48_000, channels: 1)!
    private var bank: [String: [AVAudioPCMBuffer]] = [:]

    private struct Voice {
        let player = AVAudioPlayerNode()
        let speed = AVAudioUnitVarispeed()
    }
    private var voices: [Voice] = []
    private var nextVoice = 0
    private let rubVoice = Voice()
    private var rubPlaying = false
    private var rubTarget = 0.0

    let pitchJitter = 0.08

    init() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)

        for _ in 0..<6 {
            let v = Voice()
            attach(v)
            voices.append(v)
        }
        attach(rubVoice)
        engine.mainMixerNode.outputVolume = 0.9
        engine.prepare()
        loadBank()
        startEngine()

        let nc = NotificationCenter.default
        nc.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] note in
            guard let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  AVAudioSession.InterruptionType(rawValue: raw) == .ended else { return }
            self?.startEngine()
        }
        nc.addObserver(forName: .AVAudioEngineConfigurationChange, object: engine, queue: .main) { [weak self] _ in
            self?.rubPlaying = false
            self?.startEngine()
        }
        nc.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            self?.startEngine()
        }
    }

    private func attach(_ v: Voice) {
        engine.attach(v.player)
        engine.attach(v.speed)
        engine.connect(v.player, to: v.speed, format: format)
        engine.connect(v.speed, to: engine.mainMixerNode, format: format)
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
              let manifest = try? JSONSerialization.jsonObject(with: data) as? [String: [String]] else { return }
        for (kind, files) in manifest {
            var buffers: [AVAudioPCMBuffer] = []
            for name in files {
                let base = (name as NSString).deletingPathExtension, ext = (name as NSString).pathExtension
                guard let fileURL = Bundle.main.url(forResource: base, withExtension: ext.isEmpty ? nil : ext),
                      let buffer = load(fileURL) else { continue }
                buffers.append(buffer)
            }
            bank[kind] = buffers
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

    // MARK: - Playing

    private func play(_ kind: String, gain: Double, rate: Double) {
        guard !muted, let takes = bank[kind], !takes.isEmpty else { return }
        startEngine()
        guard engine.isRunning else { return }
        let v = voices[nextVoice]
        nextVoice = (nextVoice + 1) % voices.count
        v.player.stop()
        v.speed.rate = Float(rate * (1 + Double.random(in: -pitchJitter...pitchJitter)))
        v.player.volume = Float(max(0, min(1, gain)))
        v.player.scheduleBuffer(takes[Int.random(in: 0..<takes.count)], at: nil, options: [], completionHandler: nil)
        v.player.play()
    }

    func press(gain: Double) { play("press", gain: gain, rate: 1) }
    func pull(gain: Double, rate: Double) { play("pull", gain: gain, rate: rate) }
    func release(gain: Double, rate: Double) { play("release", gain: gain, rate: rate) }

    func rub(level: Double) {
        let target = muted ? 0 : max(0, min(1, level))
        if target > 0 && !rubPlaying {
            guard let takes = bank["rub"], !takes.isEmpty else { return }
            startEngine()
            guard engine.isRunning else { return }
            rubVoice.player.stop()
            rubVoice.speed.rate = Float(1 + Double.random(in: -pitchJitter...pitchJitter))
            rubVoice.player.volume = 0
            rubVoice.player.scheduleBuffer(takes[Int.random(in: 0..<takes.count)], at: nil, options: [.loops], completionHandler: nil)
            rubVoice.player.play()
            rubPlaying = true
            rubTarget = 0
        }
        guard rubPlaying else { return }
        // smooth the volume towards the target (~60 ms); stop once faded out
        rubTarget += (target - rubTarget) * 0.25
        rubVoice.player.volume = Float(rubTarget)
        if target == 0 && rubTarget < 0.01 {
            rubVoice.player.stop()
            rubPlaying = false
            rubTarget = 0
        }
    }
}
