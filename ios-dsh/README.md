# DSH for iOS

一个原生 SwiftUI 外壳，装的是正在运行的 DeepSeek Harness Web 界面。
扫码把手机连到那台跑 `dsh web` 的电脑，会话、工具调用、审批、文件都在原来的宿主里执行，
手机只是一个原生入口——不重跑引擎，也不复制会话。

```
┌──────────── iPhone ────────────┐        ┌──────── 电脑 ────────┐
│ SwiftUI：连接 / 最近 / 设置     │  HTTPS │ dsh web              │
│ WKWebView：官方 Web UI         │◄──────►│ 会话 · 工具 · 审批    │
│ Keychain：token                │   WS   │ 工作区                │
└────────────────────────────────┘        └──────────────────────┘
```

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

打开 DSH，粘贴地址（token 会自动从 `?token=` 里拆出来），或点「扫描二维码」，
把上面那个 URL 做成二维码扫进来。连上后：

- 顶部只留一条细进度条、前进/后退和菜单，其余都是官方的 Web UI；
- 菜单里有刷新、在 Safari 打开、复制带 token 的地址、设置、断开；
- 文件选择、下载、`alert/confirm/prompt` 都接到原生；
- token 存钥匙串，最近宿主存 UserDefaults，最多 8 台。

## 构建

工程用 [XcodeGen](https://github.com/yonaskolb/XcodeGen) 生成，`App/` 下是全部源码，没有第三方依赖。

```sh
cd ios-dsh
brew install xcodegen
xcodegen generate
open DSHPocket.xcodeproj     # 选自己的 Team 即可真机调试
```

### 无签名 IPA（CI）

本机没有 Xcode 也能出包：`/.github/workflows/dsh-ios.yml` 在 `macos-15` 上跑，
`CODE_SIGNING_ALLOWED=NO` 构建后把 `.app` 打成 `Payload/` 再 zip 成 `DSH-unsigned.ipa`，
连同 `SHA256.txt` 一起作为 artifact 上传。

侧载（AltStore / Sideloadly / TrollStore）后即可安装；免费 Apple ID 签名 7 天有效。

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

## 已知限制

- 必须有一台在运行的宿主；离线不可用。这是「原生壳」形态的代价，见 `docs/research.md` 的路线对比。
- 官方 Web UI 是桌面优先的布局，iPhone 竖屏信息密度偏高；下一步在壳里加窄屏适配（折叠侧栏 / 单栏对话）。
- 无签名 IPA 需要自己签名；没有 App Store / TestFlight 通道。
- 后台不保活：切走后连接会断，回来重新连（Web UI 会自己重连）。

## 路线

1. **窄屏适配**：注入一段受控 CSS + 视口处理，让 Web UI 在 iPhone 上按单栏跑；侧栏收进抽屉。
2. **原生入口**：主屏幕快捷指令 / 分享扩展，把一段文字直接交给某个会话。
3. **离线兜底**：连不上时给一个可读的最近会话摘要（宿主下发或本地缓存）。
4. **嵌进 OpenWorld**：把这一层做成 Swift Package + 一个入口页，见 `docs/openworld-integration.md`。
