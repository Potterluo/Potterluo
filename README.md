# Potterluo 的个人博客

这是使用 [Hugo](https://gohugo.io/) 和 [Blowfish](https://github.com/nunocoracao/blowfish) 主题搭建的个人博客。

## 🚀 技术栈

- **Hugo**: 快速的静态网站生成器
- **Blowfish**: 功能强大的 Hugo 主题
- **GitHub Pages**: 网站托管
- **GitHub Actions**: 自动部署

## 📝 本地开发

### 前置要求

- [Hugo Extended](https://gohugo.io/installation/) (版本 >= 0.141.0)

### 运行博客

```bash
# 克隆仓库
git clone https://github.com/Potterluo/Potterluo.github.io
cd Potterluo.github.io

# 启动开发服务器
hugo server -D

# 在浏览器中打开 http://localhost:1313
```

### 创建新文章

```bash
hugo new posts/my-new-post.md
```

## 🛠️ 项目结构

```
.
├── config/          # 配置文件
├── content/         # 网站内容
│   ├── posts/      # 博客文章
│   └── about/      # 关于页面
├── static/         # 静态资源
├── themes/         # 主题文件
└── .github/        # GitHub Actions 配置
```

## 📄 许可证

© 2026 Potterluo. All rights reserved.
