import SwiftUI
import Foundation

struct ChatView: View {
    let sessionID: UUID

    @EnvironmentObject private var demo: DemoStore
    @State private var draft = ""
    @FocusState private var composerFocused: Bool

    private var session: ChatSession? { demo.session(sessionID) }
    private var messages: [ChatMessage] { demo.messages(for: sessionID) }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    if messages.isEmpty {
                        EmptyHint(text: "说一句话，它就开始干活。")
                            .padding(.top, 40)
                    }

                    ForEach(messages) { message in
                        MessageRow(message: message)
                            .id(message.id)
                    }

                    Color.clear
                        .frame(height: 1)
                        .id("bottom")
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 8)
            }
            .scrollIndicators(.hidden)
            .defaultScrollAnchor(.bottom)
            .onChange(of: messages.count) { _, _ in
                withAnimation(Motion.gentle) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
        }
        .background(Theme.ink.ignoresSafeArea())
        .navigationTitle(session?.title ?? "会话")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 6) {
                    Text(session?.title ?? "会话")
                        .font(.system(size: 16, weight: .semibold))
                        .lineLimit(1)
                    if session?.isRunning == true {
                        StatusDot()
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) { composer }
        .sheet(item: $demo.approval) { request in
            ApprovalSheet(request: request)
                .environmentObject(demo)
        }
    }

    // MARK: - Composer

    private var composer: some View {
        HStack(alignment: .bottom, spacing: 10) {
            Button {
                Haptics.tap()
            } label: {
                Image(systemName: "paperclip")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.75))
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.plain)

            TextField("说点什么…", text: $draft, axis: .vertical)
                .lineLimit(1...5)
                .focused($composerFocused)
                .textFieldStyle(.plain)
                .foregroundStyle(.white)
                .tint(Theme.accent)
                .padding(.vertical, 6)

            Button(action: send) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(
                        Circle().fill(
                            draft.trimmingCharacters(in: .whitespaces).isEmpty
                                ? Color.white.opacity(0.12)
                                : Theme.accent
                        )
                    )
            }
            .buttonStyle(.plain)
            .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
            .animation(Motion.snappy, value: draft.isEmpty)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .ncnsGlass(
            cornerRadius: 26,
            tint: composerFocused ? Theme.accent.opacity(0.22) : nil,
            interactive: true
        )
        .padding(.horizontal, 14)
        .padding(.bottom, 8)
        .padding(.top, 4)
    }

    private func send() {
        let text = draft
        draft = ""
        Haptics.soft()
        demo.send(text, in: sessionID)
    }
}

// MARK: - Message

private struct MessageRow: View {
    let message: ChatMessage

    var body: some View {
        if message.role == .user {
            HStack {
                Spacer(minLength: 56)
                Text(message.text)
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(
                        Theme.accent.opacity(0.18),
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )
                    .textSelection(.enabled)
            }
        } else {
            VStack(alignment: .leading, spacing: 12) {
                if message.text.isEmpty {
                    ShimmerLine(color: Theme.mint)
                        .frame(width: 120)
                } else {
                    Text(message.text)
                        .font(.system(size: 15))
                        .lineSpacing(5)
                        .foregroundStyle(.white.opacity(0.94))
                        .textSelection(.enabled)
                }

                ForEach(message.tools) { tool in
                    ToolRow(tool: tool)
                }

                if message.isStreaming {
                    ShimmerLine(color: Theme.mint)
                        .frame(width: 84)
                        .opacity(0.8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Tool

private struct ToolRow: View {
    let tool: ToolRun

    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(Motion.snappy) { expanded.toggle() }
                Haptics.soft()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(color)
                        .frame(width: 22, height: 22)
                        .background(color.opacity(0.14), in: RoundedRectangle(cornerRadius: 7, style: .continuous))

                    VStack(alignment: .leading, spacing: 1) {
                        Text(tool.name)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.92))
                        Text(tool.detail)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(Theme.muted)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 8)

                    Text(statusText)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(color)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Theme.dim)
                        .rotationEffect(.degrees(expanded ? 180 : 0))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if expanded {
                Text(tool.output.isEmpty ? "（还没有输出）" : tool.output)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.72))
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(Theme.raised, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(alignment: .top) {
            if tool.status == .running {
                ShimmerLine()
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }

    private var icon: String {
        switch tool.status {
        case .running: return "bolt.fill"
        case .done: return "checkmark"
        case .failed: return "xmark"
        }
    }

    private var color: Color {
        switch tool.status {
        case .running: return Theme.mint
        case .done: return Color.white.opacity(0.6)
        case .failed: return Color(hex: 0xFF6B6B)
        }
    }

    private var statusText: String {
        switch tool.status {
        case .running: return "运行中"
        case .done: return String(format: "%.1fs", tool.seconds)
        case .failed: return "失败"
        }
    }
}

// MARK: - Approval

struct ApprovalSheet: View {
    let request: ApprovalRequest

    @EnvironmentObject private var demo: DemoStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Capsule()
                .fill(Color.white.opacity(0.22))
                .frame(width: 36, height: 5)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 4)

            Text(request.title)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(request.detail)
                .font(.system(size: 14))
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)

            Text(request.command)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.white.opacity(0.9))
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            Spacer(minLength: 0)

            HStack(spacing: 10) {
                Button("拒绝") {
                    demo.deny()
                    dismiss()
                }
                .buttonStyle(.ncnsGlass)

                Button("允许") {
                    demo.approve()
                    dismiss()
                }
                .buttonStyle(.ncnsProminent)
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(hex: 0x141420))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .padding(10)
        .presentationDetents([.height(320)])
        .presentationBackground(.clear)
        .presentationDragIndicator(.hidden)
    }
}
