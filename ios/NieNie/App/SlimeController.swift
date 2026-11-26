import AVFoundation
import CoreHaptics
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
    /// The panel's two chips, kept in UserDefaults. showAll (v2.57): all ten in the bottom row (一隻為主 off for every material).
    /// glossyClear (v2.60, 多米 11-24: back to the opaque body): all ten glossy and see-through as in v2.53b to v2.59. Its own key: the one v2.57 kept meant the opposite, for six of them
    @Published var showAll = UserDefaults.standard.bool(forKey: "nienie.showAll") { didSet { UserDefaults.standard.set(showAll, forKey: "nienie.showAll"); pushParams() } }
    @Published var glossyClear = UserDefaults.standard.bool(forKey: "nienie.clear") { didSet { UserDefaults.standard.set(glossyClear, forKey: "nienie.clear"); pushParams() } }
    /// v2.61b (多米 11-26): two looks to compare, kept like the chip above. coreSoft: 湯圓's sesame core smaller and lighter. edgeClean: the opaque body's edge without the grey see-through rim
    @Published var coreSoft = UserDefaults.standard.bool(forKey: "nienie.coreSoft") { didSet { UserDefaults.standard.set(coreSoft, forKey: "nienie.coreSoft"); pushParams() } }
    @Published var edgeClean = UserDefaults.standard.bool(forKey: "nienie.edgeClean") { didSet { UserDefaults.standard.set(edgeClean, forKey: "nienie.edgeClean"); pushParams() } }
    /// v2.61 第一批: the fourteen switches, laid over every material and slime (changing either leaves them as they are). Not kept for the next launch,
    /// except the three of the pull, which come back with the desk's numbers
    @Published private(set) var batch = FeelBatch()
    /// v2.61 甲乙 in progress
    @Published private(set) var pullBlind: PullBlind?
    @Published var pullWhat: PullBlind.What = .all
    /// v2.21 speaker button: 0 music and sounds, 1 sounds only, 2 silent
    @Published var soundMode = 0 { didSet { sound.muted = soundMode == 2 || labGrey; syncAudio() } }
    /// v2.40 環境音: "rain", "fire", "noise" (pink noise, 11-22) or "lofi", kept in UserDefaults (long press the speaker button to choose)
    @Published var ambience = UserDefaults.standard.string(forKey: "nienie.amb") ?? "rain" {
        didSet { UserDefaults.standard.set(ambience, forKey: "nienie.amb"); sound.setAmbience(ambience) }
    }
    @Published private(set) var reduceMotion = UIAccessibility.isReduceMotionEnabled
    /// v2.59 窗景: the scene outside the window ("" = the original one), kept in UserDefaults
    @Published private(set) var winId = ""
    /// A line for the hint at the top (and the desk's own line, the hint is hidden while the desk is open)
    @Published private(set) var toastText = ""
    @Published private(set) var toastGen = 0
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
        let saved = SlimeMaterial.clay.defaults.one >= 0.5 && !UserDefaults.standard.bool(forKey: "nienie.showAll") && !UserDefaults.standard.bool(forKey: "nienie.picked") ? SlimeKind.taro : (SlimeKind(rawValue: UserDefaults.standard.string(forKey: "slime") ?? "") ?? .honey)   // v2.57: 十隻都顯示 on, the last one chosen
        slime = saved; material = saved.material
        var start = saved.material.defaults
        saved.apply(&start)
        if UserDefaults.standard.bool(forKey: "nienie.showAll") { start.one = 0 }
        if UserDefaults.standard.bool(forKey: "nienie.clear") { start.clear = 1 }
        rig = SlimeRig(params: start)
        rig.fx = saved.fx   // v2.57 its signature
        rig.reduceMotion = reduceMotion
        if let w = WindowLibrary.def(UserDefaults.standard.string(forKey: "nienie.win") ?? "") {   // v2.59 an id this build does not know: the original window
            winId = w.id
            rig.winNight = w.only
        }
        rig.onEvent = { [weak self] e in self?.handle(e) }
        rig.onGiftTap = { [weak self] in self?.walkAsk = true }
        // v2.34 熟留下來: each slime's saved trust comes back before anything can store a 0 over it; wariness starts at 0
        savedTrust = Self.trustLoad()
        if start.trKeep >= 0.5 {
            for (k, tr) in savedTrust { impressions[k] = (tr, 0) }
            if let tr = savedTrust[saved] { rig.setImpression(trust: tr, wary: 0) }
        }
        for n in [1, 2] { slotSaved[n] = UserDefaults.standard.data(forKey: Self.slotKey(n)) != nil }
        feelLoad()   // 手感調節台: last time's numbers (v2.39; v2.52 the desk's v1 store)
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
            self?.resignedActive = true   // v2.63 C4
        }
        // v2.20: the impression lives for this run only; 10 min or more in the background and it is a first meeting again
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification,
                                               object: nil, queue: .main) { [weak self] _ in self?.backgroundAt = Date() }
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification,
                                               object: nil, queue: .main) { [weak self] _ in
            guard let self, let at = self.backgroundAt else { return }
            if Date().timeIntervalSince(at) >= 600 {
                self.rig.brainBack()   // v2.63 大腦 (web impBack: brainReset(); brainJit(); then the impression)
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
        // v2.63 C4 (greetLook; web: visibilitychange back and blur/focus → greetArm(false)): back in the app (from the background, the lock screen,
        // Control Center, a banner) it turns to you 0.35 s later and blinks; asleep, it wakes slowly without a sound. After willEnterForeground
        // (the 10 min impression reset above comes first, as the web's impBack does); however long it was away, the same. greetLook 0: nothing here
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification,
                                               object: nil, queue: .main) { [weak self] _ in
            guard let self else { return }
            self.startMotion()
            if self.resignedActive { self.resignedActive = false; self.rig.greetArm(open: false) }
        }
    }

    /// The material's numbers with the chosen slime's shape seed and personality on top.
    var current: FeelParams {
        var p = params[material] ?? material.defaults
        slime.apply(&p)
        if showAll { p.one = 0 }   // v2.57
        p.clear = glossyClear ? 1 : 0   // v2.60
        p.coreSoft = coreSoft ? 1 : 0; p.edgeClean = edgeClean ? 1 : 0   // v2.61b
        batch.apply(to: &p)   // v2.61
        return p
    }

    // MARK: - Events → sound + haptics (same event, same frame)

    private func handle(_ e: SlimeEvent) {
        let p = current
        switch e {
        case .press(let gain):
            let probe = LabProbe.shared   // v2.61 B7: timed only while the desk is open, and only what really sounds or taps
            let heard: Bool = soundHeard, felt: Bool = hapticFelt
            if heard { probe.soundStart() }
            sound.press(intensity: pressIntensity(gain, radius: rig.maxTouchRadius, weight: p.sndPressSize))
            if heard { probe.soundEnd() }
            if felt { probe.hapStart() }
            haptics.transient(intensity: 0.25 + 0.35 * gain, sharpness: p.pressSharp)
            if felt { probe.hapEnd() }
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
        case .fx(let kind, let gain, let delay):
            // v2.50 場景聲; landing keeps the soft dull tap it had as .land
            sound.fx(kind, gain: gain, delay: delay)
            if kind == "land" { haptics.transient(intensity: 0.15 + 0.3 * gain, sharpness: 0.2) }
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
        if pullBlind?.pending != nil && !rig.isTouched { pullBlindApply() }   // v2.61 甲乙: the hand is off the body
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
        // v2.54 震動跟著拉力走 (多米 11-22): while pulling, a continuous rumble that grows with the tension (pull length, plus the patch
        // trailing a yank) and gets sharper as it goes taut. Takes over when stronger than the deformation level.
        if p.hapPull > 0 {
            let tn = rig.pullTension
            if tn > 0.02 {
                let lv: Double = p.hapPull * (0.18 + 0.82 * tn)
                if lv > contLevel { contLevel = lv; contSharp = 0.15 + 0.55 * tn }
            }
        }
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
    private var resignedActive = false   // v2.63 C4: left active (background, lock screen, Control Center, a system alert); the next didBecomeActive is a coming back

    func report(_ s: SlimeView.FrameStats) { stats = s }

    /// v2.25 F5 haptic ladder (panel): how faint can this phone still be felt? No public number, only the hand can answer
    func hapticTest(_ intensity: Double, continuous: Bool) { haptics.test(intensity: intensity, continuous: continuous) }

    var audioBufferMs: Double { AVAudioSession.sharedInstance().ioBufferDuration * 1000 }

    /// One line for the panel: real Hz, worst frame, dropped frames, main-thread work, finger contact radius, audio buffer;
    /// then the shake sensor: on or off, the strongest shake in the last 2 s against the threshold (both m/s²).
    var hudText: String {
        String(format: "%.0f Hz｜最長幀 %.1f ms｜掉 %ld｜算 %.2f ms｜物理 %.2f ms｜指 %.0f pt｜音訊緩衝 %.1f ms",
               stats.hz, stats.maxFrameMs, stats.dropped, stats.workMs, stats.physMs, stats.touchRadius, audioBufferMs)
        + "｜晃動感測 " + (motion.isDeviceMotionActive ? "開" : "關")
        + String(format: " %.1f／門檻 %.1f", shakePeak, current.shakeG)
    }

    // MARK: - Parameter plumbing

    private func pushParams() {
        var p = current
        if labGrey { p.greyBox() }   // v2.52 灰盒 (3-2): only the physics is left; the sliders keep their own numbers
        rig.params = p
        syncAudio()
        haptics.setAudioThroughHaptics(current.popViaHaptics >= 0.5, url: sound.releaseSampleURL)
    }

    private func syncAudio() {
        sound.master = current.volMaster
        sound.pitchJitter = current.pitchJitter
        sound.pullMax = current.sndPullMax
        sound.rubMax = current.rubMax
        sound.snd61 = current.snd61 >= 0.5   // v2.61 B1
        sound.voiceBag = current.rubVary >= 0.5   // v2.63 C6
        sound.settleAmt = current.sndSettle
        sound.music = soundMode == 0 && !labGrey ? current.volMusic : 0
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
        rig.fx = k.fx   // v2.57 the new six's signatures
        UserDefaults.standard.set(k.rawValue, forKey: "slime")
        pushParams()
        activeSlot = nil
        rig.resetShape()
        if let imp = impressions[k] { rig.setImpression(trust: imp.trust, wary: imp.wary) }
        else if current.trKeep >= 0.5, let tr = savedTrust[k] { rig.setImpression(trust: tr, wary: 0) }   // v2.34
        else { rig.resetImpression() }
        rig.brainSync()   // v2.63 心情 (web chooseSlime: …IMP set; memSync(); then startIntro)
        rig.startIntro()
        sound.press(intensity: 0.5)
    }

    /// v2.58 (QC-0007 #48: the six new ones were added but nowhere in the settings): picked in the feel desk, kept for the next launch even with 一隻為主 on
    func pickSlime(_ k: SlimeKind) {
        UserDefaults.standard.set(true, forKey: "nienie.picked")
        select(k)
    }

    // MARK: - v2.59 窗景 (多米 11-24). Nothing is bought here: no price, no count.

    private func toast(_ s: String) {
        toastText = s
        toastGen += 1
        feelNote = s
    }
    /// Day or night, for every material (the scene is not part of a slime's numbers); the body is not rebuilt
    private func setScene(_ v: Double) {
        for m in SlimeMaterial.allCases {
            var p = params[m] ?? m.defaults
            p.scene = v
            params[m] = p
        }
        pushParams()
        activeSlot = nil
    }
    /// "" = the original window
    func pickWindow(_ id: String) {
        let d: WindowDef? = WindowLibrary.def(id)
        winId = d?.id ?? ""
        UserDefaults.standard.set(winId, forKey: "nienie.win")
        rig.winNight = d?.only ?? false
        if d != nil && current.scene < 0.5 { setScene(1) }   // the blue background has no window to look out of
        toast(d?.said ?? "換回原本那扇窗")
    }
    func pickNight(_ night: Bool) {
        setScene(night ? 2 : 1)
        if !night, let d = WindowLibrary.def(winId), d.only { toast("這扇窗只有夜晚") }
    }
    /// What is on screen: 0 blue, 1 day, 2 night (a night-only window is open: night)
    var sceneShown: Int {
        let k = Int(current.scene.rounded())
        return k > 0 && (WindowLibrary.def(winId)?.only ?? false) ? 2 : k
    }
    func windowFailed() { toast("這扇窗沒載進來，先放原本那扇") }

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
                if let i = FeelBatch.index(field.key) {   // v2.61: the batch's switches are not a material's
                    let was: [Bool] = self.batch.pullOn
                    self.batch.set(i, v >= 0.5)
                    self.feelPullPressed(was)
                    self.pushParams()
                    self.activeSlot = nil
                    self.feelSave()
                    return
                }
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
        let was: [Bool] = batch.pullOn
        if pullBlind == nil { batch = FeelBatch() }   // v2.61: the panel's own button puts everything on it back
        feelPullPressed(was)
        pushParams()
        activeSlot = nil
        feelSave()   // or A3, A4, A5 would come back at the next launch
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

    // MARK: - v2.52 手感調節台 v1 (多米 11-22 交辦 B 組; 《虛擬手感》3-4 第十一節的規格)
    // What a saved feel is, the copied text and the blind comparison's rules are in UI/FeelDeskModel.swift (the same as the web's desk.js).

    private static let feelKey = "nienie.feel"
    /// Three saved feels (多米 11-22 決定 10)
    @Published private(set) var feelSlots: [FeelSnap?] = [nil, nil, nil]
    /// The blind comparisons, one line each, newest last; 60 are kept and all of them go out with the copied text
    @Published private(set) var feelLog: [String] = []
    /// Not nil when the numbers on the desk were tuned on other defaults than this build's: the desk asks 用新預設／留著我的 (B4)
    @Published private(set) var feelStale: String?
    /// A blind comparison in progress (B3)
    @Published private(set) var feelBlind: FeelBlind?
    @Published var feelQuestion = ""
    @Published var feelNote = "一次只動一條，用那一條底下寫的手勢捏幾下。兩組要比，存成兩格再按盲比。"
    private var feelPv = FeelKnob.version, feelPs = FeelKnob.stamp   // the defaults the numbers on the desk were tuned on
    /// v2.53: the numbers left on the desk when they were tuned on older defaults. Not applied until 多米 says 留著我的 (11-22: build 144 kept
    /// v2.52's strand switched on from the stored desk, so the new pulling never showed)
    private var feelStaleSnap: FeelSnap?
    private var feelBase0: FeelSnap?   // the desk as the app opened (or the material was last chosen): 「這次動過」 counts from here

    private func feelPick() -> FeelSnap {
        var s = FeelSnap.pick(current, base: material.rawValue)
        if let b = pullBlind { s.setPull(b.keep) }   // v2.61 甲乙: what is being compared is not the desk's own
        return s
    }

    private func feelSave() {
        let keep = feelStale != nil ? feelStaleSnap : nil
        let s = FeelDeskStore(pv: feelPv, ps: feelPs, base: keep?.base ?? material.rawValue, k: keep?.k ?? feelPick().k, s: feelSlots, log: Array(feelLog.suffix(60)))
        if let d = try? JSONEncoder().encode(s) { UserDefaults.standard.set(d, forKey: Self.feelKey) }
    }

    /// v2.61: A3, A4 or A5 was just pressed (not set by a whole saved feel). While 用新預設／留著我的 is not answered, feelSave writes 多米's older numbers and not the
    /// desk, so the ones that changed go into those: they are stored, and 留著我的 does not undo them. The ones not pressed stay as they were stored.
    private func feelPullPressed(_ was: [Bool]) {
        guard pullBlind == nil, let old = feelStaleSnap else { return }
        let now: [Bool] = batch.pullOn
        var kept: [Bool] = old.pullOn
        for i in kept.indices where i < now.count && i < was.count && now[i] != was[i] { kept[i] = now[i] }
        feelStaleSnap?.setPull(kept)
    }

    /// Lay a saved feel over the material's numbers: its material first, then the 13 numbers. Nothing else happens: no bump, no sound
    /// (3-4: any movement added at the switch lies on top of what is being compared).
    private func feelApply(_ s: FeelSnap) {
        if let m = SlimeMaterial(rawValue: s.base), m != material { material = m }
        var p = current
        s.apply(to: &p)
        params[material] = p
        if pullBlind == nil { batch.setPull(s.pullOn) }   // v2.61
        pushParams()
        activeSlot = nil
        feelSave()
    }

    /// At launch: the numbers 多米 left on the desk last time come back (called from init). The v2.39 to v2.51 desk's A and B become slots 1 and 2.
    func feelLoad() {
        defer { feelBase0 = feelPick() }
        guard let d = UserDefaults.standard.data(forKey: Self.feelKey), let r = FeelDeskStore.decode(d) else { return }
        feelSlots = (0..<3).map { $0 < r.store.s.count ? r.store.s[$0]?.filled() : nil }
        feelLog = r.store.log
        if r.store.ps != FeelKnob.stamp {   // tuned on other defaults: keep that on record until 多米 answers, however many launches that takes
            feelStale = r.old ? "v2.39 到 v2.51 的調節台" : (r.store.pv.isEmpty ? "舊版" : r.store.pv)
            feelPv = r.store.pv; feelPs = r.store.ps
            feelStaleSnap = FeelSnap(base: r.store.base, pv: nil, ps: nil, k: r.store.k).filled()
            return   // start from this build's defaults; 留著我的 brings the stored numbers back
        }
        if let cur = FeelSnap(base: r.store.base, pv: nil, ps: nil, k: r.store.k).filled() { feelApply(cur) }
    }

    func feelBinding(_ k: FeelKnob) -> Binding<Double> {
        Binding(
            get: { self.current[keyPath: k.key] },
            set: { v in
                var p = self.current
                p[keyPath: k.key] = v
                self.params[self.material] = p
                self.pushParams()
                self.activeSlot = nil
                self.feelSave()
            }
        )
    }

    /// 韌的另一半 (v2.51 黏條): on, the body itself stops at a stable length and the rest is a strand; off, the body pulls as far as 韌 says (交辦 A1).
    var feelStrand: Bool { current.strand >= 0.5 }
    func feelToggleStrand() {
        var p = current
        p.strand = p.strand >= 0.5 ? 0 : 1
        params[material] = p
        pushParams()
        activeSlot = nil
        feelSave()
    }

    /// 從哪個材質開始: that material's own numbers (this build's defaults, so the question about older defaults is answered too).
    func feelStartFrom(_ m: SlimeMaterial) {
        material = m
        params[m] = m.defaults
        pushParams()
        activeSlot = nil
        rig.bump(1)
        feelStale = nil; feelStaleSnap = nil; feelPv = FeelKnob.version; feelPs = FeelKnob.stamp
        feelBase0 = feelPick()
        feelSave()
        feelNote = "換成\(m.name)的預設值。"
    }

    /// v2.54 手感風格: lay one of the ten over clay's defaults, like going to a saved feel (no bump).
    func feelStyle(_ st: FeelStyle) {
        guard feelBlind == nil else { return }
        var sn = st.snap
        sn.setPull(batch.pullOn)   // v2.61: a style moves the knobs only
        feelApply(sn)
        feelNote = "套上「\(st.name)」：\(st.math)。\(st.feel)。不喜歡就按「回到預設」，喜歡的話存成一格，可以拿去跟別的盲比。"
    }
    /// The style the desk's numbers are exactly, if any.
    var feelStyleNow: String? {
        guard material == .clay else { return nil }
        let cur = feelPick()
        return FeelStyle.all.first { $0.matches(cur) }?.id
    }

    func feelStore(_ i: Int) {
        guard feelSlots.indices.contains(i) else { return }
        feelSlots[i] = feelPick()
        feelSave()
        feelNote = "現在的手感存成 \(i + 1)。"
    }

    /// v2.52 B2: no bump any more. The bump moved the body at the very moment the two feels were to be compared.
    func feelGo(_ i: Int) {
        guard feelSlots.indices.contains(i), let s = feelSlots[i] else { return }
        feelApply(s)
        feelNote = "換到 \(i + 1)（\(material.name)起點）。馬上捏，幾秒內再換另一個。"
    }

    // B3 盲比
    func feelBlindStart(_ a: Int, _ b: Int) {
        guard feelBlind == nil, feelSlots.indices.contains(a), feelSlots.indices.contains(b), feelSlots[a] != nil, feelSlots[b] != nil else { return }
        let blind = FeelBlind(a, b, keep: feelPick(), now: ProcessInfo.processInfo.systemUptime)
        feelBlind = blind
        if let s = feelSlots[blind.slot] { feelApply(s) }
        feelNote = "盲比開始。先摸的是 \(blind.first + 1) 號。用同一個手勢各捏幾下，幾秒內換過去再捏；選完才會告訴你哪個是哪個。"
    }
    func feelBlindShow(_ n: Int) {
        guard var b = feelBlind, b.current != n, n == 0 || n == 1 else { return }
        b.show(n)
        feelBlind = b
        if let s = feelSlots[b.slot] { feelApply(s) }
    }
    /// - Parameter choice: 0 or 1 for 1 號 or 2 號, nil for 分不出來
    func feelBlindEnd(choice: Int?) {
        guard let b = feelBlind else { return }
        feelBlind = nil
        guard let sa = feelSlots[b.pair.0], let sb = feelSlots[b.pair.1] else { feelApply(b.keep); return }
        feelLog.append(b.line(choice: choice, a: sa, b: sb, question: feelQuestion, now: ProcessInfo.processInfo.systemUptime))
        if feelLog.count > 60 { feelLog.removeFirst(feelLog.count - 60) }
        if let c = choice, c == 0 || c == 1, let s = feelSlots[b.map[c]] { feelApply(s) } else { feelApply(b.keep) }
        feelNote = b.reveal(choice: choice)
    }
    func feelBlindCancel() {
        guard let b = feelBlind else { return }
        feelBlind = nil
        feelApply(b.keep)
        feelNote = "盲比取消，回到剛剛的數字。這次不記。"
    }

    // B4 預設改版
    func feelUseNewDefaults() {
        params[material] = material.defaults
        pushParams()
        activeSlot = nil
        feelStale = nil; feelStaleSnap = nil; feelPv = FeelKnob.version; feelPs = FeelKnob.stamp
        feelBase0 = feelPick()
        feelSave()
        feelNote = "換成新預設（\(material.name)）。存檔那幾格還留著，是舊預設上調的。"
    }
    func feelKeepMine() {
        let old = feelStaleSnap
        feelStale = nil; feelStaleSnap = nil; feelPv = FeelKnob.version; feelPs = FeelKnob.stamp
        if let old { feelApply(old) }
        feelSave()
        feelNote = "留著你的數字。之後按「回到預設」可以看新預設。"
    }

    /// 回到預設: this slime's own material at its default numbers, the three slots cleared. The blind comparisons' lines stay.
    func feelDefaults() {
        feelBlind = nil
        material = slime.material
        for m in SlimeMaterial.allCases { params[m] = m.defaults }
        batch.setPull([false, false, false])   // v2.61: what is saved goes back, the other switches stay
        feelSlots = [nil, nil, nil]
        feelStale = nil; feelStaleSnap = nil; feelPv = FeelKnob.version; feelPs = FeelKnob.stamp
        pushParams()
        activeSlot = nil
        rig.bump(1)
        feelBase0 = feelPick()
        feelSave()
        feelNote = "回到預設（\(material.name)），三格存檔也清掉了。盲比紀錄留著。"
    }

    /// 這次動過: the knobs that differ from what was on the desk when the app opened, "名字 a→b"
    var feelChanged: [String] {
        guard let b = feelBase0 else { return [] }
        let now = feelPick()
        var o: [String] = []
        if b.base != now.base { o.append("材料 \(FeelKnob.materialName(b.base))→\(FeelKnob.materialName(now.base))") }
        for id in FeelKnob.keys where FeelKnob.fmt(b.k[id] ?? 0) != FeelKnob.fmt(now.k[id] ?? 0) {
            o.append("\(FeelKnob.name(id)) \(FeelKnob.fmt(b.k[id] ?? 0))→\(FeelKnob.fmt(now.k[id] ?? 0))")
        }
        return o + FeelSnap.pullDiff(b, now, "→")
    }

    // MARK: - v2.61 這一批

    func batchTier(_ t: FeelBatch.Tier) {
        guard pullBlind == nil else { return }
        let was: [Bool] = batch.pullOn
        batch = FeelBatch(t)
        feelPullPressed(was)
        batchDone("換到「\(t.name)」。")
    }
    func batchTogglePull(_ id: String) {
        guard pullBlind == nil else { return }
        let was: [Bool] = batch.pullOn
        batch[id] = !batch[id]
        feelPullPressed(was)
        let v: String = batch[id] ? "開" : "關"
        batchDone("\(FeelBatch.pullName(id))：\(v)。")
    }
    func batchToggleGroup(_ g: FeelBatch.Group) {
        let v = !batch.all(g.ids)
        for id in g.ids { batch[id] = v }
        let w: String = v ? "開" : "關"
        batchDone("\(g.name)：\(w)。")
    }
    /// v2.63 這一批: one switch of FeelBatch.b63 (the web's data-63k buttons), not saved
    func batchToggle63(_ it: FeelBatch.Item) {
        batch[it.id] = !batch[it.id]
        let w: String = batch[it.id] ? "開" : "關"
        batchDone("\(it.name)：\(w)。")
    }
    private func batchDone(_ note: String) {
        pushParams()
        activeSlot = nil
        feelSave()
        feelNote = note
    }

    /// 甲 or 乙 (0 or 1). The first press starts a comparison and tosses the coin.
    func pullBlindPick(_ side: Int) {
        guard feelBlind == nil, side == 0 || side == 1 else { return }
        var b = pullBlind ?? PullBlind(pullWhat, keep: batch.pullOn, now: ProcessInfo.processInfo.systemUptime)
        b.pending = side
        pullBlind = b
        if !rig.isTouched { pullBlindApply() }
    }
    func pullBlindReveal() {
        guard var b = pullBlind, !b.revealed else { return }
        b.revealed = true
        pullBlind = b
        feelLog.append(b.line(now: ProcessInfo.processInfo.systemUptime))
        if feelLog.count > 60 { feelLog.removeFirst(feelLog.count - 60) }
        feelSave()
    }
    func pullBlindStop() {
        guard var b = pullBlind else { return }
        b.pending = 2
        pullBlind = b
        if !rig.isTouched { pullBlindApply() }
    }
    private func pullBlindApply() {
        guard var b = pullBlind, let n = b.pending else { return }
        b.pending = nil
        if n == 2 {
            pullBlind = nil
            batch.setPull(b.keep)
            pushParams()
            feelSave()
            feelNote = "甲乙比完，拉的三顆回到原本的。"
            return
        }
        if let s = b.shown, s != n { b.switches += 1 }
        b.shown = n
        pullBlind = b
        batch.setPull(b.sides[n])
        pushParams()
    }

    /// v2.52 A2: what the sliders say against what the physics really uses (a scene or a mode can override a slider)
    var feelEffective: FeelEffective { FeelEffective(current, grey: labGrey) }

    /// "iPhone15,2": the hardware's own name (no public call gives the name on the box)
    private static let machine: String = {
        var info = utsname()
        uname(&info)
        return withUnsafePointer(to: &info.machine) { $0.withMemoryRebound(to: CChar.self, capacity: 1) { String(cString: $0) } }
    }()

    /// B5: the first line of the copied text: build, defaults, model, refresh rate, low power
    private var feelHeader: String {
        let info = Bundle.main.infoDictionary
        let build = (info?["CFBundleVersion"] as? String) ?? "?", ver = (info?["CFBundleShortVersionString"] as? String) ?? "?"
        return "捏捏手感 v2｜build \(build)（\(ver)）｜預設 \(FeelKnob.version)·\(FeelKnob.stamp)｜\(Self.machine)｜螢幕 \(UIScreen.main.maximumFramesPerSecond) Hz、現在 \(Int(stats.hz.rounded())) Hz｜低電量 \(ProcessInfo.processInfo.isLowPowerModeEnabled ? "開" : "關")"
    }

    /// 複製數值給 Agent. Pasted back with 貼上匯入 (here or on the web), the same numbers and slots come up again.
    var feelText: String {
        let eff = feelEffective
        var extra: [String] = []
        if labGrey || labCircle || !labLayersOff.isEmpty {
            let off = Self.labLayers.filter { labLayersOff.contains($0.id) }.map { $0.name }
            extra.append("量測：灰盒 \(labGrey ? "開" : "關")、純圓 \(labCircle ? "開" : "關")" + (off.isEmpty ? "" : "、關掉的圖層：" + off.joined(separator: "、")))
        }
        extra.append("讀數：" + labText.replacingOccurrences(of: "\n", with: "｜"))
        if let f = fuzzSummary { extra.append(f.text) }
        if LabProbe.shared.lagAny { extra.append(lagCopy) }   // v2.61 B7
        extra.append(batch.line)   // v2.61
        return FeelExport.text(header: feelHeader, slimeName: slime.name, current: feelPick(),
                               effectivePull: eff.used.maxPull != eff.set.maxPull ? eff.used.maxPull : nil,
                               slots: feelSlots, changed: feelChanged, log: feelLog, extra: extra)
    }

    /// 貼上匯入
    @discardableResult
    func feelImport(_ text: String) -> Bool {
        guard feelBlind == nil, pullBlind == nil else { return false }
        guard let r = FeelExport.parse(text) else {
            feelNote = "剪貼簿裡找不到 #nienie-feel 那一行。先拷貝「複製數值給 Agent」複製出來的整段字，再按一次「貼上匯入」。"
            return false
        }
        feelSlots = r.slots
        feelApply(r.current)
        feelNote = !r.ps.isEmpty && r.ps != FeelKnob.stamp
            ? "匯入了。注意：這段字是在預設 \(r.pv.isEmpty ? "?" : r.pv) 上調的，現在的預設是 \(FeelKnob.version)。"
            : "匯入了，數字跟那段字一樣。"
        return true
    }

    // MARK: - v2.52 量測 (交辦 B6、A5、C4; 《虛擬手感》3-2 灰盒與純圓, 3-3 亂捏測試, 3-5 一層一層量). Never saved: off again at the next launch.

    /// 灰盒: only the physics. One flat grey, no eyes, no life of its own, no sound, no haptics, no decorations; the wall, the sill and the bowl stay.
    /// The sliders keep their numbers (the grey box lies over them while it is on).
    @Published var labGrey = false {
        didSet {
            guard labGrey != oldValue else { return }
            sound.muted = soundMode == 2 || labGrey
            haptics.enabled = !labGrey
            if labGrey { sound.stopAll(); haptics.stopContinuous() }
            pushParams()
        }
    }
    /// 純圓: a 2 cm disc whose centre is the finger, nothing handed to the body: the system's own lag (跟手基準的 C)
    @Published var labCircle = false
    /// 圖層 (C4): the skin's layers switched off one at a time, to read each one's cost off the frame readout
    @Published private(set) var labLayersOff: Set<String> = []
    static let labLayers: [(id: String, name: String)] = [
        ("round", "輪廓圓角"), ("shade", "明暗"), ("hi", "高光"), ("wet", "第二高光與邊光"), ("refr", "折射"),
        ("caustic", "聚光"), ("bubbles", "氣泡"), ("dent", "凹痕"), ("mood", "心情色"),
    ]
    func labToggleLayer(_ id: String) {
        if labLayersOff.contains(id) { labLayersOff.remove(id) } else { labLayersOff.insert(id) }
    }
    /// A layer whose own number is 0 is not drawn anyway; its switch is greyed out
    func labLayerDead(_ id: String) -> Bool {
        let p = current
        switch id {
        case "round": return !(p.round > 0)
        case "hi": return !(p.lookShine > 0)
        case "wet": return !(p.lookShine > 0 && p.wet >= 0.5)
        case "refr": return !(p.water > 0)
        case "caustic": return !(p.caustic > 0)
        case "bubbles": return !(p.bubbles > 0)
        case "dent": return !(p.dent >= 0.5)
        case "mood": return !(p.moodColor > 0)
        default: return false
        }
    }
    func labResetReadouts() {
        rig.guardReset()
        LabProbe.shared.lagReset()
        LabProbe.shared.skinReset()
        objectWillChange.send()
    }

    // v2.61 B7, A7: what LabProbe reads, shown on the desk (refreshed with the frame readout twice a second) and copied
    /// The desk opened or closed: touches are timed only while it is open, and 固定 120 ends with it
    func labDesk(open: Bool) {
        LabProbe.shared.on = open
        if !open && lab120 { lab120 = false }
    }
    /// What LabProbe may time: a press that is muted, at volume 0 or on a phone without haptics returns at once and would read as fast.
    /// The ringer switch on the side silences the app too, and no call tells.
    private var soundHeard: Bool { !sound.muted && current.volMaster > 0 }
    private var hapticFelt: Bool { haptics.enabled && Self.hasHaptics }
    private static let hasHaptics: Bool = CHHapticEngine.capabilitiesForHardware().supportsHaptics
    /// 碰著時固定 120, never saved, off again when the desk is closed
    @Published var lab120 = false { didSet { LabProbe.shared.lock120 = lab120 } }
    func labSkinStart() {
        LabProbe.shared.skinStart()
        objectWillChange.send()
    }
    var labSkinOn: Bool { LabProbe.shared.skinOn }
    var labProbeText: String { LabProbe.shared.lagShort + "\n" + LabProbe.shared.skinText }
    private var lagCopy: String {
        let s = AVAudioSession.sharedInstance()
        let route = s.currentRoute.outputs.first?.portType.rawValue ?? "?"
        let ms: String = String(format: "音訊：緩衝 %.1f 毫秒、系統報的輸出延遲 %.1f、引擎報的 %.1f", s.ioBufferDuration * 1000, s.outputLatency * 1000, sound.engineLatency * 1000)
        let a: String = lab120 ? "開" : "關", b: String = latencyTest ? "開" : "關", c: String = labGrey ? "開" : "關"
        let d: String = soundHeard ? "開" : "靜音（不記）", e: String = hapticFelt ? "開" : "沒有（不記）"
        return LabProbe.shared.lagText + "\n\(ms)（輸出 \(route)）｜聲音 \(d)｜震動 \(e)｜固定 120 \(a)｜延遲測試 \(b)｜灰盒 \(c)"
    }
    /// 複製量測: plain text, with the machine, the system, low power, the version and the numbers it was measured on
    var labCopyText: String {
        let knobs: [String] = FeelKnob.main.map { $0.name + " " + FeelKnob.fmt(current[keyPath: $0.key]) }
        var t: [String] = [feelHeader + "｜系統 " + UIDevice.current.systemVersion]
        t.append("參數：" + material.name + "（" + slime.name + "）｜" + knobs.joined(separator: "、"))
        t.append(batch.line)
        t.append("讀數：" + labText.replacingOccurrences(of: "\n", with: "｜"))
        t.append(lagCopy)
        t.append(LabProbe.shared.skinText)
        return t.joined(separator: "\n")
    }

    /// The 量測 readout (B6): refresh rate, longest frame, the physics alone, how often each guard acted (since 讀數歸零)
    var labText: String {
        let g = rig.guardStats
        func f(_ v: Double, _ d: Int = 1) -> String { String(format: "%.\(d)f", v) }
        var t = "\(f(stats.hz, 0)) Hz｜最長一格 \(f(stats.maxFrameMs)) 毫秒｜掉 \(stats.dropped) 格｜整格 \(f(stats.workMs, 2)) 毫秒｜物理 \(f(stats.physMs, 2)) 毫秒（一秒內最長 \(f(stats.physMaxMs))）"
        if current.decoThru >= 0.5 { t += "｜擺飾透過身體 \(f(stats.decoMs, 2)) 毫秒" }
        t += "\n保險作用的格：拉到上限 \(f(g.pct(g.hi)))%、壓到下限 \(f(g.pct(g.lo)))%、防翻面 \(f(g.pct(g.flip)))%、手指讓 \(f(g.pct(g.give)))%｜手指最多讓 \(f(g.giveMax, 2)) 個半徑、往外拉時 \(f(g.givePull, 2))｜\(g.frames) 格"
        return t
    }

    /// 亂捏測試 on the phone (A5): 30 fixed seeds on a rig of its own, off the main thread, with the numbers on the desk. About a minute; the slime on screen can be squeezed meanwhile.
    @Published private(set) var fuzzRunning = false
    @Published private(set) var fuzzText = ""
    private(set) var fuzzSummary: SlimeFuzz.Summary?
    func fuzzRun() {
        guard !fuzzRunning, rig.W > 0, rig.H > 0 else { return }
        fuzzRunning = true
        fuzzText = "亂捏測試：0／30 組……大約一分鐘，可以繼續捏"
        let p = current, w = rig.W, h = rig.H
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let r = SlimeFuzz.run(seeds: Array(1000...1029), params: p, width: w, height: h) { done, total in
                DispatchQueue.main.async { [weak self] in self?.fuzzText = "亂捏測試：\(done)／\(total) 組……" }
                return self != nil
            }
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.fuzzRunning = false
                self.fuzzSummary = r.summary
                self.fuzzText = r.summary.text
            }
        }
    }

    // MARK: - Blind-test slots

    private static func slotKey(_ n: Int) -> String { "feelSlot\(n)" }

    func saveSlot(_ n: Int) {
        guard pullBlind == nil, let data = try? JSONEncoder().encode(current) else { return }
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
        guard pullBlind == nil, let data = UserDefaults.standard.data(forKey: Self.slotKey(n)),
              var p = decodeSlot(data) else { return }
        // v2.61: the slot's own A3, A4, A5 (a slot from before has none: off); the batch's other switches stay as they are
        let raw = ((try? JSONSerialization.jsonObject(with: data)) as? [String: Any]) ?? [:]
        batch.setPull(FeelBatch.pull.map { ((raw[$0] as? NSNumber)?.doubleValue ?? 0) >= 0.5 })
        // v2.60: a slot carries the feel, never the look. Slots saved on build 158 or older hold shine 1, opaque 0 (the glossy body): going to one would bring that back,
        // and two slots that look different are no blind test (how soft it feels follows how it looks)
        let now = current
        p.shine = now.shine; p.opaque = now.opaque; p.clear = now.clear; p.coreSoft = now.coreSoft; p.edgeClean = now.edgeClean
        params[material] = p
        pushParams()
        activeSlot = n
        rig.bump(1)
        feelSave()   // v2.61: the slot's A3, A4, A5 are on the desk now, so they are there at the next launch too (and its 13 numbers, like 換到)
    }

    /// v2.61: while 甲乙 is on, the three of the pull are nowhere on the panel
    func hiddenNow(_ f: TuneField) -> Bool {
        guard pullBlind != nil, let i = FeelBatch.index(f.key) else { return false }
        return FeelBatch.pull.contains(FeelBatch.keys[i].id)
    }

    /// Same JSON shape as the prototype's 複製數值.
    var exportText: String {
        let p = current
        let pairs = TuneField.all.filter { !hiddenNow($0) }.map { f in "\"\(f.name)\":\(Self.fmt(p[keyPath: f.key]))" }
        return "{\"史萊姆\":\"\(slime.name)\",\"手感\":\"\(material.name)\"," + pairs.joined(separator: ",") + "}"
    }

    private static func fmt(_ v: Double) -> String {
        let r = (v * 1000).rounded() / 1000
        return r == r.rounded() ? String(Int(r)) : String(r)
    }
}
