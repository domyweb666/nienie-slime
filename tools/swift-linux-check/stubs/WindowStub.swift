// Stand-ins for WindowScene.swift (v2.59), with the members the controller, the feel desk, SlimeView and JellySkin use.
import Metal
import QuartzCore
import UIKit
struct WindowDef {
    let id: String
    let set: Int
    let name: String
    let line: String
    let only: Bool
    let day: [Double]?
    var said: String { name }
    var dayColor: UIColor? { nil }
}
final class WindowLibrary {
    static let setNames: [String] = []
    static var all: [WindowDef] { [] }
    static func def(_ id: String) -> WindowDef? { nil }
}
final class WindowStage {
    let def: WindowDef
    let night: Bool
    init(def: WindowDef, night: Bool) { self.def = def; self.night = night }
}
final class WindowRenderer {
    enum Request { case ready(WindowStage), waiting, failed(String) }
    let layer = CAMetalLayer()
    init?(device: MTLDevice, queue: MTLCommandQueue) {}
    func request(_ def: WindowDef, night: Bool) -> Request { .waiting }
    func forgetFailures() {}
    func clear() {}
    func place(_ hole: CGRect, scale s: CGFloat) {}
    var settled: Bool { false }
    func draw(_ stage: WindowStage, still: Bool) {}
    func mix(into cmd: MTLCommandBuffer, room: MTLTexture) -> MTLTexture? { nil }
}
