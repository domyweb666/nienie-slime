import SwiftUI

/// SwiftUI wrapper around the UIKit slime view (UIKit gives us raw multi-touch,
/// coalesced and predicted touches, and a 120Hz display link).
struct SlimeCanvas: UIViewRepresentable {
    @ObservedObject var controller: SlimeController

    final class Coordinator {
        var material: SlimeMaterial?
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> SlimeView {
        let view = SlimeView(rig: controller.rig, colors: controller.material.colors)
        let controller = self.controller
        view.onFrame = { [weak controller] dt in controller?.frame(dt: dt) }
        context.coordinator.material = controller.material
        return view
    }

    func updateUIView(_ view: SlimeView, context: Context) {
        if context.coordinator.material != controller.material {
            context.coordinator.material = controller.material
            view.colors = controller.material.colors
        }
    }
}
