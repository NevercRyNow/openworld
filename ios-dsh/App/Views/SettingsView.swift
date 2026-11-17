import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var store: HostStore
    @EnvironmentObject private var demo: DemoStore

    @State private var showWeb = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    hostCard
                    dataCard
                    webCard
                    aboutCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
            .background(Theme.ink.ignoresSafeArea())
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showWeb) {
            if let host = store.current {
                WebScreen(host: host)
                    .preferredColorScheme(.dark)
            }
        }
    }

    private var hostCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                if store.current != nil {
                    StatusDot()
                    Text("已连接")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                } else {
                    Circle().fill(Color.white.opacity(0.3)).frame(width: 7, height: 7)
                    Text("未连接")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.muted)
                }
                Spacer()
                Text(store.current?.displayName ?? "—")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.muted)
                    .lineLimit(1)
            }

            if let host = store.current {
                Text(host.originText)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(Theme.dim)
                    .lineLimit(1)

                HStack(spacing: 10) {
                    Button("重新配对") {
                        Haptics.soft()
                        store.disconnect()
                    }
                    .buttonStyle(NcnsGlassButtonStyle(compact: true))

                    Button("在 Safari 打开") {
                        if let url = URL(string: host.originText) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .buttonStyle(NcnsGlassButtonStyle(compact: true))
                }
            } else {
                Button("连接宿主") {
                    store.disconnect()
                }
                .buttonStyle(NcnsGlassButtonStyle(compact: true))
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .ncnsGlass(cornerRadius: 22)
    }

    private var dataCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("数据源", systemImage: "cylinder.split.1x2")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                Spacer()
                Text("演示数据")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.mint)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Theme.mint.opacity(0.14), in: Capsule())
            }

            Text("界面和交互已经按最终形态跑通，数据还是本地的 demo。接上 `dsh-plugin-mobile-gateway` 的 WebSocket 之后，这里会显示连接状态与事件吞吐。")
                .font(.system(size: 12))
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var webCard: some View {
        Button {
            Haptics.tap()
            showWeb = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "globe")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 34, height: 34)
                    .background(Theme.accent.opacity(0.14), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text("网页版")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white)
                    Text("插件页、终端、文件预览这些还没原生的功能")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.muted)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Theme.dim)
            }
            .padding(16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .disabled(store.current == nil)
        .opacity(store.current == nil ? 0.5 : 1)
    }

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("NcnsDSH")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
                Text(Bundle.main.appVersion)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(Theme.dim)
            }
            Text("视觉参照 tv 与 Apple Music；玻璃只出现在 chrome 和可交互卡片上，内容区保持不透明，保证对比度。")
                .font(.system(size: 12))
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

extension Bundle {
    var appVersion: String {
        let short = infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "0"
        return "\(short) (\(build))"
    }
}
