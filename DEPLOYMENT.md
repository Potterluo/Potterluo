# 部署指南

本文档介绍如何将 Keriko 播客部署到各种平台。

## 📋 部署前准备

1. 确保已安装 Hugo Extended >= 0.122.0
2. 测试本地构建：`hugo`
3. 准备好音频文件（建议放在 `static/audio/` 目录）

## 🚀 部署到 Gitee Pages

### 步骤 1：构建网站

```bash
hugo
```

这会生成 `public/` 目录，包含所有静态文件。

### 步骤 2：提交到 Gitee

```bash
git add .
git commit -m "Deploy: 更新内容"
git push origin master
```

### 步骤 3：配置 Gitee Pages

1. 登录 Gitee，进入你的仓库
2. 点击 "服务" → "Gitee Pages"
3. 选择部署分支：`master`
4. 部署目录：`public`
5. 点击 "启动"

等待几分钟，你的网站就会在 `https://你的用户名.gitee.io/仓库名` 上线。

### 自动部署（推荐）

使用 Gitee Actions 自动构建和部署：

创建 `.gitee/workflows/deploy.yml`：

```yaml
name: Deploy to Gitee Pages

on:
  push:
    branches: [ master ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          submodules: true

      - name: Setup Hugo
        uses: peaceiris/actions-hugo@v2
        with:
          hugo-version: 'latest'
          extended: true

      - name: Build
        run: hugo --minify

      - name: Deploy
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./public
```

## 🌐 部署到 GitHub Pages

### 步骤 1：构建网站

```bash
hugo
```

### 步骤 2：推送到 GitHub

```bash
git remote add github https://github.com/keriko/keriko.git
git push github master
```

### 步骤 3：配置 GitHub Pages

1. 进入仓库 Settings
2. 找到 "Pages" 部分
3. Source 选择：Deploy from a branch
4. Branch 选择：master / public
5. Save

### 使用 GitHub Actions 自动部署

创建 `.github/workflows/deploy.yml`：

```yaml
name: Deploy to GitHub Pages

on:
  push:
    branches: [ master ]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v3
        with:
          submodules: true

      - name: Setup Hugo
        uses: peaceiris/actions-hugo@v2
        with:
          hugo-version: 'latest'
          extended: true

      - name: Build
        run: hugo --minify

      - name: Deploy
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./public
```

## 📦 部署到 Netlify

### 方法 1：通过 Git 连接

1. 登录 [Netlify](https://netlify.com)
2. 点击 "New site from Git"
3. 选择 Gitee 或 GitHub
4. 选择你的仓库
5. 构建配置：
   - Build command: `hugo`
   - Publish directory: `public`
6. 点击 "Deploy site"

### 方法 2：手动部署

```bash
# 安装 Netlify CLI
npm install -g netlify-cli

# 登录
netlify login

# 初始化
netlify init

# 部署
netlify deploy --prod
```

## ⚡ 部署到 Vercel

### 使用 Vercel CLI

```bash
# 安装 Vercel CLI
npm install -g vercel

# 登录
vercel login

# 部署
vercel --prod
```

### 配置文件 `vercel.json`

```json
{
  "buildCommand": "hugo",
  "outputDirectory": "public",
  "installCommand": "echo 'No install needed'"
}
```

## 🐳 使用 Docker 部署

创建 `Dockerfile`：

```dockerfile
FROM alpine:latest

ARG HUGO_VERSION=0.122.0
ADD https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-amd64.tar.gz /tmp/hugo.tar.gz

RUN tar xzf /tmp/hugo.tar.gz -C /tmp && \
    mv /tmp/hugo /usr/bin/hugo && \
    rm /tmp/hugo.tar.gz

WORKDIR /site
COPY . .

RUN hugo --minify

FROM nginx:alpine
COPY --from=0 /site/public /usr/share/nginx/html
EXPOSE 80
```

构建和运行：

```bash
docker build -t keriko-podcast .
docker run -p 80:80 keriko-podcast
```

## 📊 性能优化建议

### 1. 启用资源指纹

在 `config/_default/hugo.yaml` 中：

```yaml
minify:
  minifyOutput: true
```

### 2. 压缩音频文件

使用 Audacity 或 ffmpeg 压缩音频：

```bash
ffmpeg -i input.wav -b:a 64k output.mp3
```

### 3. 使用 CDN

将静态资源上传到 CDN，修改 `config/_default/params.yaml`：

```yaml
cdn: "https://your-cdn.com"
```

### 4. 启用缓存

在 `static/` 目录创建 `_headers` 文件（Netlify）：

```
/*.mp3
  Cache-Control: public
  max-age=31536000

/css/*
  Cache-Control: public
  max-age=604800
```

## 🔍 部署后检查清单

- [ ] 首页正常显示
- [ ] 所有节目可以播放
- [ ] RSS 订阅有效
- [ ] 图片加载正常
- [ ] 移动端显示正常
- [ ] 深色模式工作
- [ ] 所有链接有效
- [ ] SEO 元标签正确

## 📈 监控和分析

### 集成 Google Analytics

在 `config/_default/params.yaml` 中添加：

```yaml
analytics:
  google:
    id: "G-XXXXXXXXXX"
```

### 集成百度统计

在 `layouts/partials/head.html` 中添加百度统计代码。

## 🔐 安全建议

1. **限制目录访问**：确保不会暴露敏感文件
2. **HTTPS**：强制使用 HTTPS
3. **备份**：定期备份 content 目录
4. **子模块**：定期更新主题子模块

## 🆘 常见问题

**Q: 构建失败怎么办？**
A: 检查 Hugo 版本，确保使用 Extended 版本。

**Q: 音频文件太大怎么办？**
A: 使用更低比特率重新编码，或考虑使用外部音频托管服务。

**Q: RSS 订阅不工作？**
A: 检查 `config/_default/hugo.yaml` 中的 outputFormats 配置。

## 📞 需要帮助？

如果遇到问题，请：
1. 查看 [Hugo 文档](https://gohugo.io/)
2. 查看 [Qubt 主题 Wiki](https://github.com/chrede88/qubt/wiki)
3. 提交 [Issue](https://gitee.com/keriko/keriko/issues)

---

祝你部署顺利！🎉
