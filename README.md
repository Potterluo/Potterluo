# Keriko 播客

基于 Hugo 和 Qubt 主题的个人播客系统

## 🎙️ 关于

这是一个使用 Hugo 静态站点生成器搭建的播客网站，采用 Qubt 主题，专注于技术分享和个人成长内容的发布。

## ✨ 特性

- 🎨 **现代设计**：采用 Qubt 主题，移动优先的响应式设计
- 🌓 **深色模式**：自动适应系统偏好，支持手动切换
- 📱 **移动优化**：完美的移动端体验
- ⚡ **极速加载**：Hugo 静态生成，毫秒级加载
- 🎧 **播客支持**：内置 RSS 订阅，支持播客客户端
- 🏷️ **标签分类**：灵活的内容组织和检索
- 🔍 **SEO 优化**：良好的搜索引擎优化

## 📋 系统要求

- **Hugo Extended**: >= 0.122.0
- **Go**: >= 1.23.3

## 🚀 快速开始

### 1. 安装 Hugo

**Windows (Chocolatey):**
```bash
choco install hugo-extended
```

**macOS (Homebrew):**
```bash
brew install hugo
```

**Linux:**
```bash
snap install hugo
```

验证安装：
```bash
hugo version
```

### 2. 克隆项目

```bash
git clone https://gitee.com/keriko/keriko.git
cd keriko
```

### 3. 初始化主题模块

```bash
hugo mod get github.com/chrede88/qubt@latest
```

### 4. 启动开发服务器

```bash
hugo server -D
```

访问 `http://localhost:1313` 查看网站

## 📝 创建新节目

使用 Hugo 命令创建新的播客节目：

```bash
hugo new podcast/episode-003.md
```

编辑创建的 Markdown 文件，填写节目信息：

```yaml
---
title: "节目标题"
date: 2024-03-08
episode: 3
subtitle: "副标题"
description: "节目描述"
duration: "00:30:00"
audio_file: "/audio/episode-003.mp3"
audio_size: 15000000
categories:
  - 技术分享
tags:
  - 编程
  - Hugo
---
```

## 📁 项目结构

```
keriko/
├── assets/              # 资源文件
│   └── css/            # 自定义样式
├── config/             # 配置文件
│   └── _default/       # 默认配置
├── content/            # 内容文件
│   ├── about.md        # 关于页面
│   └── podcast/        # 播客节目
├── layouts/            # 自定义布局
│   └── podcast/        # 播客专用布局
├── static/             # 静态资源
│   ├── audio/          # 音频文件
│   └── images/         # 图片资源
├── archetypes/         # 内容模板
├── go.mod              # Go 模块配置
└── hugo.yaml           # Hugo 配置
```

## 🎨 自定义配置

### 修改站点信息

编辑 `config/_default/params.yaml`：

```yaml
# 网站信息
title: 你的播客名称
description: 你的播客描述
author: 你的名字

# 播客配置
podcast:
  title: 播客标题
  description: 播客描述
  author: 作者
  email: your@email.com
```

### 修改导航菜单

编辑 `config/_default/menus.yaml`：

```yaml
main:
  - name: 首页
    url: /
    weight: 1
  - name: 播客节目
    url: /podcast/
    weight: 2
```

### 自定义样式

编辑 `assets/css/custom.css` 添加你的自定义样式。

## 🌐 部署到 Gitee Pages

### 1. 构建网站

```bash
hugo
```

### 2. 推送到 Gitee

```bash
git add .
git commit -m "更新内容"
git push origin master
```

### 3. 在 Gitee 启用 Pages

1. 进入仓库设置
2. 找到 "Gitee Pages" 服务
3. 选择 `public` 目录作为发布目录
4. 点击启动

## 📡 RSS 订阅

播客提供以下 RSS 订阅源：

- 完整订阅：`/podcast/index.xml`
- 标准 RSS：`/index.xml`

## 🛠️ 常用命令

```bash
# 创建新内容
hugo new podcast/episode-name.md

# 启动开发服务器（包含草稿）
hugo server -D

# 构建生产版本
hugo

# 清理构建文件
hugo --cleanDestinationDir
```

## 📚 相关资源

- [Hugo 官方文档](https://gohugo.io/)
- [Qubt 主题仓库](https://github.com/chrede88/qubt)
- [Qubt 主题 Wiki](https://github.com/chrede88/qubt/wiki)
- [Markdown 语法指南](https://www.markdownguide.org/)

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

MIT License

## 📮 联系方式

- 邮箱：podcast@keriko.com
- GitHub：https://github.com/keriko
- Gitee：https://gitee.com/keriko

---

⭐ 如果这个项目对你有帮助，请给个 Star！
