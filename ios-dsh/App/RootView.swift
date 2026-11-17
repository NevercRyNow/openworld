import SwiftUI

@MainActor
struct RootView: View {
    @EnvironmentObject private var store: HostStore
    @StateObject private var demo = DemoStore()

    var body: some View {
        Group {
            if store.current == nil {
                ConnectView()
            } else {
                MainShell()
            }
        }
        .environmentObject(demo)
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.24), value: store.current?.id)
        .onOpenURL { url in
            guard let scheme = url.scheme, scheme == "ncnsdsh" || scheme == "dsh" else { return }
            let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
            let target = items?.first(where: { $0.name == "url" })?.value ?? ""
            let token = items?.first(where: { $0.name == "token" })?.value ?? ""
            if !target.isEmpty {
                store.connect(address: target, token: token)
            }
        }
    }
}

#Preview {
    RootView().environmentObject(HostStore())
}
