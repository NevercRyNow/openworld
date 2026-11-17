# NcnsDSH — 重构提示词包

给编码模型（或给我自己下一轮）直接粘贴用的提示词。
视觉参照：**tv**（暗色影院感、hero、shelf、大标题、zoom 转场）+ **Apple Music**（artwork 驱动渐变、mini player、弹簧动效）。
材质：**iOS 26 Liquid Glass**。

---

## 0. 先决条件（必须写进任何一个提示词里）

1. **Liquid Glass 只作用于原生视图。** WKWebView 里的网页内容不吃 `.glassEffect`，也不会透出背后的玻璃。想让「苹果原生质感」成立，会话、列表、审批就必须是原生的。
2. 因此这次重构等于**从「网页壳」切到「原生数据客户端」**：数据走 `dsh-plugin-mobile-gateway` 的 WebSocket 协议（扫码配对、会话列表、流式回复、审批、上传）。WKWebView 降级为兜底页（插件页、终端、文件预览），从主导航里拿掉。
3. 最低系统 **iOS 26**。要兼容 iOS 17–18，用 `if #available(iOS 26.0, *)` 包一层 `.ultraThinMaterial` 回退——但主视觉按 26 做。
4. 不引入第三方 UI 库；图标准用 SF Symbols。

---

## 1. 命名与工程改名

```
显示名      NcnsDSH
Product     NcnsDSH
Scheme      NcnsDSH
Bundle ID   com.nevercrynow.ncnsdsh
URL scheme  ncnsdsh://
目录        ios-dsh/（保留，避免一次改路径就把 CI 改挂）
```

改这五处：`project.yml` 的 `name` / target 名 / `PRODUCT_NAME` / `PRODUCT_BUNDLE_IDENTIFIER`、`App/Info.plist` 的 `CFBundleDisplayName` 与 `CFBundleURLSchemes`、`.github/workflows/dsh-ios.yml` 里的 `-scheme` 与 `NcnsDSH.app`、`codemagic.yaml` 同两处、README 标题。

---

## 2. 视觉基调：抄什么、不抄什么

**从 tv 抄**：近黑底色（#0B0B0F，不用纯黑）、hero billboard + 底部渐变 scrim、横向 shelf（卡片 16:9 与 2:3 两种）、大标题 32–34pt、右上角玻璃「全部」胶囊、点卡片 zoom 进详情、滚动时 tab bar 收成 mini。

**从 Apple Music 抄**：用封面主色生成页面渐变（`ColorExtractor` 取 artwork 主色 → 顶部 20% 透明度渐隐）、底部 mini player 胶囊（这里是「运行中会话」）、Now Playing 式全屏详情、`spring` 动效、长按 context menu、播放/暂停键的形变。

**不要抄**：Apple Music 的品牌红、tv 的 logo、真实的专辑/影片内容；也不要把系统 TabView 做成自定义 tab bar（先用系统 `.tabBarMinimizeBehavior`）。

**NcnsDSH 自己的识别色**：靛蓝 `#5B8CFF` → 薄荷 `#57E0B8` 的双色渐变，只出现在 hero、运行状态、发送键三处。

---

## 3. 主提示词（先粘这一条，定全局）

> 你是 iOS 26 设计语言专家兼 SwiftUI 工程师。把现有 `ios-dsh`（SwiftUI + WKWebView 壳，显示名 DSH）重构为 **NcnsDSH**：一个原生数据客户端。视觉参照 tv 的暗色影院式首页与 Apple Music 的 artwork 驱动详情页，材质用 iOS 26 Liquid Glass。
>
> **硬约束**
> 1. 会话、会话列表、审批、设置全部原生；WKWebView 只保留「插件页 / 终端 / 文件预览」三个兜底入口，从主 Tab 移除。
> 2. 数据层接 `dsh-plugin-mobile-gateway` 的 WebSocket 协议，不要自造 RPC，不要用 WebView 里的 DOM 取数据。
> 3. 玻璃只用在 **chrome**（tab bar、toolbar、mini player、浮层按钮、审批 sheet）和**可交互卡片按下态**；**不要**给消息气泡、列表行、滚动内容加玻璃。
> 4. 动效只用 spring（`.spring(response: 0.35, dampingFraction: 0.82)`）或 `.smooth`，时长 0.25–0.45s；滚动中不触发逐帧动画。
> 5. 无障碍：Reduce Transparency → 玻璃退化为 `.regularMaterial` 不透明面板；Reduce Motion → 把 zoom/形变换成 `.opacity`；动态字体到 AX3 不破版。
> 6. 性能预算：冷启动 < 1.2s 到首屏；常驻内存 < 180MB；滚动 120fps；流式消息合并到 ≤ 30 次/秒刷新。
> 7. 列表一律 `LazyVStack`/`List` + 稳定 id；图片走统一 `ArtworkStore`（内存 + 磁盘两级，下采样到显示尺寸 ×2）。
> 8. 先交可运行的最小闭环（Mock 数据也能跑），再逐个替换真实数据源；每个文件不超过 400 行，超过就拆。
>
> **交付**：文件清单、每个文件的关键实现、一段 30 秒能跑起来的 Mock 首页 + 会话页，以及一份「哪里用了玻璃、为什么」的清单。

---

## 4. 分屏提示词

### 4.1 启动 / 配对页

> 做一个「影院开场」式的配对页：整屏近黑，背景是一层极慢移动的靛蓝→薄荷径向光斑（`TimelineView` 驱动，周期 18s，`Reduce Motion` 时静止）。
>
> 居中偏上是 64pt 的 NcnsDSH 标记（圆角 18、双色渐变、`>_` 字符），下方 34pt 粗体标题、15pt 灰色副标题。再往下是一张玻璃卡片，装地址与 token 两个字段（`.glassEffect(.regular, in: .rect(cornerRadius: 20))`，输入聚焦时变成 `.regular.tint(accent).interactive()`）。
>
> 主按钮「连接」用 `.buttonStyle(.glassProminent)`；「扫描二维码」是同一 `GlassEffectContainer` 里的次级玻璃胶囊，两个按钮的玻璃在按下时**互相融合**（`GlassEffectContainer(spacing: 12)` + `glassEffectID`）。
>
> 扫码页：相机预览上盖一个 240×240 的玻璃取景框，扫到码的瞬间取景框收缩成一个点再弹开（spring，0.4s），触感 `.success`。
>
> 验收：键盘弹出时按钮上移不被遮挡；错误只在字段下方出现，不弹 alert。

### 4.2 首页（Shell）—— 最像 tv 的一屏

> 四个 Tab：**会话 / 工作区 / 定时 / 设置**，`TabView` + `Tab(role: .search)` 放搜索。滚动时 `.tabBarMinimizeBehavior(.onScrollDown)`，回到顶部自动展开。
>
> 首屏是 `ScrollView` + `LazyVStack`，从上到下：
> 1. **Hero**：最近活跃会话。16:9 画面（没有真封面就用「会话首字母 + 双色渐变 + 细噪点」生成），底部 40% 高的黑色渐变 scrim，压 34pt 粗体标题、15pt 次要信息（工作区 · 最后活动时间）、一行两个玻璃按钮「继续」与「新会话」。整块高度 = 屏宽 × 0.78。
> 2. **Shelf「继续」**：横向卡片 280×180、圆角 20、间距 12；卡片底部一条 2pt 进度条（这一轮已经跑了多少步）；点按 → `.navigationTransition(.zoom(sourceID:in:))` 进会话。
> 3. **Shelf「工作区」**：竖版 poster 160×200，标题压在底部，右上角状态点（有任务在跑 = 薄荷色脉冲）。
> 4. **Shelf「最近完成」**：60×60 缩略 + 两行文字的行式卡片，密度高一点。
> 每组之间 28pt，组标题 20pt semibold，右侧一个玻璃「全部」胶囊（`.buttonStyle(.glass)`，小号）。
>
> 卡片本身**不要**常驻玻璃：只在按下/聚焦时覆盖一层 `.glassEffect(.regular.interactive(), in: .rect(cornerRadius: 20))`，让高光扫过去。长按 `contextMenu`：置顶、归档、复制链接。
>
> 空状态：不要写「暂无数据」，用一句「还没有会话。说一句话，它就开始干活。」+ 一个大玻璃按钮。

### 4.3 会话页（Chat）

> 顶栏：返回、会话标题（滚动后收成 17pt inline）、右侧状态点 + 「更多」。工具栏用系统玻璃背景，自己**不要**再叠一层。
>
> 消息流 `ScrollViewReader` + `LazyVStack`：
> - 用户消息：右对齐，最大宽度 78%，背景是 accent 10% 的圆角块（不是气泡尾巴）。
> - 助手消息：全宽，Markdown 渲染；代码块用等宽字体 + 可横向滚动 + 右上角玻璃「复制」小按钮。
> - 工具调用：一行折叠卡（图标 / 名称 / 耗时 / 状态），展开显示参数与输出；运行中用一条 1.5pt 的流光从左扫到右（`TimelineView`，2s 循环），**不要**无限旋转的 spinner。
> - 审批/提问：不是 alert，是从底部升起的玻璃 sheet（`.presentationDetents([.medium, .large])` + `.presentationBackground(.clear)`，内容自己玻璃化），两个按钮「允许」`.glassProminent`、「拒绝」`.glass`。
>
> 流式：token 增量合并到 30Hz 刷新；只有当用户停在底部时才自动跟滚（用 `scrollPosition` 判断），否则显示「回到底部」的玻璃小胶囊。
>
> 输入区：`GlassEffectContainer` 里的胶囊输入条，左附件、右发送；发送键 `.buttonStyle(.glassProminent)`，无文字时降级为灰色玻璃；长按麦克风开始录音，胶囊高度从 52 → 76，波形在玻璃里起伏（`glassEffectID` 做形变，不要换视图）。
>
> 验收：100 条消息滚动不掉帧；流式输出时不抢滚动位置；键盘弹出时最后一条消息可见。

### 4.4 「运行中」Dock（学 Apple Music 的 mini player）

> 离开会话后，底部浮一条 56pt 的玻璃胶囊：左侧 28×28 的会话标记，中间标题 + 当前动作（「正在读文件…」），右侧一个 2pt 的环形进度或脉冲点。点它 → zoom 回会话。
>
> 多个会话同时跑时，胶囊能展开成 `GlassEffectContainer` 里的一排小胶囊（最多 3 个 + 「+2」），展开动画用 `glassEffectID` 做形变，不要用 sheet。
>
> 没有任务在跑时整条淡出（`.opacity` + spring），不要留空条。

### 4.5 设置

> 用 `List` + `.listStyle(.insetGrouped)`，但背景换成近黑，分组标题小写灰字。每组是一张圆角卡片（`Color.white.opacity(0.06)`），不要每行都玻璃。
>
> 顶部是「宿主」卡片：图标、地址、连接状态点、「重新配对」玻璃按钮。下面是 模型 / 外观 / 通知 / 关于 四组。危险操作（移除宿主）放最底，红色文字，二次确认用 confirmationDialog。

### 4.6 iPad

> `NavigationSplitView` 三栏：侧栏（会话列表，玻璃 toolbar）｜会话（主体）｜右侧检查器（工具输出/文件）。窗口宽度 < 700pt 时自动收成一栏，和 iPhone 共用同一套视图。

### 4.7 小组件 + 灵动岛

> 主屏小组件：中等尺寸，显示「运行中的会话」标题 + 当前工具 + 状态点，背景用 `containerBackground(for: .widget)` 的渐变。锁定屏小组件用同一份快照。
> 灵动岛：`ActivityKit`，紧凑态只显示状态点 + 会话首字，展开态显示当前工具与耗时；结束态停留 4 秒。

---

## 5. 动效与可交互性清单

| 触发 | 效果 | 参数 |
|---|---|---|
| 点会话卡 | zoom 转场进会话 | `.navigationTransition(.zoom(sourceID:in:))`，系统默认曲线 |
| 按下卡片 | 玻璃高光扫过 + 轻微放大 | `scaleEffect(0.98 → 1.0)`，`.spring(response: 0.3, damping: 0.7)` |
| Tab 切换 | 图标形变 + 玻璃背景滑动 | 系统 TabView，不自定义 |
| 滚动首页 | tab bar 收成 mini | `.tabBarMinimizeBehavior(.onScrollDown)` |
| 发送消息 | 输入条收缩、消息从底部升起 | `.spring(response: 0.4, damping: 0.85)` |
| 工具开始/结束 | 流光扫过 → 状态点变色 | `TimelineView` 2s 循环；结束用 `.success` 触感 |
| 审批 sheet | 从底部升起 + 背景变暗 | `.presentationDetents` + `.presentationBackground(.clear)` |
| 扫码成功 | 取景框收缩再弹开 | spring 0.4s + `.success` 触感 |
| 新建会话 | 空白页淡入 + 输入条聚焦 | `.opacity` 0.2s，键盘自动弹出 |

**规则**：所有交互动效都能被 `Reduce Motion` 降级；不做 3D 翻转、不做视差滚动、不做逐帧抖动。

---

## 6. 性能预算与手段

| 指标 | 预算 | 手段 |
|---|---|---|
| 冷启动到首屏 | < 1.2s | 首屏只读缓存快照，网络请求延后 200ms |
| 常驻内存 | < 180MB | 图片下采样 + `NSCache` 上限 64MB；消息只保留最近 300 条渲染态 |
| 滚动 | 120fps | `LazyVStack` + 固定行高；玻璃只在 chrome |
| 流式刷新 | ≤ 30 次/秒 | token 缓冲 + `Task.sleep(33ms)` 合并 |
| Markdown | 每条消息只解析一次 | 缓存 `AttributedString`，按内容哈希 |
| 玻璃数量 | 同屏 ≤ 6 个 glass 元素 | 全部进 `GlassEffectContainer`，共用 `@Namespace` |
| 网络 | 断线自动重连 | 指数退避 1s→30s，前台恢复立即重连 |

---

## 7. 功能扩容（学这些项目，按优先级）

| 优先级 | 功能 | 抄谁 |
|---|---|---|
| P0 | 会话列表 + 搜索 + 置顶/归档 | Whaleness |
| P0 | 流式对话 + 工具卡 + 审批 + 问答 | Whaleness / mobile-gateway |
| P0 | 图片/文件上传（分片、进度、重试） | mobile-gateway `file-upload-v1` |
| P1 | 工作区文件浏览 + 代码高亮 | fish-pocket 工作台 |
| P1 | 子 agent / 团队视图 | Whaleness Agent Teams |
| P1 | 定时任务 | fish-pocket Schedule |
| P1 | 语音输入 + 朗读 | fish-pocket |
| P2 | 小组件 / 灵动岛 / Live Activity | fish-pocket |
| P2 | 远程多宿主（含 P2P 通道） | ds-harness-remote |
| P2 | iPad 多窗口 | fish-pocket |

---

## 8. 验收清单

- [ ] 冷启动到首页可交互 ≤ 1.2s（真机，非模拟器）
- [ ] 100 条消息的会话连续滚动 10 秒不掉帧（Instruments 看不到 `hitch`）
- [ ] 流式回复时手动上滑，不被强行拉回底部
- [ ] 审批 sheet 在 Reduce Transparency 下仍是可读的不透明面板
- [ ] 动态字体 AX3 + 竖屏 320pt 宽度不横向滚动
- [ ] 断开 Wi-Fi 后 30 秒内自动重连，期间不弹 alert
- [ ] 同屏玻璃元素 ≤ 6 个，`GlassEffectContainer` 覆盖率 100%
- [ ] 所有列表 id 稳定，插入新消息不整列表重建

---

## 9. 反模式（模型最容易做错的）

1. 给每个 View 都加 `.glassEffect()` —— 又慢又花。
2. 用 `.blur` + `.opacity` 手搓玻璃，或者给 WKWebView 套玻璃。
3. 消息气泡也用玻璃 —— 文字对比度会掉到不可读。
4. `ScrollView` 里再套 `ScrollView`（横向 shelf 用 `LazyHStack`，外面别再包一层）。
5. 用 `UUID()` 当 `ForEach` 的 id。
6. 每收到一个 token 就重排整段 Markdown。
7. 用无限旋转的 `ProgressView` 表示工具在跑（用流光 + 状态点）。
8. 暗色里用纯黑 #000 和纯白 #FFF。
9. 照搬 Apple Music 的红色当强调色。
10. 自定义 tab bar 去模仿系统玻璃（先用系统 API，不够再说）。
11. 忽略 Reduce Motion / Reduce Transparency。
12. 做假的进度条（进度必须来自真实 turn 状态）。
