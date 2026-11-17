import Foundation

struct ChatSession: Identifiable, Hashable {
    let id: UUID
    var title: String
    var workspace: String
    var lastActivity: Date
    var isRunning: Bool
    var progress: Double
    var artworkIndex: Int
    var pinned: Bool
    var preview: String

    var initial: String {
        String(title.trimmingCharacters(in: .whitespaces).prefix(1))
    }

    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: lastActivity, relativeTo: Date())
    }
}

struct Workspace: Identifiable, Hashable {
    let id: UUID
    var name: String
    var path: String
    var running: Int
    var total: Int
    var artworkIndex: Int
}

struct ScheduleItem: Identifiable, Hashable {
    let id: UUID
    var title: String
    var cadence: String
    var nextRun: Date
    var enabled: Bool
}

enum ChatRole {
    case user
    case assistant
}

struct ChatMessage: Identifiable, Hashable {
    let id: UUID
    var role: ChatRole
    var text: String
    var tools: [ToolRun]
    var isStreaming: Bool
    var date: Date
}

enum ToolStatus {
    case running
    case done
    case failed
}

struct ToolRun: Identifiable, Hashable {
    let id: UUID
    var name: String
    var detail: String
    var status: ToolStatus
    var seconds: Double
    var output: String
}

struct ApprovalRequest: Identifiable, Hashable {
    let id: UUID
    var title: String
    var detail: String
    var command: String
}
