import SwiftUI
import WebKit

struct SettingsView: View {
    let host: Host

    @EnvironmentObject private var store: HostStore
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var confirmingForget = false

    init(host: Host) {
        self.host = host
        _name = State(initialValue: host.displayName)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("这台宿主") {
                    LabeledContent("地址", value: host.originText)
                    LabeledContent("Token", value: "••••••••")
                    TextField("名称", text: $name)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section("网页") {
                    Button {
                        if let url = URL(string: host.originText) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("在 Safari 打开", systemImage: "safari")
                    }

                    Button {
                        clearCache()
                    } label: {
                        Label("清除网页缓存", systemImage: "trash")
                    }
                }

                Section {
                    Button(role: .destructive) {
                        store.disconnect()
                        dismiss()
                    } label: {
                        Label("断开连接", systemImage: "rectangle.portrait.and.arrow.right")
                    }

                    Button(role: .destructive) {
                        confirmingForget = true
                    } label: {
                        Label("移除这台宿主", systemImage: "minus.circle")
                    }
                } footer: {
                    Text("移除后这台宿主的 token 会从钥匙串删除，下次需要重新扫码。")
                }

                Section {
                    LabeledContent("版本", value: Bundle.main.appVersion)
                } footer: {
                    Text("DSH 0.1 · 原生壳加载 `dsh web`，会话、工具和审批都由宿主执行。")
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        save()
                        dismiss()
                    }
                }
            }
            .confirmationDialog("移除 \(host.displayName)？", isPresented: $confirmingForget, titleVisibility: .visible) {
                Button("移除", role: .destructive) {
                    store.forget(host)
                    dismiss()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("只删除这台设备上保存的连接信息，宿主的会话和文件都不受影响。")
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty, trimmed != host.name {
            store.rename(host, to: trimmed)
        }
    }

    private func clearCache() {
        let store = WKWebsiteDataStore.default()
        store.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), modifiedSince: .distantPast) {
            Haptics.success()
        }
    }
}

extension Bundle {
    var appVersion: String {
        let short = infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "0"
        return "\(short) (\(build))"
    }
}
