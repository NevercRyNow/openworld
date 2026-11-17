# 把 DSH 做成 OpenWorld 里的一个功能

现在 `ios-dsh/` 是一个**独立 App**（`com.nevercrynow.ncnsdsh`）。这一步先证明它能用；
之后按下面的方式并进 OpenWorld，不用重写界面。

## 现状

- `ios/` —— OpenWorld 已有的 iOS 工程（`com.nevercrynow.openworld`），目前只是一个 WKWebView 装官网。
- `ios-dsh/` —— 这次做的 DSH 原生壳：连接页 + WKWebView + 设置，独立 target，独立 bundle id。
- 两者都在同一个仓库里，共用 `macos-15` 的 CI 出无签名 IPA。

## 合并方式（推荐）

把 `ios-dsh/App` 里除 `DSHApp.swift` 之外的内容提成一个本地 Swift Package `NcnsKit`：

```
Packages/NcnsKit/
  Package.swift
  Sources/NcnsKit/
    Host.swift  HostStore.swift  Keychain.swift
    ConnectView.swift  ScannerView.swift  WebScreen.swift  WebView.swift  SettingsView.swift
    Theme.swift
```

OpenWorld 的 App target 增加依赖 `NcnsKit`，然后在入口放一个 tab / 页面：

```swift
import NcnsKit

struct OpenWorldRoot: View {
    @StateObject private var hosts = HostStore()

    var body: some View {
        TabView {
            // …原有的模拟器 / 游戏页
            NcnsFeatureView()          // NcnsKit 提供，内部就是 ConnectView ↔ WebScreen
                .environmentObject(hosts)
                .tabItem { Label("DSH", systemImage: "terminal") }
        }
    }
}
```

`NcnsFeatureView` 只需要暴露三件事：宿主列表、连接入口、`store.disconnect()`。
其余（Keychain、扫码、下载、文件选择）都在包里，不依赖 OpenWorld 的任何代码。

### 需要一起改的几处

1. **Info.plist**：把 `NSCameraUsageDescription`、`NSLocalNetworkUsageDescription`、
   `NSAppTransportSecurity` 三项挪到 OpenWorld 的 Info.plist；`dsh://` scheme 视需要保留。
2. **主题**：`Theme.accent` 改成从 OpenWorld 的 design token 注入，或直接换色值；
   其余颜色都是系统色，深浅色自动跟随。
3. **入口**：OpenWorld 现在的主界面是 WKWebView（官网）。DSH 页要放在原生层
   （`TabView`/`NavigationStack`），不要塞进那个 WebView，否则会套两层。
4. **App Group（可选）**：如果 OpenWorld 和 DSH 两个 App 同时存在，并且想共用宿主列表，
   把 `UserDefaults(suiteName:)` 和 Keychain 的 access group 换成同一个 App Group
   （`group.com.nevercrynow.openworld`），`HostStore` 里改两处即可。

## 之后要不要"不连电脑"

如果 OpenWorld 的目标是自带引擎、离线可用，那就是调研里说的 **B 路线**：
把 Node 运行时 + DSH 引擎 + N-API 绑定打进 App。届时要换的只有 `WebScreen` 底下那一层
（从远程 URL 换成 `http://127.0.0.1:<本机端口>`），连接页、Keychain、扫码、错误页全部不动。

参考实现是 fish-pocket（MIT + 商用需授权），它的 `app/project.yml` 已经把需要的
xcframework 和绑定列全了：`nodejs-mobile`、`libgit2`、`ImageIO`、`CPython`、`ffmpeg`。

## 验收

- OpenWorld 主工程能编过，`DSH` tab 能进；
- 和独立 App 用同一个宿主、同一个 token，会话能看到同一份；
- 杀掉 OpenWorld 再打开，宿主列表和 token 还在（Keychain + UserDefaults）；
- 窄屏（iPhone SE 宽度）不出现横向滚动。
