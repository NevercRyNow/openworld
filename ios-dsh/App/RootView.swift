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
        .onOpenURL { url in
            guard url.scheme == "dsh" else { return }
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
    RootView()
        .environmentObject(HostStore())
}
