import Foundation
import SwiftUI

/// Demo 数据源：先把视觉和交互跑通。
/// 接真网关时，把 `send` / `approve` 两个口子换成 `MobileGateway` 的 WebSocket 调用即可，
/// 视图层不用动。
@MainActor
final class DemoStore: ObservableObject {
    @Published var demoMode = true
    @Published private(set) var sessions: [ChatSession] = []
    @Published private(set) var workspaces: [Workspace] = []
    @Published private(set) var schedules: [ScheduleItem] = []
    @Published private(set) var messages: [UUID: [ChatMessage]] = [:]
    @Published var approval: ApprovalRequest?
    @Published var activeSessionID: UUID?

    private var streamTask: Task<Void, Never>?

    init() {
        seed()
    }

    // MARK: - Reads

    func messages(for sessionID: UUID) -> [ChatMessage] {
        messages[sessionID] ?? []
    }

    func session(_ id: UUID?) -> ChatSession? {
        guard let id else { return nil }
        return sessions.first { $0.id == id }
    }

    var heroSession: ChatSession? {
        sessions.first { $0.isRunning } ?? sessions.first
    }

    var runningCount: Int {
        sessions.filter(\.isRunning).count
    }

    var continueSessions: [ChatSession] {
        Array(sessions.prefix(6))
    }

    // MARK: - Writes

    func setActive(_ id: UUID?) {
        activeSessionID = id
    }

    func newSession() {
        let session = ChatSession(
            id: UUID(),
            title: "新会话",
            workspace: "default-workspace",
            lastActivity: Date(),
            isRunning: false,
            progress: 0,
            artworkIndex: sessions.count,
            pinned: false,
            preview: "说一句话，它就开始干活。"
        )
        sessions.insert(session, at: 0)
        messages[session.id] = []
        activeSessionID = session.id
    }

    func togglePinned(_ id: UUID) {
        guard let index = sessions.firstIndex(where: { $0.id == id }) else { return }
        sessions[index].pinned.toggle()
        Haptics.soft()
    }

    func archive(_ id: UUID) {
        sessions.removeAll { $0.id == id }
        messages[id] = nil
        Haptics.soft()
    }

    // MARK: - Conversation

    func send(_ text: String, in sessionID: UUID) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        append(
            ChatMessage(id: UUID(), role: .user, text: trimmed, tools: [], isStreaming: false, date: Date()),
            to: sessionID
        )
        bump(sessionID, preview: trimmed, running: true, progress: 0.05)

        let replyID = UUID()
        append(
            ChatMessage(id: replyID, role: .assistant, text: "", tools: [], isStreaming: true, date: Date()),
            to: sessionID
        )

        streamTask?.cancel()
        streamTask = Task { [weak self] in
            guard let self else { return }
            await self.stream(replyID, in: sessionID)
        }
    }

    private func stream(_ messageID: UUID, in sessionID: UUID) async {
        let chunks = [
            "先看一眼工作区。",
            " 读到了 `openworld-site` 和 `ios-dsh` 两个项目，",
            "当前分支是 `main`，" ,
            "没有未提交的改动。",
            "\n\n接下来我按你说的把首页拆成 hero 和三条 shelf，",
            "会话页的消息流改成原生 `LazyVStack`，",
            "工具卡折叠成一行，运行中用流光扫过。",
            "\n\n你希望 hero 上放「继续最近会话」还是「新建会话」？",
        ]

        for (index, chunk) in chunks.enumerated() {
            if Task.isCancelled { return }
            try? await Task.sleep(nanoseconds: 380_000_000)
            if Task.isCancelled { return }

            if index == 3 {
                appendTool(
                    ToolRun(
                        id: UUID(),
                        name: "read_file",
                        detail: "openworld-site/ios-dsh/README.md",
                        status: .running,
                        seconds: 0.4,
                        output: ""
                    ),
                    to: messageID,
                    in: sessionID
                )
            }

            appendText(chunk, to: messageID, in: sessionID)
            bump(sessionID, preview: nil, running: true, progress: min(0.92, 0.15 + Double(index) * 0.1))
        }

        completeTool(
            ToolRun(
                id: UUID(),
                name: "read_file",
                detail: "ios-dsh/README.md",
                status: .done,
                seconds: 1.2,
                output: "# NcnsDSH\n\n一个原生 SwiftUI 客户端，玻璃只用在 chrome 上。"
            ),
            in: messageID,
            sessionID: sessionID
        )

        finishStreaming(messageID, in: sessionID)
        bump(sessionID, preview: "你希望 hero 上放「继续最近会话」还是「新建会话」？", running: false, progress: 1)

        approval = ApprovalRequest(
            id: UUID(),
            title: "允许执行 bash？",
            detail: "它想跑一次构建，确认一下命令再放行。",
            command: "xcodebuild -scheme NcnsDSH -sdk iphoneos build"
        )
    }

    func approve() {
        guard let request = approval else { return }
        approval = nil
        Haptics.success()
        guard var session = heroSession else { return }
        session.preview = "已允许：\(request.command.prefix(28))…"
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index] = session
        }
    }

    func deny() {
        approval = nil
        Haptics.soft()
    }

    // MARK: - Mutation helpers

    private func append(_ message: ChatMessage, to sessionID: UUID) {
        messages[sessionID, default: []].append(message)
        touch(sessionID)
    }

    private func appendText(_ text: String, to messageID: UUID, in sessionID: UUID) {
        guard var list = messages[sessionID],
              let index = list.firstIndex(where: { $0.id == messageID })
        else { return }
        list[index].text += text
        messages[sessionID] = list
        touch(sessionID)
    }

    private func finishStreaming(_ messageID: UUID, in sessionID: UUID) {
        guard var list = messages[sessionID],
              let index = list.firstIndex(where: { $0.id == messageID })
        else { return }
        list[index].isStreaming = false
        messages[sessionID] = list
    }

    private func appendTool(_ tool: ToolRun, to messageID: UUID, in sessionID: UUID) {
        guard var list = messages[sessionID],
              let index = list.firstIndex(where: { $0.id == messageID })
        else { return }
        list[index].tools.append(tool)
        messages[sessionID] = list
    }

    private func completeTool(_ tool: ToolRun, in messageID: UUID, sessionID: UUID) {
        guard var list = messages[sessionID],
              let messageIndex = list.firstIndex(where: { $0.id == messageID }),
              let toolIndex = list[messageIndex].tools.firstIndex(where: { $0.name == tool.name })
        else { return }
        list[messageIndex].tools[toolIndex] = tool
        messages[sessionID] = list
    }

    private func bump(_ sessionID: UUID, preview: String? = nil, running: Bool? = nil, progress: Double? = nil) {
        guard let index = sessions.firstIndex(where: { $0.id == sessionID }) else { return }
        if let preview { sessions[index].preview = preview }
        if let running { sessions[index].isRunning = running }
        if let progress { sessions[index].progress = progress }
        sessions[index].lastActivity = Date()
    }

    private func touch(_ sessionID: UUID) {
        guard let index = sessions.firstIndex(where: { $0.id == sessionID }) else { return }
        sessions[index].lastActivity = Date()
    }

    // MARK: - Seed

    private func seed() {
        let now = Date()
        sessions = [
            ChatSession(
                id: UUID(),
                title: "重构 NcnsDSH 首页",
                workspace: "openworld",
                lastActivity: now.addingTimeInterval(-90),
                isRunning: true,
                progress: 0.62,
                artworkIndex: 0,
                pinned: true,
                preview: "工具卡折叠成一行，运行中用流光扫过。"
            ),
            ChatSession(
                id: UUID(),
                title: "把官网接进 Pages",
                workspace: "openworld-site",
                lastActivity: now.addingTimeInterval(-3600),
                isRunning: false,
                progress: 1,
                artworkIndex: 1,
                pinned: false,
                preview: "部署完成，首页 HTTP 200。"
            ),
            ChatSession(
                id: UUID(),
                title: "给模拟器写图标缓存",
                workspace: "openworld-ios",
                lastActivity: now.addingTimeInterval(-7200),
                isRunning: false,
                progress: 1,
                artworkIndex: 2,
                pinned: false,
                preview: "缩略图下采样到显示尺寸 ×2。"
            ),
            ChatSession(
                id: UUID(),
                title: "整理 60 秒产品片旁白",
                workspace: "openworld-film",
                lastActivity: now.addingTimeInterval(-86_400),
                isRunning: false,
                progress: 1,
                artworkIndex: 3,
                pinned: false,
                preview: "旁白脚本已经写进 README-60s-v2.md。"
            ),
            ChatSession(
                id: UUID(),
                title: "排查 runner 排队",
                workspace: "openworld",
                lastActivity: now.addingTimeInterval(-172_800),
                isRunning: false,
                progress: 1,
                artworkIndex: 4,
                pinned: false,
                preview: "macos-15 排队 15 分钟被取消。"
            ),
        ]

        workspaces = [
            Workspace(id: UUID(), name: "openworld", path: "~/Documents/openworld", running: 1, total: 12, artworkIndex: 0),
            Workspace(id: UUID(), name: "openworld-site", path: "~/Documents/openworld-site", running: 0, total: 8, artworkIndex: 1),
            Workspace(id: UUID(), name: "openworld-ios", path: "~/Documents/openworld-ios", running: 0, total: 5, artworkIndex: 2),
            Workspace(id: UUID(), name: "openworld-film", path: "~/Documents/openworld-film", running: 0, total: 3, artworkIndex: 3),
        ]

        schedules = [
            ScheduleItem(id: UUID(), title: "每天早上汇总 CI 状态", cadence: "每天 08:30", nextRun: now.addingTimeInterval(3600 * 6), enabled: true),
            ScheduleItem(id: UUID(), title: "每周清理一次构建缓存", cadence: "周一 21:00", nextRun: now.addingTimeInterval(86_400 * 3), enabled: false),
        ]

        if let first = sessions.first {
            messages[first.id] = [
                ChatMessage(id: UUID(), role: .user, text: "把首页拆成 hero 和三条 shelf，视觉按 tv 来。", tools: [], isStreaming: false, date: now.addingTimeInterval(-600)),
                ChatMessage(
                    id: UUID(),
                    role: .assistant,
                    text: "拆好了。hero 放最近活跃的会话，下面三条分别是「继续」「工作区」「最近完成」；卡片按下时才起玻璃，常驻玻璃会压性能。",
                    tools: [
                        ToolRun(id: UUID(), name: "edit_file", detail: "Views/HomeView.swift", status: .done, seconds: 1.8, output: "+ 214 − 0"),
                        ToolRun(id: UUID(), name: "xcodebuild", detail: "NcnsDSH · Debug", status: .failed, seconds: 42.0, output: "error: cannot find 'GlassEffectContainer' in scope"),
                    ],
                    isStreaming: false,
                    date: now.addingTimeInterval(-540)
                ),
            ]
        }

        activeSessionID = sessions.first?.id
    }
}
