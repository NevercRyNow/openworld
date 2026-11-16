# DSH on iOS — 开源调研与移植方案

状态：调研完成，等三个决定（见文末）
日期：2026-11-17

## 0. 一句话结论

DSH 本体（TypeScript/Cordis）没有 iOS 目标；但它的**客户端与引擎本来就是分离的**，所以 iOS 版有两条真正可行的路——要么只做原生客户端去连宿主（快、能交付），要么把 Node 引擎和一批原生框架整个装进 App（fish-pocket 路线，工程量以周/月计）。这台设备没有 Swift/Xcode，能编译验证的只有前者。

## 1. DSH 本体结构（事实，来自源码与官方文档）

- 一个 `dsh` 进程是一棵 **Cordis 插件树**，由 profile（`web` / `headless` / `sdk` / `acp`）叠 bundle 组成，"Everything is a Plugin"。
- Host 侧通过 **`/api`（unary RPC）+ `/api/remote.mux`（WebSocket，多路复用流）** 把会话、事件、审批、文件暴露给客户端；`dsh-api-*` 包就是这些 endpoint。
- Web 客户端是插件化的浏览器应用（`dsh-client-ui-*`），**只依赖上述 RPC/流协议**，不依赖 Node。
- 桌面版（`apps/desktop`）是 Electron：同一个 Web 页面 + 一个把页面接到本地 Host 的 carrier。**"套壳"在官方产品里就是合法架构**。
- 仓库里没有 iOS/mobile 目标（`apps/` 只有 cli / desktop / desktop-host / desktop-publisher；`native/` 是 macOS/Linux 的系统 Node 发行包）。

## 2. GitHub 上已有的 iOS / 移动端项目

| 项目 | 星 | 技术 | 引擎在哪 | 对我们的价值 |
|---|---|---|---|---|
| [imsai-sh/fish-pocket](https://github.com/imsai-sh/fish-pocket) | 287 | Swift/SwiftUI，XcodeGen | **机内**：nodejs-mobile xcframework + N-API 绑定（git/image/ios-native/python/ffmpeg）+ 引擎 `engine/` | 目前最完整的"DSH iOS 版"，也是本会话所在 App；MIT + 商用需授权 |
| [Clarklevis1995/dsh-mobile](https://github.com/Clarklevis1995/dsh-mobile) | 802 | Kotlin Multiplatform + SwiftUI | 远端宿主 | 原生双端客户端，协议/状态机放 shared；iOS 用 URLSession WebSocket + Keychain + 扫码配对 |
| [dsh-plugin-mobile-gateway](https://github.com/Clarklevis1995/dsh-plugin-mobile-gateway) | 161 | TS 插件 | 宿主侧 | **现成的移动网关**：配对二维码、可信设备、会话/流式回复/审批/上传/团队，带客户端契约文档 |
| [liguobao/ds-harness-remote](https://github.com/liguobao/ds-harness-remote) | 3069 | TS + P2P | 远端宿主 | 端到端加密 P2P 通道；iOS 客户端尚未有（issue #20） |
| [shaobeichen/dsh-pocket](https://github.com/shaobeichen/dsh-pocket) | 2999 | JS | 远端宿主 | 扫码即用，手机浏览器/PWA 方向 |
| [ZSeven-W/rish-app](https://github.com/ZSeven-W/rish-app) | 163 | Rust/GPUI + 原生 | 机内（自研 agent） | 本地优先 agent 的移动端形态参考 |
| [chokwinlee/deepseek-harness-desktop](https://github.com/chokwinlee/deepseek-harness-desktop) | 286 | Swift/Kotlin | 远端宿主 | SwiftUI iPhone Remote 的先行尝试 |
| `openworld-site/ios`（本仓库已有） | — | SwiftUI + WKWebView | 无 | 目前只是官网的网页壳（`OpenWorldApp.swift` + `WebView.swift`） |

结论：**生态里"原生客户端 + 宿主网关"（Whaleness 那条路）和"引擎入机"（fish-pocket 那条路）都已被验证**，我们要选一条。

## 3. 三条路线对比

### A. 原生远程客户端 + 宿主网关（推荐）
- iOS 端：SwiftUI，自己实现 WS 客户端、会话/流状态机、Markdown、工具卡、审批、文件预览。
- 宿主端：装 `dsh-plugin-mobile-gateway`（或按它的协议写一个更瘦的插件），手机扫码配对。
- 优点：能真正出包、能真机验证协议、模块边界干净，后期作为 OpenWorld 的一个 tab 直接复用；不需要移植引擎。
- 缺点：离开宿主就是一个空壳；离线不可用。
- 本环境可交付度：**高**（Swift 可以盲写 + CI 编译；网关协议有文档；可先用本机 3080 联调）。

### B. 引擎入机（fish-pocket 路线）
- 需要：nodejs-mobile（或自建 Node iOS 运行时）、`just-bash` 式进程内 shell、libgit2/ImageIO/CPython/ffmpeg 的 N-API 绑定、大量 runtime 适配（`child_process`、模块重定向、worker、Intl、TextDecoder…）。
- 优点：不连电脑，离线可用，能力最接近桌面 DSH；OpenWorld 可以自带引擎。
- 缺点：本机没有 Swift/Xcode，**一行都编译不了**，只能等 CI；fork fish-pocket 商用还要作者书面授权。周期以周/月计。
- 本环境可交付度：**低**（只能产出工程骨架和移植清单，不能产出可安装包）。

### C. WKWebView 壳
- 把 `dsh web` 原样装进 App（openworld-site/ios 已经是这个形态的雏形，只是装的是官网）。
- 优点：一天能出包，功能 100% 对齐 Web UI。
- 缺点：不是"iOS 版"，是网页；OpenWorld 里也只是一个网页视图；离线、原生交互、系统能力都没有。
- 本环境可交付度：**最高**。

## 4. 若选 A：v1 设计草案

```
iPhone (SwiftUI)                        Host (macOS/Linux/手机)
┌───────────────────────┐   WSS/JSON   ┌──────────────────────────┐
│ Pairing (扫码/token)   │◄────────────►│ dsh-plugin-mobile-gateway │
│ Sessions 列表          │              │  ├ session/list, follow   │
│ Chat 流式 + 工具卡      │              │  ├ prompt, steer, stop    │
│ Approvals / 问答        │              │  ├ approvals, questions   │
│ Workspace 文件预览      │              │  └ files, attachments     │
└───────────────────────┘              └──────────────────────────┘
```

iOS 模块：
- `Net/`：WebSocket 传输、帧编解码、重连退避、心跳、token/Keychain
- `Model/`：Session、Turn、Event 投影（把 wire event 投影成 UI 状态，纯函数、可单测）
- `Features/`：Pairing、SessionList、Chat（Markdown/代码块/工具调用/审批/子 agent）、Settings
- `DesignSystem/`：DSH 视觉语言（克制、清晰）、深浅色、动态字体

工程与交付：
- XcodeGen（`project.yml`），iOS 17+，零第三方依赖起步（Markdown 自渲染，必要时再引 SPM）
- CI：GitHub Actions `macos-15`，`xcodebuild CODE_SIGNING_ALLOWED=NO` → unsigned IPA + SHA256，产物可侧载
- 验收：CI 绿 + 真机安装 + 连宿主完成「列表 → 发消息 → 流式回复 → 工具卡 → 审批 → 停止」一轮

## 5. 与 OpenWorld 的集成（后期）

- 形态：OpenWorld 内新增一个 Agent/DSH tab；客户端代码以本地 Swift Package 形式复用，OpenWorld 只提供入口和主题。
- 若到时需要"不连电脑"，再评估 B：把网关换成机内引擎，iOS 界面层不动。
- 需要 OpenWorld 决定：入口位置、是否共用账号/模型配置、是否需要把工作区文件接到 OpenWorld 的文档目录。

## 6. 三个待定问题

1. 形态：A（原生客户端）/ B（引擎入机）/ C（网页壳）？
2. 宿主：电脑、服务器，还是先连本机 3080 开发验证？
3. 交付：用 `NevercRyNow/openworld` 仓库出包，还是新建独立仓库？需要能推代码的 token。
