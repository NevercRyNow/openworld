import SwiftUI
import WebKit
import UIKit
import UniformTypeIdentifiers

/// Holds the live `WKWebView` so the surrounding SwiftUI chrome can drive it
/// (reload, back, forward) without owning it.
final class WebBridge {
    weak var webView: WKWebView?

    var canGoBack: Bool { webView?.canGoBack ?? false }
    var canGoForward: Bool { webView?.canGoForward ?? false }
    var url: URL? { webView?.url }

    func reload() { webView?.reload() }
    func goBack() { webView?.goBack() }
    func goForward() { webView?.goForward() }
    func stop() { webView?.stopLoading() }
}

struct DSHWebView: UIViewRepresentable {
    let host: Host
    let bridge: WebBridge

    @Binding var progress: Double
    @Binding var error: String?
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var pageTitle: String

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        configuration.websiteDataStore = .default()

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.keyboardDismissMode = .interactive
        webView.isOpaque = false
        webView.backgroundColor = .systemBackground
        webView.scrollView.backgroundColor = .systemBackground
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }

        context.coordinator.attach(webView)
        bridge.webView = webView
        webView.load(URLRequest(url: host.webURL))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.parent = self
        bridge.webView = webView
    }

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        coordinator.detach()
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKDownloadDelegate, UIDocumentPickerDelegate {
        var parent: DSHWebView
        private var observation: NSKeyValueObservation?
        private var refreshControl: UIRefreshControl?
        private var pendingUpload: (([URL]?) -> Void)?
        private var downloads: [ObjectIdentifier: URL] = [:]

        init(_ parent: DSHWebView) {
            self.parent = parent
        }

        func attach(_ webView: WKWebView) {
            observation = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] view, _ in
                let value = view.estimatedProgress
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.parent.progress = value
                    if value >= 1 { self.sync(webView) }
                }
            }

            let refresh = UIRefreshControl()
            refresh.addTarget(self, action: #selector(pulled), for: .valueChanged)
            webView.scrollView.refreshControl = refresh
            refreshControl = refresh
        }

        func detach() {
            observation?.invalidate()
            observation = nil
            refreshControl?.endRefreshing()
            refreshControl = nil
        }

        @objc private func pulled() {
            parent.bridge.webView?.reload()
        }

        private func sync(_ webView: WKWebView) {
            parent.canGoBack = webView.canGoBack
            parent.canGoForward = webView.canGoForward
            if let title = webView.title, !title.isEmpty {
                parent.pageTitle = title
            }
        }

        private func fail(_ error: Error) {
            let ns = error as NSError
            if ns.domain == NSURLErrorDomain, ns.code == NSURLErrorCancelled { return }
            refreshControl?.endRefreshing()

            let text: String
            if ns.domain == NSURLErrorDomain, ns.code == NSURLErrorCannotConnectToHost || ns.code == NSURLErrorCannotFindHost {
                text = "连不上 \(parent.host.originText)。确认电脑上 `dsh web` 在运行，手机和电脑在同一个网络，防火墙放行了这个端口。"
            } else if ns.domain == NSURLErrorDomain, ns.code == NSURLErrorTimedOut {
                text = "连接超时。宿主可能正忙，或者不在这个网络里。"
            } else {
                text = ns.localizedDescription
            }

            DispatchQueue.main.async {
                self.parent.error = text
                self.parent.progress = 0
            }
        }

        // MARK: Navigation

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.error = nil
            parent.progress = 0.08
            sync(webView)
        }

        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            sync(webView)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            refreshControl?.endRefreshing()
            parent.progress = 1
            parent.error = nil
            sync(webView)
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            fail(error)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            fail(error)
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationResponse: WKNavigationResponse,
            decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
        ) {
            if let http = navigationResponse.response as? HTTPURLResponse, http.statusCode == 401 {
                DispatchQueue.main.async {
                    self.parent.error = "宿主拒绝了这次连接：token 可能已经过期，或者地址里的 token 不是这台宿主打印的。"
                    self.parent.progress = 0
                }
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }

            if let scheme = url.scheme?.lowercased(), scheme != "http", scheme != "https" {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
                return
            }

            // A new window, or a link that leaves the host: hand it to Safari.
            let isNewWindow = navigationAction.targetFrame == nil
            let sameHost = url.host == parent.host.baseURL.host
            if isNewWindow || !sameHost {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
                return
            }

            decisionHandler(.allow)
        }

        // MARK: Downloads

        func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
            download.delegate = self
        }

        func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
            download.delegate = self
        }

        func download(
            _ download: WKDownload,
            decideDestinationUsing response: URLResponse,
            suggestedFilename: String,
            completionHandler: @escaping (URL?) -> Void
        ) {
            let name = suggestedFilename.isEmpty ? "download" : suggestedFilename
            let folder = FileManager.default.temporaryDirectory.appendingPathComponent("dsh-downloads", isDirectory: true)
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let destination = folder.appendingPathComponent(name)
            try? FileManager.default.removeItem(at: destination)
            downloads[ObjectIdentifier(download)] = destination
            completionHandler(destination)
        }

        func downloadDidFinish(_ download: WKDownload) {
            guard let url = downloads.removeValue(forKey: ObjectIdentifier(download)) else { return }
            DispatchQueue.main.async {
                Haptics.success()
                self.share(url)
            }
        }

        func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
            downloads.removeValue(forKey: ObjectIdentifier(download))
        }

        private func share(_ url: URL) {
            guard let controller = topViewController() else { return }
            let activity = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            activity.popoverPresentationController?.sourceView = controller.view
            controller.present(activity, animated: true)
        }

        // MARK: JavaScript panels

        func webView(
            _ webView: WKWebView,
            runJavaScriptAlertPanelWithMessage message: String,
            initiatedByFrame frame: WKFrameInfo,
            completionHandler: @escaping () -> Void
        ) {
            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "好", style: .default) { _ in completionHandler() })
            present(alert)
        }

        func webView(
            _ webView: WKWebView,
            runJavaScriptConfirmPanelWithMessage message: String,
            initiatedByFrame frame: WKFrameInfo,
            completionHandler: @escaping (Bool) -> Void
        ) {
            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "取消", style: .cancel) { _ in completionHandler(false) })
            alert.addAction(UIAlertAction(title: "确定", style: .default) { _ in completionHandler(true) })
            present(alert)
        }

        func webView(
            _ webView: WKWebView,
            runJavaScriptTextInputPanelWithPrompt prompt: String,
            defaultText: String?,
            initiatedByFrame frame: WKFrameInfo,
            completionHandler: @escaping (String?) -> Void
        ) {
            let alert = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)
            alert.addTextField { field in
                field.text = defaultText
            }
            alert.addAction(UIAlertAction(title: "取消", style: .cancel) { _ in completionHandler(nil) })
            alert.addAction(UIAlertAction(title: "确定", style: .default) { _ in
                completionHandler(alert.textFields?.first?.text)
            })
            present(alert)
        }

        // MARK: File upload

        func webView(
            _ webView: WKWebView,
            runOpenPanelWith parameters: WKOpenPanelParameters,
            initiatedByFrame frame: WKFrameInfo,
            completionHandler: @escaping ([URL]?) -> Void
        ) {
            pendingUpload = completionHandler
            let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item], asCopy: true)
            picker.allowsMultipleSelection = parameters.allowsMultipleSelection
            picker.delegate = self
            present(picker)
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            let completion = pendingUpload
            pendingUpload = nil
            completion?(urls)
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            let completion = pendingUpload
            pendingUpload = nil
            completion?(nil)
        }

        // MARK: Presentation

        private func present(_ controller: UIViewController) {
            DispatchQueue.main.async {
                self.topViewController()?.present(controller, animated: true)
            }
        }

        private func topViewController() -> UIViewController? {
            let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            let window = scenes.flatMap(\.windows).first(where: { $0.isKeyWindow })
                ?? scenes.flatMap(\.windows).first
            guard var controller = window?.rootViewController else { return nil }
            while let presented = controller.presentedViewController {
                controller = presented
            }
            return controller
        }
    }
}
