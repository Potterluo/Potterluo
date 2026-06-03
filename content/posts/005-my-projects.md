---
title: "聊聊我的开源项目们：LLM 基础设施方向的技术探索"
date: 2026-06-01T16:00:00+08:00
draft: false
description: "回顾这几年在 LLM 基础设施方向的开源项目探索，从性能测试到镜像管理，从 KV Cache 优化到多用户系统，记录踩坑过程中的技术成长"
tags:
  - 开源
  - 项目总结
  - LLM
categories:
  - 项目笔记
authors:
  - Potterluo
---

## 写在前面

过去两年，LLM 应用爆发式增长，但很多人关注的都是模型本身——参数量、推理能力、多模态支持。作为一个基础设施工程师，我更关注的是：**模型怎么跑起来？跑起来怎么稳定？稳定了怎么更省钱？**

这些问题看似「配角」，但在生产环境中往往决定了成败。模型再强，部署搞不定也白搭；推理再快，资源管理混乱也会翻车。

于是我开始在这个方向做了一些探索，写了几个开源项目。今天想聊聊这些项目背后的故事——解决的问题、踩过的坑、学到的东西。

---

## ClawPerf：LLM 服务性能基准测试

GitHub: [Potterluo/ClawPerf](https://github.com/Potterluo/ClawPerf)

### 问题背景

LLM 服务上线前，大家都会做性能测试。但现有的工具要么太简单（单请求测试），要么太复杂（需要搭建整套压测平台）。我想要的很简单：

- **模拟真实多用户负载**：不是发一个请求测延迟，而是模拟 10 个用户同时请求
- **统计关键指标**：TTFT（首字延迟）、TPS（每秒 token 数）、成功率
- **CLI 工具**：不想装一堆依赖，只想一个命令搞定

### ClawPerf 的设计

核心思路：**用并发控制模拟真实负载**。

```bash
# 基本用法：模拟 5 个并发用户，每个发 10 个请求
clawperf --url http://localhost:8000/v1/chat/completions \
         --model llama3 \
         --concurrency 5 \
         --requests 10 \
         --prompt "Hello, how are you?"
```

输出会统计：

- 平均 TTFT（首字延迟）
- 平均 TPS（生成速度）
- 成功/失败率
- P50/P90/P99 延迟分布

### 关键技术点

1. **并发模型**：用异步 HTTP 客户端（Python asyncio + aiohttp）实现真正的并发请求
2. **流式处理**：LLM 推理是流式输出，需要边接收边计算指标
3. **Token 计数**：没有现成的 tokenizer 时，用字符数估算（不够精确但能反映趋势）

### 适用场景

- 模型上线前的性能验收
- 不同推理引擎对比（vLLM、TGI、TensorRT-LLM）
- 硬件配置选型（测不同 GPU 的表现）

### 后续计划

想加入更多测试模式：长文本测试、多轮对话测试、混合负载测试。

---

## MirrorX：容器镜像同步系统

GitHub: [Potterluo/MirrorX](https://github.com/Potterluo/MirrorX)

### 问题背景

容器镜像管理是个老问题，但在 AI 场景变得更复杂：

- **镜像体积大**：LLM 相关镜像动辄几 GB 甚至十几 GB
- **多仓库同步**：从 Docker Hub 同步到内网仓库，还要同步到多云环境
- **定时更新**：基础镜像更新后，需要自动同步新版本

### MirrorX 的架构

核心组件：

1. **skopeo**：镜像同步的利器，支持跨仓库复制
2. **cron 定时任务**：定期检查和同步
3. **webhook 通知**：同步完成/失败时通知
4. **WebUI 管理界面**：可视化配置和监控

```yaml
# 同步任务配置示例
sync_tasks:
  - name: "sync-llm-base-images"
    source: "docker.io"
    destination: "myregistry.internal"
    images:
      - "vllm/vllm-openai:latest"
      - "huggingface/text-generation-inference:latest"
    schedule: "0 2 * * *"  # 每天 2 点执行
    notify_webhook: "https://my-webhook/sync-complete"
```

### 关键特性

- **增量同步**：只同步新增的 layer，节省带宽和时间
- **架构过滤**：只同步需要的架构（amd64 或 arm64）
- **失败重试**：网络抖动自动重试，不丢任务
- **同步历史**：可查看每次同步的详细日志

### 适用场景

- 企业内网镜像仓库维护
- 多云环境镜像分发
- CI/CD 缓存加速（提前同步常用镜像）

---

## KVCache-calculator-Skill：KV Cache 内存计算器

GitHub: [Potterluo/KVCache-calculator-Skill](https://github.com/Potterluo/KVCache-calculator-Skill)

### 问题背景

LLM 推理时，KV Cache 是内存大户。很多人问我：「我这台 GPU 能跑多大的模型？能支持多长的上下文？」

这个问题不是简单算算参数量就行，得考虑：

- **KV Cache 的内存占用**：和序列长度、层数、注意力头数相关
- **不同架构差异**：MLA、GQA、Hybrid、Standard 的内存计算方式不同

### 计算器的设计

做成 CLI 工具，输入模型参数，输出内存估算：

```bash
# 计算 Standard Attention 的 KV Cache
kvcache-calc --architecture standard \
             --num-layers 32 \
             --num-heads 32 \
             --head-dim 128 \
             --seq-length 4096 \
             --dtype fp16

# 输出：Estimated KV Cache Memory: 2.0 GB
```

支持多种架构：

| 架构 | 特点 | 计算公式差异 |
|------|------|-------------|
| Standard | 传统注意力 | `2 × layers × heads × head_dim × seq_len` |
| GQA | Grouped Query Attention | 头数按 KV group 计算，内存更省 |
| MLA | Multi-Head Latent Attention | DeepSeek 的压缩方案，内存大幅降低 |
| Hybrid | 混合架构 | 按比例组合不同 Attention |

### 技术难点

1. **公式推导**：每种架构的 KV Cache 计算方式不同，需要理解原理
2. **单位换算**：dtype 影响（fp16=2bytes, fp32=4bytes）
3. **边界情况**：超长序列、多批次时的内存峰值

### 适用场景

- 部署前的资源评估
- 不同架构的内存对比
- 长文本场景的可行性分析

---

## docker-pull-tar：Docker 镜像拉取工具

GitHub: [Potterluo/docker-pull-tar](https://github.com/Potterluo/docker-pull-tar)

这个项目我之前专门写过博客（[我写了个 Docker 镜像拉取工具，不用装 Docker](/posts/docker-pull-tar/))，简单回顾一下：

### 核心价值

**不需要 Docker/Python，只要有 curl 和 shell，就能从 Registry 拉镜像并打包成 tar。**

解决的是内网部署和离线交付的痛点：

- 目标机器没有 Docker，但需要拉镜像
- 大镜像传输中断，需要断点续传
- 拉错了架构的镜像（比如在 ARM 机器拉了 x86）

### 使用示例

```bash
# 基本用法
./docker-pull-tar.sh nginx:latest

# 指定架构
./docker-pull-tar.sh --platform linux/arm64 nginx:latest

# 断点续传
# 下载中断了，重新运行同一个命令即可
./docker-pull-tar.sh nginx:latest
```

### 技术实现

绕过 Docker，直接和 Registry HTTP API 对话：

1. 解析镜像名 → 获取 Registry 地址
2. 获取 Manifest → 查询镜像的 layer 列表
3. 下载 Layers → 用 curl 逐个下载 blob
4. 组装 Tar → 按照 Docker 的 tar 格式组装
5. 校验 SHA256 → 确保下载完整

---

## unified-cache-management：LLM KV Cache 持久化复用

GitHub: [Potterluo/unified-cache-management](https://github.com/Potterluo/unified-cache-management)

### 问题背景

LLM 推理中，KV Cache 的计算开销很大。对于相同 prefix 的请求（比如相同的 system prompt），每次都重新计算 KV Cache 是浪费。

如果能 **持久化 KV Cache，后续请求复用**，就能：

- 降低首字延迟（TTFT）
- 节省计算资源
- 提升吞吐量

### 设计思路

```text
请求流程：
1. 请求进来 → 解析 prefix（system prompt + 部分 user prompt）
2. 检查缓存池 → 是否有匹配的 KV Cache？
3. 如果有 → 复用缓存，只计算新增部分
4. 如果没有 → 完整计算，并缓存结果
```

核心挑战：

- **KV Cache 的序列化**：不同推理引擎的格式不同，需要统一接口
- **缓存匹配算法**：如何快速判断两个请求的 prefix 是否相同
- **缓存淘汰策略**：内存有限，需要 LRU 或其他策略管理缓存

### 当前进展

还在实验阶段，主要验证了：

- prefix 匹配时的性能提升（TTFT 降低 30%-50%）
- 不同推理引擎的缓存接口差异
- 内存管理的基本策略

后续想做成通用的缓存层，适配多种推理引擎。

---

## MultiUserClaw：多用户版 OpenClaw

GitHub: [Potterluo/MultiUserClaw](https://github.com/Potterluo/MultiUserClaw)

### 问题背景

OpenClaw 是一个优秀的 LLM 接口聚合项目，但原版主要面向单用户场景。在企业使用时，我们需要：

- **多用户隔离**：每个用户有自己的 API key 和权限
- **用量统计**：每个用户的 token 使用量、成本统计
- **配额管理**：防止某个用户占用过多资源

### MultiUserClaw 的扩展

在 OpenClaw 基础上增加：

```yaml
# 用户配置示例
users:
  - name: "alice"
    api_key: "sk-alice-xxx"
    quota:
      max_tokens_per_day: 100000
      max_requests_per_minute: 60
    allowed_models:
      - "gpt-4"
      - "claude-3"

  - name: "bob"
    api_key: "sk-bob-xxx"
    quota:
      max_tokens_per_day: 50000
    allowed_models:
      - "gpt-3.5"
```

### 关键特性

- **请求路由**：根据 API key 识别用户，路由到对应的模型配置
- **配额检查**：请求前检查用户配额，超限则拒绝
- **用量统计**：记录每次请求的 token 数、成本，可导出报表
- **权限隔离**：不同用户可访问不同的模型

### 适用场景

- 企业内部 LLM 服务管理
- 多团队共享推理资源
- API 服务计量计费

---

## 回顾与展望

这6个项目，看起来方向各异，但都围绕一个核心：**让 LLM 在生产环境中跑得更稳、更省、更方便。**

| 项目 | 解决的问题 | 核心价值 |
|------|-----------|---------|
| ClawPerf | 性能测试难做 | CLI 基准测试，模拟真实负载 |
| MirrorX | 镜像同步繁琐 | 自动化同步，WebUI 管理 |
| KVCache-calculator-Skill | 内存评估靠猜 | 精确计算不同架构的内存占用 |
| docker-pull-tar | 无 Docker 拉镜像 | 纯 shell 工具，断点续传 |
| unified-cache-management | KV Cache 重复计算 | 持久化复用，降低延迟 |
| MultiUserClaw | 多用户管理缺失 | 配额、权限、用量统计 |

做这些项目的过程中，学到了很多：

1. **LLM 推理的细节**：KV Cache、TTFT、TPS 这些指标背后的原理
2. **容器技术的深挖**：Registry API、镜像格式、同步机制
3. **工程化的思维**：不是做 Demo，而是做能用的工具
4. **开源的协作**：提 PR、收 Issue、迭代改进

接下来想继续深挖的方向：

- **更智能的缓存管理**：不只是 prefix 匹配，而是语义相似的请求也能复用缓存
- **推理引擎的调度优化**：多模型混跑时的资源分配
- **成本优化**：更精确的资源预估和成本控制

如果你也在做 LLM 基础设施相关工作，欢迎交流。这些项目都在 GitHub 上开源，欢迎提 Issue、PR，或者只是 Star 支持一下——这对独立开发者来说，是很大的鼓励。

---

## 相关链接

- ClawPerf: [https://github.com/Potterluo/ClawPerf](https://github.com/Potterluo/ClawPerf)
- MirrorX: [https://github.com/Potterluo/MirrorX](https://github.com/Potterluo/MirrorX)
- KVCache-calculator-Skill: [https://github.com/Potterluo/KVCache-calculator-Skill](https://github.com/Potterluo/KVCache-calculator-Skill)
- docker-pull-tar: [https://github.com/Potterluo/docker-pull-tar](https://github.com/Potterluo/docker-pull-tar)
- unified-cache-management: [https://github.com/Potterluo/unified-cache-management](https://github.com/Potterluo/unified-cache-management)
- MultiUserClaw: [https://github.com/Potterluo/MultiUserClaw](https://github.com/Potterluo/MultiUserClaw)