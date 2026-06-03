---
title: "API2MCP：把任意 API 变成 MCP 服务，统一管理"
date: 2026-05-25T11:00:00+08:00
draft: false
description: "API2MCP 将 REST API 统一封装为 MCP 服务，支持 Web 管理界面、多种认证、SSE 流式"
tags: [MCP, API, FastAPI, 工具]
categories: [技术分享]
---

## 问题场景

在 AI 应用开发中，我们经常需要集成各种外部 API 服务——天气查询、新闻聚合、图片生成、数据检索等等。传统做法是：

1. 为每个 API 写适配代码
2. 处理不同的认证方式（有的用 API Key，有的用 OAuth）
3. 管理散落在各处的配置
4. 在 AI 应用中逐个对接

这种方式存在几个痛点：

- **管理分散**：API 配置散落在代码和配置文件中，难以统一查看和维护
- **认证多样**：不同 API 使用不同认证方式，每次都要重新适配
- **测试困难**：需要额外工具测试 API 可用性，或写临时测试脚本
- **AI 对接复杂**：要让 AI Agent 使用这些 API，需要额外开发工具层

**MCP（Model Context Protocol）** 的出现提供了一个统一解决方案。但问题来了：如何把现有的 REST API 快速转换为 MCP 服务？

## API2MCP：一站式解决方案

**API2MCP** 是一个将各种 API 服务封装为标准 MCP 服务的工具。它提供了一个 Web 管理界面，让你可以：

- 添加、编辑、删除 API 配置
- 测试 API 是否正常工作
- 一键生成 MCP 服务端点
- 统一管理认证方式

核心价值：**把零散的 API 统一管理，一键变成 MCP 服务，供 AI Agent 直接调用**。

### 技术架构

API2MCP 基于 Python 生态构建：

- **FastMCP**：用于实现 MCP 协议的核心框架
- **FastAPI**：提供 Web 管理界面和 REST API
- **Uvicorn**：高性能 ASGI 服务器

整个项目轻量、易部署，依赖简单。

## 功能特点

### 1. Web 管理界面

启动服务后访问 `http://localhost:8000`，你会看到一个直观的管理面板：

- 左侧列出所有已添加的 API
- 点击 API 可以查看详情、编辑配置
- 内置测试按钮，一键验证 API 可用性

不需要手写配置文件，不需要命令行操作，鼠标点点就能完成 API 管理。

### 2. 多种认证方式支持

API2MCP 支持五种常见认证方式：

| 认证类型 | 适用场景 |
|---------|---------|
| 无认证 | 公开 API（如部分天气查询） |
| API Key | 大多数付费 API（OpenAI、各种 SaaS） |
| Basic Auth | 企业内部服务、老系统接口 |
| Token | JWT、自定义 Token 认证 |
| OAuth | 社交平台、复杂授权场景 |

添加 API 时选择认证类型，填入凭证，后续调用自动处理认证逻辑。

### 3. 三种访问方式

API2MCP 提供三种调用方式，适配不同使用场景：

**REST API**

```
POST http://localhost:8000/api/{api_name}
```

传统 HTTP 调用，适合：
- 非 AI 应用集成
- 前端直接调用
- 测试验证

**MCP SSE 流式**

```
http://localhost:8000/mcp/sse
```

Server-Sent Events 方式的 MCP 端点，适合：
- Claude Desktop、Cursor 等 MCP 客户端
- 支持 SSE 的 AI 工具
- 需要实时反馈的场景

**MCP 标准输入输出**

通过 stdin/stdout 运行 MCP 协议，适合：
- 嵌入式集成
- 不支持 SSE 的环境
- 需要进程管理的场景

### 4. 内置测试功能

每个 API 配置完成后，可以在 Web 界面直接测试：

1. 点击「测试」按钮
2. 输入测试参数（如查询关键词、坐标等）
3. 查看返回结果和耗时

测试失败会显示错误信息，方便排查问题：认证失败、参数错误、网络超时等。

### 5. 完善的日志系统

所有 API 调用都有详细日志记录：

- 请求时间、参数
- 响应状态、耗时
- 错误详情

日志可以帮助：
- 排查问题
- 分析 API 使用频率
- 监控异常调用

### 6. 预置免费 API

项目预置了多个免费可用的 API，开箱即用：

- 天气查询 API
- 新闻聚合 API
- 地理编码 API
- ...

这些预置 API 可以作为示例，也可以直接使用。

## 使用示例

### 安装与启动

```bash
git clone https://github.com/your-repo/api2mcp
cd api2mcp
pip install -r requirements.txt
python main.py
```

服务启动后：

- Web 界面：`http://localhost:8000`
- MCP SSE 端点：`http://localhost:8000/mcp/sse`

### 添加一个天气 API

假设我们要添加一个天气查询 API：

1. 打开 Web 管理界面
2. 点击「添加 API」
3. 填写配置：

```yaml
name: weather_api
display_name: 天气查询
base_url: https://api.weather.com/v1
auth_type: api_key
auth_config:
  key_name: appid
  key_value: your_api_key_here
  location: query
endpoints:
  - path: /current
    method: GET
    description: 获取当前天气
    params:
      - name: q
        description: 城市名称
        required: true
```

4. 保存后点击「测试」，输入城市名验证
5. 测试成功后，API 就可以通过 MCP 调用了

### 配置 Claude Desktop

在 Claude Desktop 配置文件中添加：

```json
{
  "mcpServers": {
    "api2mcp": {
      "url": "http://localhost:8000/mcp/sse"
    }
  }
}
```

重启 Claude Desktop，现在可以直接让 Claude 查天气：

> "帮我查询北京现在的天气情况"

Claude 会自动调用 `weather_api` 的 `/current` 端点获取数据。

## 配置文件格式

API2MCP 使用 `config.yaml` 存储配置：

```yaml
apis:
  - name: weather_api
    display_name: 天气查询
    base_url: https://api.weather.com/v1
    auth_type: api_key
    auth_config:
      key_name: appid
      key_value: ${WEATHER_API_KEY}
      location: query
    endpoints:
      - path: /current
        method: GET
        description: 获取当前天气
        params:
          - name: q
            description: 城市名称
            required: true
          - name: units
            description: 单位（metric/imperial）
            required: false
            default: metric

  - name: news_api
    display_name: 新闻聚合
    base_url: https://newsapi.org/v2
    auth_type: api_key
    auth_config:
      key_name: X-Api-Key
      key_value: ${NEWS_API_KEY}
      location: header
    endpoints:
      - path: /top-headlines
        method: GET
        description: 获取头条新闻
        params:
          - name: country
            description: 国家代码
            required: true
          - name: category
            description: 分类
            required: false
```

关键配置项说明：

- `auth_config.location`：认证参数位置，可选 `query`（URL 参数）、`header`（请求头）、`body`（请求体）
- `endpoints`：定义 API 的各个端点，包括路径、方法、参数描述
- 参数中的 `required` 和 `default` 用于 AI 调用时生成正确的参数

## 适用场景

API2MCP 特别适合以下场景：

**AI Agent 开发**

你正在开发一个需要调用多个外部 API 的 AI Agent。用 API2MCP 把这些 API 统一封装后，Agent 只需要对接 MCP 协议，不用处理各种认证、参数格式。

**API 统一管理**

团队内部有多个 API 服务，配置散落在各处。用 API2MCP 统一管理，可视化界面方便查看和维护。

**快速原型开发**

需要在 AI 应用中快速集成某个新 API。用 API2MCP 添加配置后立即可用，省去编写适配代码的时间。

**学习 MCP 协议**

想了解 MCP 协议的实际应用。API2MCP 提供了一个直观的示例：REST API → MCP 服务的转换过程。

## 小结

API2MCP 解决了一个实际问题：**如何让 AI Agent 便捷地调用现有 REST API**。它通过 MCP 协议实现了统一接口，同时提供了 Web 管理界面简化配置过程。

如果你正在做 AI Agent 开发，或者需要管理多个 API 服务，API2MCP 是一个值得尝试的工具。开箱即用的预置 API、完善的测试功能、详细的日志，让它不仅是一个转换工具，也是一个 API 管理平台。

项目地址：[GitHub - API2MCP](https://github.com/your-repo/api2mcp)

---

相关阅读：
- [PrefixBench：LLM 上下文前缀基准测试工具](/posts/006-prefix-bench)
- [MCP 协议入门指南](/posts/007-mcps2one)