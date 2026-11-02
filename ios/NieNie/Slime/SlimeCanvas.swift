import SwiftUI

/// SwiftUI wrapper around the UIKit slime view (UIKit gives us raw multi-touch,
/// coalesced and predicted touches, and a 120Hz display link).
struct SlimeCanvas: UIViewRepresentable {
    @ObservedObject var controller: SlimeController

    final class Coordinator {
        var slime: SlimeKind?   // v2.23: the colours follow the chosen slime
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> SlimeView {
        let view = SlimeView(rig: controller.rig, colors: controller.slime.colors)
        let controller = self.controller
        view.onFrame = { [weak controller] dt in controller?.frame(dt: dt) }
        view.onStats = { [weak controller] s in controller?.report(s) }
        view.latencyTest = controller.latencyTest
        context.coordinator.slime = controller.slime
        return view
    }

    func updateUIView(_ view: SlimeView, context: Context) {
        if context.coordinator.slime != controller.slime {
            context.coordinator.slime = controller.slime
            view.colors = controller.slime.colors
        }
        if view.latencyTest != controller.latencyTest {
            view.latencyTest = controller.latencyTest
        }
    }
}
