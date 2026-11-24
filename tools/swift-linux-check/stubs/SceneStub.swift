import UIKit
enum SceneArt {
    struct Images { let sky: UIImage; let wall: UIImage; let props: UIImage; let bowlFront: UIImage; let bell: UIImage?; let teru: UIImage? }
    static func make(kind: Int, size: CGSize, g: SlimeRig.SillGeo, bowl: Bool = false, props oldProps: Bool = false, deco: Int = 1) -> Images? { nil }
    static func tintedWall(_ wall: UIImage, tint: UIColor, key: String) -> UIImage { wall }
    static func sprite(_ kind: String, night: Bool) -> UIImage { fatalError() }
}
