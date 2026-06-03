---
title: "LLM 推理性能测试：用 pytest 做自动化基准测试"
date: 2026-05-08T09:00:00+08:00
draft: false
description: "介绍如何使用 pytest 构建 LLM 推理性能自动化测试框架，包括 YAML 配置管理、数据库集成、HTML 报告生成等核心功能"
tags:
  - LLM
  - 性能测试
  - pytest
  - vLLM
categories:
  - 技术分享
authors:
  - Potterluo
---

在 LLM 推理引擎的开发和优化过程中，性能测试是不可或缺的环节。传统的手工测试方式效率低、可重复性差，难以支撑大规模的性能基准测试需求。本文将介绍如何使用 pytest 7.0+ 构建一套完整的 LLM 推理性能自动化测试框架，实现从配置管理到报告生成的全流程自动化。

## 为什么选择 pytest？

pytest 是 Python 生态中最流行的测试框架之一，选择它作为性能测试框架有以下几个关键优势：

1. **强大的参数化能力**：支持多维度测试参数组合，轻松覆盖不同的推理场景
2. **灵活的标记系统**：可以按测试阶段、功能特性、运行平台等维度筛选测试
3. **丰富的插件生态**：pytest-html、pytest-xdist 等插件扩展功能
4. **简洁的 fixture 机制**：统一管理测试依赖和资源初始化

更重要的是，pytest 的设计理念与性能测试的需求高度契合——**可配置、可扩展、可重复**。

---

## 框架架构设计

整个测试框架分为五个核心模块：

```text
├── config/               # YAML 配置管理
│   ├── base.yaml        # 基础配置
│   ├── ascend.yaml      # Ascend 平台配置
│   └── cuda.yaml        # CUDA 平台配置
├── tests/               # 测试用例
│   ├── conftest.py      # fixture 和装饰器定义
│   ├── test_latency.py  # 延迟测试
│   └── test_throughput.py # 吞吐量测试
├── collectors/          # 结果采集器
│   ├── db_exporter.py   # PostgreSQL 导出
│   └── html_reporter.py # HTML 报告生成
├── utils/               # 工具函数
│   └── vllm_client.py   # vLLM UC 集成
│   └── platform.py      # 平台适配层
└── pytest.ini           # pytest 配置
```

---

## YAML 配置管理

配置管理是自动化测试的基础。我们使用 YAML 文件分层管理不同平台和场景的配置：

```yaml
# config/base.yaml
model:
  name: "Qwen/Qwen2.5-7B-Instruct"
  max_length: 4096

test_params:
  in_tokens: [128, 512, 1024, 2048]
  out_tokens: [64, 256, 512]
  concurrent: [1, 4, 8, 16]

thresholds:
  latency_p99: 500  # ms
  throughput_min: 50  # tokens/s

# config/ascend.yaml
extends: base.yaml
platform:
  type: "ascend"
  device: "npu"
  count: 8
  memory: 64  # GB

# config/cuda.yaml
extends: base.yaml
platform:
  type: "cuda"
  device: "gpu"
  count: 4
  memory: 80  # GB
```

通过 `extends` 机制实现配置继承，避免重复定义。测试启动时根据 `--platform` 参数自动加载对应配置：

```python
# tests/conftest.py
import yaml
import pytest

def pytest_addoption(parser):
    parser.addoption("--platform", action="store", default="cuda")

@pytest.fixture(scope="session")
def config(request):
    platform = request.config.getoption("--platform")
    base = yaml.safe_load(open("config/base.yaml"))
    platform_cfg = yaml.safe_load(open(f"config/{platform}.yaml"))

    # 合并配置
    merged = {**base, **platform_cfg}
    return merged
```

---

## 多维标记系统

pytest 的标记系统让我们可以灵活筛选测试用例。我们定义了三类标记：

```python
# pytest.ini
[pytest]
markers =
    stage_unit: 单元测试阶段
    stage_smoke: 冒烟测试阶段
    stage_regression: 回归测试阶段
    feature_latency: 延迟测试功能
    feature_throughput: 吞吐量测试功能
    platform_ascend: Ascend NPU 平台
    platform_cuda: CUDA GPU 平台
```

测试用例中使用多标记组合：

```python
@pytest.mark.stage_smoke
@pytest.mark.feature_latency
@pytest.mark.platform_cuda
def test_single_request_latency(config, vllm_client):
    """单请求延迟测试 - CUDA 平台冒烟阶段"""
    prompt = generate_prompt(config["test_params"]["in_tokens"][0])

    result = vllm_client.generate(
        prompt,
        max_tokens=config["test_params"]["out_tokens"][0]
    )

    assert result["latency"] < config["thresholds"]["latency_p99"]
```

运行时通过 `-m` 参数筛选：

```bash
# 只运行冒烟测试
pytest -m "stage_smoke"

# 只运行 CUDA 平台的延迟测试
pytest -m "platform_cuda and feature_latency"

# 排除 Ascend 平台的测试
pytest -m "not platform_ascend"
```

---

## 参数化测试

性能测试的核心是覆盖多种参数组合。pytest 的参数化机制完美支持这一需求：

```python
@pytest.mark.stage_regression
@pytest.mark.feature_throughput
@pytest.mark.parametrize("in_tokens", [128, 512, 1024, 2048])
@pytest.mark.parametrize("out_tokens", [64, 256, 512])
@pytest.mark.parametrize("concurrent", [1, 4, 8, 16])
def test_concurrent_throughput(
    config, vllm_client, in_tokens, out_tokens, concurrent
):
    """并发吞吐量测试 - 多参数组合"""
    prompts = [
        generate_prompt(in_tokens)
        for _ in range(concurrent)
    ]

    # 并发请求
    results = vllm_client.batch_generate(
        prompts,
        max_tokens=out_tokens,
        concurrent=concurrent
    )

    # 计算吞吐量
    total_tokens = sum(r["output_tokens"] for r in results)
    total_time = max(r["latency"] for r in results)
    throughput = total_tokens / total_time

    assert throughput >= config["thresholds"]["throughput_min"]
```

这个测试会自动生成 `4 × 3 × 4 = 48` 个测试用例，覆盖所有参数组合。每个组合独立运行，结果单独记录。

---

## @export_vars 自动采集

性能测试不仅要验证结果，还要采集过程数据。我们设计了 `@export_vars` 装饰器，自动采集测试变量并导出到数据库：

```python
# collectors/db_exporter.py
import functools
import psycopg2
from datetime import datetime

export_registry = []

def export_vars(**var_defs):
    """
    装饰器：自动采集测试变量

    用法:
        @export_vars(
            latency="result['latency']",
            tokens="result['output_tokens']",
            throughput="throughput"
        )
        def test_xxx(...):
            ...
    """
    def decorator(func):
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            # 执行测试
            result = func(*args, **kwargs)

            # 采集变量
            exported = {}
            for var_name, var_path in var_defs.items():
                # 从函数局部变量中提取
                value = eval(var_path, func.__globals__, locals())
                exported[var_name] = value

            # 注册到全局采集器
            export_registry.append({
                "test_name": func.__name__,
                "timestamp": datetime.now(),
                "platform": kwargs.get("config", {}).get("platform", {}).get("type"),
                **exported
            })

            return result
        return wrapper
    return decorator
```

测试用例中使用装饰器：

```python
@pytest.mark.stage_regression
@pytest.mark.feature_latency
@pytest.mark.parametrize("in_tokens", [128, 512])
@export_vars(
    latency="result['latency']",
    tokens="result['output_tokens']",
    ttft="result['time_to_first_token']",
    platform="config['platform']['type']"
)
def test_request_latency(config, vllm_client, in_tokens):
    prompt = generate_prompt(in_tokens)
    result = vllm_client.generate(prompt, max_tokens=256)
    assert result["latency"] < config["thresholds"]["latency_p99"]
    return result  # 装饰器需要返回结果
```

测试完成后，采集器自动将数据导出到 PostgreSQL：

```python
# collectors/db_exporter.py
@pytest.fixture(scope="session", autouse=True)
def db_exporter(config):
    """会话结束时导出所有采集数据到数据库"""

    yield  # 等待所有测试完成

    conn = psycopg2.connect(
        host=config["db"]["host"],
        database=config["db"]["name"],
        user=config["db"]["user"],
        password=config["db"]["password"]
    )

    cursor = conn.cursor()

    # 创建表（如果不存在）
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS perf_results (
            test_name VARCHAR(255),
            timestamp TIMESTAMP,
            platform VARCHAR(50),
            latency FLOAT,
            tokens INT,
            throughput FLOAT,
            ttft FLOAT,
            in_tokens INT,
            out_tokens INT,
            concurrent INT
        )
    """)

    # 批量插入
    for record in export_registry:
        cursor.execute("""
            INSERT INTO perf_results VALUES (
                %(test_name)s, %(timestamp)s, %(platform)s,
                %(latency)s, %(tokens)s, %(throughput)s,
                %(ttft)s, %(in_tokens)s, %(out_tokens)s, %(concurrent)s
            )
        """, record)

    conn.commit()
    conn.close()
```

---

## vLLM UC 集成

我们与 vLLM UC（Unified Client）深度集成，提供统一的推理接口：

```python
# utils/vllm_client.py
import requests
import asyncio
import aiohttp

class vLLMClient:
    """vLLM UC 客户端封装"""

    def __init__(self, config):
        self.base_url = config["vllm"]["api_base"]
        self.model = config["model"]["name"]

    def generate(self, prompt, max_tokens=256):
        """单请求推理"""
        response = requests.post(
            f"{self.base_url}/generate",
            json={
                "model": self.model,
                "prompt": prompt,
                "max_tokens": max_tokens,
                "stream": False
            }
        )
        data = response.json()

        return {
            "text": data["text"],
            "latency": data["latency"],
            "output_tokens": data["output_tokens"],
            "time_to_first_token": data["ttft"]
        }

    async def batch_generate_async(
        self, prompts, max_tokens=256, concurrent=8
    ):
        """并发推理"""
        semaphore = asyncio.Semaphore(concurrent)

        async def _generate(session, prompt):
            async with semaphore:
                async with session.post(
                    f"{self.base_url}/generate",
                    json={
                        "model": self.model,
                        "prompt": prompt,
                        "max_tokens": max_tokens
                    }
                ) as resp:
                    return await resp.json()

        async with aiohttp.ClientSession() as session:
            results = await asyncio.gather(
                *[_generate(session, p) for p in prompts]
            )

        return results

    def batch_generate(self, prompts, max_tokens=256, concurrent=8):
        """同步包装"""
        return asyncio.run(
            self.batch_generate_async(prompts, max_tokens, concurrent)
        )
```

fixture 中初始化客户端：

```python
@pytest.fixture(scope="session")
def vllm_client(config):
    """vLLM UC 客户端"""
    client = vLLMClient(config)

    # 健康检查
    try:
        requests.get(f"{client.base_url}/health")
    except Exception as e:
        pytest.fail(f"vLLM service not available: {e}")

    return client
```

---

## HTML 报告生成

pytest-html 插件生成可视化报告，但我们进一步定制报告模板：

```python
# collectors/html_reporter.py
from pytest_html import HTMLReport

def pytest_configure(config):
    """注册自定义报告"""
    config.pluginmanager.register(HTMLReport(config))

class HTMLReport:
    """自定义 HTML 报告"""

    def pytest_sessionfinish(self, session):
        # 生成报告时注入自定义数据
        self.add_perf_summary(export_registry)

    def add_perf_summary(self, records):
        """添加性能摘要表"""
        html = """
        <h2>性能测试摘要</h2>
        <table>
            <tr>
                <th>测试名称</th>
                <th>平台</th>
                <th>平均延迟</th>
                <th>吞吐量</th>
                <th>P99 TTFT</th>
            </tr>
        """

        # 按测试聚合
        summary = self.aggregate_results(records)

        for test_name, data in summary.items():
            html += f"""
            <tr>
                <td>{test_name}</td>
                <td>{data['platform']}</td>
                <td>{data['avg_latency']:.2f} ms</td>
                <td>{data['avg_throughput']:.1f} tokens/s</td>
                <td>{data['p99_ttft']:.2f} ms</td>
            </tr>
            """

        html += "</table>"
        return html
```

运行测试时指定报告路径：

```bash
pytest \
    --platform cuda \
    -m "stage_regression" \
    --html=reports/cuda_regression.html \
    --self-contained-html
```

---

## 平台适配层

Ascend NPU 和 CUDA GPU 的差异通过适配层统一处理：

```python
# utils/platform.py
import os

class PlatformAdapter:
    """平台适配器"""

    def __init__(self, platform_type):
        self.platform = platform_type
        self.device_map = {
            "cuda": "cuda:0",
            "ascend": "npu:0"
        }

    def get_device_count(self):
        """获取设备数量"""
        if self.platform == "cuda":
            import torch
            return torch.cuda.device_count()
        elif self.platform == "ascend":
            return int(os.environ.get("ASCEND_DEVICE_COUNT", 8))

    def set_device(self, device_id):
        """设置当前设备"""
        if self.platform == "cuda":
            import torch
            torch.cuda.set_device(device_id)
        elif self.platform == "ascend":
            os.environ["ASCEND_DEVICE_ID"] = str(device_id)

    def get_memory_info(self):
        """获取内存信息"""
        if self.platform == "cuda":
            import torch
            total = torch.cuda.get_device_properties(0).total_memory
            used = torch.cuda.memory_allocated()
            return {"total": total, "used": used}
        elif self.platform == "ascend":
            # Ascend 内存查询接口
            return self._query_ascend_memory()
```

fixture 中根据平台初始化：

```python
@pytest.fixture(scope="session")
def platform_adapter(config):
    """平台适配器"""
    platform_type = config["platform"]["type"]
    adapter = PlatformAdapter(platform_type)

    # 设置设备
    adapter.set_device(0)

    return adapter
```

---

## 完整运行示例

```bash
# CUDA 平台冒烟测试
pytest --platform cuda -m "stage_smoke" --html=reports/smoke.html

# Ascend 平台回归测试（并行）
pytest --platform ascend -m "stage_regression" \
    -n 4 --dist=loadscope \
    --html=reports/ascend_regression.html

# 全量测试（生成详细报告）
pytest --platform cuda \
    --html=reports/full.html \
    --self-contained-html \
    --json=reports/results.json
```

---

## 总结

这套 pytest 性能测试框架的核心优势：

| 特性 | 实现方式 | 价值 |
|------|----------|------|
| **参数化测试** | `@pytest.mark.parametrize` | 自动覆盖多参数组合 |
| **多维标记** | 自定义 markers | 按阶段/功能/平台筛选 |
| **变量采集** | `@export_vars` 装饰器 | 自动导出到数据库 |
| **配置管理** | YAML + extends | 分层管理平台配置 |
| **平台适配** | PlatformAdapter | 统一 Ascend/CUDA 接口 |
| **报告生成** | pytest-html + 定制 | 可视化性能摘要 |

通过这套框架，我们可以：

1. **自动化执行** 大规模性能基准测试（数百个参数组合）
2. **持久化存储** 测试结果到 PostgreSQL，支持历史对比
3. **可视化报告** 自动生成 HTML 报告，一目了然
4. **跨平台支持** Ascend NPU 和 CUDA GPU 一套代码适配

最重要的是，这套框架**可维护、可扩展**。新增测试场景只需添加配置和测试用例，无需修改框架核心。这正是 pytest 设计理念的最佳实践。

---

## 参考资料

- pytest 官方文档: https://docs.pytest.org/en/stable/
- pytest-html 插件: https://pytest-html.readthedocs.io/
- vLLM 官方文档: https://vllm.readthedocs.io/
- PostgreSQL Python 驱动: https://www.psycopg.org/docs/