import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: HostStore

    var body: some View {
        Group {
            if let host = store.current {
                WebScreen(host: host)
                    .id(host.id)
            } else {
                ConnectView()
            }
        }
        .animation(.easeInOut(duration: 0.22), value: store.current?.id)
    }
}

#Preview {
    RootView()
        .environmentObject(HostStore())
}
