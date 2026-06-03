---
title: "读 Nano-vLLM 源码：一个极简 LLM 推理引擎是如何工作的"
date: 2026-06-03T14:00:00+08:00
draft: false
description: "通过阅读 nanovllm 源码，理解 LLM 推理引擎的核心架构：调度器、KV Cache 块管理、模型执行流程"
tags: [LLM, vLLM, 源码阅读, KV Cache, Python]
categories: [技术分享]
---

## 引言

vLLM 是当前最流行的 LLM 推理引擎之一，以其高效的 KV Cache 管理和 PagedAttention 机制闻名。但对于初学者来说，vLLM 的源码庞大复杂，难以快速把握核心原理。

**Nano-vLLM** 是一个精简版的 vLLM 实现，保留了核心架构，代码量极少，非常适合学习 LLM 推理引擎的内部机制。本文通过阅读 nanovllm 源码，深入理解推理引擎的核心组件和执行流程。

## 项目结构一览

nanovllm 的代码结构非常清晰：

```
nanovllm/
├── llm.py                    # 用户入口（仅5行）
├── engine/                   # 引擎核心
│   ├── llm_engine.py        # LLM引擎主类
│   ├── scheduler.py         # 请求调度器
│   ├── block_manager.py     # KV Cache块管理
│   ├── model_runner.py      # 模型执行器
│   └── sequence.py          # 序列数据结构
├── layers/                   # 神经网络层
│   ├── attention.py         # 注意力层
│   ├── linear.py            # 线性层
│   ├── rotary_embedding.py  # 旋转位置编码
│   ├── layernorm.py         # 层归一化
│   ├── activation.py        # 激活函数
│   ├── sampler.py           # 采样器
│   └── embed_head.py        # 嵌入头
├── models/                   # 模型定义
│   └── qwen3.py             # Qwen3模型
└── utils/                    # 工具函数
    ├── context.py           # 上下文管理
    └── loader.py            # 模型加载器
```

这个结构涵盖了 LLM 推理引擎的所有核心部分，从用户接口到底层算子实现，形成一个完整的执行链条。

## 极简的用户接口

nanovllm 的用户接口设计极简，只需 5 行代码就能启动推理：

```python
from nanovllm import LLM, SamplingParams

llm = LLM(model_path, enforce_eager=True, tensor_parallel_size=1)
sampling_params = SamplingParams(temperature=0.6, max_tokens=256)
outputs = llm.generate(prompts, sampling_params)
```

让我们看看 `llm.py` 的实现：

```python
class LLM(LLMEngine):
    """A wrapper around LLMEngine for easy usage."""

    def __init__(self, model_path: str, **kwargs):
        super().__init__(model_path, **kwargs)

    def generate(self, prompts, sampling_params):
        return super().generate(prompts, sampling_params)
```

仅仅是继承 `LLMEngine` 并暴露接口，真正的逻辑都在 `LLMEngine` 中实现。这种设计体现了"入口简洁，内核强大"的思想。

## 核心架构：四组件协作模型

nanovllm 的核心架构可以概括为四个组件的协作：

```
┌─────────────────────────────────────────────────┐
│                    LLMEngine                    │
│  ┌───────────┐  ┌──────────────┐  ┌─────────┐ │
│  │ Scheduler │→ │ BlockManager │→ │  Model  │ │
│  │           │  │              │  │ Runner  │ │
│  └─────┬─────┘  └──────┬───────┘  └────┬────┘ │
│        │               │                │      │
│        └───────────────┴────────────────┘      │
│                    Sequence                    │
└─────────────────────────────────────────────────┘
```

### 1. Scheduler：请求调度器

Scheduler 负责管理推理请求的生命周期，决定何时执行哪些请求。核心职责：

- **请求队列管理**：维护等待、运行、完成三类请求队列
- **抢占机制**：当内存不足时暂停低优先级请求，释放资源给高优先级请求
- **调度策略**：优先调度新请求，其次恢复被抢占的请求

```python
class Scheduler:
    def __init__(self, block_manager):
        self.block_manager = block_manager
        self.waiting = []      # 等待队列
        self.running = []      # 运行队列
        self.swapped = []      # 换出队列

    def schedule(self):
        """调度策略：优先填充running队列"""
        # 1. 尝试恢复swapped请求
        # 2. 从waiting队列调度新请求
        # 3. 检查内存，必要时抢占请求
        return scheduler_output
```

### 2. BlockManager：KV Cache 块管理器

这是 vLLM 的核心创新——将 KV Cache 组织为固定大小的"块"（Block），类似操作系统的虚拟内存管理。

每个 Block 存储固定数量的 token 的 KV Cache：
- **物理块**：实际存储 KV Cache 的内存块
- **逻辑块**：Sequence 的逻辑视图，映射到物理块
- **引用计数**：支持共享前缀（如 system prompt）

```python
class BlockManager:
    def __init__(self, num_blocks, block_size):
        self.num_blocks = num_blocks      # 物理块总数
        self.block_size = block_size      # 每块存储的token数
        self.free_blocks = set(range(num_blocks))

    def allocate(self, num_blocks):
        """分配物理块"""
        allocated = []
        for _ in range(num_blocks):
            if not self.free_blocks:
                raise MemoryError("Out of blocks")
            block_id = self.free_blocks.pop()
            allocated.append(block_id)
        return allocated

    def free(self, block_ids):
        """释放物理块"""
        for block_id in block_ids:
            self.free_blocks.add(block_id)
```

这种设计带来的优势：
- **内存效率**：按需分配，避免预分配浪费
- **共享前缀**：多个请求共享相同 prompt 时，只存储一份 KV Cache
- **抢占恢复**：可以换出整块 KV Cache，稍后恢复

### 3. ModelRunner：模型执行器

ModelRunner 负责实际执行模型推理，管理 CUDA kernel 和 tensor 操作：

```python
class ModelRunner:
    def __init__(self, model, block_size):
        self.model = model
        self.block_size = block_size

    def run(self, sequences, blocks):
        """执行模型推理"""
        # 1. 准备输入tensor
        input_ids = self.prepare_input_ids(sequences)
        positions = self.prepare_positions(sequences)

        # 2. 构建KV Cache索引
        block_tables = self.prepare_block_tables(blocks)

        # 3. 执行模型forward
        hidden_states = self.model.forward(
            input_ids, positions, block_tables
        )

        # 4. 采样生成下一个token
        next_tokens = self.sample(hidden_states)
        return next_tokens
```

关键点在于 **KV Cache 的索引方式**：每个 Sequence 维护一个 `block_table`，记录其逻辑块到物理块的映射。Attention kernel 通过 block_table 定位实际的 KV Cache 数据。

### 4. Sequence：序列数据结构

Sequence 尴尬表示一个推理请求的生命周期：

```python
class Sequence:
    def __init__(self, prompt, sampling_params):
        self.prompt = prompt
        self.sampling_params = sampling_params
        self.token_ids = []          # 生成的token序列
        self.block_table = []        # 逻辑块->物理块映射
        self.status = "waiting"      # 状态：waiting/running/swapped/finished

    def append_token(self, token_id):
        """追加新生成的token"""
        self.token_ids.append(token_id)
        # 检查是否需要新块
        if len(self.token_ids) % self.block_size == 0:
            self._allocate_new_block()

    def is_finished(self):
        """检查是否完成"""
        return (
            len(self.token_ids) >= self.max_tokens or
            token_id in self.stop_tokens
        )
```

## 执行流程全景图

将所有组件串联起来，完整的推理流程如下：

```
用户请求 → LLMEngine.generate()
              ↓
         创建Sequence对象
              ↓
         加入Scheduler.waiting队列
              ↓
    ┌──── Scheduler.schedule() ←────┐
    │         ↓                     │
    │   分配BlockManager物理块       │
    │         ↓                     │
    │   ModelRunner.run() 执行推理   │
    │         ↓                     │
    │   生成新token，更新Sequence    │
    │         ↓                     │
    │   检查是否完成                 │
    │    ├── 完成 → 移至完成队列      │
    │    └未完成 → 继续循环           │
    └─────────────────────────────────┘
```

核心代码在 `LLMEngine.generate()` 中：

```python
class LLMEngine:
    def generate(self, prompts, sampling_params):
        # 1. 创建Sequence
        sequences = [Sequence(p, sampling_params) for p in prompts]

        # 2. 加入等待队列
        for seq in sequences:
            self.scheduler.add(seq)

        # 3. 推理循环
        while not self.scheduler.is_finished():
            # 调度
            scheduler_output = self.scheduler.schedule()

            # 执行模型
            output = self.model_runner.run(
                scheduler_output.running,
                scheduler_output.blocks
            )

            # 更新序列
            self._update_sequences(output)

        return [seq.token_ids for seq in sequences]
```

## Attention 层的实现

nanovllm 的 Attention 层实现了 PagedAttention 的核心逻辑：

```python
class Attention:
    def forward(self, hidden_states, positions, block_tables):
        # 1. 计算Q, K, V
        q = self.q_proj(hidden_states)
        k = self.k_proj(hidden_states)
        v = self.v_proj(hidden_states)

        # 2. 应用旋转位置编码
        q, k = self.rotary_emb(q, k, positions)

        # 3. 写入KV Cache到物理块
        self._write_to_blocks(k, v, block_tables)

        # 4. 读取历史KV Cache
        k_cache, v_cache = self._read_from_blocks(block_tables)

        # 5. 计算注意力分数
        attn_output = self._compute_attention(q, k_cache, v_cache)

        return self.o_proj(attn_output)
```

关键在于 `_read_from_blocks()` 和 `_write_to_blocks()` 的实现——通过 block_tables 定位物理块中的 KV Cache，实现高效的内存访问。

## 为什么值得学习 nanovllm

1. **代码量少**：核心逻辑约 1000 行，易于整体把握
2. **结构清晰**：每个组件职责明确，边界清晰
3. **保留精髓**：Scheduler + BlockManager + PagedAttention 的核心架构完整
4. **易于扩展**：可以在此基础上添加新特性（如 tensor parallelism）

相比之下，vLLM 源码有数万行，包含大量优化、多后端支持、分布式推理等复杂逻辑。nanovllm 是理解核心原理的最佳切入点。

## 学习建议

建议按以下顺序阅读源码：

1. **从 llm.py 开始**：理解入口接口
2. **阅读 sequence.py**：理解数据结构
3. **深入 scheduler.py**：理解调度机制
4. **研究 block_manager.py**：理解 KV Cache 管理
5. **学习 model_runner.py**：理解执行流程
6. **探索 layers/attention.py**：理解 PagedAttention 实现

每个文件都可以独立理解，逐步构建完整的推理引擎心智模型。

## 总结

Nano-vLLM 是学习 LLM 推理引擎的绝佳材料。通过本文的源码分析，我们理解了：

- **用户接口设计**：简洁的入口封装复杂内核
- **四组件架构**：Scheduler、BlockManager、ModelRunner、Sequence 协作
- **KV Cache 管理**：Block-based 内存管理，类似操作系统虚拟内存
- **执行流程**：调度-分配-执行-更新的循环

掌握这些核心概念后，再去阅读 vLLM 完整源码，会发现复杂逻辑都是在这些核心机制上的扩展和优化。nanovllm 为我们提供了一个清晰的学习起点。

> 项目地址：[github.com/Geeeek/nanovllm](https://github.com/Geeeek/nanovllm)