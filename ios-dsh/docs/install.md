# 怎么把它装到手机上

分两条：**今天就能用**的 PWA，和**需要一次构建**的 IPA。

## A. 现在就能用：主屏幕 Web App

不需要构建、不需要签名，Safari 直接装：

1. 电脑上 `dsh web --host <局域网地址>`；
2. 手机 Safari 打开打印出来的地址（带 token）；
3. 分享 → **添加到主屏幕**。

DSH 的 Web 端本来就带 `manifest.webmanifest`、`apple-touch-icon` 和
`mobile-web-app-capable`，加到主屏幕后是全屏、没有地址栏，图标也是官方的。

这条路的限制：没有原生连接页、token 存在浏览器里、没有扫码、没有原生文件选择/下载分享。
这些正是 `ios-dsh/` 那个原生壳补的。

## B. 出 IPA

### B1. 有 Mac（最稳）

```sh
cd ios-dsh
brew install xcodegen     # 只需一次
./build-ipa.sh            # 产出 DSH-unsigned.ipa + SHA256.txt
```

### B2. Codemagic（没有 Mac，但要有 Codemagic 账号）

仓库根目录的 `codemagic.yaml` 里已经加好 `dsh-ios-unsigned-ipa`：
登录 codemagic.io → 连接 `NevercRyNow/openworld` → 选这个 workflow → Start build，
产物在 Artifacts 里。

### B3. GitHub Actions（当前拿不到 macOS runner）

`.github/workflows/dsh-ios.yml` 已经写好，逻辑和 OpenWorld 那个 IPA workflow 一样。
但实测：`macos-15` / `macos-latest` 的 job 排队 **15 分钟仍分配不到机器，然后被 GitHub 取消**
（2026-11-16 这一晚连续 3 次）。ubuntu 的 job 正常，所以不是仓库配置问题，是 macOS runner 容量/配额。

能确认 runner 恢复后，直接：

```sh
gh workflow run dsh-ios.yml     # 或网页 Actions → Build DSH iOS IPA → Run workflow
```

### 安装

无签名 IPA 需要自己签一次再装：

- **Sideloadly**（Windows/macOS，免费 Apple ID 可签，7 天有效）
- **AltStore / SideStore**
- **TrollStore**（系统版本支持的话，永久签名）

装好后第一次打开：粘贴 `dsh web` 打印的地址（token 会自动拆出来），或扫码。

## 排错

配对失败先用命令行确认宿主这一侧是好的：

```sh
node tools/probe-host.mjs http://192.168.1.8:3080 --token <token>
```

- `401` —— token 已经用过了（它是一次性的，换 cookie 用），或者宿主重启过；回电脑重新拿地址。
- `403` —— Host 不在信任列表：`--host` 要用电脑自己的局域网地址，或在启动时加 `--trusted-host`。
- 连不上 —— 检查同一个 Wi-Fi、防火墙、以及 `dsh web` 是不是还开着。
