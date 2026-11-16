import SwiftUI

@main
struct DSHApp: App {
    @StateObject private var store = HostStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .tint(Theme.accent)
        }
    }
}
