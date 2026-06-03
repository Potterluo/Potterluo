---
title: "我写了个 Docker 镜像拉取工具，不用装 Docker"
date: 2026-03-15T10:00:00+08:00
draft: false
description: "docker-pull-tar：一个无需 Docker/Python 环境的镜像拉取工具，支持断点续传、多架构、SHA256 校验、并发下载，适合内网和离线部署场景"
tags:
  - docker
  - 工具
  - 运维
categories:
  - 技术分享
authors:
  - Potterluo
---

## 问题的由来

去年我在做一个私有化部署项目，客户的环境非常严格：内网、无外网访问、安全审计不允许安装额外软件。我们需要部署一套微服务架构的应用，总共 12 个镜像，最大的一个有 3.2GB。

最初我们用的方案很传统：

1. 在有外网的开发机上 `docker pull` 拉镜像
2. `docker save` 打包成 tar 文件
3. 通过 U 盘把 tar 拷贝到客户内网环境
4. 客户用 `docker load` 加载镜像

第一次部署就遇到了问题：

- **传输中断**：拷贝 3.2GB 镜像时 U 盘写入失败，只能重新导出再拷贝
- **架构错误**：我们的开发机是 ARM Mac，客户服务器是 x86 Linux，拉错了架构
- **依赖问题**：客户的另一台机器没有 Docker，我们想用 Python 脚本辅助，结果连 Python 也没装

那天在现场折腾了整整一下午，才把所有镜像部署上去。回到公司后，我就在想：能不能做一个工具，不依赖 Docker 也不依赖 Python，还能解决这些痛点？

于是就有了 **docker-pull-tar**。

---

## docker-pull-tar 是什么

这是一个纯 Shell + curl 的工具，直接从 Docker Registry 拉取镜像并打包成 tar 文件。核心特点：

| 特性 | 说明 |
|------|------|
| ✅ 零依赖 | 不需要安装 Docker 或 Python，只要有 curl 和 shell 即可运行 |
| ✅ 断点续传 | 传输中断后重新运行会自动继续，无需从头下载 |
| ✅ 多架构支持 | 明确指定 amd64/arm64/v7 等架构，避免拉错镜像 |
| ✅ SHA256 校验 | 下载完成后自动校验每个 layer 的完整性 |
| ✅ 并发下载 | 多个 layer 同时下载，显著提升大镜像拉取速度 |
| ✅ 私有仓库 | 支持 Basic Auth 认证的私有 Registry |

项目开源在 GitHub：[Potterluo/docker-pull-tar](https://github.com/Potterluo/docker-pull-tar)，采用 MIT 许可证，可自由使用和修改。

---

## 使用方法

### 基本用法

最简单的用法，直接指定镜像名：

```bash
# 拉取 nginx 镜像并打包成 tar
./docker-pull-tar.sh nginx:latest

# 默认输出文件名: nginx_latest.tar
```

### 指定架构

明确指定目标架构，避免架构不匹配问题：

```bash
# 拉取 x86_64 (AMD64) 版本
./docker-pull-tar.sh --platform linux/amd64 nginx:latest

# 拉取 ARM64 版本（适合 ARM 服务器/Mac）
./docker-pull-tar.sh --platform linux/arm64 nginx:latest

# 拉取 ARM v7 版本（适合 Raspberry Pi 等）
./docker-pull-tar.sh --platform linux/arm/v7 nginx:latest
```

### 并发下载加速

大镜像通常有多个 layer，并发下载可以显著提速：

```bash
# 默认 4 个并发下载
./docker-pull-tar.sh nginx:latest

# 自定义并发数（适合带宽充足的环境）
./docker-pull-tar.sh --concurrent 8 large-image:v2

# 网络较差时减少并发
./docker-pull-tar.sh --concurrent 2 slow-registry.com/image:v1
```

实测效果：拉取一个 2GB 的镜像（12 个 layer）：

| 并发数 | 下载耗时 |
|--------|----------|
| 1 | 12 分钟 |
| 4 | 4 分钟 |
| 8 | 2.5 分钟 |

### 断点续传

网络不稳定时特别有用，重新运行同一个命令即可：

```bash
# 第一次下载，中途网络断了
./docker-pull-tar.sh huge-image:v1
# 输出: [ERROR] Connection timeout, 5/12 layers downloaded

# 重新运行，会检测已下载的 layer，只下载剩余部分
./docker-pull-tar.sh huge-image:v1
# 输出: [INFO] Resuming from previous download, 5 layers already cached
```

已下载的 layer 会缓存在临时目录，直到完整打包成 tar 后才清理。

### 私有仓库认证

支持需要认证的私有 Registry：

```bash
# Docker Hub 私有仓库（需要用户名密码）
./docker-pull-tar.sh --user myuser --pass mypass myuser/private-image:v1

# 自建 Registry（如 Harbor、Nexus）
./docker-pull-tar.sh --user admin --pass Harbor12345 harbor.company.com/backend:v2

# 使用环境变量避免密码泄露
export REGISTRY_PASSWORD=Harbor12345
./docker-pull-tar.sh --user admin --pass-env REGISTRY_PASSWORD harbor.company.com/backend:v2
```

---

## 工作原理

docker-pull-tar 的核心思路：**绕过 Docker daemon，直接和 Docker Registry HTTP API 对话**。

整体流程图：

```text
┌─────────────┐
│ 解析镜像名   │ → 分离 Registry/Repository/Tag/Digest
└─────────────┘
      ↓
┌─────────────┐
│ 认证获取 Token│ → 私有仓库需要 Basic Auth → Bearer Token
└─────────────┘
      ↓
┌─────────────┐
│ 获取 Manifest │ → HTTP GET /v2/<name>/manifests/<ref>
└─────────────┘
      ↓
┌─────────────┐
│ 解析 Layer 列表│ → 从 manifest 提取 blob digest 列表
└─────────────┘
      ↓
┌─────────────┐
│ 并发下载 Blob │ → 多线程 curl 下载每个 layer blob
└─────────────┘
      ↓
┌─────────────┐
│ SHA256 校验   │ → 每个下载的 blob 校验 digest 是否匹配
└─────────────┘
      ↓
┌─────────────┐
│ 组装 Tar 包   │ → 按照 OCI Image Spec 格式打包
└─────────────┘
      ↓
┌─────────────┐
│ 输出 tar 文件 │ → 可直接 docker load 加载
└─────────────┘
```

### Registry API 关键端点

Docker Registry V2 API 是标准 HTTP API，主要有这些端点：

```bash
# 1. 检查 API 版本
GET /v2/

# 2. 获取镜像 Manifest（包含 layer 列表）
GET /v2/<name>/manifests/<reference>

# 3. 下载 Layer Blob
GET /v2/<name>/blobs/<digest>

# 4. 认证（私有仓库）
GET /v2/<name>/blobs/<digest>
Authorization: Basic <base64(user:pass)>
# 或 Bearer Token
```

### 并发下载的实现

关键代码片段（简化版）：

```bash
# 获取 layer 数量
layer_count=$(echo "$manifest" | jq '.layers | length')

# 使用 xargs 实现并发
echo "$layer_digests" | xargs -P $concurrent -I {} \
  curl -f -L -C - \
    -H "Authorization: Bearer $token" \
    "$registry/v2/$repo/blobs/{}" \
    -o "cache/{}.tar.gz"

# 等待所有下载完成
wait
```

`xargs -P` 参数控制并发数，每个 curl 进程独立下载一个 layer blob。

### Docker tar 格式结构

生成的 tar 包符合 OCI Image Spec 标准：

```text
image.tar
├── manifest.json        # 镜像元数据（RepoTags、Config、Layers）
├── <config-digest>.json # 镜像配置（环境变量、入口命令等）
├── <layer-digest>.tar   # 每个文件系统层
├── <layer-digest>.tar
└── ...
```

这个格式可以直接被 `docker load` 解析和加载。

---

## 适用场景

### 1. 内网部署

目标机器没有外网，需要在跳板机上拉镜像再传过去。

```bash
# 在跳板机拉取
./docker-pull-tar.sh myimage:v1

# 传到内网机器
scp myimage_v1.tar target:/tmp/

# 在内网机器加载（前提是有 docker）
docker load -i /tmp/myimage_v1.tar
```

### 2. 离线交付

产品交付给客户，客户环境无法联网。

```bash
# 打包所有需要的镜像
./docker-pull-tar.sh backend:v1
./docker-pull-tar.sh frontend:v1
./docker-pull-tar.sh database:v1

# 一起打包给客户
tar -cvf product_images.tar *_v1.tar
```

### 3. CI/CD 缓存

CI 环境不想装 Docker，只想缓存镜像。

```bash
# 在 CI 中缓存
./docker-pull-tar.sh base-image:latest

# 后续步骤直接使用 tar
```

---

## 和其他方案的对比

主流方案各有优劣，选择取决于场景：

| 方案 | 运行依赖 | 断点续传 | 并发下载 | 多架构 | SHA256 校验 |
|------|----------|----------|----------|--------|-------------|
| `docker pull` + `docker save` | Docker daemon | ❌ | ✅ (内置) | ✅ | ✅ |
| `skopeo copy` | skopeo 二进制 | ❌ | ✅ | ✅ | ✅ |
| `crane pull` | crane (go容器) | ❌ | ✅ | ✅ | ✅ |
| Python 脚本方案 | Python + libs | 部分 | ✅ | ✅ | ✅ |
| **docker-pull-tar** | **curl + shell** | **✅** | **✅** | ✅ | ✅ |

docker-pull-tar 不是要取代这些成熟的工具，而是在以下场景提供独特价值：

- 环境限制严格，不允许安装 Docker/skopeo/Python
- 网络不稳定，需要可靠的断点续传能力
- 嵌入式/边缘设备，资源受限只需要最简依赖
- 应急场景：临时拿到一台跳板机，快速拉镜像传到内网

---

## 限制和注意事项

使用前需要了解的限制：

1. **加载仍需 Docker**: 这个工具解决的是「拉取 + 打包」环节，加载 tar 到容器运行环境仍需要 `docker load` 或其他容器引擎
2. **平台兼容性**: 目前只支持 Linux 和 macOS 的 Shell 环境，Windows 需 WSL 或 Git Bash
3. **磁盘空间**: 下载过程会缓存临时文件，确保有 2 倍镜像大小的空间
4. **大镜像耗时**: 单 layer 大文件（如 2GB+ 的基础镜像）即使并发也无法加速单个 blob 下载
5. **认证限制**: 目前只支持 Basic Auth，Bearer Token 自动获取但暂不支持自定义 Token

实用建议：

```bash
# 清理缓存（如果下载中断且想重新开始）
rm -rf ~/.cache/docker-pull-tar/

# 查看下载进度详情
./docker-pull-tar.sh --verbose image:tag

# 只下载不打包（适合调试）
./docker-pull-tar.sh --no-pack image:tag
```

---

## 写在最后

docker-pull-tar 解决的问题很小：「在没有 Docker 的环境拉取 Docker 镜像」。技术实现也不复杂，就是把 Registry HTTP API 和 curl 结合起来，加上 Shell 的并发控制能力。

但在实际工作中，这种小工具往往能解决最棘手的问题。那次私有化部署后，我们把工具加进了交付流程的标准工具包，后续几个项目都顺畅了很多。同事反馈说：「终于不用在客户现场装 Docker 再导出镜像了，直接在有网的机器上跑个脚本就行」。

项目完全开源，MIT 许可证，可自由使用、修改和集成：

```bash
git clone https://github.com/Potterluo/docker-pull-tar.git
cd docker-pull-tar
./docker-pull-tar.sh your-image:tag
```

如果你也遇到过类似的痛点，欢迎试用反馈。Issue 和 PR 都欢迎，一起让它更实用。

**相关资源**：

- GitHub: [https://github.com/Potterluo/docker-pull-tar](https://github.com/Potterluo/docker-pull-tar)
- 许可证: MIT License
- Docker Registry V2 API 规范: [https://docs.docker.com/registry/spec/api/](https://docs.docker.com/registry/spec/api/)
- OCI Image Spec: [https://github.com/opencontainers/image-spec](https://github.com/opencontainers/image-spec)