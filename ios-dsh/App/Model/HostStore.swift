import Foundation
import Combine

final class HostStore: ObservableObject {
    @Published private(set) var hosts: [Host] = []
    @Published var current: Host?
    @Published var lastError: String?

    private let hostsKey = "dsh.hosts.v1"
    private let currentKey = "dsh.current.v1"

    init() {
        restore()
    }

    // MARK: - Connecting

    /// Saves and opens a host. `address` may carry `?token=…`; an explicit
    /// token argument wins when it is not empty.
    func connect(address: String, token: String) {
        guard var host = HostParser.parse(address) else {
            lastError = "地址不对。示例：192.168.1.8:3080 或 http://mac.local:3080"
            Haptics.failure()
            return
        }

        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            host.token = trimmed
        }
        if host.token.isEmpty {
            lastError = "还需要 token。dsh web 启动时会打印带 token 的地址。"
            Haptics.failure()
            return
        }

        if let index = hosts.firstIndex(where: { $0.baseURL == host.baseURL && $0.token == host.token }) {
            host = hosts.remove(at: index)
            hosts.insert(host, at: 0)
        } else {
            hosts.insert(host, at: 0)
            if hosts.count > 8 {
                hosts.removeLast(hosts.count - 8)
            }
        }

        Keychain.set(host.token, for: Self.tokenAccount(host))
        save()
        lastError = nil
        Haptics.success()
        current = host
    }

    func open(_ host: Host) {
        current = host
        UserDefaults.standard.set(host.id.uuidString, forKey: currentKey)
    }

    func disconnect() {
        current = nil
        UserDefaults.standard.removeObject(forKey: currentKey)
    }

    func forget(_ host: Host) {
        Keychain.delete(Self.tokenAccount(host))
        hosts.removeAll { $0.id == host.id }
        if current?.id == host.id {
            current = nil
        }
        save()
    }

    func rename(_ host: Host, to name: String) {
        guard let index = hosts.firstIndex(where: { $0.id == host.id }) else { return }
        var copy = hosts[index]
        copy.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        hosts[index] = copy
        if current?.id == host.id {
            current = copy
        }
        save()
    }

    // MARK: - Persistence

    private static func tokenAccount(_ host: Host) -> String {
        "host.\(host.id.uuidString)"
    }

    private func save() {
        let sanitized = hosts.map { host -> Host in
            var copy = host
            copy.token = ""
            return copy
        }
        if let data = try? JSONEncoder().encode(sanitized) {
            UserDefaults.standard.set(data, forKey: hostsKey)
        }
        if let id = current?.id.uuidString {
            UserDefaults.standard.set(id, forKey: currentKey)
        }
    }

    private func restore() {
        guard let data = UserDefaults.standard.data(forKey: hostsKey),
              let decoded = try? JSONDecoder().decode([Host].self, from: data)
        else { return }

        hosts = decoded.map { host in
            var copy = host
            copy.token = Keychain.get(Self.tokenAccount(host)) ?? ""
            return copy
        }
        hosts.removeAll { $0.token.isEmpty }

        guard let idText = UserDefaults.standard.string(forKey: currentKey),
              let id = UUID(uuidString: idText),
              let host = hosts.first(where: { $0.id == id })
        else { return }
        current = host
    }
}
