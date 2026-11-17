import SwiftUI

struct ConnectView: View {
    @EnvironmentObject private var store: HostStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
        ZStack {
            backdrop

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    fields
                    actions
                    recents
                    footer
                }
                .padding(.horizontal, 22)
                .padding(.top, 40)
                .padding(.bottom, 48)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(Theme.ink.ignoresSafeArea())
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

    // MARK: - Backdrop

    private var backdrop: some View {
        ZStack {
            Theme.ink

            if reduceMotion {
                RadialGradient(
                    colors: [Theme.accent.opacity(0.34), Color.clear],
                    center: .top,
                    startRadius: 0,
                    endRadius: 420
                )
            } else {
                TimelineView(.animation) { context in
                    let time = context.date.timeIntervalSinceReferenceDate
                    let x = 0.5 + 0.12 * sin(time / 9)
                    let y = 0.24 + 0.06 * cos(time / 11)

                    ZStack {
                        RadialGradient(
                            colors: [Theme.accent.opacity(0.40), Color.clear],
                            center: UnitPoint(x: x, y: y),
                            startRadius: 0,
                            endRadius: 430
                        )
                        RadialGradient(
                            colors: [Theme.mint.opacity(0.20), Color.clear],
                            center: UnitPoint(x: 1 - x, y: 0.82),
                            startRadius: 0,
                            endRadius: 380
                        )
                    }
                }
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Theme.markGradient)
                .frame(width: 68, height: 68)
                .overlay(
                    Text(">_")
                        .font(.system(size: 27, weight: .heavy, design: .monospaced))
                        .foregroundStyle(.white)
                )
                .shadow(color: Theme.accent.opacity(0.45), radius: 22, y: 10)

            Text("NcnsDSH")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("把手机接到那台正在跑 `dsh web` 的电脑。\n会话、工具和审批都在它那里执行。")
                .font(.system(size: 15))
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var fields: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text("地址")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.muted)
                    .textCase(.uppercase)
                    .tracking(1.2)
                TextField("192.168.1.8:3080", text: $address)
                    .textContentType(.URL)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.next)
                    .onSubmit { focused = .token }
                    .focused($focused, equals: .address)
                    .font(.system(size: 16, design: .monospaced))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            Divider().overlay(Theme.hairline)

            VStack(alignment: .leading, spacing: 6) {
                Text("Token")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.muted)
                    .textCase(.uppercase)
                    .tracking(1.2)

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
                    .submitLabel(.go)
                    .onSubmit(connect)
                    .focused($focused, equals: .token)
                    .font(.system(size: 16, design: .monospaced))
                    .foregroundStyle(.white)

                    Button {
                        revealToken.toggle()
                    } label: {
                        Image(systemName: revealToken ? "eye.slash" : "eye")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.muted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .ncnsGlass(cornerRadius: 22, interactive: true)

        .overlay(alignment: .bottomLeading) {
            if let error = store.lastError {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: 0xFFB86B))
                    .padding(.horizontal, 6)
                    .offset(y: 26)
            }
        }
        .padding(.bottom, store.lastError == nil ? 0 : 24)
    }

    private var actions: some View {
        VStack(spacing: 10) {
            Button(action: connect) {
                Text("连接")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.ncnsProminent)
            .disabled(address.trimmingCharacters(in: .whitespaces).isEmpty)

            Button {
                Haptics.tap()
                scanning = true
            } label: {
                Label("扫描二维码", systemImage: "qrcode.viewfinder")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.ncnsGlass)

            Button {
                address = "http://127.0.0.1:3080"
                focused = .token
            } label: {
                Text("填入本机 3080")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.dim)
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
        }
    }

    @ViewBuilder
    private var recents: some View {
        if !store.hosts.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("最近")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.muted)
                    .textCase(.uppercase)
                    .tracking(1.2)

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
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Theme.artwork(host.displayName.count))
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Image(systemName: "desktopcomputer")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(.white.opacity(0.9))
                                    )

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(host.displayName)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(.white)
                                        .lineLimit(1)
                                    Text(host.originText)
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundStyle(Theme.muted)
                                        .lineLimit(1)
                                }

                                Spacer(minLength: 8)

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(Theme.dim)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 11)
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
                            Divider().overlay(Theme.hairline).padding(.leading, 62)
                        }
                    }
                }
                .ncnsGlass(cornerRadius: 20)
            }
        }
    }

    private var footer: some View {
        Text("在电脑上运行 `dsh web --host <局域网地址>`，把打印出来的地址填进来；带 `?token=` 的地址会自动拆出 token。token 是一次性的，换过登录 cookie 之后就不再需要它。")
            .font(.system(size: 12))
            .foregroundStyle(Theme.dim)
            .fixedSize(horizontal: false, vertical: true)
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
                focused = .token
            } else {
                connect()
            }
        }
    }
}

#Preview {
    ConnectView().environmentObject(HostStore())
}
