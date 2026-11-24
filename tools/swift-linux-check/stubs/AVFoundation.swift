@_exported import Foundation
public final class AVAudioSession {
    public static func sharedInstance() -> AVAudioSession { AVAudioSession() }
    public var ioBufferDuration: Double { 0.005 }
    public var outputLatency: Double { 0 }
    public var currentRoute: AVAudioSessionRouteDescription { AVAudioSessionRouteDescription() }
    public struct Port: RawRepresentable { public let rawValue: String; public init(rawValue: String) { self.rawValue = rawValue } }
}
public final class AVAudioSessionRouteDescription { public init() {}; public var outputs: [AVAudioSessionPortDescription] { [] } }
public final class AVAudioSessionPortDescription { public init() {}; public var portType: AVAudioSession.Port { AVAudioSession.Port(rawValue: "") } }
