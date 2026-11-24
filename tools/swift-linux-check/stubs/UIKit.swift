// Linux stand-in for the little of UIKit the app's non-drawing code touches (type-check only, nothing runs).
@_exported import Foundation
public typealias CGFloat = Foundation.CGFloat
public final class UIColor {
    public init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {}
    public init(white: CGFloat, alpha: CGFloat) {}
    public var cgColor: CGColor { CGColor() }
    public func withAlphaComponent(_ a: CGFloat) -> UIColor { self }
    public static let white = UIColor(white: 1, alpha: 1)
    public static let black = UIColor(white: 0, alpha: 1)
    public static let clear = UIColor(white: 0, alpha: 0)
}
public enum UIAccessibility {
    public static var isReduceMotionEnabled: Bool { false }
    public static let reduceMotionStatusDidChangeNotification = Notification.Name("a")
}
public final class UIApplication {
    public static let willResignActiveNotification = Notification.Name("b")
    public static let didEnterBackgroundNotification = Notification.Name("c")
    public static let willEnterForegroundNotification = Notification.Name("d")
    public static let didBecomeActiveNotification = Notification.Name("e")
}
public final class UIScreen {
    public static let main = UIScreen()
    public var maximumFramesPerSecond: Int { 120 }
    public var scale: CGFloat { 3 }
}
public final class UIDevice {
    public static let current = UIDevice()
    public var systemVersion: String { "" }
}
public final class UIPasteboard {
    public static let general = UIPasteboard()
    public var string: String?
}
extension ProcessInfo { public var isLowPowerModeEnabled: Bool { false } }
