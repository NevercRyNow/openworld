import SwiftUI
import WebKit

struct WebScreen: View {
    let host: Host

    @EnvironmentObject private var store: HostStore
    @Environment(\.scenePhase) private var scenePhase
    @State private var bridge = WebBridge()
    @State private var progress: Double = 0
    @State private var error: String?
    @State private var canGoBack = false
    @State private var canGoForward = false
    @State private var pageTitle = ""
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                DSHWebView(
                    host: host,
                    bridge: bridge,
                    progress: $progress,
                    error: $error,
                    canGoBack: $canGoBack,
                    canGoForward: $canGoForward,
                    pageTitle: $pageTitle
                )

                if progress > 0.02, progress < 1 {
                    ProgressView(value: min(max(progress, 0), 1))
                        .progressViewStyle(.linear)
                        .tint(Theme.accent)
                        .frame(height: 3)
                }

                if let message = error {
                    ErrorOverlay(
                        message: message,
                        host: host,
                        onRetry: {
                            self.error = nil
                            bridge.reload()
                        },
                        onRepair: repair,
                        onOpenSafari: openInSafari
                    )
                }
            }
            .navigationTitle(pageTitle.isEmpty ? host.displayName : pageTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .onChange(of: scenePhase) { _, phase in
                // Coming back from the background: if the last attempt failed,
                // try once more instead of leaving the user on the error card.
                if phase == .active, error != nil {
                    bridge.reload()
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(host: host)
                    .environmentObject(store)
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            HStack(spacing: 14) {
                Button {
                    Haptics.tap()
                    if canGoBack { bridge.goBack() }
                } label: {
                    Image(systemName: "chevron.left")
                }
                .disabled(!canGoBack)

                Button {
                    Haptics.tap()
                    if canGoForward { bridge.goForward() }
                } label: {
                    Image(systemName: "chevron.right")
                }
                .disabled(!canGoForward)
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button {
                    bridge.reload()
                } label: {
                    Label("刷新", systemImage: "arrow.clockwise")
                }

                Button(action: openInSafari) {
                    Label("在 Safari 打开", systemImage: "safari")
                }

                Button {
                    UIPasteboard.general.string = host.originText
                    Haptics.success()
                } label: {
                    Label("复制地址", systemImage: "doc.on.doc")
                }

                Divider()

                Button {
                    showSettings = true
                } label: {
                    Label("设置", systemImage: "gearshape")
                }

                Button(role: .destructive) {
                    store.disconnect()
                } label: {
                    Label("断开", systemImage: "rectangle.portrait.and.arrow.right")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }

    /// The launch token is exchanged for a cookie once; if the cookie is gone
    /// (cleared data, a restarted host) the stale token cannot log in again, so
    /// pairing has to start over from the connect screen.
    private func repair() {
        let cookies = WKWebsiteDataStore.default()
        cookies.removeData(ofTypes: Set([WKWebsiteDataTypeCookies]), modifiedSince: .distantPast) {
            store.disconnect()
        }
    }

    private func openInSafari() {
        let url = bridge.url ?? host.webURL
        UIApplication.shared.open(url)
    }
}

private struct ErrorOverlay: View {
    let message: String
    let host: Host
    let onRetry: () -> Void
    let onRepair: () -> Void
    let onOpenSafari: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 24)

            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.orange)
                    Text("连不上")
                        .font(.headline)
                }

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(host.originText)
                    .font(.caption.monospaced())
                    .foregroundStyle(.tertiary)

                VStack(spacing: 8) {
                    Button(action: onRetry) {
                        Text("重试")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.roundedRectangle)

                    HStack(spacing: 8) {
                        Button(action: onRepair) {
                            Text("重新配对")
                                .font(.footnote.weight(.medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 9)
                        }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.roundedRectangle)

                        Button(action: onOpenSafari) {
                            Text("在 Safari 打开")
                                .font(.footnote.weight(.medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 9)
                        }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.roundedRectangle)
                    }
                }
            }
            .padding(20)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: .black.opacity(0.12), radius: 24, y: 10)
            .padding(.horizontal, 24)

            Spacer(minLength: 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground).opacity(0.92))
    }
}
