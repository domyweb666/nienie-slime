// A stand-in for the part of SwiftUI the app's views use, so their own logic can be type-checked on Linux. Nothing runs.
@_exported import Foundation
@_exported import UIKit

// MARK: data flow
public final class ObservableObjectPublisher { public init() {}; public func send() {} }
public protocol ObservableObject: AnyObject {}
extension ObservableObject { public var objectWillChange: ObservableObjectPublisher { ObservableObjectPublisher() } }
@propertyWrapper public struct Published<Value> {
    public var wrappedValue: Value
    public init(wrappedValue: Value) { self.wrappedValue = wrappedValue }
    public var projectedValue: Int { 0 }
}
@propertyWrapper @dynamicMemberLookup public struct Binding<Value> {
    public var wrappedValue: Value { get { fatalError() } nonmutating set {} }
    public var projectedValue: Binding<Value> { self }
    public init(get: @escaping () -> Value, set: @escaping (Value) -> Void) {}
    public static func constant(_ v: Value) -> Binding<Value> { fatalError() }
    public subscript<T>(dynamicMember kp: WritableKeyPath<Value, T>) -> Binding<T> { fatalError() }
}
@propertyWrapper public struct State<Value> {
    public init(wrappedValue: Value) {}
    public init(initialValue: Value) {}
    public var wrappedValue: Value { get { fatalError() } nonmutating set {} }
    public var projectedValue: Binding<Value> { fatalError() }
}
@propertyWrapper public struct FocusState<Value: Hashable> {
    public init() where Value == Bool {}
    public var wrappedValue: Value { get { fatalError() } nonmutating set {} }
    public struct Binding {}
    public var projectedValue: Binding { Binding() }
}
@propertyWrapper public struct EnvironmentObject<ObjectType: ObservableObject> {
    public init() {}
    public var wrappedValue: ObjectType { fatalError() }
    @dynamicMemberLookup public struct Wrapper {
        public subscript<T>(dynamicMember kp: ReferenceWritableKeyPath<ObjectType, T>) -> SwiftUI.Binding<T> { fatalError() }
    }
    public var projectedValue: Wrapper { Wrapper() }
}
@propertyWrapper public struct ObservedObject<ObjectType: ObservableObject> {
    public init(wrappedValue: ObjectType) {}
    public var wrappedValue: ObjectType { fatalError() }
}
@propertyWrapper public struct StateObject<ObjectType: ObservableObject> {
    public init(wrappedValue: @autoclosure @escaping () -> ObjectType) {}
    public var wrappedValue: ObjectType { fatalError() }
}

// MARK: views
public protocol View { associatedtype Body: View; @ViewBuilder var body: Body { get } }
extension Never: View { public var body: Never { fatalError() } }
extension Optional: View where Wrapped: View { public var body: Never { fatalError() } }
public struct EmptyView: View { public init() {}; public var body: Never { fatalError() } }
public struct TupleView<T>: View { public init(_ t: T) {}; public var body: Never { fatalError() } }
public struct _ConditionalContent<A: View, B: View>: View { public var body: Never { fatalError() } }
@resultBuilder public struct ViewBuilder {
    public static func buildBlock() -> EmptyView { EmptyView() }
    public static func buildBlock<C: View>(_ c: C) -> C { c }
    public static func buildBlock<each C: View>(_ c: repeat each C) -> TupleView<(repeat each C)> { TupleView((repeat each c)) }
    public static func buildIf<C: View>(_ c: C?) -> C? { c }
    public static func buildEither<A: View, B: View>(first: A) -> _ConditionalContent<A, B> { fatalError() }
    public static func buildEither<A: View, B: View>(second: B) -> _ConditionalContent<A, B> { fatalError() }
    public static func buildExpression<C: View>(_ c: C) -> C { c }
}
public protocol ShapeStyle {}
public struct Color: ShapeStyle, View, Hashable {
    public init(red: Double, green: Double, blue: Double) {}
    public init(white: Double) {}
    public init(uiColor: UIColor) {}
    public static let white = Color(white: 1), black = Color(white: 0), clear = Color(white: 0)
    public var body: Never { fatalError() }
}
extension ShapeStyle where Self == Color { public static var white: Color { .white }; public static var black: Color { .black }; public static var clear: Color { .clear } }
public struct Font {
    public enum Weight { case ultraLight, thin, light, regular, medium, semibold, bold, heavy, black }
    public enum Design { case `default`, rounded, monospaced, serif }
    public static func system(size: CGFloat, weight: Weight? = nil, design: Design? = nil) -> Font { Font() }
}
public struct Text: View {
    public init(_ s: String) {}
    public var body: Never { fatalError() }
    public func font(_ f: Font?) -> Text { self }
    public func foregroundStyle<S: ShapeStyle>(_ s: S) -> Text { self }
    public func tracking(_ t: CGFloat) -> Text { self }
}
public struct Image: View { public init(systemName: String) {}; public var body: Never { fatalError() } }
public struct Spacer: View { public init(minLength: CGFloat? = nil) {}; public var body: Never { fatalError() } }
public enum HorizontalAlignment { case leading, center, trailing }
public struct VerticalAlignment { public static let top = VerticalAlignment(), center = VerticalAlignment(), bottom = VerticalAlignment(), firstTextBaseline = VerticalAlignment() }
public struct Alignment { public static let leading = Alignment(), center = Alignment(), trailing = Alignment(), top = Alignment(), bottom = Alignment() }
public struct VStack<C: View>: View { public init(alignment: HorizontalAlignment = .center, spacing: CGFloat? = nil, @ViewBuilder content: () -> C) {}; public var body: Never { fatalError() } }
public struct HStack<C: View>: View { public init(alignment: VerticalAlignment = .center, spacing: CGFloat? = nil, @ViewBuilder content: () -> C) {}; public var body: Never { fatalError() } }
public struct ZStack<C: View>: View { public init(alignment: Alignment = .center, @ViewBuilder content: () -> C) {}; public var body: Never { fatalError() } }
public struct GridItem {
    public enum Size { case fixed(CGFloat), flexible(minimum: CGFloat = 10, maximum: CGFloat = .infinity) }
    public init(_ size: Size = .flexible(), spacing: CGFloat? = nil, alignment: Alignment? = nil) {}
}
public struct LazyVGrid<C: View>: View { public init(columns: [GridItem], alignment: HorizontalAlignment = .center, spacing: CGFloat? = nil, @ViewBuilder content: () -> C) {}; public var body: Never { fatalError() } }
public struct Group<C: View>: View { public init(@ViewBuilder content: () -> C) {}; public var body: Never { fatalError() } }
public struct Axis { public struct Set: OptionSet { public let rawValue: Int; public init(rawValue: Int) { self.rawValue = rawValue }; public static let horizontal = Set(rawValue: 1), vertical = Set(rawValue: 2) } }
public struct ScrollView<C: View>: View { public init(_ axes: Axis.Set = .vertical, showsIndicators: Bool = true, @ViewBuilder content: () -> C) {}; public var body: Never { fatalError() } }
public struct ForEach<Data, ID, C: View>: View {
    public var body: Never { fatalError() }
    public init(_ data: Data, @ViewBuilder content: @escaping (Data.Element) -> C) where Data: RandomAccessCollection, Data.Element: Identifiable, ID == Data.Element.ID {}
    public init(_ data: Data, id: KeyPath<Data.Element, ID>, @ViewBuilder content: @escaping (Data.Element) -> C) where Data: RandomAccessCollection, ID: Hashable {}
}
public struct Button<Label: View>: View {
    public var body: Never { fatalError() }
    public init(action: @escaping () -> Void, @ViewBuilder label: () -> Label) {}
    public init(_ title: String, action: @escaping () -> Void) where Label == Text {}
}
public struct Slider: View { public init(value: Binding<Double>, in r: ClosedRange<Double>, step: Double) {}; public var body: Never { fatalError() } }
public struct Toggle<Label: View>: View { public init(isOn: Binding<Bool>, @ViewBuilder label: () -> Label) {}; public var body: Never { fatalError() } }
public struct TextField: View { public init(_ title: String, text: Binding<String>) {}; public var body: Never { fatalError() } }
public struct DisclosureGroup<Label: View, C: View>: View { public init(isExpanded: Binding<Bool>, @ViewBuilder content: @escaping () -> C, @ViewBuilder label: () -> Label) {}; public var body: Never { fatalError() } }
public struct Picker<C: View>: View { public init<V: Hashable>(_ title: String, selection: Binding<V>, @ViewBuilder content: () -> C) {}; public var body: Never { fatalError() } }
public protocol Shape: View {}
extension Shape {
    public func fill<S: ShapeStyle>(_ s: S) -> some View { EmptyView() }
    public func stroke<S: ShapeStyle>(_ s: S, lineWidth: CGFloat = 1) -> some View { EmptyView() }
}
public struct Capsule: Shape { public init() {}; public var body: Never { fatalError() } }
public struct Circle: Shape { public init() {}; public var body: Never { fatalError() } }
public struct Rectangle: Shape { public init() {}; public var body: Never { fatalError() } }
public struct RoundedRectangle: Shape { public init(cornerRadius: CGFloat) {}; public var body: Never { fatalError() } }

// MARK: styles, small types
public struct ButtonStyleConfiguration { public struct Label: View { public var body: Never { fatalError() } }; public let label: Label; public let isPressed: Bool }
public protocol ButtonStyle { associatedtype Body: View; @ViewBuilder func makeBody(configuration: Configuration) -> Body; typealias Configuration = ButtonStyleConfiguration }
public protocol PrimitiveButtonStyle {}
public struct PlainButtonStyle: PrimitiveButtonStyle { public init() {} }
extension PrimitiveButtonStyle where Self == PlainButtonStyle { public static var plain: PlainButtonStyle { PlainButtonStyle() } }
public protocol TextFieldStyle {}
public struct RoundedBorderTextFieldStyle: TextFieldStyle { public init() {} }
extension TextFieldStyle where Self == RoundedBorderTextFieldStyle { public static var roundedBorder: RoundedBorderTextFieldStyle { RoundedBorderTextFieldStyle() } }
public struct Edge { public struct Set: OptionSet { public let rawValue: Int; public init(rawValue: Int) { self.rawValue = rawValue }
    public static let top = Set(rawValue: 1), bottom = Set(rawValue: 2), leading = Set(rawValue: 4), trailing = Set(rawValue: 8), horizontal = Set(rawValue: 12), vertical = Set(rawValue: 3), all = Set(rawValue: 15) } }
public struct AccessibilityTraits: OptionSet { public let rawValue: Int; public init(rawValue: Int) { self.rawValue = rawValue }; public static let isHeader = AccessibilityTraits(rawValue: 1), isSelected = AccessibilityTraits(rawValue: 2), isButton = AccessibilityTraits(rawValue: 4) }
public enum AccessibilityChildBehavior { case contain, combine, ignore }
public struct AnyTransition { public static let opacity = AnyTransition() }
public struct Animation { public static let `default` = Animation(); public static func easeOut(duration: Double) -> Animation { Animation() } }
public func withAnimation<R>(_ a: Animation? = .default, _ body: () throws -> R) rethrows -> R { try body() }
public enum SubmitLabel { case done, go, send, search, next }
public protocol TextSelectability {}
public struct EnabledTextSelectability: TextSelectability {}
extension TextSelectability where Self == EnabledTextSelectability { public static var enabled: EnabledTextSelectability { EnabledTextSelectability() } }

// MARK: modifiers (each returns the view itself, opaquely)
extension View {
    public func font(_ f: Font?) -> some View { self }
    public func foregroundStyle<S: ShapeStyle>(_ s: S) -> some View { self }
    public func padding(_ edges: Edge.Set = .all, _ length: CGFloat? = nil) -> some View { self }
    public func padding(_ length: CGFloat) -> some View { self }
    public func frame(width: CGFloat? = nil, height: CGFloat? = nil, alignment: Alignment = .center) -> some View { self }
    public func frame(minWidth: CGFloat? = nil, idealWidth: CGFloat? = nil, maxWidth: CGFloat? = nil, minHeight: CGFloat? = nil, idealHeight: CGFloat? = nil, maxHeight: CGFloat? = nil, alignment: Alignment = .center) -> some View { self }
    public func background<V: View>(_ v: V) -> some View { self }
    public func overlay<V: View>(_ v: V) -> some View { self }
    public func buttonStyle<S: ButtonStyle>(_ s: S) -> some View { self }
    public func buttonStyle<S: PrimitiveButtonStyle>(_ s: S) -> some View { self }
    public func textFieldStyle<S: TextFieldStyle>(_ s: S) -> some View { self }
    public func disabled(_ d: Bool) -> some View { self }
    public func opacity(_ o: Double) -> some View { self }
    public func scaleEffect(_ s: CGFloat) -> some View { self }
    public func tint(_ c: Color?) -> some View { self }
    public func lineLimit(_ n: Int?) -> some View { self }
    public func fixedSize(horizontal: Bool, vertical: Bool) -> some View { self }
    public func textSelection<S: TextSelectability>(_ s: S) -> some View { self }
    public func transition(_ t: AnyTransition) -> some View { self }
    public func allowsHitTesting(_ b: Bool) -> some View { self }
    public func ignoresSafeArea() -> some View { self }
    public func contentShape<S: Shape>(_ s: S) -> some View { self }
    public func onLongPressGesture(minimumDuration: Double = 0.5, perform: @escaping () -> Void) -> some View { self }
    public func accessibilityLabel(_ s: String) -> some View { self }
    public func accessibilityValue(_ s: String) -> some View { self }
    public func accessibilityHint(_ s: String) -> some View { self }
    public func accessibilityAddTraits(_ t: AccessibilityTraits) -> some View { self }
    public func accessibilityAction(named: String, _ handler: @escaping () -> Void) -> some View { self }
    public func accessibilityElement(children: AccessibilityChildBehavior = .ignore) -> some View { self }
    public func alert<A: View, M: View>(_ title: String, isPresented: Binding<Bool>, @ViewBuilder actions: () -> A, @ViewBuilder message: () -> M) -> some View { self }
    public func task(_ action: @escaping @Sendable () async -> Void) -> some View { self }
    public func contextMenu<M: View>(@ViewBuilder menuItems: () -> M) -> some View { self }
    public func onChange<V: Equatable>(of value: V, initial: Bool = false, _ action: @escaping (V, V) -> Void) -> some View { self }
    public func tag<V: Hashable>(_ t: V) -> some View { self }
    public func focused(_ b: FocusState<Bool>.Binding) -> some View { self }
    public func submitLabel(_ l: SubmitLabel) -> some View { self }
    public func onSubmit(_ action: @escaping () -> Void) -> some View { self }
    public func environmentObject<T: ObservableObject>(_ o: T) -> some View { self }
}
