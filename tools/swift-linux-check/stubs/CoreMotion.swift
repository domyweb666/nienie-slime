@_exported import Foundation
public final class CMPedometerData { public var numberOfSteps: NSNumber { 0 } }
public final class CMPedometer {
    public init() {}
    public static func isStepCountingAvailable() -> Bool { false }
    public func queryPedometerData(from: Date, to: Date, withHandler: @escaping (CMPedometerData?, Error?) -> Void) {}
}
public struct CMAcceleration { public var x = 0.0, y = 0.0, z = 0.0 }
public final class CMDeviceMotion { public var userAcceleration: CMAcceleration { CMAcceleration() }; public var timestamp: TimeInterval { 0 } }
public final class CMMotionManager {
    public init() {}
    public var isDeviceMotionAvailable: Bool { false }
    public var isDeviceMotionActive: Bool { false }
    public var deviceMotionUpdateInterval: TimeInterval = 0
    public func startDeviceMotionUpdates(to: OperationQueue, withHandler: @escaping (CMDeviceMotion?, Error?) -> Void) {}
    public func stopDeviceMotionUpdates() {}
}
