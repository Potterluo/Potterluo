---
title: "MCPS2ONE：用小模型给 MCP 工具瘦身，省下 90% 的 token"
date: 2026-06-02T14:00:00+08:00
draft: false
description: "MCPS2ONE 用小语言模型智能选择 MCP 工具，减少主模型的 token 消耗和上下文窗口占用"
tags: [MCP, AI, 工具, token优化]
categories: [技术分享]
---

## 一个真实的痛点

如果你正在使用 MCP (Model Context Protocol) 来扩展 AI 模型的能力，可能已经遇到了一个让人头疼的问题：每次请求，AI 模型都会收到**所有 MCP Server 提供的全部工具定义**。

想象一下这个场景：你配置了 5 个 MCP Server，每个 Server 提供 10-20 个工具。每次对话，无论你只是想查个天气还是读个文件，模型都要先"阅读"近百个工具的完整定义——包括名称、描述、参数 schema 等。这些工具定义占据了大量的 context window，消耗了大量的 token。

更要命的是，这些 token 消耗发生在**每次请求**，即使你只用到其中 1-2 个工具。这就像去超市只买一瓶水，却要先把整个超市的商品目录都读一遍。

## MCPS2ONE 的核心思路

MCPS2ONE (MCP Service Selector) 的设计思路很直观：**让一个轻量的小模型负责"筛选"工作，把真正相关的工具交给主模型**。

这就像给大厨配了个助手。客人点菜后，助手先从几百种食材里选出相关的几样，再交给大厨处理。大厨不用每次都面对整仓库的食材清单，效率自然提升。

核心技术选型：
- 使用轻量小模型如 Qwen-1.5B、Phi-3-mini 作为选择代理
- 这些小模型可以在本地运行，保护隐私且成本低
- 仅将筛选后的工具定义传递给主模型

## 多种选择策略

MCPS2ONE 提供了四种工具选择策略，适应不同场景：

### 1. Keyword Strategy
基于关键词匹配。简单快速，适合工具名称和描述明确、用户意图清晰的场景。比如用户说"帮我读取文件"，Keyword 策略会匹配包含 "read"、"file" 关键词的工具。

### 2. Semantic Strategy
基于语义相似度。使用向量嵌入计算用户 query 与工具描述的语义距离。比关键词更智能，能理解"打开文档"和"读取文件"的语义关联。

### 3. LLM Strategy
让小语言模型真正"理解"用户意图，从工具列表中做出选择。这是最智能的方式，小模型会分析 query 的上下文，选择最合适的工具组合。

### 4. Hybrid Strategy
混合策略，结合上述多种方式。先用 Keyword 快速过滤，再用 Semantic 或 LLM 精选。兼顾速度和准确性。

## MCP Server 聚合

除了智能选择，MCPS2ONE 还有一个实用功能：**MCP Server 聚合**。

原本你需要配置多个 MCP Server endpoint，现在只需要一个。MCPS2ONE 在背后连接所有你配置的 Server，将它们的工具统一管理。

配置示例：

```json
{
  "mcpServers": {
    "filesystem": { "command": "npx", "args": ["-y", "@modelcontextprotocol/server-filesystem"] },
    "web-search": { "command": "npx", "args": ["-y", "@anthropic/mcp-server-web-search"] },
    "slack": { "command": "npx", "args": ["-y", "@anthropic/mcp-server-slack"] }
  }
}
```

用户端只需要连接 MCPS2ONE 提供的单一 endpoint，所有工具都从这里获取。

## 本地优先，隐私安全

MCPS2ONE 的设计理念是"本地优先"：

- 小模型完全可以在本地运行（CPU 即可，无需 GPU）
- 用户的 query 和工具选择过程不发送到外部服务
- 只有最终筛选后的工具列表交给主模型

如果你的主模型调用本身是本地部署的，那么整个链路都在你的控制范围内。即使使用云端主模型，暴露的也只是筛选后精简的工具定义，大幅降低了信息泄露风险。

## 实测效果：90% Token 减少

根据项目测试数据，使用 MCPS2ONE 可以减少约 **90% 的 token 消耗**。

举个例子：

- **原始方案**：100 个工具定义 × 200 tokens/工具 = 20,000 tokens（每次请求）
- **MCPS2ONE**：筛选后 5 个工具 × 200 tokens/工具 = 1,000 tokens

节省的不仅是 token 成本，还有宝贵的 context window。主模型可以把更多空间留给真正的对话内容、历史上下文和复杂推理。

## 快速上手

安装非常简单：

```bash
pip install mcps2one
```

启动服务：

```bash
mcps2one --config your_config.json
```

然后将你的 AI 应用（Claude Desktop、Cursor 等）的 MCP endpoint 配置为 MCPS2ONE 提供的地址。

项目要求 Python 3.10+，采用 MIT 许可证，代码完全开源。

## 设计思考

MCPS2ONE 的设计体现了几个值得借鉴的思路：

**分层架构**：将"选择"和"执行"分离。小模型做选择，大模型做推理。各司其职，效率最大化。

**轻量介入**：不需要改动现有的 MCP Server 或主模型配置。MCPS2ONE 作为中间层，透明接入。

**渐进式智能**：从 Keyword 到 LLM，用户可以根据实际需求选择策略。简单场景用简单策略，复杂场景用智能策略。

**实用优先**：解决真实痛点而非炫技。90% 的 token 减少是实实在在的成本节省。

## 结语

MCP 协议正在快速发展，越来越多的 AI 应用开始接入 MCP 工具生态。但随着工具数量增长，token 消耗问题会越来越突出。

MCPS2ONE 用一个巧妙的设计解决了这个问题：用小模型做筛选，让大模型专注推理。这种"分工"思路在 AI 系统设计中值得更多探索。

如果你也在使用 MCP 并遇到 token 消耗问题，不妨试试 MCPS2ONE。几分钟就能接入，效果立竿见影。

---

**项目地址**：[GitHub - MCPS2ONE](https://github.com/your-repo/mcps2one)

**安装**：`pip install mcps2one`

**许可证**：MIT