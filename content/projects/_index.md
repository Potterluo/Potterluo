---
title: "项目"
date: 2026-03-08T19:30:00+08:00
draft: false
description: "我的开源项目矩阵：LLM 基础设施、容器工具、性能测试"
authors: ["potterluo"]
---

这里列出了我的主要开源项目，大部分围绕 LLM 推理基础设施和容器工具链。每个项目都源于工作中遇到的真实痛点。

---

## LLM 推理相关

### ClawPerf

{{< github repo="Potterluo/ClawPerf" >}}

LLM 服务 CLI 基准测试工具。一条命令测试推理性能，支持 TTFB、TPS、延迟分布、并发能力等指标。适合对比不同推理引擎（vLLM、TGI、OpenAI API）的性能。

---

### KVCache-calculator

{{< github repo="Potterluo/KVCache-calculator" >}}

KV Cache 内存计算器。支持 MLA、GQA、MHA、Hybrid 等架构，输入模型参数即可计算显存需求。帮助规划 LLM 推理部署的硬件资源。

---

### unified-cache-management

{{< github repo="Potterluo/unified-cache-management" >}}

LLM KV Cache 持久化与复用方案。探索在请求间复用 KV Cache，减少重复计算开销。与 vLLM UC (Unified Cache Management) 理念一致。

---

### PrefixBench

{{< github repo="Potterluo/PrefixBench" >}}

LLM 长序列推理 KV Cache 前缀复用性能评估基准。31,255条测试样本覆盖 8K-128K 五个级别，支持中英文双语，兼容 EvalScope/AIS Bench/vLLM Bench。[ModelScope 数据集](https://modelscope.cn/datasets/keriko/PrefixBench)

---

## 容器工具链

### docker-pull-tar

{{< github repo="Potterluo/docker-pull-tar" >}}

无需 Docker/Python 环境的镜像拉取工具。纯 Shell + curl 实现，支持断点续传、多架构、SHA256 校验。适合内网环境、离线部署场景。

[详细介绍 →](/posts/docker-pull-tar)

---

### MirrorX

{{< github repo="Potterluo/MirrorX" >}}

容器镜像同步管理系统。基于 skopeo + cron + webhook，支持定时同步、状态监控、Webhook 通知。适合内网 Registry 镜像管理。

---

## MCP 工具链

### API2MCP

{{< github repo="Potterluo/API2MCP" >}}

API 转 MCP 封装工具。将任意 REST API 封装为标准 MCP 服务，支持 Web 管理界面、多种认证方式、SSE 流式。基于 FastAPI + FastMCP。

---

### MCPS2ONE

{{< github repo="Potterluo/MCPS2ONE" >}}

MCP 智能工具选择器。用小模型（Qwen-1.5B等）智能筛选最相关的 MCP 工具，减少主模型 90% 的 token 消耗。支持 Keyword/Semantic/LLM/Hybrid 多种策略。

---

## 其他项目

### MultiUserClaw

{{< github repo="Potterluo/MultiUserClaw" >}}

多用户 LLM 聊天 Bot。支持微信/钉钉/飞书平台，包含用户权限管理、额度控制、历史记录等功能。

---

## 项目矩阵总览

| 项目 | 类型 | 核心解决的问题 |
|------|------|----------------|
| ClawPerf | CLI 工具 | LLM 服务性能基准测试 |
| KVCache-calculator | Web 工具 | KV Cache 内存计算 |
| unified-cache-management | Python | KV Cache 持久化复用 |
| PrefixBench | 数据集 | KV Cache 前缀复用性能评估 |
| docker-pull-tar | Shell 工具 | 无 Docker 环境拉取镜像 |
| MirrorX | 系统 | 容器镜像同步管理 |
| API2MCP | API 工具 | REST API 转 MCP 封装 |
| MCPS2ONE | 智能筛选 | MCP 工具 token 优化 |
| MultiUserClaw | Bot | 多用户 LLM 聊天 |

---

更多项目可以在我的 [GitHub](https://github.com/Potterluo) 找到。欢迎提 Issue 和 PR，一起让它们更好用。