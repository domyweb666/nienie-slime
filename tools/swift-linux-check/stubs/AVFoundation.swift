@_exported import Foundation
public final class AVAudioSession {
    public static func sharedInstance() -> AVAudioSession { AVAudioSession() }
    public var ioBufferDuration: Double { 0.005 }
}
