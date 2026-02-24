---
title: "Hugo 入门指南：从零开始搭建静态博客"
date: 2024-02-24
draft: false
description: "详细介绍如何使用 Hugo 静态站点生成器搭建个人博客"
tags:
  - Hugo
  - 静态站点
  - 教程
categories:
  - 技术分享
---

# Hugo 入门指南

## 什么是 Hugo？

[Hugo](https://gohugo.io/) 是一个用 Go 语言编写的快速、现代化的静态站点生成器。它非常适合用来搭建博客、文档站点、作品集等。

<!--more-->

### Hugo 的优势

- ⚡ **极速构建**：毫秒级构建速度
- 🎯 **简单易用**：配置简单，上手容易
- 🔧 **功能强大**：支持丰富的主题和自定义
- 🌐 **跨平台**：支持 Windows、macOS、Linux
- 📦 **零依赖**：单个可执行文件，无需额外依赖

## 安装 Hugo

### Windows

使用 Chocolatey：

```powershell
choco install hugo-extended
```

### macOS

使用 Homebrew：

```bash
brew install hugo
```

### Linux

使用 Snap：

```bash
snap install hugo
```

验证安装：

```bash
hugo version
```

应该显示 `hugo v0.x.x extended` 或更高版本。

## 创建第一个 Hugo 站点

### 1. 创建新站点

```bash
hugo new site my-blog
cd my-blog
```

### 2. 添加主题

Hugo 有很多优秀的主题。可以在 [themes.gohugo.io](https://themes.gohugo.io/) 浏览。

使用 Git 子模块添加主题：

```bash
git init
git submodule add https://github.com/chrede88/qubt.git themes/qubt
```

### 3. 配置主题

复制主题的示例配置：

```bash
cp -a themes/qubt/exampleSite/config ./config
```

或手动创建 `config/_default/hugo.yaml`：

```yaml
baseURL: 'https://example.com/'
languageCode: 'zh-CN'
title: '我的博客'
theme: 'qubt'
```

### 4. 创建第一篇文章

```bash
hugo new blog/my-first-post.md
```

编辑这个 Markdown 文件：

```markdown
---
title: "我的第一篇文章"
date: 2024-02-24
draft: false
---

# 欢迎来到我的博客

这是我的第一篇文章...
```

### 5. 启动开发服务器

```bash
hugo server -D
```

访问 http://localhost:1313 查看网站。

## Hugo 项目结构

```
my-blog/
├── archetypes/         # 内容模板
├── assets/            # 资源文件（CSS、JS）
├── config/            # 配置文件
│   └── _default/
├── content/           # 网站内容
│   ├── blog/         # 博客文章
│   └── about.md      # 关于页面
├── data/              # 数据文件
├── layouts/           # 自定义布局
├── static/            # 静态资源（图片、字体）
├── themes/            # 主题文件
└── hugo.yaml          # 主配置文件
```

## 内容管理

### Front Matter

每个 Markdown 文件都需要 Front Matter（元数据）：

```yaml
---
title: "文章标题"
date: 2024-02-24
draft: false        # 是否为草稿
description: "文章描述"
tags:
  - Hugo
  - 教程
categories:
  - 技术分享
---
```

### 内容组织

```
content/
├── blog/              # 博客文章
│   ├── post-1.md
│   └── post-2.md
├── about.md          # 关于页面
└── _index.md         # 首页
```

## 构建和部署

### 本地构建

```bash
hugo
```

生成静态文件到 `public/` 目录。

### 部署到 GitHub Pages

1. 将 `public/` 目录推送到 `gh-pages` 分支
2. 或使用 GitHub Actions 自动部署

### 部署到 Gitee Pages

1. 构建网站：`hugo`
2. 推送到 Gitee 仓库
3. 在仓库设置中启用 Gitee Pages

## 常用命令

```bash
# 创建新内容
hugo new blog/post-title.md

# 启动开发服务器（包含草稿）
hugo server -D

# 构建生产版本
hugo

# 构建并最小化
hugo --minify

# 清理构建文件
hugo --cleanDestinationDir
```

## 进阶技巧

### 1. 自定义主题

在 `assets/css/custom.css` 中添加自定义样式：

```css
/* 自定义样式 */
body {
  font-family: 'Your Font', sans-serif;
}
```

### 2. 添加短代码

在 `layouts/shortcodes/` 目录创建自定义短代码。

### 3. 配置 Taxonomy

在 `config/_default/hugo.yaml` 中配置分类法：

```yaml
taxonomies:
  tag: tags
  category: categories
  series: series
```

### 4. 启用评论

集成 Disqus、Giscus 或其他评论系统。

## 资源和参考

- 📖 [Hugo 官方文档](https://gohugo.io/documentation/)
- 🎨 [Hugo 主题](https://themes.gohugo.io/)
- 💬 [Hugo 论坛](https://discourse.gohugo.io/)
- 📺 [Hugo 视频教程](https://www.youtube.com/results?search_query=hugo+tutorial)

## 总结

Hugo 是一个强大而易用的静态站点生成器。通过本指南，你应该能够：

- ✅ 安装和配置 Hugo
- ✅ 创建和管理内容
- ✅ 使用和定制主题
- ✅ 构建和部署网站

开始你的 Hugo 之旅吧！🚀

---

*更新于 2024年2月24日*
