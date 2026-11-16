# 把 OpenWorld 官网发布到 GitHub Pages

这份教程从“本地已经有 `openworld-site` 文件夹”开始，到拿到一个公开 URL 为止。全程不需要服务器、不需要数据库，也不需要改代码。

---

## 0. 你会得到什么

发布后地址形如：

```text
https://<你的GitHub用户名>.github.io/openworld-site/
```

仓库里包含：

- 静态站点：`index.html`、`styles.css`、`app.js`
- App 图标 / 影片 / 截图：`assets/`
- 可下载的未签名 IPA：`assets/downloads/iOSHub-3.2.1-unsigned.ipa`
- 自动部署工作流：`.github/workflows/deploy.yml`
- SHA-256：`assets/downloads/SHA256.txt`

> `iOSHub 3.2.1` 是未签名 IPA，只能通过 SideStore / AltStore / Sideloadly 等工具安装；不是 App Store 包。官网已经标注了这一点。

---

## 1. 先在本地验收

在终端执行：

```bash
cd /home/dsh/Documents/deepseek-harness/default-workspace/openworld-site
python3 -m http.server 4174
```

浏览器打开：

```text
http://127.0.0.1:4174
```

重点检查四件事：

1. Hero 区 App 预览的五个页签可以点击。
2. Discover 搜索、筛选、项目详情可以打开。
3. Downloads 里 IPA 能下载，SHA-256 复制按钮正常。
4. 手机宽度下导航、项目卡、对比表没有横向溢出。

确认没问题再发布。

---

## 2. 创建 GitHub 仓库

### 方式 A：网页创建（推荐第一次使用）

1. 登录 GitHub。
2. 右上角 `+` → **New repository**。
3. 填写：
   - **Repository name**：`openworld-site`
   - **Description**：`OpenWorld product site`
   - **Visibility**：Public（GitHub Pages 免费版需要公开仓库）
   - **Initialize this repository with**：全部不勾
     - 不要加 README
     - 不要加 .gitignore
     - 不要加 license
4. 点 **Create repository**。
5. 复制页面上的仓库地址，例如：

```text
https://github.com/你的账号/openworld-site.git
```

### 方式 B：GitHub CLI

安装 `gh` 后：

```bash
gh auth login
gh repo create openworld-site --public --source=. --remote=origin --push
```

如果本地还没有 git 仓库，先执行第 3 节。

---

## 2.5 不想用命令行：GitHub Desktop / 网页上传

### GitHub Desktop（推荐给不熟悉终端的人）

1. 安装 GitHub Desktop，登录 GitHub。
2. **File → Add local repository**，选择 `openworld-site` 文件夹。
3. 如果提示 “not a Git repository”，点 **create a repository**，名字填 `openworld-site`。
4. 左下角填写 commit message，点 **Commit to main**。
5. 右上角 **Publish repository**：
   - Name：`openworld-site`
   - 取消勾选 **Keep this code private**
   - Publish。
6. 之后每次改完：Commit → Push origin。

### 网页上传（完全不装 Git）

1. 先在 GitHub 创建空仓库 `openworld-site`。
2. 仓库页 → **Add file → Upload files**。
3. 把 `openworld-site` 里面的**所有内容**拖进去：
   - `index.html`
   - `styles.css`
   - `app.js`
   - `404.html`
   - `robots.txt`
   - `site.webmanifest`
   - `.nojekyll`
   - `assets/` 整个文件夹
   - `.github/` 整个文件夹
4. 注意不要只上传 `index.html`，否则图片、IPA、工作流都会缺。
5. Commit changes。
6. 网页上传单文件上限 25 MB，IPA 只有 3.9 MB，没问题；文件总数不要超过 100 个。

> 网页上传不会带上 `.git`，但 `.github/workflows/deploy.yml` 会一起上传，Pages 仍然可用。

---

## 3. 把本地文件推到仓库

### 如果你拿到的是完整文件夹（含 `.git`）

当前这份 `openworld-site` 已经初始化过 `main` 分支并提交过：

```bash
cd /home/dsh/Documents/deepseek-harness/default-workspace/openworld-site
git status
git log --oneline -5
```

添加远程仓库并推送：

```bash
git remote add origin https://github.com/你的账号/openworld-site.git
git branch -M main
git push -u origin main
```

如果已经存在 `origin`：

```bash
git remote set-url origin https://github.com/你的账号/openworld-site.git
git push -u origin main
```

### 如果你拿到的是普通文件夹（没有 `.git`）

```bash
cd /path/to/openworld-site
git init -b main
git add .
git commit -m "Initial OpenWorld site"
git remote add origin https://github.com/你的账号/openworld-site.git
git push -u origin main
```

### 推送时要求登录

GitHub 已经不支持账号密码 push，用 **Personal Access Token** 当密码。

用户名填 GitHub 用户名，密码填 token。

---

## 4. 创建 Personal Access Token（PAT）

1. GitHub 右上角头像 → **Settings**。
2. 左侧最下方 → **Developer settings**。
3. **Personal access tokens** → **Fine-grained tokens**。
4. **Generate new token**。
5. 填写：
   - **Token name**：`openworld-site-deploy`
   - **Expiration**：7 days（发布完即可撤销）
   - **Resource owner**：你的账号
   - **Repository access**：Only select repositories → `openworld-site`
   - **Permissions**：
     - **Contents**：Read and write（推送站点文件）
     - **Workflows**：Read and write（仓库里有 `.github/workflows/deploy.yml`，没有这个权限 GitHub 会拒绝推送 workflow 文件）
     - **Pages**：Read and write（可选；如果想让脚本直接开启 Pages，否则在网页里手动开）
     - **Metadata**：Read-only（自动带）
6. 生成后复制 token，只显示一次。

推送：

```bash
git push -u origin main
# Username: 你的GitHub用户名
# Password: 粘贴 token，不会显示字符
```

发布完成后到同一页面 **Revoke** 这个 token。

> 不要把 token 写进 `README`、`app.js`、远程 URL 或截图里。  
> 如果 token 曾经出现在终端历史中，发布完成后撤销并重新生成。

---

## 5. 开启 GitHub Pages

静态站有两条路，任选一条。

### 路线 A：最简单，直接发布分支（推荐）

1. 打开仓库 → **Settings → Pages**。
2. **Build and deployment → Source** 选 **Deploy from a branch**。
3. **Branch** 选 `main`，目录选 **/(root)**，点 **Save**。
4. 等 1–2 分钟，Pages 页面会显示 URL：

```text
https://你的账号.github.io/openworld-site/
```

这条路线不需要 Actions，哪怕网页上传时漏了 `.github/` 也能发布。

### 路线 B：使用仓库里的自动部署工作流

1. **Settings → Pages → Source** 选 **GitHub Actions**。
2. 打开仓库顶部 **Actions** 标签。
3. 看到 **Deploy OpenWorld site** 工作流：
   - 首次 push 会自动触发。
   - 如果没有触发，点 **Run workflow** → `main` → **Run workflow**。

工作流做三件事：

```text
checkout → 把静态文件复制到 _site → upload-pages-artifact → deploy-pages
```

绿色勾出现后，Pages 页面会显示：

```text
https://你的账号.github.io/openworld-site/
```

---

## 6. 验证线上站点

打开线上 URL，检查：

- [ ] 首页 Hero、App 预览正常
- [ ] 60 秒影片能播放，字幕出现
- [ ] 下载按钮返回 200，文件大小 3,986,640 bytes
- [ ] SHA-256 与 `675247dce3d4213b3321ff171df664c5c49c98e7ca91d51bfe6814f46ac2c32b` 一致
- [ ] 手机 Safari / Chrome 打开正常
- [ ] 刷新任意锚点（如 `/#discover`）不 404

如果页面 404，先看第 9 节。

---

## 7. 以后怎么更新

改完文件后：

```bash
cd /home/dsh/Documents/deepseek-harness/default-workspace/openworld-site
git add .
git commit -m "Update copy"
git push
```

工作流会自动重新发布，通常 1–2 分钟。

注意：工作流里的 `Stage site` 明确复制了这些路径：

```text
index.html styles.css app.js 404.html robots.txt site.webmanifest .nojekyll assets
```

如果新增了顶层文件（例如 `favicon.ico`、新的 `docs/`），要同步加进 `.github/workflows/deploy.yml` 的 `cp` 命令，否则线上不会更新。

---

## 8. 可选：绑定自己的域名

1. 在仓库根目录新建 `CNAME`，内容只要一行：

```text
openworld.example.com
```

2. 域名 DNS 添加：

```text
CNAME   openworld   <你的账号>.github.io
```

3. 回到 GitHub：**Settings → Pages → Custom domain** 填入域名。
4. 等 DNS 生效后勾选 **Enforce HTTPS**。
5. 如果使用 apex 域名（`example.com`），用 A 记录指向 GitHub Pages 的四个 IP，或使用 ALIAS/ANAME。

---

## 9. 常见问题

### 页面 404

- Pages 的 Source 是否选了 **Deploy from a branch** 或 **GitHub Actions**？
- 选分支时，Branch 是否是 `main`、目录是否是 `/(root)`？
- 选 Actions 时，工作流是否成功？
- 推送的是不是 `main` 分支？
- 仓库是否是 Public（免费账户）？
- 工作流 `path` 是否是 `_site`？

### CSS / 图片 404

站点全部使用相对路径，正常放在仓库根目录即可。不要单独把 `index.html` 上传到别的目录。

### IPA 下载失败

- 文件是 3.9 MB，GitHub 限制单文件 100 MB，没问题。
- iOS Safari 可能把 `.ipa` 当未知文件；用桌面浏览器或支持下载的 App 打开。
- 未签名 IPA 不能直接安装，需要 SideStore / AltStore / Sideloadly。
- 如果不想公开托管 IPA，删除 `assets/downloads/iOSHub-3.2.1-unsigned.ipa`，把下载按钮改成 GitHub Releases 链接。

### Actions 报 `Resource not accessible by integration`

检查 `.github/workflows/deploy.yml` 顶部：

```yaml
permissions:
  contents: read
  pages: write
  id-token: write
```

并确认仓库 **Settings → Actions → General → Workflow permissions** 允许读取。

### 推送被拒绝

如果远程仓库创建时勾选了 README，先拉取合并：

```bash
git pull --rebase origin main
git push -u origin main
```

### Token 泄漏

立刻到 GitHub **Settings → Developer settings → Personal access tokens** 撤销，重新生成；不要试图只删掉某次 commit。

---

## 10. 最短路径（复制即可）

如果你只想跑通一次：

```bash
cd /home/dsh/Documents/deepseek-harness/default-workspace/openworld-site

# 1. 创建远程仓库后
git remote add origin https://github.com/你的账号/openworld-site.git
git branch -M main
git push -u origin main

# 2. 到 GitHub 仓库 Settings → Pages → Source: GitHub Actions
# 3. 到 Actions 看 Deploy OpenWorld site 是否变绿
# 4. 打开 https://你的账号.github.io/openworld-site/
```

---

## 11. 当前仓库状态

```text
branch: main
remote: 尚未配置
workflow: .github/workflows/deploy.yml
site root: openworld-site/
download: assets/downloads/iOSHub-3.2.1-unsigned.ipa
sha256: 675247dce3d4213b3321ff171df664c5c49c98e7ca91d51bfe6814f46ac2c32b
```
