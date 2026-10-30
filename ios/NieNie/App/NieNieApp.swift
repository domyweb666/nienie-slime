import SwiftUI

@main
struct NieNieApp: App {
    @StateObject private var controller = SlimeController()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(controller)
        }
    }
}
