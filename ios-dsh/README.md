# NcnsDSH

DeepSeek Harness 的 iOS 原生客户端。视觉参照 tv 的暗色影院首页与 Apple Music 的
artwork 驱动详情页，材质用 iOS 26 Liquid Glass；会话、工具卡、审批全部原生。

```
┌──────────── iPhone ────────────┐        ┌──────── 电脑 ────────┐
│ SwiftUI：首页 / 会话 / 审批      │   WS   │ dsh web              │
│ 演示数据（接网关前的占位）        │◄──────►│ 会话 · 工具 · 审批    │
│ WKWebView：插件页 / 终端兜底     │        │ 工作区                │
└────────────────────────────────┘        └──────────────────────┘
```

**当前阶段**：视觉与交互已经按最终形态跑通（B + C），数据是本地的演示数据（`DemoStore`）。
接 `dsh-plugin-mobile-gateway` 的 WebSocket 之后，只需把 `DemoStore.send/approve` 换成真实调用，
视图层不动（A 的那一半）。

## 快速开始

### 1. 宿主：让 `dsh web` 监听局域网

默认只监听 `127.0.0.1`，手机连不上。指定电脑的局域网地址（必须是本机某个网卡的具体地址，不能用 `0.0.0.0`）：

```sh
dsh web --host 192.168.1.8
```

终端会打印 `http://192.168.1.8:3080/?token=…`。把这个地址（或二维码里的内容）交给手机。

`--host` 也可以换成 Tailscale / ZeroTier 的地址；公网访问请套 HTTPS 反向代理，并用 `--trusted-host` 声明域名，
否则 `/api` 的 Host 校验会返回 403。

### 2. 手机：连接

打开 NcnsDSH，粘贴地址（token 会自动从 `?token=` 里拆出来），或点「扫描二维码」，
把上面那个 URL 做成二维码扫进来。连上后进的是原生界面：

- 首页：hero + 「继续 / 工作区 / 最近完成」三条 shelf；
- 会话：原生消息流、可折叠工具卡、底部玻璃输入条、审批 sheet；
- 底部「运行中」胶囊：离开会话后仍能看到正在跑的那一个；
- 插件页、终端、文件预览还留在「设置 → 网页版」里（WKWebView 兜底）。

token 存钥匙串，最近宿主存 UserDefaults，最多 8 台。

### token 是「一次性的」

`dsh web` 打印出来的 token 只负责换一枚登录 cookie（`/` 上 303 + `Set-Cookie`）。
换过之后同一行 token 再用就是 401；宿主重启也会发新 token。
所以正常使用靠的是 WKWebView 里持久化的 cookie，token 只在第一次配对时需要。
cookie 丢了（清了数据、换了宿主进程）就点错误页上的「重新配对」，回电脑上拿新地址。

## 构建

工程用 [XcodeGen](https://github.com/yonaskolb/XcodeGen) 生成，`App/` 下是全部源码，没有第三方依赖。

```sh
cd ios-dsh
brew install xcodegen
xcodegen generate
open NcnsDSH.xcodeproj     # 选自己的 Team 即可真机调试
```

### 本机一键出包

```sh
./build-ipa.sh      # 产出 NcnsDSH-unsigned.ipa + SHA256.txt
```

### 无签名 IPA（CI）

本机没有 Xcode 也能出包：`/.github/workflows/dsh-ios.yml` 在 `macos-15` 上跑，
`CODE_SIGNING_ALLOWED=NO` 构建后把 `.app` 打成 `Payload/` 再 zip 成 `NcnsDSH-unsigned.ipa`，
连同 `SHA256.txt` 一起作为 artifact 上传。

侧载（AltStore / Sideloadly / TrollStore）后即可安装；免费 Apple ID 签名 7 天有效。
macOS runner 当前拿不到机器时（job 排队 15 分钟被取消），换 Codemagic 或任意一台 Mac，
详见 [`docs/install.md`](docs/install.md)。

## 目录

```
ios-dsh/
├── project.yml              # XcodeGen 描述
├── App/
│   ├── Info.plist           # ATS、相机、本地网络、dsh:// scheme
│   ├── DSHApp.swift
│   ├── RootView.swift
│   ├── Model/               # Host 解析、HostStore、Keychain
│   ├── Views/               # Connect、Scanner、Web、Settings
│   ├── Support/             # 主题与触感
│   └── Assets.xcassets/     # AppIcon（tools/make-icon.mjs 生成）
├── tools/make-icon.mjs
└── docs/                    # 调研、OpenWorld 集成方案
```

## 玻璃与系统版本

`App/DesignSystem/Glass.swift` 把 Liquid Glass 收在一个地方：
iOS 26 SDK 编出来、跑在 iOS 26 上是真玻璃（`.glassEffect(_:in:)`）；
旧 SDK 或旧系统自动退化成 `.ultraThinMaterial`，用 `#if compiler(>=6.2)` + `#available` 隔开。
玻璃只给 chrome（tab bar、toolbar、输入条、审批、运行中胶囊）和卡片按下态，内容区一律不透明。

## 已知限制

- 数据还是演示数据；`DemoStore` 就是接网关时要替换的那一层。
- 必须有一台在运行的宿主；离线不可用。这是客户端形态的代价，见 `docs/research.md` 的路线对比。
- 官方 Web UI 是桌面优先的布局，iPhone 竖屏信息密度偏高；下一步在壳里加窄屏适配（折叠侧栏 / 单栏对话）。
- 无签名 IPA 需要自己签名；没有 App Store / TestFlight 通道。
- 后台不保活：切走后连接会断，回来重新连（Web UI 会自己重连）。
- 官方 Web UI 没有按宽度做的响应式断点（只有 `hover/pointer` 查询），iPhone 竖屏是桌面三栏压缩后的样子。

## 路线

1. **窄屏适配**：注入一段受控 CSS + 视口处理，让 Web UI 在 iPhone 上按单栏跑；侧栏收进抽屉。
2. **原生入口**：主屏幕快捷指令 / 分享扩展，把一段文字直接交给某个会话。
3. **离线兜底**：连不上时给一个可读的最近会话摘要（宿主下发或本地缓存）。
4. **嵌进 OpenWorld**：把这一层做成 Swift Package + 一个入口页，见 `docs/openworld-integration.md`。
