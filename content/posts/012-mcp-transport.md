---
title: "详解 MCP 传输机制：stdio、SSE 和 HTTP 怎么选？"
date: 2026-05-20T10:00:00+08:00
draft: false
tags: [MCP, AI, 协议]
categories: [技术分享]
---

MCP（Model Context Protocol）作为连接 AI 模型与外部工具的标准协议，其传输机制是理解整个协议架构的关键。MCP 支持三种主要的传输方式：**stdio**、**SSE** 和 **HTTP**，每种方式都有其独特的适用场景和优缺点。本文将深入解析这三种传输机制，帮助你做出正确的技术选型。

## MCP 传输机制概述

MCP 的设计目标是让 AI 模型能够安全、高效地访问外部数据源和工具。传输层是 MCP 架构的基础，负责在客户端（通常是 AI 应用）和服务器（提供工具/数据的服务）之间传递 JSON-RPC 消息。

选择合适的传输方式，直接影响系统的：
- **部署复杂度**：本地工具 vs 远程服务
- **性能表现**：延迟、吞吐量
- **安全性**：进程隔离 vs 网络暴露
- **可扩展性**：单机 vs 分布式

## 一、stdio 传输：本地工具的最佳选择

### 工作原理

stdio（标准输入/输出）传输是最简单直接的方式。MCP 服务器作为子进程启动，通过 stdin 接收请求，通过 stdout 返回响应。

```
AI 应用 → stdin → MCP Server → stdout → AI 应用
```

消息格式遵循 JSON-RPC 2.0 规范，每个消息以换行符分隔。

### 典型实现

```typescript
// 客户端启动 MCP 服务器进程
const serverProcess = spawn('my-mcp-server', [], {
  stdio: ['pipe', 'pipe', 'pipe']
});

// 发送请求
serverProcess.stdin.write(JSON.stringify(request) + '\n');

// 接收响应
serverProcess.stdout.on('data', (data) => {
  const response = JSON.parse(data.toString());
  // 处理响应
});
```

### 优点

1. **零网络开销**：进程间直接通信，无 TCP/IP 协议栈开销
2. **天然隔离**：服务器进程崩溃不影响主应用
3. **部署简单**：无需配置端口、防火墙、SSL
4. **安全性高**：仅本地可访问，无网络暴露风险
5. **启动快速**：进程启动比网络服务更快

### 缺点

1. **仅限本地**：无法跨机器通信
2. **生命周期绑定**：客户端退出时服务器通常也要终止
3. **调试困难**：stdout/stdin 被占用，日志输出受限
4. **资源限制**：每个客户端可能启动独立的服务器进程

### 适用场景

- **本地 CLI 工具**：如 Claude Code、Cursor 等编辑器集成
- **文件系统访问**：读写本地文件、搜索代码库
- **开发调试**：快速验证 MCP 服务器逻辑
- **单用户场景**：个人开发环境、本地自动化脚本

### 实际案例

Claude Code 使用 stdio 传输连接多个 MCP 服务器：
- 文件系统服务器：读写本地文件
- Git 服务器：执行 git 命令
- 数据库服务器：连接本地数据库

## 二、SSE 传输：远程服务的标准方案

### 工作原理

SSE（Server-Sent Events）是一种基于 HTTP 的单向推送技术。MCP 使用 SSE 实现双向通信：
- **客户端→服务器**：通过 HTTP POST 发送请求
- **服务器→客户端**：通过 SSE 连接推送响应和通知

```
AI 应用 ←──SSE连接──→ MCP Server
        │              │
        └──HTTP POST──→  (发送请求)
```

### 典型实现

**服务器端（Node.js）：**

```typescript
import express from 'express';

const app = express();

// SSE 端点
app.get('/sse', (req, res) => {
  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  
  // 保存连接，用于推送消息
  const clientId = generateId();
  connections.set(clientId, res);
  
  // 发送 endpoint 事件，告知客户端 POST 地址
  res.write(`event: endpoint\ndata: /message?clientId=${clientId}\n\n`);
});

// 接收请求的 POST 端点
app.post('/message', express.json(), (req, res) => {
  const { clientId } = req.query;
  const connection = connections.get(clientId);
  
  // 处理请求，通过 SSE 推送响应
  handleRequest(req.body).then(response => {
    connection.write(`event: message\ndata: ${JSON.stringify(response)}\n\n`);
  });
  
  res.sendStatus(200);
});
```

**客户端：**

```typescript
// 建立 SSE 连接
const eventSource = new EventSource('http://server/sse');

eventSource.addEventListener('endpoint', (e) => {
  postEndpoint = e.data; // 保存 POST 地址
});

eventSource.addEventListener('message', (e) => {
  const response = JSON.parse(e.data);
  // 处理响应
});

// 发送请求
fetch(postEndpoint, {
  method: 'POST',
  body: JSON.stringify(request)
});
```

### 优点

1. **跨网络通信**：支持远程部署、分布式架构
2. **原生浏览器支持**：EventSource API 无需额外库
3. **自动重连**：浏览器 SSE 实现内置重连机制
4. **单向流高效**：服务器推送无需客户端轮询
5. **兼容性好**：基于标准 HTTP，穿透防火墙容易

### 缺点

1. **单向限制**：需要 POST+SSE 组合实现双向
2. **长连接开销**：每个客户端占用一个持久连接
3. **无二进制支持**：仅文本消息
4. **调试复杂**：需要网络抓包工具
5. **部署要求**：需要服务器、域名、可能的 SSL 配置

### 适用场景

- **Web 应用集成**：浏览器端 AI 应用连接后端服务
- **远程 MCP 服务**：云端部署的工具和数据源
- **团队共享**：多个客户端连接同一服务器
- **企业环境**：统一管理的 MCP 服务器集群

### 实际案例

- **远程数据库服务**：云数据库 MCP 服务器
- **API 网关**：统一 MCP 工具入口
- **协作平台**：多用户共享工具集

## 三、HTTP 传输：灵活的备选方案

### 工作原理

HTTP 传输使用简单的请求-响应模式：客户端发送 HTTP POST 请求，服务器返回 JSON 响应。

与 SSE 不同，HTTP 传输不支持服务器主动推送通知，客户端需要轮询获取异步消息。

```
AI 应用 ──HTTP POST──→ MCP Server
                    ←─JSON Response──
```

### 优点

1. **实现简单**：标准 RESTful 风格
2. **无长连接**：资源占用更低
3. **易于缓存**：可利用 HTTP 缓存机制
4. **负载均衡友好**：适合水平扩展

### 缺点

1. **无实时推送**：通知需要轮询
2. **延迟较高**：轮询间隔影响响应速度
3. **效率较低**：空轮询浪费资源

### 适用场景

- **低频操作**：不需要实时通知的场景
- **受限环境**：不支持 SSE 的特殊网络环境
- **简单集成**：快速原型开发

## 传输方式对比表

| 特性 | stdio | SSE | HTTP |
|------|-------|-----|------|
| **通信模式** | 双向流 | SSE推送+POST | 请求-响应 |
| **网络支持** | 仅本地 | 远程 | 远程 |
| **实时性** | 最高 | 高 | 中（需轮询） |
| **部署复杂度** | 低 | 中 | 低 |
| **安全性** | 进程隔离 | 需认证+HTTPS | 需认证+HTTPS |
| **资源开销** | 进程 | 长连接 | 无 |
| **浏览器支持** | 否 | 是 | 是 |
| **推送通知** | 支持 | 支持 | 不支持 |

## 选型决策树

```
开始选型
│
├─ 是否需要远程访问？
│   ├─ 否 → stdio（本地工具）
│   │
│   └─ 是 → 需要服务器推送通知？
│       ├─ 是 → SSE（推荐）
│       ├─ 否 → HTTP（简单场景）
│       └─ 受限环境 → HTTP
```

## 最佳实践建议

### 优先选择 stdio 的场景

1. **本地开发工具**：编辑器插件、CLI 工具
2. **文件/代码操作**：读写本地资源
3. **快速迭代**：开发调试阶段

### 优先选择 SSE 的场景

1. **生产级远程服务**：需要稳定推送
2. **Web 应用**：浏览器客户端
3. **多用户场景**：共享 MCP 服务器

### 安全注意事项

**stdio**：
- 验证服务器二进制来源
- 限制服务器权限范围

**SSE/HTTP**：
- 启用 HTTPS 加密传输
- 实现身份认证（API Key、OAuth）
- 限制 CORS 来源
- 监控异常请求

## 总结

MCP 的三种传输方式各有优势：
- **stdio** 是本地工具的首选，零网络开销、部署简单
- **SSE** 是远程服务的标准，支持实时推送、浏览器兼容
- **HTTP** 是简单场景的备选，实现简单但缺乏实时性

实际项目中，常见的组合是：
- 本地工具用 stdio（如 Claude Code）
- 远程服务用 SSE（如云端 MCP 服务器）

理解这些传输机制，能帮助你更好地设计 MCP 架构，在性能、安全性和部署复杂度之间找到平衡点。