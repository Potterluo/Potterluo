---
title: "Hugo 静态站点生成器入门"
date: 2024-03-01
draft: false
episode: 2
subtitle: "从零开始学习 Hugo"
description: "本期节目详细介绍 Hugo 静态站点生成器的安装、配置和使用方法。"
duration: "00:35:45"
audio_file: "/audio/episode-002.mp3"
audio_size: 21000000
audio_type: "audio/mpeg"
categories:
  - 技术分享
  - 教程
tags:
  - Hugo
  - 静态站点
  - Web开发
guests: []
chapters:
  - time: "00:00"
    title: "开场回顾"
  - time: "03:00"
    title: "什么是 Hugo"
  - time: "08:00"
    title: "Hugo 的优势"
  - time: "15:00"
    title: "安装和配置"
  - time: "25:00"
    title: "创建第一个站点"
  - time: "32:00"
    title: "最佳实践和资源"
---

## 节目简介

大家好，欢迎回到 Keriko 播客！今天是第二期节目，我们来聊聊 Hugo 静态站点生成器。

### 什么是 Hugo？

Hugo 是一个用 Go 语言编写的快速、现代化的静态站点生成器。它非常适合用来搭建博客、文档站点、播客网站等。

### Hugo 的核心优势

1. **极速构建**：毫秒级构建速度
2. **简单易用**：配置简单，上手容易
3. **功能强大**：支持丰富的主题和自定义
4. **跨平台**：支持 Windows、macOS、Linux

### 本期内容要点

- Hugo 的安装方法
- 项目结构解析
- 内容组织和分类
- 主题使用和定制
- 部署到 Gitee Pages

## 时间轴

- **00:00** - 上期回顾和本期开场
- **03:00** - 什么是静态站点生成器
- **08:00** - Hugo vs Jekyll vs Hexo
- **15:00** - 详细安装教程
- **20:00** - 项目结构说明
- **25:00** - 创建内容和使用 Markdown
- **32:00** - 主题选择和定制

## 实战代码示例

### 安装 Hugo

```bash
# Windows (Chocolatey)
choco install hugo-extended

# macOS (Homebrew)
brew install hugo

# Linux (Snap)
snap install hugo
```

### 创建新站点

```bash
hugo new site my-podcast
cd my-podcast
```

### 添加主题

```bash
git init
git submodule add https://github.com/chrede88/qubt.git themes/qubt
```

### 创建第一篇文章

```bash
hugo new podcast/episode-001.md
```

## 相关链接

- [Hugo 官方网站](https://gohugo.io/)
- [Hugo 中文文档](https://www.gohugo.org/)
- [Qubt 主题文档](https://github.com/chrede88/qubt/wiki)
- [Markdown 语法指南](https://www.markdownguide.org/)

## 常见问题

**Q: Hugo 和 WordPress 有什么区别？**
A: Hugo 是静态站点生成器，生成纯 HTML 文件，无需数据库，速度更快，更适合博客和文档。

**Q: 可以部署到哪里？**
A: 可以部署到 Gitee Pages、GitHub Pages、Netlify、Vercel 等平台。

**Q: 支持自定义域名吗？**
A: 完全支持，配置非常简单。

## 下期预告

第三期我们将分享"播客制作完整指南：从录音到发布"，包括录音设备推荐、音频处理、RSS 配置等内容。

---

**资源下载**：
- 本期示例代码：[GitHub Gist](#)
- 配置文件模板：[下载链接](#)

感谢收听！别忘了点赞、订阅和分享！
