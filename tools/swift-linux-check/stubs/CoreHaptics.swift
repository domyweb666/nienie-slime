@_exported import Foundation
public protocol CHHapticDeviceCapability { var supportsHaptics: Bool { get } }
struct NoHaptics: CHHapticDeviceCapability { var supportsHaptics: Bool { false } }
public final class CHHapticEngine {
    public static func capabilitiesForHardware() -> CHHapticDeviceCapability { NoHaptics() }
}
