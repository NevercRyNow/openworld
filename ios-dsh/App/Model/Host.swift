import Foundation

/// One DSH host the app can open. `baseURL` is the origin the `dsh web`
/// server printed (minus the `?token=` query); `token` is the launch token.
struct Host: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var baseURL: URL
    var token: String

    var webURL: URL {
        guard !token.isEmpty else { return baseURL }
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            return baseURL
        }
        var items = components.queryItems ?? []
        items.removeAll { $0.name == "token" }
        items.append(URLQueryItem(name: "token", value: token))
        components.queryItems = items
        return components.url ?? baseURL
    }

    var displayName: String {
        if !name.isEmpty { return name }
        return baseURL.host ?? baseURL.absoluteString
    }

    var originText: String {
        var text = baseURL.absoluteString
        while text.hasSuffix("/") { text.removeLast() }
        return text
    }
}

enum HostParser {
    /// Accepts `192.168.1.8:3080`, `http://mac.local:3080/?token=…`,
    /// `https://box.example.com/dsh`, or a `dsh://connect?url=…` link.
    static func parse(_ raw: String) -> Host? {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }

        if text.lowercased().hasPrefix("dsh://") {
            guard let link = URL(string: text),
                  let components = URLComponents(url: link, resolvingAgainstBaseURL: false),
                  let inner = components.queryItems?.first(where: { $0.name == "url" })?.value
            else { return nil }
            text = inner
        }

        if !text.contains("://") {
            text = "http://" + text
        }

        guard var components = URLComponents(string: text) else { return nil }
        guard let scheme = components.scheme?.lowercased(), scheme == "http" || scheme == "https" else {
            return nil
        }
        guard let hostname = components.host, !hostname.isEmpty else { return nil }

        var token = ""
        if let items = components.queryItems {
            token = items.first(where: { $0.name == "token" })?.value ?? ""
            let kept = items.filter { $0.name != "token" }
            components.queryItems = kept.isEmpty ? nil : kept
        }
        if components.path.count > 1, components.path.hasSuffix("/") {
            components.path = String(components.path.dropLast())
        }

        guard let base = components.url else { return nil }

        var name = hostname
        if let port = components.port {
            name += ":\(port)"
        }

        return Host(id: UUID(), name: name, baseURL: base, token: token)
    }
}
