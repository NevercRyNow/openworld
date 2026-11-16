import SwiftUI

struct ConnectView: View {
    @EnvironmentObject private var store: HostStore

    @State private var address = ""
    @State private var token = ""
    @State private var revealToken = false
    @State private var scanning = false
    @FocusState private var focused: Field?

    private enum Field {
        case address
        case token
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    fields
                    actions
                    recents
                    footer
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)
                .padding(.bottom, 40)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Theme.paper.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $scanning) {
                ScannerView(
                    onCode: { code in
                        scanning = false
                        apply(code)
                    },
                    onCancel: { scanning = false }
                )
                .ignoresSafeArea()
            }
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Theme.markGradient)
                .frame(width: 64, height: 64)
                .overlay(
                    Text(">_")
                        .font(.system(size: 26, weight: .heavy, design: .monospaced))
                        .foregroundStyle(.white)
                )
                .shadow(color: Theme.accent.opacity(0.35), radius: 18, y: 8)

            Text("DSH")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text("DeepSeek Harness，在你的手机上继续。\n连上正在运行的那台电脑，会话、工具和审批都在。")
                .font(.subheadline)
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var fields: some View {
        VStack(spacing: 12) {
            fieldCard {
                VStack(alignment: .leading, spacing: 6) {
                    Text("地址")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.muted)
                    TextField("192.168.1.8:3080", text: $address)
                        .textContentType(.URL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focused, equals: .address)
                        .submitLabel(.next)
                        .onSubmit { focused = .token }
                        .font(.body.monospaced())
                }
            }

            fieldCard {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Token")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.muted)
                    HStack(spacing: 8) {
                        Group {
                            if revealToken {
                                TextField("启动时打印的 token", text: $token)
                            } else {
                                SecureField("启动时打印的 token", text: $token)
                            }
                        }
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focused, equals: .token)
                        .submitLabel(.go)
                        .onSubmit(connect)
                        .font(.body.monospaced())

                        Button {
                            revealToken.toggle()
                        } label: {
                            Image(systemName: revealToken ? "eye.slash" : "eye")
                                .foregroundStyle(Theme.muted)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if let error = store.lastError {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var actions: some View {
        VStack(spacing: 10) {
            Button(action: connect) {
                Text("连接")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.roundedRectangle)
            .disabled(address.trimmingCharacters(in: .whitespaces).isEmpty)

            Button {
                Haptics.tap()
                scanning = true
            } label: {
                Label("扫描二维码", systemImage: "qrcode.viewfinder")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.roundedRectangle)

            Button {
                address = "http://127.0.0.1:3080"
                focused = .token
            } label: {
                Text("填入本机 3080")
                    .font(.footnote)
                    .foregroundStyle(Theme.muted)
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var recents: some View {
        if !store.hosts.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("最近")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.muted)

                VStack(spacing: 0) {
                    ForEach(store.hosts) { host in
                        Button {
                            Haptics.tap()
                            if host.token.isEmpty {
                                address = host.originText
                                token = ""
                                focused = .token
                            } else {
                                store.open(host)
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(Theme.accent.opacity(0.14))
                                    .frame(width: 34, height: 34)
                                    .overlay(
                                        Image(systemName: "desktopcomputer")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundStyle(Theme.accent)
                                    )

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(host.displayName)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                    Text(host.originText)
                                        .font(.caption.monospaced())
                                        .foregroundStyle(Theme.muted)
                                        .lineLimit(1)
                                }

                                Spacer(minLength: 8)

                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 10)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                store.forget(host)
                            } label: {
                                Label("移除", systemImage: "trash")
                            }
                        }

                        if host.id != store.hosts.last?.id {
                            Divider().padding(.leading, 46)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("在电脑上运行 `dsh web`，把打印出来的地址填进来；地址里带 `?token=` 的话，token 会自动识别。局域网连接需要在配置里把 host 设成电脑的局域网地址，并放行防火墙。")
                .font(.caption)
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 6)
    }

    private func fieldCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Actions

    private func connect() {
        focused = nil
        store.connect(address: address, token: token)
    }

    private func apply(_ code: String) {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        if let parsed = HostParser.parse(trimmed) {
            address = parsed.originText
            token = parsed.token
            if parsed.token.isEmpty {
                token = ""
                focused = .token
            } else {
                connect()
            }
        } else if trimmed.contains("token="),
                  let components = URLComponents(string: trimmed.hasPrefix("http") ? trimmed : "http://" + trimmed),
                  let value = components.queryItems?.first(where: { $0.name == "token" })?.value {
            token = value
        }
    }
}

#Preview {
    ConnectView().environmentObject(HostStore())
}
