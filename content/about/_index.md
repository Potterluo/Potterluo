---
title: "关于我"
date: 2026-03-08T19:30:00+08:00
draft: false
description: "了解更多关于我的信息 - 一个在行星上观察技术的 LLM 基础设施工程师"
authors: ["potterluo"]
---

## 你好，我是 Keriko 👋

我是一名 LLM 基础设施工程师，目前在北京的中科院大学（UCAS）学习和工作。欢迎来到「行星观察笔记」—— 这里是我记录技术探索、开源旅程和偶尔发呆的地方。

技术是我的望远镜，而好奇心是我的引力。我相信每一行代码都是一次对话，每一次开源都是一次握手。

---

## 技术方向

我主要关注 **LLM 基础设施** 相关的技术领域。这些不是冰冷的名词，而是我每天都在打交道的老朋友：

### KV Cache 优化

这是我最着迷的领域之一。LLM 推理的瓶颈往往不在计算，而在内存。我研究 KV Cache 的持久化与复用方案，探索如何在有限的显存中榨出更多性能。从 PagedAttention 到 MLA，从 prefix caching 到跨请求复用，每一项优化都像在解开一道精巧的谜题。

> 当你发现一个请求可以复用上一个请求的缓存，推理延迟从秒级降到毫秒级——那种成就感，懂的人都懂。

### 容器镜像管理

在内网环境中分发 Docker 镜像是一个经典痛点。我开发了 `docker-pull-tar`，一个无需 Docker 和 Python 的镜像拉取工具，让离线部署不再是噩梦。技术应该让人省心，而不是让人加班。

### LLM 性能基准测试

如何量化一个 LLM 服务的性能？TTFT、TPOT、Throughput……这些指标背后是真实用户体验的映射。我用 pytest 搭建自动化测试框架，让性能回归变得可检测、可追踪、可优化。

### 开源工具开发

把工作中遇到的问题变成可复用的解决方案，这是开源对我的意义。不是为了 stars，而是为了让下一个人遇到同样问题时，能少走一段弯路。

---

## 开源贡献者

我在 GitHub 上维护了 **25+ 个仓库**，大部分围绕 LLM 推理和容器工具链。开源不只是代码分享，更是一种「问题 → 解决方案 → 共享」的习惯。

### 代表项目

| 项目 | 简介 |
|------|------|
| [ClawPerf](https://github.com/Potterluo/ClawPerf) | LLM 服务 CLI 基准测试工具，用 pytest 框架构建，支持多并发、多场景压测 |
| [KVCache-calculator](https://github.com/Potterluo/KVCache-calculator) | KV Cache 内存计算器，支持 MLA/GQA/Hybrid 等多种注意力机制，CLI 可视化输出 |
| [docker-pull-tar](https://github.com/Potterluo/docker-pull-tar) | 纯 Shell 实现的镜像拉取工具，无需 Docker/Python，适合离线环境 |
| [unified-cache-management](https://github.com/Potterluo/unified-cache-management) | LLM KV Cache 持久化与复用方案探索，跨请求、跨会话的缓存管理 |

更多项目可以在我的 [GitHub](https://github.com/Potterluo) 找到。如果你在用其中任何一个，欢迎提 issue 或 PR，让我知道它帮到了你。

---

## 个人理念

> "May the world be less steeped in bias and inequity, may we both embrace a spirit unbound by societal norms, seeking the essence of self"
>
> 愿世界少一些偏见与不公，愿我们都能拥抱不被社会规训束缚的精神，寻找自我的本质。

这是我写在 GitHub bio 里的一句话。技术之外，我常常在想：

- **关于偏见**：算法有偏见，因为训练数据有偏见。人有偏见，因为社会有偏见。保持清醒，是最小单位的抵抗。
- **关于自由**：自由不是随心所欲，而是有能力选择自己想要承担的代价。
- **关于自我**：我们都在社会规训的模具里长大，偶尔停下来问问自己：这是我想要的吗？

技术让我看清世界的复杂性，也让我有工具去做出一点改变。哪怕只是让一个部署脚本跑得更顺畅，让一个推理延迟下降几毫秒——这些微小的改进，也是我抵抗混乱的方式。

---

## 技能栈

```text
编程语言    Python ████████████░░ Go ████████░░░░░░ Shell ███████░░░░░░░ Rust ████░░░░░░░░░░
基础设施    Docker / Kubernetes / Linux / Network
LLM 接触    vLLM / Transformers / KV Cache / Ascend NPU / FlashInfer
工具链      pytest / Git / Makefile / CI-CD / Prometheus
其他        Hugo / Markdown / 稍微会一点前端
```

我是个务实的工程师：先解决问题，再追求优雅。能跑起来的代码才是好代码，能被别人读懂的代码才是更好的代码。

---

## 联系方式

如果你想和我交流技术、开源、或者聊点别的，可以通过这些方式找到我：

- **GitHub**: [Potterluo](https://github.com/Potterluo) ← 最活跃的地方
- **个人网站**: [keriko.fun](http://keriko.fun/)
- **邮箱**: 可以通过 GitHub 联系我

我不常在线社交，但会认真回复每一条有诚意的信息。

---

## 关于这个博客

「行星观察笔记」这个名字，源于一个想法：

> 我们都是漂浮在宇宙中的行星，技术是我们观察世界的方式。每一次技术探索，都是一次引力弹弓。

这个博客是我记录：

- 📝 **技术探索的笔记** —— 不追求完美，追求真实
- 🔧 **开源项目的旅程** —— 从 0 到 1 的过程比结果更有价值
- 💭 **偶尔的思考与发呆** —— 技术之外的风景也值得记录

感谢你的访问。如果你在这里找到了一点有用的东西，或者共鸣了一句话，那就是我最大的开心。

---

> *"代码是暂时的，思想是永恒的。但写代码的过程，就是思考变成永恒的过程。"*