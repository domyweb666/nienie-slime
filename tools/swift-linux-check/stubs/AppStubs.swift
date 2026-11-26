// Stand-ins for the app's own UIKit/AVFoundation/CoreHaptics/Metal-heavy classes, with the members the controller and the SwiftUI views use.
import SwiftUI

protocol SlimeSoundSource: AnyObject {
    var muted: Bool { get set }
    var master: Double { get set }
    var pitchJitter: Double { get set }
    var pullMax: Double { get set }
    var rubMax: Double { get set }
    var snd61: Bool { get set }
    var voiceBag: Bool { get set }
    var sndB6: Bool { get set }
    var sndB5: Bool { get set }
    var engineLatency: Double { get }
    var settleAmt: Double { get set }
    var music: Double { get set }
    func setAmbience(_ name: String)
    func press(intensity: Double)
    func strand(gain: Double)
    func release(gain: Double)
    func flinch(gain: Double)
    func frame(dt: Double, rub: Double, stretch: Double, grabbing: Bool)
    func stopAll()
    func voice(_ kind: String, gain: Double, rate: Double)
    func ding(gain: Double)
    func fx(_ kind: String, gain: Double, delay: Double)
    var releaseSampleURL: URL? { get }
}
final class SlimeAudio: SlimeSoundSource {
    var muted = false, master = 1.0, pitchJitter = 0.0, pullMax = 0.0, rubMax = 0.0, settleAmt = 0.0, music = 0.0
    var snd61 = true
    var voiceBag = true
    var sndB6 = true
    var sndB5 = true
    var engineLatency: Double { 0 }
    func setAmbience(_ name: String) {}
    func press(intensity: Double) {}
    func strand(gain: Double) {}
    func release(gain: Double) {}
    func flinch(gain: Double) {}
    func frame(dt: Double, rub: Double, stretch: Double, grabbing: Bool) {}
    func stopAll() {}
    func voice(_ kind: String, gain: Double, rate: Double) {}
    func ding(gain: Double) {}
    func fx(_ kind: String, gain: Double, delay: Double) {}
    var releaseSampleURL: URL? { nil }
}
final class SlimeHaptics {
    var enabled = true
    var popAudioReady: Bool { false }
    func updateContinuous(level: Double, sharpness: Double) {}
    func setAudioThroughHaptics(_ on: Bool, url: URL?) {}
    func stopContinuous() {}
    func test(intensity: Double, continuous isContinuous: Bool) {}
    func transient(intensity: Double, sharpness: Double) {}
    func pop(strength: Double, count: Int, gap: Double, decay: Double, sharpness: Double, minIntensity: Double, maxIntensity: Double, audioVolume: Double? = nil) {}
    func tick(intensity: Double, sharpness: Double) {}
    func flush() {}
}
struct SlimeCanvas: View {
    var controller: SlimeController
    var body: some View { EmptyView() }
}
struct StepProbe: View { var body: some View { EmptyView() } }
