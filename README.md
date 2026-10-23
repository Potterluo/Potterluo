<div align="center">

<img src="https://raw.githubusercontent.com/Potterluo/Potterluo/main/assets/avatar.png" width="112" alt="Keriko" />

# 你好，我是 Keriko 👋

**LLM 基础设施工程师** · 中国科学院大学（UCAS）· 北京

[![博客](https://img.shields.io/badge/博客-行星观察笔记-397C82?style=flat-square&logo=astro&logoColor=white)](https://keriko-blog.pages.dev)
[![RSS](https://img.shields.io/badge/RSS-订阅-EE802F?style=flat-square&logo=rss&logoColor=white)](https://keriko-blog.pages.dev/rss.xml)
[![GitHub Followers](https://img.shields.io/github/followers/Potterluo?style=flat-square&color=397C82&label=followers)](https://github.com/Potterluo?tab=followers)

<img src="https://readme-typing-svg.demolab.com?font=Fira+Code&size=15&duration=2800&pause=900&color=397C82&center=true&vCenter=true&width=520&lines=LLM+Infrastructure+Engineer;KV+Cache+%C2%B7+Inference+Performance+%C2%B7+MCP;Making+infrastructure+feel+simple" alt="LLM Infrastructure Engineer" />

</div>

---

## 🧭 关于我

- 🔭 在 **UCAS** 做 LLM 推理基础设施，主要折腾 **KV Cache 的持久化、卸载与跨请求复用**
- 🧪 喜欢把「感觉快了」变成可度量的数字：TTFT、TPOT、缓存命中率、吞吐
- 🧰 把工作里的重复劳动做成工具：镜像分发、MCP 网关、性能基准
- ✍️ 在 [「行星观察笔记」](https://keriko-blog.pages.dev) 记录技术复盘、开源旅程，和偶尔的发呆
- 🌱 相信开源是「问题 → 方案 → 共享」的循环，而不是攒 star

> 技术是我的望远镜，而好奇心是我的引力。

## 🎯 最近在忙

- **UCM** — KV Cache 持久化与复用系统的架构演进：接口设计、Pipeline 存储、锁优化、多 rank 加载
- **MCP 工具链** — 让模型少读一点上下文，多干一点正事（[API2MCP](https://github.com/Potterluo/API2MCP) / [MCPS2ONE](https://github.com/Potterluo/MCPS2ONE)）
- **基准测试** — 把推理性能评测做成可复现的自动化流程（[ClawPerf](https://github.com/Potterluo/ClawPerf) / [PrefixBench 数据集](https://modelscope.cn/datasets/keriko/PrefixBench)）

## 🚀 精选项目

| 项目 | 它解决什么问题 | 语言 |
| :--- | :--- | :--- |
| [**ClawPerf**](https://github.com/Potterluo/ClawPerf) | 面向 Agent 场景的 LLM 服务基准测试：多用户、长对话、长上下文压测 | `Python` ![★](https://img.shields.io/github/stars/Potterluo/ClawPerf?style=flat-square&color=397C82&label=%E2%98%85) |
| [**KVCache-calculator-Skill**](https://github.com/Potterluo/KVCache-calculator-Skill) | KV Cache 显存计算，支持 MLA / GQA / Hybrid，部署前先算清账 | `Python` ![★](https://img.shields.io/github/stars/Potterluo/KVCache-calculator-Skill?style=flat-square&color=397C82&label=%E2%98%85) |
| [**API2MCP**](https://github.com/Potterluo/API2MCP) | 把任意 REST API 封装成标准 MCP 服务，统一 SSE 接入 | `JavaScript` ![★](https://img.shields.io/github/stars/Potterluo/API2MCP?style=flat-square&color=397C82&label=%E2%98%85) |
| [**MCPS2ONE**](https://github.com/Potterluo/MCPS2ONE) | 用小模型自动挑选 MCP 工具，给主模型省下约 90% 的 token | `Python` ![★](https://img.shields.io/github/stars/Potterluo/MCPS2ONE?style=flat-square&color=397C82&label=%E2%98%85) |
| [**docker-pull-tar**](https://github.com/Potterluo/docker-pull-tar) | 不装 Docker / Python 也能拉镜像，离线内网部署友好 | `Go` ![★](https://img.shields.io/github/stars/Potterluo/docker-pull-tar?style=flat-square&color=397C82&label=%E2%98%85) |
| [**MirrorX**](https://github.com/Potterluo/MirrorX) | 容器镜像同步管理：skopeo + cron + webhook + Web UI | `Python` ![★](https://img.shields.io/github/stars/Potterluo/MirrorX?style=flat-square&color=397C82&label=%E2%98%85) |

<sub>其他方向：[Dream-Interviewer](https://github.com/Potterluo/Dream-Interviewer)（AI 模拟面试，17★） · [xpu-monitor](https://github.com/Potterluo/xpu-monitor)（NPU / GPU 监控，7★） · [PocketLLM](https://github.com/Potterluo/PocketLLM)（跑在 ESP32 上的小模型） · [GPT-Zero](https://github.com/Potterluo/GPT-Zero)（OpenAI 兼容的 mock LLM 服务）</sub>

## 📝 最近在写

<!-- BLOG-POST-LIST:START -->- [UCM v2 推理数据卸载/重载系统：接口设计文档（搬运）](https://keriko-blog.pages.dev/posts/018-ucm-v2-interface-design) ·  2026-10-23
- [UCM Store 的 Pipeline 架构：把存储拆成一条可插拔流水线](https://keriko-blog.pages.dev/posts/019-ucm-pipeline-store) ·  2026-10-23
- [把共享内存缓存的锁拆掉：UCM 桶锁乐观化与节点锁无锁化](https://keriko-blog.pages.dev/posts/020-ucm-cache-concurrency) ·  2026-10-23
- [多 rank 共享 KV Cache：UCM 加载路径的重构](https://keriko-blog.pages.dev/posts/021-ucm-multi-rank-load) ·  2026-10-23
- [UCM 演进之路：从 commit 史看一个 KV Cache 系统如何长出来](https://keriko-blog.pages.dev/posts/022-ucm-evolution) ·  2026-10-23
- [KVCache 卸载方案技术竞争力对比：UCM vs 七家](https://keriko-blog.pages.dev/posts/023-kvcache-competitive-analysis) ·  2026-10-23
<!-- BLOG-POST-LIST:END -->

<sub>由 GitHub Actions 每天从 [RSS](https://keriko-blog.pages.dev/rss.xml) 自动同步 · [全部文章 →](https://keriko-blog.pages.dev/posts)</sub>

## 🧵 专题笔记

- **UCM 深度系列（8 篇）** — [接口设计](https://keriko-blog.pages.dev/posts/018-ucm-v2-interface-design) · [Pipeline 存储](https://keriko-blog.pages.dev/posts/019-ucm-pipeline-store) · [并发锁优化](https://keriko-blog.pages.dev/posts/020-ucm-cache-concurrency) · [多 rank 加载](https://keriko-blog.pages.dev/posts/021-ucm-multi-rank-load) · [演进史](https://keriko-blog.pages.dev/posts/022-ucm-evolution) · [竞品对比](https://keriko-blog.pages.dev/posts/023-kvcache-competitive-analysis) · [性能路线](https://keriko-blog.pages.dev/posts/024-ucm-performance-first) · [与 LMCache 对照](https://keriko-blog.pages.dev/posts/025-lmcache-compatibility)
- **LLM 推理与性能** — [Nano-vLLM 源码](https://keriko-blog.pages.dev/posts/010-nanovllm) · [注意力机制](https://keriko-blog.pages.dev/posts/llm-attention-mechanism) · [pytest 性能基准](https://keriko-blog.pages.dev/posts/004-llm-perf-testing) · [PrefixBench](https://keriko-blog.pages.dev/posts/006-prefix-bench)
- **工程复盘** — [K8s 控制平面瘫痪](https://keriko-blog.pages.dev/posts/k8s-control-plane-outage) · [EVA 验证架构](https://keriko-blog.pages.dev/posts/eva-engineering-validation-architecture) · [Jenkins 异步流水线](https://keriko-blog.pages.dev/posts/017-jenkins-async-pipeline)
- **计算机基础** — [MIT 6.824](https://keriko-blog.pages.dev/posts/013-mit-6824) · [B+ 树索引](https://keriko-blog.pages.dev/posts/009-btree-index) · [Diffusion Model](https://keriko-blog.pages.dev/posts/016-diffusion-model)

## 🧰 技术栈

**推理 / LLM**：[![vLLM](https://img.shields.io/badge/vLLM-5B5BD6?style=flat-square)](https://github.com/vllm-project/vllm) [![SGLang](https://img.shields.io/badge/SGLang-1F6FEB?style=flat-square)](https://github.com/sgl-project/sglang) [![Transformers](https://img.shields.io/badge/Transformers-FFD21E?style=flat-square&logo=huggingface&logoColor=black)](https://github.com/huggingface/transformers) [![KV Cache](https://img.shields.io/badge/KV_Cache-E91E63?style=flat-square)](https://github.com/ModelEngine-Group/unified-cache-management) [![MCP](https://img.shields.io/badge/MCP-7C3AED?style=flat-square)](https://modelcontextprotocol.io) [![Ascend NPU](https://img.shields.io/badge/Ascend_NPU-CF0A2C?style=flat-square)](https://www.hiascend.com)

**语言**：[![Python](https://img.shields.io/badge/Python-3776AB?style=flat-square&logo=python&logoColor=white)](https://www.python.org) [![Go](https://img.shields.io/badge/Go-00ADD8?style=flat-square&logo=go&logoColor=white)](https://go.dev) [![C++](https://img.shields.io/badge/C%2B%2B-00599C?style=flat-square&logo=cplusplus&logoColor=white)](https://isocpp.org) [![Rust](https://img.shields.io/badge/Rust-DEA584?style=flat-square&logo=rust&logoColor=black)](https://www.rust-lang.org) [![Shell](https://img.shields.io/badge/Shell-4EAA25?style=flat-square&logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash)

**基础设施**：[![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat-square&logo=docker&logoColor=white)](https://www.docker.com) [![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=flat-square&logo=kubernetes&logoColor=white)](https://kubernetes.io) [![Linux](https://img.shields.io/badge/Linux-FCC624?style=flat-square&logo=linux&logoColor=black)](https://www.kernel.org) [![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=flat-square&logo=prometheus&logoColor=white)](https://prometheus.io) [![etcd](https://img.shields.io/badge/etcd-419CD8?style=flat-square)](https://etcd.io) [![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-2088FF?style=flat-square&logo=githubactions&logoColor=white)](https://github.com/features/actions)

**工具链**：[![pytest](https://img.shields.io/badge/pytest-0A9EDC?style=flat-square&logo=pytest&logoColor=white)](https://pytest.org) [![Git](https://img.shields.io/badge/Git-F05032?style=flat-square&logo=git&logoColor=white)](https://git-scm.com) [![Astro](https://img.shields.io/badge/Astro-FF5D01?style=flat-square&logo=astro&logoColor=white)](https://astro.build) [![Markdown](https://img.shields.io/badge/Markdown-000000?style=flat-square&logo=markdown&logoColor=white)](https://commonmark.org)

## 📊 GitHub 数据

<p align="center">
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://github-readme-stats.vercel.app/api?username=Potterluo&show_icons=true&hide_border=true&bg_color=0D1117&title_color=5FB3B3&icon_color=5FB3B3&text_color=C9D1D9&border_color=30363D&card_width=420" />
  <img src="https://github-readme-stats.vercel.app/api?username=Potterluo&show_icons=true&hide_border=true&bg_color=FFFFFF&title_color=397C82&icon_color=397C82&text_color=3A3A3A&border_color=E7EBEA&card_width=420" width="420" alt="GitHub Stats" />
</picture>
</p>

<p align="center">
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://streak-stats.demolab.com?user=Potterluo&background=0D1117&border=30363D&stroke=30363D&ring=5FB3B3&fire=5FB3B3&currStreakNum=C9D1D9&sideNums=C9D1D9&currStreakLabel=5FB3B3&sideLabels=C9D1D9&dates=8B949E&hide_border=true" />
  <img src="https://streak-stats.demolab.com?user=Potterluo&background=FFFFFF&border=E7EBEA&stroke=E7EBEA&ring=397C82&fire=397C82&currStreakNum=3A3A3A&sideNums=3A3A3A&currStreakLabel=397C82&sideLabels=3A3A3A&dates=8A8F8D&hide_border=true" width="460" alt="GitHub Streak" />
</picture>
</p>

## 📬 找到我

- **博客**：[keriko-blog.pages.dev](https://keriko-blog.pages.dev) — 技术复盘、开源旅程与偶尔的发呆
- **RSS**：[订阅](https://keriko-blog.pages.dev/rss.xml) — 不想被算法安排，就直接订阅
- **GitHub**：你已经在看了；想聊 LLM Infra、开源，或者任何有意思的事，欢迎开 [Issue](https://github.com/Potterluo/Potterluo/issues) 或来博客留言

---

<div align="center">

<sub>「代码是暂时的，思想是永恒的。但写代码的过程，就是思考变成永恒的过程。」</sub>

</div>
