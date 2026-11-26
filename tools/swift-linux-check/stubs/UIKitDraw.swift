// Core Graphics, Core Animation and UIView stand-ins for SlimeView.swift (type-check only)
public typealias CFTimeInterval = Double
public func CACurrentMediaTime() -> CFTimeInterval { 0 }
public final class CGColorSpace {}
public func CGColorSpaceCreateDeviceRGB() -> CGColorSpace { CGColorSpace() }
public func CGColorSpaceCreateDeviceGray() -> CGColorSpace { CGColorSpace() }
public final class CGImage {}
public enum CGImageAlphaInfo: UInt32 { case none = 0, premultipliedFirst = 2 }
public struct CGBitmapInfo: OptionSet { public let rawValue: UInt32; public init(rawValue: UInt32) { self.rawValue = rawValue }; public static let byteOrder32Little = CGBitmapInfo(rawValue: 2 << 12) }
public final class CGContext {
    public init?(data: UnsafeMutableRawPointer?, width: Int, height: Int, bitsPerComponent: Int, bytesPerRow: Int, space: CGColorSpace, bitmapInfo: UInt32) {}
    public var data: UnsafeMutableRawPointer? { nil }
    public var bytesPerRow: Int { 0 }
    public func translateBy(x: CGFloat, y: CGFloat) {}
    public func scaleBy(x: CGFloat, y: CGFloat) {}
    public func rotate(by: CGFloat) {}
    public func setFillColor(gray: CGFloat, alpha: CGFloat) {}
    public func setStrokeColor(gray: CGFloat, alpha: CGFloat) {}
    public func setLineCap(_ c: CGLineCap) {}
    public func move(to: CGPoint) {}
    public func addLine(to: CGPoint) {}
    public func clear(_ r: CGRect) {}
    public func setFillColor(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {}
    public func fill(_ r: CGRect) {}
    public func addPath(_ p: CGPath) {}
    public func fillPath() {}
    public func draw(_ image: CGImage, in rect: CGRect, byTiling: Bool = false) {}
    public func saveGState() {}
    public func restoreGState() {}
    public func clip(to rect: CGRect) {}
    public func setAlpha(_ a: CGFloat) {}
}
extension UIColor { public func getRed(_ r: UnsafeMutablePointer<CGFloat>?, green: UnsafeMutablePointer<CGFloat>?, blue: UnsafeMutablePointer<CGFloat>?, alpha: UnsafeMutablePointer<CGFloat>?) -> Bool { true } }

public final class CGColor {}
public struct CGAffineTransform {
    public var a: CGFloat = 1, b: CGFloat = 0, c: CGFloat = 0, d: CGFloat = 1, tx: CGFloat = 0, ty: CGFloat = 0
    public init() {}
    public init(a: CGFloat, b: CGFloat, c: CGFloat, d: CGFloat, tx: CGFloat, ty: CGFloat) {}
    public init(rotationAngle: CGFloat) {}
    public init(scaleX: CGFloat, y: CGFloat) {}
    public init(translationX: CGFloat, y: CGFloat) {}
    public static let identity = CGAffineTransform()
    public func concatenating(_ t: CGAffineTransform) -> CGAffineTransform { self }
    public func rotated(by: CGFloat) -> CGAffineTransform { self }
    public func scaledBy(x: CGFloat, y: CGFloat) -> CGAffineTransform { self }
    public func translatedBy(x: CGFloat, y: CGFloat) -> CGAffineTransform { self }
}
public enum CGLineCap { case butt, round, square }
public enum CGLineJoin { case miter, round, bevel }
public class CGPath {
    public init() {}
    public init(ellipseIn: CGRect, transform: UnsafePointer<CGAffineTransform>?) {}
    public init(rect: CGRect, transform: UnsafePointer<CGAffineTransform>?) {}
    public init(roundedRect: CGRect, cornerWidth: CGFloat, cornerHeight: CGFloat, transform: UnsafePointer<CGAffineTransform>?) {}
    public var boundingBoxOfPath: CGRect { .zero }
    public var boundingBox: CGRect { .zero }
    public var isEmpty: Bool { true }
    public func copy(strokingWithWidth: CGFloat, lineCap: CGLineCap, lineJoin: CGLineJoin, miterLimit: CGFloat, transform: CGAffineTransform = .identity) -> CGPath { self }
    public func contains(_ p: CGPoint) -> Bool { false }
}
public final class CGMutablePath: CGPath {
    public func move(to: CGPoint, transform: CGAffineTransform = .identity) {}
    public func addLine(to: CGPoint, transform: CGAffineTransform = .identity) {}
    public func addQuadCurve(to: CGPoint, control: CGPoint, transform: CGAffineTransform = .identity) {}
    public func addCurve(to: CGPoint, control1: CGPoint, control2: CGPoint, transform: CGAffineTransform = .identity) {}
    public func addArc(center: CGPoint, radius: CGFloat, startAngle: CGFloat, endAngle: CGFloat, clockwise: Bool, transform: CGAffineTransform = .identity) {}
    public func addEllipse(in: CGRect, transform: CGAffineTransform = .identity) {}
    public func addRect(_ r: CGRect, transform: CGAffineTransform = .identity) {}
    public func addRoundedRect(in: CGRect, cornerWidth: CGFloat, cornerHeight: CGFloat, transform: CGAffineTransform = .identity) {}
    public func addPath(_ p: CGPath, transform: CGAffineTransform = .identity) {}
    public func addLines(between: [CGPoint], transform: CGAffineTransform = .identity) {}
    public func closeSubpath() {}
}
public final class CGGradient { public init?(colorsSpace: CGColorSpace?, colors: CFArray, locations: UnsafePointer<CGFloat>?) {} }
public typealias CFArray = NSArray
public struct CGGradientDrawingOptions: OptionSet { public let rawValue: UInt32; public init(rawValue: UInt32) { self.rawValue = rawValue }; public static let drawsBeforeStartLocation = CGGradientDrawingOptions(rawValue: 1), drawsAfterEndLocation = CGGradientDrawingOptions(rawValue: 2) }
extension CGContext {
    public func drawRadialGradient(_ g: CGGradient, startCenter: CGPoint, startRadius: CGFloat, endCenter: CGPoint, endRadius: CGFloat, options: CGGradientDrawingOptions) {}
    public func drawLinearGradient(_ g: CGGradient, start: CGPoint, end: CGPoint, options: CGGradientDrawingOptions) {}
    public func setFillColor(_ c: CGColor) {}
    public func setStrokeColor(_ c: CGColor) {}
    public func setLineWidth(_ w: CGFloat) {}
    public func fillEllipse(in: CGRect) {}
    public func strokeEllipse(in: CGRect) {}
    public func addEllipse(in: CGRect) {}
    public func strokePath() {}
    public func clip() {}
    public func setBlendMode(_ m: CGBlendMode) {}
    public func concatenate(_ t: CGAffineTransform) {}
}
public enum CGBlendMode { case normal, multiply, destinationOut, sourceAtop, clear, copy }
public struct CALayerContentsGravity { public static let resize = CALayerContentsGravity(), resizeAspect = CALayerContentsGravity(), center = CALayerContentsGravity() }
open class CALayer {
    public init() {}
    public var frame = CGRect.zero, bounds = CGRect.zero
    public var position = CGPoint.zero, anchorPoint = CGPoint.zero
    public var zPosition: CGFloat = 0, contentsScale: CGFloat = 1, cornerRadius: CGFloat = 0
    public var isHidden = false, isOpaque = false, masksToBounds = false
    public var opacity: Float = 1
    public var contents: Any?
    public var contentsGravity = CALayerContentsGravity.resize
    public var mask: CALayer?
    public var backgroundColor: CGColor?
    public var sublayers: [CALayer]?
    public var name: String?
    public func addSublayer(_ l: CALayer) {}
    public func insertSublayer(_ l: CALayer, at: UInt32) {}
    public func insertSublayer(_ l: CALayer, above sibling: CALayer?) {}
    public func removeFromSuperlayer() {}
    public func setAffineTransform(_ t: CGAffineTransform) {}
    public func affineTransform() -> CGAffineTransform { .identity }
}
public struct CAShapeLayerLineCap { public static let butt = CAShapeLayerLineCap(), round = CAShapeLayerLineCap(), square = CAShapeLayerLineCap() }
public struct CAShapeLayerLineJoin { public static let miter = CAShapeLayerLineJoin(), round = CAShapeLayerLineJoin(), bevel = CAShapeLayerLineJoin() }
public struct CAShapeLayerFillRule { public static let nonZero = CAShapeLayerFillRule(), evenOdd = CAShapeLayerFillRule() }
public final class CAShapeLayer: CALayer {
    public var path: CGPath?
    public var fillColor: CGColor?, strokeColor: CGColor?
    public var lineWidth: CGFloat = 1
    public var lineCap = CAShapeLayerLineCap.butt
    public var lineJoin = CAShapeLayerLineJoin.miter
    public var fillRule = CAShapeLayerFillRule.nonZero
}
public struct CAGradientLayerType { public static let axial = CAGradientLayerType(), radial = CAGradientLayerType() }
public final class CAGradientLayer: CALayer {
    public var colors: [Any]?
    public var locations: [NSNumber]?
    public var startPoint = CGPoint.zero, endPoint = CGPoint.zero
    public var type = CAGradientLayerType.axial
}
public struct CAMediaTimingFunctionName { public static let easeInEaseOut = CAMediaTimingFunctionName(), linear = CAMediaTimingFunctionName(), easeOut = CAMediaTimingFunctionName() }
public final class CAMediaTimingFunction { public init(name: CAMediaTimingFunctionName) {} }
public enum CATransaction {
    public static func begin() {}
    public static func commit() {}
    public static func setDisableActions(_ b: Bool) {}
    public static func setAnimationDuration(_ d: CFTimeInterval) {}
    public static func setAnimationTimingFunction(_ f: CAMediaTimingFunction?) {}
}
public struct Selector { public init(_ s: String) {} }
public struct CAFrameRateRange { public init(minimum: Float, maximum: Float, preferred: Float) {} }
public final class CADisplayLink {
    public init(target: Any, selector: Selector) {}
    public var preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 120, preferred: 120)
    public var timestamp: CFTimeInterval { 0 }
    public var targetTimestamp: CFTimeInterval { 0 }
    public func add(to: RunLoop, forMode: RunLoop.Mode) {}
    public func invalidate() {}
}
public struct UIEdgeInsets { public var top: CGFloat = 0, left: CGFloat = 0, bottom: CGFloat = 0, right: CGFloat = 0 }
public final class UIWindow { public var screen: UIScreen { .main } }
public final class UIImage {
    public init?(named: String) {}
    public init(cgImage: CGImage) {}
    public var cgImage: CGImage? { nil }
    public var size: CGSize { .zero }
    public var scale: CGFloat { 1 }
}
public final class UITouch: Hashable {
    public static func == (a: UITouch, b: UITouch) -> Bool { a === b }
    public func hash(into h: inout Hasher) {}
    public func location(in v: UIView?) -> CGPoint { .zero }
    public func previousLocation(in v: UIView?) -> CGPoint { .zero }
    public var timestamp: TimeInterval { 0 }
    public var majorRadius: CGFloat { 0 }
    public var force: CGFloat { 0 }
    public var maximumPossibleForce: CGFloat { 0 }
}
public final class UIEvent {
    public func coalescedTouches(for t: UITouch) -> [UITouch]? { nil }
    public func predictedTouches(for t: UITouch) -> [UITouch]? { nil }
}
public struct UIAccessibilityTraits: OptionSet { public let rawValue: UInt64; public init(rawValue: UInt64) { self.rawValue = rawValue }; public static let allowsDirectInteraction = UIAccessibilityTraits(rawValue: 1), button = UIAccessibilityTraits(rawValue: 2) }
public final class UIAccessibilityCustomAction { public init(name: String, actionHandler: @escaping (UIAccessibilityCustomAction) -> Bool) {} }
open class UIView {
    public init(frame: CGRect) {}
    public required init?(coder: NSCoder) {}
    public var layer: CALayer { CALayer() }
    public var bounds = CGRect.zero, frame = CGRect.zero
    public var window: UIWindow? { nil }
    public var safeAreaInsets: UIEdgeInsets { UIEdgeInsets() }
    public var isMultipleTouchEnabled = false, isOpaque = true, isAccessibilityElement = false
    public var backgroundColor: UIColor?
    public var accessibilityLabel: String?
    public var accessibilityTraits: UIAccessibilityTraits = []
    public var accessibilityCustomActions: [UIAccessibilityCustomAction]?
    open func layoutSubviews() {}
    open func didMoveToWindow() {}
    open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {}
    open func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {}
    open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {}
    open func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {}
    public func setNeedsLayout() {}
}
public final class UIGraphicsImageRendererFormat { public init() {}; public var scale: CGFloat = 1; public var opaque = false }
public final class UIGraphicsImageRendererContext { public var cgContext: CGContext { fatalError() } }
public final class UIGraphicsImageRenderer {
    public init(size: CGSize, format: UIGraphicsImageRendererFormat) {}
    public init(size: CGSize) {}
    public func image(actions: (UIGraphicsImageRendererContext) -> Void) -> UIImage { fatalError() }
}
