import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var demo: DemoStore
    @EnvironmentObject private var store: HostStore

    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    topBar
                    if let hero = demo.heroSession {
                        heroCard(hero)
                    }
                    continueShelf
                    workspaceShelf
                    recentShelf
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
            .background(Theme.ink.ignoresSafeArea())
            .navigationDestination(for: UUID.self) { id in
                ChatView(sessionID: id)
            }
            .safeAreaInset(edge: .bottom) { dock }
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("NcnsDSH")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.muted)
                    .textCase(.uppercase)
                    .tracking(1.4)
                Text("会话")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            Spacer()

            HStack(spacing: 10) {
                if demo.runningCount > 0 {
                    HStack(spacing: 6) {
                        StatusDot()
                        Text("\(demo.runningCount) 个在跑")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .ncnsPill()
                }

                Button {
                    Haptics.tap()
                    demo.newSession()
                    if let id = demo.activeSessionID {
                        path.append(id)
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
                .ncnsPill()
            }
        }
    }

    // MARK: - Hero

    private func heroCard(_ session: ChatSession) -> some View {
        ZStack(alignment: .bottomLeading) {
            ArtworkView(index: session.artworkIndex, initial: session.initial, cornerRadius: 26)
                .frame(height: 320)

            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.10), Color.black.opacity(0.82)],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    StatusDot(color: session.isRunning ? Theme.mint : Color.white.opacity(0.6), pulsing: session.isRunning)
                    Text(session.isRunning ? "正在运行" : "上次活动")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.82))
                    Text("·")
                        .foregroundStyle(.white.opacity(0.4))
                    Text(session.relativeTime)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                }

                Text(session.title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                Text("\(session.workspace) · \(session.preview)")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.68))
                    .lineLimit(2)

                HStack(spacing: 10) {
                    Button("继续") {
                        Haptics.soft()
                        path.append(session.id)
                    }
                    .buttonStyle(.ncnsProminent)

                    Button("新会话") {
                        Haptics.soft()
                        demo.newSession()
                        if let id = demo.activeSessionID {
                            path.append(id)
                        }
                    }
                    .buttonStyle(.ncnsGlass)
                }
                .padding(.top, 4)
            }
            .padding(22)
        }
        .frame(height: 320)
    }

    // MARK: - Shelves

    private var continueShelf: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "继续")

            ScrollView(.horizontal) {
                LazyHStack(spacing: 12) {
                    ForEach(demo.continueSessions) { session in
                        NavigationLink(value: session.id) {
                            continueCard(session)
                        }
                        .buttonStyle(CardPressStyle())
                        .contextMenu {
                            Button {
                                demo.togglePinned(session.id)
                            } label: {
                                Label(session.pinned ? "取消置顶" : "置顶", systemImage: "pin")
                            }
                            Button(role: .destructive) {
                                demo.archive(session.id)
                            } label: {
                                Label("归档", systemImage: "archivebox")
                            }
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
            .scrollIndicators(.hidden)
        }
    }

    private func continueCard(_ session: ChatSession) -> some View {
        ZStack(alignment: .bottomLeading) {
            ArtworkView(index: session.artworkIndex, initial: session.initial, cornerRadius: 20, showsInitial: false)

            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.78)],
                startPoint: .center,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Spacer()
                HStack(spacing: 6) {
                    if session.isRunning {
                        StatusDot()
                    }
                    Text(session.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
                Text(session.workspace)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1)
                if session.isRunning {
                    ProgressLine(progress: session.progress)
                }
            }
            .padding(14)
        }
        .frame(width: 280, height: 180)
    }

    private var workspaceShelf: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "工作区")

            ScrollView(.horizontal) {
                LazyHStack(spacing: 12) {
                    ForEach(demo.workspaces) { workspace in
                        VStack(alignment: .leading, spacing: 0) {
                            ArtworkView(
                                index: workspace.artworkIndex,
                                initial: String(workspace.name.prefix(1)),
                                cornerRadius: 18
                            )
                            .frame(width: 160, height: 200)

                            HStack(spacing: 6) {
                                Text(workspace.name)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                if workspace.running > 0 {
                                    StatusDot()
                                }
                            }
                            .padding(.top, 8)

                            Text("\(workspace.total) 个会话")
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.muted)
                        }
                        .frame(width: 160)
                    }
                }
                .padding(.horizontal, 2)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var recentShelf: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "最近完成")

            VStack(spacing: 0) {
                ForEach(Array(demo.sessions.dropFirst(2).prefix(4))) { session in
                    NavigationLink(value: session.id) {
                        HStack(spacing: 12) {
                            ArtworkView(
                                index: session.artworkIndex,
                                initial: session.initial,
                                cornerRadius: 10,
                                showsInitial: false
                            )
                            .frame(width: 46, height: 46)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(session.title)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                Text("\(session.workspace) · \(session.relativeTime)")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Theme.muted)
                                    .lineLimit(1)
                            }

                            Spacer(minLength: 8)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Theme.dim)
                        }
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if session.id != demo.sessions.dropFirst(2).prefix(4).last?.id {
                        Divider().overlay(Theme.hairline).padding(.leading, 58)
                    }
                }
            }
        }
    }

    // MARK: - Dock

    @ViewBuilder
    private var dock: some View {
        if let running = demo.sessions.first(where: { $0.isRunning }) {
            Button {
                Haptics.soft()
                path.append(running.id)
            } label: {
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Theme.artwork(running.artworkIndex))
                        .frame(width: 30, height: 30)
                        .overlay(
                            Text(running.initial)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.9))
                        )

                    VStack(alignment: .leading, spacing: 1) {
                        Text(running.title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Text("正在工作 · \(Int(running.progress * 100))%")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.muted)
                    }

                    Spacer(minLength: 8)

                    StatusDot()

                    Image(systemName: "chevron.up")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.dim)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .ncnsPill()
                .padding(.horizontal, 16)
                .padding(.bottom, 6)
            }
            .buttonStyle(.plain)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

/// 卡片按下时轻微收缩，配合玻璃高光。
struct CardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.975 : 1)
            .overlay {
                if configuration.isPressed {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                }
            }
            .animation(Motion.snappy, value: configuration.isPressed)
    }
}
